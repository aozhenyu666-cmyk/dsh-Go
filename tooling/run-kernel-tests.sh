#!/usr/bin/env bash
# Runs the loop/kernel unit tests without Gradle, Android SDK, an emulator or a device.
#
# Why this exists: the kernel suite (Coordinator, ProactiveScheduler, InterceptGuard, the ack
# lattice, the intercept doors) is plain Kotlin over the JVM. It used to be run by a script living
# outside the repository, which meant the "191 tests pass" number could not be reproduced by anyone
# else -- and :app:testArm64DebugUnitTest cannot stand in for it, because app/android ships no
# gradlew (Flutter's .gitignore drops it) and the Gradle tasks need the Android SDK plus a runtime
# that only exists after build-runtime.sh has run on a Linux host.
#
# What it needs, and nothing else:
#   * a JDK 21 (JAVA_HOME or java on PATH)
#   * the Kotlin compiler + stdlib jars, either from a local Gradle cache or from KOTLIN_JARS
#   * junit 4.13.2 + hamcrest-core 1.3, same rule
#
# Usage:
#   tooling/run-kernel-tests.sh              # compile + run everything it can find
#   tooling/run-kernel-tests.sh --list       # print the test classes it would run
#   KOTLIN_JARS=/path/to/jars tooling/run-kernel-tests.sh
#
# Exit code 0 only when every class ran and nothing failed.
set -euo pipefail

HERE="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
ROOT="$(cd "$HERE/.." && pwd)"
APP="$ROOT/app/android/app"
MAIN="$APP/src/main/kotlin/io/github/ccch1mneyyy/dsh_app"
TEST="$APP/src/test/kotlin/io/github/ccch1mneyyy/dsh_app"

say() { printf '%s\n' "$*"; }
die() { printf 'error: %s\n' "$*" >&2; exit 1; }

# ---- JDK ------------------------------------------------------------------------------------
JAVA_BIN="${JAVA_HOME:+$JAVA_HOME/bin/java}"
[[ -n "$JAVA_BIN" && -x "$JAVA_BIN" ]] || JAVA_BIN="$(command -v java || true)"
[[ -n "$JAVA_BIN" ]] || die "no java on PATH and JAVA_HOME is unset"
JAVAC_BIN="$(dirname "$JAVA_BIN")/javac"

# ---- jars -----------------------------------------------------------------------------------
# One directory holding everything the compiler and the tests need. Order of preference:
#   1. KOTLIN_JARS                 (explicit; what CI or another machine should use)
#   2. the local Gradle cache      (works on the machine that has built this project before)
#   3. ~/.m2/repository            (if someone resolved them with Maven)
find_in_cache() {
  local base="$1"; shift
  local p
  for p in "$@"; do
    local hit
    hit="$(find "$base/$p" -name '*.jar' -type f 2>/dev/null | head -1)"
    [[ -n "$hit" ]] && { printf '%s\n' "$hit"; return 0; }
  done
  return 1
}

JARS=()
if [[ -n "${KOTLIN_JARS:-}" ]]; then
  [[ -d "$KOTLIN_JARS" ]] || die "KOTLIN_JARS=$KOTLIN_JARS is not a directory"
  while IFS= read -r j; do JARS+=("$j"); done < <(find "$KOTLIN_JARS" -maxdepth 1 -name '*.jar' | sort)
