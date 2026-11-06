#!/bin/bash
# 大肥鱼端到端测试：装真 DSH 引擎（版本锁同 APK）、起假模型、加载 app/assets/engine/plugins 下的五个插件，
# 按手机的调用顺序跑 warm（热会话）→ 重启引擎 → cold（冷会话）。任何一项失败退出码非 0。
# 用法：bash tooling/companion-e2e/run.sh        （需要 node ≥ 22.13、能访问 registry.npmjs.org）
set -u
HERE="$(cd "$(dirname "$0")" && pwd)"; ROOT="$(cd "$HERE/../.." && pwd)"
WORK="${E2E_WORK:-$HERE/.work}"; ENG="$HERE/.engine"; PORT=18080; LLM=18900
export E2E_WORK="$WORK" E2E_BASE="http://127.0.0.1:$PORT"
VER="$(ls "$ROOT/runtime/locks" | grep '^dsh-' | sed 's/^dsh-//' | sort -V | tail -1)"
if [ ! -x "$ENG/node_modules/.bin/dsh" ]; then
  mkdir -p "$ENG" && cp "$ROOT/runtime/locks/dsh-$VER/package"*.json "$ENG/"
  sed -i 's#https://registry.npmmirror.com#https://registry.npmjs.org#g' "$ENG/package-lock.json"
  (cd "$ENG" && npm ci --ignore-scripts --no-audit --no-fund --loglevel=error --registry=https://registry.npmjs.org) || exit 2
fi
rm -rf "$WORK"; mkdir -p "$WORK/home"; : > "$WORK/llm.log"
P="$ROOT/app/assets/engine/plugins"
{ echo "- insert:"; for id in dsh-feiyu-mood dsh-fish-strict dsh-go-memory dsh-go-relationship dsh-go-companion; do
  echo "    - id: $id"; echo "      name: $P/$id/lib/index.js"; done; } > "$WORK/patch.yml"
cleanup() { pkill -f "$HERE/fake-llm.mjs" 2>/dev/null; pkill -f "dsh/lib/bin.js web --patch $WORK" 2>/dev/null; }
trap cleanup EXIT
# 假模型慢 1.5 秒：模拟真机上模型慢，"正在聊"的场景才测得出来。
(FAKE_DELAY_MS=1500 PORT=$LLM node "$HERE/fake-llm.mjs" "$WORK/llm.log" > "$WORK/fake.out" 2>&1 &)
start() {
  pkill -f "dsh/lib/bin.js web --patch $WORK" 2>/dev/null; while pgrep -f "dsh/lib/bin.js web --patch $WORK" >/dev/null; do :; done
  (cd "$WORK" && DSH_HOME="$WORK/home" HOME="$WORK/home" DEEPSEEK_API_KEY=sk-fake DEEPSEEK_BASE_URL="http://127.0.0.1:$LLM" TZ=GMT \
    nohup node "$ENG/node_modules/@deepseek-ai/dsh/lib/bin.js" web --patch "$WORK/patch.yml" --host 127.0.0.1 --port $PORT --no-open > "$WORK/dsh.log" 2>&1 &)
  for i in $(seq 1 300); do grep -q "dsh web: http" "$WORK/dsh.log" 2>/dev/null && break; timeout 0.2 tail -f /dev/null; done
  local t; t=$(grep -o 'token=[^ ]*' "$WORK/dsh.log" | head -1 | cut -d= -f2)
  [ -n "$t" ] || { echo "引擎没起来："; tail -20 "$WORK/dsh.log"; exit 3; }
  curl -s -c "$WORK/c.txt" -o /dev/null "$E2E_BASE/?token=$t"
}
start; node "$HERE/e2e.mjs" warm; A=$?
start; node "$HERE/e2e.mjs" cold; B=$?
echo "引擎日志：$WORK/dsh.log   模型请求：$WORK/llm.log   账本：$WORK/home/companion/ledger.jsonl"
[ $A -eq 0 ] && [ $B -eq 0 ]