else
  CACHE="${GRADLE_CACHE:-${GRADLE_USER_HOME:-$HOME/.gradle}/caches/modules-2/files-2.1}"
  M2="${MAVEN_REPO:-$HOME/.m2/repository}"
  for base in "$CACHE" "$M2"; do
    [[ -d "$base" ]] || continue
    for spec in \
      "org.jetbrains.kotlin/kotlin-compiler-embeddable/2.2.21" \
      "org.jetbrains.kotlin/kotlin-stdlib/2.2.21" \
      "org.jetbrains.kotlin/kotlin-reflect" \
      "org.jetbrains.kotlin/kotlin-script-runtime" \
      "org.jetbrains.kotlin/kotlin-daemon-embeddable" \
      "org.jetbrains.kotlinx/kotlinx-coroutines-core-jvm" \
      "org.jetbrains/annotations" \
      "junit/junit/4.13.2" \
      "org.hamcrest/hamcrest-core/1.3" \
      "org.json/json" ; do
      if j="$(find_in_cache "$base" "$spec")"; then JARS+=("$j"); fi
    done
    [[ ${#JARS[@]} -ge 8 ]] && break
    JARS=()
  done
fi
[[ ${#JARS[@]} -gt 0 ]] || die "no jars found; set KOTLIN_JARS to a directory of jars (see the header of this script)"

have() { local n="$1"; for j in "${JARS[@]}"; do [[ "$(basename "$j")" == $n* ]] && return 0; done; return 1; }
have kotlin-compiler-embeddable || die "kotlin-compiler-embeddable missing from the jar set"
have kotlin-stdlib || die "kotlin-stdlib missing from the jar set"
have junit || die "junit missing from the jar set"
have hamcrest-core || die "hamcrest-core missing from the jar set"

TOOL_CP="$(IFS=:; echo "${JARS[*]}")"
LIB_CP="$TOOL_CP"

# ---- sources --------------------------------------------------------------------------------
# The kernel is loop/core plus the loop files that carry no Android types. LoopHardeningTest is
# excluded on purpose: it imports InteractionHub, which needs android.content, so it only compiles
# inside a real Android test runtime.
SOURCES=()
while IFS= read -r f; do SOURCES+=("$f"); done < <(find "$MAIN/loop/core" -name '*.kt' | sort)
for f in loop/EventScheduler.kt loop/KernelMirror.kt loop/LoopDiagnostics.kt loop/LoopEngine.kt \
         loop/LoopEvent.kt loop/LoopStore.kt loop/EventObserver.kt loop/ProtectedForeground.kt \
         phone/Json.kt phone/a11y/ProtectedPages.kt phone/a11y/UiTree.kt; do
  [[ -f "$MAIN/$f" ]] && SOURCES+=("$MAIN/$f")
done
while IFS= read -r f; do SOURCES+=("$f"); done < <(
  find "$TEST/loop" -name '*.kt' ! -name 'LoopHardeningTest.kt' | sort
)

# ---- test classes ----------------------------------------------------------------------------
# Every *Test class under test/loop, with the exception above. Discovered, not hard-coded, so a new
# test file cannot be silently left out of the number this script prints.
CLASSES=()
while IFS= read -r f; do
  pkg="$(grep -m1 '^package ' "$f" | sed 's/^package //; s/[[:space:]]*$//')"
  cls="$(basename "$f" .kt)"
  CLASSES+=("$pkg.$cls")
done < <(find "$TEST/loop" -name '*Test.kt' ! -name 'LoopHardeningTest.kt' | sort)

if [[ "${1:-}" == "--list" ]]; then
  say "sources: ${#SOURCES[@]}"
  printf '%s\n' "${CLASSES[@]}"
  exit 0
fi

OUT="${OUT_DIR:-$ROOT/.kernel-tests}"
rm -rf "$OUT"; mkdir -p "$OUT"

say "java:    $JAVA_BIN"
say "jars:    ${#JARS[@]}"
say "sources: ${#SOURCES[@]}"
say "classes: ${#CLASSES[@]}"
say "compiling..."
set +e
"$JAVA_BIN" -cp "$TOOL_CP" org.jetbrains.kotlin.cli.jvm.K2JVMCompiler \
  -no-stdlib -no-reflect -cp "$LIB_CP" -d "$OUT" "${SOURCES[@]}" > "$OUT/compile.log" 2>&1
rc=$?
set -e
if [[ $rc -ne 0 ]]; then
  say "COMPILE FAIL ($rc) -- see $OUT/compile.log"
  grep -m20 'error:' "$OUT/compile.log" || tail -20 "$OUT/compile.log"
  exit 1
fi
say "compiled"

say "running ${#CLASSES[@]} classes..."
set +e
"$JAVA_BIN" -cp "$OUT:$LIB_CP" org.junit.runner.JUnitCore "${CLASSES[@]}" > "$OUT/test.log" 2>&1
rc=$?
set -e
grep -E '^(OK \(|Tests run:|FAILURES)' "$OUT/test.log" || tail -20 "$OUT/test.log"
if [[ $rc -ne 0 ]]; then
  say "FAIL -- see $OUT/test.log"
  exit $rc
fi
say "PASS"

# ---- W3/F5: production-path guards -------------------------------------------------------------
# The kernel suite above proves the pieces work. It cannot prove the pieces are USED: 24 tests were
# green while three mechanisms had never executed in production once (self-audit B-1/B-2/B-3).
#
# F5: these greps used to run over raw sources, so a line inside a comment satisfied them. A comment
# saying "EnforcementAlert.notify" was enough to pass while the real call had been deleted. Every
# search below now runs over SOURCE WITH COMMENTS STRIPPED.
say "checking production wiring..."
WIRING_FAIL=0
MAIN_DIR="$ROOT/app/android/app/src/main/kotlin"
FAILFILE="$OUT/wiring.fail"
rm -f "$FAILFILE"

# Strip comment-only lines before looking for anything. This is deliberately line-based: it is not
# a Kotlin parser, but no real call statement begins with //, *, or /*.
CODE_ONLY="$OUT/code-only"
rm -rf "$CODE_ONLY"; mkdir -p "$CODE_ONLY"
( cd "$MAIN_DIR" && find . -name "*.kt" -print0 | while IFS= read -r -d "" f; do
    mkdir -p "$CODE_ONLY/$(dirname "$f")"
    grep -v "^[[:space:]]*\(//\|\*\|/\*\)" "$f" > "$CODE_ONLY/$f" 2>/dev/null || true
  done )

# 1. Every InterceptGuard( built in production must name its repository, unless it is the explicit
#    legacy fallback. Match the whole call, not one line: the production call spans several lines.
set +e
while IFS= read -r file; do
  [[ -z "$file" ]] && continue
  while IFS=: read -r ln rest; do
    [[ -z "$ln" ]] && continue
    block=$(sed -n "${ln},$((ln + 14))p" "$CODE_ONLY/$file")
    if ! grep -q "repository" <<<"$block" && ! grep -q "legacy-fallback" <<<"$block"; then
      say "  FAIL: $file:$ln builds InterceptGuard without repository="
      echo 1 > "$FAILFILE"
    fi
  done < <(grep -n "InterceptGuard(" "$CODE_ONLY/$file" 2>/dev/null | grep -v "class InterceptGuard")
done < <(cd "$CODE_ONLY" && grep -rl "InterceptGuard(" . --include="*.kt" 2>/dev/null | sed "s|^\./||")

# 2. A seam whose default "looks like success" is worse than no seam: it answers silently and
#    wrongly. Only the D2 seams are checked by name - a nullable lambda elsewhere (dayKey, labels)
#    legitimately means "no value yet", not "the operation succeeded".
for seam in currentForeground notifyEnforcementUnavailable; do
  hits=$(grep -rn "var $seam.*= { null }\|var $seam.*-> Unit = { }" "$CODE_ONLY" --include="*.kt" 2>/dev/null)
  if [[ -n "$hits" ]]; then
    say "  FAIL: $seam still has a silent default:"
    printf "%s\n" "$hits" | sed "s|$CODE_ONLY/||"
    echo 1 > "$FAILFILE"
  fi
done

# 3. The alert must be reachable AND tappable: a notification nobody can send, or that does nothing
#    when pressed, is the bug this replaces.
if ! grep -rq "EnforcementAlert.notify" "$CODE_ONLY" --include="*.kt" 2>/dev/null; then
  say "  FAIL: nothing calls EnforcementAlert.notify - the person would never be told"
  echo 1 > "$FAILFILE"
fi
if ! grep -rq "EnforcementAlert.launchIntent *=" "$CODE_ONLY" --include="*.kt" 2>/dev/null; then
  say "  FAIL: EnforcementAlert.launchIntent is never assigned - tapping the alert does nothing"
  echo 1 > "$FAILFILE"
fi

# 4. G2: the debug-only failure switch must stay behind a debug gate. The marker file name may only
#    appear inside a function that also tests FLAG_DEBUGGABLE - otherwise a release build could be
#    told to fail every launch, which would silently disable interception.
#
#    The brief asked for "inside a BuildConfig.DEBUG check". This project is on AGP 9.1.0, where
#    BuildConfig is not generated unless buildFeatures.buildConfig is enabled, and build.gradle.kts is
#    not a file this round may edit. ApplicationInfo.FLAG_DEBUGGABLE is set by the build type in the
#    manifest, so it is just as impossible to flip at runtime - the intent is preserved.
if grep -rq "debug-fail-start" "$CODE_ONLY" --include="*.kt" 2>/dev/null; then
  while IFS= read -r file; do
    [[ -z "$file" ]] && continue
    while IFS=: read -r ln rest; do
      [[ -z "$ln" ]] && continue
      window=$(sed -n "$((ln > 8 ? ln - 8 : 1)),$((ln + 2))p" "$CODE_ONLY/$file")
      if ! grep -q "FLAG_DEBUGGABLE" <<<"$window"; then
        say "  FAIL: $file:$ln mentions debug-fail-start outside a FLAG_DEBUGGABLE gate"
        echo 1 > "$FAILFILE"
      fi
    done < <(grep -n "debug-fail-start" "$CODE_ONLY/$file" 2>/dev/null)
  done < <(cd "$CODE_ONLY" && grep -rl "debug-fail-start" . --include="*.kt" 2>/dev/null | sed "s|^\./||")
fi

# 4. The production entry point must go through the kernel factory, not build its own guard.
if ! grep -rq "InterceptKernel.open" "$CODE_ONLY" --include="*.kt" 2>/dev/null; then
  say "  FAIL: nothing calls InterceptKernel.open - the atomic snapshot is not in the production path"
  echo 1 > "$FAILFILE"
fi
set -e
rm -rf "$CODE_ONLY"

if [[ -f "$FAILFILE" ]]; then
  say "WIRING FAIL -- a mechanism exists but is not connected to the production path"
  exit 1
fi
say "wiring OK"
