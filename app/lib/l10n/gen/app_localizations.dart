import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:intl/intl.dart' as intl;

import 'app_localizations_en.dart';
import 'app_localizations_zh.dart';

// ignore_for_file: type=lint

/// Callers can lookup localized strings with an instance of L10n
/// returned by `L10n.of(context)`.
///
/// Applications need to include `L10n.delegate()` in their app's
/// `localizationDelegates` list, and the locales they support in the app's
/// `supportedLocales` list. For example:
///
/// ```dart
/// import 'gen/app_localizations.dart';
///
/// return MaterialApp(
///   localizationsDelegates: L10n.localizationsDelegates,
///   supportedLocales: L10n.supportedLocales,
///   home: MyApplicationHome(),
/// );
/// ```
///
/// ## Update pubspec.yaml
///
/// Please make sure to update your pubspec.yaml to include the following
/// packages:
///
/// ```yaml
/// dependencies:
///   # Internationalization support.
///   flutter_localizations:
///     sdk: flutter
///   intl: any # Use the pinned version from flutter_localizations
///
///   # Rest of dependencies
/// ```
///
/// ## iOS Applications
///
/// iOS applications define key application metadata, including supported
/// locales, in an Info.plist file that is built into the application bundle.
/// To configure the locales supported by your app, you’ll need to edit this
/// file.
///
/// First, open your project’s ios/Runner.xcworkspace Xcode workspace file.
/// Then, in the Project Navigator, open the Info.plist file under the Runner
/// project’s Runner folder.
///
/// Next, select the Information Property List item, select Add Item from the
/// Editor menu, then select Localizations from the pop-up menu.
///
/// Select and expand the newly-created Localizations item then, for each
/// locale your application supports, add a new item and select the locale
/// you wish to add from the pop-up menu in the Value field. This list should
/// be consistent with the languages listed in the L10n.supportedLocales
/// property.
abstract class L10n {
  L10n(String locale) : localeName = intl.Intl.canonicalizedLocale(locale.toString());

  final String localeName;

  static L10n of(BuildContext context) {
    return Localizations.of<L10n>(context, L10n)!;
  }

  static const LocalizationsDelegate<L10n> delegate = _L10nDelegate();

  /// A list of this localizations delegate along with the default localizations
  /// delegates.
  ///
  /// Returns a list of localizations delegates containing this delegate along with
  /// GlobalMaterialLocalizations.delegate, GlobalCupertinoLocalizations.delegate,
  /// and GlobalWidgetsLocalizations.delegate.
  ///
  /// Additional delegates can be added by appending to this list in
  /// MaterialApp. This list does not have to be used at all if a custom list
  /// of delegates is preferred or required.
  static const List<LocalizationsDelegate<dynamic>> localizationsDelegates = <LocalizationsDelegate<dynamic>>[
    delegate,
    GlobalMaterialLocalizations.delegate,
    GlobalCupertinoLocalizations.delegate,
    GlobalWidgetsLocalizations.delegate,
  ];

  /// A list of this localizations delegate's supported locales.
  static const List<Locale> supportedLocales = <Locale>[Locale('en'), Locale('zh')];

  /// No description provided for @a11yRestoreTitle.
  ///
  /// In zh, this message translates to:
  /// **'自动恢复无障碍'**
  String get a11yRestoreTitle;

  /// No description provided for @searchKwA11yRestore.
  ///
  /// In zh, this message translates to:
  /// **'无障碍,恢复,重连,自动恢复,掉线,授权,ADB,Shizuku,Sui,root'**
  String get searchKwA11yRestore;

  /// No description provided for @a11yRestoreNeedsGrant.
  ///
  /// In zh, this message translates to:
  /// **'需要授权'**
  String get a11yRestoreNeedsGrant;

  /// No description provided for @a11yRestoreNotice.
  ///
  /// In zh, this message translates to:
  /// **'开启后，在系统设置里关掉无障碍会被自动打开；要关闭手机操控，请在 DSH Go 里关。'**
  String get a11yRestoreNotice;

  /// No description provided for @a11yRestoreForceStop.
  ///
  /// In zh, this message translates to:
  /// **'被强制停止后，重新打开 DSH Go 才能恢复。'**
  String get a11yRestoreForceStop;

  /// No description provided for @a11yRestoreGrant.
  ///
  /// In zh, this message translates to:
  /// **'授权并开启'**
  String get a11yRestoreGrant;

  /// No description provided for @a11yRestoreGrantShizuku.
  ///
  /// In zh, this message translates to:
  /// **'通过 Shizuku 授予'**
  String get a11yRestoreGrantShizuku;

  /// No description provided for @a11yRestoreGrantShizukuPermission.
  ///
  /// In zh, this message translates to:
  /// **'先授权 Shizuku，再授予权限'**
  String get a11yRestoreGrantShizukuPermission;

  /// No description provided for @a11yRestoreGrantAdb.
  ///
  /// In zh, this message translates to:
  /// **'通过自连 ADB 授予'**
  String get a11yRestoreGrantAdb;

  /// No description provided for @a11yRestoreRootNote.
  ///
  /// In zh, this message translates to:
  /// **'通过已授权的 root 连接，只授予这一项权限。'**
  String get a11yRestoreRootNote;

  /// No description provided for @a11yRestoreSetup.
  ///
  /// In zh, this message translates to:
  /// **'配置 Shizuku 或无线调试'**
  String get a11yRestoreSetup;

  /// No description provided for @a11yRestoreWaiting.
  ///
  /// In zh, this message translates to:
  /// **'请在 Shizuku 中允许授权'**
  String get a11yRestoreWaiting;

  /// No description provided for @a11yRestoreWaitingSui.
  ///
  /// In zh, this message translates to:
  /// **'请在 Sui 中允许授权'**
  String get a11yRestoreWaitingSui;

  /// No description provided for @a11yRestoreComputer.
  ///
  /// In zh, this message translates to:
  /// **'也可以连接电脑，执行一次：'**
  String get a11yRestoreComputer;

  /// No description provided for @a11yRestoreCopy.
  ///
  /// In zh, this message translates to:
  /// **'复制授权命令'**
  String get a11yRestoreCopy;

  /// No description provided for @a11yRestoreCopied.
  ///
  /// In zh, this message translates to:
  /// **'授权命令已复制'**
  String get a11yRestoreCopied;

  /// No description provided for @accessPickTitle.
  ///
  /// In zh, this message translates to:
  /// **'想让 DSH Go 帮你做哪些事'**
  String get accessPickTitle;

  /// No description provided for @accessPickMessage.
  ///
  /// In zh, this message translates to:
  /// **'选好后逐项开启'**
  String get accessPickMessage;

  /// No description provided for @accessPickConfirm.
  ///
  /// In zh, this message translates to:
  /// **'开启所选'**
  String get accessPickConfirm;

  /// No description provided for @accessSkip.
  ///
  /// In zh, this message translates to:
  /// **'跳过'**
  String get accessSkip;

  /// No description provided for @accessFeatureFiles.
  ///
  /// In zh, this message translates to:
  /// **'读写手机里的文件'**
  String get accessFeatureFiles;

  /// No description provided for @accessFeatureFilesNeeds.
  ///
  /// In zh, this message translates to:
  /// **'需要文件访问权限'**
  String get accessFeatureFilesNeeds;

  /// No description provided for @accessFeaturePet.
  ///
  /// In zh, this message translates to:
  /// **'桌宠与悬浮窗'**
  String get accessFeaturePet;

  /// No description provided for @accessFeaturePetNeeds.
  ///
  /// In zh, this message translates to:
  /// **'需要悬浮窗权限'**
  String get accessFeaturePetNeeds;

  /// No description provided for @accessFeaturePhone.
  ///
  /// In zh, this message translates to:
  /// **'手机操控'**
  String get accessFeaturePhone;

  /// No description provided for @accessFeaturePhoneNeeds.
  ///
  /// In zh, this message translates to:
  /// **'需要无障碍和通知权限'**
  String get accessFeaturePhoneNeeds;

  /// No description provided for @accessFeatureBackground.
  ///
  /// In zh, this message translates to:
  /// **'后台持续运行'**
  String get accessFeatureBackground;

  /// No description provided for @accessFeatureBackgroundNeeds.
  ///
  /// In zh, this message translates to:
  /// **'任务跑完通知你，需要通知和后台权限'**
  String get accessFeatureBackgroundNeeds;

  /// No description provided for @accessFeatureVoice.
  ///
  /// In zh, this message translates to:
  /// **'语音输入'**
  String get accessFeatureVoice;

  /// No description provided for @accessFeatureVoiceNeeds.
  ///
  /// In zh, this message translates to:
  /// **'需要麦克风权限'**
  String get accessFeatureVoiceNeeds;

  /// No description provided for @accessVoiceModel.
  ///
  /// In zh, this message translates to:
  /// **'离线识别，需下载约 {size} MB 语音模型'**
  String accessVoiceModel(int size);

  /// No description provided for @accessVoiceMetered.
  ///
  /// In zh, this message translates to:
  /// **'当前是移动数据，下载会消耗流量'**
  String get accessVoiceMetered;

  /// No description provided for @accessFilesRiskBody.
  ///
  /// In zh, this message translates to:
  /// **'AI 能读取和修改相册、下载、文档等手机文件。'**
  String get accessFilesRiskBody;

  /// No description provided for @accessStepCount.
  ///
  /// In zh, this message translates to:
  /// **'{index} / {total}'**
  String accessStepCount(int index, int total);

  /// No description provided for @accessTurnOn.
  ///
  /// In zh, this message translates to:
  /// **'去开启'**
  String get accessTurnOn;

  /// No description provided for @accessOpenSettings.
  ///
  /// In zh, this message translates to:
  /// **'去设置'**
  String get accessOpenSettings;

  /// No description provided for @accessItsSet.
  ///
  /// In zh, this message translates to:
  /// **'设好了'**
  String get accessItsSet;

  /// No description provided for @accessOpenAgain.
  ///
  /// In zh, this message translates to:
  /// **'再去一次'**
  String get accessOpenAgain;

  /// No description provided for @accessIsOn.
  ///
  /// In zh, this message translates to:
  /// **'已开启'**
  String get accessIsOn;

  /// No description provided for @accessNotOnYet.
  ///
  /// In zh, this message translates to:
  /// **'还没开启'**
  String get accessNotOnYet;

  /// No description provided for @accessDidYouSet.
  ///
  /// In zh, this message translates to:
  /// **'在那一页打开了吗？'**
  String get accessDidYouSet;

  /// No description provided for @accessWhere.
  ///
  /// In zh, this message translates to:
  /// **'位置：{path}'**
  String accessWhere(String path);

  /// No description provided for @accessOpenFailed.
  ///
  /// In zh, this message translates to:
  /// **'没能打开系统设置'**
  String get accessOpenFailed;

  /// No description provided for @accessMicTitle.
  ///
  /// In zh, this message translates to:
  /// **'允许使用麦克风'**
  String get accessMicTitle;

  /// No description provided for @accessMicWhy.
  ///
  /// In zh, this message translates to:
  /// **'语音输入要用到'**
  String get accessMicWhy;

  /// No description provided for @accessStorageTitle.
  ///
  /// In zh, this message translates to:
  /// **'允许访问文件'**
  String get accessStorageTitle;

  /// No description provided for @accessStorageWhy.
  ///
  /// In zh, this message translates to:
  /// **'让 AI 读写相册、下载和文档'**
  String get accessStorageWhy;

  /// No description provided for @accessNotifyTitle.
  ///
  /// In zh, this message translates to:
  /// **'允许通知'**
  String get accessNotifyTitle;

  /// No description provided for @accessNotifyWhy.
  ///
  /// In zh, this message translates to:
  /// **'任务跑完、需要确认时提醒你'**
  String get accessNotifyWhy;

  /// No description provided for @accessBatteryTitle.
  ///
  /// In zh, this message translates to:
  /// **'允许在后台运行'**
  String get accessBatteryTitle;

  /// No description provided for @accessBatteryWhy.
  ///
  /// In zh, this message translates to:
  /// **'切到别的 App 时任务照常跑'**
  String get accessBatteryWhy;

  /// No description provided for @accessVendorBackgroundWhy.
  ///
  /// In zh, this message translates to:
  /// **'锁屏或切走后，不被系统断网、清理'**
  String get accessVendorBackgroundWhy;

  /// No description provided for @accessAutostartTitle.
  ///
  /// In zh, this message translates to:
  /// **'允许自启动'**
  String get accessAutostartTitle;

  /// No description provided for @accessAutostartWhy.
  ///
  /// In zh, this message translates to:
  /// **'被系统清理后能自己恢复'**
  String get accessAutostartWhy;

  /// No description provided for @accessVivoAutostartPath.
  ///
  /// In zh, this message translates to:
  /// **'权限管理 › 自启动 › {app}'**
  String accessVivoAutostartPath(String app);

  /// No description provided for @accessXiaomiAutostartPath.
  ///
  /// In zh, this message translates to:
  /// **'应用管理 › {app} › 自启动'**
  String accessXiaomiAutostartPath(String app);

  /// No description provided for @accessA11yTitle.
  ///
  /// In zh, this message translates to:
  /// **'打开无障碍'**
  String get accessA11yTitle;

  /// No description provided for @accessA11yWhy.
  ///
  /// In zh, this message translates to:
  /// **'手机操控靠它看屏幕、点按'**
  String get accessA11yWhy;

  /// No description provided for @accessPopupTitle.
  ///
  /// In zh, this message translates to:
  /// **'允许后台弹出界面'**
  String get accessPopupTitle;

  /// No description provided for @accessPopupWhy.
  ///
  /// In zh, this message translates to:
  /// **'手机操控做完能回到 DSH Go'**
  String get accessPopupWhy;

  /// No description provided for @accessVivoPopupPath.
  ///
  /// In zh, this message translates to:
  /// **'权限管理 › {app} › 后台弹出界面'**
  String accessVivoPopupPath(String app);

  /// No description provided for @accessXiaomiPopupPath.
  ///
  /// In zh, this message translates to:
  /// **'应用管理 › {app} › 其他权限 › 后台弹出界面'**
  String accessXiaomiPopupPath(String app);

  /// No description provided for @accessOverlayTitle.
  ///
  /// In zh, this message translates to:
  /// **'允许显示在其他应用上层'**
  String get accessOverlayTitle;

  /// No description provided for @accessOverlayWhy.
  ///
  /// In zh, this message translates to:
  /// **'宠物才能出现在别的 App 上'**
  String get accessOverlayWhy;

  /// No description provided for @accessOverlayGreyed.
  ///
  /// In zh, this message translates to:
  /// **'开关是灰的？'**
  String get accessOverlayGreyed;

  /// No description provided for @accessRestrictedTitle.
  ///
  /// In zh, this message translates to:
  /// **'先允许受限制的设置'**
  String get accessRestrictedTitle;

  /// No description provided for @accessRestrictedTap.
  ///
  /// In zh, this message translates to:
  /// **'在无障碍里点一下「DSH 手机操控」，出现「受限制的设置」时点确定'**
  String get accessRestrictedTap;

  /// No description provided for @accessRestrictedMenu.
  ///
  /// In zh, this message translates to:
  /// **'在应用信息里点右上角的三个点，选「允许受限制的设置」'**
  String get accessRestrictedMenu;

  /// No description provided for @accessRestrictedAdvanced.
  ///
  /// In zh, this message translates to:
  /// **'在应用信息的「高级设置」里打开「允许受限制的设置」'**
  String get accessRestrictedAdvanced;

  /// No description provided for @accessRestrictedBack.
  ///
  /// In zh, this message translates to:
  /// **'回到无障碍，打开「DSH 手机操控」'**
  String get accessRestrictedBack;

  /// No description provided for @accessRestrictedHelp.
  ///
  /// In zh, this message translates to:
  /// **'看图示'**
  String get accessRestrictedHelp;

  /// No description provided for @accessOpenA11y.
  ///
  /// In zh, this message translates to:
  /// **'去无障碍'**
  String get accessOpenA11y;

  /// No description provided for @accessOpenAppInfo.
  ///
  /// In zh, this message translates to:
  /// **'去应用信息'**
  String get accessOpenAppInfo;

  /// No description provided for @accessStateOn.
  ///
  /// In zh, this message translates to:
  /// **'已开启'**
  String get accessStateOn;

  /// No description provided for @accessStateOff.
  ///
  /// In zh, this message translates to:
  /// **'未开启'**
  String get accessStateOff;

  /// No description provided for @accessStateVisited.
  ///
  /// In zh, this message translates to:
  /// **'已去设置'**
  String get accessStateVisited;

  /// No description provided for @accessStateUnknown.
  ///
  /// In zh, this message translates to:
  /// **'去设置'**
  String get accessStateUnknown;

  /// No description provided for @accessSummaryAllSet.
  ///
  /// In zh, this message translates to:
  /// **'都开好了'**
  String get accessSummaryAllSet;

  /// No description provided for @accessSummaryLeft.
  ///
  /// In zh, this message translates to:
  /// **'还有 {count} 项没开'**
  String accessSummaryLeft(int count);

  /// No description provided for @accessSummaryMessage.
  ///
  /// In zh, this message translates to:
  /// **'随时可在「设置 › 通用 › 系统权限」补开'**
  String get accessSummaryMessage;

  /// No description provided for @accessFinishFailed.
  ///
  /// In zh, this message translates to:
  /// **'没能完成设置'**
  String get accessFinishFailed;

  /// No description provided for @accessVoiceDownload.
  ///
  /// In zh, this message translates to:
  /// **'语音模型（约 {size} MB）会在引擎就绪后开始下载，进度在「设置 › 通用 › 语音输入」里查看'**
  String accessVoiceDownload(int size);

  /// No description provided for @accessPageTitle.
  ///
  /// In zh, this message translates to:
  /// **'系统权限'**
  String get accessPageTitle;

  /// No description provided for @accessPageSubtitle.
  ///
  /// In zh, this message translates to:
  /// **'各项功能用到的系统权限'**
  String get accessPageSubtitle;

  /// No description provided for @activityThinkingUntangle.
  ///
  /// In zh, this message translates to:
  /// **'嗯…让我捋捋'**
  String get activityThinkingUntangle;

  /// No description provided for @activityThinkingWorkThrough.
  ///
  /// In zh, this message translates to:
  /// **'盘一下盘一下'**
  String get activityThinkingWorkThrough;

  /// No description provided for @activityThinkingGears.
  ///
  /// In zh, this message translates to:
  /// **'大脑转起来了'**
  String get activityThinkingGears;

  /// No description provided for @activityThinkingSecond.
  ///
  /// In zh, this message translates to:
  /// **'给我一秒'**
  String get activityThinkingSecond;

  /// No description provided for @activityThinkingSmoking.
  ///
  /// In zh, this message translates to:
  /// **'脑子在冒烟'**
  String get activityThinkingSmoking;

  /// No description provided for @activityThinkingOnIt.
  ///
  /// In zh, this message translates to:
  /// **'想呢想呢'**
  String get activityThinkingOnIt;

  /// No description provided for @activityThinkingNoRush.
  ///
  /// In zh, this message translates to:
  /// **'别催别催'**
  String get activityThinkingNoRush;

  /// No description provided for @activityThinkingPonder.
  ///
  /// In zh, this message translates to:
  /// **'让我琢磨下'**
  String get activityThinkingPonder;

  /// No description provided for @activityThinkingLogic.
  ///
  /// In zh, this message translates to:
  /// **'正在盘逻辑'**
  String get activityThinkingLogic;

  /// No description provided for @activityThinkingBrain.
  ///
  /// In zh, this message translates to:
  /// **'小脑瓜动一下'**
  String get activityThinkingBrain;

  /// No description provided for @activityThinkingSort.
  ///
  /// In zh, this message translates to:
  /// **'让我理理'**
  String get activityThinkingSort;

  /// No description provided for @activityThinkingMemory.
  ///
  /// In zh, this message translates to:
  /// **'翻翻脑子'**
  String get activityThinkingMemory;

  /// No description provided for @activityThinkingStorm.
  ///
  /// In zh, this message translates to:
  /// **'脑内风暴中'**
  String get activityThinkingStorm;

  /// No description provided for @activityThinkingSavor.
  ///
  /// In zh, this message translates to:
  /// **'嗯…让我品品'**
  String get activityThinkingSavor;

  /// No description provided for @activityThinkingMoment.
  ///
  /// In zh, this message translates to:
  /// **'稍等，在想'**
  String get activityThinkingMoment;

  /// No description provided for @activityThinkingHeadScratch.
  ///
  /// In zh, this message translates to:
  /// **'挠头…'**
  String get activityThinkingHeadScratch;

  /// No description provided for @activityThinkingPlayOut.
  ///
  /// In zh, this message translates to:
  /// **'让子弹飞一会'**
  String get activityThinkingPlayOut;

  /// No description provided for @activityThinkingLoading.
  ///
  /// In zh, this message translates to:
  /// **'思路加载中'**
  String get activityThinkingLoading;

  /// No description provided for @activityThinkingMulling.
  ///
  /// In zh, this message translates to:
  /// **'琢磨中'**
  String get activityThinkingMulling;

  /// No description provided for @activityThinkingBreakDown.
  ///
  /// In zh, this message translates to:
  /// **'嗯…让我拆一下'**
  String get activityThinkingBreakDown;

  /// No description provided for @activityThinkingTrain.
  ///
  /// In zh, this message translates to:
  /// **'脑内跑火车'**
  String get activityThinkingTrain;

  /// No description provided for @activityThinkingSomething.
  ///
  /// In zh, this message translates to:
  /// **'嗯…有点东西'**
  String get activityThinkingSomething;

  /// No description provided for @activityThinkingJog.
  ///
  /// In zh, this message translates to:
  /// **'小跑一下思路'**
  String get activityThinkingJog;

  /// No description provided for @activityThinkingPicture.
  ///
  /// In zh, this message translates to:
  /// **'等下，有画面了'**
  String get activityThinkingPicture;

  /// No description provided for @activityThinkingBubbles.
  ///
  /// In zh, this message translates to:
  /// **'思考泡泡'**
  String get activityThinkingBubbles;

  /// No description provided for @activityThinkingWaves.
  ///
  /// In zh, this message translates to:
  /// **'脑电波传输中'**
  String get activityThinkingWaves;

  /// No description provided for @activityThinkingCoffee.
  ///
  /// In zh, this message translates to:
  /// **'脑子在煮咖啡'**
  String get activityThinkingCoffee;

  /// No description provided for @activityThinkingDraft.
  ///
  /// In zh, this message translates to:
  /// **'我打个腹稿'**
  String get activityThinkingDraft;

  /// No description provided for @activityThinkingComing.
  ///
  /// In zh, this message translates to:
  /// **'嗯，来了来了'**
  String get activityThinkingComing;

  /// No description provided for @activityThinkingBubbling.
  ///
  /// In zh, this message translates to:
  /// **'脑子冒泡泡'**
  String get activityThinkingBubbling;

  /// No description provided for @activityThinkingTackle.
  ///
  /// In zh, this message translates to:
  /// **'嗯…盘它'**
  String get activityThinkingTackle;

  /// No description provided for @activityThinkingSpark.
  ///
  /// In zh, this message translates to:
  /// **'闪个思路'**
  String get activityThinkingSpark;

  /// No description provided for @activityThinkingLogicFirst.
  ///
  /// In zh, this message translates to:
  /// **'先捋一下逻辑'**
  String get activityThinkingLogicFirst;

  /// No description provided for @activityThinkingLocate.
  ///
  /// In zh, this message translates to:
  /// **'定位一下'**
  String get activityThinkingLocate;

  /// No description provided for @activityThinkingInvestigate.
  ///
  /// In zh, this message translates to:
  /// **'排查一下'**
  String get activityThinkingInvestigate;

  /// No description provided for @activityThinkingGif.
  ///
  /// In zh, this message translates to:
  /// **'思考.gif'**
  String get activityThinkingGif;

  /// No description provided for @activityThinkingLook.
  ///
  /// In zh, this message translates to:
  /// **'让我康康'**
  String get activityThinkingLook;

  /// No description provided for @activityThinkingInteresting.
  ///
  /// In zh, this message translates to:
  /// **'嗯…有点意思'**
  String get activityThinkingInteresting;

  /// No description provided for @activityThinkingHands.
  ///
  /// In zh, this message translates to:
  /// **'搓搓手想想'**
  String get activityThinkingHands;

  /// No description provided for @activityThinkingFiveMinutes.
  ///
  /// In zh, this message translates to:
  /// **'5 分钟，大工程'**
  String get activityThinkingFiveMinutes;

  /// No description provided for @activityThinkingSerious.
  ///
  /// In zh, this message translates to:
  /// **'这把我得认真'**
  String get activityThinkingSerious;

  /// No description provided for @activityThinkingTricky.
  ///
  /// In zh, this message translates to:
  /// **'确实有点绕'**
  String get activityThinkingTricky;

  /// No description provided for @activityThinkingAscend.
  ///
  /// In zh, this message translates to:
  /// **'我在修仙'**
  String get activityThinkingAscend;

  /// No description provided for @activityThinkingAlmostPromise.
  ///
  /// In zh, this message translates to:
  /// **'快好了，真的'**
  String get activityThinkingAlmostPromise;

  /// No description provided for @activityThinkingLongWay.
  ///
  /// In zh, this message translates to:
  /// **'盘了一大圈'**
  String get activityThinkingLongWay;

  /// No description provided for @activityThinkingWrapping.
  ///
  /// In zh, this message translates to:
  /// **'在收尾了'**
  String get activityThinkingWrapping;

  /// No description provided for @activityThinkingSong.
  ///
  /// In zh, this message translates to:
  /// **'给我一首歌的时间'**
  String get activityThinkingSong;

  /// No description provided for @activityThinkingBigMove.
  ///
  /// In zh, this message translates to:
  /// **'憋大招中'**
  String get activityThinkingBigMove;

  /// No description provided for @activityThinkingSimple.
  ///
  /// In zh, this message translates to:
  /// **'这个需求很简单（不是）'**
  String get activityThinkingSimple;

  /// No description provided for @activityThinkingOneMinute.
  ///
  /// In zh, this message translates to:
  /// **'1 分钟，还在想'**
  String get activityThinkingOneMinute;

  /// No description provided for @activityThinkingChallenge.
  ///
  /// In zh, this message translates to:
  /// **'这题有点东西'**
  String get activityThinkingChallenge;

  /// No description provided for @activityThinkingDig.
  ///
  /// In zh, this message translates to:
  /// **'让我再钻研下'**
  String get activityThinkingDig;

  /// No description provided for @activityThinkingNotSimple.
  ///
  /// In zh, this message translates to:
  /// **'问题不简单'**
  String get activityThinkingNotSimple;

  /// No description provided for @activityThinkingDeep.
  ///
  /// In zh, this message translates to:
  /// **'盘得有点深'**
  String get activityThinkingDeep;

  /// No description provided for @activityThinkingBurning.
  ///
  /// In zh, this message translates to:
  /// **'脑细胞在燃烧'**
  String get activityThinkingBurning;

  /// No description provided for @activityThinkingNearlyClear.
  ///
  /// In zh, this message translates to:
  /// **'快盘清了'**
  String get activityThinkingNearlyClear;

  /// No description provided for @activityThinkingTwisty.
  ///
  /// In zh, this message translates to:
  /// **'这个有点绕…'**
  String get activityThinkingTwisty;

  /// No description provided for @activityThinkingWorkout.
  ///
  /// In zh, this message translates to:
  /// **'烧脑中…'**
  String get activityThinkingWorkout;

  /// No description provided for @activityThinkingStay.
  ///
  /// In zh, this message translates to:
  /// **'别走，快了'**
  String get activityThinkingStay;

  /// No description provided for @activityThinkingCloser.
  ///
  /// In zh, this message translates to:
  /// **'嗯，让我细想想'**
  String get activityThinkingCloser;

  /// No description provided for @activityThinkingThirtySeconds.
  ///
  /// In zh, this message translates to:
  /// **'30 秒了，还在盘'**
  String get activityThinkingThirtySeconds;

  /// No description provided for @activityThinkingSoon.
  ///
  /// In zh, this message translates to:
  /// **'别急，快出结果了'**
  String get activityThinkingSoon;

  /// No description provided for @activityThinkingAnotherPass.
  ///
  /// In zh, this message translates to:
  /// **'让我再捋一捋'**
  String get activityThinkingAnotherPass;

  /// No description provided for @activityThinkingTrack.
  ///
  /// In zh, this message translates to:
  /// **'思路没断'**
  String get activityThinkingTrack;

  /// No description provided for @activityThinkingLead.
  ///
  /// In zh, this message translates to:
  /// **'有眉目了'**
  String get activityThinkingLead;

  /// No description provided for @activityThinkingCircles.
  ///
  /// In zh, this message translates to:
  /// **'转圈圈…'**
  String get activityThinkingCircles;

  /// No description provided for @activityThinkingAnyMoment.
  ///
  /// In zh, this message translates to:
  /// **'马上马上'**
  String get activityThinkingAnyMoment;

  /// No description provided for @activityThinkingStillLocate.
  ///
  /// In zh, this message translates to:
  /// **'还在定位'**
  String get activityThinkingStillLocate;

  /// No description provided for @activityWaitingCall.
  ///
  /// In zh, this message translates to:
  /// **'呼叫模型…'**
  String get activityWaitingCall;

  /// No description provided for @activityWaitingOnWay.
  ///
  /// In zh, this message translates to:
  /// **'模型在路上了'**
  String get activityWaitingOnWay;

  /// No description provided for @activityWaitingSpeak.
  ///
  /// In zh, this message translates to:
  /// **'等它开口…'**
  String get activityWaitingSpeak;

  /// No description provided for @activityWaitingWords.
  ///
  /// In zh, this message translates to:
  /// **'它在组织语言'**
  String get activityWaitingWords;

  /// No description provided for @activityWaitingAwake.
  ///
  /// In zh, this message translates to:
  /// **'模型醒了么'**
  String get activityWaitingAwake;

  /// No description provided for @activityWaitingStretch.
  ///
  /// In zh, this message translates to:
  /// **'等它伸懒腰'**
  String get activityWaitingStretch;

  /// No description provided for @activityWaitingYawn.
  ///
  /// In zh, this message translates to:
  /// **'它打了个哈欠'**
  String get activityWaitingYawn;

  /// No description provided for @activityWaitingComing.
  ///
  /// In zh, this message translates to:
  /// **'模型：来了来了'**
  String get activityWaitingComing;

  /// No description provided for @activityWaitingText.
  ///
  /// In zh, this message translates to:
  /// **'等它出字'**
  String get activityWaitingText;

  /// No description provided for @activityWaitingQueue.
  ///
  /// In zh, this message translates to:
  /// **'还在排队'**
  String get activityWaitingQueue;

  /// No description provided for @activityWaitingBrew.
  ///
  /// In zh, this message translates to:
  /// **'它在酝酿'**
  String get activityWaitingBrew;

  /// No description provided for @activityWaitingWater.
  ///
  /// In zh, this message translates to:
  /// **'模型在喝水'**
  String get activityWaitingWater;

  /// No description provided for @activityWaitingWarmup.
  ///
  /// In zh, this message translates to:
  /// **'等它热身'**
  String get activityWaitingWarmup;

  /// No description provided for @activityWaitingMeditate.
  ///
  /// In zh, this message translates to:
  /// **'模型在冥想'**
  String get activityWaitingMeditate;

  /// No description provided for @activityWaitingBlink.
  ///
  /// In zh, this message translates to:
  /// **'等它眨个眼'**
  String get activityWaitingBlink;

  /// No description provided for @activityWaitingMoment.
  ///
  /// In zh, this message translates to:
  /// **'它说稍等'**
  String get activityWaitingMoment;

  /// No description provided for @activityWritingWords.
  ///
  /// In zh, this message translates to:
  /// **'组织语言中'**
  String get activityWritingWords;

  /// No description provided for @activityWritingTyping.
  ///
  /// In zh, this message translates to:
  /// **'码字中'**
  String get activityWritingTyping;

  /// No description provided for @activityWritingInspired.
  ///
  /// In zh, this message translates to:
  /// **'下笔如有神'**
  String get activityWritingInspired;

  /// No description provided for @activityWritingOnIt.
  ///
  /// In zh, this message translates to:
  /// **'在写了在写了'**
  String get activityWritingOnIt;

  /// No description provided for @activityWritingCareful.
  ///
  /// In zh, this message translates to:
  /// **'字斟句酌'**
  String get activityWritingCareful;

  /// No description provided for @activityWritingFlow.
  ///
  /// In zh, this message translates to:
  /// **'一气呵成'**
  String get activityWritingFlow;

  /// No description provided for @activityWritingPlain.
  ///
  /// In zh, this message translates to:
  /// **'整理成人话'**
  String get activityWritingPlain;

  /// No description provided for @activityWritingIdeas.
  ///
  /// In zh, this message translates to:
  /// **'把想法写下来'**
  String get activityWritingIdeas;

  /// No description provided for @activityWritingKeys.
  ///
  /// In zh, this message translates to:
  /// **'敲字中'**
  String get activityWritingKeys;

  /// No description provided for @activityWritingAlmost.
  ///
  /// In zh, this message translates to:
  /// **'马上写完'**
  String get activityWritingAlmost;

  /// No description provided for @activityWritingTell.
  ///
  /// In zh, this message translates to:
  /// **'娓娓道来'**
  String get activityWritingTell;

  /// No description provided for @activityWritingFast.
  ///
  /// In zh, this message translates to:
  /// **'奋笔疾书'**
  String get activityWritingFast;

  /// No description provided for @activityWritingBreeze.
  ///
  /// In zh, this message translates to:
  /// **'笔下生风'**
  String get activityWritingBreeze;

  /// No description provided for @activityWritingFormat.
  ///
  /// In zh, this message translates to:
  /// **'排个版'**
  String get activityWritingFormat;

  /// No description provided for @activityNightAscend.
  ///
  /// In zh, this message translates to:
  /// **'修仙中…'**
  String get activityNightAscend;

  /// No description provided for @activityNightHello.
  ///
  /// In zh, this message translates to:
  /// **'深夜冒泡'**
  String get activityNightHello;

  /// No description provided for @activityNightOwl.
  ///
  /// In zh, this message translates to:
  /// **'你也是夜猫子呀'**
  String get activityNightOwl;

  /// No description provided for @activityNightMoon.
  ///
  /// In zh, this message translates to:
  /// **'月亮不睡我不睡'**
  String get activityNightMoon;

  /// No description provided for @activityNightSlow.
  ///
  /// In zh, this message translates to:
  /// **'夜里脑子慢，谅解'**
  String get activityNightSlow;

  /// No description provided for @activityNightChampion.
  ///
  /// In zh, this message translates to:
  /// **'熬夜冠军上线'**
  String get activityNightChampion;

  /// No description provided for @activityNightSleepy.
  ///
  /// In zh, this message translates to:
  /// **'困了，但能行'**
  String get activityNightSleepy;

  /// No description provided for @activityNightMidnight.
  ///
  /// In zh, this message translates to:
  /// **'过了零点照样肝'**
  String get activityNightMidnight;

  /// No description provided for @activityNightOpen.
  ///
  /// In zh, this message translates to:
  /// **'深夜档营业'**
  String get activityNightOpen;

  /// No description provided for @activityNightStars.
  ///
  /// In zh, this message translates to:
  /// **'星星都睡了'**
  String get activityNightStars;

  /// No description provided for @activityNightDawn.
  ///
  /// In zh, this message translates to:
  /// **'凌晨还在盘'**
  String get activityNightDawn;

  /// No description provided for @activityWeekendChill.
  ///
  /// In zh, this message translates to:
  /// **'周末摸鱼中'**
  String get activityWeekendChill;

  /// No description provided for @activityWeekendHere.
  ///
  /// In zh, this message translates to:
  /// **'周末也在！'**
  String get activityWeekendHere;

  /// No description provided for @activityWeekendCompany.
  ///
  /// In zh, this message translates to:
  /// **'放假也陪你'**
  String get activityWeekendCompany;

  /// No description provided for @activityWeekendOnline.
  ///
  /// In zh, this message translates to:
  /// **'周末不关机'**
  String get activityWeekendOnline;

  /// No description provided for @activityWeekendSneak.
  ///
  /// In zh, this message translates to:
  /// **'周末偷着盘'**
  String get activityWeekendSneak;

  /// No description provided for @activityWeekendWorking.
  ///
  /// In zh, this message translates to:
  /// **'周末也在卷？'**
  String get activityWeekendWorking;

  /// No description provided for @activityWeekendMode.
  ///
  /// In zh, this message translates to:
  /// **'周末模式 ON'**
  String get activityWeekendMode;

  /// No description provided for @activityWeekendBugs.
  ///
  /// In zh, this message translates to:
  /// **'周末在修 bug'**
  String get activityWeekendBugs;

  /// No description provided for @activityWeekendSkin.
  ///
  /// In zh, this message translates to:
  /// **'周末限定皮肤'**
  String get activityWeekendSkin;

  /// No description provided for @activityNewYearCheers.
  ///
  /// In zh, this message translates to:
  /// **'新年快乐！'**
  String get activityNewYearCheers;

  /// No description provided for @activityNewYearDay.
  ///
  /// In zh, this message translates to:
  /// **'元旦快乐'**
  String get activityNewYearDay;

  /// No description provided for @activityNewYearBugs.
  ///
  /// In zh, this message translates to:
  /// **'新的一年，新的 bug'**
  String get activityNewYearBugs;

  /// No description provided for @activityNewYearFirstLine.
  ///
  /// In zh, this message translates to:
  /// **'新年第一行代码'**
  String get activityNewYearFirstLine;

  /// No description provided for @activityNewYearWork.
  ///
  /// In zh, this message translates to:
  /// **'开工大吉'**
  String get activityNewYearWork;

  /// No description provided for @activityValentineCode.
  ///
  /// In zh, this message translates to:
  /// **'情人节也在敲代码'**
  String get activityValentineCode;

  /// No description provided for @activityValentineLove.
  ///
  /// In zh, this message translates to:
  /// **'代码才是真爱'**
  String get activityValentineLove;

  /// No description provided for @activityValentineDate.
  ///
  /// In zh, this message translates to:
  /// **'今天不约会？'**
  String get activityValentineDate;

  /// No description provided for @activityValentineKeyboard.
  ///
  /// In zh, this message translates to:
  /// **'键盘就是玫瑰'**
  String get activityValentineKeyboard;

  /// No description provided for @activityPiDay.
  ///
  /// In zh, this message translates to:
  /// **'π 节快乐'**
  String get activityPiDay;

  /// No description provided for @activityPiCircle.
  ///
  /// In zh, this message translates to:
  /// **'今天的圆格外圆'**
  String get activityPiCircle;

  /// No description provided for @activityAprilFools.
  ///
  /// In zh, this message translates to:
  /// **'愚人节快乐'**
  String get activityAprilFools;

  /// No description provided for @activityAprilBug.
  ///
  /// In zh, this message translates to:
  /// **'这个 bug 是假的吧'**
  String get activityAprilBug;

  /// No description provided for @activityAprilErrors.
  ///
  /// In zh, this message translates to:
  /// **'小心假报错'**
  String get activityAprilErrors;

  /// No description provided for @activityAprilKidding.
  ///
  /// In zh, this message translates to:
  /// **'骗你的，没报错'**
  String get activityAprilKidding;

  /// No description provided for @activityLaborWorking.
  ///
  /// In zh, this message translates to:
  /// **'劳动节还在卷'**
  String get activityLaborWorking;

  /// No description provided for @activityLaborPride.
  ///
  /// In zh, this message translates to:
  /// **'劳动最光荣'**
  String get activityLaborPride;

  /// No description provided for @activityLaborSpirit.
  ///
  /// In zh, this message translates to:
  /// **'打工人打工魂'**
  String get activityLaborSpirit;

  /// No description provided for @activityChildrenDay.
  ///
  /// In zh, this message translates to:
  /// **'儿童节快乐'**
  String get activityChildrenDay;

  /// No description provided for @activityChildrenHeart.
  ///
  /// In zh, this message translates to:
  /// **'谁还不是个宝宝'**
  String get activityChildrenHeart;

  /// No description provided for @activityChildrenCode.
  ///
  /// In zh, this message translates to:
  /// **'今天代码要写得可爱'**
  String get activityChildrenCode;

  /// No description provided for @activityProgrammerCheers.
  ///
  /// In zh, this message translates to:
  /// **'1024 程序员节快乐'**
  String get activityProgrammerCheers;

  /// No description provided for @activityProgrammerDay.
  ///
  /// In zh, this message translates to:
  /// **'今天是程序员节'**
  String get activityProgrammerDay;

  /// No description provided for @activityProgrammer1024.
  ///
  /// In zh, this message translates to:
  /// **'1024，节日快乐'**
  String get activityProgrammer1024;

  /// No description provided for @activityProgrammerCode.
  ///
  /// In zh, this message translates to:
  /// **'程序员节也在写代码'**
  String get activityProgrammerCode;

  /// No description provided for @activityHalloween.
  ///
  /// In zh, this message translates to:
  /// **'万圣节快乐'**
  String get activityHalloween;

  /// No description provided for @activityHalloweenTreat.
  ///
  /// In zh, this message translates to:
  /// **'不给糖就捣蛋'**
  String get activityHalloweenTreat;

  /// No description provided for @activityHalloweenCode.
  ///
  /// In zh, this message translates to:
  /// **'代码也会吓人'**
  String get activityHalloweenCode;

  /// No description provided for @activityChristmasEve.
  ///
  /// In zh, this message translates to:
  /// **'平安夜快乐'**
  String get activityChristmasEve;

  /// No description provided for @activityChristmasEveThinking.
  ///
  /// In zh, this message translates to:
  /// **'平安夜也在盘'**
  String get activityChristmasEveThinking;

  /// No description provided for @activityChristmasEveGift.
  ///
  /// In zh, this message translates to:
  /// **'今晚写代码有礼物'**
  String get activityChristmasEveGift;

  /// No description provided for @activityChristmas.
  ///
  /// In zh, this message translates to:
  /// **'圣诞快乐'**
  String get activityChristmas;

  /// No description provided for @activityChristmasCompany.
  ///
  /// In zh, this message translates to:
  /// **'圣诞也陪你'**
  String get activityChristmasCompany;

  /// No description provided for @activityChristmasEgg.
  ///
  /// In zh, this message translates to:
  /// **'圣诞限定彩蛋'**
  String get activityChristmasEgg;

  /// No description provided for @activityChristmasReindeer.
  ///
  /// In zh, this message translates to:
  /// **'麋鹿送代码来了'**
  String get activityChristmasReindeer;

  /// No description provided for @activityYearEndEve.
  ///
  /// In zh, this message translates to:
  /// **'跨年夜'**
  String get activityYearEndEve;

  /// No description provided for @activityYearEndLast.
  ///
  /// In zh, this message translates to:
  /// **'今年最后一盘'**
  String get activityYearEndLast;

  /// No description provided for @activityYearEndReady.
  ///
  /// In zh, this message translates to:
  /// **'准备跨年'**
  String get activityYearEndReady;

  /// No description provided for @activityYearEndSeeYou.
  ///
  /// In zh, this message translates to:
  /// **'明年见！'**
  String get activityYearEndSeeYou;

  /// No description provided for @activityZodiacRat.
  ///
  /// In zh, this message translates to:
  /// **'鼠'**
  String get activityZodiacRat;

  /// No description provided for @activityZodiacOx.
  ///
  /// In zh, this message translates to:
  /// **'牛'**
  String get activityZodiacOx;

  /// No description provided for @activityZodiacTiger.
  ///
  /// In zh, this message translates to:
  /// **'虎'**
  String get activityZodiacTiger;

  /// No description provided for @activityZodiacRabbit.
  ///
  /// In zh, this message translates to:
  /// **'兔'**
  String get activityZodiacRabbit;

  /// No description provided for @activityZodiacDragon.
  ///
  /// In zh, this message translates to:
  /// **'龙'**
  String get activityZodiacDragon;

  /// No description provided for @activityZodiacSnake.
  ///
  /// In zh, this message translates to:
  /// **'蛇'**
  String get activityZodiacSnake;

  /// No description provided for @activityZodiacHorse.
  ///
  /// In zh, this message translates to:
  /// **'马'**
  String get activityZodiacHorse;

  /// No description provided for @activityZodiacGoat.
  ///
  /// In zh, this message translates to:
  /// **'羊'**
  String get activityZodiacGoat;

  /// No description provided for @activityZodiacMonkey.
  ///
  /// In zh, this message translates to:
  /// **'猴'**
  String get activityZodiacMonkey;

  /// No description provided for @activityZodiacRooster.
  ///
  /// In zh, this message translates to:
  /// **'鸡'**
  String get activityZodiacRooster;

  /// No description provided for @activityZodiacDog.
  ///
  /// In zh, this message translates to:
  /// **'狗'**
  String get activityZodiacDog;

  /// No description provided for @activityZodiacPig.
  ///
  /// In zh, this message translates to:
  /// **'猪'**
  String get activityZodiacPig;

  /// No description provided for @activityLunarCheers.
  ///
  /// In zh, this message translates to:
  /// **'春节快乐！'**
  String get activityLunarCheers;

  /// No description provided for @activityLunarCode.
  ///
  /// In zh, this message translates to:
  /// **'过年还在写代码'**
  String get activityLunarCode;

  /// No description provided for @activityLunarEnvelope.
  ///
  /// In zh, this message translates to:
  /// **'红包拿来'**
  String get activityLunarEnvelope;

  /// No description provided for @activityLunarSpring.
  ///
  /// In zh, this message translates to:
  /// **'新春快乐'**
  String get activityLunarSpring;

  /// No description provided for @activityLunarGreeting.
  ///
  /// In zh, this message translates to:
  /// **'过年好'**
  String get activityLunarGreeting;

  /// No description provided for @activityLunarCodeGreeting.
  ///
  /// In zh, this message translates to:
  /// **'代码也拜个年'**
  String get activityLunarCodeGreeting;

  /// No description provided for @activityRareSsr.
  ///
  /// In zh, this message translates to:
  /// **'SSR！稀有彩蛋'**
  String get activityRareSsr;

  /// No description provided for @activityRareUr.
  ///
  /// In zh, this message translates to:
  /// **'UR 掉落'**
  String get activityRareUr;

  /// No description provided for @activityRareLegend.
  ///
  /// In zh, this message translates to:
  /// **'金色传说！'**
  String get activityRareLegend;

  /// No description provided for @activityRareOrange.
  ///
  /// In zh, this message translates to:
  /// **'出橙了'**
  String get activityRareOrange;

  /// No description provided for @activityRareEgg.
  ///
  /// In zh, this message translates to:
  /// **'彩蛋砸脸'**
  String get activityRareEgg;

  /// No description provided for @activityRareChosen.
  ///
  /// In zh, this message translates to:
  /// **'天选时刻'**
  String get activityRareChosen;

  /// No description provided for @activityRareHidden.
  ///
  /// In zh, this message translates to:
  /// **'你发现了隐藏款'**
  String get activityRareHidden;

  /// No description provided for @activityRareChat.
  ///
  /// In zh, this message translates to:
  /// **'触发隐藏对话'**
  String get activityRareChat;

  /// No description provided for @activityRareMax.
  ///
  /// In zh, this message translates to:
  /// **'稀有度 MAX'**
  String get activityRareMax;

  /// No description provided for @activityRareLucky.
  ///
  /// In zh, this message translates to:
  /// **'欧皇降临'**
  String get activityRareLucky;

  /// No description provided for @activityRareCritical.
  ///
  /// In zh, this message translates to:
  /// **'暴击了'**
  String get activityRareCritical;

  /// No description provided for @activityRareNextLevel.
  ///
  /// In zh, this message translates to:
  /// **'这波在大气层'**
  String get activityRareNextLevel;

  /// No description provided for @activityFailCrash.
  ///
  /// In zh, this message translates to:
  /// **'翻车了'**
  String get activityFailCrash;

  /// No description provided for @activityFailOops.
  ///
  /// In zh, this message translates to:
  /// **'哎呀'**
  String get activityFailOops;

  /// No description provided for @activityFailRun.
  ///
  /// In zh, this message translates to:
  /// **'没跑通'**
  String get activityFailRun;

  /// No description provided for @activityFailTrip.
  ///
  /// In zh, this message translates to:
  /// **'摔了一跤'**
  String get activityFailTrip;

  /// No description provided for @activityFailWrong.
  ///
  /// In zh, this message translates to:
  /// **'这不对'**
  String get activityFailWrong;

  /// No description provided for @activityFailHiccup.
  ///
  /// In zh, this message translates to:
  /// **'出岔子了'**
  String get activityFailHiccup;

  /// No description provided for @activityFailBroken.
  ///
  /// In zh, this message translates to:
  /// **'不灵了'**
  String get activityFailBroken;

  /// No description provided for @activityFailLocal.
  ///
  /// In zh, this message translates to:
  /// **'我本地能跑啊'**
  String get activityFailLocal;

  /// No description provided for @activityFailYesterday.
  ///
  /// In zh, this message translates to:
  /// **'昨天还能跑'**
  String get activityFailYesterday;

  /// No description provided for @activityFailTough.
  ///
  /// In zh, this message translates to:
  /// **'难绷'**
  String get activityFailTough;

  /// No description provided for @activityFailCrack.
  ///
  /// In zh, this message translates to:
  /// **'裂开'**
  String get activityFailCrack;

  /// No description provided for @activityFailPressure.
  ///
  /// In zh, this message translates to:
  /// **'血压上来了'**
  String get activityFailPressure;

  /// No description provided for @activityFailCareless.
  ///
  /// In zh, this message translates to:
  /// **'这波大意了'**
  String get activityFailCareless;

  /// No description provided for @activityFailSlip.
  ///
  /// In zh, this message translates to:
  /// **'手滑'**
  String get activityFailSlip;

  /// No description provided for @activityFailTryAgain.
  ///
  /// In zh, this message translates to:
  /// **'换个姿势再来'**
  String get activityFailTryAgain;

  /// No description provided for @activityFailChance.
  ///
  /// In zh, this message translates to:
  /// **'再给我一次机会'**
  String get activityFailChance;

  /// No description provided for @activityTestGreen.
  ///
  /// In zh, this message translates to:
  /// **'测试全绿'**
  String get activityTestGreen;

  /// No description provided for @activityTestAllGreen.
  ///
  /// In zh, this message translates to:
  /// **'全绿，舒服'**
  String get activityTestAllGreen;

  /// No description provided for @activityTestFirstTry.
  ///
  /// In zh, this message translates to:
  /// **'一次过！'**
  String get activityTestFirstTry;

  /// No description provided for @activityTestNoErrors.
  ///
  /// In zh, this message translates to:
  /// **'没报错'**
  String get activityTestNoErrors;

  /// No description provided for @activityTestPassed.
  ///
  /// In zh, this message translates to:
  /// **'过了过了'**
  String get activityTestPassed;

  /// No description provided for @activityTestSolid.
  ///
  /// In zh, this message translates to:
  /// **'稳了'**
  String get activityTestSolid;

  /// No description provided for @activityTestRed.
  ///
  /// In zh, this message translates to:
  /// **'红了，看看哪挂了'**
  String get activityTestRed;

  /// No description provided for @activityTestInvestigate.
  ///
  /// In zh, this message translates to:
  /// **'测试挂了，排查一下'**
  String get activityTestInvestigate;

  /// No description provided for @activityTestStubborn.
  ///
  /// In zh, this message translates to:
  /// **'有个用例不服'**
  String get activityTestStubborn;

  /// No description provided for @activityTestFix.
  ///
  /// In zh, this message translates to:
  /// **'红灯，再改改'**
  String get activityTestFix;

  /// No description provided for @activityGitCommitSave.
  ///
  /// In zh, this message translates to:
  /// **'提交了，存个档'**
  String get activityGitCommitSave;

  /// No description provided for @activityGitSaved.
  ///
  /// In zh, this message translates to:
  /// **'存档成功'**
  String get activityGitSaved;

  /// No description provided for @activityGitCommitRelief.
  ///
  /// In zh, this message translates to:
  /// **'commit 一下，安心'**
  String get activityGitCommitRelief;

  /// No description provided for @activityGitPushed.
  ///
  /// In zh, this message translates to:
  /// **'推上去了'**
  String get activityGitPushed;

  /// No description provided for @activityGitPushDone.
  ///
  /// In zh, this message translates to:
  /// **'push 完成，起飞'**
  String get activityGitPushDone;

  /// No description provided for @activityGitCodeOut.
  ///
  /// In zh, this message translates to:
  /// **'代码出门了'**
  String get activityGitCodeOut;

  /// No description provided for @activityInstallDone.
  ///
  /// In zh, this message translates to:
  /// **'依赖装好了'**
  String get activityInstallDone;

  /// No description provided for @activityInstallInternet.
  ///
  /// In zh, this message translates to:
  /// **'下载了半个互联网'**
  String get activityInstallInternet;

  /// No description provided for @activityInstallPackages.
  ///
  /// In zh, this message translates to:
  /// **'包都到齐了'**
  String get activityInstallPackages;

  /// No description provided for @activityMilestoneFive.
  ///
  /// In zh, this message translates to:
  /// **'工具 x5，手感来了'**
  String get activityMilestoneFive;

  /// No description provided for @activityMilestoneTen.
  ///
  /// In zh, this message translates to:
  /// **'工具连击 x10'**
  String get activityMilestoneTen;

  /// No description provided for @activityMilestoneTwenty.
  ///
  /// In zh, this message translates to:
  /// **'工具 x20，停不下来'**
  String get activityMilestoneTwenty;

  /// No description provided for @activityMilestoneFifty.
  ///
  /// In zh, this message translates to:
  /// **'工具 x50，劳模本模'**
  String get activityMilestoneFifty;

  /// No description provided for @activityRetryWait.
  ///
  /// In zh, this message translates to:
  /// **'稍等，重试中'**
  String get activityRetryWait;

  /// No description provided for @activityRetryBackoff.
  ///
  /// In zh, this message translates to:
  /// **'刚被拒了，退避一下'**
  String get activityRetryBackoff;

  /// No description provided for @activityRetryKnock.
  ///
  /// In zh, this message translates to:
  /// **'再敲一次门'**
  String get activityRetryKnock;

  /// No description provided for @activityRateLimited.
  ///
  /// In zh, this message translates to:
  /// **'被限流了，缓缓再试'**
  String get activityRateLimited;

  /// No description provided for @activityRate429.
  ///
  /// In zh, this message translates to:
  /// **'429 了，歇口气再来'**
  String get activityRate429;

  /// No description provided for @activityRateQueue.
  ///
  /// In zh, this message translates to:
  /// **'排队的人有点多'**
  String get activityRateQueue;

  /// No description provided for @activityCompactContext.
  ///
  /// In zh, this message translates to:
  /// **'收拾一下上下文…'**
  String get activityCompactContext;

  /// No description provided for @activityCompactBag.
  ///
  /// In zh, this message translates to:
  /// **'整理背包中…'**
  String get activityCompactBag;

  /// No description provided for @activityCompactSpace.
  ///
  /// In zh, this message translates to:
  /// **'腾地方中'**
  String get activityCompactSpace;

  /// No description provided for @activityCompactMemory.
  ///
  /// In zh, this message translates to:
  /// **'给记忆瘦个身'**
  String get activityCompactMemory;

  /// No description provided for @activityCompactChats.
  ///
  /// In zh, this message translates to:
  /// **'打包旧对话'**
  String get activityCompactChats;

  /// No description provided for @activityReminderWater.
  ///
  /// In zh, this message translates to:
  /// **'半小时了，喝口水？'**
  String get activityReminderWater;

  /// No description provided for @activityReminderTenMinutes.
  ///
  /// In zh, this message translates to:
  /// **'10 分钟了，这活不小'**
  String get activityReminderTenMinutes;

  /// No description provided for @activityDiffTitle.
  ///
  /// In zh, this message translates to:
  /// **'本轮改动'**
  String get activityDiffTitle;

  /// No description provided for @activityDiffCopied.
  ///
  /// In zh, this message translates to:
  /// **'已复制补丁'**
  String get activityDiffCopied;

  /// No description provided for @activityDiffNoWrap.
  ///
  /// In zh, this message translates to:
  /// **'不换行'**
  String get activityDiffNoWrap;

  /// No description provided for @activityDiffWrap.
  ///
  /// In zh, this message translates to:
  /// **'自动换行'**
  String get activityDiffWrap;

  /// No description provided for @activityDiffCopy.
  ///
  /// In zh, this message translates to:
  /// **'复制补丁'**
  String get activityDiffCopy;

  /// No description provided for @activityDiffEmpty.
  ///
  /// In zh, this message translates to:
  /// **'空文件，没有可显示的改动'**
  String get activityDiffEmpty;

  /// No description provided for @activityDiffNewFile.
  ///
  /// In zh, this message translates to:
  /// **'新建文件'**
  String get activityDiffNewFile;

  /// No description provided for @activityDiffUnknownLines.
  ///
  /// In zh, this message translates to:
  /// **'行号未知'**
  String get activityDiffUnknownLines;

  /// No description provided for @activityDiffCopyPath.
  ///
  /// In zh, this message translates to:
  /// **'复制路径'**
  String get activityDiffCopyPath;

  /// No description provided for @activityThinking.
  ///
  /// In zh, this message translates to:
  /// **'思考'**
  String get activityThinking;

  /// No description provided for @activityReplyInterrupted.
  ///
  /// In zh, this message translates to:
  /// **'回复（已中断）'**
  String get activityReplyInterrupted;

  /// No description provided for @activityWaitingApproval.
  ///
  /// In zh, this message translates to:
  /// **'等待确认'**
  String get activityWaitingApproval;

  /// No description provided for @activityWaitingAnswer.
  ///
  /// In zh, this message translates to:
  /// **'等待回答'**
  String get activityWaitingAnswer;

  /// No description provided for @activityWriting.
  ///
  /// In zh, this message translates to:
  /// **'写回复中'**
  String get activityWriting;

  /// No description provided for @activityThinkingNow.
  ///
  /// In zh, this message translates to:
  /// **'思考中'**
  String get activityThinkingNow;

  /// No description provided for @activityRetrying.
  ///
  /// In zh, this message translates to:
  /// **'重试中'**
  String get activityRetrying;

  /// No description provided for @activityCompacting.
  ///
  /// In zh, this message translates to:
  /// **'压缩上下文'**
  String get activityCompacting;

  /// No description provided for @activityVerbRun.
  ///
  /// In zh, this message translates to:
  /// **'跑'**
  String get activityVerbRun;

  /// No description provided for @activityVerbWrite.
  ///
  /// In zh, this message translates to:
  /// **'写'**
  String get activityVerbWrite;

  /// No description provided for @activityVerbEdit.
  ///
  /// In zh, this message translates to:
  /// **'改'**
  String get activityVerbEdit;

  /// No description provided for @activityVerbImage.
  ///
  /// In zh, this message translates to:
  /// **'看图'**
  String get activityVerbImage;

  /// No description provided for @activityVerbRead.
  ///
  /// In zh, this message translates to:
  /// **'读'**
  String get activityVerbRead;

  /// No description provided for @activityVerbFind.
  ///
  /// In zh, this message translates to:
  /// **'找'**
  String get activityVerbFind;

  /// No description provided for @activityVerbSearch.
  ///
  /// In zh, this message translates to:
  /// **'搜'**
  String get activityVerbSearch;

  /// No description provided for @activityVerbWebSearch.
  ///
  /// In zh, this message translates to:
  /// **'搜网页'**
  String get activityVerbWebSearch;

  /// No description provided for @activityVerbWebView.
  ///
  /// In zh, this message translates to:
  /// **'看网页'**
  String get activityVerbWebView;

  /// No description provided for @activityVerbSubagent.
  ///
  /// In zh, this message translates to:
  /// **'派子代理'**
  String get activityVerbSubagent;

  /// No description provided for @activityVerbTodo.
  ///
  /// In zh, this message translates to:
  /// **'更新待办'**
  String get activityVerbTodo;

  /// No description provided for @activitySecretHide.
  ///
  /// In zh, this message translates to:
  /// **'隐藏密钥'**
  String get activitySecretHide;

  /// No description provided for @activitySecretShow.
  ///
  /// In zh, this message translates to:
  /// **'显示密钥'**
  String get activitySecretShow;

  /// No description provided for @activitySlashNoMatch.
  ///
  /// In zh, this message translates to:
  /// **'没有匹配的指令，按普通消息发送'**
  String get activitySlashNoMatch;

  /// No description provided for @activitySlashCommands.
  ///
  /// In zh, this message translates to:
  /// **'指令'**
  String get activitySlashCommands;

  /// No description provided for @activitySlashEnterArgs.
  ///
  /// In zh, this message translates to:
  /// **'输入参数后发送'**
  String get activitySlashEnterArgs;

  /// No description provided for @activityStepTitle.
  ///
  /// In zh, this message translates to:
  /// **'步骤详情'**
  String get activityStepTitle;

  /// No description provided for @activityStepMissing.
  ///
  /// In zh, this message translates to:
  /// **'这一步不在已加载的记录里'**
  String get activityStepMissing;

  /// No description provided for @activityStepQuestion.
  ///
  /// In zh, this message translates to:
  /// **'提问'**
  String get activityStepQuestion;

  /// No description provided for @activityStepSuccess.
  ///
  /// In zh, this message translates to:
  /// **'成功'**
  String get activityStepSuccess;

  /// No description provided for @activityStepNeedsPermission.
  ///
  /// In zh, this message translates to:
  /// **'需要授权'**
  String get activityStepNeedsPermission;

  /// No description provided for @activityTools.
  ///
  /// In zh, this message translates to:
  /// **'工具'**
  String get activityTools;

  /// No description provided for @activityStepDispatched.
  ///
  /// In zh, this message translates to:
  /// **'发出'**
  String get activityStepDispatched;

  /// No description provided for @activityStepExecution.
  ///
  /// In zh, this message translates to:
  /// **'执行'**
  String get activityStepExecution;

  /// No description provided for @activityStepLocation.
  ///
  /// In zh, this message translates to:
  /// **'所在'**
  String get activityStepLocation;

  /// No description provided for @activityStepArguments.
  ///
  /// In zh, this message translates to:
  /// **'参数'**
  String get activityStepArguments;

  /// No description provided for @activityStepChanges.
  ///
  /// In zh, this message translates to:
  /// **'改动'**
  String get activityStepChanges;

  /// No description provided for @activityStepFullScreen.
  ///
  /// In zh, this message translates to:
  /// **'全屏查看'**
  String get activityStepFullScreen;

  /// No description provided for @activityStepReadContent.
  ///
  /// In zh, this message translates to:
  /// **'读到的内容'**
  String get activityStepReadContent;

  /// No description provided for @activityStepWrittenContent.
  ///
  /// In zh, this message translates to:
  /// **'写入的内容'**
  String get activityStepWrittenContent;

  /// No description provided for @activityStepError.
  ///
  /// In zh, this message translates to:
  /// **'错误'**
  String get activityStepError;

  /// No description provided for @activityOutput.
  ///
  /// In zh, this message translates to:
  /// **'输出'**
  String get activityOutput;

  /// No description provided for @activityStepResult.
  ///
  /// In zh, this message translates to:
  /// **'结果'**
  String get activityStepResult;

  /// No description provided for @activityStepDeclined.
  ///
  /// In zh, this message translates to:
  /// **'你拒绝了这次调用'**
  String get activityStepDeclined;

  /// No description provided for @activityStepNoOutput.
  ///
  /// In zh, this message translates to:
  /// **'没有输出'**
  String get activityStepNoOutput;

  /// No description provided for @activityStepStart.
  ///
  /// In zh, this message translates to:
  /// **'开始'**
  String get activityStepStart;

  /// No description provided for @activityDuration.
  ///
  /// In zh, this message translates to:
  /// **'用时'**
  String get activityDuration;

  /// No description provided for @activityFirstToken.
  ///
  /// In zh, this message translates to:
  /// **'首字'**
  String get activityFirstToken;

  /// No description provided for @activityStepGeneration.
  ///
  /// In zh, this message translates to:
  /// **'生成'**
  String get activityStepGeneration;

  /// No description provided for @activityStepSpeed.
  ///
  /// In zh, this message translates to:
  /// **'速度'**
  String get activityStepSpeed;

  /// No description provided for @activityModel.
  ///
  /// In zh, this message translates to:
  /// **'模型'**
  String get activityModel;

  /// No description provided for @activityStepTiming.
  ///
  /// In zh, this message translates to:
  /// **'计时'**
  String get activityStepTiming;

  /// No description provided for @activityUsage.
  ///
  /// In zh, this message translates to:
  /// **'用量'**
  String get activityUsage;

  /// No description provided for @activityInput.
  ///
  /// In zh, this message translates to:
  /// **'输入'**
  String get activityInput;

  /// No description provided for @activityStepCacheHit.
  ///
  /// In zh, this message translates to:
  /// **'  命中缓存'**
  String get activityStepCacheHit;

  /// No description provided for @activityStepCacheMiss.
  ///
  /// In zh, this message translates to:
  /// **'  未命中'**
  String get activityStepCacheMiss;

  /// No description provided for @activityStepCacheWrite.
  ///
  /// In zh, this message translates to:
  /// **'  写入缓存'**
  String get activityStepCacheWrite;

  /// No description provided for @activityStepReasoning.
  ///
  /// In zh, this message translates to:
  /// **'  推理'**
  String get activityStepReasoning;

  /// No description provided for @activityStepAnswer.
  ///
  /// In zh, this message translates to:
  /// **'  回答'**
  String get activityStepAnswer;

  /// No description provided for @activityStepThinking.
  ///
  /// In zh, this message translates to:
  /// **'思考过程'**
  String get activityStepThinking;

  /// No description provided for @activityStepExplanation.
  ///
  /// In zh, this message translates to:
  /// **'说明'**
  String get activityStepExplanation;

  /// No description provided for @activityStepToolCalls.
  ///
  /// In zh, this message translates to:
  /// **'本步调用的工具'**
  String get activityStepToolCalls;

  /// No description provided for @activityStepProcessing.
  ///
  /// In zh, this message translates to:
  /// **'模型正在处理'**
  String get activityStepProcessing;

  /// No description provided for @activityApprovalAllowed.
  ///
  /// In zh, this message translates to:
  /// **'允许了'**
  String get activityApprovalAllowed;

  /// No description provided for @activityApprovalUnanswered.
  ///
  /// In zh, this message translates to:
  /// **'无人确认'**
  String get activityApprovalUnanswered;

  /// No description provided for @activityApprovalAnswered.
  ///
  /// In zh, this message translates to:
  /// **'已答复'**
  String get activityApprovalAnswered;

  /// No description provided for @activityToolRead.
  ///
  /// In zh, this message translates to:
  /// **'读取'**
  String get activityToolRead;

  /// No description provided for @activityToolWrite.
  ///
  /// In zh, this message translates to:
  /// **'写入'**
  String get activityToolWrite;

  /// No description provided for @activityToolCall.
  ///
  /// In zh, this message translates to:
  /// **'调用工具'**
  String get activityToolCall;

  /// No description provided for @activityTraceTitle.
  ///
  /// In zh, this message translates to:
  /// **'本轮轨迹'**
  String get activityTraceTitle;

  /// No description provided for @activityTraceNotLoaded.
  ///
  /// In zh, this message translates to:
  /// **'本轮记录尚未加载'**
  String get activityTraceNotLoaded;

  /// No description provided for @activityTraceOutputLimit.
  ///
  /// In zh, this message translates to:
  /// **'输出达到上限'**
  String get activityTraceOutputLimit;

  /// No description provided for @activityTraceEngineRestarted.
  ///
  /// In zh, this message translates to:
  /// **'引擎重启，已中断'**
  String get activityTraceEngineRestarted;

  /// No description provided for @activityTraceBlocked.
  ///
  /// In zh, this message translates to:
  /// **'已被拦截'**
  String get activityTraceBlocked;

  /// No description provided for @activityTraceHeading.
  ///
  /// In zh, this message translates to:
  /// **'本轮轨迹  '**
  String get activityTraceHeading;

  /// No description provided for @activityTraceWaiting.
  ///
  /// In zh, this message translates to:
  /// **'等你'**
  String get activityTraceWaiting;

  /// No description provided for @activityTraceNoSteps.
  ///
  /// In zh, this message translates to:
  /// **'本轮没有可计时的步骤'**
  String get activityTraceNoSteps;

  /// No description provided for @activityUsageInputIncludesCache.
  ///
  /// In zh, this message translates to:
  /// **'输入含缓存命中'**
  String get activityUsageInputIncludesCache;

  /// No description provided for @activityCacheHit.
  ///
  /// In zh, this message translates to:
  /// **'缓存命中'**
  String get activityCacheHit;

  /// No description provided for @activitySummaryTodo.
  ///
  /// In zh, this message translates to:
  /// **'更新了待办'**
  String get activitySummaryTodo;

  /// No description provided for @activityUsageBalance.
  ///
  /// In zh, this message translates to:
  /// **'DeepSeek 余额'**
  String get activityUsageBalance;

  /// No description provided for @activityUsageContext.
  ///
  /// In zh, this message translates to:
  /// **'上下文'**
  String get activityUsageContext;

  /// No description provided for @activityUsageChat.
  ///
  /// In zh, this message translates to:
  /// **'本对话'**
  String get activityUsageChat;

  /// No description provided for @activityUsageAfterMessage.
  ///
  /// In zh, this message translates to:
  /// **'发送消息后显示'**
  String get activityUsageAfterMessage;

  /// No description provided for @activityUsageContextFull.
  ///
  /// In zh, this message translates to:
  /// **'上下文将满，发送 /compact 可压缩'**
  String get activityUsageContextFull;

  /// No description provided for @activitySpanZero.
  ///
  /// In zh, this message translates to:
  /// **'0 秒'**
  String get activitySpanZero;

  /// No description provided for @activitySpanTiny.
  ///
  /// In zh, this message translates to:
  /// **'<0.1 秒'**
  String get activitySpanTiny;

  /// No description provided for @activityTokensTenThousands.
  ///
  /// In zh, this message translates to:
  /// **'{value} 万'**
  String activityTokensTenThousands(String value);

  /// No description provided for @activityTokensHundredMillions.
  ///
  /// In zh, this message translates to:
  /// **'{value} 亿'**
  String activityTokensHundredMillions(String value);

  /// No description provided for @activityUsageContextSemantics.
  ///
  /// In zh, this message translates to:
  /// **'上下文已用 {percent}，查看用量'**
  String activityUsageContextSemantics(String percent);

  /// No description provided for @activityUsageSystemTokens.
  ///
  /// In zh, this message translates to:
  /// **'系统 {tokens}'**
  String activityUsageSystemTokens(String tokens);

  /// No description provided for @activityUsageToolTokens.
  ///
  /// In zh, this message translates to:
  /// **'工具 {tokens}'**
  String activityUsageToolTokens(String tokens);

  /// No description provided for @activityUsageMessageTokens.
  ///
  /// In zh, this message translates to:
  /// **'消息 {tokens}'**
  String activityUsageMessageTokens(String tokens);

  /// No description provided for @activityUsageTurns.
  ///
  /// In zh, this message translates to:
  /// **'共 {count} 轮'**
  String activityUsageTurns(int count);

  /// No description provided for @activityUsageCacheWriteTokens.
  ///
  /// In zh, this message translates to:
  /// **'写入缓存 {tokens}'**
  String activityUsageCacheWriteTokens(String tokens);

  /// No description provided for @activitySummaryCommands.
  ///
  /// In zh, this message translates to:
  /// **'执行 {count} 条命令'**
  String activitySummaryCommands(int count);

  /// No description provided for @activitySummaryEditedFiles.
  ///
  /// In zh, this message translates to:
  /// **'改了 {count} 个文件'**
  String activitySummaryEditedFiles(int count);

  /// No description provided for @activitySummaryReadFiles.
  ///
  /// In zh, this message translates to:
  /// **'读了 {count} 个文件'**
  String activitySummaryReadFiles(int count);

  /// No description provided for @activitySummarySearches.
  ///
  /// In zh, this message translates to:
  /// **'搜索 {count} 次'**
  String activitySummarySearches(int count);

  /// No description provided for @activitySummaryWeb.
  ///
  /// In zh, this message translates to:
  /// **'联网 {count} 次'**
  String activitySummaryWeb(int count);

  /// No description provided for @activitySummarySubagents.
  ///
  /// In zh, this message translates to:
  /// **'调用子代理 {count} 次'**
  String activitySummarySubagents(int count);

  /// No description provided for @activitySummaryOther.
  ///
  /// In zh, this message translates to:
  /// **'其他工具 {count} 次'**
  String activitySummaryOther(int count);

  /// No description provided for @activitySummaryTotal.
  ///
  /// In zh, this message translates to:
  /// **'使用了 {count} 个工具'**
  String activitySummaryTotal(int count);

  /// No description provided for @activityDiffBlockMarker.
  ///
  /// In zh, this message translates to:
  /// **'@@ 第 {index}/{total} 处修改 @@'**
  String activityDiffBlockMarker(int index, int total);

  /// No description provided for @activityDiffEditMarker.
  ///
  /// In zh, this message translates to:
  /// **'第 {index} 次修改（共 {total} 次）'**
  String activityDiffEditMarker(int index, int total);

  /// No description provided for @activityTraceSpanSemantics.
  ///
  /// In zh, this message translates to:
  /// **'{title} {detail}，用时 {duration}'**
  String activityTraceSpanSemantics(String title, String detail, String duration);

  /// No description provided for @activityTraceGroupSemantics.
  ///
  /// In zh, this message translates to:
  /// **'{label}，用时 {duration}'**
  String activityTraceGroupSemantics(String label, String duration);

  /// No description provided for @activityTraceEstimatedCost.
  ///
  /// In zh, this message translates to:
  /// **'{cost}（按官方单价估算）'**
  String activityTraceEstimatedCost(String cost);

  /// No description provided for @activityTraceReasoningTokens.
  ///
  /// In zh, this message translates to:
  /// **'其中推理 {tokens}'**
  String activityTraceReasoningTokens(String tokens);

  /// No description provided for @activityStepPosition.
  ///
  /// In zh, this message translates to:
  /// **'第 {turn} 轮 · 第 {step} 步'**
  String activityStepPosition(int turn, Object step);

  /// No description provided for @activityStepTokenSpeed.
  ///
  /// In zh, this message translates to:
  /// **'{speed} tokens/秒'**
  String activityStepTokenSpeed(String speed);

  /// No description provided for @activityStepRetryCount.
  ///
  /// In zh, this message translates to:
  /// **'{count} 次'**
  String activityStepRetryCount(int count);

  /// No description provided for @activityStepTruncated.
  ///
  /// In zh, this message translates to:
  /// **'{text}\n…（仅显示前 {count}k 字，复制可得全文）'**
  String activityStepTruncated(String text, int count);

  /// No description provided for @activityStepLiveElapsed.
  ///
  /// In zh, this message translates to:
  /// **'{elapsed} · 进行中{suffix}'**
  String activityStepLiveElapsed(String elapsed, String suffix);

  /// No description provided for @activityStepCopySection.
  ///
  /// In zh, this message translates to:
  /// **'复制{title}'**
  String activityStepCopySection(String title);

  /// No description provided for @activityStepCopiedSection.
  ///
  /// In zh, this message translates to:
  /// **'已复制{title}'**
  String activityStepCopiedSection(String title);

  /// No description provided for @activitySlashDescriptionArgs.
  ///
  /// In zh, this message translates to:
  /// **'{description} · 输入参数后发送'**
  String activitySlashDescriptionArgs(String description);

  /// No description provided for @activitySpanSecondsText.
  ///
  /// In zh, this message translates to:
  /// **'{seconds} 秒'**
  String activitySpanSecondsText(String seconds);

  /// No description provided for @activitySpanSeconds.
  ///
  /// In zh, this message translates to:
  /// **'{seconds} 秒'**
  String activitySpanSeconds(int seconds);

  /// No description provided for @activitySpanMinutesSeconds.
  ///
  /// In zh, this message translates to:
  /// **'{minutes} 分 {seconds} 秒'**
  String activitySpanMinutesSeconds(int minutes, String seconds);

  /// No description provided for @activitySpanHoursMinutes.
  ///
  /// In zh, this message translates to:
  /// **'{hours} 小时 {minutes} 分'**
  String activitySpanHoursMinutes(int hours, String minutes);

  /// No description provided for @activityCostUnderCent.
  ///
  /// In zh, this message translates to:
  /// **'不到 {symbol}0.01'**
  String activityCostUnderCent(String symbol);

  /// No description provided for @activityCostApprox.
  ///
  /// In zh, this message translates to:
  /// **'约 {symbol}{amount}'**
  String activityCostApprox(String symbol, String amount);

  /// No description provided for @activitySpanRetries.
  ///
  /// In zh, this message translates to:
  /// **'重试 {count} 次'**
  String activitySpanRetries(int count);

  /// No description provided for @activitySpanToolCalls.
  ///
  /// In zh, this message translates to:
  /// **'决定调用 {count} 个工具'**
  String activitySpanToolCalls(int count);

  /// No description provided for @activityRunningItems.
  ///
  /// In zh, this message translates to:
  /// **'等 {count} 项'**
  String activityRunningItems(int count);

  /// No description provided for @activityRetryAttempt.
  ///
  /// In zh, this message translates to:
  /// **'第 {count} 次'**
  String activityRetryAttempt(int count);

  /// No description provided for @activityDiffFileCount.
  ///
  /// In zh, this message translates to:
  /// **'{count} 个文件'**
  String activityDiffFileCount(int count);

  /// No description provided for @activityDiffFileSemantics.
  ///
  /// In zh, this message translates to:
  /// **'{path}，新增 {added} 行，删除 {removed} 行'**
  String activityDiffFileSemantics(String path, int added, int removed);

  /// No description provided for @activityDiffEditNumber.
  ///
  /// In zh, this message translates to:
  /// **'第 {edit} 次修改'**
  String activityDiffEditNumber(int edit);

  /// No description provided for @activityDiffHunkNumber.
  ///
  /// In zh, this message translates to:
  /// **'第 {index} 处'**
  String activityDiffHunkNumber(int index);

  /// No description provided for @activityDiffFromLine.
  ///
  /// In zh, this message translates to:
  /// **'第 {line} 行起'**
  String activityDiffFromLine(int line);

  /// No description provided for @activityDiffEditCount.
  ///
  /// In zh, this message translates to:
  /// **'修改 {count} 次'**
  String activityDiffEditCount(int count);

  /// No description provided for @activityLunarZodiac.
  ///
  /// In zh, this message translates to:
  /// **'{animal}年大吉'**
  String activityLunarZodiac(String animal);

  /// No description provided for @activityReminderHours.
  ///
  /// In zh, this message translates to:
  /// **'已经连续干了 {hours} 小时，歇会儿？'**
  String activityReminderHours(int hours);

  /// No description provided for @activityStepModelRequest.
  ///
  /// In zh, this message translates to:
  /// **'一次模型请求'**
  String get activityStepModelRequest;

  /// No description provided for @activityStepModelRequestDetail.
  ///
  /// In zh, this message translates to:
  /// **'一次模型请求 · {detail}'**
  String activityStepModelRequestDetail(String detail);

  /// No description provided for @activityUsageEstimatedCost.
  ///
  /// In zh, this message translates to:
  /// **'约 {symbol}{amount}'**
  String activityUsageEstimatedCost(String symbol, String amount);

  /// No description provided for @activitySlashCommandSemantics.
  ///
  /// In zh, this message translates to:
  /// **'{label}，/{name}'**
  String activitySlashCommandSemantics(String label, String name);

  /// No description provided for @activityToolListSeparator.
  ///
  /// In zh, this message translates to:
  /// **'、'**
  String get activityToolListSeparator;

  /// No description provided for @botsFolderGone.
  ///
  /// In zh, this message translates to:
  /// **'这个文件夹已经不在了'**
  String get botsFolderGone;

  /// No description provided for @botsFolderReadFailed.
  ///
  /// In zh, this message translates to:
  /// **'没能读取这个文件夹'**
  String get botsFolderReadFailed;

  /// No description provided for @botsFolderOpenFailed.
  ///
  /// In zh, this message translates to:
  /// **'打不开这个文件夹'**
  String get botsFolderOpenFailed;

  /// No description provided for @botsFolderCount.
  ///
  /// In zh, this message translates to:
  /// **'{count} 个文件夹'**
  String botsFolderCount(int count);

  /// No description provided for @botsWorkingFolder.
  ///
  /// In zh, this message translates to:
  /// **'工作目录'**
  String get botsWorkingFolder;

  /// No description provided for @botsFolderTeamDefault.
  ///
  /// In zh, this message translates to:
  /// **'团队工作区'**
  String get botsFolderTeamDefault;

  /// No description provided for @botsFolderRoomDefault.
  ///
  /// In zh, this message translates to:
  /// **'每位 Bot 各自的目录'**
  String get botsFolderRoomDefault;

  /// No description provided for @botsFolderHint.
  ///
  /// In zh, this message translates to:
  /// **'目录位于已连接的主机。'**
  String get botsFolderHint;

  /// No description provided for @botsFolderCurrent.
  ///
  /// In zh, this message translates to:
  /// **'当前目录'**
  String get botsFolderCurrent;

  /// No description provided for @botsFolderUnavailable.
  ///
  /// In zh, this message translates to:
  /// **'连接或目录已变化，请重新打开。'**
  String get botsFolderUnavailable;

  /// No description provided for @botsFolderNoChoices.
  ///
  /// In zh, this message translates to:
  /// **'主机上暂无其他目录。'**
  String get botsFolderNoChoices;

  /// No description provided for @botsFolderConfirm.
  ///
  /// In zh, this message translates to:
  /// **'使用此工作目录？'**
  String get botsFolderConfirm;

  /// No description provided for @botsFolderRefused.
  ///
  /// In zh, this message translates to:
  /// **'主机拒绝了此目录：它可能已不存在、无法访问或受保护。请另选目录或重试。'**
  String get botsFolderRefused;

  /// No description provided for @botsChildCount.
  ///
  /// In zh, this message translates to:
  /// **'{count} 个下级'**
  String botsChildCount(int count);

  /// No description provided for @botsCurrentChat.
  ///
  /// In zh, this message translates to:
  /// **'当前对话'**
  String get botsCurrentChat;

  /// No description provided for @botsSubagentCount.
  ///
  /// In zh, this message translates to:
  /// **'{count} 个子代理'**
  String botsSubagentCount(int count);

  /// No description provided for @botsRunningCount.
  ///
  /// In zh, this message translates to:
  /// **'{count} 个运行中'**
  String botsRunningCount(int count);

  /// No description provided for @botsFailedCount.
  ///
  /// In zh, this message translates to:
  /// **'{count} 个出错'**
  String botsFailedCount(int count);

  /// No description provided for @botsNestedCount.
  ///
  /// In zh, this message translates to:
  /// **'含 {count} 个下级'**
  String botsNestedCount(int count);

  /// No description provided for @botsBackToParent.
  ///
  /// In zh, this message translates to:
  /// **'返回「{title}」'**
  String botsBackToParent(String title);

  /// No description provided for @botsTeamMemberCount.
  ///
  /// In zh, this message translates to:
  /// **'智能体团队，{count} 位成员'**
  String botsTeamMemberCount(int count);

  /// No description provided for @botsAgentTeam.
  ///
  /// In zh, this message translates to:
  /// **'智能体团队'**
  String get botsAgentTeam;

  /// No description provided for @botsSubagentRunningCount.
  ///
  /// In zh, this message translates to:
  /// **'{count} 个子代理，{running} 个运行中'**
  String botsSubagentRunningCount(int count, int running);

  /// No description provided for @botsSubagents.
  ///
  /// In zh, this message translates to:
  /// **'子代理'**
  String get botsSubagents;

  /// No description provided for @botsNoSubagents.
  ///
  /// In zh, this message translates to:
  /// **'没有派出子代理'**
  String get botsNoSubagents;

  /// No description provided for @botsOpenChatFirst.
  ///
  /// In zh, this message translates to:
  /// **'先打开一个对话'**
  String get botsOpenChatFirst;

  /// No description provided for @botsTeamReadFailed.
  ///
  /// In zh, this message translates to:
  /// **'没能读到团队'**
  String get botsTeamReadFailed;

  /// No description provided for @botsNoTeamOnHost.
  ///
  /// In zh, this message translates to:
  /// **'这台主机没有智能体团队'**
  String get botsNoTeamOnHost;

  /// No description provided for @botsTeamNotEnabled.
  ///
  /// In zh, this message translates to:
  /// **'智能体团队未开启'**
  String get botsTeamNotEnabled;

  /// No description provided for @botsTeamDescription.
  ///
  /// In zh, this message translates to:
  /// **'多个智能体分工协作，共用一块任务板'**
  String get botsTeamDescription;

  /// No description provided for @botsTeamEnabling.
  ///
  /// In zh, this message translates to:
  /// **'正在开启…'**
  String get botsTeamEnabling;

  /// No description provided for @botsTeamEnable.
  ///
  /// In zh, this message translates to:
  /// **'开启团队'**
  String get botsTeamEnable;

  /// No description provided for @botsMembersWorking.
  ///
  /// In zh, this message translates to:
  /// **'{count} 位成员在工作'**
  String botsMembersWorking(int count);

  /// No description provided for @botsTeamStandby.
  ///
  /// In zh, this message translates to:
  /// **'都在待命'**
  String get botsTeamStandby;

  /// No description provided for @botsMembers.
  ///
  /// In zh, this message translates to:
  /// **'成员'**
  String get botsMembers;

  /// No description provided for @botsTasks.
  ///
  /// In zh, this message translates to:
  /// **'任务'**
  String get botsTasks;

  /// No description provided for @botsTeamRecordUnreadable.
  ///
  /// In zh, this message translates to:
  /// **'团队记录有一条读不出来'**
  String get botsTeamRecordUnreadable;

  /// No description provided for @botsMessages.
  ///
  /// In zh, this message translates to:
  /// **'消息'**
  String get botsMessages;

  /// No description provided for @botsOwner.
  ///
  /// In zh, this message translates to:
  /// **'负责人'**
  String get botsOwner;

  /// No description provided for @botsTeamCreateHint.
  ///
  /// In zh, this message translates to:
  /// **'在对话里请 AI 组建团队'**
  String get botsTeamCreateHint;

  /// No description provided for @botsCurrent.
  ///
  /// In zh, this message translates to:
  /// **'当前'**
  String get botsCurrent;

  /// No description provided for @botsNoTasks.
  ///
  /// In zh, this message translates to:
  /// **'还没有任务'**
  String get botsNoTasks;

  /// No description provided for @botsTodo.
  ///
  /// In zh, this message translates to:
  /// **'待办'**
  String get botsTodo;

  /// No description provided for @botsUnassigned.
  ///
  /// In zh, this message translates to:
  /// **'未分配'**
  String get botsUnassigned;

  /// No description provided for @botsTaskWaitingFor.
  ///
  /// In zh, this message translates to:
  /// **'等 {dependencies}'**
  String botsTaskWaitingFor(String dependencies);

  /// No description provided for @botsWriteOverlap.
  ///
  /// In zh, this message translates to:
  /// **'写入范围重叠'**
  String get botsWriteOverlap;

  /// No description provided for @botsWaitingDependencies.
  ///
  /// In zh, this message translates to:
  /// **'等依赖'**
  String get botsWaitingDependencies;

  /// No description provided for @botsReadyToStart.
  ///
  /// In zh, this message translates to:
  /// **'可开始'**
  String get botsReadyToStart;

  /// No description provided for @botsTaskId.
  ///
  /// In zh, this message translates to:
  /// **'编号'**
  String get botsTaskId;

  /// No description provided for @botsDependencies.
  ///
  /// In zh, this message translates to:
  /// **'依赖'**
  String get botsDependencies;

  /// No description provided for @botsWriteScopes.
  ///
  /// In zh, this message translates to:
  /// **'写入范围'**
  String get botsWriteScopes;

  /// No description provided for @botsMessagesReadFailed.
  ///
  /// In zh, this message translates to:
  /// **'没能读到消息'**
  String get botsMessagesReadFailed;

  /// No description provided for @botsNoMemberMessages.
  ///
  /// In zh, this message translates to:
  /// **'成员之间还没有消息'**
  String get botsNoMemberMessages;

  /// No description provided for @botsMessagesIncomplete.
  ///
  /// In zh, this message translates to:
  /// **'部分成员的消息没能读到 · 重试'**
  String get botsMessagesIncomplete;

  /// No description provided for @botsDateTime.
  ///
  /// In zh, this message translates to:
  /// **'{date} {time}'**
  String botsDateTime(String date, String time);

  /// No description provided for @botsViewDetails.
  ///
  /// In zh, this message translates to:
  /// **'查看详情'**
  String get botsViewDetails;

  /// No description provided for @botsAdmin.
  ///
  /// In zh, this message translates to:
  /// **'管理员'**
  String get botsAdmin;

  /// No description provided for @botsFullTextChanged.
  ///
  /// In zh, this message translates to:
  /// **'对话已变化'**
  String get botsFullTextChanged;

  /// No description provided for @botsFullTextReopen.
  ///
  /// In zh, this message translates to:
  /// **'请重新打开这条消息'**
  String get botsFullTextReopen;

  /// No description provided for @botsFullTextReadFailed.
  ///
  /// In zh, this message translates to:
  /// **'没能读取全文'**
  String get botsFullTextReadFailed;

  /// No description provided for @botsShowAll.
  ///
  /// In zh, this message translates to:
  /// **'显示全部'**
  String get botsShowAll;

  /// No description provided for @botsImagePlaceholder.
  ///
  /// In zh, this message translates to:
  /// **'［图片］'**
  String get botsImagePlaceholder;

  /// No description provided for @botsSending.
  ///
  /// In zh, this message translates to:
  /// **'发送中'**
  String get botsSending;

  /// No description provided for @botsWriteOwn.
  ///
  /// In zh, this message translates to:
  /// **'自己写'**
  String get botsWriteOwn;

  /// No description provided for @botsSubmit.
  ///
  /// In zh, this message translates to:
  /// **'提交'**
  String get botsSubmit;

  /// No description provided for @botsChooseModelFor.
  ///
  /// In zh, this message translates to:
  /// **'给 {name} 选一个模型'**
  String botsChooseModelFor(String name);

  /// No description provided for @botsModelGreeting.
  ///
  /// In zh, this message translates to:
  /// **'选好后它就会打招呼'**
  String get botsModelGreeting;

  /// No description provided for @botsChooseModel.
  ///
  /// In zh, this message translates to:
  /// **'选择模型'**
  String get botsChooseModel;

  /// No description provided for @botsSkipAnswer.
  ///
  /// In zh, this message translates to:
  /// **'不回答'**
  String get botsSkipAnswer;

  /// No description provided for @botsBotGone.
  ///
  /// In zh, this message translates to:
  /// **'这个 Bot 已不在'**
  String get botsBotGone;

  /// No description provided for @botsWaitingModel.
  ///
  /// In zh, this message translates to:
  /// **'等你选模型'**
  String get botsWaitingModel;

  /// No description provided for @botsThinking.
  ///
  /// In zh, this message translates to:
  /// **'正在思考'**
  String get botsThinking;

  /// No description provided for @botsMainBot.
  ///
  /// In zh, this message translates to:
  /// **'主 Bot'**
  String get botsMainBot;

  /// No description provided for @botsIdle.
  ///
  /// In zh, this message translates to:
  /// **'空闲'**
  String get botsIdle;

  /// No description provided for @botsAnsweredQuestion.
  ///
  /// In zh, this message translates to:
  /// **'你回答了它的问题'**
  String get botsAnsweredQuestion;

  /// No description provided for @botsEarlierMessages.
  ///
  /// In zh, this message translates to:
  /// **'更早的部分'**
  String get botsEarlierMessages;

  /// No description provided for @botsComposerHint.
  ///
  /// In zh, this message translates to:
  /// **'给 {name} 发消息…'**
  String botsComposerHint(String name);

  /// No description provided for @botsDeleteNamed.
  ///
  /// In zh, this message translates to:
  /// **'删除「{name}」？'**
  String botsDeleteNamed(String name);

  /// No description provided for @botsDeleteBotBody.
  ///
  /// In zh, this message translates to:
  /// **'它的对话还在，记忆会移到归档里。'**
  String get botsDeleteBotBody;

  /// No description provided for @botsTokensToday.
  ///
  /// In zh, this message translates to:
  /// **'24 小时 tokens'**
  String get botsTokensToday;

  /// No description provided for @botsMemoryUnit.
  ///
  /// In zh, this message translates to:
  /// **'条记忆'**
  String get botsMemoryUnit;

  /// No description provided for @botsRoomUnit.
  ///
  /// In zh, this message translates to:
  /// **'个群聊'**
  String get botsRoomUnit;

  /// No description provided for @botsProfile.
  ///
  /// In zh, this message translates to:
  /// **'资料'**
  String get botsProfile;

  /// No description provided for @botsModel.
  ///
  /// In zh, this message translates to:
  /// **'模型'**
  String get botsModel;

  /// No description provided for @botsBotName.
  ///
  /// In zh, this message translates to:
  /// **'名字'**
  String get botsBotName;

  /// No description provided for @botsRole.
  ///
  /// In zh, this message translates to:
  /// **'角色'**
  String get botsRole;

  /// No description provided for @botsWriterExample.
  ///
  /// In zh, this message translates to:
  /// **'比如：写手'**
  String get botsWriterExample;

  /// No description provided for @botsInstructions.
  ///
  /// In zh, this message translates to:
  /// **'说明'**
  String get botsInstructions;

  /// No description provided for @botsInstructionsHint.
  ///
  /// In zh, this message translates to:
  /// **'它该怎么做事'**
  String get botsInstructionsHint;

  /// No description provided for @botsColor.
  ///
  /// In zh, this message translates to:
  /// **'颜色'**
  String get botsColor;

  /// No description provided for @botsUsage.
  ///
  /// In zh, this message translates to:
  /// **'用量'**
  String get botsUsage;

  /// No description provided for @botsUsageScanning.
  ///
  /// In zh, this message translates to:
  /// **'正在统计历史对话，数据稍后补全。'**
  String get botsUsageScanning;

  /// No description provided for @botsUsageRefresh.
  ///
  /// In zh, this message translates to:
  /// **'刷新'**
  String get botsUsageRefresh;

  /// No description provided for @botsToday.
  ///
  /// In zh, this message translates to:
  /// **'近 24 小时'**
  String get botsToday;

  /// No description provided for @botsLastWeek.
  ///
  /// In zh, this message translates to:
  /// **'近 7 天'**
  String get botsLastWeek;

  /// No description provided for @botsLastMonth.
  ///
  /// In zh, this message translates to:
  /// **'近 30 天'**
  String get botsLastMonth;

  /// No description provided for @botsMonthCalls.
  ///
  /// In zh, this message translates to:
  /// **'近 30 天 · {count} 次调用'**
  String botsMonthCalls(int count);

  /// No description provided for @botsFullRecord.
  ///
  /// In zh, this message translates to:
  /// **'完整记录'**
  String get botsFullRecord;

  /// No description provided for @botsEveryToolCall.
  ///
  /// In zh, this message translates to:
  /// **'每一步工具调用'**
  String get botsEveryToolCall;

  /// No description provided for @botsUnsetMain.
  ///
  /// In zh, this message translates to:
  /// **'取消主 Bot'**
  String get botsUnsetMain;

  /// No description provided for @botsSetMain.
  ///
  /// In zh, this message translates to:
  /// **'设为主 Bot'**
  String get botsSetMain;

  /// No description provided for @botsDeleteBot.
  ///
  /// In zh, this message translates to:
  /// **'删除 Bot'**
  String get botsDeleteBot;

  /// No description provided for @botsEffortOff.
  ///
  /// In zh, this message translates to:
  /// **'不思考'**
  String get botsEffortOff;

  /// No description provided for @botsEffortMinimal.
  ///
  /// In zh, this message translates to:
  /// **'极少'**
  String get botsEffortMinimal;

  /// No description provided for @botsEffortLow.
  ///
  /// In zh, this message translates to:
  /// **'低'**
  String get botsEffortLow;

  /// No description provided for @botsEffortMedium.
  ///
  /// In zh, this message translates to:
  /// **'中'**
  String get botsEffortMedium;

  /// No description provided for @botsEffortHigh.
  ///
  /// In zh, this message translates to:
  /// **'高'**
  String get botsEffortHigh;

  /// No description provided for @botsEffortMax.
  ///
  /// In zh, this message translates to:
  /// **'最高'**
  String get botsEffortMax;

  /// No description provided for @botsNamedRecord.
  ///
  /// In zh, this message translates to:
  /// **'{name} · 完整记录'**
  String botsNamedRecord(String name);

  /// No description provided for @botsOrganizingNotes.
  ///
  /// In zh, this message translates to:
  /// **'正在整理笔记'**
  String get botsOrganizingNotes;

  /// No description provided for @botsToolRun.
  ///
  /// In zh, this message translates to:
  /// **'运行命令'**
  String get botsToolRun;

  /// No description provided for @botsToolRead.
  ///
  /// In zh, this message translates to:
  /// **'查看文件'**
  String get botsToolRead;

  /// No description provided for @botsToolEdit.
  ///
  /// In zh, this message translates to:
  /// **'修改文件'**
  String get botsToolEdit;

  /// No description provided for @botsToolSearch.
  ///
  /// In zh, this message translates to:
  /// **'联网搜索'**
  String get botsToolSearch;

  /// No description provided for @botsToolBrowse.
  ///
  /// In zh, this message translates to:
  /// **'看网页'**
  String get botsToolBrowse;

  /// No description provided for @botsToolMessage.
  ///
  /// In zh, this message translates to:
  /// **'联系其他 Bot'**
  String get botsToolMessage;

  /// No description provided for @botsToolGroup.
  ///
  /// In zh, this message translates to:
  /// **'在群里沟通'**
  String get botsToolGroup;

  /// No description provided for @botsToolMemory.
  ///
  /// In zh, this message translates to:
  /// **'整理记忆'**
  String get botsToolMemory;

  /// No description provided for @botsToolRecall.
  ///
  /// In zh, this message translates to:
  /// **'翻看记录'**
  String get botsToolRecall;

  /// No description provided for @botsToolTeam.
  ///
  /// In zh, this message translates to:
  /// **'安排团队'**
  String get botsToolTeam;

  /// No description provided for @botsToolAsk.
  ///
  /// In zh, this message translates to:
  /// **'准备问你'**
  String get botsToolAsk;

  /// No description provided for @botsToolWork.
  ///
  /// In zh, this message translates to:
  /// **'干活'**
  String get botsToolWork;

  /// No description provided for @botsJustNow.
  ///
  /// In zh, this message translates to:
  /// **'刚刚'**
  String get botsJustNow;

  /// No description provided for @botsCountHundredMillion.
  ///
  /// In zh, this message translates to:
  /// **'{value} 亿'**
  String botsCountHundredMillion(String value);

  /// No description provided for @botsCountTenThousand.
  ///
  /// In zh, this message translates to:
  /// **'{value} 万'**
  String botsCountTenThousand(String value);

  /// No description provided for @botsModelNotSelected.
  ///
  /// In zh, this message translates to:
  /// **'未选择'**
  String get botsModelNotSelected;

  /// No description provided for @botsYourPreview.
  ///
  /// In zh, this message translates to:
  /// **'你：{preview}'**
  String botsYourPreview(String preview);

  /// No description provided for @botsEventWorking.
  ///
  /// In zh, this message translates to:
  /// **'{name} 开始干活'**
  String botsEventWorking(String name);

  /// No description provided for @botsEventApproval.
  ///
  /// In zh, this message translates to:
  /// **'{name} 在等你批准'**
  String botsEventApproval(String name);

  /// No description provided for @botsEventDone.
  ///
  /// In zh, this message translates to:
  /// **'{name} 完成了工作'**
  String botsEventDone(String name);

  /// No description provided for @botsEventStopped.
  ///
  /// In zh, this message translates to:
  /// **'你停下了 {name} 的工作'**
  String botsEventStopped(String name);

  /// No description provided for @botsEventFailed.
  ///
  /// In zh, this message translates to:
  /// **'{name} 没能回答'**
  String botsEventFailed(String name);

  /// No description provided for @botsEventMissed.
  ///
  /// In zh, this message translates to:
  /// **'{name} 没有及时回应'**
  String botsEventMissed(String name);

  /// No description provided for @botsEventLookup.
  ///
  /// In zh, this message translates to:
  /// **'{name} 翻看了自己的聊天'**
  String botsEventLookup(String name);

  /// No description provided for @botsEventLookupQuery.
  ///
  /// In zh, this message translates to:
  /// **'{name} 在自己的聊天里找「{query}」'**
  String botsEventLookupQuery(String name, String query);

  /// No description provided for @botsEventResumed.
  ///
  /// In zh, this message translates to:
  /// **'{name} 重启后接着干'**
  String botsEventResumed(String name);

  /// No description provided for @botsEventCut.
  ///
  /// In zh, this message translates to:
  /// **'{name} 又被重启打断，停下了'**
  String botsEventCut(String name);

  /// No description provided for @botsAutomation.
  ///
  /// In zh, this message translates to:
  /// **'定时任务'**
  String get botsAutomation;

  /// No description provided for @botsAutomationText.
  ///
  /// In zh, this message translates to:
  /// **'定时任务：{text}'**
  String botsAutomationText(String text);

  /// No description provided for @botsOtherBot.
  ///
  /// In zh, this message translates to:
  /// **'其他 Bot'**
  String get botsOtherBot;

  /// No description provided for @botsMessageFrom.
  ///
  /// In zh, this message translates to:
  /// **'来自 {name} 的消息'**
  String botsMessageFrom(String name);

  /// No description provided for @botsEventReplied.
  ///
  /// In zh, this message translates to:
  /// **'{name} 回复了'**
  String botsEventReplied(String name);

  /// No description provided for @botsGroupReplied.
  ///
  /// In zh, this message translates to:
  /// **'群里有了回复'**
  String get botsGroupReplied;

  /// No description provided for @botsNamedGroupReplied.
  ///
  /// In zh, this message translates to:
  /// **'「{name}」里有了回复'**
  String botsNamedGroupReplied(String name);

  /// No description provided for @botsEventCalledStop.
  ///
  /// In zh, this message translates to:
  /// **'{name} 叫停了工作'**
  String botsEventCalledStop(String name);

  /// No description provided for @botsChooseMember.
  ///
  /// In zh, this message translates to:
  /// **'选择成员'**
  String get botsChooseMember;

  /// No description provided for @botsMentionMember.
  ///
  /// In zh, this message translates to:
  /// **'提到成员'**
  String get botsMentionMember;

  /// No description provided for @botsRelayUnavailable.
  ///
  /// In zh, this message translates to:
  /// **'经中转连接时用不了 Bot'**
  String get botsRelayUnavailable;

  /// No description provided for @botsUseSsh.
  ///
  /// In zh, this message translates to:
  /// **'用 SSH 连接这台电脑即可使用'**
  String get botsUseSsh;

  /// No description provided for @botsTeamLoadFailed.
  ///
  /// In zh, this message translates to:
  /// **'没能读取 Bot 团队'**
  String get botsTeamLoadFailed;

  /// No description provided for @botsBotCount.
  ///
  /// In zh, this message translates to:
  /// **'{count} 个 Bot'**
  String botsBotCount(int count);

  /// No description provided for @botsRoomCount.
  ///
  /// In zh, this message translates to:
  /// **'{count} 个群聊'**
  String botsRoomCount(int count);

  /// No description provided for @botsNewBot.
  ///
  /// In zh, this message translates to:
  /// **'新建 Bot'**
  String get botsNewBot;

  /// No description provided for @botsGroupChat.
  ///
  /// In zh, this message translates to:
  /// **'群聊'**
  String get botsGroupChat;

  /// No description provided for @botsNewGroup.
  ///
  /// In zh, this message translates to:
  /// **'新建群聊'**
  String get botsNewGroup;

  /// No description provided for @botsDuplicateCreated.
  ///
  /// In zh, this message translates to:
  /// **'已复制，稍后会出现在列表中。'**
  String get botsDuplicateCreated;

  /// No description provided for @botsDuplicate.
  ///
  /// In zh, this message translates to:
  /// **'复制 Bot'**
  String get botsDuplicate;

  /// No description provided for @botsDuplicateHint.
  ///
  /// In zh, this message translates to:
  /// **'沿用设置，对话与记忆从头开始'**
  String get botsDuplicateHint;

  /// No description provided for @botsDuplicateNamed.
  ///
  /// In zh, this message translates to:
  /// **'复制 {name}？'**
  String botsDuplicateNamed(String name);

  /// No description provided for @botsDuplicateBody.
  ///
  /// In zh, this message translates to:
  /// **'新 Bot 沿用职责、指令和模型设置，对话与个人记忆从头开始，名称由主机分配。模型可用时，它会先发送一句问候。'**
  String get botsDuplicateBody;

  /// No description provided for @botsChooseModelStart.
  ///
  /// In zh, this message translates to:
  /// **'选一个模型开始'**
  String get botsChooseModelStart;

  /// No description provided for @botsNoChats.
  ///
  /// In zh, this message translates to:
  /// **'还没有对话'**
  String get botsNoChats;

  /// No description provided for @botsUnreadCount.
  ///
  /// In zh, this message translates to:
  /// **'{count} 条未读'**
  String botsUnreadCount(int count);

  /// No description provided for @botsMainTag.
  ///
  /// In zh, this message translates to:
  /// **'主'**
  String get botsMainTag;

  /// No description provided for @botsMemberNeedsApproval.
  ///
  /// In zh, this message translates to:
  /// **'有成员等你批准'**
  String get botsMemberNeedsApproval;

  /// No description provided for @botsNamedWorking.
  ///
  /// In zh, this message translates to:
  /// **'{name} 正在干活'**
  String botsNamedWorking(String name);

  /// No description provided for @botsNamesWorking.
  ///
  /// In zh, this message translates to:
  /// **'{names} 正在干活'**
  String botsNamesWorking(String names);

  /// No description provided for @botsMemberCount.
  ///
  /// In zh, this message translates to:
  /// **'{count} 位成员'**
  String botsMemberCount(int count);

  /// No description provided for @botsUpdateRequired.
  ///
  /// In zh, this message translates to:
  /// **'DS Bot 需要更新'**
  String get botsUpdateRequired;

  /// No description provided for @botsInstall.
  ///
  /// In zh, this message translates to:
  /// **'安装 DS Bot'**
  String get botsInstall;

  /// No description provided for @botsUpdateForPhone.
  ///
  /// In zh, this message translates to:
  /// **'新版才能在手机上用'**
  String get botsUpdateForPhone;

  /// No description provided for @botsInstallDescription.
  ///
  /// In zh, this message translates to:
  /// **'一组长期在线的 Bot，各有记忆和分工'**
  String get botsInstallDescription;

  /// No description provided for @botsInstallOnHost.
  ///
  /// In zh, this message translates to:
  /// **'在{host}上装好后就能用'**
  String botsInstallOnHost(String host);

  /// No description provided for @botsRunsOnHost.
  ///
  /// In zh, this message translates to:
  /// **'在{host}上运行'**
  String botsRunsOnHost(String host);

  /// No description provided for @botsInstalling.
  ///
  /// In zh, this message translates to:
  /// **'正在安装'**
  String get botsInstalling;

  /// No description provided for @botsMemory.
  ///
  /// In zh, this message translates to:
  /// **'记忆'**
  String get botsMemory;

  /// No description provided for @botsEditMemory.
  ///
  /// In zh, this message translates to:
  /// **'编辑记忆'**
  String get botsEditMemory;

  /// No description provided for @botsAddMemory.
  ///
  /// In zh, this message translates to:
  /// **'添加记忆'**
  String get botsAddMemory;

  /// No description provided for @botsMemoryReplyExample.
  ///
  /// In zh, this message translates to:
  /// **'比如：回复尽量简短'**
  String get botsMemoryReplyExample;

  /// No description provided for @botsMemoryDraftExample.
  ///
  /// In zh, this message translates to:
  /// **'比如：周五前交初稿'**
  String get botsMemoryDraftExample;

  /// No description provided for @botsMemoryCount.
  ///
  /// In zh, this message translates to:
  /// **'记忆 · {count}'**
  String botsMemoryCount(int count);

  /// No description provided for @botsMemoryReadFailed.
  ///
  /// In zh, this message translates to:
  /// **'没能读取记忆'**
  String get botsMemoryReadFailed;

  /// No description provided for @botsSummary.
  ///
  /// In zh, this message translates to:
  /// **'概要'**
  String get botsSummary;

  /// No description provided for @botsNoMemory.
  ///
  /// In zh, this message translates to:
  /// **'还没有记忆'**
  String get botsNoMemory;

  /// No description provided for @botsTeam.
  ///
  /// In zh, this message translates to:
  /// **'团队'**
  String get botsTeam;

  /// No description provided for @botsSelf.
  ///
  /// In zh, this message translates to:
  /// **'自己'**
  String get botsSelf;

  /// No description provided for @botsWrittenByYou.
  ///
  /// In zh, this message translates to:
  /// **'你写的'**
  String get botsWrittenByYou;

  /// No description provided for @botsNameRequired.
  ///
  /// In zh, this message translates to:
  /// **'起个名字'**
  String get botsNameRequired;

  /// No description provided for @botsRoleHint.
  ///
  /// In zh, this message translates to:
  /// **'一句话说它是做什么的'**
  String get botsRoleHint;

  /// No description provided for @botsNewInstructionsHint.
  ///
  /// In zh, this message translates to:
  /// **'它该怎么做事，有什么要注意的'**
  String get botsNewInstructionsHint;

  /// No description provided for @botsAppearance.
  ///
  /// In zh, this message translates to:
  /// **'外观'**
  String get botsAppearance;

  /// No description provided for @botsCreating.
  ///
  /// In zh, this message translates to:
  /// **'正在创建'**
  String get botsCreating;

  /// No description provided for @botsGroupNameOptional.
  ///
  /// In zh, this message translates to:
  /// **'群名（可不填）'**
  String get botsGroupNameOptional;

  /// No description provided for @botsMembersSelected.
  ///
  /// In zh, this message translates to:
  /// **'成员 · 已选 {count}'**
  String botsMembersSelected(int count);

  /// No description provided for @botsPickTwoBots.
  ///
  /// In zh, this message translates to:
  /// **'至少选两个 Bot'**
  String get botsPickTwoBots;

  /// No description provided for @botsFullText.
  ///
  /// In zh, this message translates to:
  /// **'全文'**
  String get botsFullText;

  /// No description provided for @botsTextPartial.
  ///
  /// In zh, this message translates to:
  /// **'仅显示前 {count} 个字符'**
  String botsTextPartial(String count);

  /// No description provided for @botsTextCompletenessUnknown.
  ///
  /// In zh, this message translates to:
  /// **'无法确认是否为完整内容'**
  String get botsTextCompletenessUnknown;

  /// No description provided for @botsRoomGone.
  ///
  /// In zh, this message translates to:
  /// **'这个群聊已不在'**
  String get botsRoomGone;

  /// No description provided for @botsNamedSpeaking.
  ///
  /// In zh, this message translates to:
  /// **'{name} 正在发言'**
  String botsNamedSpeaking(String name);

  /// No description provided for @botsNamedActivity.
  ///
  /// In zh, this message translates to:
  /// **'{name} {activity}'**
  String botsNamedActivity(String name, String activity);

  /// No description provided for @botsWorking.
  ///
  /// In zh, this message translates to:
  /// **'正在干活'**
  String get botsWorking;

  /// No description provided for @botsDiscussing.
  ///
  /// In zh, this message translates to:
  /// **'正在讨论'**
  String get botsDiscussing;

  /// No description provided for @botsTyping.
  ///
  /// In zh, this message translates to:
  /// **'正在输入'**
  String get botsTyping;

  /// No description provided for @botsGroupComposerHint.
  ///
  /// In zh, this message translates to:
  /// **'给大家发消息…'**
  String get botsGroupComposerHint;

  /// No description provided for @botsDecline.
  ///
  /// In zh, this message translates to:
  /// **'拒绝'**
  String get botsDecline;

  /// No description provided for @botsAllowOnce.
  ///
  /// In zh, this message translates to:
  /// **'允许本次'**
  String get botsAllowOnce;

  /// No description provided for @botsPrivateChat.
  ///
  /// In zh, this message translates to:
  /// **'私聊'**
  String get botsPrivateChat;

  /// No description provided for @botsSetAdmin.
  ///
  /// In zh, this message translates to:
  /// **'设为管理员'**
  String get botsSetAdmin;

  /// No description provided for @botsRemoveMember.
  ///
  /// In zh, this message translates to:
  /// **'移出群聊'**
  String get botsRemoveMember;

  /// No description provided for @botsDeleteRoomBody.
  ///
  /// In zh, this message translates to:
  /// **'群里的记录还在，群记忆会移到归档里。'**
  String get botsDeleteRoomBody;

  /// No description provided for @botsNamedAdmin.
  ///
  /// In zh, this message translates to:
  /// **'管理员 {name}'**
  String botsNamedAdmin(String name);

  /// No description provided for @botsRoomWorkingCount.
  ///
  /// In zh, this message translates to:
  /// **'{count} 位在干活'**
  String botsRoomWorkingCount(int count);

  /// No description provided for @botsMembersCountTitle.
  ///
  /// In zh, this message translates to:
  /// **'成员 · {count}'**
  String botsMembersCountTitle(int count);

  /// No description provided for @botsStopMember.
  ///
  /// In zh, this message translates to:
  /// **'停下'**
  String get botsStopMember;

  /// No description provided for @botsAddMember.
  ///
  /// In zh, this message translates to:
  /// **'添加成员'**
  String get botsAddMember;

  /// No description provided for @botsWhoAnswers.
  ///
  /// In zh, this message translates to:
  /// **'谁先回答'**
  String get botsWhoAnswers;

  /// No description provided for @botsAdminFirst.
  ///
  /// In zh, this message translates to:
  /// **'管理员先答'**
  String get botsAdminFirst;

  /// No description provided for @botsEveryoneInTurn.
  ///
  /// In zh, this message translates to:
  /// **'全员轮流'**
  String get botsEveryoneInTurn;

  /// No description provided for @botsGroupName.
  ///
  /// In zh, this message translates to:
  /// **'群名'**
  String get botsGroupName;

  /// No description provided for @botsGroupNotice.
  ///
  /// In zh, this message translates to:
  /// **'群公告'**
  String get botsGroupNotice;

  /// No description provided for @botsGroupNoticeHint.
  ///
  /// In zh, this message translates to:
  /// **'每个成员发言前都会看到'**
  String get botsGroupNoticeHint;

  /// No description provided for @botsDeleteGroup.
  ///
  /// In zh, this message translates to:
  /// **'删除群聊'**
  String get botsDeleteGroup;

  /// No description provided for @botsDiscardTitle.
  ///
  /// In zh, this message translates to:
  /// **'放弃修改？'**
  String get botsDiscardTitle;

  /// No description provided for @botsKeepEditing.
  ///
  /// In zh, this message translates to:
  /// **'继续编辑'**
  String get botsKeepEditing;

  /// No description provided for @botsDiscard.
  ///
  /// In zh, this message translates to:
  /// **'放弃'**
  String get botsDiscard;

  /// No description provided for @botsProgress.
  ///
  /// In zh, this message translates to:
  /// **'进度'**
  String get botsProgress;

  /// No description provided for @botsGlyphRun.
  ///
  /// In zh, this message translates to:
  /// **'运行'**
  String get botsGlyphRun;

  /// No description provided for @botsGlyphJobOutput.
  ///
  /// In zh, this message translates to:
  /// **'查看后台任务'**
  String get botsGlyphJobOutput;

  /// No description provided for @botsGlyphJobs.
  ///
  /// In zh, this message translates to:
  /// **'后台任务'**
  String get botsGlyphJobs;

  /// No description provided for @botsGlyphStopJob.
  ///
  /// In zh, this message translates to:
  /// **'停止后台任务'**
  String get botsGlyphStopJob;

  /// No description provided for @botsGlyphRead.
  ///
  /// In zh, this message translates to:
  /// **'读取'**
  String get botsGlyphRead;

  /// No description provided for @botsGlyphImage.
  ///
  /// In zh, this message translates to:
  /// **'查看图片'**
  String get botsGlyphImage;

  /// No description provided for @botsGlyphDeliver.
  ///
  /// In zh, this message translates to:
  /// **'交付文件'**
  String get botsGlyphDeliver;

  /// No description provided for @botsGlyphWrite.
  ///
  /// In zh, this message translates to:
  /// **'写入'**
  String get botsGlyphWrite;

  /// No description provided for @botsGlyphSearch.
  ///
  /// In zh, this message translates to:
  /// **'搜索'**
  String get botsGlyphSearch;

  /// No description provided for @botsGlyphFindFiles.
  ///
  /// In zh, this message translates to:
  /// **'查找文件'**
  String get botsGlyphFindFiles;

  /// No description provided for @botsGlyphOpenWeb.
  ///
  /// In zh, this message translates to:
  /// **'打开网页'**
  String get botsGlyphOpenWeb;

  /// No description provided for @botsGlyphMessageAgent.
  ///
  /// In zh, this message translates to:
  /// **'发消息给子代理'**
  String get botsGlyphMessageAgent;

  /// No description provided for @botsGlyphInterruptAgent.
  ///
  /// In zh, this message translates to:
  /// **'打断子代理'**
  String get botsGlyphInterruptAgent;

  /// No description provided for @botsGlyphListModels.
  ///
  /// In zh, this message translates to:
  /// **'列出子代理模型'**
  String get botsGlyphListModels;

  /// No description provided for @botsGlyphWorkflow.
  ///
  /// In zh, this message translates to:
  /// **'工作流'**
  String get botsGlyphWorkflow;

  /// No description provided for @botsGlyphLoop.
  ///
  /// In zh, this message translates to:
  /// **'循环任务'**
  String get botsGlyphLoop;

  /// No description provided for @botsGlyphSkill.
  ///
  /// In zh, this message translates to:
  /// **'使用技能'**
  String get botsGlyphSkill;

  /// No description provided for @botsGlyphTodo.
  ///
  /// In zh, this message translates to:
  /// **'更新待办'**
  String get botsGlyphTodo;

  /// No description provided for @botsGlyphSetGoal.
  ///
  /// In zh, this message translates to:
  /// **'设定目标'**
  String get botsGlyphSetGoal;

  /// No description provided for @botsGlyphViewGoal.
  ///
  /// In zh, this message translates to:
  /// **'查看目标'**
  String get botsGlyphViewGoal;

  /// No description provided for @botsGlyphUpdateGoal.
  ///
  /// In zh, this message translates to:
  /// **'更新目标'**
  String get botsGlyphUpdateGoal;

  /// No description provided for @botsGlyphAsk.
  ///
  /// In zh, this message translates to:
  /// **'提问'**
  String get botsGlyphAsk;

  /// No description provided for @botsCommunityEmpty.
  ///
  /// In zh, this message translates to:
  /// **'暂时没有内容'**
  String get botsCommunityEmpty;

  /// No description provided for @botsCommunityGroups.
  ///
  /// In zh, this message translates to:
  /// **'交流群'**
  String get botsCommunityGroups;

  /// No description provided for @botsCommunity.
  ///
  /// In zh, this message translates to:
  /// **'社区'**
  String get botsCommunity;

  /// No description provided for @botsForum.
  ///
  /// In zh, this message translates to:
  /// **'论坛'**
  String get botsForum;

  /// No description provided for @botsForumSubtitle.
  ///
  /// In zh, this message translates to:
  /// **'提问、分享、找同好'**
  String get botsForumSubtitle;

  /// No description provided for @botsProjectHome.
  ///
  /// In zh, this message translates to:
  /// **'DSH Go 项目主页'**
  String get botsProjectHome;

  /// No description provided for @botsOpenSource.
  ///
  /// In zh, this message translates to:
  /// **'开源项目'**
  String get botsOpenSource;

  /// No description provided for @botsPluginCatalogFailed.
  ///
  /// In zh, this message translates to:
  /// **'插件目录没打开'**
  String get botsPluginCatalogFailed;

  /// No description provided for @botsTapRetry.
  ///
  /// In zh, this message translates to:
  /// **'点一下重试'**
  String get botsTapRetry;

  /// No description provided for @botsFeaturedPlugins.
  ///
  /// In zh, this message translates to:
  /// **'精选插件'**
  String get botsFeaturedPlugins;

  /// No description provided for @botsPluginSource.
  ///
  /// In zh, this message translates to:
  /// **'插件信息来自 dshfind'**
  String get botsPluginSource;

  /// No description provided for @botsPromptIdeas.
  ///
  /// In zh, this message translates to:
  /// **'玩法'**
  String get botsPromptIdeas;

  /// No description provided for @botsUpdates.
  ///
  /// In zh, this message translates to:
  /// **'更新动态'**
  String get botsUpdates;

  /// No description provided for @botsLink.
  ///
  /// In zh, this message translates to:
  /// **'链接'**
  String get botsLink;

  /// No description provided for @botsLinkOpenFailed.
  ///
  /// In zh, this message translates to:
  /// **'没能打开 {host}'**
  String botsLinkOpenFailed(String host);

  /// No description provided for @botsYearMonth.
  ///
  /// In zh, this message translates to:
  /// **'{year}年{month}月'**
  String botsYearMonth(int year, String month);

  /// No description provided for @botsCopyGroupNumber.
  ///
  /// In zh, this message translates to:
  /// **'复制群号'**
  String get botsCopyGroupNumber;

  /// No description provided for @botsQrCodeLabel.
  ///
  /// In zh, this message translates to:
  /// **'{title}二维码'**
  String botsQrCodeLabel(String title);

  /// No description provided for @botsFiles.
  ///
  /// In zh, this message translates to:
  /// **'文件'**
  String get botsFiles;

  /// No description provided for @botsEmptyCell.
  ///
  /// In zh, this message translates to:
  /// **'（空）'**
  String get botsEmptyCell;

  /// No description provided for @botsYesterdayTime.
  ///
  /// In zh, this message translates to:
  /// **'昨天 {time}'**
  String botsYesterdayTime(String time);

  /// No description provided for @botsOutsideWorkspace.
  ///
  /// In zh, this message translates to:
  /// **'不在工作区里'**
  String get botsOutsideWorkspace;

  /// No description provided for @botsNotFolder.
  ///
  /// In zh, this message translates to:
  /// **'这不是文件夹'**
  String get botsNotFolder;

  /// No description provided for @botsChatNotFound.
  ///
  /// In zh, this message translates to:
  /// **'找不到这个对话'**
  String get botsChatNotFound;

  /// No description provided for @botsBrowseUnsupported.
  ///
  /// In zh, this message translates to:
  /// **'这个连接不支持浏览文件'**
  String get botsBrowseUnsupported;

  /// No description provided for @botsWorkspace.
  ///
  /// In zh, this message translates to:
  /// **'工作区'**
  String get botsWorkspace;

  /// No description provided for @botsSearchFiles.
  ///
  /// In zh, this message translates to:
  /// **'搜索文件'**
  String get botsSearchFiles;

  /// No description provided for @botsGoUp.
  ///
  /// In zh, this message translates to:
  /// **'回到上一级'**
  String get botsGoUp;

  /// No description provided for @botsEmptyFolder.
  ///
  /// In zh, this message translates to:
  /// **'空文件夹'**
  String get botsEmptyFolder;

  /// No description provided for @botsFileCount.
  ///
  /// In zh, this message translates to:
  /// **'{count} 个文件'**
  String botsFileCount(int count);

  /// No description provided for @botsTruncatedItems.
  ///
  /// In zh, this message translates to:
  /// **'只列出了前 {count} 项'**
  String botsTruncatedItems(int count);

  /// No description provided for @botsMoreActions.
  ///
  /// In zh, this message translates to:
  /// **'更多操作'**
  String get botsMoreActions;

  /// No description provided for @botsSearchFailed.
  ///
  /// In zh, this message translates to:
  /// **'没能搜索'**
  String get botsSearchFailed;

  /// No description provided for @botsNoResults.
  ///
  /// In zh, this message translates to:
  /// **'没有找到'**
  String get botsNoResults;

  /// No description provided for @botsCopyPath.
  ///
  /// In zh, this message translates to:
  /// **'复制路径'**
  String get botsCopyPath;

  /// No description provided for @botsPetOutsideApp.
  ///
  /// In zh, this message translates to:
  /// **'App 外显示'**
  String get botsPetOutsideApp;

  /// No description provided for @botsPetNotAuthorized.
  ///
  /// In zh, this message translates to:
  /// **'未授权'**
  String get botsPetNotAuthorized;

  /// No description provided for @botsPetDisplayWhen.
  ///
  /// In zh, this message translates to:
  /// **'显示时机'**
  String get botsPetDisplayWhen;

  /// No description provided for @botsPetWhenActive.
  ///
  /// In zh, this message translates to:
  /// **'有事时显示'**
  String get botsPetWhenActive;

  /// No description provided for @botsPetAlways.
  ///
  /// In zh, this message translates to:
  /// **'一直显示'**
  String get botsPetAlways;

  /// No description provided for @botsPetSwitchDisabled.
  ///
  /// In zh, this message translates to:
  /// **'开关点不动'**
  String get botsPetSwitchDisabled;

  /// No description provided for @botsPetRestrictedSettings.
  ///
  /// In zh, this message translates to:
  /// **'允许受限制的设置'**
  String get botsPetRestrictedSettings;

  /// No description provided for @botsPetHiddenToday.
  ///
  /// In zh, this message translates to:
  /// **'今天不再显示'**
  String get botsPetHiddenToday;

  /// No description provided for @botsPetRestore.
  ///
  /// In zh, this message translates to:
  /// **'恢复'**
  String get botsPetRestore;

  /// No description provided for @botsPetChange.
  ///
  /// In zh, this message translates to:
  /// **'换宠物'**
  String get botsPetChange;

  /// No description provided for @botsPetHideHour.
  ///
  /// In zh, this message translates to:
  /// **'藏起来 1 小时'**
  String get botsPetHideHour;

  /// No description provided for @botsPetSettings.
  ///
  /// In zh, this message translates to:
  /// **'宠物设置'**
  String get botsPetSettings;

  /// No description provided for @botsPetDeepy.
  ///
  /// In zh, this message translates to:
  /// **'Deepy 小鲸鱼'**
  String get botsPetDeepy;

  /// No description provided for @botsPetWhaleGirl.
  ///
  /// In zh, this message translates to:
  /// **'鲸娘'**
  String get botsPetWhaleGirl;

  /// No description provided for @botsPetNone.
  ///
  /// In zh, this message translates to:
  /// **'不显示'**
  String get botsPetNone;

  /// No description provided for @botsPets.
  ///
  /// In zh, this message translates to:
  /// **'宠物'**
  String get botsPets;

  /// No description provided for @botsPetSource.
  ///
  /// In zh, this message translates to:
  /// **'来自 DSH-TUI'**
  String get botsPetSource;

  /// No description provided for @botsPetSize.
  ///
  /// In zh, this message translates to:
  /// **'大小'**
  String get botsPetSize;

  /// No description provided for @botsPetQuiet.
  ///
  /// In zh, this message translates to:
  /// **'安静模式'**
  String get botsPetQuiet;

  /// No description provided for @botsPetQuietSubtitle.
  ///
  /// In zh, this message translates to:
  /// **'只做动作，不冒气泡'**
  String get botsPetQuietSubtitle;

  /// No description provided for @botsPetShowNow.
  ///
  /// In zh, this message translates to:
  /// **'立即显示'**
  String get botsPetShowNow;

  /// No description provided for @botsPetHiddenUntil.
  ///
  /// In zh, this message translates to:
  /// **'藏到 {time}'**
  String botsPetHiddenUntil(String time);

  /// No description provided for @botsKeyEsc.
  ///
  /// In zh, this message translates to:
  /// **'发送 Esc'**
  String get botsKeyEsc;

  /// No description provided for @botsKeyTab.
  ///
  /// In zh, this message translates to:
  /// **'发送 Tab'**
  String get botsKeyTab;

  /// No description provided for @botsKeyLeft.
  ///
  /// In zh, this message translates to:
  /// **'左'**
  String get botsKeyLeft;

  /// No description provided for @botsKeyUp.
  ///
  /// In zh, this message translates to:
  /// **'上'**
  String get botsKeyUp;

  /// No description provided for @botsKeyDown.
  ///
  /// In zh, this message translates to:
  /// **'下'**
  String get botsKeyDown;

  /// No description provided for @botsKeyRight.
  ///
  /// In zh, this message translates to:
  /// **'右'**
  String get botsKeyRight;

  /// No description provided for @botsKeyPipe.
  ///
  /// In zh, this message translates to:
  /// **'竖线'**
  String get botsKeyPipe;

  /// No description provided for @botsKeyTilde.
  ///
  /// In zh, this message translates to:
  /// **'波浪号'**
  String get botsKeyTilde;

  /// No description provided for @botsKeySlash.
  ///
  /// In zh, this message translates to:
  /// **'斜杠'**
  String get botsKeySlash;

  /// No description provided for @botsKeyDash.
  ///
  /// In zh, this message translates to:
  /// **'短横线'**
  String get botsKeyDash;

  /// No description provided for @botsTerminal.
  ///
  /// In zh, this message translates to:
  /// **'终端'**
  String get botsTerminal;

  /// No description provided for @botsTerminalRename.
  ///
  /// In zh, this message translates to:
  /// **'重命名终端'**
  String get botsTerminalRename;

  /// No description provided for @botsTerminalName.
  ///
  /// In zh, this message translates to:
  /// **'终端名称'**
  String get botsTerminalName;

  /// No description provided for @botsTerminalRenameFailed.
  ///
  /// In zh, this message translates to:
  /// **'没能重命名'**
  String get botsTerminalRenameFailed;

  /// No description provided for @botsTerminalCloseNamed.
  ///
  /// In zh, this message translates to:
  /// **'关闭「{title}」？'**
  String botsTerminalCloseNamed(String title);

  /// No description provided for @botsTerminalCloseBody.
  ///
  /// In zh, this message translates to:
  /// **'里面的进程会结束'**
  String get botsTerminalCloseBody;

  /// No description provided for @botsTerminalUnsupported.
  ///
  /// In zh, this message translates to:
  /// **'这个连接用不了终端'**
  String get botsTerminalUnsupported;

  /// No description provided for @botsTerminalSupportedHosts.
  ///
  /// In zh, this message translates to:
  /// **'在本机或 SSH 主机上可用'**
  String get botsTerminalSupportedHosts;

  /// No description provided for @botsTerminalOpening.
  ///
  /// In zh, this message translates to:
  /// **'正在打开终端…'**
  String get botsTerminalOpening;

  /// No description provided for @botsTerminalNone.
  ///
  /// In zh, this message translates to:
  /// **'没有打开的终端'**
  String get botsTerminalNone;

  /// No description provided for @botsTerminalNew.
  ///
  /// In zh, this message translates to:
  /// **'新建终端'**
  String get botsTerminalNew;

  /// No description provided for @botsTerminalClose.
  ///
  /// In zh, this message translates to:
  /// **'关闭终端'**
  String get botsTerminalClose;

  /// No description provided for @botsTerminalChooseShell.
  ///
  /// In zh, this message translates to:
  /// **'选择 Shell'**
  String get botsTerminalChooseShell;

  /// No description provided for @botsTerminalShellFailed.
  ///
  /// In zh, this message translates to:
  /// **'没能读取 Shell'**
  String get botsTerminalShellFailed;

  /// No description provided for @botsTerminalReading.
  ///
  /// In zh, this message translates to:
  /// **'正在读取…'**
  String get botsTerminalReading;

  /// No description provided for @botsTerminalDefaultShell.
  ///
  /// In zh, this message translates to:
  /// **'默认 Shell'**
  String get botsTerminalDefaultShell;

  /// No description provided for @botsTerminalOtherDevice.
  ///
  /// In zh, this message translates to:
  /// **'其他设备正在输入'**
  String get botsTerminalOtherDevice;

  /// No description provided for @botsTerminalTakeOver.
  ///
  /// In zh, this message translates to:
  /// **'接管'**
  String get botsTerminalTakeOver;

  /// No description provided for @botsTerminalStarting.
  ///
  /// In zh, this message translates to:
  /// **'正在启动…'**
  String get botsTerminalStarting;

  /// No description provided for @botsTerminalConnecting.
  ///
  /// In zh, this message translates to:
  /// **'正在连接…'**
  String get botsTerminalConnecting;

  /// No description provided for @botsTerminalDisconnected.
  ///
  /// In zh, this message translates to:
  /// **'连接已断开'**
  String get botsTerminalDisconnected;

  /// No description provided for @botsTerminalReconnect.
  ///
  /// In zh, this message translates to:
  /// **'重新连接'**
  String get botsTerminalReconnect;

  /// No description provided for @botsTerminalEnded.
  ///
  /// In zh, this message translates to:
  /// **'已结束'**
  String get botsTerminalEnded;

  /// No description provided for @botsTerminalExitCode.
  ///
  /// In zh, this message translates to:
  /// **'已结束 · 退出码 {code}'**
  String botsTerminalExitCode(int code);

  /// No description provided for @botsTerminalGone.
  ///
  /// In zh, this message translates to:
  /// **'这个终端已不在了'**
  String get botsTerminalGone;

  /// No description provided for @botsTerminalLimit.
  ///
  /// In zh, this message translates to:
  /// **'先关掉不用的终端'**
  String get botsTerminalLimit;

  /// No description provided for @botsToolWorkingRun.
  ///
  /// In zh, this message translates to:
  /// **'正在运行命令'**
  String get botsToolWorkingRun;

  /// No description provided for @botsToolApprovalRun.
  ///
  /// In zh, this message translates to:
  /// **'{name} 想运行命令'**
  String botsToolApprovalRun(String name);

  /// No description provided for @botsToolWorkingRead.
  ///
  /// In zh, this message translates to:
  /// **'正在查看文件'**
  String get botsToolWorkingRead;

  /// No description provided for @botsToolApprovalRead.
  ///
  /// In zh, this message translates to:
  /// **'{name} 想查看文件'**
  String botsToolApprovalRead(String name);

  /// No description provided for @botsToolWorkingEdit.
  ///
  /// In zh, this message translates to:
  /// **'正在修改文件'**
  String get botsToolWorkingEdit;

  /// No description provided for @botsToolApprovalEdit.
  ///
  /// In zh, this message translates to:
  /// **'{name} 想修改文件'**
  String botsToolApprovalEdit(String name);

  /// No description provided for @botsToolWorkingSearch.
  ///
  /// In zh, this message translates to:
  /// **'正在联网搜索'**
  String get botsToolWorkingSearch;

  /// No description provided for @botsToolApprovalSearch.
  ///
  /// In zh, this message translates to:
  /// **'{name} 想联网搜索'**
  String botsToolApprovalSearch(String name);

  /// No description provided for @botsToolWorkingBrowse.
  ///
  /// In zh, this message translates to:
  /// **'正在看网页'**
  String get botsToolWorkingBrowse;

  /// No description provided for @botsToolApprovalBrowse.
  ///
  /// In zh, this message translates to:
  /// **'{name} 想看网页'**
  String botsToolApprovalBrowse(String name);

  /// No description provided for @botsToolWorkingMessage.
  ///
  /// In zh, this message translates to:
  /// **'正在联系其他 Bot'**
  String get botsToolWorkingMessage;

  /// No description provided for @botsToolApprovalMessage.
  ///
  /// In zh, this message translates to:
  /// **'{name} 想联系其他 Bot'**
  String botsToolApprovalMessage(String name);

  /// No description provided for @botsToolWorkingGroup.
  ///
  /// In zh, this message translates to:
  /// **'正在在群里沟通'**
  String get botsToolWorkingGroup;

  /// No description provided for @botsToolApprovalGroup.
  ///
  /// In zh, this message translates to:
  /// **'{name} 想在群里沟通'**
  String botsToolApprovalGroup(String name);

  /// No description provided for @botsToolWorkingMemory.
  ///
  /// In zh, this message translates to:
  /// **'正在整理记忆'**
  String get botsToolWorkingMemory;

  /// No description provided for @botsToolApprovalMemory.
  ///
  /// In zh, this message translates to:
  /// **'{name} 想整理记忆'**
  String botsToolApprovalMemory(String name);

  /// No description provided for @botsToolWorkingRecall.
  ///
  /// In zh, this message translates to:
  /// **'正在翻看记录'**
  String get botsToolWorkingRecall;

  /// No description provided for @botsToolApprovalRecall.
  ///
  /// In zh, this message translates to:
  /// **'{name} 想翻看记录'**
  String botsToolApprovalRecall(String name);

  /// No description provided for @botsToolWorkingTeam.
  ///
  /// In zh, this message translates to:
  /// **'正在安排团队'**
  String get botsToolWorkingTeam;

  /// No description provided for @botsToolApprovalTeam.
  ///
  /// In zh, this message translates to:
  /// **'{name} 想安排团队'**
  String botsToolApprovalTeam(String name);

  /// No description provided for @botsToolWorkingAsk.
  ///
  /// In zh, this message translates to:
  /// **'正在准备问你'**
  String get botsToolWorkingAsk;

  /// No description provided for @botsToolApprovalAsk.
  ///
  /// In zh, this message translates to:
  /// **'{name} 想准备问你'**
  String botsToolApprovalAsk(String name);

  /// No description provided for @botsToolWorkingWork.
  ///
  /// In zh, this message translates to:
  /// **'正在干活'**
  String get botsToolWorkingWork;

  /// No description provided for @botsToolApprovalWork.
  ///
  /// In zh, this message translates to:
  /// **'{name} 想干活'**
  String botsToolApprovalWork(String name);

  /// No description provided for @botsEveryone.
  ///
  /// In zh, this message translates to:
  /// **'所有人'**
  String get botsEveryone;

  /// No description provided for @botsActivelyRunning.
  ///
  /// In zh, this message translates to:
  /// **'正在运行'**
  String get botsActivelyRunning;

  /// No description provided for @botsListSeparator.
  ///
  /// In zh, this message translates to:
  /// **'，'**
  String get botsListSeparator;

  /// No description provided for @botsNameSeparator.
  ///
  /// In zh, this message translates to:
  /// **'、'**
  String get botsNameSeparator;

  /// No description provided for @botsGlyphSubagent.
  ///
  /// In zh, this message translates to:
  /// **'子代理'**
  String get botsGlyphSubagent;

  /// No description provided for @botsGlyphWebSearch.
  ///
  /// In zh, this message translates to:
  /// **'联网搜索'**
  String get botsGlyphWebSearch;

  /// No description provided for @botsSenderPreview.
  ///
  /// In zh, this message translates to:
  /// **'{name}：{preview}'**
  String botsSenderPreview(String name, String preview);

  /// No description provided for @botsAgentSemantics.
  ///
  /// In zh, this message translates to:
  /// **'{title}，{state}'**
  String botsAgentSemantics(String title, String state);

  /// No description provided for @botsViewMetric.
  ///
  /// In zh, this message translates to:
  /// **'{label}：{value}'**
  String botsViewMetric(Object label, Object value);

  /// No description provided for @botsEffortXhigh.
  ///
  /// In zh, this message translates to:
  /// **'超高'**
  String get botsEffortXhigh;

  /// No description provided for @botsRelayLimit.
  ///
  /// In zh, this message translates to:
  /// **'Bot 互叫上限'**
  String get botsRelayLimit;

  /// No description provided for @botsRelayLimitHint.
  ///
  /// In zh, this message translates to:
  /// **'从你最近一次发言起，Bot 之间互叫达到此次数后暂停。填写 1–200 的整数，留空使用默认值。'**
  String get botsRelayLimitHint;

  /// No description provided for @botsRelayLimitDefault.
  ///
  /// In zh, this message translates to:
  /// **'默认：{count}'**
  String botsRelayLimitDefault(int count);

  /// No description provided for @botsRelayLimitInvalid.
  ///
  /// In zh, this message translates to:
  /// **'请填写 1–200 的整数'**
  String get botsRelayLimitInvalid;

  /// No description provided for @botsRelayLimitRestore.
  ///
  /// In zh, this message translates to:
  /// **'恢复默认'**
  String get botsRelayLimitRestore;

  /// No description provided for @botsRelayLimitConnectionChanged.
  ///
  /// In zh, this message translates to:
  /// **'连接已变化，请关闭后重新打开。'**
  String get botsRelayLimitConnectionChanged;

  /// No description provided for @botsMobileUnsupportedTitle.
  ///
  /// In zh, this message translates to:
  /// **'DS Bot 暂不支持手机端'**
  String get botsMobileUnsupportedTitle;

  /// No description provided for @botsMobileApiRequired.
  ///
  /// In zh, this message translates to:
  /// **'可先在网页版中使用'**
  String get botsMobileApiRequired;

  /// No description provided for @botsMobileApiMissing.
  ///
  /// In zh, this message translates to:
  /// **'手机端暂不支持，可先在网页版中使用'**
  String get botsMobileApiMissing;

  /// No description provided for @botsCreationConnectionChanged.
  ///
  /// In zh, this message translates to:
  /// **'连接已变化，请重新打开创建页面后再操作。'**
  String get botsCreationConnectionChanged;

  /// No description provided for @brandXiaomi.
  ///
  /// In zh, this message translates to:
  /// **'小米 / Redmi'**
  String get brandXiaomi;

  /// No description provided for @brandHuawei.
  ///
  /// In zh, this message translates to:
  /// **'华为'**
  String get brandHuawei;

  /// No description provided for @brandHonor.
  ///
  /// In zh, this message translates to:
  /// **'荣耀'**
  String get brandHonor;

  /// No description provided for @brandOppo.
  ///
  /// In zh, this message translates to:
  /// **'OPPO / 一加 / realme'**
  String get brandOppo;

  /// No description provided for @brandSamsung.
  ///
  /// In zh, this message translates to:
  /// **'三星'**
  String get brandSamsung;

  /// No description provided for @brandVivoOs.
  ///
  /// In zh, this message translates to:
  /// **'vivo / iQOO（OriginOS）'**
  String get brandVivoOs;

  /// No description provided for @brandXiaomiOs.
  ///
  /// In zh, this message translates to:
  /// **'小米 / Redmi（HyperOS、MIUI）'**
  String get brandXiaomiOs;

  /// No description provided for @brandHuaweiOs.
  ///
  /// In zh, this message translates to:
  /// **'华为 / 荣耀（HarmonyOS、MagicOS）'**
  String get brandHuaweiOs;

  /// No description provided for @brandOppoOs.
  ///
  /// In zh, this message translates to:
  /// **'OPPO / 一加 / realme（ColorOS）'**
  String get brandOppoOs;

  /// No description provided for @brandSamsungOs.
  ///
  /// In zh, this message translates to:
  /// **'三星（One UI）'**
  String get brandSamsungOs;

  /// No description provided for @brandZhihu.
  ///
  /// In zh, this message translates to:
  /// **'知乎'**
  String get brandZhihu;

  /// No description provided for @catalogCurrentChat.
  ///
  /// In zh, this message translates to:
  /// **'当前对话'**
  String get catalogCurrentChat;

  /// No description provided for @catalogChatDetails.
  ///
  /// In zh, this message translates to:
  /// **'对话详情'**
  String get catalogChatDetails;

  /// No description provided for @catalogChatDetailsSummary.
  ///
  /// In zh, this message translates to:
  /// **'轨迹、改动与进度'**
  String get catalogChatDetailsSummary;

  /// No description provided for @catalogArtifacts.
  ///
  /// In zh, this message translates to:
  /// **'产出的文件'**
  String get catalogArtifacts;

  /// No description provided for @catalogArtifactsSummary.
  ///
  /// In zh, this message translates to:
  /// **'预览、分享、保存'**
  String get catalogArtifactsSummary;

  /// No description provided for @catalogFiles.
  ///
  /// In zh, this message translates to:
  /// **'文件'**
  String get catalogFiles;

  /// No description provided for @catalogFilesSummary.
  ///
  /// In zh, this message translates to:
  /// **'浏览与预览'**
  String get catalogFilesSummary;

  /// No description provided for @catalogTerminal.
  ///
  /// In zh, this message translates to:
  /// **'终端'**
  String get catalogTerminal;

  /// No description provided for @catalogTerminalSummary.
  ///
  /// In zh, this message translates to:
  /// **'工作区里的终端'**
  String get catalogTerminalSummary;

  /// No description provided for @catalogExport.
  ///
  /// In zh, this message translates to:
  /// **'导出对话日志'**
  String get catalogExport;

  /// No description provided for @catalogExportSummary.
  ///
  /// In zh, this message translates to:
  /// **'打包成 ZIP'**
  String get catalogExportSummary;

  /// No description provided for @catalogJobs.
  ///
  /// In zh, this message translates to:
  /// **'后台任务'**
  String get catalogJobs;

  /// No description provided for @catalogJobsSummary.
  ///
  /// In zh, this message translates to:
  /// **'查看输出、停止'**
  String get catalogJobsSummary;

  /// No description provided for @catalogPlanGoal.
  ///
  /// In zh, this message translates to:
  /// **'计划与目标'**
  String get catalogPlanGoal;

  /// No description provided for @catalogPlanGoalSummary.
  ///
  /// In zh, this message translates to:
  /// **'目标、计划与待办'**
  String get catalogPlanGoalSummary;

  /// No description provided for @catalogSkills.
  ///
  /// In zh, this message translates to:
  /// **'技能'**
  String get catalogSkills;

  /// No description provided for @catalogSkillsSummary.
  ///
  /// In zh, this message translates to:
  /// **'在对话里用技能'**
  String get catalogSkillsSummary;

  /// No description provided for @catalogSubagents.
  ///
  /// In zh, this message translates to:
  /// **'子代理'**
  String get catalogSubagents;

  /// No description provided for @catalogSubagentsSummary.
  ///
  /// In zh, this message translates to:
  /// **'谱系与状态，点开接着聊'**
  String get catalogSubagentsSummary;

  /// No description provided for @catalogReference.
  ///
  /// In zh, this message translates to:
  /// **'引用文件和对话'**
  String get catalogReference;

  /// No description provided for @catalogReferenceSummary.
  ///
  /// In zh, this message translates to:
  /// **'在输入框用 @ 引用'**
  String get catalogReferenceSummary;

  /// No description provided for @catalogAutomationSection.
  ///
  /// In zh, this message translates to:
  /// **'自动化'**
  String get catalogAutomationSection;

  /// No description provided for @catalogSchedules.
  ///
  /// In zh, this message translates to:
  /// **'自动化任务'**
  String get catalogSchedules;

  /// No description provided for @catalogSchedulesSummary.
  ///
  /// In zh, this message translates to:
  /// **'定时与周期任务'**
  String get catalogSchedulesSummary;

  /// No description provided for @catalogAgentModelsSection.
  ///
  /// In zh, this message translates to:
  /// **'Agent 与模型'**
  String get catalogAgentModelsSection;

  /// No description provided for @catalogPermission.
  ///
  /// In zh, this message translates to:
  /// **'权限'**
  String get catalogPermission;

  /// No description provided for @catalogPermissionSummary.
  ///
  /// In zh, this message translates to:
  /// **'执行前是否确认'**
  String get catalogPermissionSummary;

  /// No description provided for @catalogAgentPresets.
  ///
  /// In zh, this message translates to:
  /// **'Agent 预设'**
  String get catalogAgentPresets;

  /// No description provided for @catalogAgentPresetsSummary.
  ///
  /// In zh, this message translates to:
  /// **'新对话的工作方式'**
  String get catalogAgentPresetsSummary;

  /// No description provided for @catalogModels.
  ///
  /// In zh, this message translates to:
  /// **'模型'**
  String get catalogModels;

  /// No description provided for @catalogModelsSummary.
  ///
  /// In zh, this message translates to:
  /// **'订阅与自定义渠道'**
  String get catalogModelsSummary;

  /// No description provided for @catalogSubagentSettings.
  ///
  /// In zh, this message translates to:
  /// **'子代理设置'**
  String get catalogSubagentSettings;

  /// No description provided for @catalogSubagentSettingsSummary.
  ///
  /// In zh, this message translates to:
  /// **'层数、并行与模型'**
  String get catalogSubagentSettingsSummary;

  /// No description provided for @catalogAgentLoop.
  ///
  /// In zh, this message translates to:
  /// **'Agent 循环'**
  String get catalogAgentLoop;

  /// No description provided for @catalogAgentLoopSummary.
  ///
  /// In zh, this message translates to:
  /// **'工具并行上限'**
  String get catalogAgentLoopSummary;

  /// No description provided for @catalogShellSettings.
  ///
  /// In zh, this message translates to:
  /// **'命令执行'**
  String get catalogShellSettings;

  /// No description provided for @catalogShellSettingsSummary.
  ///
  /// In zh, this message translates to:
  /// **'超时与输出上限'**
  String get catalogShellSettingsSummary;

  /// No description provided for @catalogWebSearch.
  ///
  /// In zh, this message translates to:
  /// **'联网搜索'**
  String get catalogWebSearch;

  /// No description provided for @catalogWebSearchSummary.
  ///
  /// In zh, this message translates to:
  /// **'搜索服务与预算'**
  String get catalogWebSearchSummary;

  /// No description provided for @catalogPlugins.
  ///
  /// In zh, this message translates to:
  /// **'插件'**
  String get catalogPlugins;

  /// No description provided for @catalogPluginsSummary.
  ///
  /// In zh, this message translates to:
  /// **'已安装与插件市场'**
  String get catalogPluginsSummary;

  /// No description provided for @catalogPluginInventory.
  ///
  /// In zh, this message translates to:
  /// **'插件清单'**
  String get catalogPluginInventory;

  /// No description provided for @catalogPluginInventorySummary.
  ///
  /// In zh, this message translates to:
  /// **'已加载的全部插件'**
  String get catalogPluginInventorySummary;

  /// No description provided for @catalogCordisSummary.
  ///
  /// In zh, this message translates to:
  /// **'插件创建的动态面板'**
  String get catalogCordisSummary;

  /// No description provided for @catalogAgentTeam.
  ///
  /// In zh, this message translates to:
  /// **'智能体团队'**
  String get catalogAgentTeam;

  /// No description provided for @catalogAgentTeamSummary.
  ///
  /// In zh, this message translates to:
  /// **'成员、任务板与消息'**
  String get catalogAgentTeamSummary;

  /// No description provided for @catalogCotTranslation.
  ///
  /// In zh, this message translates to:
  /// **'思考过程翻译'**
  String get catalogCotTranslation;

  /// No description provided for @catalogCotTranslationSummary.
  ///
  /// In zh, this message translates to:
  /// **'展开思考后点「翻译」'**
  String get catalogCotTranslationSummary;

  /// No description provided for @catalogVoiceInput.
  ///
  /// In zh, this message translates to:
  /// **'语音输入'**
  String get catalogVoiceInput;

  /// No description provided for @catalogVoiceInputSummary.
  ///
  /// In zh, this message translates to:
  /// **'输入框里的麦克风'**
  String get catalogVoiceInputSummary;

  /// No description provided for @catalogCommunitySharingSection.
  ///
  /// In zh, this message translates to:
  /// **'社区与分享'**
  String get catalogCommunitySharingSection;

  /// No description provided for @catalogForum.
  ///
  /// In zh, this message translates to:
  /// **'论坛'**
  String get catalogForum;

  /// No description provided for @catalogForumSummary.
  ///
  /// In zh, this message translates to:
  /// **'提问、分享、找同好'**
  String get catalogForumSummary;

  /// No description provided for @catalogCommunity.
  ///
  /// In zh, this message translates to:
  /// **'社区'**
  String get catalogCommunity;

  /// No description provided for @catalogCommunitySummary.
  ///
  /// In zh, this message translates to:
  /// **'精选与交流群'**
  String get catalogCommunitySummary;

  /// No description provided for @catalogBotSummary.
  ///
  /// In zh, this message translates to:
  /// **'Bot 团队与群聊'**
  String get catalogBotSummary;

  /// No description provided for @catalogShareProfile.
  ///
  /// In zh, this message translates to:
  /// **'分享配置'**
  String get catalogShareProfile;

  /// No description provided for @catalogShareProfileSummary.
  ///
  /// In zh, this message translates to:
  /// **'插件、设置与技能'**
  String get catalogShareProfileSummary;

  /// No description provided for @catalogHostsSettingsSection.
  ///
  /// In zh, this message translates to:
  /// **'主机与设置'**
  String get catalogHostsSettingsSection;

  /// No description provided for @catalogSearch.
  ///
  /// In zh, this message translates to:
  /// **'搜索对话'**
  String get catalogSearch;

  /// No description provided for @catalogSearchSummary.
  ///
  /// In zh, this message translates to:
  /// **'按标题和正文查找'**
  String get catalogSearchSummary;

  /// No description provided for @catalogNotifications.
  ///
  /// In zh, this message translates to:
  /// **'通知'**
  String get catalogNotifications;

  /// No description provided for @catalogNotificationsSummary.
  ///
  /// In zh, this message translates to:
  /// **'完成与待确认提醒'**
  String get catalogNotificationsSummary;

  /// No description provided for @catalogWorkspaces.
  ///
  /// In zh, this message translates to:
  /// **'工作区'**
  String get catalogWorkspaces;

  /// No description provided for @catalogWorkspacesSummary.
  ///
  /// In zh, this message translates to:
  /// **'添加与切换目录'**
  String get catalogWorkspacesSummary;

  /// No description provided for @catalogGeneral.
  ///
  /// In zh, this message translates to:
  /// **'通用设置'**
  String get catalogGeneral;

  /// No description provided for @catalogGeneralSummary.
  ///
  /// In zh, this message translates to:
  /// **'显示、发送与日志上传'**
  String get catalogGeneralSummary;

  /// No description provided for @catalogAccount.
  ///
  /// In zh, this message translates to:
  /// **'账号与余额'**
  String get catalogAccount;

  /// No description provided for @catalogAccountSummary.
  ///
  /// In zh, this message translates to:
  /// **'登录、余额与充值'**
  String get catalogAccountSummary;

  /// No description provided for @catalogRemoteSummary.
  ///
  /// In zh, this message translates to:
  /// **'连接电脑或服务器'**
  String get catalogRemoteSummary;

  /// No description provided for @catalogPhoneControl.
  ///
  /// In zh, this message translates to:
  /// **'手机操控'**
  String get catalogPhoneControl;

  /// No description provided for @catalogPhoneControlSummary.
  ///
  /// In zh, this message translates to:
  /// **'看屏幕、帮你点按'**
  String get catalogPhoneControlSummary;

  /// No description provided for @catalogEngine.
  ///
  /// In zh, this message translates to:
  /// **'本机引擎'**
  String get catalogEngine;

  /// No description provided for @catalogEngineSummary.
  ///
  /// In zh, this message translates to:
  /// **'本机引擎状态与日志'**
  String get catalogEngineSummary;

  /// No description provided for @catalogDiagnostics.
  ///
  /// In zh, this message translates to:
  /// **'诊断'**
  String get catalogDiagnostics;

  /// No description provided for @catalogDiagnosticsSummary.
  ///
  /// In zh, this message translates to:
  /// **'导出诊断包'**
  String get catalogDiagnosticsSummary;

  /// No description provided for @catalogWebSummary.
  ///
  /// In zh, this message translates to:
  /// **'DSH 官方界面'**
  String get catalogWebSummary;

  /// No description provided for @catalogPluginPanel.
  ///
  /// In zh, this message translates to:
  /// **'插件面板'**
  String get catalogPluginPanel;

  /// No description provided for @catalogHostPluginMissing.
  ///
  /// In zh, this message translates to:
  /// **'这台主机没有这个插件'**
  String get catalogHostPluginMissing;

  /// No description provided for @catalogAllFeatures.
  ///
  /// In zh, this message translates to:
  /// **'全部功能'**
  String get catalogAllFeatures;

  /// No description provided for @catalogAllFeaturesSubtitle.
  ///
  /// In zh, this message translates to:
  /// **'网页版的功能，也都在这里'**
  String get catalogAllFeaturesSubtitle;

  /// No description provided for @catalogOpenChatFirst.
  ///
  /// In zh, this message translates to:
  /// **'先打开一个对话'**
  String get catalogOpenChatFirst;

  /// No description provided for @catalogNoOpenChat.
  ///
  /// In zh, this message translates to:
  /// **'还没打开对话'**
  String get catalogNoOpenChat;

  /// No description provided for @catalogOpenChat.
  ///
  /// In zh, this message translates to:
  /// **'当前打开的对话'**
  String get catalogOpenChat;

  /// No description provided for @catalogOpenOrCreateChat.
  ///
  /// In zh, this message translates to:
  /// **'先在聊天里打开或新建一个'**
  String get catalogOpenOrCreateChat;

  /// No description provided for @catalogCordisHostClient.
  ///
  /// In zh, this message translates to:
  /// **'后台和界面'**
  String get catalogCordisHostClient;

  /// No description provided for @catalogCordisHostOnly.
  ///
  /// In zh, this message translates to:
  /// **'仅后台'**
  String get catalogCordisHostOnly;

  /// No description provided for @catalogCordisClientOnly.
  ///
  /// In zh, this message translates to:
  /// **'仅界面'**
  String get catalogCordisClientOnly;

  /// No description provided for @catalogCordisPluginGone.
  ///
  /// In zh, this message translates to:
  /// **'插件已经不在了'**
  String get catalogCordisPluginGone;

  /// No description provided for @catalogCordisStopFailed.
  ///
  /// In zh, this message translates to:
  /// **'没能停止'**
  String get catalogCordisStopFailed;

  /// No description provided for @catalogCordisRemoveOne.
  ///
  /// In zh, this message translates to:
  /// **'会停止它并删除。'**
  String get catalogCordisRemoveOne;

  /// No description provided for @catalogCordisRemove.
  ///
  /// In zh, this message translates to:
  /// **'移除'**
  String get catalogCordisRemove;

  /// No description provided for @catalogCordisRemoved.
  ///
  /// In zh, this message translates to:
  /// **'已移除'**
  String get catalogCordisRemoved;

  /// No description provided for @catalogCordisRemoveFailed.
  ///
  /// In zh, this message translates to:
  /// **'没能移除'**
  String get catalogCordisRemoveFailed;

  /// No description provided for @catalogCordisChat.
  ///
  /// In zh, this message translates to:
  /// **'所属对话'**
  String get catalogCordisChat;

  /// No description provided for @catalogCordisMakeup.
  ///
  /// In zh, this message translates to:
  /// **'组成'**
  String get catalogCordisMakeup;

  /// No description provided for @catalogCordisStopping.
  ///
  /// In zh, this message translates to:
  /// **'正在停止…'**
  String get catalogCordisStopping;

  /// No description provided for @catalogCordisRemoving.
  ///
  /// In zh, this message translates to:
  /// **'正在移除…'**
  String get catalogCordisRemoving;

  /// No description provided for @catalogSeatGone.
  ///
  /// In zh, this message translates to:
  /// **'插件已不可用'**
  String get catalogSeatGone;

  /// No description provided for @catalogCordisRemoveTitle.
  ///
  /// In zh, this message translates to:
  /// **'移除「{name}」？'**
  String catalogCordisRemoveTitle(String name);

  /// No description provided for @catalogCordisRemoveVersions.
  ///
  /// In zh, this message translates to:
  /// **'会停止它，并删除全部 {versions} 个版本。'**
  String catalogCordisRemoveVersions(int versions);

  /// No description provided for @catalogCordisVersionCount.
  ///
  /// In zh, this message translates to:
  /// **'{count} 个'**
  String catalogCordisVersionCount(int count);

  /// No description provided for @catalogToolsSection.
  ///
  /// In zh, this message translates to:
  /// **'工具'**
  String get catalogToolsSection;

  /// No description provided for @catalogAllSettings.
  ///
  /// In zh, this message translates to:
  /// **'全部设置'**
  String get catalogAllSettings;

  /// No description provided for @diagnosticsForAi.
  ///
  /// In zh, this message translates to:
  /// **'让 AI 看诊断'**
  String get diagnosticsForAi;

  /// No description provided for @diagnosticsForAiHint.
  ///
  /// In zh, this message translates to:
  /// **'把环境快照写进引擎，AI 自己读'**
  String get diagnosticsForAiHint;

  /// No description provided for @diagnosticsForAiDone.
  ///
  /// In zh, this message translates to:
  /// **'已写入诊断，问 AI「看下诊断」就行'**
  String get diagnosticsForAiDone;

  /// No description provided for @diagnosticsForAiFailed.
  ///
  /// In zh, this message translates to:
  /// **'写不进去：本机运行时还没装好'**
  String get diagnosticsForAiFailed;

  /// No description provided for @chatBackgroundTaskNotice.
  ///
  /// In zh, this message translates to:
  /// **'后台任务通知'**
  String get chatBackgroundTaskNotice;

  /// No description provided for @chatBackgroundTaskMessage.
  ///
  /// In zh, this message translates to:
  /// **'后台任务消息'**
  String get chatBackgroundTaskMessage;

  /// No description provided for @chatDeclineQuestion.
  ///
  /// In zh, this message translates to:
  /// **'不回答'**
  String get chatDeclineQuestion;

  /// No description provided for @chatChats.
  ///
  /// In zh, this message translates to:
  /// **'对话列表'**
  String get chatChats;

  /// No description provided for @chatViewChatDetails.
  ///
  /// In zh, this message translates to:
  /// **'查看对话详情'**
  String get chatViewChatDetails;

  /// No description provided for @chatUnsent.
  ///
  /// In zh, this message translates to:
  /// **'未发送'**
  String get chatUnsent;

  /// No description provided for @chatFailedSubmission.
  ///
  /// In zh, this message translates to:
  /// **'未送达 · 已保留'**
  String get chatFailedSubmission;

  /// No description provided for @chatEditFailedSubmission.
  ///
  /// In zh, this message translates to:
  /// **'编辑后重发'**
  String get chatEditFailedSubmission;

  /// No description provided for @chatErrReasoningEffortUnsupported.
  ///
  /// In zh, this message translates to:
  /// **'当前模型不支持此推理档位，请调整档位或换模型'**
  String get chatErrReasoningEffortUnsupported;

  /// No description provided for @chatSteerNextStep.
  ///
  /// In zh, this message translates to:
  /// **'插话 · 下一步生效'**
  String get chatSteerNextStep;

  /// No description provided for @chatQueuedAfterTurn.
  ///
  /// In zh, this message translates to:
  /// **'排队中 · 本轮结束后发送'**
  String get chatQueuedAfterTurn;

  /// No description provided for @chatSteering.
  ///
  /// In zh, this message translates to:
  /// **'插话中'**
  String get chatSteering;

  /// No description provided for @chatQueued.
  ///
  /// In zh, this message translates to:
  /// **'排队中'**
  String get chatQueued;

  /// No description provided for @chatStoppingTurn.
  ///
  /// In zh, this message translates to:
  /// **'正在停止本轮'**
  String get chatStoppingTurn;

  /// No description provided for @chatSending.
  ///
  /// In zh, this message translates to:
  /// **'发送中'**
  String get chatSending;

  /// No description provided for @chatSendNow.
  ///
  /// In zh, this message translates to:
  /// **'立即发送'**
  String get chatSendNow;

  /// No description provided for @chatSwitchToSteer.
  ///
  /// In zh, this message translates to:
  /// **'改为插话'**
  String get chatSwitchToSteer;

  /// No description provided for @chatWithdraw.
  ///
  /// In zh, this message translates to:
  /// **'撤回'**
  String get chatWithdraw;

  /// No description provided for @chatContinuedInNewChat.
  ///
  /// In zh, this message translates to:
  /// **'已在新对话中继续'**
  String get chatContinuedInNewChat;

  /// No description provided for @chatReadOriginalImageFailed.
  ///
  /// In zh, this message translates to:
  /// **'读取原图失败，请重试'**
  String get chatReadOriginalImageFailed;

  /// No description provided for @chatRegenerateFailed.
  ///
  /// In zh, this message translates to:
  /// **'重新回答失败'**
  String get chatRegenerateFailed;

  /// No description provided for @chatRegeneratedInNewChat.
  ///
  /// In zh, this message translates to:
  /// **'已在新对话中重新回答'**
  String get chatRegeneratedInNewChat;

  /// No description provided for @chatOpenedInNewChatReattach.
  ///
  /// In zh, this message translates to:
  /// **'已在新对话中打开，附件需重新添加'**
  String get chatOpenedInNewChatReattach;

  /// No description provided for @chatOpenedInNewChat.
  ///
  /// In zh, this message translates to:
  /// **'已在新对话中打开'**
  String get chatOpenedInNewChat;

  /// No description provided for @chatForkQueuedLeft.
  ///
  /// In zh, this message translates to:
  /// **'{message}（{left} 条排队消息未能带走）'**
  String chatForkQueuedLeft(String message, int left);

  /// No description provided for @chatReturnToOriginal.
  ///
  /// In zh, this message translates to:
  /// **'返回原对话'**
  String get chatReturnToOriginal;

  /// No description provided for @chatWaitingCount.
  ///
  /// In zh, this message translates to:
  /// **'{count} 项待确认'**
  String chatWaitingCount(int count);

  /// No description provided for @chatWaitingBackToBottom.
  ///
  /// In zh, this message translates to:
  /// **'{count} 项待确认，回到底部'**
  String chatWaitingBackToBottom(int count);

  /// No description provided for @chatBackToBottom.
  ///
  /// In zh, this message translates to:
  /// **'回到底部'**
  String get chatBackToBottom;

  /// No description provided for @chatCreateFailed.
  ///
  /// In zh, this message translates to:
  /// **'新建对话失败'**
  String get chatCreateFailed;

  /// No description provided for @chatSendMode.
  ///
  /// In zh, this message translates to:
  /// **'发送方式'**
  String get chatSendMode;

  /// No description provided for @chatSteer.
  ///
  /// In zh, this message translates to:
  /// **'插话'**
  String get chatSteer;

  /// No description provided for @chatSteerHint.
  ///
  /// In zh, this message translates to:
  /// **'不打断，AI 下一步会看到'**
  String get chatSteerHint;

  /// No description provided for @chatInterruptAndSend.
  ///
  /// In zh, this message translates to:
  /// **'中断并发送'**
  String get chatInterruptAndSend;

  /// No description provided for @chatInterruptHint.
  ///
  /// In zh, this message translates to:
  /// **'停下当前任务，先处理这条'**
  String get chatInterruptHint;

  /// No description provided for @chatQueue.
  ///
  /// In zh, this message translates to:
  /// **'排队'**
  String get chatQueue;

  /// No description provided for @chatQueueHint.
  ///
  /// In zh, this message translates to:
  /// **'本轮结束后发送'**
  String get chatQueueHint;

  /// No description provided for @chatWithdrawnEditable.
  ///
  /// In zh, this message translates to:
  /// **'已撤回，可修改后再发'**
  String get chatWithdrawnEditable;

  /// No description provided for @chatWithdrawn.
  ///
  /// In zh, this message translates to:
  /// **'已撤回'**
  String get chatWithdrawn;

  /// No description provided for @chatAttachmentLimit.
  ///
  /// In zh, this message translates to:
  /// **'每条消息最多 {count} 个附件'**
  String chatAttachmentLimit(int count);

  /// No description provided for @chatAttachmentPermission.
  ///
  /// In zh, this message translates to:
  /// **'没有权限，可在系统设置中开启'**
  String get chatAttachmentPermission;

  /// No description provided for @chatOpenAttachmentFailed.
  ///
  /// In zh, this message translates to:
  /// **'没能打开附件'**
  String get chatOpenAttachmentFailed;

  /// No description provided for @chatReadFailed.
  ///
  /// In zh, this message translates to:
  /// **'读取失败'**
  String get chatReadFailed;

  /// No description provided for @chatReadImageFailed.
  ///
  /// In zh, this message translates to:
  /// **'没能读取图片'**
  String get chatReadImageFailed;

  /// No description provided for @chatOpenChatFirst.
  ///
  /// In zh, this message translates to:
  /// **'先打开一个对话'**
  String get chatOpenChatFirst;

  /// No description provided for @chatTurnCompleted.
  ///
  /// In zh, this message translates to:
  /// **'这一轮已完成'**
  String get chatTurnCompleted;

  /// No description provided for @chatTurnError.
  ///
  /// In zh, this message translates to:
  /// **'这一轮出错了'**
  String get chatTurnError;

  /// No description provided for @chatAnswerHint.
  ///
  /// In zh, this message translates to:
  /// **'输入回答…'**
  String get chatAnswerHint;

  /// No description provided for @chatStarting.
  ///
  /// In zh, this message translates to:
  /// **'正在启动'**
  String get chatStarting;

  /// No description provided for @chatConnecting.
  ///
  /// In zh, this message translates to:
  /// **'正在连接'**
  String get chatConnecting;

  /// No description provided for @chatDisconnected.
  ///
  /// In zh, this message translates to:
  /// **'连接已断开'**
  String get chatDisconnected;

  /// No description provided for @chatReconnecting.
  ///
  /// In zh, this message translates to:
  /// **'重新连接中'**
  String get chatReconnecting;

  /// No description provided for @chatGenerating.
  ///
  /// In zh, this message translates to:
  /// **'生成中'**
  String get chatGenerating;

  /// No description provided for @chatGoToSettings.
  ///
  /// In zh, this message translates to:
  /// **'去设置'**
  String get chatGoToSettings;

  /// No description provided for @chatListeningEllipsis.
  ///
  /// In zh, this message translates to:
  /// **'正在聆听…'**
  String get chatListeningEllipsis;

  /// No description provided for @chatTranscribingEllipsis.
  ///
  /// In zh, this message translates to:
  /// **'正在转写…'**
  String get chatTranscribingEllipsis;

  /// No description provided for @chatConnectToSend.
  ///
  /// In zh, this message translates to:
  /// **'连接引擎后即可发送'**
  String get chatConnectToSend;

  /// No description provided for @chatGeneratingSteerHint.
  ///
  /// In zh, this message translates to:
  /// **'生成中 · 可直接插话'**
  String get chatGeneratingSteerHint;

  /// No description provided for @chatComposerHint.
  ///
  /// In zh, this message translates to:
  /// **'给 DSH 发消息…'**
  String get chatComposerHint;

  /// No description provided for @chatStopGenerating.
  ///
  /// In zh, this message translates to:
  /// **'停止生成'**
  String get chatStopGenerating;

  /// No description provided for @chatVoiceInput.
  ///
  /// In zh, this message translates to:
  /// **'语音输入'**
  String get chatVoiceInput;

  /// No description provided for @chatStopVoiceInput.
  ///
  /// In zh, this message translates to:
  /// **'停止语音输入'**
  String get chatStopVoiceInput;

  /// No description provided for @chatGoal.
  ///
  /// In zh, this message translates to:
  /// **'目标'**
  String get chatGoal;

  /// No description provided for @chatGoalActions.
  ///
  /// In zh, this message translates to:
  /// **'目标操作'**
  String get chatGoalActions;

  /// No description provided for @chatGoalBlocked.
  ///
  /// In zh, this message translates to:
  /// **'受阻'**
  String get chatGoalBlocked;

  /// No description provided for @chatGoalRoundLimit.
  ///
  /// In zh, this message translates to:
  /// **'第 {rounds} / {max} 轮'**
  String chatGoalRoundLimit(int rounds, int max);

  /// No description provided for @chatGoalRound.
  ///
  /// In zh, this message translates to:
  /// **'第 {rounds} 轮'**
  String chatGoalRound(int rounds);

  /// No description provided for @chatEditGoal.
  ///
  /// In zh, this message translates to:
  /// **'编辑目标'**
  String get chatEditGoal;

  /// No description provided for @chatPauseGoal.
  ///
  /// In zh, this message translates to:
  /// **'暂停'**
  String get chatPauseGoal;

  /// No description provided for @chatPauseGoalHint.
  ///
  /// In zh, this message translates to:
  /// **'先不自动推进'**
  String get chatPauseGoalHint;

  /// No description provided for @chatResumeGoal.
  ///
  /// In zh, this message translates to:
  /// **'恢复'**
  String get chatResumeGoal;

  /// No description provided for @chatResumeGoalHint.
  ///
  /// In zh, this message translates to:
  /// **'继续自动推进'**
  String get chatResumeGoalHint;

  /// No description provided for @chatClearGoal.
  ///
  /// In zh, this message translates to:
  /// **'清除目标'**
  String get chatClearGoal;

  /// No description provided for @chatGoalHint.
  ///
  /// In zh, this message translates to:
  /// **'要完成什么'**
  String get chatGoalHint;

  /// No description provided for @chatClearGoalTitle.
  ///
  /// In zh, this message translates to:
  /// **'清除目标？'**
  String get chatClearGoalTitle;

  /// No description provided for @chatTodoCurrent.
  ///
  /// In zh, this message translates to:
  /// **'正在：{content}'**
  String chatTodoCurrent(String content);

  /// No description provided for @chatTodoNext.
  ///
  /// In zh, this message translates to:
  /// **'下一步：{content}'**
  String chatTodoNext(String content);

  /// No description provided for @chatTodoAllDone.
  ///
  /// In zh, this message translates to:
  /// **'全部完成'**
  String get chatTodoAllDone;

  /// No description provided for @chatTodoSemantics.
  ///
  /// In zh, this message translates to:
  /// **'待办 {count}，{label}'**
  String chatTodoSemantics(String count, String label);

  /// No description provided for @chatCollapseTodos.
  ///
  /// In zh, this message translates to:
  /// **'收起清单'**
  String get chatCollapseTodos;

  /// No description provided for @chatExpandTodos.
  ///
  /// In zh, this message translates to:
  /// **'展开清单'**
  String get chatExpandTodos;

  /// No description provided for @chatDockFolded.
  ///
  /// In zh, this message translates to:
  /// **'{count} 条状态已叠起'**
  String chatDockFolded(int count);

  /// No description provided for @chatDockSpread.
  ///
  /// In zh, this message translates to:
  /// **'展开'**
  String get chatDockSpread;

  /// No description provided for @chatDockFold.
  ///
  /// In zh, this message translates to:
  /// **'收起状态条'**
  String get chatDockFold;

  /// No description provided for @chatDockNext.
  ///
  /// In zh, this message translates to:
  /// **'下一张'**
  String get chatDockNext;

  /// No description provided for @chatDockPrevious.
  ///
  /// In zh, this message translates to:
  /// **'上一张'**
  String get chatDockPrevious;

  /// No description provided for @chatTodoNotStarted.
  ///
  /// In zh, this message translates to:
  /// **'未开始'**
  String get chatTodoNotStarted;

  /// No description provided for @chatFile.
  ///
  /// In zh, this message translates to:
  /// **'文件'**
  String get chatFile;

  /// No description provided for @chatFolder.
  ///
  /// In zh, this message translates to:
  /// **'文件夹'**
  String get chatFolder;

  /// No description provided for @chatChat.
  ///
  /// In zh, this message translates to:
  /// **'对话'**
  String get chatChat;

  /// No description provided for @chatSubagent.
  ///
  /// In zh, this message translates to:
  /// **'子代理'**
  String get chatSubagent;

  /// No description provided for @chatRecent.
  ///
  /// In zh, this message translates to:
  /// **'最近'**
  String get chatRecent;

  /// No description provided for @chatMentionSearching.
  ///
  /// In zh, this message translates to:
  /// **'正在查找…'**
  String get chatMentionSearching;

  /// No description provided for @chatMentionNoFiles.
  ///
  /// In zh, this message translates to:
  /// **'没有匹配的文件'**
  String get chatMentionNoFiles;

  /// No description provided for @chatMentionNoMatches.
  ///
  /// In zh, this message translates to:
  /// **'没有匹配的文件或对话'**
  String get chatMentionNoMatches;

  /// No description provided for @chatQuote.
  ///
  /// In zh, this message translates to:
  /// **'引用'**
  String get chatQuote;

  /// No description provided for @chatOpenFolder.
  ///
  /// In zh, this message translates to:
  /// **'打开文件夹'**
  String get chatOpenFolder;

  /// No description provided for @chatJustNow.
  ///
  /// In zh, this message translates to:
  /// **'刚刚'**
  String get chatJustNow;

  /// No description provided for @chatMentionAgeMinutes.
  ///
  /// In zh, this message translates to:
  /// **'{count}分钟'**
  String chatMentionAgeMinutes(int count);

  /// No description provided for @chatMentionAgeHours.
  ///
  /// In zh, this message translates to:
  /// **'{count}小时'**
  String chatMentionAgeHours(int count);

  /// No description provided for @chatMentionAgeDays.
  ///
  /// In zh, this message translates to:
  /// **'{count}天'**
  String chatMentionAgeDays(int count);

  /// No description provided for @chatMentionAgeMonths.
  ///
  /// In zh, this message translates to:
  /// **'{count}个月'**
  String chatMentionAgeMonths(int count);

  /// No description provided for @chatMentionAgeYears.
  ///
  /// In zh, this message translates to:
  /// **'{count}年'**
  String chatMentionAgeYears(int count);

  /// No description provided for @chatMermaidChart.
  ///
  /// In zh, this message translates to:
  /// **'Mermaid 图表'**
  String get chatMermaidChart;

  /// No description provided for @chatPreview.
  ///
  /// In zh, this message translates to:
  /// **'预览'**
  String get chatPreview;

  /// No description provided for @chatUnwrapLines.
  ///
  /// In zh, this message translates to:
  /// **'不换行'**
  String get chatUnwrapLines;

  /// No description provided for @chatWrapLines.
  ///
  /// In zh, this message translates to:
  /// **'自动换行'**
  String get chatWrapLines;

  /// No description provided for @chatAlertNote.
  ///
  /// In zh, this message translates to:
  /// **'注意'**
  String get chatAlertNote;

  /// No description provided for @chatAlertTip.
  ///
  /// In zh, this message translates to:
  /// **'提示'**
  String get chatAlertTip;

  /// No description provided for @chatAlertImportant.
  ///
  /// In zh, this message translates to:
  /// **'重要'**
  String get chatAlertImportant;

  /// No description provided for @chatAlertWarning.
  ///
  /// In zh, this message translates to:
  /// **'警告'**
  String get chatAlertWarning;

  /// No description provided for @chatAlertCaution.
  ///
  /// In zh, this message translates to:
  /// **'小心'**
  String get chatAlertCaution;

  /// No description provided for @chatImage.
  ///
  /// In zh, this message translates to:
  /// **'图片'**
  String get chatImage;

  /// No description provided for @chatImageNotFound.
  ///
  /// In zh, this message translates to:
  /// **'找不到图片'**
  String get chatImageNotFound;

  /// No description provided for @chatImageOffline.
  ///
  /// In zh, this message translates to:
  /// **'未连接 DSH'**
  String get chatImageOffline;

  /// No description provided for @chatImageTooLarge.
  ///
  /// In zh, this message translates to:
  /// **'图片过大'**
  String get chatImageTooLarge;

  /// No description provided for @chatImageReadFailed.
  ///
  /// In zh, this message translates to:
  /// **'无法读取文件'**
  String get chatImageReadFailed;

  /// No description provided for @chatImageDisplayFailed.
  ///
  /// In zh, this message translates to:
  /// **'无法显示'**
  String get chatImageDisplayFailed;

  /// No description provided for @chatImageTapToView.
  ///
  /// In zh, this message translates to:
  /// **'轻点查看'**
  String get chatImageTapToView;

  /// No description provided for @chatImageTapToRetry.
  ///
  /// In zh, this message translates to:
  /// **'轻点重试'**
  String get chatImageTapToRetry;

  /// No description provided for @chatImageUnsupportedAddress.
  ///
  /// In zh, this message translates to:
  /// **'不支持的地址'**
  String get chatImageUnsupportedAddress;

  /// No description provided for @chatMermaidNeedsNetwork.
  ///
  /// In zh, this message translates to:
  /// **'需要联网'**
  String get chatMermaidNeedsNetwork;

  /// No description provided for @chatMermaidSyntaxError.
  ///
  /// In zh, this message translates to:
  /// **'图表语法有误'**
  String get chatMermaidSyntaxError;

  /// No description provided for @chatChartPreview.
  ///
  /// In zh, this message translates to:
  /// **'图表预览'**
  String get chatChartPreview;

  /// No description provided for @chatCopyCode.
  ///
  /// In zh, this message translates to:
  /// **'复制代码'**
  String get chatCopyCode;

  /// No description provided for @chatChartClosed.
  ///
  /// In zh, this message translates to:
  /// **'图表已关闭'**
  String get chatChartClosed;

  /// No description provided for @chatVoiceMicrophoneFailed.
  ///
  /// In zh, this message translates to:
  /// **'没能打开麦克风'**
  String get chatVoiceMicrophoneFailed;

  /// No description provided for @chatVoicePermissionOff.
  ///
  /// In zh, this message translates to:
  /// **'麦克风权限已关闭'**
  String get chatVoicePermissionOff;

  /// No description provided for @chatVoicePermissionNeeded.
  ///
  /// In zh, this message translates to:
  /// **'需要麦克风权限才能语音输入'**
  String get chatVoicePermissionNeeded;

  /// No description provided for @chatVoiceUnavailable.
  ///
  /// In zh, this message translates to:
  /// **'这台手机没有可用的语音识别'**
  String get chatVoiceUnavailable;

  /// No description provided for @chatVoiceNotHeard.
  ///
  /// In zh, this message translates to:
  /// **'没有听清，再说一次'**
  String get chatVoiceNotHeard;

  /// No description provided for @chatVoiceTranscriptionFailed.
  ///
  /// In zh, this message translates to:
  /// **'没能转写这段语音'**
  String get chatVoiceTranscriptionFailed;

  /// No description provided for @chatVoiceNetworkFailed.
  ///
  /// In zh, this message translates to:
  /// **'网络不太好，没能识别'**
  String get chatVoiceNetworkFailed;

  /// No description provided for @chatVoiceLanguageUnsupported.
  ///
  /// In zh, this message translates to:
  /// **'暂不支持这种语言'**
  String get chatVoiceLanguageUnsupported;

  /// No description provided for @chatVoiceMicrophoneBusy.
  ///
  /// In zh, this message translates to:
  /// **'麦克风正被占用'**
  String get chatVoiceMicrophoneBusy;

  /// No description provided for @chatVoiceBusy.
  ///
  /// In zh, this message translates to:
  /// **'语音识别正忙，稍后再试'**
  String get chatVoiceBusy;

  /// No description provided for @chatVoiceRecognitionFailed.
  ///
  /// In zh, this message translates to:
  /// **'语音识别出错了'**
  String get chatVoiceRecognitionFailed;

  /// No description provided for @chatListening.
  ///
  /// In zh, this message translates to:
  /// **'正在聆听'**
  String get chatListening;

  /// No description provided for @chatTranscribing.
  ///
  /// In zh, this message translates to:
  /// **'正在转写'**
  String get chatTranscribing;

  /// No description provided for @chatCancelVoiceInput.
  ///
  /// In zh, this message translates to:
  /// **'取消语音输入'**
  String get chatCancelVoiceInput;

  /// No description provided for @chatViewTurnTrace.
  ///
  /// In zh, this message translates to:
  /// **'查看本轮轨迹'**
  String get chatViewTurnTrace;

  /// No description provided for @chatTokensPerSecond.
  ///
  /// In zh, this message translates to:
  /// **'约 {count} tokens/秒'**
  String chatTokensPerSecond(int count);

  /// No description provided for @chatNoTokensStreaming.
  ///
  /// In zh, this message translates to:
  /// **'没有在出字'**
  String get chatNoTokensStreaming;

  /// No description provided for @chatCurrentStep.
  ///
  /// In zh, this message translates to:
  /// **'这一步 {step}'**
  String chatCurrentStep(String step);

  /// No description provided for @chatTodoProgress.
  ///
  /// In zh, this message translates to:
  /// **'待办进度 {done}/{total}'**
  String chatTodoProgress(int done, int total);

  /// No description provided for @chatProgress.
  ///
  /// In zh, this message translates to:
  /// **'进度 {done}/{total}'**
  String chatProgress(int done, int total);

  /// No description provided for @chatApproveCommand.
  ///
  /// In zh, this message translates to:
  /// **'允许运行这条命令？'**
  String get chatApproveCommand;

  /// No description provided for @chatApproveWrite.
  ///
  /// In zh, this message translates to:
  /// **'允许写入这个文件？'**
  String get chatApproveWrite;

  /// No description provided for @chatApproveEdit.
  ///
  /// In zh, this message translates to:
  /// **'允许修改这个文件？'**
  String get chatApproveEdit;

  /// No description provided for @chatApproveWebpage.
  ///
  /// In zh, this message translates to:
  /// **'允许打开这个网页？'**
  String get chatApproveWebpage;

  /// No description provided for @chatApproveSearch.
  ///
  /// In zh, this message translates to:
  /// **'允许联网搜索？'**
  String get chatApproveSearch;

  /// No description provided for @chatApproveTool.
  ///
  /// In zh, this message translates to:
  /// **'允许使用「{name}」？'**
  String chatApproveTool(String name);

  /// No description provided for @chatDecline.
  ///
  /// In zh, this message translates to:
  /// **'拒绝'**
  String get chatDecline;

  /// No description provided for @chatAllowOnce.
  ///
  /// In zh, this message translates to:
  /// **'允许本次'**
  String get chatAllowOnce;

  /// No description provided for @chatAllowForChat.
  ///
  /// In zh, this message translates to:
  /// **'本对话都允许'**
  String get chatAllowForChat;

  /// No description provided for @chatSaveToDownloads.
  ///
  /// In zh, this message translates to:
  /// **'存到「下载」'**
  String get chatSaveToDownloads;

  /// No description provided for @chatCopyPath.
  ///
  /// In zh, this message translates to:
  /// **'复制路径'**
  String get chatCopyPath;

  /// No description provided for @chatOpenInDefaultApp.
  ///
  /// In zh, this message translates to:
  /// **'用默认应用打开'**
  String get chatOpenInDefaultApp;

  /// No description provided for @chatDownloadsFolderHint.
  ///
  /// In zh, this message translates to:
  /// **'下载/DSH-Go 文件夹'**
  String get chatDownloadsFolderHint;

  /// No description provided for @chatSavedToDownloadsPath.
  ///
  /// In zh, this message translates to:
  /// **'已存到 下载/{path}'**
  String chatSavedToDownloadsPath(String path);

  /// No description provided for @chatSavedToPath.
  ///
  /// In zh, this message translates to:
  /// **'已存到 {path}'**
  String chatSavedToPath(String path);

  /// No description provided for @chatDeliveredFiles.
  ///
  /// In zh, this message translates to:
  /// **'交付了 {count} 个文件'**
  String chatDeliveredFiles(int count);

  /// No description provided for @chatGeneratedFiles.
  ///
  /// In zh, this message translates to:
  /// **'生成了 {count} 个文件'**
  String chatGeneratedFiles(int count);

  /// No description provided for @chatAllFiles.
  ///
  /// In zh, this message translates to:
  /// **'全部 {count} 个文件'**
  String chatAllFiles(int count);

  /// No description provided for @chatCollapseFileList.
  ///
  /// In zh, this message translates to:
  /// **'收起文件列表'**
  String get chatCollapseFileList;

  /// No description provided for @chatExpandAllFiles.
  ///
  /// In zh, this message translates to:
  /// **'展开全部 {count} 个文件'**
  String chatExpandAllFiles(int count);

  /// No description provided for @chatDownloading.
  ///
  /// In zh, this message translates to:
  /// **'正在下载…'**
  String get chatDownloading;

  /// No description provided for @chatDownloadingPercent.
  ///
  /// In zh, this message translates to:
  /// **'正在下载… {percent}%'**
  String chatDownloadingPercent(int percent);

  /// No description provided for @chatOpening.
  ///
  /// In zh, this message translates to:
  /// **'正在打开…'**
  String get chatOpening;

  /// No description provided for @chatSavingToDownloads.
  ///
  /// In zh, this message translates to:
  /// **'正在存到「下载」…'**
  String get chatSavingToDownloads;

  /// No description provided for @chatOpenInPhoneApp.
  ///
  /// In zh, this message translates to:
  /// **'用手机上的应用打开'**
  String get chatOpenInPhoneApp;

  /// No description provided for @chatMoreActions.
  ///
  /// In zh, this message translates to:
  /// **'更多操作'**
  String get chatMoreActions;

  /// No description provided for @chatAlreadyInDownloads.
  ///
  /// In zh, this message translates to:
  /// **'已在手机的「下载」里'**
  String get chatAlreadyInDownloads;

  /// No description provided for @chatArtifactCopyPathOnly.
  ///
  /// In zh, this message translates to:
  /// **'当前连接无法读取文件，只能复制路径'**
  String get chatArtifactCopyPathOnly;

  /// No description provided for @chatReplying.
  ///
  /// In zh, this message translates to:
  /// **'正在回复'**
  String get chatReplying;

  /// No description provided for @chatInterrupted.
  ///
  /// In zh, this message translates to:
  /// **'已中断'**
  String get chatInterrupted;

  /// No description provided for @chatGallery.
  ///
  /// In zh, this message translates to:
  /// **'相册'**
  String get chatGallery;

  /// No description provided for @chatTakePhoto.
  ///
  /// In zh, this message translates to:
  /// **'拍照'**
  String get chatTakePhoto;

  /// No description provided for @chatAddAttachment.
  ///
  /// In zh, this message translates to:
  /// **'添加图片或文件'**
  String get chatAddAttachment;

  /// No description provided for @chatRemoveAttachment.
  ///
  /// In zh, this message translates to:
  /// **'移除「{name}」'**
  String chatRemoveAttachment(String name);

  /// No description provided for @chatAutoApproveCommands.
  ///
  /// In zh, this message translates to:
  /// **'自动允许命令'**
  String get chatAutoApproveCommands;

  /// No description provided for @chatAutoApproving.
  ///
  /// In zh, this message translates to:
  /// **'自动允许中'**
  String get chatAutoApproving;

  /// No description provided for @chatViewMoreChanges.
  ///
  /// In zh, this message translates to:
  /// **'查看改动，还有 {count} 个文件'**
  String chatViewMoreChanges(int count);

  /// No description provided for @chatViewChanges.
  ///
  /// In zh, this message translates to:
  /// **'查看改动'**
  String get chatViewChanges;

  /// No description provided for @chatChangedFiles.
  ///
  /// In zh, this message translates to:
  /// **'改动了 {count} 个文件'**
  String chatChangedFiles(int count);

  /// No description provided for @chatMoreFiles.
  ///
  /// In zh, this message translates to:
  /// **'还有 {count} 个文件'**
  String chatMoreFiles(int count);

  /// No description provided for @chatFileChangeSemantics.
  ///
  /// In zh, this message translates to:
  /// **'{path}，新增 {added} 行，删除 {removed} 行'**
  String chatFileChangeSemantics(String path, int added, int removed);

  /// No description provided for @chatNewFileSuffix.
  ///
  /// In zh, this message translates to:
  /// **'  新建'**
  String get chatNewFileSuffix;

  /// No description provided for @chatPathCopied.
  ///
  /// In zh, this message translates to:
  /// **'已复制路径'**
  String get chatPathCopied;

  /// No description provided for @chatCommandCompacted.
  ///
  /// In zh, this message translates to:
  /// **'已压缩 {count} 条历史记录（约 {tokens} tokens）'**
  String chatCommandCompacted(int count, String tokens);

  /// No description provided for @chatCommandPermissionChanged.
  ///
  /// In zh, this message translates to:
  /// **'已切换为{name}'**
  String chatCommandPermissionChanged(String name);

  /// No description provided for @chatCommandCurrentPermission.
  ///
  /// In zh, this message translates to:
  /// **'当前权限：{name}'**
  String chatCommandCurrentPermission(String name);

  /// No description provided for @chatCommandUnknownPermission.
  ///
  /// In zh, this message translates to:
  /// **'没有这个权限预设'**
  String get chatCommandUnknownPermission;

  /// No description provided for @chatCommandFeedbackRequired.
  ///
  /// In zh, this message translates to:
  /// **'写上反馈内容再发送'**
  String get chatCommandFeedbackRequired;

  /// No description provided for @chatCommandFeedbackSubmitted.
  ///
  /// In zh, this message translates to:
  /// **'反馈已提交'**
  String get chatCommandFeedbackSubmitted;

  /// No description provided for @chatCommandNothingToCompact.
  ///
  /// In zh, this message translates to:
  /// **'还没有可压缩的内容'**
  String get chatCommandNothingToCompact;

  /// No description provided for @chatCommandCompactionCancelled.
  ///
  /// In zh, this message translates to:
  /// **'已取消压缩'**
  String get chatCommandCompactionCancelled;

  /// No description provided for @chatCommandCompactionBusy.
  ///
  /// In zh, this message translates to:
  /// **'正在忙，稍后再压缩'**
  String get chatCommandCompactionBusy;

  /// No description provided for @chatCommandCompactedSaveFailed.
  ///
  /// In zh, this message translates to:
  /// **'已压缩，但没能保存'**
  String get chatCommandCompactedSaveFailed;

  /// No description provided for @chatCommandCompactUsage.
  ///
  /// In zh, this message translates to:
  /// **'/compact 不带参数'**
  String get chatCommandCompactUsage;

  /// No description provided for @chatCommandHistoryChanged.
  ///
  /// In zh, this message translates to:
  /// **'对话有变化，请再试一次'**
  String get chatCommandHistoryChanged;

  /// No description provided for @chatCommandCompactionFailed.
  ///
  /// In zh, this message translates to:
  /// **'没能完成压缩，请再试一次'**
  String get chatCommandCompactionFailed;

  /// No description provided for @chatCommandCompactionIncomplete.
  ///
  /// In zh, this message translates to:
  /// **'压缩未完成，请查看对话'**
  String get chatCommandCompactionIncomplete;

  /// No description provided for @chatCommandPlanEnabled.
  ///
  /// In zh, this message translates to:
  /// **'已进入计划模式'**
  String get chatCommandPlanEnabled;

  /// No description provided for @chatCommandPlanEnabling.
  ///
  /// In zh, this message translates to:
  /// **'下一步起进入计划模式'**
  String get chatCommandPlanEnabling;

  /// No description provided for @chatCommandPlanDisabled.
  ///
  /// In zh, this message translates to:
  /// **'已退出计划模式'**
  String get chatCommandPlanDisabled;

  /// No description provided for @chatCommandPlanDisabling.
  ///
  /// In zh, this message translates to:
  /// **'下一步起退出计划模式'**
  String get chatCommandPlanDisabling;

  /// No description provided for @chatCommandPlanCancelled.
  ///
  /// In zh, this message translates to:
  /// **'已取消进入计划模式'**
  String get chatCommandPlanCancelled;

  /// No description provided for @chatCommandPlanInactive.
  ///
  /// In zh, this message translates to:
  /// **'当前未开启计划模式'**
  String get chatCommandPlanInactive;

  /// No description provided for @chatCommandPlanNoAttachments.
  ///
  /// In zh, this message translates to:
  /// **'退出计划模式时不能附带文件'**
  String get chatCommandPlanNoAttachments;

  /// No description provided for @chatCommandNoGoal.
  ///
  /// In zh, this message translates to:
  /// **'还没有目标'**
  String get chatCommandNoGoal;

  /// No description provided for @chatCommandGoalRequired.
  ///
  /// In zh, this message translates to:
  /// **'写上新的目标再发送'**
  String get chatCommandGoalRequired;

  /// No description provided for @chatCommandGoalAttachments.
  ///
  /// In zh, this message translates to:
  /// **'附件需要和目标一起发送'**
  String get chatCommandGoalAttachments;

  /// No description provided for @chatCommandGoalCleared.
  ///
  /// In zh, this message translates to:
  /// **'已清除目标'**
  String get chatCommandGoalCleared;

  /// No description provided for @chatCommandGoalInvalid.
  ///
  /// In zh, this message translates to:
  /// **'当前无法执行，请查看目标'**
  String get chatCommandGoalInvalid;

  /// No description provided for @chatCommandGoalExists.
  ///
  /// In zh, this message translates to:
  /// **'已有目标，请编辑或清除后再设置'**
  String get chatCommandGoalExists;

  /// No description provided for @chatCommandGoalCreated.
  ///
  /// In zh, this message translates to:
  /// **'已设置目标'**
  String get chatCommandGoalCreated;

  /// No description provided for @chatCommandGoalUpdated.
  ///
  /// In zh, this message translates to:
  /// **'已更新目标'**
  String get chatCommandGoalUpdated;

  /// No description provided for @chatCommandGoalPaused.
  ///
  /// In zh, this message translates to:
  /// **'已暂停目标'**
  String get chatCommandGoalPaused;

  /// No description provided for @chatCommandGoalResumed.
  ///
  /// In zh, this message translates to:
  /// **'已继续目标'**
  String get chatCommandGoalResumed;

  /// No description provided for @chatCommandCurrentGoal.
  ///
  /// In zh, this message translates to:
  /// **'当前目标'**
  String get chatCommandCurrentGoal;

  /// No description provided for @chatCommandGoalBlocked.
  ///
  /// In zh, this message translates to:
  /// **'等待处理'**
  String get chatCommandGoalBlocked;

  /// No description provided for @chatCommandGoalSummary.
  ///
  /// In zh, this message translates to:
  /// **'{title}\n{objective}\n{status} · 第 {rounds}/{max} 轮'**
  String chatCommandGoalSummary(String title, String objective, String status, int rounds, int max);

  /// No description provided for @chatCommandFailed.
  ///
  /// In zh, this message translates to:
  /// **'执行失败'**
  String get chatCommandFailed;

  /// No description provided for @chatImageStorageDenied.
  ///
  /// In zh, this message translates to:
  /// **'没有存储权限，未能保存'**
  String get chatImageStorageDenied;

  /// No description provided for @chatImageCannotSave.
  ///
  /// In zh, this message translates to:
  /// **'这张图片无法保存'**
  String get chatImageCannotSave;

  /// No description provided for @chatImageDownloadFailed.
  ///
  /// In zh, this message translates to:
  /// **'图片下载失败，请重试'**
  String get chatImageDownloadFailed;

  /// No description provided for @chatImageSaveFailed.
  ///
  /// In zh, this message translates to:
  /// **'保存失败，请重试'**
  String get chatImageSaveFailed;

  /// No description provided for @chatImageSavedToPhotos.
  ///
  /// In zh, this message translates to:
  /// **'已保存到相册'**
  String get chatImageSavedToPhotos;

  /// No description provided for @chatShareFailed.
  ///
  /// In zh, this message translates to:
  /// **'无法打开分享'**
  String get chatShareFailed;

  /// No description provided for @chatSubmit.
  ///
  /// In zh, this message translates to:
  /// **'提交'**
  String get chatSubmit;

  /// No description provided for @chatSelectText.
  ///
  /// In zh, this message translates to:
  /// **'选择文字'**
  String get chatSelectText;

  /// No description provided for @chatRegenerate.
  ///
  /// In zh, this message translates to:
  /// **'重新回答'**
  String get chatRegenerate;

  /// No description provided for @chatBranchFromHere.
  ///
  /// In zh, this message translates to:
  /// **'从这里分叉'**
  String get chatBranchFromHere;

  /// No description provided for @chatEditAndResend.
  ///
  /// In zh, this message translates to:
  /// **'编辑后重发'**
  String get chatEditAndResend;

  /// No description provided for @chatRegenerateHint.
  ///
  /// In zh, this message translates to:
  /// **'在新对话中重新生成，原对话不变'**
  String get chatRegenerateHint;

  /// No description provided for @chatBranchHint.
  ///
  /// In zh, this message translates to:
  /// **'在新对话中继续，原对话不变'**
  String get chatBranchHint;

  /// No description provided for @chatEditResendHint.
  ///
  /// In zh, this message translates to:
  /// **'在新对话中改写，原对话不变'**
  String get chatEditResendHint;

  /// No description provided for @chatSaveToPhotos.
  ///
  /// In zh, this message translates to:
  /// **'保存到相册'**
  String get chatSaveToPhotos;

  /// No description provided for @chatCopyAll.
  ///
  /// In zh, this message translates to:
  /// **'全部复制'**
  String get chatCopyAll;

  /// No description provided for @chatRequestRetrying.
  ///
  /// In zh, this message translates to:
  /// **'请求失败，正在重试'**
  String get chatRequestRetrying;

  /// No description provided for @chatRequestRetryAttempt.
  ///
  /// In zh, this message translates to:
  /// **'请求失败，正在重试（第 {count} 次）'**
  String chatRequestRetryAttempt(int count);

  /// No description provided for @chatRequestRetryLimit.
  ///
  /// In zh, this message translates to:
  /// **'请求失败，正在重试（{count}/{max}）'**
  String chatRequestRetryLimit(int count, int max);

  /// No description provided for @chatSubscriptionExpired.
  ///
  /// In zh, this message translates to:
  /// **'{name} 登录已失效'**
  String chatSubscriptionExpired(String name);

  /// No description provided for @chatProviderKeyMissing.
  ///
  /// In zh, this message translates to:
  /// **'这个模型渠道还没有密钥'**
  String get chatProviderKeyMissing;

  /// No description provided for @chatDeepSeekKeyMissing.
  ///
  /// In zh, this message translates to:
  /// **'还没有 DeepSeek API Key'**
  String get chatDeepSeekKeyMissing;

  /// No description provided for @chatOutputLimitReached.
  ///
  /// In zh, this message translates to:
  /// **'已达单次输出上限'**
  String get chatOutputLimitReached;

  /// No description provided for @chatTurnBlocked.
  ///
  /// In zh, this message translates to:
  /// **'本轮已被拦截'**
  String get chatTurnBlocked;

  /// No description provided for @chatTurnEngineRestarted.
  ///
  /// In zh, this message translates to:
  /// **'引擎重启过，本轮已中断'**
  String get chatTurnEngineRestarted;

  /// No description provided for @chatSignInAgain.
  ///
  /// In zh, this message translates to:
  /// **'重新登录'**
  String get chatSignInAgain;

  /// No description provided for @chatQuestionsTitle.
  ///
  /// In zh, this message translates to:
  /// **'有 {count} 个问题想问你'**
  String chatQuestionsTitle(int count);

  /// No description provided for @chatOneQuestion.
  ///
  /// In zh, this message translates to:
  /// **'有个问题想问你'**
  String get chatOneQuestion;

  /// No description provided for @chatMultipleChoices.
  ///
  /// In zh, this message translates to:
  /// **'可多选'**
  String get chatMultipleChoices;

  /// No description provided for @chatCustomAnswer.
  ///
  /// In zh, this message translates to:
  /// **'其他回答'**
  String get chatCustomAnswer;

  /// No description provided for @chatCustomAnswerHint.
  ///
  /// In zh, this message translates to:
  /// **'输入你的回答'**
  String get chatCustomAnswerHint;

  /// No description provided for @chatQuoteSemantics.
  ///
  /// In zh, this message translates to:
  /// **'引用：{text}'**
  String chatQuoteSemantics(String text);

  /// No description provided for @chatRemoveQuote.
  ///
  /// In zh, this message translates to:
  /// **'移除引用'**
  String get chatRemoveQuote;

  /// No description provided for @chatReadOnlySubagent.
  ///
  /// In zh, this message translates to:
  /// **'一次性子代理，只能查看'**
  String get chatReadOnlySubagent;

  /// No description provided for @chatThinkingActive.
  ///
  /// In zh, this message translates to:
  /// **'思考中'**
  String get chatThinkingActive;

  /// No description provided for @chatThinking.
  ///
  /// In zh, this message translates to:
  /// **'思考'**
  String get chatThinking;

  /// No description provided for @chatTranslate.
  ///
  /// In zh, this message translates to:
  /// **'翻译'**
  String get chatTranslate;

  /// No description provided for @chatTranslationUnavailable.
  ///
  /// In zh, this message translates to:
  /// **'翻译暂不可用'**
  String get chatTranslationUnavailable;

  /// No description provided for @chatViewOriginal.
  ///
  /// In zh, this message translates to:
  /// **'查看原文'**
  String get chatViewOriginal;

  /// No description provided for @chatViewTranslation.
  ///
  /// In zh, this message translates to:
  /// **'查看译文'**
  String get chatViewTranslation;

  /// No description provided for @chatTranslating.
  ///
  /// In zh, this message translates to:
  /// **'正在翻译'**
  String get chatTranslating;

  /// No description provided for @chatToolFailures.
  ///
  /// In zh, this message translates to:
  /// **'{label},{count} 个失败'**
  String chatToolFailures(String label, int count);

  /// No description provided for @chatToolNeedsApproval.
  ///
  /// In zh, this message translates to:
  /// **'需要授权后才能执行'**
  String get chatToolNeedsApproval;

  /// No description provided for @chatCommand.
  ///
  /// In zh, this message translates to:
  /// **'命令'**
  String get chatCommand;

  /// No description provided for @chatToolLineRange.
  ///
  /// In zh, this message translates to:
  /// **' · 第 {first}⁠–⁠{last} 行'**
  String chatToolLineRange(int first, int last);

  /// No description provided for @chatParameters.
  ///
  /// In zh, this message translates to:
  /// **'参数'**
  String get chatParameters;

  /// No description provided for @chatOutput.
  ///
  /// In zh, this message translates to:
  /// **'输出'**
  String get chatOutput;

  /// No description provided for @chatResult.
  ///
  /// In zh, this message translates to:
  /// **'结果'**
  String get chatResult;

  /// No description provided for @chatError.
  ///
  /// In zh, this message translates to:
  /// **'错误'**
  String get chatError;

  /// No description provided for @chatChanges.
  ///
  /// In zh, this message translates to:
  /// **'改动'**
  String get chatChanges;

  /// No description provided for @chatContent.
  ///
  /// In zh, this message translates to:
  /// **'内容'**
  String get chatContent;

  /// No description provided for @chatNoOutput.
  ///
  /// In zh, this message translates to:
  /// **'没有输出'**
  String get chatNoOutput;

  /// No description provided for @chatToolDeclined.
  ///
  /// In zh, this message translates to:
  /// **'已拒绝这次调用'**
  String get chatToolDeclined;

  /// No description provided for @chatToolRunning.
  ///
  /// In zh, this message translates to:
  /// **'正在执行…'**
  String get chatToolRunning;

  /// No description provided for @chatNoDetails.
  ///
  /// In zh, this message translates to:
  /// **'暂无详情'**
  String get chatNoDetails;

  /// No description provided for @chatErrApiKey.
  ///
  /// In zh, this message translates to:
  /// **'API Key 无效或已过期'**
  String get chatErrApiKey;

  /// No description provided for @chatErrBalance.
  ///
  /// In zh, this message translates to:
  /// **'余额不足'**
  String get chatErrBalance;

  /// No description provided for @chatErrAccountQuota.
  ///
  /// In zh, this message translates to:
  /// **'账号额度已用完'**
  String get chatErrAccountQuota;

  /// No description provided for @chatErrRateLimit.
  ///
  /// In zh, this message translates to:
  /// **'请求太频繁，稍后再试'**
  String get chatErrRateLimit;

  /// No description provided for @chatErrContextLength.
  ///
  /// In zh, this message translates to:
  /// **'对话太长，发送 /compact 压缩后再试'**
  String get chatErrContextLength;

  /// No description provided for @chatErrModelUnavailable.
  ///
  /// In zh, this message translates to:
  /// **'模型服务暂时不可用'**
  String get chatErrModelUnavailable;

  /// No description provided for @chatErrModelTimeout.
  ///
  /// In zh, this message translates to:
  /// **'模型响应超时'**
  String get chatErrModelTimeout;

  /// No description provided for @chatErrModelConnection.
  ///
  /// In zh, this message translates to:
  /// **'没能连上模型服务'**
  String get chatErrModelConnection;

  /// No description provided for @chatErrModelEmpty.
  ///
  /// In zh, this message translates to:
  /// **'模型没有返回内容'**
  String get chatErrModelEmpty;

  /// No description provided for @chatErrEngineOutdated.
  ///
  /// In zh, this message translates to:
  /// **'这个模型需要新版引擎'**
  String get chatErrEngineOutdated;

  /// No description provided for @chatErrModelUnsupported.
  ///
  /// In zh, this message translates to:
  /// **'当前模型不可用'**
  String get chatErrModelUnsupported;

  /// No description provided for @chatSwitchModel.
  ///
  /// In zh, this message translates to:
  /// **'换模型'**
  String get chatSwitchModel;

  /// No description provided for @chatErrTurn.
  ///
  /// In zh, this message translates to:
  /// **'本轮出错了'**
  String get chatErrTurn;

  /// No description provided for @chatTurnSteps.
  ///
  /// In zh, this message translates to:
  /// **'{count} 步'**
  String chatTurnSteps(int count);

  /// No description provided for @chatTurnFootnoteSemantics.
  ///
  /// In zh, this message translates to:
  /// **'本轮 {summary}，查看本轮轨迹'**
  String chatTurnFootnoteSemantics(String summary);

  /// No description provided for @chatTurnToolCalls.
  ///
  /// In zh, this message translates to:
  /// **'{count} 次工具调用'**
  String chatTurnToolCalls(int count);

  /// No description provided for @chatTurnMessages.
  ///
  /// In zh, this message translates to:
  /// **'{count} 条消息'**
  String chatTurnMessages(int count);

  /// No description provided for @chatTurnThoughts.
  ///
  /// In zh, this message translates to:
  /// **'{count} 段思考'**
  String chatTurnThoughts(int count);

  /// No description provided for @chatMe.
  ///
  /// In zh, this message translates to:
  /// **'我'**
  String get chatMe;

  /// No description provided for @chatGoalSemantics.
  ///
  /// In zh, this message translates to:
  /// **'目标，{objective}'**
  String chatGoalSemantics(String objective);

  /// No description provided for @chatGoalStateSemantics.
  ///
  /// In zh, this message translates to:
  /// **'目标，{objective}，{state}'**
  String chatGoalStateSemantics(String objective, String state);

  /// No description provided for @chatTodoItemSemantics.
  ///
  /// In zh, this message translates to:
  /// **'{content}，{state}'**
  String chatTodoItemSemantics(String content, String state);

  /// No description provided for @chatMentionSemantics.
  ///
  /// In zh, this message translates to:
  /// **'{kind}：{label}'**
  String chatMentionSemantics(String kind, String label);

  /// No description provided for @chatArtifactSemantics.
  ///
  /// In zh, this message translates to:
  /// **'{name}，{description}'**
  String chatArtifactSemantics(String name, String description);

  /// No description provided for @commonCancel.
  ///
  /// In zh, this message translates to:
  /// **'取消'**
  String get commonCancel;

  /// No description provided for @commonRetry.
  ///
  /// In zh, this message translates to:
  /// **'重试'**
  String get commonRetry;

  /// No description provided for @commonClose.
  ///
  /// In zh, this message translates to:
  /// **'关闭'**
  String get commonClose;

  /// No description provided for @commonCopied.
  ///
  /// In zh, this message translates to:
  /// **'已复制'**
  String get commonCopied;

  /// No description provided for @commonSave.
  ///
  /// In zh, this message translates to:
  /// **'保存'**
  String get commonSave;

  /// No description provided for @commonSettings.
  ///
  /// In zh, this message translates to:
  /// **'设置'**
  String get commonSettings;

  /// No description provided for @commonBack.
  ///
  /// In zh, this message translates to:
  /// **'返回'**
  String get commonBack;

  /// No description provided for @commonCopy.
  ///
  /// In zh, this message translates to:
  /// **'复制'**
  String get commonCopy;

  /// No description provided for @commonDone.
  ///
  /// In zh, this message translates to:
  /// **'完成'**
  String get commonDone;

  /// No description provided for @commonDelete.
  ///
  /// In zh, this message translates to:
  /// **'删除'**
  String get commonDelete;

  /// No description provided for @commonInstall.
  ///
  /// In zh, this message translates to:
  /// **'安装'**
  String get commonInstall;

  /// No description provided for @commonShare.
  ///
  /// In zh, this message translates to:
  /// **'分享'**
  String get commonShare;

  /// No description provided for @commonAdd.
  ///
  /// In zh, this message translates to:
  /// **'添加'**
  String get commonAdd;

  /// No description provided for @commonEdit.
  ///
  /// In zh, this message translates to:
  /// **'编辑'**
  String get commonEdit;

  /// No description provided for @commonClear.
  ///
  /// In zh, this message translates to:
  /// **'清除'**
  String get commonClear;

  /// No description provided for @commonCollapse.
  ///
  /// In zh, this message translates to:
  /// **'收起'**
  String get commonCollapse;

  /// No description provided for @commonEnable.
  ///
  /// In zh, this message translates to:
  /// **'启用'**
  String get commonEnable;

  /// No description provided for @commonOpen.
  ///
  /// In zh, this message translates to:
  /// **'打开'**
  String get commonOpen;

  /// No description provided for @commonDetails.
  ///
  /// In zh, this message translates to:
  /// **'详情'**
  String get commonDetails;

  /// No description provided for @commonMore.
  ///
  /// In zh, this message translates to:
  /// **'更多'**
  String get commonMore;

  /// No description provided for @commonCreate.
  ///
  /// In zh, this message translates to:
  /// **'创建'**
  String get commonCreate;

  /// No description provided for @commonSend.
  ///
  /// In zh, this message translates to:
  /// **'发送'**
  String get commonSend;

  /// No description provided for @commonStop.
  ///
  /// In zh, this message translates to:
  /// **'停止'**
  String get commonStop;

  /// No description provided for @commonPaste.
  ///
  /// In zh, this message translates to:
  /// **'粘贴'**
  String get commonPaste;

  /// No description provided for @commonHide.
  ///
  /// In zh, this message translates to:
  /// **'隐藏'**
  String get commonHide;

  /// No description provided for @commonLater.
  ///
  /// In zh, this message translates to:
  /// **'稍后'**
  String get commonLater;

  /// No description provided for @commonConfirm.
  ///
  /// In zh, this message translates to:
  /// **'确认'**
  String get commonConfirm;

  /// No description provided for @commonRename.
  ///
  /// In zh, this message translates to:
  /// **'重命名'**
  String get commonRename;

  /// No description provided for @commonContinue.
  ///
  /// In zh, this message translates to:
  /// **'继续'**
  String get commonContinue;

  /// No description provided for @commonNotSet.
  ///
  /// In zh, this message translates to:
  /// **'未设置'**
  String get commonNotSet;

  /// No description provided for @commonDefault.
  ///
  /// In zh, this message translates to:
  /// **'默认'**
  String get commonDefault;

  /// No description provided for @commonSaved.
  ///
  /// In zh, this message translates to:
  /// **'已保存'**
  String get commonSaved;

  /// No description provided for @commonSaveFailed.
  ///
  /// In zh, this message translates to:
  /// **'没能保存'**
  String get commonSaveFailed;

  /// No description provided for @commonSaveFailedRetry.
  ///
  /// In zh, this message translates to:
  /// **'没能保存，请重试'**
  String get commonSaveFailedRetry;

  /// No description provided for @commonFailedTryAgain.
  ///
  /// In zh, this message translates to:
  /// **'没能完成，再试一次'**
  String get commonFailedTryAgain;

  /// No description provided for @commonEngineUnreachable.
  ///
  /// In zh, this message translates to:
  /// **'没能连上引擎'**
  String get commonEngineUnreachable;

  /// No description provided for @commonStorageFull.
  ///
  /// In zh, this message translates to:
  /// **'存储空间不足'**
  String get commonStorageFull;

  /// No description provided for @commonConnectionFailed.
  ///
  /// In zh, this message translates to:
  /// **'连接失败'**
  String get commonConnectionFailed;

  /// No description provided for @commonCopyLink.
  ///
  /// In zh, this message translates to:
  /// **'复制链接'**
  String get commonCopyLink;

  /// No description provided for @commonOpenWith.
  ///
  /// In zh, this message translates to:
  /// **'用其他应用打开'**
  String get commonOpenWith;

  /// No description provided for @commonOpenInWeb.
  ///
  /// In zh, this message translates to:
  /// **'在网页版打开'**
  String get commonOpenInWeb;

  /// No description provided for @commonUntitledChat.
  ///
  /// In zh, this message translates to:
  /// **'未命名对话'**
  String get commonUntitledChat;

  /// No description provided for @commonNewChat.
  ///
  /// In zh, this message translates to:
  /// **'新对话'**
  String get commonNewChat;

  /// No description provided for @commonYesterday.
  ///
  /// In zh, this message translates to:
  /// **'昨天'**
  String get commonYesterday;

  /// No description provided for @commonSignedIn.
  ///
  /// In zh, this message translates to:
  /// **'已登录'**
  String get commonSignedIn;

  /// No description provided for @commonSignIn.
  ///
  /// In zh, this message translates to:
  /// **'登录'**
  String get commonSignIn;

  /// No description provided for @commonSignOut.
  ///
  /// In zh, this message translates to:
  /// **'退出登录'**
  String get commonSignOut;

  /// No description provided for @commonThisPhone.
  ///
  /// In zh, this message translates to:
  /// **'本机'**
  String get commonThisPhone;

  /// No description provided for @commonRemoteHost.
  ///
  /// In zh, this message translates to:
  /// **'远程主机'**
  String get commonRemoteHost;

  /// No description provided for @commonWeb.
  ///
  /// In zh, this message translates to:
  /// **'网页版'**
  String get commonWeb;

  /// No description provided for @commonFollowSystem.
  ///
  /// In zh, this message translates to:
  /// **'跟随系统'**
  String get commonFollowSystem;

  /// No description provided for @commonLight.
  ///
  /// In zh, this message translates to:
  /// **'浅色'**
  String get commonLight;

  /// No description provided for @commonDark.
  ///
  /// In zh, this message translates to:
  /// **'深色'**
  String get commonDark;

  /// No description provided for @commonInProgress.
  ///
  /// In zh, this message translates to:
  /// **'进行中'**
  String get commonInProgress;

  /// No description provided for @commonCompleted.
  ///
  /// In zh, this message translates to:
  /// **'已完成'**
  String get commonCompleted;

  /// No description provided for @commonStopped.
  ///
  /// In zh, this message translates to:
  /// **'已停止'**
  String get commonStopped;

  /// No description provided for @commonCancelled.
  ///
  /// In zh, this message translates to:
  /// **'已取消'**
  String get commonCancelled;

  /// No description provided for @commonRunning.
  ///
  /// In zh, this message translates to:
  /// **'运行中'**
  String get commonRunning;

  /// No description provided for @commonPaused.
  ///
  /// In zh, this message translates to:
  /// **'已暂停'**
  String get commonPaused;

  /// No description provided for @commonDeclined.
  ///
  /// In zh, this message translates to:
  /// **'已拒绝'**
  String get commonDeclined;

  /// No description provided for @commonFailed.
  ///
  /// In zh, this message translates to:
  /// **'失败'**
  String get commonFailed;

  /// No description provided for @commonStopping.
  ///
  /// In zh, this message translates to:
  /// **'正在停止'**
  String get commonStopping;

  /// No description provided for @commonWaitingApproval.
  ///
  /// In zh, this message translates to:
  /// **'等你确认'**
  String get commonWaitingApproval;

  /// No description provided for @commonWaitingAnswer.
  ///
  /// In zh, this message translates to:
  /// **'等你回答'**
  String get commonWaitingAnswer;

  /// No description provided for @commonNotConnected.
  ///
  /// In zh, this message translates to:
  /// **'未连接'**
  String get commonNotConnected;

  /// No description provided for @commonInstalled.
  ///
  /// In zh, this message translates to:
  /// **'已安装'**
  String get commonInstalled;

  /// No description provided for @commonName.
  ///
  /// In zh, this message translates to:
  /// **'名称'**
  String get commonName;

  /// No description provided for @commonStatus.
  ///
  /// In zh, this message translates to:
  /// **'状态'**
  String get commonStatus;

  /// No description provided for @commonVersion.
  ///
  /// In zh, this message translates to:
  /// **'版本'**
  String get commonVersion;

  /// No description provided for @commonOther.
  ///
  /// In zh, this message translates to:
  /// **'其他'**
  String get commonOther;

  /// No description provided for @commonPin.
  ///
  /// In zh, this message translates to:
  /// **'置顶'**
  String get commonPin;

  /// No description provided for @commonReply.
  ///
  /// In zh, this message translates to:
  /// **'回复'**
  String get commonReply;

  /// No description provided for @commonUpdate.
  ///
  /// In zh, this message translates to:
  /// **'更新'**
  String get commonUpdate;

  /// No description provided for @commonViewLogs.
  ///
  /// In zh, this message translates to:
  /// **'查看日志'**
  String get commonViewLogs;

  /// No description provided for @commonItemCount.
  ///
  /// In zh, this message translates to:
  /// **'{count} 项'**
  String commonItemCount(int count);

  /// Short date (month 1–12).
  ///
  /// In zh, this message translates to:
  /// **'{month}月{day}日'**
  String commonMonthDay(String month, int day);

  /// No description provided for @engineNewChatDefaultsLast.
  ///
  /// In zh, this message translates to:
  /// **'新对话默认（上次选择）'**
  String get engineNewChatDefaultsLast;

  /// No description provided for @engineNewChatDefaultsFixed.
  ///
  /// In zh, this message translates to:
  /// **'新对话默认（固定）'**
  String get engineNewChatDefaultsFixed;

  /// No description provided for @engineNewChatUseLast.
  ///
  /// In zh, this message translates to:
  /// **'沿用上次'**
  String get engineNewChatUseLast;

  /// No description provided for @engineNewChatUseFixed.
  ///
  /// In zh, this message translates to:
  /// **'固定默认'**
  String get engineNewChatUseFixed;

  /// No description provided for @engineNewChatDefaultsHint.
  ///
  /// In zh, this message translates to:
  /// **'保存在当前主机，只影响新对话的模型和思考深度。权限仍用独立默认，不继承临时会话授权。'**
  String get engineNewChatDefaultsHint;

  /// No description provided for @engineNewChatDefaultsLegacy.
  ///
  /// In zh, this message translates to:
  /// **'此引擎仅支持沿用上次选择；不支持固定默认，也无法确认切换时默认值是否保存成功。'**
  String get engineNewChatDefaultsLegacy;

  /// No description provided for @engineNewChatDefaultsUnsupported.
  ///
  /// In zh, this message translates to:
  /// **'此主机没有可编辑的默认模型设置'**
  String get engineNewChatDefaultsUnsupported;

  /// No description provided for @engineNewChatDefaultsSelectionUnavailable.
  ///
  /// In zh, this message translates to:
  /// **'此模型或思考深度已不可用，请重新选择。'**
  String get engineNewChatDefaultsSelectionUnavailable;

  /// No description provided for @engineNewChatDefaultsInheritedEffort.
  ///
  /// In zh, this message translates to:
  /// **'主机基础配置指定了思考深度，不能在这里为无思考模型清除。请先调整主机配置。'**
  String get engineNewChatDefaultsInheritedEffort;

  /// No description provided for @engineNewChatDefaultsSaving.
  ///
  /// In zh, this message translates to:
  /// **'正在保存并确认默认值…'**
  String get engineNewChatDefaultsSaving;

  /// No description provided for @engineNewChatDefaultsUnconfirmed.
  ///
  /// In zh, this message translates to:
  /// **'没能确认完整默认值，请刷新后检查模型和思考深度。主机基础配置或其他客户端可能已改变它们。'**
  String get engineNewChatDefaultsUnconfirmed;

  /// No description provided for @engineModelDefaultSaveFailed.
  ///
  /// In zh, this message translates to:
  /// **'当前对话的模型已切换，但新对话默认未保存。请到设置 › 模型检查并重试。'**
  String get engineModelDefaultSaveFailed;

  /// No description provided for @engineAccountSignedIn.
  ///
  /// In zh, this message translates to:
  /// **'已登录 DeepSeek 账号'**
  String get engineAccountSignedIn;

  /// No description provided for @engineAccountSignOutTitle.
  ///
  /// In zh, this message translates to:
  /// **'退出 DeepSeek 账号？'**
  String get engineAccountSignOutTitle;

  /// No description provided for @engineAccountSignOutBusy.
  ///
  /// In zh, this message translates to:
  /// **'有任务正在使用账号模型，退出会立即中断它们。对话和文件都会保留。'**
  String get engineAccountSignOutBusy;

  /// No description provided for @engineAccountSignOutBody.
  ///
  /// In zh, this message translates to:
  /// **'账号模型将不可用。对话、文件和 API Key 都会保留，随时可以重新登录。'**
  String get engineAccountSignOutBody;

  /// No description provided for @engineAccountSignOutUnknown.
  ///
  /// In zh, this message translates to:
  /// **'无法确认是否有任务在使用账号模型；如果有，退出会中断它们。'**
  String get engineAccountSignOutUnknown;

  /// No description provided for @engineAccountSignOutFailed.
  ///
  /// In zh, this message translates to:
  /// **'没能退出，稍后再试'**
  String get engineAccountSignOutFailed;

  /// No description provided for @engineAccountTitle.
  ///
  /// In zh, this message translates to:
  /// **'账号'**
  String get engineAccountTitle;

  /// No description provided for @engineAccountRefresh.
  ///
  /// In zh, this message translates to:
  /// **'刷新'**
  String get engineAccountRefresh;

  /// No description provided for @engineAccountDeepSeek.
  ///
  /// In zh, this message translates to:
  /// **'DeepSeek 账号'**
  String get engineAccountDeepSeek;

  /// No description provided for @engineAccountProfileUnavailable.
  ///
  /// In zh, this message translates to:
  /// **'资料暂时读不到'**
  String get engineAccountProfileUnavailable;

  /// No description provided for @engineAccountBalance.
  ///
  /// In zh, this message translates to:
  /// **'余额'**
  String get engineAccountBalance;

  /// No description provided for @engineAccountBalanceHint.
  ///
  /// In zh, this message translates to:
  /// **'账号模型的费用从余额中扣除'**
  String get engineAccountBalanceHint;

  /// No description provided for @engineAccountBalanceEngineOff.
  ///
  /// In zh, this message translates to:
  /// **'引擎未运行，启动后显示余额'**
  String get engineAccountBalanceEngineOff;

  /// No description provided for @engineAccountTopUp.
  ///
  /// In zh, this message translates to:
  /// **'去充值'**
  String get engineAccountTopUp;

  /// No description provided for @engineAccountUsageDetails.
  ///
  /// In zh, this message translates to:
  /// **'用量明细'**
  String get engineAccountUsageDetails;

  /// No description provided for @engineAccountToppedUpBalance.
  ///
  /// In zh, this message translates to:
  /// **'充值余额'**
  String get engineAccountToppedUpBalance;

  /// No description provided for @engineAccountGrantedBalance.
  ///
  /// In zh, this message translates to:
  /// **'赠送余额'**
  String get engineAccountGrantedBalance;

  /// No description provided for @engineAccountBalanceUnavailable.
  ///
  /// In zh, this message translates to:
  /// **'余额暂时读不到'**
  String get engineAccountBalanceUnavailable;

  /// No description provided for @engineAccountNoKeyNeeded.
  ///
  /// In zh, this message translates to:
  /// **'登录后无需 API Key'**
  String get engineAccountNoKeyNeeded;

  /// No description provided for @engineAccountUnsupported.
  ///
  /// In zh, this message translates to:
  /// **'当前引擎不支持账号登录'**
  String get engineAccountUnsupported;

  /// No description provided for @engineAccountSignInDeepSeek.
  ///
  /// In zh, this message translates to:
  /// **'用 DeepSeek 账号登录'**
  String get engineAccountSignInDeepSeek;

  /// No description provided for @engineAccountAutoStart.
  ///
  /// In zh, this message translates to:
  /// **'引擎未运行，登录时会自动启动'**
  String get engineAccountAutoStart;

  /// No description provided for @engineAccountReplaceKey.
  ///
  /// In zh, this message translates to:
  /// **'更换 Key'**
  String get engineAccountReplaceKey;

  /// No description provided for @engineAccountClearKeyTitle.
  ///
  /// In zh, this message translates to:
  /// **'清除 API Key？'**
  String get engineAccountClearKeyTitle;

  /// No description provided for @engineAccountClearKeyBody.
  ///
  /// In zh, this message translates to:
  /// **'删除 App 里保存的 Key。本机引擎运行时，引擎里的 Key 也会一并删除。'**
  String get engineAccountClearKeyBody;

  /// No description provided for @engineAccountBrowserFailed.
  ///
  /// In zh, this message translates to:
  /// **'没能打开浏览器'**
  String get engineAccountBrowserFailed;

  /// No description provided for @engineAccountSignInSuccess.
  ///
  /// In zh, this message translates to:
  /// **'登录成功'**
  String get engineAccountSignInSuccess;

  /// No description provided for @engineAccountAlmostReady.
  ///
  /// In zh, this message translates to:
  /// **'马上就好'**
  String get engineAccountAlmostReady;

  /// No description provided for @engineAccountStartingEngine.
  ///
  /// In zh, this message translates to:
  /// **'正在启动引擎'**
  String get engineAccountStartingEngine;

  /// No description provided for @engineAccountOpenSignInNext.
  ///
  /// In zh, this message translates to:
  /// **'随后打开登录页'**
  String get engineAccountOpenSignInNext;

  /// No description provided for @engineAccountPreparingSignIn.
  ///
  /// In zh, this message translates to:
  /// **'正在准备登录'**
  String get engineAccountPreparingSignIn;

  /// No description provided for @engineAccountOpenDeepSeekNext.
  ///
  /// In zh, this message translates to:
  /// **'马上打开 DeepSeek 登录页'**
  String get engineAccountOpenDeepSeekNext;

  /// No description provided for @engineAccountFinishInBrowser.
  ///
  /// In zh, this message translates to:
  /// **'在浏览器中完成登录'**
  String get engineAccountFinishInBrowser;

  /// No description provided for @engineAccountReturnToDsh.
  ///
  /// In zh, this message translates to:
  /// **'登录完成后回到 DSH Go'**
  String get engineAccountReturnToDsh;

  /// No description provided for @engineAccountFinishingSignIn.
  ///
  /// In zh, this message translates to:
  /// **'正在完成登录'**
  String get engineAccountFinishingSignIn;

  /// No description provided for @engineAccountSavingSignIn.
  ///
  /// In zh, this message translates to:
  /// **'正在保存登录信息'**
  String get engineAccountSavingSignIn;

  /// No description provided for @engineAccountAwaitingResult.
  ///
  /// In zh, this message translates to:
  /// **'还没收到登录结果'**
  String get engineAccountAwaitingResult;

  /// No description provided for @engineAccountCopySignInLink.
  ///
  /// In zh, this message translates to:
  /// **'复制登录链接'**
  String get engineAccountCopySignInLink;

  /// No description provided for @engineAccountReopenSignIn.
  ///
  /// In zh, this message translates to:
  /// **'重新打开登录页'**
  String get engineAccountReopenSignIn;

  /// No description provided for @engineAccountCancelSignIn.
  ///
  /// In zh, this message translates to:
  /// **'取消登录'**
  String get engineAccountCancelSignIn;

  /// No description provided for @engineAccountSignInLinkCopied.
  ///
  /// In zh, this message translates to:
  /// **'登录链接已复制'**
  String get engineAccountSignInLinkCopied;

  /// No description provided for @engineAccountSigningIn.
  ///
  /// In zh, this message translates to:
  /// **'登录中'**
  String get engineAccountSigningIn;

  /// No description provided for @engineAccountSignedOut.
  ///
  /// In zh, this message translates to:
  /// **'未登录'**
  String get engineAccountSignedOut;

  /// No description provided for @engineAccountUsageFact.
  ///
  /// In zh, this message translates to:
  /// **'用量从账号余额中扣除'**
  String get engineAccountUsageFact;

  /// No description provided for @engineAccountBrowserFact.
  ///
  /// In zh, this message translates to:
  /// **'在浏览器中登录，密码不经过 DSH'**
  String get engineAccountBrowserFact;

  /// No description provided for @engineAccountCredentialsFact.
  ///
  /// In zh, this message translates to:
  /// **'登录凭据只保存在本机'**
  String get engineAccountCredentialsFact;

  /// No description provided for @engineSubagentTitle.
  ///
  /// In zh, this message translates to:
  /// **'子代理'**
  String get engineSubagentTitle;

  /// No description provided for @engineAgentLoopTitle.
  ///
  /// In zh, this message translates to:
  /// **'Agent 循环'**
  String get engineAgentLoopTitle;

  /// No description provided for @engineShellTitle.
  ///
  /// In zh, this message translates to:
  /// **'命令执行'**
  String get engineShellTitle;

  /// No description provided for @engineSearchTitle.
  ///
  /// In zh, this message translates to:
  /// **'联网搜索'**
  String get engineSearchTitle;

  /// No description provided for @engineSearchNewApiBadge.
  ///
  /// In zh, this message translates to:
  /// **'新版 API'**
  String get engineSearchNewApiBadge;

  /// No description provided for @engineGeneralTitle.
  ///
  /// In zh, this message translates to:
  /// **'通用设置'**
  String get engineGeneralTitle;

  /// No description provided for @engineSettingsTitle.
  ///
  /// In zh, this message translates to:
  /// **'引擎参数'**
  String get engineSettingsTitle;

  /// No description provided for @engineSettingsReadFailed.
  ///
  /// In zh, this message translates to:
  /// **'没能读取设置'**
  String get engineSettingsReadFailed;

  /// No description provided for @engineSettingsRun.
  ///
  /// In zh, this message translates to:
  /// **'运行'**
  String get engineSettingsRun;

  /// No description provided for @engineSettingsPlugins.
  ///
  /// In zh, this message translates to:
  /// **'插件'**
  String get engineSettingsPlugins;

  /// No description provided for @engineSettingsPluginInventory.
  ///
  /// In zh, this message translates to:
  /// **'插件清单'**
  String get engineSettingsPluginInventory;

  /// No description provided for @engineSettingsPluginStopped.
  ///
  /// In zh, this message translates to:
  /// **'插件没有在运行'**
  String get engineSettingsPluginStopped;

  /// No description provided for @engineSettingsEnablePlugin.
  ///
  /// In zh, this message translates to:
  /// **'启用后再来设置'**
  String get engineSettingsEnablePlugin;

  /// No description provided for @engineSettingsNoEditableFields.
  ///
  /// In zh, this message translates to:
  /// **'没有可以在这里改的设置'**
  String get engineSettingsNoEditableFields;

  /// No description provided for @engineFieldRestoreDefault.
  ///
  /// In zh, this message translates to:
  /// **'恢复默认'**
  String get engineFieldRestoreDefault;

  /// No description provided for @engineFieldDecrease.
  ///
  /// In zh, this message translates to:
  /// **'减少'**
  String get engineFieldDecrease;

  /// No description provided for @engineFieldIncrease.
  ///
  /// In zh, this message translates to:
  /// **'增加'**
  String get engineFieldIncrease;

  /// No description provided for @engineFieldRemove.
  ///
  /// In zh, this message translates to:
  /// **'移除'**
  String get engineFieldRemove;

  /// No description provided for @engineFieldShow.
  ///
  /// In zh, this message translates to:
  /// **'显示'**
  String get engineFieldShow;

  /// No description provided for @engineFieldFromEnvironment.
  ///
  /// In zh, this message translates to:
  /// **'由启动环境提供'**
  String get engineFieldFromEnvironment;

  /// No description provided for @engineFieldItem.
  ///
  /// In zh, this message translates to:
  /// **'项'**
  String get engineFieldItem;

  /// No description provided for @engineFieldAlreadyAdded.
  ///
  /// In zh, this message translates to:
  /// **'已经添加过'**
  String get engineFieldAlreadyAdded;

  /// No description provided for @engineFieldEnterName.
  ///
  /// In zh, this message translates to:
  /// **'填写名称'**
  String get engineFieldEnterName;

  /// No description provided for @engineFieldEnterNumber.
  ///
  /// In zh, this message translates to:
  /// **'填写数值'**
  String get engineFieldEnterNumber;

  /// No description provided for @engineFieldValue.
  ///
  /// In zh, this message translates to:
  /// **'值'**
  String get engineFieldValue;

  /// No description provided for @engineFieldNew.
  ///
  /// In zh, this message translates to:
  /// **'新建'**
  String get engineFieldNew;

  /// No description provided for @engineFieldRequired.
  ///
  /// In zh, this message translates to:
  /// **'必填'**
  String get engineFieldRequired;

  /// No description provided for @engineGeneralMissing.
  ///
  /// In zh, this message translates to:
  /// **'这台主机没有通用设置'**
  String get engineGeneralMissing;

  /// No description provided for @engineSettingsVersionRequired.
  ///
  /// In zh, this message translates to:
  /// **'需要 DSH 0.2.1 或更新版本'**
  String get engineSettingsVersionRequired;

  /// No description provided for @engineGeneralWebDisplay.
  ///
  /// In zh, this message translates to:
  /// **'网页版显示'**
  String get engineGeneralWebDisplay;

  /// No description provided for @engineGeneralWebSending.
  ///
  /// In zh, this message translates to:
  /// **'网页版发送'**
  String get engineGeneralWebSending;

  /// No description provided for @engineGeneralData.
  ///
  /// In zh, this message translates to:
  /// **'数据'**
  String get engineGeneralData;

  /// No description provided for @engineSubagentModelsTitle.
  ///
  /// In zh, this message translates to:
  /// **'子代理模型'**
  String get engineSubagentModelsTitle;

  /// No description provided for @engineChatLogTitle.
  ///
  /// In zh, this message translates to:
  /// **'对话日志'**
  String get engineChatLogTitle;

  /// No description provided for @engineThinkingTranslationTitle.
  ///
  /// In zh, this message translates to:
  /// **'思考过程翻译'**
  String get engineThinkingTranslationTitle;

  /// No description provided for @enginePluginIndexesTitle.
  ///
  /// In zh, this message translates to:
  /// **'插件市场索引'**
  String get enginePluginIndexesTitle;

  /// No description provided for @enginePermissionTitle.
  ///
  /// In zh, this message translates to:
  /// **'权限'**
  String get enginePermissionTitle;

  /// No description provided for @engineAgentPresetsTitle.
  ///
  /// In zh, this message translates to:
  /// **'Agent 预设'**
  String get engineAgentPresetsTitle;

  /// No description provided for @engineDefaultModelTitle.
  ///
  /// In zh, this message translates to:
  /// **'默认模型'**
  String get engineDefaultModelTitle;

  /// No description provided for @engineWebAppearanceTitle.
  ///
  /// In zh, this message translates to:
  /// **'网页版外观'**
  String get engineWebAppearanceTitle;

  /// No description provided for @engineLanguageTitle.
  ///
  /// In zh, this message translates to:
  /// **'语言'**
  String get engineLanguageTitle;

  /// No description provided for @engineFieldCommandTimeout.
  ///
  /// In zh, this message translates to:
  /// **'命令超时'**
  String get engineFieldCommandTimeout;

  /// No description provided for @engineFieldMaxOutput.
  ///
  /// In zh, this message translates to:
  /// **'输出上限'**
  String get engineFieldMaxOutput;

  /// No description provided for @engineFieldMaxTimeout.
  ///
  /// In zh, this message translates to:
  /// **'最长可申请超时'**
  String get engineFieldMaxTimeout;

  /// No description provided for @engineFieldMaxSpill.
  ///
  /// In zh, this message translates to:
  /// **'转存文件上限'**
  String get engineFieldMaxSpill;

  /// No description provided for @engineFieldGracePeriod.
  ///
  /// In zh, this message translates to:
  /// **'终止宽限时间'**
  String get engineFieldGracePeriod;

  /// No description provided for @engineFieldDefaultCwd.
  ///
  /// In zh, this message translates to:
  /// **'默认工作目录'**
  String get engineFieldDefaultCwd;

  /// No description provided for @engineFieldFollowChat.
  ///
  /// In zh, this message translates to:
  /// **'跟随对话'**
  String get engineFieldFollowChat;

  /// No description provided for @engineSubagentMaxDepth.
  ///
  /// In zh, this message translates to:
  /// **'最大递归深度'**
  String get engineSubagentMaxDepth;

  /// No description provided for @engineFieldLayersUnit.
  ///
  /// In zh, this message translates to:
  /// **'层'**
  String get engineFieldLayersUnit;

  /// No description provided for @engineSubagentMaxActive.
  ///
  /// In zh, this message translates to:
  /// **'同时运行上限'**
  String get engineSubagentMaxActive;

  /// No description provided for @engineFieldCountUnit.
  ///
  /// In zh, this message translates to:
  /// **'个'**
  String get engineFieldCountUnit;

  /// No description provided for @engineSubagentAllowModelChoice.
  ///
  /// In zh, this message translates to:
  /// **'允许 AI 给子代理选模型'**
  String get engineSubagentAllowModelChoice;

  /// No description provided for @engineSubagentAllowedModels.
  ///
  /// In zh, this message translates to:
  /// **'可选模型'**
  String get engineSubagentAllowedModels;

  /// No description provided for @engineAgentMaxParallelCalls.
  ///
  /// In zh, this message translates to:
  /// **'每步并行工具调用上限'**
  String get engineAgentMaxParallelCalls;

  /// No description provided for @engineFieldSearchProvider.
  ///
  /// In zh, this message translates to:
  /// **'搜索服务'**
  String get engineFieldSearchProvider;

  /// No description provided for @engineFieldFetchProvider.
  ///
  /// In zh, this message translates to:
  /// **'网页抓取服务'**
  String get engineFieldFetchProvider;

  /// No description provided for @engineFieldBaseUrl.
  ///
  /// In zh, this message translates to:
  /// **'服务地址'**
  String get engineFieldBaseUrl;

  /// No description provided for @engineSearchMaxUses.
  ///
  /// In zh, this message translates to:
  /// **'每次请求最多搜索'**
  String get engineSearchMaxUses;

  /// No description provided for @engineFieldTimesUnit.
  ///
  /// In zh, this message translates to:
  /// **'次'**
  String get engineFieldTimesUnit;

  /// No description provided for @engineSearchHelperModel.
  ///
  /// In zh, this message translates to:
  /// **'辅助模型'**
  String get engineSearchHelperModel;

  /// No description provided for @engineFieldApiVersion.
  ///
  /// In zh, this message translates to:
  /// **'API 版本'**
  String get engineFieldApiVersion;

  /// No description provided for @engineFieldMaxTokens.
  ///
  /// In zh, this message translates to:
  /// **'最大输出长度'**
  String get engineFieldMaxTokens;

  /// No description provided for @engineSearchResultsPerSearch.
  ///
  /// In zh, this message translates to:
  /// **'每次搜索结果数'**
  String get engineSearchResultsPerSearch;

  /// No description provided for @engineFieldResultsUnit.
  ///
  /// In zh, this message translates to:
  /// **'条'**
  String get engineFieldResultsUnit;

  /// No description provided for @engineSearchSendOriginalQuestion.
  ///
  /// In zh, this message translates to:
  /// **'搜索时附带用户原问题'**
  String get engineSearchSendOriginalQuestion;

  /// No description provided for @engineChatLogUpload.
  ///
  /// In zh, this message translates to:
  /// **'向 DeepSeek 上传对话日志'**
  String get engineChatLogUpload;

  /// No description provided for @engineTranslationProvider.
  ///
  /// In zh, this message translates to:
  /// **'翻译服务'**
  String get engineTranslationProvider;

  /// No description provided for @engineTranslationAccountPaid.
  ///
  /// In zh, this message translates to:
  /// **'DeepSeek 账号（付费）'**
  String get engineTranslationAccountPaid;

  /// No description provided for @engineTranslationApiPaid.
  ///
  /// In zh, this message translates to:
  /// **'DeepSeek API（付费）'**
  String get engineTranslationApiPaid;

  /// No description provided for @engineTranslationTargetLanguage.
  ///
  /// In zh, this message translates to:
  /// **'目标语言'**
  String get engineTranslationTargetLanguage;

  /// No description provided for @engineTranslationFollowLanguage.
  ///
  /// In zh, this message translates to:
  /// **'跟随界面语言'**
  String get engineTranslationFollowLanguage;

  /// No description provided for @engineTranslationLanguageHint.
  ///
  /// In zh, this message translates to:
  /// **'填 auto 或语言代码，如 zh、en、ja'**
  String get engineTranslationLanguageHint;

  /// No description provided for @enginePluginIndexSources.
  ///
  /// In zh, this message translates to:
  /// **'索引源'**
  String get enginePluginIndexSources;

  /// No description provided for @enginePluginIndexUrl.
  ///
  /// In zh, this message translates to:
  /// **'索引地址'**
  String get enginePluginIndexUrl;

  /// No description provided for @engineFieldHttpUrlHint.
  ///
  /// In zh, this message translates to:
  /// **'以 http:// 或 https:// 开头的地址'**
  String get engineFieldHttpUrlHint;

  /// No description provided for @enginePermissionNewChat.
  ///
  /// In zh, this message translates to:
  /// **'新对话默认权限'**
  String get enginePermissionNewChat;

  /// No description provided for @engineAgentDefaultPreset.
  ///
  /// In zh, this message translates to:
  /// **'默认 Agent 预设'**
  String get engineAgentDefaultPreset;

  /// No description provided for @engineProviderTitle.
  ///
  /// In zh, this message translates to:
  /// **'渠道'**
  String get engineProviderTitle;

  /// No description provided for @engineModelTitle.
  ///
  /// In zh, this message translates to:
  /// **'模型'**
  String get engineModelTitle;

  /// No description provided for @engineFieldReasoningEffort.
  ///
  /// In zh, this message translates to:
  /// **'思考深度'**
  String get engineFieldReasoningEffort;

  /// No description provided for @engineGeneralShowCodingView.
  ///
  /// In zh, this message translates to:
  /// **'显示代码工作视图'**
  String get engineGeneralShowCodingView;

  /// No description provided for @engineGeneralWorkDetails.
  ///
  /// In zh, this message translates to:
  /// **'工作步骤展示'**
  String get engineGeneralWorkDetails;

  /// No description provided for @engineFieldCompact.
  ///
  /// In zh, this message translates to:
  /// **'简洁'**
  String get engineFieldCompact;

  /// No description provided for @engineFieldStandard.
  ///
  /// In zh, this message translates to:
  /// **'标准'**
  String get engineFieldStandard;

  /// No description provided for @engineFieldDetailed.
  ///
  /// In zh, this message translates to:
  /// **'详细'**
  String get engineFieldDetailed;

  /// No description provided for @engineFieldVerbose.
  ///
  /// In zh, this message translates to:
  /// **'完全展开'**
  String get engineFieldVerbose;

  /// No description provided for @engineGeneralCollapseTiming.
  ///
  /// In zh, this message translates to:
  /// **'工作步骤收起时机'**
  String get engineGeneralCollapseTiming;

  /// No description provided for @engineGeneralOnCompletion.
  ///
  /// In zh, this message translates to:
  /// **'回答结束后'**
  String get engineGeneralOnCompletion;

  /// No description provided for @engineGeneralOnNewMessage.
  ///
  /// In zh, this message translates to:
  /// **'有新消息时'**
  String get engineGeneralOnNewMessage;

  /// No description provided for @engineGeneralPerformanceUsage.
  ///
  /// In zh, this message translates to:
  /// **'性能与用量'**
  String get engineGeneralPerformanceUsage;

  /// No description provided for @engineGeneralLinkOpening.
  ///
  /// In zh, this message translates to:
  /// **'链接打开方式'**
  String get engineGeneralLinkOpening;

  /// No description provided for @engineGeneralAppSidebar.
  ///
  /// In zh, this message translates to:
  /// **'应用内侧栏'**
  String get engineGeneralAppSidebar;

  /// No description provided for @engineGeneralDefaultBrowser.
  ///
  /// In zh, this message translates to:
  /// **'默认浏览器'**
  String get engineGeneralDefaultBrowser;

  /// No description provided for @engineGeneralBusySend.
  ///
  /// In zh, this message translates to:
  /// **'AI 工作时发送'**
  String get engineGeneralBusySend;

  /// No description provided for @engineGeneralQueueSend.
  ///
  /// In zh, this message translates to:
  /// **'排队发送'**
  String get engineGeneralQueueSend;

  /// No description provided for @engineGeneralSteerSend.
  ///
  /// In zh, this message translates to:
  /// **'插话发送'**
  String get engineGeneralSteerSend;

  /// No description provided for @engineFieldTheme.
  ///
  /// In zh, this message translates to:
  /// **'主题'**
  String get engineFieldTheme;

  /// No description provided for @engineFieldFontSize.
  ///
  /// In zh, this message translates to:
  /// **'字号'**
  String get engineFieldFontSize;

  /// No description provided for @engineFieldCodeFontSize.
  ///
  /// In zh, this message translates to:
  /// **'代码字号'**
  String get engineFieldCodeFontSize;

  /// No description provided for @engineFieldTerminalFontSize.
  ///
  /// In zh, this message translates to:
  /// **'终端字号'**
  String get engineFieldTerminalFontSize;

  /// No description provided for @engineFieldTextFont.
  ///
  /// In zh, this message translates to:
  /// **'正文字体'**
  String get engineFieldTextFont;

  /// No description provided for @engineFieldCodeFont.
  ///
  /// In zh, this message translates to:
  /// **'代码字体'**
  String get engineFieldCodeFont;

  /// No description provided for @engineFieldTerminalFont.
  ///
  /// In zh, this message translates to:
  /// **'终端字体'**
  String get engineFieldTerminalFont;

  /// No description provided for @engineFieldInterfaceLanguage.
  ///
  /// In zh, this message translates to:
  /// **'界面语言'**
  String get engineFieldInterfaceLanguage;

  /// No description provided for @engineFieldSecondsUnit.
  ///
  /// In zh, this message translates to:
  /// **'秒'**
  String get engineFieldSecondsUnit;

  /// No description provided for @engineFieldBytesUnit.
  ///
  /// In zh, this message translates to:
  /// **'字节'**
  String get engineFieldBytesUnit;

  /// No description provided for @engineFieldGreaterThanZero.
  ///
  /// In zh, this message translates to:
  /// **'大于 0'**
  String get engineFieldGreaterThanZero;

  /// No description provided for @engineFieldEnterNumeric.
  ///
  /// In zh, this message translates to:
  /// **'请填数字'**
  String get engineFieldEnterNumeric;

  /// No description provided for @engineFieldEnterInteger.
  ///
  /// In zh, this message translates to:
  /// **'请填整数'**
  String get engineFieldEnterInteger;

  /// No description provided for @engineFieldInvalidFormat.
  ///
  /// In zh, this message translates to:
  /// **'格式不对'**
  String get engineFieldInvalidFormat;

  /// No description provided for @engineFieldAddress.
  ///
  /// In zh, this message translates to:
  /// **'地址'**
  String get engineFieldAddress;

  /// No description provided for @engineFieldToken.
  ///
  /// In zh, this message translates to:
  /// **'令牌'**
  String get engineFieldToken;

  /// No description provided for @engineFieldService.
  ///
  /// In zh, this message translates to:
  /// **'服务'**
  String get engineFieldService;

  /// No description provided for @engineFieldTimeout.
  ///
  /// In zh, this message translates to:
  /// **'超时'**
  String get engineFieldTimeout;

  /// No description provided for @engineFieldQuantity.
  ///
  /// In zh, this message translates to:
  /// **'数量'**
  String get engineFieldQuantity;

  /// No description provided for @engineFieldMaxUses.
  ///
  /// In zh, this message translates to:
  /// **'最多次数'**
  String get engineFieldMaxUses;

  /// No description provided for @engineFieldMaxRetries.
  ///
  /// In zh, this message translates to:
  /// **'最多重试次数'**
  String get engineFieldMaxRetries;

  /// No description provided for @engineFieldConcurrency.
  ///
  /// In zh, this message translates to:
  /// **'并发数'**
  String get engineFieldConcurrency;

  /// No description provided for @engineFieldInterval.
  ///
  /// In zh, this message translates to:
  /// **'间隔'**
  String get engineFieldInterval;

  /// No description provided for @engineFieldPrompt.
  ///
  /// In zh, this message translates to:
  /// **'提示词'**
  String get engineFieldPrompt;

  /// No description provided for @engineFieldSystemPrompt.
  ///
  /// In zh, this message translates to:
  /// **'系统提示词'**
  String get engineFieldSystemPrompt;

  /// No description provided for @engineFieldTemperature.
  ///
  /// In zh, this message translates to:
  /// **'温度'**
  String get engineFieldTemperature;

  /// No description provided for @engineFieldDebugMode.
  ///
  /// In zh, this message translates to:
  /// **'调试模式'**
  String get engineFieldDebugMode;

  /// No description provided for @engineFieldVerboseLogs.
  ///
  /// In zh, this message translates to:
  /// **'详细日志'**
  String get engineFieldVerboseLogs;

  /// No description provided for @engineFieldPath.
  ///
  /// In zh, this message translates to:
  /// **'路径'**
  String get engineFieldPath;

  /// No description provided for @engineFieldCwd.
  ///
  /// In zh, this message translates to:
  /// **'工作目录'**
  String get engineFieldCwd;

  /// No description provided for @engineFieldCommand.
  ///
  /// In zh, this message translates to:
  /// **'命令'**
  String get engineFieldCommand;

  /// No description provided for @engineFieldArguments.
  ///
  /// In zh, this message translates to:
  /// **'参数'**
  String get engineFieldArguments;

  /// No description provided for @engineFieldEnvironment.
  ///
  /// In zh, this message translates to:
  /// **'环境变量'**
  String get engineFieldEnvironment;

  /// No description provided for @engineFieldHeaders.
  ///
  /// In zh, this message translates to:
  /// **'请求头'**
  String get engineFieldHeaders;

  /// No description provided for @engineFieldProxy.
  ///
  /// In zh, this message translates to:
  /// **'代理'**
  String get engineFieldProxy;

  /// No description provided for @engineFieldAuto.
  ///
  /// In zh, this message translates to:
  /// **'自动'**
  String get engineFieldAuto;

  /// No description provided for @engineFieldEnabled.
  ///
  /// In zh, this message translates to:
  /// **'开启'**
  String get engineFieldEnabled;

  /// No description provided for @engineFieldOn.
  ///
  /// In zh, this message translates to:
  /// **'开'**
  String get engineFieldOn;

  /// No description provided for @engineFieldOff.
  ///
  /// In zh, this message translates to:
  /// **'关'**
  String get engineFieldOff;

  /// No description provided for @engineFieldLow.
  ///
  /// In zh, this message translates to:
  /// **'低'**
  String get engineFieldLow;

  /// No description provided for @engineFieldMedium.
  ///
  /// In zh, this message translates to:
  /// **'中'**
  String get engineFieldMedium;

  /// No description provided for @engineFieldHigh.
  ///
  /// In zh, this message translates to:
  /// **'高'**
  String get engineFieldHigh;

  /// No description provided for @engineFieldMax.
  ///
  /// In zh, this message translates to:
  /// **'最高'**
  String get engineFieldMax;

  /// No description provided for @engineFieldNone.
  ///
  /// In zh, this message translates to:
  /// **'无'**
  String get engineFieldNone;

  /// No description provided for @engineFieldModified.
  ///
  /// In zh, this message translates to:
  /// **'已修改'**
  String get engineFieldModified;

  /// No description provided for @engineFieldLocked.
  ///
  /// In zh, this message translates to:
  /// **'由配置文件固定'**
  String get engineFieldLocked;

  /// No description provided for @engineFieldSharedWithModel.
  ///
  /// In zh, this message translates to:
  /// **'与模型共用'**
  String get engineFieldSharedWithModel;

  /// No description provided for @engineFieldNotConfigured.
  ///
  /// In zh, this message translates to:
  /// **'未配置'**
  String get engineFieldNotConfigured;

  /// No description provided for @engineFieldConfigured.
  ///
  /// In zh, this message translates to:
  /// **'已配置'**
  String get engineFieldConfigured;

  /// No description provided for @engineSettingsMissing.
  ///
  /// In zh, this message translates to:
  /// **'这台主机没有这项设置'**
  String get engineSettingsMissing;

  /// No description provided for @engineSettingsPluginDisabled.
  ///
  /// In zh, this message translates to:
  /// **'相关插件未启用'**
  String get engineSettingsPluginDisabled;

  /// No description provided for @engineSettingsReadOnly.
  ///
  /// In zh, this message translates to:
  /// **'引擎设置是只读的，这里只能查看'**
  String get engineSettingsReadOnly;

  /// No description provided for @engineSubagentSavedUnavailable.
  ///
  /// In zh, this message translates to:
  /// **'已保存但当前不可用'**
  String get engineSubagentSavedUnavailable;

  /// No description provided for @engineSubagentKeepOneModel.
  ///
  /// In zh, this message translates to:
  /// **'至少保留一个模型'**
  String get engineSubagentKeepOneModel;

  /// No description provided for @engineSubagentLimits.
  ///
  /// In zh, this message translates to:
  /// **'运行限制'**
  String get engineSubagentLimits;

  /// No description provided for @engineSubagentModelSelection.
  ///
  /// In zh, this message translates to:
  /// **'模型选择'**
  String get engineSubagentModelSelection;

  /// No description provided for @engineSubagentPickFirstModel.
  ///
  /// In zh, this message translates to:
  /// **'选一个模型后生效'**
  String get engineSubagentPickFirstModel;

  /// No description provided for @engineSubagentReadModelsFailed.
  ///
  /// In zh, this message translates to:
  /// **'没能读取模型'**
  String get engineSubagentReadModelsFailed;

  /// No description provided for @engineSubagentNoModels.
  ///
  /// In zh, this message translates to:
  /// **'还没有可选的模型'**
  String get engineSubagentNoModels;

  /// No description provided for @engineSubagentConnectModel.
  ///
  /// In zh, this message translates to:
  /// **'接入模型'**
  String get engineSubagentConnectModel;

  /// No description provided for @engineSearchDeepSeek.
  ///
  /// In zh, this message translates to:
  /// **'DeepSeek 搜索'**
  String get engineSearchDeepSeek;

  /// No description provided for @engineSearchNewApi.
  ///
  /// In zh, this message translates to:
  /// **'新版搜索 API'**
  String get engineSearchNewApi;

  /// No description provided for @engineProviderDeleteBody.
  ///
  /// In zh, this message translates to:
  /// **'渠道和它的 API Key 会一起删除，用它的对话需要换个模型。'**
  String get engineProviderDeleteBody;

  /// No description provided for @engineProviderReadFailed.
  ///
  /// In zh, this message translates to:
  /// **'没能读取渠道'**
  String get engineProviderReadFailed;

  /// No description provided for @engineProviderGone.
  ///
  /// In zh, this message translates to:
  /// **'这个渠道已不在'**
  String get engineProviderGone;

  /// No description provided for @engineProviderProtocol.
  ///
  /// In zh, this message translates to:
  /// **'协议'**
  String get engineProviderProtocol;

  /// No description provided for @engineProviderEnterKey.
  ///
  /// In zh, this message translates to:
  /// **'填写 API Key'**
  String get engineProviderEnterKey;

  /// No description provided for @engineProviderIssues.
  ///
  /// In zh, this message translates to:
  /// **'问题'**
  String get engineProviderIssues;

  /// No description provided for @engineProviderRejectedConfig.
  ///
  /// In zh, this message translates to:
  /// **'引擎拒绝了部分配置'**
  String get engineProviderRejectedConfig;

  /// No description provided for @engineProviderConnection.
  ///
  /// In zh, this message translates to:
  /// **'连接'**
  String get engineProviderConnection;

  /// No description provided for @engineProviderDefaultUrl.
  ///
  /// In zh, this message translates to:
  /// **'默认地址'**
  String get engineProviderDefaultUrl;

  /// No description provided for @engineProviderKeyNotRequired.
  ///
  /// In zh, this message translates to:
  /// **'不需要'**
  String get engineProviderKeyNotRequired;

  /// No description provided for @engineProviderNoModels.
  ///
  /// In zh, this message translates to:
  /// **'还没有模型'**
  String get engineProviderNoModels;

  /// No description provided for @engineProviderWebConfigured.
  ///
  /// In zh, this message translates to:
  /// **'这个渠道在网页版里配置，这里只能查看和删除'**
  String get engineProviderWebConfigured;

  /// No description provided for @engineProviderDelete.
  ///
  /// In zh, this message translates to:
  /// **'删除渠道'**
  String get engineProviderDelete;

  /// No description provided for @engineProviderConfigFile.
  ///
  /// In zh, this message translates to:
  /// **'由引擎配置文件提供，无法在这里删除'**
  String get engineProviderConfigFile;

  /// No description provided for @engineProviderTesting.
  ///
  /// In zh, this message translates to:
  /// **'正在测试'**
  String get engineProviderTesting;

  /// No description provided for @engineProviderTestConnection.
  ///
  /// In zh, this message translates to:
  /// **'测试连接'**
  String get engineProviderTestConnection;

  /// No description provided for @engineProviderKeyFirst.
  ///
  /// In zh, this message translates to:
  /// **'先填写 API Key'**
  String get engineProviderKeyFirst;

  /// No description provided for @engineProviderNoDiscoveredModels.
  ///
  /// In zh, this message translates to:
  /// **'服务没有列出模型，请手动添加'**
  String get engineProviderNoDiscoveredModels;

  /// No description provided for @engineProviderNeedModel.
  ///
  /// In zh, this message translates to:
  /// **'至少添加一个模型'**
  String get engineProviderNeedModel;

  /// No description provided for @engineProviderEdit.
  ///
  /// In zh, this message translates to:
  /// **'编辑渠道'**
  String get engineProviderEdit;

  /// No description provided for @engineProviderAdd.
  ///
  /// In zh, this message translates to:
  /// **'添加渠道'**
  String get engineProviderAdd;

  /// No description provided for @engineProviderBasicInfo.
  ///
  /// In zh, this message translates to:
  /// **'基本信息'**
  String get engineProviderBasicInfo;

  /// No description provided for @engineProviderNameHint.
  ///
  /// In zh, this message translates to:
  /// **'比如：我的网关'**
  String get engineProviderNameHint;

  /// No description provided for @engineProviderCompatibleProtocol.
  ///
  /// In zh, this message translates to:
  /// **'兼容协议'**
  String get engineProviderCompatibleProtocol;

  /// No description provided for @engineProviderKeepStoredKey.
  ///
  /// In zh, this message translates to:
  /// **'已保存，留空则不修改'**
  String get engineProviderKeepStoredKey;

  /// No description provided for @engineProviderSaving.
  ///
  /// In zh, this message translates to:
  /// **'正在保存'**
  String get engineProviderSaving;

  /// No description provided for @engineProviderWaitingEngine.
  ///
  /// In zh, this message translates to:
  /// **'等待引擎连接'**
  String get engineProviderWaitingEngine;

  /// No description provided for @engineProviderFetchingModels.
  ///
  /// In zh, this message translates to:
  /// **'正在获取模型'**
  String get engineProviderFetchingModels;

  /// No description provided for @engineProviderFetchModels.
  ///
  /// In zh, this message translates to:
  /// **'获取模型'**
  String get engineProviderFetchModels;

  /// No description provided for @engineProviderAddManually.
  ///
  /// In zh, this message translates to:
  /// **'手动添加'**
  String get engineProviderAddManually;

  /// No description provided for @engineProviderManualModel.
  ///
  /// In zh, this message translates to:
  /// **'手动添加模型'**
  String get engineProviderManualModel;

  /// No description provided for @engineProviderModelId.
  ///
  /// In zh, this message translates to:
  /// **'模型 ID'**
  String get engineProviderModelId;

  /// No description provided for @engineProviderSelectModels.
  ///
  /// In zh, this message translates to:
  /// **'选择模型'**
  String get engineProviderSelectModels;

  /// No description provided for @engineProviderSearchModels.
  ///
  /// In zh, this message translates to:
  /// **'搜索模型'**
  String get engineProviderSearchModels;

  /// No description provided for @engineProviderDeselectAll.
  ///
  /// In zh, this message translates to:
  /// **'全不选'**
  String get engineProviderDeselectAll;

  /// No description provided for @engineProviderSelectAll.
  ///
  /// In zh, this message translates to:
  /// **'全选'**
  String get engineProviderSelectAll;

  /// No description provided for @engineProviderNoMatchingModels.
  ///
  /// In zh, this message translates to:
  /// **'没有匹配的模型'**
  String get engineProviderNoMatchingModels;

  /// No description provided for @engineProviderAlreadyAdded.
  ///
  /// In zh, this message translates to:
  /// **'已添加'**
  String get engineProviderAlreadyAdded;

  /// No description provided for @engineProviderReady.
  ///
  /// In zh, this message translates to:
  /// **'可用'**
  String get engineProviderReady;

  /// No description provided for @engineProviderMissingKey.
  ///
  /// In zh, this message translates to:
  /// **'缺少 API Key'**
  String get engineProviderMissingKey;

  /// No description provided for @engineProviderMisconfigured.
  ///
  /// In zh, this message translates to:
  /// **'配置有误'**
  String get engineProviderMisconfigured;

  /// No description provided for @engineProviderInactive.
  ///
  /// In zh, this message translates to:
  /// **'未启用'**
  String get engineProviderInactive;

  /// No description provided for @engineProviderConfiguredInWeb.
  ///
  /// In zh, this message translates to:
  /// **'网页版配置'**
  String get engineProviderConfiguredInWeb;

  /// No description provided for @engineProvidersTitle.
  ///
  /// In zh, this message translates to:
  /// **'模型'**
  String get engineProvidersTitle;

  /// No description provided for @engineProvidersNotConnected.
  ///
  /// In zh, this message translates to:
  /// **'没有连上引擎'**
  String get engineProvidersNotConnected;

  /// No description provided for @engineProvidersStartEngine.
  ///
  /// In zh, this message translates to:
  /// **'引擎运行后可添加渠道'**
  String get engineProvidersStartEngine;

  /// No description provided for @engineProvidersUnsupported.
  ///
  /// In zh, this message translates to:
  /// **'这台主机不支持自定义渠道'**
  String get engineProvidersUnsupported;

  /// No description provided for @engineProvidersNotConfiguredHere.
  ///
  /// In zh, this message translates to:
  /// **'未在这台主机上配置'**
  String get engineProvidersNotConfiguredHere;

  /// No description provided for @engineProvidersSigningIn.
  ///
  /// In zh, this message translates to:
  /// **'正在登录…'**
  String get engineProvidersSigningIn;

  /// No description provided for @engineProvidersSignInOrKey.
  ///
  /// In zh, this message translates to:
  /// **'登录账号或填写 API Key'**
  String get engineProvidersSignInOrKey;

  /// No description provided for @engineProvidersOfficial.
  ///
  /// In zh, this message translates to:
  /// **'官方'**
  String get engineProvidersOfficial;

  /// No description provided for @engineProvidersSubscription.
  ///
  /// In zh, this message translates to:
  /// **'订阅'**
  String get engineProvidersSubscription;

  /// No description provided for @engineProvidersCustom.
  ///
  /// In zh, this message translates to:
  /// **'自定义'**
  String get engineProvidersCustom;

  /// No description provided for @engineProvidersCompatibleHint.
  ///
  /// In zh, this message translates to:
  /// **'OpenAI、Anthropic 兼容的服务'**
  String get engineProvidersCompatibleHint;

  /// No description provided for @engineProvidersReadOnly.
  ///
  /// In zh, this message translates to:
  /// **'引擎设置是只读的，无法添加'**
  String get engineProvidersReadOnly;

  /// No description provided for @engineSubscriptionSignOutBody.
  ///
  /// In zh, this message translates to:
  /// **'它的模型会从模型选择里移除。'**
  String get engineSubscriptionSignOutBody;

  /// No description provided for @engineSubscriptionNoModels.
  ///
  /// In zh, this message translates to:
  /// **'暂无模型'**
  String get engineSubscriptionNoModels;

  /// No description provided for @engineSubscriptionModelsFailed.
  ///
  /// In zh, this message translates to:
  /// **'没能读取模型'**
  String get engineSubscriptionModelsFailed;

  /// No description provided for @engineSubscriptionPreparing.
  ///
  /// In zh, this message translates to:
  /// **'正在准备…'**
  String get engineSubscriptionPreparing;

  /// No description provided for @engineSubscriptionCancelled.
  ///
  /// In zh, this message translates to:
  /// **'登录已取消'**
  String get engineSubscriptionCancelled;

  /// No description provided for @engineSubscriptionIncomplete.
  ///
  /// In zh, this message translates to:
  /// **'登录没有完成'**
  String get engineSubscriptionIncomplete;

  /// No description provided for @engineSubscriptionWaitingSignIn.
  ///
  /// In zh, this message translates to:
  /// **'等待登录…'**
  String get engineSubscriptionWaitingSignIn;

  /// No description provided for @engineSubscriptionReopen.
  ///
  /// In zh, this message translates to:
  /// **'重新打开'**
  String get engineSubscriptionReopen;

  /// No description provided for @engineSubscriptionCode.
  ///
  /// In zh, this message translates to:
  /// **'验证码'**
  String get engineSubscriptionCode;

  /// No description provided for @engineSubscriptionWaitingVerification.
  ///
  /// In zh, this message translates to:
  /// **'等待验证…'**
  String get engineSubscriptionWaitingVerification;

  /// No description provided for @engineSubscriptionCopyCode.
  ///
  /// In zh, this message translates to:
  /// **'复制验证码'**
  String get engineSubscriptionCopyCode;

  /// No description provided for @engineSubscriptionOpenVerification.
  ///
  /// In zh, this message translates to:
  /// **'打开验证页'**
  String get engineSubscriptionOpenVerification;

  /// No description provided for @engineSubscriptionPasteRedirect.
  ///
  /// In zh, this message translates to:
  /// **'粘贴跳转后的链接'**
  String get engineSubscriptionPasteRedirect;

  /// No description provided for @engineSubscriptionPasteCode.
  ///
  /// In zh, this message translates to:
  /// **'粘贴授权码'**
  String get engineSubscriptionPasteCode;

  /// No description provided for @engineSubscriptionPasteHere.
  ///
  /// In zh, this message translates to:
  /// **'粘贴到这里'**
  String get engineSubscriptionPasteHere;

  /// No description provided for @engineSubscriptionConfirm.
  ///
  /// In zh, this message translates to:
  /// **'确定'**
  String get engineSubscriptionConfirm;

  /// No description provided for @engineSubscriptionTryAgain.
  ///
  /// In zh, this message translates to:
  /// **'再试一次'**
  String get engineSubscriptionTryAgain;

  /// No description provided for @engineAccountWelcome.
  ///
  /// In zh, this message translates to:
  /// **'欢迎，{name}'**
  String engineAccountWelcome(String name);

  /// No description provided for @engineLayerCount.
  ///
  /// In zh, this message translates to:
  /// **'{count} 层'**
  String engineLayerCount(int count);

  /// No description provided for @engineFieldDefaultValue.
  ///
  /// In zh, this message translates to:
  /// **'默认 {value}'**
  String engineFieldDefaultValue(String value);

  /// No description provided for @engineFieldDefaultValueUnit.
  ///
  /// In zh, this message translates to:
  /// **'默认 {value} {unit}'**
  String engineFieldDefaultValueUnit(String value, String unit);

  /// No description provided for @engineFieldCurrentValue.
  ///
  /// In zh, this message translates to:
  /// **'当前 {value}'**
  String engineFieldCurrentValue(String value);

  /// No description provided for @engineFieldRemoveItem.
  ///
  /// In zh, this message translates to:
  /// **'移除 {name}'**
  String engineFieldRemoveItem(String name);

  /// No description provided for @engineFieldAddItem.
  ///
  /// In zh, this message translates to:
  /// **'添加{item}'**
  String engineFieldAddItem(String item);

  /// No description provided for @engineFieldItemIndex.
  ///
  /// In zh, this message translates to:
  /// **'第 {index} 项'**
  String engineFieldItemIndex(int index);

  /// No description provided for @engineFieldByteCount.
  ///
  /// In zh, this message translates to:
  /// **'{count} 字节'**
  String engineFieldByteCount(int count);

  /// No description provided for @engineFieldHours.
  ///
  /// In zh, this message translates to:
  /// **'{value} 小时'**
  String engineFieldHours(String value);

  /// No description provided for @engineFieldMinutes.
  ///
  /// In zh, this message translates to:
  /// **'{value} 分钟'**
  String engineFieldMinutes(String value);

  /// No description provided for @engineFieldSeconds.
  ///
  /// In zh, this message translates to:
  /// **'{value} 秒'**
  String engineFieldSeconds(String value);

  /// No description provided for @engineFieldMilliseconds.
  ///
  /// In zh, this message translates to:
  /// **'{value} 毫秒'**
  String engineFieldMilliseconds(String value);

  /// No description provided for @engineFieldPositiveMax.
  ///
  /// In zh, this message translates to:
  /// **'大于 0，不超过 {max}'**
  String engineFieldPositiveMax(String max);

  /// No description provided for @engineFieldMin.
  ///
  /// In zh, this message translates to:
  /// **'不小于 {min}'**
  String engineFieldMin(String min);

  /// No description provided for @engineFieldMaxBound.
  ///
  /// In zh, this message translates to:
  /// **'不超过 {max}'**
  String engineFieldMaxBound(String max);

  /// No description provided for @engineFieldBelowMin.
  ///
  /// In zh, this message translates to:
  /// **'不能小于 {min}'**
  String engineFieldBelowMin(String min);

  /// No description provided for @engineFieldAboveMax.
  ///
  /// In zh, this message translates to:
  /// **'不能大于 {max}'**
  String engineFieldAboveMax(String max);

  /// No description provided for @engineFieldMultiple.
  ///
  /// In zh, this message translates to:
  /// **'需是 {step} 的倍数'**
  String engineFieldMultiple(String step);

  /// No description provided for @engineFieldMinCharacters.
  ///
  /// In zh, this message translates to:
  /// **'至少 {count} 个字符'**
  String engineFieldMinCharacters(int count);

  /// No description provided for @engineFieldMaxCharacters.
  ///
  /// In zh, this message translates to:
  /// **'最多 {count} 个字符'**
  String engineFieldMaxCharacters(int count);

  /// No description provided for @engineSubagentUnavailableProvider.
  ///
  /// In zh, this message translates to:
  /// **'{provider} · 当前不可用'**
  String engineSubagentUnavailableProvider(String provider);

  /// No description provided for @engineProviderDeleteTitle.
  ///
  /// In zh, this message translates to:
  /// **'删除「{name}」？'**
  String engineProviderDeleteTitle(String name);

  /// No description provided for @engineProviderDeleteFailed.
  ///
  /// In zh, this message translates to:
  /// **'没能删除：{error}'**
  String engineProviderDeleteFailed(String error);

  /// No description provided for @engineProviderModelCount.
  ///
  /// In zh, this message translates to:
  /// **'模型 · {count}'**
  String engineProviderModelCount(int count);

  /// No description provided for @engineProviderContext.
  ///
  /// In zh, this message translates to:
  /// **'上下文 {size}'**
  String engineProviderContext(String size);

  /// No description provided for @engineProviderTestPassed.
  ///
  /// In zh, this message translates to:
  /// **'连接正常 · 列出 {count} 个模型'**
  String engineProviderTestPassed(int count);

  /// No description provided for @engineProviderCompletedUrl.
  ///
  /// In zh, this message translates to:
  /// **'已补全为 {url}'**
  String engineProviderCompletedUrl(String url);

  /// No description provided for @engineProviderSaveFailed.
  ///
  /// In zh, this message translates to:
  /// **'没能保存：{error}'**
  String engineProviderSaveFailed(String error);

  /// No description provided for @engineProviderCandidateCount.
  ///
  /// In zh, this message translates to:
  /// **'共 {count} 个'**
  String engineProviderCandidateCount(int count);

  /// No description provided for @engineProviderAddModels.
  ///
  /// In zh, this message translates to:
  /// **'添加 {count} 个模型'**
  String engineProviderAddModels(int count);

  /// No description provided for @engineProviderModels.
  ///
  /// In zh, this message translates to:
  /// **'{count} 个模型'**
  String engineProviderModels(int count);

  /// No description provided for @engineProvidersSummary.
  ///
  /// In zh, this message translates to:
  /// **'{total} 个渠道 · {ready} 个可用'**
  String engineProvidersSummary(int total, int ready);

  /// No description provided for @engineProvidersAccount.
  ///
  /// In zh, this message translates to:
  /// **'账号 · {name}'**
  String engineProvidersAccount(String name);

  /// No description provided for @engineProvidersSignedInAccount.
  ///
  /// In zh, this message translates to:
  /// **'已登录 · {account}'**
  String engineProvidersSignedInAccount(String account);

  /// No description provided for @engineSubscriptionSignIn.
  ///
  /// In zh, this message translates to:
  /// **'登录 {provider}'**
  String engineSubscriptionSignIn(String provider);

  /// No description provided for @engineSubscriptionSignOutTitle.
  ///
  /// In zh, this message translates to:
  /// **'退出 {provider}？'**
  String engineSubscriptionSignOutTitle(String provider);

  /// No description provided for @engineSubscriptionSignOutFailed.
  ///
  /// In zh, this message translates to:
  /// **'没能退出：{error}'**
  String engineSubscriptionSignOutFailed(String error);

  /// No description provided for @engineSubscriptionCodeSemantics.
  ///
  /// In zh, this message translates to:
  /// **'验证码 {code}'**
  String engineSubscriptionCodeSemantics(String code);

  /// No description provided for @engineFieldItemCount.
  ///
  /// In zh, this message translates to:
  /// **'{count} 个'**
  String engineFieldItemCount(int count);

  /// No description provided for @engineFieldUseCount.
  ///
  /// In zh, this message translates to:
  /// **'{count} 次'**
  String engineFieldUseCount(int count);

  /// No description provided for @engineFieldResultCount.
  ///
  /// In zh, this message translates to:
  /// **'{count} 条'**
  String engineFieldResultCount(int count);

  /// No description provided for @engineFieldMinCharactersDecimal.
  ///
  /// In zh, this message translates to:
  /// **'至少 {bound} 个字符'**
  String engineFieldMinCharactersDecimal(String bound);

  /// No description provided for @engineFieldMaxCharactersDecimal.
  ///
  /// In zh, this message translates to:
  /// **'最多 {bound} 个字符'**
  String engineFieldMaxCharactersDecimal(String bound);

  /// No description provided for @engineLayerValue.
  ///
  /// In zh, this message translates to:
  /// **'{value} 层'**
  String engineLayerValue(String value);

  /// No description provided for @engineFieldEnterPositiveRange.
  ///
  /// In zh, this message translates to:
  /// **'请填 大于 0，不超过 {max} 之间的数'**
  String engineFieldEnterPositiveRange(String max);

  /// No description provided for @engineFieldEnterBoundedRange.
  ///
  /// In zh, this message translates to:
  /// **'请填 {min}–{max} 之间的数'**
  String engineFieldEnterBoundedRange(String min, String max);

  /// No description provided for @engineModelTokenLimits.
  ///
  /// In zh, this message translates to:
  /// **'Token 上限'**
  String get engineModelTokenLimits;

  /// No description provided for @engineModelContextLength.
  ///
  /// In zh, this message translates to:
  /// **'上下文长度'**
  String get engineModelContextLength;

  /// No description provided for @engineModelContextOverrideHint.
  ///
  /// In zh, this message translates to:
  /// **'留空使用渠道目录里的值；改大后引擎按新值计算上下文占用与压缩。'**
  String get engineModelContextOverrideHint;

  /// No description provided for @engineModelMaxOutput.
  ///
  /// In zh, this message translates to:
  /// **'最大输出'**
  String get engineModelMaxOutput;

  /// No description provided for @engineModelDefaultSize.
  ///
  /// In zh, this message translates to:
  /// **'默认 {size}'**
  String engineModelDefaultSize(String size);

  /// No description provided for @engineModelCapabilities.
  ///
  /// In zh, this message translates to:
  /// **'能力'**
  String get engineModelCapabilities;

  /// No description provided for @engineModelInputType.
  ///
  /// In zh, this message translates to:
  /// **'输入类型'**
  String get engineModelInputType;

  /// No description provided for @engineModelInputText.
  ///
  /// In zh, this message translates to:
  /// **'文本'**
  String get engineModelInputText;

  /// No description provided for @engineModelInputTextImage.
  ///
  /// In zh, this message translates to:
  /// **'文本和图片'**
  String get engineModelInputTextImage;

  /// No description provided for @engineModelThinking.
  ///
  /// In zh, this message translates to:
  /// **'思考'**
  String get engineModelThinking;

  /// No description provided for @engineModelVision.
  ///
  /// In zh, this message translates to:
  /// **'识图'**
  String get engineModelVision;

  /// No description provided for @engineModelLevels.
  ///
  /// In zh, this message translates to:
  /// **'可选档位'**
  String get engineModelLevels;

  /// No description provided for @engineModelNeedLevel.
  ///
  /// In zh, this message translates to:
  /// **'至少选一个档位'**
  String get engineModelNeedLevel;

  /// No description provided for @engineFieldEditOnWeb.
  ///
  /// In zh, this message translates to:
  /// **'在网页版编辑此项'**
  String get engineFieldEditOnWeb;

  /// No description provided for @engineSettingsHostChanged.
  ///
  /// In zh, this message translates to:
  /// **'主机已切换，请重新打开设置后编辑。'**
  String get engineSettingsHostChanged;

  /// No description provided for @engineSecretTargetChanged.
  ///
  /// In zh, this message translates to:
  /// **'此项已变化，请重新打开后编辑。'**
  String get engineSecretTargetChanged;

  /// No description provided for @engineSettingsGroupCount.
  ///
  /// In zh, this message translates to:
  /// **'{count} 项'**
  String engineSettingsGroupCount(int count);

  /// No description provided for @featuresCordisSubtitle.
  ///
  /// In zh, this message translates to:
  /// **'动态插件 · 引擎重启后清空'**
  String get featuresCordisSubtitle;

  /// No description provided for @featuresCordisUnavailable.
  ///
  /// In zh, this message translates to:
  /// **'这个连接看不到 Cordis'**
  String get featuresCordisUnavailable;

  /// No description provided for @featuresCordisRemoteUnavailable.
  ///
  /// In zh, this message translates to:
  /// **'经 DSH Remote 中转时不可用'**
  String get featuresCordisRemoteUnavailable;

  /// No description provided for @featuresCordisReadFailed.
  ///
  /// In zh, this message translates to:
  /// **'没能读取插件'**
  String get featuresCordisReadFailed;

  /// No description provided for @featuresCordisEmpty.
  ///
  /// In zh, this message translates to:
  /// **'还没有动态插件'**
  String get featuresCordisEmpty;

  /// No description provided for @featuresCordisEmptyHint.
  ///
  /// In zh, this message translates to:
  /// **'插件创建后会出现在这里'**
  String get featuresCordisEmptyHint;

  /// No description provided for @featuresCurrentChat.
  ///
  /// In zh, this message translates to:
  /// **'当前对话'**
  String get featuresCurrentChat;

  /// No description provided for @featuresOtherChats.
  ///
  /// In zh, this message translates to:
  /// **'其他对话'**
  String get featuresOtherChats;

  /// No description provided for @featuresPresetDefaultSet.
  ///
  /// In zh, this message translates to:
  /// **'新对话将使用「{name}」'**
  String featuresPresetDefaultSet(String name);

  /// No description provided for @featuresPresetDefaultFailed.
  ///
  /// In zh, this message translates to:
  /// **'没能设为默认'**
  String get featuresPresetDefaultFailed;

  /// No description provided for @featuresPresetDeleteTitle.
  ///
  /// In zh, this message translates to:
  /// **'删除「{name}」？'**
  String featuresPresetDeleteTitle(String name);

  /// No description provided for @featuresPresetDeleteHint.
  ///
  /// In zh, this message translates to:
  /// **'新对话不能再选它，已开始的对话不受影响。'**
  String get featuresPresetDeleteHint;

  /// No description provided for @featuresDeleted.
  ///
  /// In zh, this message translates to:
  /// **'已删除'**
  String get featuresDeleted;

  /// No description provided for @featuresDeleteFailed.
  ///
  /// In zh, this message translates to:
  /// **'没能删除'**
  String get featuresDeleteFailed;

  /// No description provided for @featuresPresetAlreadyDefault.
  ///
  /// In zh, this message translates to:
  /// **'已是新对话默认'**
  String get featuresPresetAlreadyDefault;

  /// No description provided for @featuresPresetSetDefault.
  ///
  /// In zh, this message translates to:
  /// **'设为新对话默认'**
  String get featuresPresetSetDefault;

  /// No description provided for @featuresPresetViewConfig.
  ///
  /// In zh, this message translates to:
  /// **'查看配置'**
  String get featuresPresetViewConfig;

  /// No description provided for @featuresPresetDuplicate.
  ///
  /// In zh, this message translates to:
  /// **'复制为新预设'**
  String get featuresPresetDuplicate;

  /// No description provided for @featuresPresetDefaultDeleteHint.
  ///
  /// In zh, this message translates to:
  /// **'先把别的预设设为新对话默认'**
  String get featuresPresetDefaultDeleteHint;

  /// No description provided for @featuresAgentPresets.
  ///
  /// In zh, this message translates to:
  /// **'Agent 预设'**
  String get featuresAgentPresets;

  /// No description provided for @featuresAgentPresetsSubtitle.
  ///
  /// In zh, this message translates to:
  /// **'新对话的工具与工作方式'**
  String get featuresAgentPresetsSubtitle;

  /// No description provided for @featuresNew.
  ///
  /// In zh, this message translates to:
  /// **'新建'**
  String get featuresNew;

  /// No description provided for @featuresPresetsReadFailed.
  ///
  /// In zh, this message translates to:
  /// **'没能读取 Agent 预设'**
  String get featuresPresetsReadFailed;

  /// No description provided for @featuresLoadFailed.
  ///
  /// In zh, this message translates to:
  /// **'加载失败'**
  String get featuresLoadFailed;

  /// No description provided for @featuresNewChatDefault.
  ///
  /// In zh, this message translates to:
  /// **'新对话默认'**
  String get featuresNewChatDefault;

  /// No description provided for @featuresEmptyDocument.
  ///
  /// In zh, this message translates to:
  /// **'（空）'**
  String get featuresEmptyDocument;

  /// No description provided for @featuresReadFailed.
  ///
  /// In zh, this message translates to:
  /// **'没能读取'**
  String get featuresReadFailed;

  /// No description provided for @featuresTodayTime.
  ///
  /// In zh, this message translates to:
  /// **'今天 {time}'**
  String featuresTodayTime(String time);

  /// No description provided for @featuresTomorrowTime.
  ///
  /// In zh, this message translates to:
  /// **'明天 {time}'**
  String featuresTomorrowTime(String time);

  /// No description provided for @featuresYesterdayTime.
  ///
  /// In zh, this message translates to:
  /// **'昨天 {time}'**
  String featuresYesterdayTime(String time);

  /// No description provided for @featuresScheduleSummaryNext.
  ///
  /// In zh, this message translates to:
  /// **'{rule} · 下次 {time}'**
  String featuresScheduleSummaryNext(String rule, String time);

  /// No description provided for @featuresEnded.
  ///
  /// In zh, this message translates to:
  /// **'已结束'**
  String get featuresEnded;

  /// No description provided for @featuresScheduleSummaryEnded.
  ///
  /// In zh, this message translates to:
  /// **'已结束 · {time} 运行过'**
  String featuresScheduleSummaryEnded(String time);

  /// No description provided for @featuresJobElapsed.
  ///
  /// In zh, this message translates to:
  /// **'已运行 {span}'**
  String featuresJobElapsed(String span);

  /// No description provided for @featuresJobDuration.
  ///
  /// In zh, this message translates to:
  /// **'用时 {span}'**
  String featuresJobDuration(String span);

  /// No description provided for @featuresPermissionReadOnly.
  ///
  /// In zh, this message translates to:
  /// **'仅可查看'**
  String get featuresPermissionReadOnly;

  /// No description provided for @featuresPermissionWorkspaceWrite.
  ///
  /// In zh, this message translates to:
  /// **'工作区内修改'**
  String get featuresPermissionWorkspaceWrite;

  /// No description provided for @featuresPermissionFullAccess.
  ///
  /// In zh, this message translates to:
  /// **'完全权限'**
  String get featuresPermissionFullAccess;

  /// No description provided for @featuresPermissionAutoReview.
  ///
  /// In zh, this message translates to:
  /// **'自动审查'**
  String get featuresPermissionAutoReview;

  /// No description provided for @featuresPermissionCustom.
  ///
  /// In zh, this message translates to:
  /// **'自定义'**
  String get featuresPermissionCustom;

  /// No description provided for @featuresPermissionReadOnlyHint.
  ///
  /// In zh, this message translates to:
  /// **'只看文件，不做修改'**
  String get featuresPermissionReadOnlyHint;

  /// No description provided for @featuresPermissionWorkspaceWriteHint.
  ///
  /// In zh, this message translates to:
  /// **'可改工作区内的文件，越界先问你'**
  String get featuresPermissionWorkspaceWriteHint;

  /// No description provided for @featuresPermissionFullAccessHint.
  ///
  /// In zh, this message translates to:
  /// **'不再确认，直接执行'**
  String get featuresPermissionFullAccessHint;

  /// No description provided for @featuresPermissionAutoReviewHint.
  ///
  /// In zh, this message translates to:
  /// **'由模型逐次审查，拿不准再问你'**
  String get featuresPermissionAutoReviewHint;

  /// No description provided for @featuresPresetStandard.
  ///
  /// In zh, this message translates to:
  /// **'标准模式'**
  String get featuresPresetStandard;

  /// No description provided for @featuresPresetPtc.
  ///
  /// In zh, this message translates to:
  /// **'PTC 模式'**
  String get featuresPresetPtc;

  /// No description provided for @featuresPresetMinimal.
  ///
  /// In zh, this message translates to:
  /// **'极简模式'**
  String get featuresPresetMinimal;

  /// No description provided for @featuresPresetCreator.
  ///
  /// In zh, this message translates to:
  /// **'创造模式'**
  String get featuresPresetCreator;

  /// No description provided for @featuresPresetStandardDescription.
  ///
  /// In zh, this message translates to:
  /// **'代码、文件和资料，适合大多数任务'**
  String get featuresPresetStandardDescription;

  /// No description provided for @featuresPresetPtcDescription.
  ///
  /// In zh, this message translates to:
  /// **'批量调用工具，再筛选、统计、汇总'**
  String get featuresPresetPtcDescription;

  /// No description provided for @featuresPresetMinimalDescription.
  ///
  /// In zh, this message translates to:
  /// **'只用终端和读图，适合测试对比'**
  String get featuresPresetMinimalDescription;

  /// No description provided for @featuresPresetCreatorDescription.
  ///
  /// In zh, this message translates to:
  /// **'让 Agent 写插件，定制 DSH 本身'**
  String get featuresPresetCreatorDescription;

  /// No description provided for @featuresHostUnreachable.
  ///
  /// In zh, this message translates to:
  /// **'连不上「{name}」'**
  String featuresHostUnreachable(String name);

  /// No description provided for @featuresHostConnecting.
  ///
  /// In zh, this message translates to:
  /// **'正在连接「{name}」…'**
  String featuresHostConnecting(String name);

  /// No description provided for @featuresJobs.
  ///
  /// In zh, this message translates to:
  /// **'后台任务'**
  String get featuresJobs;

  /// No description provided for @featuresJobsSubtitle.
  ///
  /// In zh, this message translates to:
  /// **'引擎重启后清空'**
  String get featuresJobsSubtitle;

  /// No description provided for @featuresJobsReadFailed.
  ///
  /// In zh, this message translates to:
  /// **'没能读取后台任务'**
  String get featuresJobsReadFailed;

  /// No description provided for @featuresJobsEmpty.
  ///
  /// In zh, this message translates to:
  /// **'没有后台任务'**
  String get featuresJobsEmpty;

  /// No description provided for @featuresJobsEmptyHint.
  ///
  /// In zh, this message translates to:
  /// **'开发服务器这类命令会在这里'**
  String get featuresJobsEmptyHint;

  /// No description provided for @featuresJobsEndedCount.
  ///
  /// In zh, this message translates to:
  /// **'已结束 · {count}'**
  String featuresJobsEndedCount(int count);

  /// No description provided for @featuresJobStopTitle.
  ///
  /// In zh, this message translates to:
  /// **'停止这个任务？'**
  String get featuresJobStopTitle;

  /// No description provided for @featuresJobAlreadyEnded.
  ///
  /// In zh, this message translates to:
  /// **'任务已经结束了'**
  String get featuresJobAlreadyEnded;

  /// No description provided for @featuresJobStopFailed.
  ///
  /// In zh, this message translates to:
  /// **'没能停止'**
  String get featuresJobStopFailed;

  /// No description provided for @featuresJobOutput.
  ///
  /// In zh, this message translates to:
  /// **'任务输出'**
  String get featuresJobOutput;

  /// No description provided for @featuresOutput.
  ///
  /// In zh, this message translates to:
  /// **'输出'**
  String get featuresOutput;

  /// No description provided for @featuresJobRecentLines.
  ///
  /// In zh, this message translates to:
  /// **'最近 {count} 行'**
  String featuresJobRecentLines(int count);

  /// No description provided for @featuresJobOutputSubject.
  ///
  /// In zh, this message translates to:
  /// **'DSH 任务输出'**
  String get featuresJobOutputSubject;

  /// No description provided for @featuresJobOutputReadFailed.
  ///
  /// In zh, this message translates to:
  /// **'没能读取输出'**
  String get featuresJobOutputReadFailed;

  /// No description provided for @featuresJobOutputWaiting.
  ///
  /// In zh, this message translates to:
  /// **'等待输出…'**
  String get featuresJobOutputWaiting;

  /// No description provided for @featuresJobOutputEmpty.
  ///
  /// In zh, this message translates to:
  /// **'没有输出'**
  String get featuresJobOutputEmpty;

  /// No description provided for @featuresPermissionAutoTitle.
  ///
  /// In zh, this message translates to:
  /// **'开启自动审查？'**
  String get featuresPermissionAutoTitle;

  /// No description provided for @featuresPermissionAutoWarning.
  ///
  /// In zh, this message translates to:
  /// **'每次操作由模型判断放不放行，可能误判。'**
  String get featuresPermissionAutoWarning;

  /// No description provided for @featuresSwitchFailed.
  ///
  /// In zh, this message translates to:
  /// **'没能切换'**
  String get featuresSwitchFailed;

  /// No description provided for @featuresPermissions.
  ///
  /// In zh, this message translates to:
  /// **'权限'**
  String get featuresPermissions;

  /// No description provided for @featuresPermissionsSubtitle.
  ///
  /// In zh, this message translates to:
  /// **'执行命令、修改文件前，要不要先问你'**
  String get featuresPermissionsSubtitle;

  /// No description provided for @featuresPermissionsReadFailed.
  ///
  /// In zh, this message translates to:
  /// **'没能读取权限设置'**
  String get featuresPermissionsReadFailed;

  /// No description provided for @featuresPermissionCustomHint.
  ///
  /// In zh, this message translates to:
  /// **'当前用的是自定义权限，选预设会替换它'**
  String get featuresPermissionCustomHint;

  /// No description provided for @featuresModuleInstructions.
  ///
  /// In zh, this message translates to:
  /// **'工作区指令加载'**
  String get featuresModuleInstructions;

  /// No description provided for @featuresModuleTime.
  ///
  /// In zh, this message translates to:
  /// **'时间感知'**
  String get featuresModuleTime;

  /// No description provided for @featuresModuleBash.
  ///
  /// In zh, this message translates to:
  /// **'Bash 命令工具'**
  String get featuresModuleBash;

  /// No description provided for @featuresModulePersistentBash.
  ///
  /// In zh, this message translates to:
  /// **'持久 Bash 工具'**
  String get featuresModulePersistentBash;

  /// No description provided for @featuresModulePowerShell.
  ///
  /// In zh, this message translates to:
  /// **'PowerShell 命令工具'**
  String get featuresModulePowerShell;

  /// No description provided for @featuresModuleFiles.
  ///
  /// In zh, this message translates to:
  /// **'文件读写工具'**
  String get featuresModuleFiles;

  /// No description provided for @featuresModuleFileSearch.
  ///
  /// In zh, this message translates to:
  /// **'文件搜索工具'**
  String get featuresModuleFileSearch;

  /// No description provided for @featuresModuleJobs.
  ///
  /// In zh, this message translates to:
  /// **'后台任务工具'**
  String get featuresModuleJobs;

  /// No description provided for @featuresModuleSchedule.
  ///
  /// In zh, this message translates to:
  /// **'自动化任务工具'**
  String get featuresModuleSchedule;

  /// No description provided for @featuresModuleLocalSkills.
  ///
  /// In zh, this message translates to:
  /// **'本地技能加载'**
  String get featuresModuleLocalSkills;

  /// No description provided for @featuresModuleSkillTool.
  ///
  /// In zh, this message translates to:
  /// **'技能加载工具'**
  String get featuresModuleSkillTool;

  /// No description provided for @featuresModuleGoalCommand.
  ///
  /// In zh, this message translates to:
  /// **'目标管理命令'**
  String get featuresModuleGoalCommand;

  /// No description provided for @featuresModuleGoalTool.
  ///
  /// In zh, this message translates to:
  /// **'目标管理工具'**
  String get featuresModuleGoalTool;

  /// No description provided for @featuresModulePlan.
  ///
  /// In zh, this message translates to:
  /// **'计划模式'**
  String get featuresModulePlan;

  /// No description provided for @featuresModuleCompaction.
  ///
  /// In zh, this message translates to:
  /// **'上下文压缩'**
  String get featuresModuleCompaction;

  /// No description provided for @featuresModuleCompactCommand.
  ///
  /// In zh, this message translates to:
  /// **'上下文压缩命令'**
  String get featuresModuleCompactCommand;

  /// No description provided for @featuresModuleAskUser.
  ///
  /// In zh, this message translates to:
  /// **'向用户提问工具'**
  String get featuresModuleAskUser;

  /// No description provided for @featuresModuleTodo.
  ///
  /// In zh, this message translates to:
  /// **'待办清单工具'**
  String get featuresModuleTodo;

  /// No description provided for @featuresModuleWeb.
  ///
  /// In zh, this message translates to:
  /// **'网页搜索与读取工具'**
  String get featuresModuleWeb;

  /// No description provided for @featuresModulePresent.
  ///
  /// In zh, this message translates to:
  /// **'文件交付工具'**
  String get featuresModulePresent;

  /// No description provided for @featuresModuleCordis.
  ///
  /// In zh, this message translates to:
  /// **'插件 API 查询工具'**
  String get featuresModuleCordis;

  /// No description provided for @featuresModuleSubagent.
  ///
  /// In zh, this message translates to:
  /// **'子代理委派工具'**
  String get featuresModuleSubagent;

  /// No description provided for @featuresModuleSubagentControl.
  ///
  /// In zh, this message translates to:
  /// **'子代理控制工具'**
  String get featuresModuleSubagentControl;

  /// No description provided for @featuresModuleWorkflow.
  ///
  /// In zh, this message translates to:
  /// **'工作流工具'**
  String get featuresModuleWorkflow;

  /// No description provided for @featuresModulePluginManager.
  ///
  /// In zh, this message translates to:
  /// **'插件管理工具'**
  String get featuresModulePluginManager;

  /// No description provided for @featuresModulePluginMarket.
  ///
  /// In zh, this message translates to:
  /// **'插件市场工具'**
  String get featuresModulePluginMarket;

  /// No description provided for @featuresModuleToolCalls.
  ///
  /// In zh, this message translates to:
  /// **'工具调用方式'**
  String get featuresModuleToolCalls;

  /// No description provided for @featuresModuleTerminal.
  ///
  /// In zh, this message translates to:
  /// **'持久终端服务'**
  String get featuresModuleTerminal;

  /// No description provided for @featuresModulePersona.
  ///
  /// In zh, this message translates to:
  /// **'智能体角色设定'**
  String get featuresModulePersona;

  /// No description provided for @featuresGroupDelegation.
  ///
  /// In zh, this message translates to:
  /// **'子代理委派'**
  String get featuresGroupDelegation;

  /// No description provided for @featuresGroupTerminal.
  ///
  /// In zh, this message translates to:
  /// **'持久终端'**
  String get featuresGroupTerminal;

  /// No description provided for @featuresPresetIdRequired.
  ///
  /// In zh, this message translates to:
  /// **'填写标识'**
  String get featuresPresetIdRequired;

  /// No description provided for @featuresPresetIdLength.
  ///
  /// In zh, this message translates to:
  /// **'最多 40 个字符'**
  String get featuresPresetIdLength;

  /// No description provided for @featuresPresetIdFormat.
  ///
  /// In zh, this message translates to:
  /// **'只用小写字母、数字和连字符'**
  String get featuresPresetIdFormat;

  /// No description provided for @featuresPresetIdTaken.
  ///
  /// In zh, this message translates to:
  /// **'这个标识已被使用'**
  String get featuresPresetIdTaken;

  /// No description provided for @featuresPresetCopyName.
  ///
  /// In zh, this message translates to:
  /// **'{name} 副本'**
  String featuresPresetCopyName(String name);

  /// No description provided for @featuresPresetBasedOn.
  ///
  /// In zh, this message translates to:
  /// **'基于'**
  String get featuresPresetBasedOn;

  /// No description provided for @featuresNameRequired.
  ///
  /// In zh, this message translates to:
  /// **'填写名称'**
  String get featuresNameRequired;

  /// No description provided for @featuresCreatorOpenFailed.
  ///
  /// In zh, this message translates to:
  /// **'没能打开创造模式'**
  String get featuresCreatorOpenFailed;

  /// No description provided for @featuresPresetNameHint.
  ///
  /// In zh, this message translates to:
  /// **'比如：代码审查'**
  String get featuresPresetNameHint;

  /// No description provided for @featuresPresetId.
  ///
  /// In zh, this message translates to:
  /// **'标识'**
  String get featuresPresetId;

  /// No description provided for @featuresPresetIdHint.
  ///
  /// In zh, this message translates to:
  /// **'小写字母、数字和连字符'**
  String get featuresPresetIdHint;

  /// No description provided for @featuresPresetDescription.
  ///
  /// In zh, this message translates to:
  /// **'说明'**
  String get featuresPresetDescription;

  /// No description provided for @featuresPresetDescriptionHint.
  ///
  /// In zh, this message translates to:
  /// **'一句话说明它适合做什么'**
  String get featuresPresetDescriptionHint;

  /// No description provided for @featuresPresetConfigReadFailed.
  ///
  /// In zh, this message translates to:
  /// **'没能读取预设配置'**
  String get featuresPresetConfigReadFailed;

  /// No description provided for @featuresPresetCreateTitle.
  ///
  /// In zh, this message translates to:
  /// **'新建 Agent 预设'**
  String get featuresPresetCreateTitle;

  /// No description provided for @featuresPresetDuplicateTitle.
  ///
  /// In zh, this message translates to:
  /// **'复制 Agent 预设'**
  String get featuresPresetDuplicateTitle;

  /// No description provided for @featuresPresetEditTitle.
  ///
  /// In zh, this message translates to:
  /// **'编辑 Agent 预设'**
  String get featuresPresetEditTitle;

  /// No description provided for @featuresCreatorOpening.
  ///
  /// In zh, this message translates to:
  /// **'正在打开创造模式'**
  String get featuresCreatorOpening;

  /// No description provided for @featuresWaitingEngine.
  ///
  /// In zh, this message translates to:
  /// **'等待引擎连接'**
  String get featuresWaitingEngine;

  /// No description provided for @featuresCreatorUnavailable.
  ///
  /// In zh, this message translates to:
  /// **'创造模式不可用'**
  String get featuresCreatorUnavailable;

  /// No description provided for @featuresPresetStartUpdate.
  ///
  /// In zh, this message translates to:
  /// **'开始更新'**
  String get featuresPresetStartUpdate;

  /// No description provided for @featuresPresetStartCreate.
  ///
  /// In zh, this message translates to:
  /// **'开始创建'**
  String get featuresPresetStartCreate;

  /// No description provided for @featuresPresetSystemPrompt.
  ///
  /// In zh, this message translates to:
  /// **'系统提示'**
  String get featuresPresetSystemPrompt;

  /// No description provided for @featuresPresetSystemPromptHint.
  ///
  /// In zh, this message translates to:
  /// **'你是谁、怎么工作'**
  String get featuresPresetSystemPromptHint;

  /// No description provided for @featuresPresetReplaceSystemPrompt.
  ///
  /// In zh, this message translates to:
  /// **'完整替换系统提示'**
  String get featuresPresetReplaceSystemPrompt;

  /// No description provided for @featuresPresetTools.
  ///
  /// In zh, this message translates to:
  /// **'工具'**
  String get featuresPresetTools;

  /// No description provided for @featuresSkills.
  ///
  /// In zh, this message translates to:
  /// **'技能'**
  String get featuresSkills;

  /// No description provided for @featuresPresetContextModes.
  ///
  /// In zh, this message translates to:
  /// **'上下文与模式'**
  String get featuresPresetContextModes;

  /// No description provided for @featuresCronMinute.
  ///
  /// In zh, this message translates to:
  /// **'分钟'**
  String get featuresCronMinute;

  /// No description provided for @featuresCronHour.
  ///
  /// In zh, this message translates to:
  /// **'小时'**
  String get featuresCronHour;

  /// No description provided for @featuresDate.
  ///
  /// In zh, this message translates to:
  /// **'日期'**
  String get featuresDate;

  /// No description provided for @featuresCronMonth.
  ///
  /// In zh, this message translates to:
  /// **'月份'**
  String get featuresCronMonth;

  /// No description provided for @featuresCronWeekday.
  ///
  /// In zh, this message translates to:
  /// **'星期'**
  String get featuresCronWeekday;

  /// No description provided for @featuresCronRequired.
  ///
  /// In zh, this message translates to:
  /// **'填写 5 段 Cron 表达式'**
  String get featuresCronRequired;

  /// No description provided for @featuresCronWhitespace.
  ///
  /// In zh, this message translates to:
  /// **'首尾不能有空格'**
  String get featuresCronWhitespace;

  /// No description provided for @featuresCronFieldCount.
  ///
  /// In zh, this message translates to:
  /// **'需要 5 段，现在是 {count} 段'**
  String featuresCronFieldCount(int count);

  /// No description provided for @featuresCronInvalidField.
  ///
  /// In zh, this message translates to:
  /// **'第 {index} 段（{name}）写法不对'**
  String featuresCronInvalidField(int index, String name);

  /// No description provided for @featuresWeekdayMon.
  ///
  /// In zh, this message translates to:
  /// **'一'**
  String get featuresWeekdayMon;

  /// No description provided for @featuresWeekdayTue.
  ///
  /// In zh, this message translates to:
  /// **'二'**
  String get featuresWeekdayTue;

  /// No description provided for @featuresWeekdayWed.
  ///
  /// In zh, this message translates to:
  /// **'三'**
  String get featuresWeekdayWed;

  /// No description provided for @featuresWeekdayThu.
  ///
  /// In zh, this message translates to:
  /// **'四'**
  String get featuresWeekdayThu;

  /// No description provided for @featuresWeekdayFri.
  ///
  /// In zh, this message translates to:
  /// **'五'**
  String get featuresWeekdayFri;

  /// No description provided for @featuresWeekdaySat.
  ///
  /// In zh, this message translates to:
  /// **'六'**
  String get featuresWeekdaySat;

  /// No description provided for @featuresWeekdaySun.
  ///
  /// In zh, this message translates to:
  /// **'日'**
  String get featuresWeekdaySun;

  /// No description provided for @featuresMonthJan.
  ///
  /// In zh, this message translates to:
  /// **'一月'**
  String get featuresMonthJan;

  /// No description provided for @featuresMonthFeb.
  ///
  /// In zh, this message translates to:
  /// **'二月'**
  String get featuresMonthFeb;

  /// No description provided for @featuresMonthMar.
  ///
  /// In zh, this message translates to:
  /// **'三月'**
  String get featuresMonthMar;

  /// No description provided for @featuresMonthApr.
  ///
  /// In zh, this message translates to:
  /// **'四月'**
  String get featuresMonthApr;

  /// No description provided for @featuresMonthMay.
  ///
  /// In zh, this message translates to:
  /// **'五月'**
  String get featuresMonthMay;

  /// No description provided for @featuresMonthJun.
  ///
  /// In zh, this message translates to:
  /// **'六月'**
  String get featuresMonthJun;

  /// No description provided for @featuresMonthJul.
  ///
  /// In zh, this message translates to:
  /// **'七月'**
  String get featuresMonthJul;

  /// No description provided for @featuresMonthAug.
  ///
  /// In zh, this message translates to:
  /// **'八月'**
  String get featuresMonthAug;

  /// No description provided for @featuresMonthSep.
  ///
  /// In zh, this message translates to:
  /// **'九月'**
  String get featuresMonthSep;

  /// No description provided for @featuresMonthOct.
  ///
  /// In zh, this message translates to:
  /// **'十月'**
  String get featuresMonthOct;

  /// No description provided for @featuresMonthNov.
  ///
  /// In zh, this message translates to:
  /// **'十一月'**
  String get featuresMonthNov;

  /// No description provided for @featuresMonthDec.
  ///
  /// In zh, this message translates to:
  /// **'十二月'**
  String get featuresMonthDec;

  /// No description provided for @featuresWeekdayName.
  ///
  /// In zh, this message translates to:
  /// **'周{day}'**
  String featuresWeekdayName(String day);

  /// No description provided for @featuresCronWeekdayRange.
  ///
  /// In zh, this message translates to:
  /// **'{first}至{last}'**
  String featuresCronWeekdayRange(String first, String last);

  /// No description provided for @featuresCronEveryDay.
  ///
  /// In zh, this message translates to:
  /// **'每天{months}'**
  String featuresCronEveryDay(String months);

  /// No description provided for @featuresCronMonthDays.
  ///
  /// In zh, this message translates to:
  /// **'每月 {days} 日{months}'**
  String featuresCronMonthDays(String days, String months);

  /// No description provided for @featuresCronMonthDaysAndWeekdays.
  ///
  /// In zh, this message translates to:
  /// **'每月 {days} 日且{weekdays}{months}'**
  String featuresCronMonthDaysAndWeekdays(String days, String weekdays, String months);

  /// No description provided for @featuresCronMonthDaysOrWeekdays.
  ///
  /// In zh, this message translates to:
  /// **'每月 {days} 日或{weekdays}{months}'**
  String featuresCronMonthDaysOrWeekdays(String days, String weekdays, String months);

  /// No description provided for @featuresCronHourRange.
  ///
  /// In zh, this message translates to:
  /// **'{first} 至 {last}'**
  String featuresCronHourRange(String first, String last);

  /// No description provided for @featuresEveryMinute.
  ///
  /// In zh, this message translates to:
  /// **'每分钟'**
  String get featuresEveryMinute;

  /// No description provided for @featuresCronEveryMinutes.
  ///
  /// In zh, this message translates to:
  /// **'每 {count} 分钟'**
  String featuresCronEveryMinutes(int count);

  /// No description provided for @featuresEveryHour.
  ///
  /// In zh, this message translates to:
  /// **'每小时'**
  String get featuresEveryHour;

  /// No description provided for @featuresCronHourlyMinutes.
  ///
  /// In zh, this message translates to:
  /// **'每小时的第 {minutes} 分钟'**
  String featuresCronHourlyMinutes(String minutes);

  /// No description provided for @featuresCronHoursEveryMinute.
  ///
  /// In zh, this message translates to:
  /// **'{hours} 点的每分钟'**
  String featuresCronHoursEveryMinute(String hours);

  /// No description provided for @featuresCronHoursEveryMinutes.
  ///
  /// In zh, this message translates to:
  /// **'{hours} 点内每 {count} 分钟'**
  String featuresCronHoursEveryMinutes(String hours, int count);

  /// No description provided for @featuresCronEveryHours.
  ///
  /// In zh, this message translates to:
  /// **'每 {count} 小时'**
  String featuresCronEveryHours(int count);

  /// No description provided for @featuresCronHoursMinutes.
  ///
  /// In zh, this message translates to:
  /// **'{hours} 点的第 {minutes} 分钟'**
  String featuresCronHoursMinutes(String hours, String minutes);

  /// No description provided for @featuresRepeatDaily.
  ///
  /// In zh, this message translates to:
  /// **'每天'**
  String get featuresRepeatDaily;

  /// No description provided for @featuresRepeatWeekdays.
  ///
  /// In zh, this message translates to:
  /// **'工作日'**
  String get featuresRepeatWeekdays;

  /// No description provided for @featuresRepeatWeekly.
  ///
  /// In zh, this message translates to:
  /// **'每周'**
  String get featuresRepeatWeekly;

  /// No description provided for @featuresRepeatMonthly.
  ///
  /// In zh, this message translates to:
  /// **'每月'**
  String get featuresRepeatMonthly;

  /// No description provided for @featuresRepeatInterval.
  ///
  /// In zh, this message translates to:
  /// **'间隔'**
  String get featuresRepeatInterval;

  /// No description provided for @featuresRepeatOnce.
  ///
  /// In zh, this message translates to:
  /// **'仅一次'**
  String get featuresRepeatOnce;

  /// No description provided for @featuresRepeatAdvanced.
  ///
  /// In zh, this message translates to:
  /// **'高级'**
  String get featuresRepeatAdvanced;

  /// No description provided for @featuresIntervalSeconds.
  ///
  /// In zh, this message translates to:
  /// **'秒'**
  String get featuresIntervalSeconds;

  /// No description provided for @featuresZoneUnavailable.
  ///
  /// In zh, this message translates to:
  /// **'时区不可用'**
  String get featuresZoneUnavailable;

  /// No description provided for @featuresChooseDay.
  ///
  /// In zh, this message translates to:
  /// **'至少选一天'**
  String get featuresChooseDay;

  /// No description provided for @featuresIntervalMinimum.
  ///
  /// In zh, this message translates to:
  /// **'间隔至少为 1'**
  String get featuresIntervalMinimum;

  /// No description provided for @featuresMinimumMinute.
  ///
  /// In zh, this message translates to:
  /// **'至少 1 分钟'**
  String get featuresMinimumMinute;

  /// No description provided for @featuresTimeDoesNotExist.
  ///
  /// In zh, this message translates to:
  /// **'这个时间在该时区不存在'**
  String get featuresTimeDoesNotExist;

  /// No description provided for @featuresChooseFutureTime.
  ///
  /// In zh, this message translates to:
  /// **'选一个以后的时间'**
  String get featuresChooseFutureTime;

  /// No description provided for @featuresCronNeverRuns.
  ///
  /// In zh, this message translates to:
  /// **'这个表达式不会运行'**
  String get featuresCronNeverRuns;

  /// No description provided for @featuresRuleDaily.
  ///
  /// In zh, this message translates to:
  /// **'每天 {time}'**
  String featuresRuleDaily(String time);

  /// No description provided for @featuresRuleWeekdays.
  ///
  /// In zh, this message translates to:
  /// **'每个工作日 {time}'**
  String featuresRuleWeekdays(String time);

  /// No description provided for @featuresRuleWeekends.
  ///
  /// In zh, this message translates to:
  /// **'每个周末 {time}'**
  String featuresRuleWeekends(String time);

  /// No description provided for @featuresRuleWeekly.
  ///
  /// In zh, this message translates to:
  /// **'每周{days} {time}'**
  String featuresRuleWeekly(String days, String time);

  /// No description provided for @featuresRuleMonthly.
  ///
  /// In zh, this message translates to:
  /// **'每月 {days} 日 {time}'**
  String featuresRuleMonthly(String days, String time);

  /// No description provided for @featuresRepeat.
  ///
  /// In zh, this message translates to:
  /// **'重复'**
  String get featuresRepeat;

  /// No description provided for @featuresChat.
  ///
  /// In zh, this message translates to:
  /// **'对话'**
  String get featuresChat;

  /// No description provided for @featuresWorkspace.
  ///
  /// In zh, this message translates to:
  /// **'工作区'**
  String get featuresWorkspace;

  /// No description provided for @featuresInstructionRequired.
  ///
  /// In zh, this message translates to:
  /// **'填写指令'**
  String get featuresInstructionRequired;

  /// No description provided for @featuresScheduleSaveError.
  ///
  /// In zh, this message translates to:
  /// **'没能保存：{reason}'**
  String featuresScheduleSaveError(String reason);

  /// No description provided for @featuresScheduleCreateError.
  ///
  /// In zh, this message translates to:
  /// **'没能创建：{reason}'**
  String featuresScheduleCreateError(String reason);

  /// No description provided for @featuresScheduleNameHint.
  ///
  /// In zh, this message translates to:
  /// **'比如：每日站会提醒'**
  String get featuresScheduleNameHint;

  /// No description provided for @featuresScheduleInstruction.
  ///
  /// In zh, this message translates to:
  /// **'指令'**
  String get featuresScheduleInstruction;

  /// No description provided for @featuresScheduleInstructionHint.
  ///
  /// In zh, this message translates to:
  /// **'比如：整理昨天的提交，发我摘要'**
  String get featuresScheduleInstructionHint;

  /// No description provided for @featuresScheduleRunTime.
  ///
  /// In zh, this message translates to:
  /// **'运行时间'**
  String get featuresScheduleRunTime;

  /// No description provided for @featuresScheduleOpenChat.
  ///
  /// In zh, this message translates to:
  /// **'去对话里看看'**
  String get featuresScheduleOpenChat;

  /// No description provided for @featuresScheduleEditTitle.
  ///
  /// In zh, this message translates to:
  /// **'编辑自动化任务'**
  String get featuresScheduleEditTitle;

  /// No description provided for @featuresScheduleCreateTitle.
  ///
  /// In zh, this message translates to:
  /// **'新建自动化任务'**
  String get featuresScheduleCreateTitle;

  /// No description provided for @featuresScheduleSaving.
  ///
  /// In zh, this message translates to:
  /// **'正在保存'**
  String get featuresScheduleSaving;

  /// No description provided for @featuresScheduleCreating.
  ///
  /// In zh, this message translates to:
  /// **'正在对话里创建'**
  String get featuresScheduleCreating;

  /// No description provided for @featuresTime.
  ///
  /// In zh, this message translates to:
  /// **'时间'**
  String get featuresTime;

  /// No description provided for @featuresNotSelected.
  ///
  /// In zh, this message translates to:
  /// **'未选'**
  String get featuresNotSelected;

  /// No description provided for @featuresMonthDaysLabel.
  ///
  /// In zh, this message translates to:
  /// **'{days} 日'**
  String featuresMonthDaysLabel(String days);

  /// No description provided for @featuresTimeZone.
  ///
  /// In zh, this message translates to:
  /// **'时区'**
  String get featuresTimeZone;

  /// No description provided for @featuresScheduleRunLocation.
  ///
  /// In zh, this message translates to:
  /// **'在哪里运行'**
  String get featuresScheduleRunLocation;

  /// No description provided for @featuresJustCreatedChat.
  ///
  /// In zh, this message translates to:
  /// **'刚建的对话'**
  String get featuresJustCreatedChat;

  /// No description provided for @featuresModel.
  ///
  /// In zh, this message translates to:
  /// **'模型'**
  String get featuresModel;

  /// No description provided for @featuresRequestRefused.
  ///
  /// In zh, this message translates to:
  /// **'引擎没有接受这个请求'**
  String get featuresRequestRefused;

  /// No description provided for @featuresScheduleNotFound.
  ///
  /// In zh, this message translates to:
  /// **'这个任务已经不在了'**
  String get featuresScheduleNotFound;

  /// No description provided for @featuresScheduleEndedError.
  ///
  /// In zh, this message translates to:
  /// **'任务已结束，不能再改'**
  String get featuresScheduleEndedError;

  /// No description provided for @featuresScheduleConflict.
  ///
  /// In zh, this message translates to:
  /// **'任务刚被改过，返回后再试'**
  String get featuresScheduleConflict;

  /// No description provided for @featuresScheduleInvalidPrompt.
  ///
  /// In zh, this message translates to:
  /// **'名称和指令不能为空，名称最多 120 字'**
  String get featuresScheduleInvalidPrompt;

  /// No description provided for @featuresScheduleInvalidTime.
  ///
  /// In zh, this message translates to:
  /// **'运行时间不对'**
  String get featuresScheduleInvalidTime;

  /// No description provided for @featuresScheduleIntervalTooShort.
  ///
  /// In zh, this message translates to:
  /// **'间隔至少 1 分钟'**
  String get featuresScheduleIntervalTooShort;

  /// No description provided for @featuresScheduleTimeOutOfRange.
  ///
  /// In zh, this message translates to:
  /// **'时间超出范围'**
  String get featuresScheduleTimeOutOfRange;

  /// No description provided for @featuresScheduleSubagentError.
  ///
  /// In zh, this message translates to:
  /// **'这个对话收不到自动化任务'**
  String get featuresScheduleSubagentError;

  /// No description provided for @featuresEvery.
  ///
  /// In zh, this message translates to:
  /// **'每'**
  String get featuresEvery;

  /// No description provided for @featuresCronExpression.
  ///
  /// In zh, this message translates to:
  /// **'Cron 表达式'**
  String get featuresCronExpression;

  /// No description provided for @featuresCronFieldGuide.
  ///
  /// In zh, this message translates to:
  /// **'分  时  日  月  周'**
  String get featuresCronFieldGuide;

  /// No description provided for @featuresZoneTimeSuffix.
  ///
  /// In zh, this message translates to:
  /// **'（{city}时间）'**
  String featuresZoneTimeSuffix(String city);

  /// No description provided for @featuresScheduleNextLocal.
  ///
  /// In zh, this message translates to:
  /// **'接下来（本机时间）'**
  String get featuresScheduleNextLocal;

  /// No description provided for @featuresScheduleNext.
  ///
  /// In zh, this message translates to:
  /// **'接下来'**
  String get featuresScheduleNext;

  /// No description provided for @featuresMonthDayChoice.
  ///
  /// In zh, this message translates to:
  /// **'{day} 日'**
  String featuresMonthDayChoice(int day);

  /// No description provided for @featuresZonesCommon.
  ///
  /// In zh, this message translates to:
  /// **'常用'**
  String get featuresZonesCommon;

  /// No description provided for @featuresZonesAll.
  ///
  /// In zh, this message translates to:
  /// **'全部'**
  String get featuresZonesAll;

  /// No description provided for @featuresZoneSearchHint.
  ///
  /// In zh, this message translates to:
  /// **'搜索城市、时区或 UTC 偏移'**
  String get featuresZoneSearchHint;

  /// No description provided for @featuresZonesNoMatch.
  ///
  /// In zh, this message translates to:
  /// **'没有匹配的时区'**
  String get featuresZonesNoMatch;

  /// No description provided for @featuresZoneUTC.
  ///
  /// In zh, this message translates to:
  /// **'协调世界时'**
  String get featuresZoneUTC;

  /// No description provided for @featuresZoneShanghai.
  ///
  /// In zh, this message translates to:
  /// **'上海'**
  String get featuresZoneShanghai;

  /// No description provided for @featuresZoneUrumqi.
  ///
  /// In zh, this message translates to:
  /// **'乌鲁木齐'**
  String get featuresZoneUrumqi;

  /// No description provided for @featuresZoneHongKong.
  ///
  /// In zh, this message translates to:
  /// **'香港'**
  String get featuresZoneHongKong;

  /// No description provided for @featuresZoneMacau.
  ///
  /// In zh, this message translates to:
  /// **'澳门'**
  String get featuresZoneMacau;

  /// No description provided for @featuresZoneTaipei.
  ///
  /// In zh, this message translates to:
  /// **'台北'**
  String get featuresZoneTaipei;

  /// No description provided for @featuresZoneTokyo.
  ///
  /// In zh, this message translates to:
  /// **'东京'**
  String get featuresZoneTokyo;

  /// No description provided for @featuresZoneSeoul.
  ///
  /// In zh, this message translates to:
  /// **'首尔'**
  String get featuresZoneSeoul;

  /// No description provided for @featuresZoneSingapore.
  ///
  /// In zh, this message translates to:
  /// **'新加坡'**
  String get featuresZoneSingapore;

  /// No description provided for @featuresZoneKualaLumpur.
  ///
  /// In zh, this message translates to:
  /// **'吉隆坡'**
  String get featuresZoneKualaLumpur;

  /// No description provided for @featuresZoneBangkok.
  ///
  /// In zh, this message translates to:
  /// **'曼谷'**
  String get featuresZoneBangkok;

  /// No description provided for @featuresZoneHoChiMinh.
  ///
  /// In zh, this message translates to:
  /// **'胡志明市'**
  String get featuresZoneHoChiMinh;

  /// No description provided for @featuresZoneJakarta.
  ///
  /// In zh, this message translates to:
  /// **'雅加达'**
  String get featuresZoneJakarta;

  /// No description provided for @featuresZoneManila.
  ///
  /// In zh, this message translates to:
  /// **'马尼拉'**
  String get featuresZoneManila;

  /// No description provided for @featuresZoneKolkata.
  ///
  /// In zh, this message translates to:
  /// **'加尔各答'**
  String get featuresZoneKolkata;

  /// No description provided for @featuresZoneDubai.
  ///
  /// In zh, this message translates to:
  /// **'迪拜'**
  String get featuresZoneDubai;

  /// No description provided for @featuresZoneJerusalem.
  ///
  /// In zh, this message translates to:
  /// **'耶路撒冷'**
  String get featuresZoneJerusalem;

  /// No description provided for @featuresZoneLondon.
  ///
  /// In zh, this message translates to:
  /// **'伦敦'**
  String get featuresZoneLondon;

  /// No description provided for @featuresZoneDublin.
  ///
  /// In zh, this message translates to:
  /// **'都柏林'**
  String get featuresZoneDublin;

  /// No description provided for @featuresZoneLisbon.
  ///
  /// In zh, this message translates to:
  /// **'里斯本'**
  String get featuresZoneLisbon;

  /// No description provided for @featuresZoneParis.
  ///
  /// In zh, this message translates to:
  /// **'巴黎'**
  String get featuresZoneParis;

  /// No description provided for @featuresZoneBerlin.
  ///
  /// In zh, this message translates to:
  /// **'柏林'**
  String get featuresZoneBerlin;

  /// No description provided for @featuresZoneMadrid.
  ///
  /// In zh, this message translates to:
  /// **'马德里'**
  String get featuresZoneMadrid;

  /// No description provided for @featuresZoneRome.
  ///
  /// In zh, this message translates to:
  /// **'罗马'**
  String get featuresZoneRome;

  /// No description provided for @featuresZoneAmsterdam.
  ///
  /// In zh, this message translates to:
  /// **'阿姆斯特丹'**
  String get featuresZoneAmsterdam;

  /// No description provided for @featuresZoneZurich.
  ///
  /// In zh, this message translates to:
  /// **'苏黎世'**
  String get featuresZoneZurich;

  /// No description provided for @featuresZoneStockholm.
  ///
  /// In zh, this message translates to:
  /// **'斯德哥尔摩'**
  String get featuresZoneStockholm;

  /// No description provided for @featuresZoneWarsaw.
  ///
  /// In zh, this message translates to:
  /// **'华沙'**
  String get featuresZoneWarsaw;

  /// No description provided for @featuresZoneAthens.
  ///
  /// In zh, this message translates to:
  /// **'雅典'**
  String get featuresZoneAthens;

  /// No description provided for @featuresZoneIstanbul.
  ///
  /// In zh, this message translates to:
  /// **'伊斯坦布尔'**
  String get featuresZoneIstanbul;

  /// No description provided for @featuresZoneMoscow.
  ///
  /// In zh, this message translates to:
  /// **'莫斯科'**
  String get featuresZoneMoscow;

  /// No description provided for @featuresZoneCairo.
  ///
  /// In zh, this message translates to:
  /// **'开罗'**
  String get featuresZoneCairo;

  /// No description provided for @featuresZoneJohannesburg.
  ///
  /// In zh, this message translates to:
  /// **'约翰内斯堡'**
  String get featuresZoneJohannesburg;

  /// No description provided for @featuresZoneLagos.
  ///
  /// In zh, this message translates to:
  /// **'拉各斯'**
  String get featuresZoneLagos;

  /// No description provided for @featuresZoneNewYork.
  ///
  /// In zh, this message translates to:
  /// **'纽约'**
  String get featuresZoneNewYork;

  /// No description provided for @featuresZoneToronto.
  ///
  /// In zh, this message translates to:
  /// **'多伦多'**
  String get featuresZoneToronto;

  /// No description provided for @featuresZoneChicago.
  ///
  /// In zh, this message translates to:
  /// **'芝加哥'**
  String get featuresZoneChicago;

  /// No description provided for @featuresZoneDenver.
  ///
  /// In zh, this message translates to:
  /// **'丹佛'**
  String get featuresZoneDenver;

  /// No description provided for @featuresZonePhoenix.
  ///
  /// In zh, this message translates to:
  /// **'凤凰城'**
  String get featuresZonePhoenix;

  /// No description provided for @featuresZoneLosAngeles.
  ///
  /// In zh, this message translates to:
  /// **'洛杉矶'**
  String get featuresZoneLosAngeles;

  /// No description provided for @featuresZoneVancouver.
  ///
  /// In zh, this message translates to:
  /// **'温哥华'**
  String get featuresZoneVancouver;

  /// No description provided for @featuresZoneAnchorage.
  ///
  /// In zh, this message translates to:
  /// **'安克雷奇'**
  String get featuresZoneAnchorage;

  /// No description provided for @featuresZoneMexicoCity.
  ///
  /// In zh, this message translates to:
  /// **'墨西哥城'**
  String get featuresZoneMexicoCity;

  /// No description provided for @featuresZoneBogota.
  ///
  /// In zh, this message translates to:
  /// **'波哥大'**
  String get featuresZoneBogota;

  /// No description provided for @featuresZoneLima.
  ///
  /// In zh, this message translates to:
  /// **'利马'**
  String get featuresZoneLima;

  /// No description provided for @featuresZoneSantiago.
  ///
  /// In zh, this message translates to:
  /// **'圣地亚哥'**
  String get featuresZoneSantiago;

  /// No description provided for @featuresZoneSaoPaulo.
  ///
  /// In zh, this message translates to:
  /// **'圣保罗'**
  String get featuresZoneSaoPaulo;

  /// No description provided for @featuresZoneBuenosAires.
  ///
  /// In zh, this message translates to:
  /// **'布宜诺斯艾利斯'**
  String get featuresZoneBuenosAires;

  /// No description provided for @featuresZoneHonolulu.
  ///
  /// In zh, this message translates to:
  /// **'檀香山'**
  String get featuresZoneHonolulu;

  /// No description provided for @featuresZoneAuckland.
  ///
  /// In zh, this message translates to:
  /// **'奥克兰'**
  String get featuresZoneAuckland;

  /// No description provided for @featuresZoneSydney.
  ///
  /// In zh, this message translates to:
  /// **'悉尼'**
  String get featuresZoneSydney;

  /// No description provided for @featuresZoneMelbourne.
  ///
  /// In zh, this message translates to:
  /// **'墨尔本'**
  String get featuresZoneMelbourne;

  /// No description provided for @featuresZoneBrisbane.
  ///
  /// In zh, this message translates to:
  /// **'布里斯班'**
  String get featuresZoneBrisbane;

  /// No description provided for @featuresZonePerth.
  ///
  /// In zh, this message translates to:
  /// **'珀斯'**
  String get featuresZonePerth;

  /// No description provided for @featuresScheduleCreated.
  ///
  /// In zh, this message translates to:
  /// **'已创建'**
  String get featuresScheduleCreated;

  /// No description provided for @featuresSchedulesReadFailed.
  ///
  /// In zh, this message translates to:
  /// **'没能读取自动化任务'**
  String get featuresSchedulesReadFailed;

  /// No description provided for @featuresSchedulesEmpty.
  ///
  /// In zh, this message translates to:
  /// **'还没有自动化任务'**
  String get featuresSchedulesEmpty;

  /// No description provided for @featuresSchedulesEmptyHint.
  ///
  /// In zh, this message translates to:
  /// **'到点自动发进对话，替你跑一遍'**
  String get featuresSchedulesEmptyHint;

  /// No description provided for @featuresScheduleNewTask.
  ///
  /// In zh, this message translates to:
  /// **'新建任务'**
  String get featuresScheduleNewTask;

  /// No description provided for @featuresSchedulesNoMatch.
  ///
  /// In zh, this message translates to:
  /// **'没有匹配的任务'**
  String get featuresSchedulesNoMatch;

  /// No description provided for @featuresSchedulesNoActive.
  ///
  /// In zh, this message translates to:
  /// **'没有开启中的任务'**
  String get featuresSchedulesNoActive;

  /// No description provided for @featuresSchedulesNoEnded.
  ///
  /// In zh, this message translates to:
  /// **'没有已结束的任务'**
  String get featuresSchedulesNoEnded;

  /// No description provided for @featuresSchedules.
  ///
  /// In zh, this message translates to:
  /// **'自动化任务'**
  String get featuresSchedules;

  /// No description provided for @featuresSchedulesSubtitle.
  ///
  /// In zh, this message translates to:
  /// **'到点自动发进原来的对话'**
  String get featuresSchedulesSubtitle;

  /// No description provided for @featuresSchedulesSearch.
  ///
  /// In zh, this message translates to:
  /// **'搜索任务'**
  String get featuresSchedulesSearch;

  /// No description provided for @featuresSchedulesAllCount.
  ///
  /// In zh, this message translates to:
  /// **'全部 {count}'**
  String featuresSchedulesAllCount(int count);

  /// No description provided for @featuresScheduleUntitled.
  ///
  /// In zh, this message translates to:
  /// **'未命名任务'**
  String get featuresScheduleUntitled;

  /// No description provided for @featuresScheduleSent.
  ///
  /// In zh, this message translates to:
  /// **'已发进对话'**
  String get featuresScheduleSent;

  /// No description provided for @featuresView.
  ///
  /// In zh, this message translates to:
  /// **'查看'**
  String get featuresView;

  /// No description provided for @featuresSendFailed.
  ///
  /// In zh, this message translates to:
  /// **'没能发送'**
  String get featuresSendFailed;

  /// No description provided for @featuresScheduleDeleteTitle.
  ///
  /// In zh, this message translates to:
  /// **'删除这个任务？'**
  String get featuresScheduleDeleteTitle;

  /// No description provided for @featuresScheduleDeleteHint.
  ///
  /// In zh, this message translates to:
  /// **'会停止之后的运行，并删掉它的运行记录。原来的对话不受影响。'**
  String get featuresScheduleDeleteHint;

  /// No description provided for @featuresScheduleDeleted.
  ///
  /// In zh, this message translates to:
  /// **'任务已删除'**
  String get featuresScheduleDeleted;

  /// No description provided for @featuresScheduleActive.
  ///
  /// In zh, this message translates to:
  /// **'已开启'**
  String get featuresScheduleActive;

  /// No description provided for @featuresScheduleRun.
  ///
  /// In zh, this message translates to:
  /// **'运行'**
  String get featuresScheduleRun;

  /// No description provided for @featuresScheduleNextRun.
  ///
  /// In zh, this message translates to:
  /// **'下次'**
  String get featuresScheduleNextRun;

  /// No description provided for @featuresScheduleLastRun.
  ///
  /// In zh, this message translates to:
  /// **'上次'**
  String get featuresScheduleLastRun;

  /// No description provided for @featuresScheduleRule.
  ///
  /// In zh, this message translates to:
  /// **'规则'**
  String get featuresScheduleRule;

  /// No description provided for @featuresScheduleLinkedChat.
  ///
  /// In zh, this message translates to:
  /// **'关联对话'**
  String get featuresScheduleLinkedChat;

  /// No description provided for @featuresScheduleChatDeleted.
  ///
  /// In zh, this message translates to:
  /// **'对话已删除'**
  String get featuresScheduleChatDeleted;

  /// No description provided for @featuresScheduleEdit.
  ///
  /// In zh, this message translates to:
  /// **'编辑任务'**
  String get featuresScheduleEdit;

  /// No description provided for @featuresScheduleRunNow.
  ///
  /// In zh, this message translates to:
  /// **'立即运行'**
  String get featuresScheduleRunNow;

  /// No description provided for @featuresScheduleHistory.
  ///
  /// In zh, this message translates to:
  /// **'运行记录'**
  String get featuresScheduleHistory;

  /// No description provided for @featuresScheduleNeverRun.
  ///
  /// In zh, this message translates to:
  /// **'还没有运行过'**
  String get featuresScheduleNeverRun;

  /// No description provided for @featuresScheduleHistoryUnavailable.
  ///
  /// In zh, this message translates to:
  /// **'记录不可用'**
  String get featuresScheduleHistoryUnavailable;

  /// No description provided for @featuresScheduleHistoryReadFailed.
  ///
  /// In zh, this message translates to:
  /// **'没能读取运行记录'**
  String get featuresScheduleHistoryReadFailed;

  /// No description provided for @featuresScheduleDelete.
  ///
  /// In zh, this message translates to:
  /// **'删除任务'**
  String get featuresScheduleDelete;

  /// No description provided for @featuresExportSavedTo.
  ///
  /// In zh, this message translates to:
  /// **'已存到 {path}'**
  String featuresExportSavedTo(String path);

  /// No description provided for @featuresExportTitle.
  ///
  /// In zh, this message translates to:
  /// **'导出对话日志'**
  String get featuresExportTitle;

  /// No description provided for @featuresExportSubtitle.
  ///
  /// In zh, this message translates to:
  /// **'打包成一个 ZIP，用于反馈或备份'**
  String get featuresExportSubtitle;

  /// No description provided for @featuresExportUnavailable.
  ///
  /// In zh, this message translates to:
  /// **'这个连接导不了'**
  String get featuresExportUnavailable;

  /// No description provided for @featuresExportRemoteHint.
  ///
  /// In zh, this message translates to:
  /// **'经 DSH Remote 中转时拿不到日志，可以在电脑上的网页版导出'**
  String get featuresExportRemoteHint;

  /// No description provided for @featuresExportShareHint.
  ///
  /// In zh, this message translates to:
  /// **'附在问题反馈里，或发给自己'**
  String get featuresExportShareHint;

  /// No description provided for @featuresExportSaveDownloads.
  ///
  /// In zh, this message translates to:
  /// **'存到「下载」'**
  String get featuresExportSaveDownloads;

  /// No description provided for @featuresExportDownloadsHint.
  ///
  /// In zh, this message translates to:
  /// **'存进 下载/DSH-Go'**
  String get featuresExportDownloadsHint;

  /// No description provided for @featuresExportContents.
  ///
  /// In zh, this message translates to:
  /// **'含这个对话和子代理的全部记录与附件'**
  String get featuresExportContents;

  /// No description provided for @featuresSkillUseHere.
  ///
  /// In zh, this message translates to:
  /// **'在对话里用'**
  String get featuresSkillUseHere;

  /// No description provided for @featuresSkillUseNew.
  ///
  /// In zh, this message translates to:
  /// **'新对话里用'**
  String get featuresSkillUseNew;

  /// No description provided for @featuresSkillsCallHint.
  ///
  /// In zh, this message translates to:
  /// **'输入 /技能名 调用'**
  String get featuresSkillsCallHint;

  /// No description provided for @featuresSkillsReadFailed.
  ///
  /// In zh, this message translates to:
  /// **'没能读取技能'**
  String get featuresSkillsReadFailed;

  /// No description provided for @featuresSkillsEmpty.
  ///
  /// In zh, this message translates to:
  /// **'这个对话还没有技能'**
  String get featuresSkillsEmpty;

  /// No description provided for @featuresSkillsEmptyHint.
  ///
  /// In zh, this message translates to:
  /// **'放进 .dsh/skills 的技能会出现在这里'**
  String get featuresSkillsEmptyHint;

  /// No description provided for @featuresSkillsSourceHint.
  ///
  /// In zh, this message translates to:
  /// **'来自项目和 ~/.dsh 下的 skills 目录'**
  String get featuresSkillsSourceHint;

  /// No description provided for @featuresSkillUsage.
  ///
  /// In zh, this message translates to:
  /// **'适用：{usage}'**
  String featuresSkillUsage(String usage);

  /// No description provided for @featuresSkillManual.
  ///
  /// In zh, this message translates to:
  /// **'仅手动'**
  String get featuresSkillManual;

  /// No description provided for @featuresArtifactsSemantic.
  ///
  /// In zh, this message translates to:
  /// **'产出的文件，共 {count} 个，查看全部'**
  String featuresArtifactsSemantic(int count);

  /// No description provided for @featuresArtifactsTitle.
  ///
  /// In zh, this message translates to:
  /// **'产出的文件'**
  String get featuresArtifactsTitle;

  /// No description provided for @featuresArtifactsAllCount.
  ///
  /// In zh, this message translates to:
  /// **'全部 {count} 个'**
  String featuresArtifactsAllCount(int count);

  /// No description provided for @featuresArtifactsCount.
  ///
  /// In zh, this message translates to:
  /// **'{count} 个'**
  String featuresArtifactsCount(int count);

  /// No description provided for @featuresArtifactsNoFiles.
  ///
  /// In zh, this message translates to:
  /// **'还没有文件'**
  String get featuresArtifactsNoFiles;

  /// No description provided for @featuresArtifactsTotal.
  ///
  /// In zh, this message translates to:
  /// **'{count} 个文件 · 交付的和生成的'**
  String featuresArtifactsTotal(int count);

  /// No description provided for @featuresArtifactsEmpty.
  ///
  /// In zh, this message translates to:
  /// **'还没有产出文件'**
  String get featuresArtifactsEmpty;

  /// No description provided for @featuresArtifactsEmptyHint.
  ///
  /// In zh, this message translates to:
  /// **'AI 交付或生成的文件会出现在这里'**
  String get featuresArtifactsEmptyHint;

  /// No description provided for @featuresListSeparator.
  ///
  /// In zh, this message translates to:
  /// **'、'**
  String get featuresListSeparator;

  /// No description provided for @featuresErrorReason.
  ///
  /// In zh, this message translates to:
  /// **'{title}：{reason}'**
  String featuresErrorReason(String title, String reason);

  /// No description provided for @featuresYearDate.
  ///
  /// In zh, this message translates to:
  /// **'{year}年{date}'**
  String featuresYearDate(int year, String date);

  /// No description provided for @featuresDateWeekdayTime.
  ///
  /// In zh, this message translates to:
  /// **'{date} {week} {time}'**
  String featuresDateWeekdayTime(String date, String week, String time);

  /// No description provided for @featuresDateWeekday.
  ///
  /// In zh, this message translates to:
  /// **'{date} 周{day}'**
  String featuresDateWeekday(String date, String day);

  /// No description provided for @featuresOnceDescription.
  ///
  /// In zh, this message translates to:
  /// **'{rule} · {date} {time}'**
  String featuresOnceDescription(String rule, String date, String time);

  /// No description provided for @featuresCronMonthSuffix.
  ///
  /// In zh, this message translates to:
  /// **'（{months}）'**
  String featuresCronMonthSuffix(String months);

  /// No description provided for @featuresRuleIntervalSeconds.
  ///
  /// In zh, this message translates to:
  /// **'每 {count} 秒'**
  String featuresRuleIntervalSeconds(int count);

  /// No description provided for @featuresRuleIntervalMinutes.
  ///
  /// In zh, this message translates to:
  /// **'每 {count} 分钟'**
  String featuresRuleIntervalMinutes(int count);

  /// No description provided for @featuresRuleIntervalHours.
  ///
  /// In zh, this message translates to:
  /// **'每 {count} 小时'**
  String featuresRuleIntervalHours(int count);

  /// No description provided for @featuresSchedulesActiveCount.
  ///
  /// In zh, this message translates to:
  /// **'已开启 {count}'**
  String featuresSchedulesActiveCount(int count);

  /// No description provided for @featuresSchedulesEndedCount.
  ///
  /// In zh, this message translates to:
  /// **'已结束 {count}'**
  String featuresSchedulesEndedCount(int count);

  /// No description provided for @featuresScheduleRetention.
  ///
  /// In zh, this message translates to:
  /// **'只保留最近 {days} 天、最多 {count} 条'**
  String featuresScheduleRetention(int days, int count);

  /// No description provided for @featuresScheduleRetentionUnknown.
  ///
  /// In zh, this message translates to:
  /// **'只保留最近 {days} 天、最多 — 条'**
  String featuresScheduleRetentionUnknown(int days);

  /// No description provided for @featuresArtifactsDeliveredTurn.
  ///
  /// In zh, this message translates to:
  /// **'第 {turn} 轮 · 交付'**
  String featuresArtifactsDeliveredTurn(int turn);

  /// No description provided for @featuresArtifactsGeneratedTurn.
  ///
  /// In zh, this message translates to:
  /// **'第 {turn} 轮 · 生成'**
  String featuresArtifactsGeneratedTurn(int turn);

  /// No description provided for @featuresPresetCreateRequest.
  ///
  /// In zh, this message translates to:
  /// **'新建 Agent 预设「{name}」（{id}）：在工作区写下这两个文件（内容原样），再用 plugin_manager 的 install_bundle 安装 `{directory}` 目录。只做这些。\n\n'**
  String featuresPresetCreateRequest(String name, String id, String directory);

  /// No description provided for @featuresPresetUpdateRequest.
  ///
  /// In zh, this message translates to:
  /// **'更新 Agent 预设「{name}」（{id}）：在工作区写下这两个文件（内容原样），用 plugin_manager 先移除组合包 `{replacing}`，再用 install_bundle 安装 `{directory}` 目录。只做这些。\n\n'**
  String featuresPresetUpdateRequest(String name, String id, String replacing, String directory);

  /// No description provided for @featuresZoneThisPhone.
  ///
  /// In zh, this message translates to:
  /// **'{city} · 本机'**
  String featuresZoneThisPhone(String city);

  /// No description provided for @featuresPermissionResetHint.
  ///
  /// In zh, this message translates to:
  /// **'新对话的默认权限已失效'**
  String get featuresPermissionResetHint;

  /// No description provided for @featuresPermissionResetDefault.
  ///
  /// In zh, this message translates to:
  /// **'恢复默认'**
  String get featuresPermissionResetDefault;

  /// No description provided for @fileImageName.
  ///
  /// In zh, this message translates to:
  /// **'图片'**
  String get fileImageName;

  /// No description provided for @fileSharedText.
  ///
  /// In zh, this message translates to:
  /// **'分享的文字.txt'**
  String get fileSharedText;

  /// No description provided for @fileChatFallback.
  ///
  /// In zh, this message translates to:
  /// **'对话'**
  String get fileChatFallback;

  /// No description provided for @hubSessionDetails.
  ///
  /// In zh, this message translates to:
  /// **'对话详情'**
  String get hubSessionDetails;

  /// No description provided for @hubTerminal.
  ///
  /// In zh, this message translates to:
  /// **'终端'**
  String get hubTerminal;

  /// No description provided for @hubSessionNoTurns.
  ///
  /// In zh, this message translates to:
  /// **'还没有完整的一轮'**
  String get hubSessionNoTurns;

  /// No description provided for @hubSessionElapsed.
  ///
  /// In zh, this message translates to:
  /// **'用时'**
  String get hubSessionElapsed;

  /// No description provided for @hubSessionSteps.
  ///
  /// In zh, this message translates to:
  /// **'步骤'**
  String get hubSessionSteps;

  /// No description provided for @hubSessionChangedFiles.
  ///
  /// In zh, this message translates to:
  /// **'改动文件'**
  String get hubSessionChangedFiles;

  /// No description provided for @hubSessionTrajectoryHint.
  ///
  /// In zh, this message translates to:
  /// **'每一轮的步骤和用时会排在这里'**
  String get hubSessionTrajectoryHint;

  /// No description provided for @hubSessionLoadEarlier.
  ///
  /// In zh, this message translates to:
  /// **'加载更早的轮次'**
  String get hubSessionLoadEarlier;

  /// No description provided for @hubSessionError.
  ///
  /// In zh, this message translates to:
  /// **'出错'**
  String get hubSessionError;

  /// No description provided for @hubSessionInterrupted.
  ///
  /// In zh, this message translates to:
  /// **'被中断'**
  String get hubSessionInterrupted;

  /// No description provided for @hubSessionOutputLimit.
  ///
  /// In zh, this message translates to:
  /// **'达到输出上限'**
  String get hubSessionOutputLimit;

  /// No description provided for @hubSessionNoChanges.
  ///
  /// In zh, this message translates to:
  /// **'还没有改过文件'**
  String get hubSessionNoChanges;

  /// No description provided for @hubSessionShellChangesHint.
  ///
  /// In zh, this message translates to:
  /// **'用 shell 命令改的文件不在这里'**
  String get hubSessionShellChangesHint;

  /// No description provided for @hubSessionChanges.
  ///
  /// In zh, this message translates to:
  /// **'对话改动'**
  String get hubSessionChanges;

  /// No description provided for @hubSessionChangesNote.
  ///
  /// In zh, this message translates to:
  /// **'只统计已加载的记录里，用写入和编辑工具做的改动'**
  String get hubSessionChangesNote;

  /// No description provided for @hubSessionNoGoal.
  ///
  /// In zh, this message translates to:
  /// **'还没有目标或待办'**
  String get hubSessionNoGoal;

  /// No description provided for @hubSessionGoalHint.
  ///
  /// In zh, this message translates to:
  /// **'复杂任务里 AI 会列出待办，进度在这里看'**
  String get hubSessionGoalHint;

  /// No description provided for @hubSessionGoal.
  ///
  /// In zh, this message translates to:
  /// **'目标'**
  String get hubSessionGoal;

  /// No description provided for @hubSessionPlanMode.
  ///
  /// In zh, this message translates to:
  /// **'计划模式'**
  String get hubSessionPlanMode;

  /// No description provided for @hubSessionPlanSwitching.
  ///
  /// In zh, this message translates to:
  /// **'正在切换计划模式'**
  String get hubSessionPlanSwitching;

  /// No description provided for @hubSessionPlanHint.
  ///
  /// In zh, this message translates to:
  /// **'AI 先出方案，不改文件'**
  String get hubSessionPlanHint;

  /// No description provided for @hubSessionTodos.
  ///
  /// In zh, this message translates to:
  /// **'待办'**
  String get hubSessionTodos;

  /// No description provided for @hubSessionNotStarted.
  ///
  /// In zh, this message translates to:
  /// **'未开始'**
  String get hubSessionNotStarted;

  /// No description provided for @hubSessionTurnUsage.
  ///
  /// In zh, this message translates to:
  /// **'每轮用量'**
  String get hubSessionTurnUsage;

  /// No description provided for @hubSessionNoSubagents.
  ///
  /// In zh, this message translates to:
  /// **'没有派出子代理'**
  String get hubSessionNoSubagents;

  /// No description provided for @hubSessionDelegations.
  ///
  /// In zh, this message translates to:
  /// **'派活记录'**
  String get hubSessionDelegations;

  /// No description provided for @hubTabTrajectory.
  ///
  /// In zh, this message translates to:
  /// **'轨迹'**
  String get hubTabTrajectory;

  /// No description provided for @hubTabChanges.
  ///
  /// In zh, this message translates to:
  /// **'改动'**
  String get hubTabChanges;

  /// No description provided for @hubTabFiles.
  ///
  /// In zh, this message translates to:
  /// **'文件'**
  String get hubTabFiles;

  /// No description provided for @hubTabProgress.
  ///
  /// In zh, this message translates to:
  /// **'进度'**
  String get hubTabProgress;

  /// No description provided for @hubTabContext.
  ///
  /// In zh, this message translates to:
  /// **'上下文'**
  String get hubTabContext;

  /// No description provided for @hubTabSubagents.
  ///
  /// In zh, this message translates to:
  /// **'子代理'**
  String get hubTabSubagents;

  /// No description provided for @hubPlugins.
  ///
  /// In zh, this message translates to:
  /// **'插件'**
  String get hubPlugins;

  /// No description provided for @hubSettingsFullAccessTitle.
  ///
  /// In zh, this message translates to:
  /// **'开启完全权限？'**
  String get hubSettingsFullAccessTitle;

  /// No description provided for @hubSettingsFullAccessBody.
  ///
  /// In zh, this message translates to:
  /// **'AI 执行命令、改动文件前不再问你。'**
  String get hubSettingsFullAccessBody;

  /// No description provided for @hubSettingsStorageTitle.
  ///
  /// In zh, this message translates to:
  /// **'让 AI 访问手机文件？'**
  String get hubSettingsStorageTitle;

  /// No description provided for @hubSettingsStorageAllow.
  ///
  /// In zh, this message translates to:
  /// **'允许读写'**
  String get hubSettingsStorageAllow;

  /// No description provided for @hubSettingsStorageDenied.
  ///
  /// In zh, this message translates to:
  /// **'没有拿到存储权限。到系统设置里给 DSH Go 开启「所有文件访问」后再试'**
  String get hubSettingsStorageDenied;

  /// No description provided for @hubSettingsRestartRequired.
  ///
  /// In zh, this message translates to:
  /// **'重启引擎后生效'**
  String get hubSettingsRestartRequired;

  /// No description provided for @hubSettingsRestartNow.
  ///
  /// In zh, this message translates to:
  /// **'立即重启'**
  String get hubSettingsRestartNow;

  /// No description provided for @hubSettingsInterface.
  ///
  /// In zh, this message translates to:
  /// **'界面'**
  String get hubSettingsInterface;

  /// No description provided for @hubSettingsChat.
  ///
  /// In zh, this message translates to:
  /// **'对话'**
  String get hubSettingsChat;

  /// No description provided for @hubSettingsAutoCommands.
  ///
  /// In zh, this message translates to:
  /// **'自动执行命令'**
  String get hubSettingsAutoCommands;

  /// No description provided for @hubSettingsPhoneFiles.
  ///
  /// In zh, this message translates to:
  /// **'访问手机文件'**
  String get hubSettingsPhoneFiles;

  /// No description provided for @hubSettingsPhoneFilesHint.
  ///
  /// In zh, this message translates to:
  /// **'AI 可读写手机存储'**
  String get hubSettingsPhoneFilesHint;

  /// No description provided for @hubSettingsVisualReplies.
  ///
  /// In zh, this message translates to:
  /// **'可视化回复'**
  String get hubSettingsVisualReplies;

  /// No description provided for @hubSettingsVisualRepliesHint.
  ///
  /// In zh, this message translates to:
  /// **'图表、对比卡和可点的选项'**
  String get hubSettingsVisualRepliesHint;

  /// No description provided for @hubSettingsPhoneControl.
  ///
  /// In zh, this message translates to:
  /// **'手机操控'**
  String get hubSettingsPhoneControl;

  /// No description provided for @hubSettingsPhoneControlHint.
  ///
  /// In zh, this message translates to:
  /// **'看屏幕、帮你点按'**
  String get hubSettingsPhoneControlHint;

  /// No description provided for @hubSettingsPreferences.
  ///
  /// In zh, this message translates to:
  /// **'个人偏好'**
  String get hubSettingsPreferences;

  /// No description provided for @hubSettingsAppearance.
  ///
  /// In zh, this message translates to:
  /// **'外观'**
  String get hubSettingsAppearance;

  /// No description provided for @hubSettingsChatTextSize.
  ///
  /// In zh, this message translates to:
  /// **'对话字号'**
  String get hubSettingsChatTextSize;

  /// No description provided for @hubSettingsCollapseSteps.
  ///
  /// In zh, this message translates to:
  /// **'完成后收起过程'**
  String get hubSettingsCollapseSteps;

  /// No description provided for @hubSettingsCollapseStepsHint.
  ///
  /// In zh, this message translates to:
  /// **'思考与工具调用收成一行'**
  String get hubSettingsCollapseStepsHint;

  /// No description provided for @hubSettingsWebPhoneLayout.
  ///
  /// In zh, this message translates to:
  /// **'网页版手机布局'**
  String get hubSettingsWebPhoneLayout;

  /// No description provided for @hubSettingsWebPhoneLayoutHint.
  ///
  /// In zh, this message translates to:
  /// **'为手机屏幕重排网页版'**
  String get hubSettingsWebPhoneLayoutHint;

  /// No description provided for @hubSettingsEngineExtensions.
  ///
  /// In zh, this message translates to:
  /// **'引擎与扩展'**
  String get hubSettingsEngineExtensions;

  /// No description provided for @hubSettingsEngine.
  ///
  /// In zh, this message translates to:
  /// **'本机引擎'**
  String get hubSettingsEngine;

  /// No description provided for @hubSettingsProviders.
  ///
  /// In zh, this message translates to:
  /// **'模型'**
  String get hubSettingsProviders;

  /// No description provided for @hubSettingsEngineSettings.
  ///
  /// In zh, this message translates to:
  /// **'引擎参数'**
  String get hubSettingsEngineSettings;

  /// No description provided for @hubSettingsShareConfig.
  ///
  /// In zh, this message translates to:
  /// **'分享配置'**
  String get hubSettingsShareConfig;

  /// No description provided for @hubSettingsAllFeatures.
  ///
  /// In zh, this message translates to:
  /// **'全部功能'**
  String get hubSettingsAllFeatures;

  /// No description provided for @hubSettingsAbout.
  ///
  /// In zh, this message translates to:
  /// **'关于'**
  String get hubSettingsAbout;

  /// No description provided for @hubSettingsCommunity.
  ///
  /// In zh, this message translates to:
  /// **'社区'**
  String get hubSettingsCommunity;

  /// No description provided for @hubSettingsLicenses.
  ///
  /// In zh, this message translates to:
  /// **'开源许可'**
  String get hubSettingsLicenses;

  /// No description provided for @hubSettingsAccount.
  ///
  /// In zh, this message translates to:
  /// **'DeepSeek 账号'**
  String get hubSettingsAccount;

  /// No description provided for @hubSettingsSigningIn.
  ///
  /// In zh, this message translates to:
  /// **'正在登录…'**
  String get hubSettingsSigningIn;

  /// No description provided for @hubSettingsInvalidKey.
  ///
  /// In zh, this message translates to:
  /// **'Key 无效，查不到余额'**
  String get hubSettingsInvalidKey;

  /// No description provided for @hubSettingsNoApiKey.
  ///
  /// In zh, this message translates to:
  /// **'未设置 API Key'**
  String get hubSettingsNoApiKey;

  /// No description provided for @hubSettingsApiKeyHint.
  ///
  /// In zh, this message translates to:
  /// **'填写 Key 后即可对话'**
  String get hubSettingsApiKeyHint;

  /// No description provided for @hubSettingsSignInAccount.
  ///
  /// In zh, this message translates to:
  /// **'登录 DeepSeek 账号'**
  String get hubSettingsSignInAccount;

  /// No description provided for @hubSettingsOrApiKey.
  ///
  /// In zh, this message translates to:
  /// **'或填写 API Key'**
  String get hubSettingsOrApiKey;

  /// No description provided for @hubPluginShare.
  ///
  /// In zh, this message translates to:
  /// **'分享插件'**
  String get hubPluginShare;

  /// No description provided for @hubPluginDetails.
  ///
  /// In zh, this message translates to:
  /// **'插件详情'**
  String get hubPluginDetails;

  /// No description provided for @hubPluginFeatured.
  ///
  /// In zh, this message translates to:
  /// **'dshfind 推荐'**
  String get hubPluginFeatured;

  /// No description provided for @hubPluginWebOnly.
  ///
  /// In zh, this message translates to:
  /// **'仅网页版'**
  String get hubPluginWebOnly;

  /// No description provided for @hubPluginStars.
  ///
  /// In zh, this message translates to:
  /// **'星标'**
  String get hubPluginStars;

  /// No description provided for @hubPluginSource.
  ///
  /// In zh, this message translates to:
  /// **'来源'**
  String get hubPluginSource;

  /// No description provided for @hubPluginInstalledVersion.
  ///
  /// In zh, this message translates to:
  /// **'已装版本'**
  String get hubPluginInstalledVersion;

  /// No description provided for @hubPluginRequiresDsh.
  ///
  /// In zh, this message translates to:
  /// **'需要 DSH'**
  String get hubPluginRequiresDsh;

  /// No description provided for @hubPluginPackageName.
  ///
  /// In zh, this message translates to:
  /// **'包名'**
  String get hubPluginPackageName;

  /// No description provided for @hubPluginHomepage.
  ///
  /// In zh, this message translates to:
  /// **'主页'**
  String get hubPluginHomepage;

  /// No description provided for @hubPluginRepository.
  ///
  /// In zh, this message translates to:
  /// **'代码仓库'**
  String get hubPluginRepository;

  /// No description provided for @hubPluginManageTitle.
  ///
  /// In zh, this message translates to:
  /// **'管理插件'**
  String get hubPluginManageTitle;

  /// No description provided for @hubPluginManage.
  ///
  /// In zh, this message translates to:
  /// **'管理'**
  String get hubPluginManage;

  /// No description provided for @hubPluginSafeModeInstall.
  ///
  /// In zh, this message translates to:
  /// **'安全模式下不能安装'**
  String get hubPluginSafeModeInstall;

  /// No description provided for @hubPluginInstallCommand.
  ///
  /// In zh, this message translates to:
  /// **'获取安装命令'**
  String get hubPluginInstallCommand;

  /// No description provided for @hubPluginInstallComputer.
  ///
  /// In zh, this message translates to:
  /// **'在电脑上安装'**
  String get hubPluginInstallComputer;

  /// No description provided for @hubPluginInstalling.
  ///
  /// In zh, this message translates to:
  /// **'安装中…'**
  String get hubPluginInstalling;

  /// No description provided for @hubPluginAllowBuilds.
  ///
  /// In zh, this message translates to:
  /// **'允许构建脚本并重试'**
  String get hubPluginAllowBuilds;

  /// No description provided for @hubPluginRetryInstall.
  ///
  /// In zh, this message translates to:
  /// **'重试安装'**
  String get hubPluginRetryInstall;

  /// No description provided for @hubPluginOfficial.
  ///
  /// In zh, this message translates to:
  /// **'DSH 官方'**
  String get hubPluginOfficial;

  /// No description provided for @hubPluginNotLoaded.
  ///
  /// In zh, this message translates to:
  /// **'没有正常加载'**
  String get hubPluginNotLoaded;

  /// No description provided for @hubPluginComponents.
  ///
  /// In zh, this message translates to:
  /// **'组件'**
  String get hubPluginComponents;

  /// No description provided for @hubPluginSafeModeRemove.
  ///
  /// In zh, this message translates to:
  /// **'安全模式下不能卸载'**
  String get hubPluginSafeModeRemove;

  /// No description provided for @hubPluginRemoveCommand.
  ///
  /// In zh, this message translates to:
  /// **'获取卸载命令'**
  String get hubPluginRemoveCommand;

  /// No description provided for @hubPluginRemoveComputer.
  ///
  /// In zh, this message translates to:
  /// **'在电脑上卸载'**
  String get hubPluginRemoveComputer;

  /// No description provided for @hubPluginUninstall.
  ///
  /// In zh, this message translates to:
  /// **'卸载'**
  String get hubPluginUninstall;

  /// No description provided for @hubSessionTurns.
  ///
  /// In zh, this message translates to:
  /// **'共 {count} 轮'**
  String hubSessionTurns(int count);

  /// No description provided for @hubSessionTurnsRunning.
  ///
  /// In zh, this message translates to:
  /// **'共 {count} 轮 · 进行中'**
  String hubSessionTurnsRunning(int count);

  /// No description provided for @hubSessionStepCount.
  ///
  /// In zh, this message translates to:
  /// **'{count} 步'**
  String hubSessionStepCount(int count);

  /// No description provided for @hubSessionWaitTime.
  ///
  /// In zh, this message translates to:
  /// **'等你 {duration}'**
  String hubSessionWaitTime(String duration);

  /// No description provided for @hubSessionTurn.
  ///
  /// In zh, this message translates to:
  /// **'第 {turn} 轮'**
  String hubSessionTurn(int turn);

  /// No description provided for @hubSessionFileCount.
  ///
  /// In zh, this message translates to:
  /// **'改动了 {count} 个文件'**
  String hubSessionFileCount(int count);

  /// No description provided for @hubSessionEditCount.
  ///
  /// In zh, this message translates to:
  /// **'改了 {count} 次'**
  String hubSessionEditCount(int count);

  /// No description provided for @hubSessionTurnOf.
  ///
  /// In zh, this message translates to:
  /// **'第 {turn} / {total} 轮'**
  String hubSessionTurnOf(int turn, int total);

  /// No description provided for @hubSessionCacheHit.
  ///
  /// In zh, this message translates to:
  /// **'命中 {percent}'**
  String hubSessionCacheHit(String percent);

  /// No description provided for @hubSessionBlocked.
  ///
  /// In zh, this message translates to:
  /// **'受阻'**
  String get hubSessionBlocked;

  /// No description provided for @hubSessionBlockedReason.
  ///
  /// In zh, this message translates to:
  /// **'受阻：{reason}'**
  String hubSessionBlockedReason(String reason);

  /// No description provided for @hubSessionTodoSemantics.
  ///
  /// In zh, this message translates to:
  /// **'{content},{status}'**
  String hubSessionTodoSemantics(String content, String status);

  /// No description provided for @hubSettingsStorageBody.
  ///
  /// In zh, this message translates to:
  /// **'AI 能读取和修改相册、下载、文档等手机文件，引擎会重启一次。'**
  String get hubSettingsStorageBody;

  /// No description provided for @hubSettingsBalance.
  ///
  /// In zh, this message translates to:
  /// **'余额 {amount}'**
  String hubSettingsBalance(String amount);

  /// No description provided for @hubSettingsBalanceLow.
  ///
  /// In zh, this message translates to:
  /// **'余额 {amount} · 余额不足'**
  String hubSettingsBalanceLow(String amount);

  /// No description provided for @hubSettingsAccountSemantics.
  ///
  /// In zh, this message translates to:
  /// **'账号：{title}，{subtitle}'**
  String hubSettingsAccountSemantics(String title, String subtitle);

  /// No description provided for @hubSettingsHostSemantics.
  ///
  /// In zh, this message translates to:
  /// **'远程主机：{name}，{status}'**
  String hubSettingsHostSemantics(String name, String status);

  /// No description provided for @hubSettingsApiKey.
  ///
  /// In zh, this message translates to:
  /// **'DeepSeek API Key'**
  String get hubSettingsApiKey;

  /// No description provided for @hubPluginBrowserFailed.
  ///
  /// In zh, this message translates to:
  /// **'没能打开浏览器，请手动访问 {address}'**
  String hubPluginBrowserFailed(String address);

  /// No description provided for @hubPluginYearMonth.
  ///
  /// In zh, this message translates to:
  /// **'{year}年{month}月'**
  String hubPluginYearMonth(int year, String month);

  /// No description provided for @hubPluginUpdateTo.
  ///
  /// In zh, this message translates to:
  /// **'更新到 {version}'**
  String hubPluginUpdateTo(String version);

  /// No description provided for @hubPluginInstallOn.
  ///
  /// In zh, this message translates to:
  /// **'安装到{host}'**
  String hubPluginInstallOn(String host);

  /// No description provided for @hubPluginComponentCount.
  ///
  /// In zh, this message translates to:
  /// **'{count} 个'**
  String hubPluginComponentCount(int count);

  /// No description provided for @hubPluginComponentSeparator.
  ///
  /// In zh, this message translates to:
  /// **'、'**
  String get hubPluginComponentSeparator;

  /// No description provided for @hubGroupAi.
  ///
  /// In zh, this message translates to:
  /// **'AI'**
  String get hubGroupAi;

  /// No description provided for @hubGroupCapabilities.
  ///
  /// In zh, this message translates to:
  /// **'能力'**
  String get hubGroupCapabilities;

  /// No description provided for @hubGroupGeneral.
  ///
  /// In zh, this message translates to:
  /// **'通用'**
  String get hubGroupGeneral;

  /// No description provided for @hubGroupHosts.
  ///
  /// In zh, this message translates to:
  /// **'主机'**
  String get hubGroupHosts;

  /// No description provided for @hubGroupHelp.
  ///
  /// In zh, this message translates to:
  /// **'帮助与关于'**
  String get hubGroupHelp;

  /// No description provided for @hubPersonalization.
  ///
  /// In zh, this message translates to:
  /// **'个性化'**
  String get hubPersonalization;

  /// No description provided for @hubPersonalizationAboutYou.
  ///
  /// In zh, this message translates to:
  /// **'关于你'**
  String get hubPersonalizationAboutYou;

  /// No description provided for @hubPersonalizationReplies.
  ///
  /// In zh, this message translates to:
  /// **'回答'**
  String get hubPersonalizationReplies;

  /// No description provided for @hubPersonalizationWorkStyle.
  ///
  /// In zh, this message translates to:
  /// **'工作方式'**
  String get hubPersonalizationWorkStyle;

  /// No description provided for @hubPrivacy.
  ///
  /// In zh, this message translates to:
  /// **'隐私与分享'**
  String get hubPrivacy;

  /// No description provided for @hubPrivacySharing.
  ///
  /// In zh, this message translates to:
  /// **'分享'**
  String get hubPrivacySharing;

  /// No description provided for @hubInterfaceHome.
  ///
  /// In zh, this message translates to:
  /// **'首页'**
  String get hubInterfaceHome;

  /// No description provided for @hubInterfaceWebHint.
  ///
  /// In zh, this message translates to:
  /// **'DSH 官方网页版'**
  String get hubInterfaceWebHint;

  /// No description provided for @hubInterfaceOpenWeb.
  ///
  /// In zh, this message translates to:
  /// **'打开网页版'**
  String get hubInterfaceOpenWeb;

  /// No description provided for @hubInterfacePhoneLayout.
  ///
  /// In zh, this message translates to:
  /// **'手机布局'**
  String get hubInterfacePhoneLayout;

  /// No description provided for @hubTableTint.
  ///
  /// In zh, this message translates to:
  /// **'表格底色'**
  String get hubTableTint;

  /// No description provided for @hubTableTintFollow.
  ///
  /// In zh, this message translates to:
  /// **'跟随主题'**
  String get hubTableTintFollow;

  /// No description provided for @hubTableTintFill.
  ///
  /// In zh, this message translates to:
  /// **'淡底整表'**
  String get hubTableTintFill;

  /// No description provided for @hubTableTintNone.
  ///
  /// In zh, this message translates to:
  /// **'无底色'**
  String get hubTableTintNone;

  /// No description provided for @hubTableTintFillHint.
  ///
  /// In zh, this message translates to:
  /// **'隔行淡一档，长表格更好扫读'**
  String get hubTableTintFillHint;

  /// No description provided for @hubTableTintFollowHint.
  ///
  /// In zh, this message translates to:
  /// **'表头浅底，表身跟随正文'**
  String get hubTableTintFollowHint;

  /// No description provided for @hubTableTintNoneHint.
  ///
  /// In zh, this message translates to:
  /// **'只剩网格线，最轻'**
  String get hubTableTintNoneHint;

  /// No description provided for @hubAbout.
  ///
  /// In zh, this message translates to:
  /// **'关于 DSH Go'**
  String get hubAbout;

  /// No description provided for @hubAboutAuthor.
  ///
  /// In zh, this message translates to:
  /// **'DSH Go 原作者'**
  String get hubAboutAuthor;

  /// No description provided for @hubAboutBilibili.
  ///
  /// In zh, this message translates to:
  /// **'B站主页'**
  String get hubAboutBilibili;

  /// No description provided for @hubAboutX.
  ///
  /// In zh, this message translates to:
  /// **'X 主页'**
  String get hubAboutX;

  /// No description provided for @hubAboutGithub.
  ///
  /// In zh, this message translates to:
  /// **'GitHub 主页'**
  String get hubAboutGithub;

  /// No description provided for @hubAboutNewVersion.
  ///
  /// In zh, this message translates to:
  /// **'有新版本'**
  String get hubAboutNewVersion;

  /// No description provided for @hubValueSet.
  ///
  /// In zh, this message translates to:
  /// **'已设置'**
  String get hubValueSet;

  /// No description provided for @hubValueOff.
  ///
  /// In zh, this message translates to:
  /// **'未开启'**
  String get hubValueOff;

  /// No description provided for @hubValueOneStep.
  ///
  /// In zh, this message translates to:
  /// **'还差一步'**
  String get hubValueOneStep;

  /// No description provided for @hubValueAllowed.
  ///
  /// In zh, this message translates to:
  /// **'已允许'**
  String get hubValueAllowed;

  /// No description provided for @hubValueNeedsSetup.
  ///
  /// In zh, this message translates to:
  /// **'需设置'**
  String get hubValueNeedsSetup;

  /// No description provided for @hubValueHosts.
  ///
  /// In zh, this message translates to:
  /// **'{count} 台'**
  String hubValueHosts(int count);

  /// No description provided for @hubValueNoHosts.
  ///
  /// In zh, this message translates to:
  /// **'未添加'**
  String get hubValueNoHosts;

  /// No description provided for @hubValuePlugins.
  ///
  /// In zh, this message translates to:
  /// **'{count} 个'**
  String hubValuePlugins(int count);

  /// No description provided for @hubEngineStartup.
  ///
  /// In zh, this message translates to:
  /// **'启动'**
  String get hubEngineStartup;

  /// No description provided for @hubThemeLightDark.
  ///
  /// In zh, this message translates to:
  /// **'明暗'**
  String get hubThemeLightDark;

  /// No description provided for @hubPermissionPhone.
  ///
  /// In zh, this message translates to:
  /// **'手机'**
  String get hubPermissionPhone;

  /// No description provided for @hubPermissionPhoneConfirm.
  ///
  /// In zh, this message translates to:
  /// **'手机操控确认'**
  String get hubPermissionPhoneConfirm;

  /// No description provided for @hubHardwareEnterSends.
  ///
  /// In zh, this message translates to:
  /// **'外接键盘按 Enter 发送'**
  String get hubHardwareEnterSends;

  /// No description provided for @hubHardwareEnterSendsHint.
  ///
  /// In zh, this message translates to:
  /// **'开启后，Shift+Enter 换行。屏幕键盘仍换行；Ctrl/⌘+Enter 始终可发送。'**
  String get hubHardwareEnterSendsHint;

  /// No description provided for @hubQuickPanel.
  ///
  /// In zh, this message translates to:
  /// **'左滑快捷入口'**
  String get hubQuickPanel;

  /// No description provided for @hubQuickPanelSwipe.
  ///
  /// In zh, this message translates to:
  /// **'左滑打开'**
  String get hubQuickPanelSwipe;

  /// No description provided for @hubQuickPanelSwipeHint.
  ///
  /// In zh, this message translates to:
  /// **'在对话里从右向左滑。代码块、表格这些能横向滚动的内容不受影响。'**
  String get hubQuickPanelSwipeHint;

  /// No description provided for @hubQuickPanelItems.
  ///
  /// In zh, this message translates to:
  /// **'显示的入口'**
  String get hubQuickPanelItems;

  /// No description provided for @hubQuickPanelItemsNone.
  ///
  /// In zh, this message translates to:
  /// **'没有选择，左滑不会打开'**
  String get hubQuickPanelItemsNone;

  /// No description provided for @launchScreenTitle.
  ///
  /// In zh, this message translates to:
  /// **'启动画面'**
  String get launchScreenTitle;

  /// No description provided for @launchDefault.
  ///
  /// In zh, this message translates to:
  /// **'默认'**
  String get launchDefault;

  /// No description provided for @launchCustom.
  ///
  /// In zh, this message translates to:
  /// **'自定义'**
  String get launchCustom;

  /// No description provided for @launchFit.
  ///
  /// In zh, this message translates to:
  /// **'适配方式'**
  String get launchFit;

  /// No description provided for @launchFitFill.
  ///
  /// In zh, this message translates to:
  /// **'填满'**
  String get launchFitFill;

  /// No description provided for @launchFitCenter.
  ///
  /// In zh, this message translates to:
  /// **'居中'**
  String get launchFitCenter;

  /// No description provided for @launchBackground.
  ///
  /// In zh, this message translates to:
  /// **'背景色'**
  String get launchBackground;

  /// No description provided for @launchBackdropAuto.
  ///
  /// In zh, this message translates to:
  /// **'自动'**
  String get launchBackdropAuto;

  /// No description provided for @launchBackdropEdge.
  ///
  /// In zh, this message translates to:
  /// **'取自图片'**
  String get launchBackdropEdge;

  /// No description provided for @launchBackdropWhite.
  ///
  /// In zh, this message translates to:
  /// **'白色'**
  String get launchBackdropWhite;

  /// No description provided for @launchBackdropBlack.
  ///
  /// In zh, this message translates to:
  /// **'黑色'**
  String get launchBackdropBlack;

  /// No description provided for @launchReplace.
  ///
  /// In zh, this message translates to:
  /// **'更换图片或视频'**
  String get launchReplace;

  /// No description provided for @launchPreview.
  ///
  /// In zh, this message translates to:
  /// **'预览'**
  String get launchPreview;

  /// No description provided for @launchFooter.
  ///
  /// In zh, this message translates to:
  /// **'图片、动图 8 MB 以内，视频 30 MB 以内。冷启动时完整播放一遍，轻点可跳过'**
  String get launchFooter;

  /// No description provided for @launchChanged.
  ///
  /// In zh, this message translates to:
  /// **'启动画面已更换'**
  String get launchChanged;

  /// No description provided for @launchChangedSize.
  ///
  /// In zh, this message translates to:
  /// **'启动画面已更换 · {size}'**
  String launchChangedSize(String size);

  /// No description provided for @launchTooLarge.
  ///
  /// In zh, this message translates to:
  /// **'图片超过 8 MB'**
  String get launchTooLarge;

  /// No description provided for @launchOverLimit.
  ///
  /// In zh, this message translates to:
  /// **'文件超过 30 MB'**
  String get launchOverLimit;

  /// No description provided for @launchUnsupported.
  ///
  /// In zh, this message translates to:
  /// **'支持 PNG、JPEG、WebP、GIF 和 MP4'**
  String get launchUnsupported;

  /// No description provided for @launchUnreadable.
  ///
  /// In zh, this message translates to:
  /// **'无法读取这个文件'**
  String get launchUnreadable;

  /// No description provided for @launchUnavailable.
  ///
  /// In zh, this message translates to:
  /// **'无法打开相册'**
  String get launchUnavailable;

  /// No description provided for @launchBroken.
  ///
  /// In zh, this message translates to:
  /// **'无法读取'**
  String get launchBroken;

  /// No description provided for @iconShortcutRow.
  ///
  /// In zh, this message translates to:
  /// **'图片快捷方式'**
  String get iconShortcutRow;

  /// No description provided for @iconShortcutRowSubtitle.
  ///
  /// In zh, this message translates to:
  /// **'用自己的图片在桌面放一个入口'**
  String get iconShortcutRowSubtitle;

  /// No description provided for @iconShortcutPick.
  ///
  /// In zh, this message translates to:
  /// **'选择图片'**
  String get iconShortcutPick;

  /// No description provided for @iconShortcutChange.
  ///
  /// In zh, this message translates to:
  /// **'换一张'**
  String get iconShortcutChange;

  /// No description provided for @iconShortcutHint.
  ///
  /// In zh, this message translates to:
  /// **'拖动或双指缩放'**
  String get iconShortcutHint;

  /// No description provided for @iconShortcutName.
  ///
  /// In zh, this message translates to:
  /// **'名称'**
  String get iconShortcutName;

  /// No description provided for @iconShortcutAdd.
  ///
  /// In zh, this message translates to:
  /// **'添加到桌面'**
  String get iconShortcutAdd;

  /// No description provided for @iconShortcutNote.
  ///
  /// In zh, this message translates to:
  /// **'系统不允许把桌面图标换成任意图片，这里会另放一个打开 DSH Go 的快捷方式；部分桌面会在它的角上加一个小标'**
  String get iconShortcutNote;

  /// No description provided for @iconShortcutAdded.
  ///
  /// In zh, this message translates to:
  /// **'已添加到桌面'**
  String get iconShortcutAdded;

  /// No description provided for @iconShortcutConfirm.
  ///
  /// In zh, this message translates to:
  /// **'在弹出的窗口里确认'**
  String get iconShortcutConfirm;

  /// No description provided for @iconShortcutNoDialog.
  ///
  /// In zh, this message translates to:
  /// **'没有弹窗？在系统设置里允许 DSH Go 创建桌面快捷方式'**
  String get iconShortcutNoDialog;

  /// No description provided for @iconShortcutSettings.
  ///
  /// In zh, this message translates to:
  /// **'去设置'**
  String get iconShortcutSettings;

  /// No description provided for @iconShortcutUnsupported.
  ///
  /// In zh, this message translates to:
  /// **'这个桌面不支持添加快捷方式'**
  String get iconShortcutUnsupported;

  /// No description provided for @iconShortcutFailed.
  ///
  /// In zh, this message translates to:
  /// **'没能添加，稍后再试'**
  String get iconShortcutFailed;

  /// No description provided for @searchKwLaunchScreen.
  ///
  /// In zh, this message translates to:
  /// **'开屏,启动动画,闪屏,开机画面,欢迎画面'**
  String get searchKwLaunchScreen;

  /// No description provided for @searchKwIconShortcut.
  ///
  /// In zh, this message translates to:
  /// **'快捷方式,自定义图标,桌面图片,换图标'**
  String get searchKwIconShortcut;

  /// No description provided for @liveThinking.
  ///
  /// In zh, this message translates to:
  /// **'正在思考'**
  String get liveThinking;

  /// No description provided for @liveWorking.
  ///
  /// In zh, this message translates to:
  /// **'正在干活'**
  String get liveWorking;

  /// No description provided for @liveJuggling.
  ///
  /// In zh, this message translates to:
  /// **'子代理在帮忙'**
  String get liveJuggling;

  /// No description provided for @liveSweeping.
  ///
  /// In zh, this message translates to:
  /// **'正在整理上下文'**
  String get liveSweeping;

  /// No description provided for @liveRunsCount.
  ///
  /// In zh, this message translates to:
  /// **'{count} 个对话在跑'**
  String liveRunsCount(int count);

  /// No description provided for @liveChipThinking.
  ///
  /// In zh, this message translates to:
  /// **'思考中'**
  String get liveChipThinking;

  /// No description provided for @liveChipWorking.
  ///
  /// In zh, this message translates to:
  /// **'干活中'**
  String get liveChipWorking;

  /// No description provided for @liveChipJuggling.
  ///
  /// In zh, this message translates to:
  /// **'协作中'**
  String get liveChipJuggling;

  /// No description provided for @liveChipSweeping.
  ///
  /// In zh, this message translates to:
  /// **'整理中'**
  String get liveChipSweeping;

  /// No description provided for @liveChipApproval.
  ///
  /// In zh, this message translates to:
  /// **'待确认'**
  String get liveChipApproval;

  /// No description provided for @liveChipQuestion.
  ///
  /// In zh, this message translates to:
  /// **'待回答'**
  String get liveChipQuestion;

  /// No description provided for @liveChipDone.
  ///
  /// In zh, this message translates to:
  /// **'完成'**
  String get liveChipDone;

  /// No description provided for @liveChipFailed.
  ///
  /// In zh, this message translates to:
  /// **'出错'**
  String get liveChipFailed;

  /// No description provided for @livePublicRunning.
  ///
  /// In zh, this message translates to:
  /// **'DSH 正在干活'**
  String get livePublicRunning;

  /// No description provided for @livePublicWaiting.
  ///
  /// In zh, this message translates to:
  /// **'DSH 在等你处理'**
  String get livePublicWaiting;

  /// No description provided for @livePublicDone.
  ///
  /// In zh, this message translates to:
  /// **'DSH 做完了'**
  String get livePublicDone;

  /// No description provided for @livePublicFailed.
  ///
  /// In zh, this message translates to:
  /// **'DSH 出错了'**
  String get livePublicFailed;

  /// No description provided for @liveSettingsTitle.
  ///
  /// In zh, this message translates to:
  /// **'实时活动'**
  String get liveSettingsTitle;

  /// No description provided for @liveSettingsSwitch.
  ///
  /// In zh, this message translates to:
  /// **'显示实时活动'**
  String get liveSettingsSwitch;

  /// No description provided for @liveSettingsSubtitle.
  ///
  /// In zh, this message translates to:
  /// **'干活、等你处理、操作手机时，显示在状态栏胶囊和锁屏上；支持的手机会放进灵动岛'**
  String get liveSettingsSubtitle;

  /// No description provided for @liveSettingsFooter.
  ///
  /// In zh, this message translates to:
  /// **'Android 16 的实时活动（Live Updates）：小米 HyperOS 3.1+、OPPO / 一加 ColorOS 16、荣耀 MagicOS 10 和 Pixel 会显示；vivo 原子岛和三星 Now Bar 目前只对厂商合作的应用开放。'**
  String get liveSettingsFooter;

  /// No description provided for @liveUnsupported.
  ///
  /// In zh, this message translates to:
  /// **'这台手机的系统还不支持实时活动'**
  String get liveUnsupported;

  /// No description provided for @liveBlockedTitle.
  ///
  /// In zh, this message translates to:
  /// **'系统没有允许实时活动'**
  String get liveBlockedTitle;

  /// No description provided for @liveBlockedText.
  ///
  /// In zh, this message translates to:
  /// **'在系统设置里为 DSH Go 打开「实时活动」（有的手机叫「在流体云中显示」）'**
  String get liveBlockedText;

  /// No description provided for @localeTitle.
  ///
  /// In zh, this message translates to:
  /// **'语言'**
  String get localeTitle;

  /// No description provided for @localeSystem.
  ///
  /// In zh, this message translates to:
  /// **'跟随系统'**
  String get localeSystem;

  /// No description provided for @localeZh.
  ///
  /// In zh, this message translates to:
  /// **'简体中文'**
  String get localeZh;

  /// No description provided for @localeEn.
  ///
  /// In zh, this message translates to:
  /// **'English'**
  String get localeEn;

  /// No description provided for @localEnvChooseTitle.
  ///
  /// In zh, this message translates to:
  /// **'DSH 在哪里运行？'**
  String get localEnvChooseTitle;

  /// No description provided for @localEnvChooseMessage.
  ///
  /// In zh, this message translates to:
  /// **'之后可以在设置里更改'**
  String get localEnvChooseMessage;

  /// No description provided for @localEnvThisPhoneDetail.
  ///
  /// In zh, this message translates to:
  /// **'存储约 {storage} MB · 内存约 {memory} MB'**
  String localEnvThisPhoneDetail(int storage, int memory);

  /// No description provided for @localEnvThisPhoneDetailShort.
  ///
  /// In zh, this message translates to:
  /// **'内存约 {memory} MB'**
  String localEnvThisPhoneDetailShort(int memory);

  /// No description provided for @localEnvLowStorage.
  ///
  /// In zh, this message translates to:
  /// **'存储空间不足，需要约 {needed} MB'**
  String localEnvLowStorage(int needed);

  /// No description provided for @localEnvRemoteDetail.
  ///
  /// In zh, this message translates to:
  /// **'连接电脑或服务器上的 DSH'**
  String get localEnvRemoteDetail;

  /// No description provided for @localEnvRecommended.
  ///
  /// In zh, this message translates to:
  /// **'推荐'**
  String get localEnvRecommended;

  /// No description provided for @localEnvInstallTitle.
  ///
  /// In zh, this message translates to:
  /// **'安装本机运行环境'**
  String get localEnvInstallTitle;

  /// No description provided for @localEnvInstallMessage.
  ///
  /// In zh, this message translates to:
  /// **'在这台手机上运行 DSH'**
  String get localEnvInstallMessage;

  /// No description provided for @localEnvFactStorage.
  ///
  /// In zh, this message translates to:
  /// **'约 {storage} MB 存储空间'**
  String localEnvFactStorage(int storage);

  /// No description provided for @localEnvFactMemory.
  ///
  /// In zh, this message translates to:
  /// **'运行时约 {memory} MB 内存'**
  String localEnvFactMemory(int memory);

  /// No description provided for @localEnvUseRemote.
  ///
  /// In zh, this message translates to:
  /// **'改用远程主机'**
  String get localEnvUseRemote;

  /// No description provided for @localEnvNotInstalled.
  ///
  /// In zh, this message translates to:
  /// **'本机未安装运行环境'**
  String get localEnvNotInstalled;

  /// No description provided for @localEnvUninstall.
  ///
  /// In zh, this message translates to:
  /// **'卸载运行环境'**
  String get localEnvUninstall;

  /// No description provided for @localEnvUninstallHint.
  ///
  /// In zh, this message translates to:
  /// **'释放存储空间'**
  String get localEnvUninstallHint;

  /// No description provided for @localEnvUninstallTitle.
  ///
  /// In zh, this message translates to:
  /// **'卸载运行环境？'**
  String get localEnvUninstallTitle;

  /// No description provided for @localEnvUninstallBody.
  ///
  /// In zh, this message translates to:
  /// **'本机的对话、工作区、插件、设置、界面配置和技能会一并删除。'**
  String get localEnvUninstallBody;

  /// No description provided for @localEnvUninstallConfirm.
  ///
  /// In zh, this message translates to:
  /// **'卸载'**
  String get localEnvUninstallConfirm;

  /// No description provided for @localEnvUninstallFailed.
  ///
  /// In zh, this message translates to:
  /// **'没能卸载，再试一次'**
  String get localEnvUninstallFailed;

  /// No description provided for @localEnvPhoneNeedsRuntime.
  ///
  /// In zh, this message translates to:
  /// **'安装本机运行环境后可用'**
  String get localEnvPhoneNeedsRuntime;

  /// No description provided for @localEnvSignInNeedsRuntime.
  ///
  /// In zh, this message translates to:
  /// **'需要本机运行环境'**
  String get localEnvSignInNeedsRuntime;

  /// No description provided for @localEnvSignInInstallFirst.
  ///
  /// In zh, this message translates to:
  /// **'安装后即可登录'**
  String get localEnvSignInInstallFirst;

  /// No description provided for @marketSectionOfficial.
  ///
  /// In zh, this message translates to:
  /// **'官方'**
  String get marketSectionOfficial;

  /// No description provided for @marketSectionAdapted.
  ///
  /// In zh, this message translates to:
  /// **'适配 DSH Go'**
  String get marketSectionAdapted;

  /// No description provided for @marketSectionAll.
  ///
  /// In zh, this message translates to:
  /// **'全部'**
  String get marketSectionAll;

  /// No description provided for @marketSectionLoading.
  ///
  /// In zh, this message translates to:
  /// **'正在载入…'**
  String get marketSectionLoading;

  /// No description provided for @marketSectionFailed.
  ///
  /// In zh, this message translates to:
  /// **'官方目录没打开'**
  String get marketSectionFailed;

  /// No description provided for @marketSectionEmpty.
  ///
  /// In zh, this message translates to:
  /// **'暂无'**
  String get marketSectionEmpty;

  /// No description provided for @marketTierOfficial.
  ///
  /// In zh, this message translates to:
  /// **'官方'**
  String get marketTierOfficial;

  /// No description provided for @marketTierAdapted.
  ///
  /// In zh, this message translates to:
  /// **'适配 DSH Go'**
  String get marketTierAdapted;

  /// No description provided for @marketRiskMedium.
  ///
  /// In zh, this message translates to:
  /// **'中风险'**
  String get marketRiskMedium;

  /// No description provided for @marketRiskHigh.
  ///
  /// In zh, this message translates to:
  /// **'高风险'**
  String get marketRiskHigh;

  /// No description provided for @marketFlagInstallScripts.
  ///
  /// In zh, this message translates to:
  /// **'安装时运行脚本'**
  String get marketFlagInstallScripts;

  /// No description provided for @marketFlagInstallScriptsBody.
  ///
  /// In zh, this message translates to:
  /// **'安装时会自动运行包里的脚本（preinstall、install 或 postinstall）'**
  String get marketFlagInstallScriptsBody;

  /// No description provided for @marketFlagNativeCode.
  ///
  /// In zh, this message translates to:
  /// **'含原生程序'**
  String get marketFlagNativeCode;

  /// No description provided for @marketFlagNativeCodeBody.
  ///
  /// In zh, this message translates to:
  /// **'包里有编译好的原生程序（.node、binding.gyp 或二进制文件），没法直接阅读'**
  String get marketFlagNativeCodeBody;

  /// No description provided for @marketFlagShell.
  ///
  /// In zh, this message translates to:
  /// **'执行命令'**
  String get marketFlagShell;

  /// No description provided for @marketFlagShellBody.
  ///
  /// In zh, this message translates to:
  /// **'代码里会调用系统命令（child_process）'**
  String get marketFlagShellBody;

  /// No description provided for @marketFlagNetwork.
  ///
  /// In zh, this message translates to:
  /// **'联网'**
  String get marketFlagNetwork;

  /// No description provided for @marketFlagNetworkBody.
  ///
  /// In zh, this message translates to:
  /// **'代码里会发起网络请求（fetch、http、WebSocket）'**
  String get marketFlagNetworkBody;

  /// No description provided for @marketFlagFilesystem.
  ///
  /// In zh, this message translates to:
  /// **'写工作区外的文件'**
  String get marketFlagFilesystem;

  /// No description provided for @marketFlagFilesystemBody.
  ///
  /// In zh, this message translates to:
  /// **'会写入工作区以外的路径'**
  String get marketFlagFilesystemBody;

  /// No description provided for @marketFlagObfuscated.
  ///
  /// In zh, this message translates to:
  /// **'代码难以审阅'**
  String get marketFlagObfuscated;

  /// No description provided for @marketFlagObfuscatedBody.
  ///
  /// In zh, this message translates to:
  /// **'有压缩或混淆过的大文件，看不出它做什么'**
  String get marketFlagObfuscatedBody;

  /// No description provided for @marketFlagNotAdapted.
  ///
  /// In zh, this message translates to:
  /// **'未适配 DSH Go'**
  String get marketFlagNotAdapted;

  /// No description provided for @marketFlagNotAdaptedBody.
  ///
  /// In zh, this message translates to:
  /// **'没有声明 DSH Go 原生协议，在 App 里没有原生界面'**
  String get marketFlagNotAdaptedBody;

  /// No description provided for @marketFlagOtherBody.
  ///
  /// In zh, this message translates to:
  /// **'自动检查报告的其他特征'**
  String get marketFlagOtherBody;

  /// No description provided for @marketChecksTitle.
  ///
  /// In zh, this message translates to:
  /// **'自动检查'**
  String get marketChecksTitle;

  /// No description provided for @marketChecksClean.
  ///
  /// In zh, this message translates to:
  /// **'没有发现风险特征'**
  String get marketChecksClean;

  /// No description provided for @marketChecksNote.
  ///
  /// In zh, this message translates to:
  /// **'自动检查发现的特征，不代表插件有恶意'**
  String get marketChecksNote;

  /// No description provided for @marketCheckedOn.
  ///
  /// In zh, this message translates to:
  /// **'检查于 {date}'**
  String marketCheckedOn(String date);

  /// No description provided for @marketScreenshot.
  ///
  /// In zh, this message translates to:
  /// **'截图 {index}'**
  String marketScreenshot(int index);

  /// No description provided for @marketRiskConfirmTitle.
  ///
  /// In zh, this message translates to:
  /// **'「{name}」有风险特征'**
  String marketRiskConfirmTitle(String name);

  /// No description provided for @marketRiskConfirmAction.
  ///
  /// In zh, this message translates to:
  /// **'仍然安装'**
  String get marketRiskConfirmAction;

  /// No description provided for @marketPinnedVersion.
  ///
  /// In zh, this message translates to:
  /// **'锁定版本'**
  String get marketPinnedVersion;

  /// No description provided for @marketRequiresApp.
  ///
  /// In zh, this message translates to:
  /// **'需要 DSH Go'**
  String get marketRequiresApp;

  /// No description provided for @marketNeedsApp.
  ///
  /// In zh, this message translates to:
  /// **'需要 DSH Go {version} 或更高版本'**
  String marketNeedsApp(String version);

  /// No description provided for @marketUpdateAvailable.
  ///
  /// In zh, this message translates to:
  /// **'有更新'**
  String get marketUpdateAvailable;

  /// No description provided for @marketBlockedTitle.
  ///
  /// In zh, this message translates to:
  /// **'这个版本已下架'**
  String get marketBlockedTitle;

  /// No description provided for @marketBlockedMessage.
  ///
  /// In zh, this message translates to:
  /// **'已安装的 {version} 已从插件市场下架，建议卸载'**
  String marketBlockedMessage(String version);

  /// No description provided for @marketBlockedRow.
  ///
  /// In zh, this message translates to:
  /// **'此版本已下架，建议卸载'**
  String get marketBlockedRow;

  /// No description provided for @marketBlockedBadge.
  ///
  /// In zh, this message translates to:
  /// **'已下架'**
  String get marketBlockedBadge;

  /// No description provided for @marketVerifying.
  ///
  /// In zh, this message translates to:
  /// **'正在核对版本…'**
  String get marketVerifying;

  /// No description provided for @marketMismatchTitle.
  ///
  /// In zh, this message translates to:
  /// **'版本校验不一致'**
  String get marketMismatchTitle;

  /// No description provided for @marketMismatchMessage.
  ///
  /// In zh, this message translates to:
  /// **'npm 上的 {version} 和插件市场检查过的不是同一个包，已停止安装'**
  String marketMismatchMessage(String version);

  /// No description provided for @marketSubmit.
  ///
  /// In zh, this message translates to:
  /// **'提交插件'**
  String get marketSubmit;

  /// No description provided for @marketSubmitHint.
  ///
  /// In zh, this message translates to:
  /// **'在 GitHub 提交，通过自动检查即上架'**
  String get marketSubmitHint;

  /// No description provided for @marketLinkNotFound.
  ///
  /// In zh, this message translates to:
  /// **'插件市场里没有 {name}'**
  String marketLinkNotFound(String name);

  /// No description provided for @marketVerificationUnavailableTitle.
  ///
  /// In zh, this message translates to:
  /// **'暂时无法核对版本'**
  String get marketVerificationUnavailableTitle;

  /// No description provided for @marketVerificationUnavailableBody.
  ///
  /// In zh, this message translates to:
  /// **'没能取得 npm 的版本校验信息，尚未开始安装。请检查网络后重试。'**
  String get marketVerificationUnavailableBody;

  /// No description provided for @marketCombinedCount.
  ///
  /// In zh, this message translates to:
  /// **'{count} 个插件'**
  String marketCombinedCount(int count);

  /// No description provided for @mediaGenerateTile.
  ///
  /// In zh, this message translates to:
  /// **'生成'**
  String get mediaGenerateTile;

  /// No description provided for @mediaAiGenerated.
  ///
  /// In zh, this message translates to:
  /// **'AI 生成'**
  String get mediaAiGenerated;

  /// No description provided for @mediaCostEstimate.
  ///
  /// In zh, this message translates to:
  /// **'约 {amount}'**
  String mediaCostEstimate(String amount);

  /// No description provided for @mediaSavedCount.
  ///
  /// In zh, this message translates to:
  /// **'已保存 {count} 张到相册'**
  String mediaSavedCount(int count);

  /// No description provided for @mediaRegenerate.
  ///
  /// In zh, this message translates to:
  /// **'重新生成'**
  String get mediaRegenerate;

  /// No description provided for @mediaCopyPrompt.
  ///
  /// In zh, this message translates to:
  /// **'复制提示词'**
  String get mediaCopyPrompt;

  /// No description provided for @mediaFileGone.
  ///
  /// In zh, this message translates to:
  /// **'文件已不在'**
  String get mediaFileGone;

  /// No description provided for @mediaKindImage.
  ///
  /// In zh, this message translates to:
  /// **'图像'**
  String get mediaKindImage;

  /// No description provided for @mediaKindVideo.
  ///
  /// In zh, this message translates to:
  /// **'视频'**
  String get mediaKindVideo;

  /// No description provided for @mediaTitleImage.
  ///
  /// In zh, this message translates to:
  /// **'生成图像'**
  String get mediaTitleImage;

  /// No description provided for @mediaTitleVideo.
  ///
  /// In zh, this message translates to:
  /// **'生成视频'**
  String get mediaTitleVideo;

  /// No description provided for @mediaOpenElsewhere.
  ///
  /// In zh, this message translates to:
  /// **'在其他应用中打开'**
  String get mediaOpenElsewhere;

  /// No description provided for @mediaShowInFiles.
  ///
  /// In zh, this message translates to:
  /// **'在文件中显示'**
  String get mediaShowInFiles;

  /// No description provided for @mediaGenerating.
  ///
  /// In zh, this message translates to:
  /// **'生成中'**
  String get mediaGenerating;

  /// No description provided for @mediaGeneratingProgress.
  ///
  /// In zh, this message translates to:
  /// **'生成中 · {progress}'**
  String mediaGeneratingProgress(String progress);

  /// No description provided for @mediaCancelled.
  ///
  /// In zh, this message translates to:
  /// **'已取消'**
  String get mediaCancelled;

  /// No description provided for @mediaNotGenerated.
  ///
  /// In zh, this message translates to:
  /// **'未生成'**
  String get mediaNotGenerated;

  /// No description provided for @mediaPartial.
  ///
  /// In zh, this message translates to:
  /// **'{done} / {total} 张'**
  String mediaPartial(int done, int total);

  /// No description provided for @mediaCount.
  ///
  /// In zh, this message translates to:
  /// **'{count} 张'**
  String mediaCount(int count);

  /// No description provided for @mediaSeconds.
  ///
  /// In zh, this message translates to:
  /// **'{seconds} 秒'**
  String mediaSeconds(int seconds);

  /// No description provided for @mediaImageOf.
  ///
  /// In zh, this message translates to:
  /// **'第 {index} 张，共 {count} 张'**
  String mediaImageOf(int index, int count);

  /// No description provided for @mediaPageOf.
  ///
  /// In zh, this message translates to:
  /// **'{index} / {count}'**
  String mediaPageOf(int index, int count);

  /// No description provided for @mediaErrorPolicyInput.
  ///
  /// In zh, this message translates to:
  /// **'描述未通过内容审核'**
  String get mediaErrorPolicyInput;

  /// No description provided for @mediaErrorPolicyOutput.
  ///
  /// In zh, this message translates to:
  /// **'生成结果未通过内容审核'**
  String get mediaErrorPolicyOutput;

  /// No description provided for @mediaErrorAuth.
  ///
  /// In zh, this message translates to:
  /// **'服务未授权'**
  String get mediaErrorAuth;

  /// No description provided for @mediaErrorBalance.
  ///
  /// In zh, this message translates to:
  /// **'余额不足'**
  String get mediaErrorBalance;

  /// No description provided for @mediaErrorQuota.
  ///
  /// In zh, this message translates to:
  /// **'今天的额度已用完'**
  String get mediaErrorQuota;

  /// No description provided for @mediaErrorUnavailable.
  ///
  /// In zh, this message translates to:
  /// **'服务暂时不可用'**
  String get mediaErrorUnavailable;

  /// No description provided for @mediaErrorExpired.
  ///
  /// In zh, this message translates to:
  /// **'结果已过期'**
  String get mediaErrorExpired;

  /// No description provided for @mediaErrorGeneric.
  ///
  /// In zh, this message translates to:
  /// **'没能生成'**
  String get mediaErrorGeneric;

  /// No description provided for @mediaVary.
  ///
  /// In zh, this message translates to:
  /// **'变体'**
  String get mediaVary;

  /// No description provided for @mediaEdit.
  ///
  /// In zh, this message translates to:
  /// **'编辑'**
  String get mediaEdit;

  /// No description provided for @mediaRevise.
  ///
  /// In zh, this message translates to:
  /// **'修改'**
  String get mediaRevise;

  /// No description provided for @mediaUpscale.
  ///
  /// In zh, this message translates to:
  /// **'放大'**
  String get mediaUpscale;

  /// No description provided for @mediaMakeVideo.
  ///
  /// In zh, this message translates to:
  /// **'做成视频'**
  String get mediaMakeVideo;

  /// No description provided for @mediaDetailModel.
  ///
  /// In zh, this message translates to:
  /// **'模型'**
  String get mediaDetailModel;

  /// No description provided for @mediaDetailSize.
  ///
  /// In zh, this message translates to:
  /// **'尺寸'**
  String get mediaDetailSize;

  /// No description provided for @mediaDetailCost.
  ///
  /// In zh, this message translates to:
  /// **'费用'**
  String get mediaDetailCost;

  /// No description provided for @mediaDetailProvenance.
  ///
  /// In zh, this message translates to:
  /// **'来源标识'**
  String get mediaDetailProvenance;

  /// No description provided for @mediaDetailFile.
  ///
  /// In zh, this message translates to:
  /// **'文件'**
  String get mediaDetailFile;

  /// No description provided for @mediaOriginalPrompt.
  ///
  /// In zh, this message translates to:
  /// **'原文：{text}'**
  String mediaOriginalPrompt(String text);

  /// No description provided for @mediaProvenanceC2pa.
  ///
  /// In zh, this message translates to:
  /// **'C2PA'**
  String get mediaProvenanceC2pa;

  /// No description provided for @mediaProvenanceImplicit.
  ///
  /// In zh, this message translates to:
  /// **'隐式'**
  String get mediaProvenanceImplicit;

  /// No description provided for @mediaProvenanceVisible.
  ///
  /// In zh, this message translates to:
  /// **'可见水印'**
  String get mediaProvenanceVisible;

  /// No description provided for @mediaModeExit.
  ///
  /// In zh, this message translates to:
  /// **'退出生成'**
  String get mediaModeExit;

  /// No description provided for @mediaModeLabel.
  ///
  /// In zh, this message translates to:
  /// **'生成参数：{summary}'**
  String mediaModeLabel(String summary);

  /// No description provided for @mediaParamModel.
  ///
  /// In zh, this message translates to:
  /// **'模型'**
  String get mediaParamModel;

  /// No description provided for @mediaParamAspect.
  ///
  /// In zh, this message translates to:
  /// **'比例'**
  String get mediaParamAspect;

  /// No description provided for @mediaParamCount.
  ///
  /// In zh, this message translates to:
  /// **'数量'**
  String get mediaParamCount;

  /// No description provided for @mediaParamQuality.
  ///
  /// In zh, this message translates to:
  /// **'清晰度'**
  String get mediaParamQuality;

  /// No description provided for @mediaParamDuration.
  ///
  /// In zh, this message translates to:
  /// **'时长'**
  String get mediaParamDuration;

  /// No description provided for @mediaQualityAuto.
  ///
  /// In zh, this message translates to:
  /// **'自动'**
  String get mediaQualityAuto;

  /// No description provided for @mediaQualityStandard.
  ///
  /// In zh, this message translates to:
  /// **'标准'**
  String get mediaQualityStandard;

  /// No description provided for @mediaQualityHigh.
  ///
  /// In zh, this message translates to:
  /// **'高清'**
  String get mediaQualityHigh;

  /// No description provided for @mediaQuality4k.
  ///
  /// In zh, this message translates to:
  /// **'4K'**
  String get mediaQuality4k;

  /// No description provided for @mediaQualityLevelLow.
  ///
  /// In zh, this message translates to:
  /// **'低'**
  String get mediaQualityLevelLow;

  /// No description provided for @mediaQualityLevelMedium.
  ///
  /// In zh, this message translates to:
  /// **'中'**
  String get mediaQualityLevelMedium;

  /// No description provided for @mediaQualityLevelHigh.
  ///
  /// In zh, this message translates to:
  /// **'高'**
  String get mediaQualityLevelHigh;

  /// No description provided for @mediaModelPick.
  ///
  /// In zh, this message translates to:
  /// **'请选择'**
  String get mediaModelPick;

  /// No description provided for @mediaPickModelFirst.
  ///
  /// In zh, this message translates to:
  /// **'先选一个模型'**
  String get mediaPickModelFirst;

  /// No description provided for @mediaPricePerImage.
  ///
  /// In zh, this message translates to:
  /// **'{price} / 张'**
  String mediaPricePerImage(String price);

  /// No description provided for @mediaPricePerSecond.
  ///
  /// In zh, this message translates to:
  /// **'{price} / 秒'**
  String mediaPricePerSecond(String price);

  /// No description provided for @mediaManageModels.
  ///
  /// In zh, this message translates to:
  /// **'管理'**
  String get mediaManageModels;

  /// No description provided for @mediaHintImage.
  ///
  /// In zh, this message translates to:
  /// **'描述你想要的画面…'**
  String get mediaHintImage;

  /// No description provided for @mediaHintVideo.
  ///
  /// In zh, this message translates to:
  /// **'描述画面和镜头…'**
  String get mediaHintVideo;

  /// No description provided for @mediaHintEdit.
  ///
  /// In zh, this message translates to:
  /// **'想怎么改…'**
  String get mediaHintEdit;

  /// No description provided for @mediaFirstFrame.
  ///
  /// In zh, this message translates to:
  /// **'首帧'**
  String get mediaFirstFrame;

  /// No description provided for @mediaLastFrame.
  ///
  /// In zh, this message translates to:
  /// **'尾帧'**
  String get mediaLastFrame;

  /// No description provided for @mediaNoLastFrame.
  ///
  /// In zh, this message translates to:
  /// **'这个模型不支持尾帧'**
  String get mediaNoLastFrame;

  /// No description provided for @mediaNoRefs.
  ///
  /// In zh, this message translates to:
  /// **'这个模型不支持参考图'**
  String get mediaNoRefs;

  /// No description provided for @mediaRefLimit.
  ///
  /// In zh, this message translates to:
  /// **'最多 {count} 张参考图'**
  String mediaRefLimit(int count);

  /// No description provided for @mediaNoDescription.
  ///
  /// In zh, this message translates to:
  /// **'先写下想要的画面'**
  String get mediaNoDescription;

  /// No description provided for @mediaDescriptionTooLong.
  ///
  /// In zh, this message translates to:
  /// **'描述太长，删短一些再生成'**
  String get mediaDescriptionTooLong;

  /// No description provided for @mediaInstallTitle.
  ///
  /// In zh, this message translates to:
  /// **'图像与视频'**
  String get mediaInstallTitle;

  /// No description provided for @mediaInstallBody.
  ///
  /// In zh, this message translates to:
  /// **'这台主机还没有图像与视频插件'**
  String get mediaInstallBody;

  /// No description provided for @mediaInstallAction.
  ///
  /// In zh, this message translates to:
  /// **'在此主机上安装'**
  String get mediaInstallAction;

  /// No description provided for @mediaUnavailableTitle.
  ///
  /// In zh, this message translates to:
  /// **'生成模式不可用'**
  String get mediaUnavailableTitle;

  /// No description provided for @mediaUnavailableBody.
  ///
  /// In zh, this message translates to:
  /// **'这台主机的图像与视频插件版本不兼容。仍可直接在对话里描述想要的画面。'**
  String get mediaUnavailableBody;

  /// No description provided for @mediaUnavailableAction.
  ///
  /// In zh, this message translates to:
  /// **'管理插件'**
  String get mediaUnavailableAction;

  /// No description provided for @mediaSettingsTitle.
  ///
  /// In zh, this message translates to:
  /// **'图像与视频'**
  String get mediaSettingsTitle;

  /// No description provided for @searchKwMediaGeneration.
  ///
  /// In zh, this message translates to:
  /// **'生图,画图,文生图,视频生成,AI 绘画,生成图片,生成视频'**
  String get searchKwMediaGeneration;

  /// No description provided for @mediaSettingsDefaults.
  ///
  /// In zh, this message translates to:
  /// **'默认'**
  String get mediaSettingsDefaults;

  /// No description provided for @mediaSettingsLegacyDefault.
  ///
  /// In zh, this message translates to:
  /// **'旧版通用默认'**
  String get mediaSettingsLegacyDefault;

  /// No description provided for @mediaSettingsLegacyDefaultHint.
  ///
  /// In zh, this message translates to:
  /// **'0.2.x 的设置；图片和视频没有单独默认时使用'**
  String get mediaSettingsLegacyDefaultHint;

  /// No description provided for @mediaSettingsLegacyDefaultStale.
  ///
  /// In zh, this message translates to:
  /// **'指向的服务已不可用；清除它可避免生成时报错'**
  String get mediaSettingsLegacyDefaultStale;

  /// No description provided for @mediaSettingsLegacyDefaultClear.
  ///
  /// In zh, this message translates to:
  /// **'清除旧版通用默认'**
  String get mediaSettingsLegacyDefaultClear;

  /// No description provided for @mediaSettingsDefaultModel.
  ///
  /// In zh, this message translates to:
  /// **'默认模型'**
  String get mediaSettingsDefaultModel;

  /// No description provided for @mediaSettingsDefaultFooterLegacy.
  ///
  /// In zh, this message translates to:
  /// **'旧版插件只有一个默认模型；更新插件后可以分别设置图片和视频。'**
  String get mediaSettingsDefaultFooterLegacy;

  /// No description provided for @mediaSettingsDefaultsFooter.
  ///
  /// In zh, this message translates to:
  /// **'图片和视频分别选择默认模型；留空自动使用第一个可用的。'**
  String get mediaSettingsDefaultsFooter;

  /// No description provided for @mediaSettingsNoVideoModels.
  ///
  /// In zh, this message translates to:
  /// **'这台主机的目录里还没有视频模型'**
  String get mediaSettingsNoVideoModels;

  /// No description provided for @mediaSettingsServices.
  ///
  /// In zh, this message translates to:
  /// **'服务'**
  String get mediaSettingsServices;

  /// No description provided for @mediaSettingsAddService.
  ///
  /// In zh, this message translates to:
  /// **'添加服务'**
  String get mediaSettingsAddService;

  /// No description provided for @mediaSettingsAddServiceHint.
  ///
  /// In zh, this message translates to:
  /// **'从服务商预设开始，地址、协议和模型都会自动带好'**
  String get mediaSettingsAddServiceHint;

  /// No description provided for @mediaSettingsServiceLimit.
  ///
  /// In zh, this message translates to:
  /// **'最多 {count} 个服务'**
  String mediaSettingsServiceLimit(int count);

  /// No description provided for @mediaSettingsNoServices.
  ///
  /// In zh, this message translates to:
  /// **'还没有服务。添加一个服务商就能开始生成图片或视频。'**
  String get mediaSettingsNoServices;

  /// No description provided for @mediaSettingsNoModels.
  ///
  /// In zh, this message translates to:
  /// **'未选模型'**
  String get mediaSettingsNoModels;

  /// No description provided for @mediaSettingsKeyMissing.
  ///
  /// In zh, this message translates to:
  /// **'未配置 API Key'**
  String get mediaSettingsKeyMissing;

  /// No description provided for @mediaSettingsCatalogMissing.
  ///
  /// In zh, this message translates to:
  /// **'这个主机的插件没有提供模型目录；已有服务仍可编辑，但暂时不能新增服务或选择默认模型。'**
  String get mediaSettingsCatalogMissing;

  /// No description provided for @mediaSettingsCatalogBroken.
  ///
  /// In zh, this message translates to:
  /// **'模型目录读不了（可能版本不兼容）；已有服务仍可编辑，但暂时不能新增服务或选择默认模型。'**
  String get mediaSettingsCatalogBroken;

  /// No description provided for @mediaSettingsCatalogEmpty.
  ///
  /// In zh, this message translates to:
  /// **'模型目录里还没有模型；已有服务仍可编辑，但暂时不能新增服务或选择默认模型。'**
  String get mediaSettingsCatalogEmpty;

  /// No description provided for @mediaSettingsNoPresets.
  ///
  /// In zh, this message translates to:
  /// **'目录里还没有可添加的服务。'**
  String get mediaSettingsNoPresets;

  /// No description provided for @mediaSettingsLimits.
  ///
  /// In zh, this message translates to:
  /// **'请求上限'**
  String get mediaSettingsLimits;

  /// No description provided for @mediaSettingsLimitsHint.
  ///
  /// In zh, this message translates to:
  /// **'限制单次请求的图片张数和字节数；默认是插件硬上限'**
  String get mediaSettingsLimitsHint;

  /// No description provided for @mediaSettingsMaxImages.
  ///
  /// In zh, this message translates to:
  /// **'单次图片张数'**
  String get mediaSettingsMaxImages;

  /// No description provided for @mediaSettingsMaxImageBytes.
  ///
  /// In zh, this message translates to:
  /// **'单张原件字节上限'**
  String get mediaSettingsMaxImageBytes;

  /// No description provided for @mediaSettingsMaxResponseBytes.
  ///
  /// In zh, this message translates to:
  /// **'服务响应字节上限'**
  String get mediaSettingsMaxResponseBytes;

  /// No description provided for @mediaSettingsMaxTotalImageBytes.
  ///
  /// In zh, this message translates to:
  /// **'单次图片总字节上限'**
  String get mediaSettingsMaxTotalImageBytes;

  /// No description provided for @mediaSettingsMaxVideoBytes.
  ///
  /// In zh, this message translates to:
  /// **'视频原件字节上限'**
  String get mediaSettingsMaxVideoBytes;

  /// No description provided for @mediaSettingsBudget.
  ///
  /// In zh, this message translates to:
  /// **'费用保护'**
  String get mediaSettingsBudget;

  /// No description provided for @mediaSettingsDailyBudget.
  ///
  /// In zh, this message translates to:
  /// **'每日预算（元）'**
  String get mediaSettingsDailyBudget;

  /// No description provided for @mediaSettingsDailyBudgetHint.
  ///
  /// In zh, this message translates to:
  /// **'按上海日期重置；用完即暂停生成'**
  String get mediaSettingsDailyBudgetHint;

  /// No description provided for @mediaSettingsUnknownPriceHold.
  ///
  /// In zh, this message translates to:
  /// **'无可靠价格时每次预留（元）'**
  String get mediaSettingsUnknownPriceHold;

  /// No description provided for @mediaSettingsUnknownPriceHoldHint.
  ///
  /// In zh, this message translates to:
  /// **'逐次确认的预留金额，不是供应商的收费上限'**
  String get mediaSettingsUnknownPriceHoldHint;

  /// No description provided for @mediaSettingsApiKey.
  ///
  /// In zh, this message translates to:
  /// **'API Key'**
  String get mediaSettingsApiKey;

  /// No description provided for @mediaSettingsReuseKey.
  ///
  /// In zh, this message translates to:
  /// **'复用密钥'**
  String get mediaSettingsReuseKey;

  /// No description provided for @mediaSettingsReuseKeyHint.
  ///
  /// In zh, this message translates to:
  /// **'同一服务商的图片和视频共用一个 API Key，不用再填一次。'**
  String get mediaSettingsReuseKeyHint;

  /// No description provided for @mediaSettingsReuseKeyNone.
  ///
  /// In zh, this message translates to:
  /// **'同一服务商还没有其它服务。'**
  String get mediaSettingsReuseKeyNone;

  /// No description provided for @mediaSettingsReuseKeyShared.
  ///
  /// In zh, this message translates to:
  /// **'已复用'**
  String get mediaSettingsReuseKeyShared;

  /// No description provided for @mediaSettingsModels.
  ///
  /// In zh, this message translates to:
  /// **'模型'**
  String get mediaSettingsModels;

  /// No description provided for @mediaSettingsModelsEmpty.
  ///
  /// In zh, this message translates to:
  /// **'目录里没有这个协议的模型'**
  String get mediaSettingsModelsEmpty;

  /// No description provided for @mediaSettingsModelKeepOne.
  ///
  /// In zh, this message translates to:
  /// **'至少保留一个模型'**
  String get mediaSettingsModelKeepOne;

  /// No description provided for @mediaSettingsModelMissing.
  ///
  /// In zh, this message translates to:
  /// **'目录中不存在'**
  String get mediaSettingsModelMissing;

  /// No description provided for @mediaSettingsAdvanced.
  ///
  /// In zh, this message translates to:
  /// **'高级'**
  String get mediaSettingsAdvanced;

  /// No description provided for @mediaSettingsBaseUrl.
  ///
  /// In zh, this message translates to:
  /// **'API 根地址'**
  String get mediaSettingsBaseUrl;

  /// No description provided for @mediaSettingsBaseUrlInvalid.
  ///
  /// In zh, this message translates to:
  /// **'地址要以 https:// 开头'**
  String get mediaSettingsBaseUrlInvalid;

  /// No description provided for @mediaSettingsProvider.
  ///
  /// In zh, this message translates to:
  /// **'服务商标识'**
  String get mediaSettingsProvider;

  /// No description provided for @mediaSettingsKeyRef.
  ///
  /// In zh, this message translates to:
  /// **'凭据名'**
  String get mediaSettingsKeyRef;

  /// No description provided for @mediaSettingsKeyRefInvalid.
  ///
  /// In zh, this message translates to:
  /// **'凭据名只能包含字母、数字和下划线'**
  String get mediaSettingsKeyRefInvalid;

  /// No description provided for @mediaSettingsResponseFormat.
  ///
  /// In zh, this message translates to:
  /// **'返回格式'**
  String get mediaSettingsResponseFormat;

  /// No description provided for @mediaSettingsResponseFormatAuto.
  ///
  /// In zh, this message translates to:
  /// **'按协议'**
  String get mediaSettingsResponseFormatAuto;

  /// No description provided for @mediaSettingsServiceId.
  ///
  /// In zh, this message translates to:
  /// **'服务 ID'**
  String get mediaSettingsServiceId;

  /// No description provided for @mediaSettingsServiceGone.
  ///
  /// In zh, this message translates to:
  /// **'这个服务已经不在了'**
  String get mediaSettingsServiceGone;

  /// No description provided for @mediaSettingsServiceGoneBody.
  ///
  /// In zh, this message translates to:
  /// **'它可能已在别处被删掉。返回上一页可以重新添加。'**
  String get mediaSettingsServiceGoneBody;

  /// No description provided for @mediaSettingsDelete.
  ///
  /// In zh, this message translates to:
  /// **'删除服务'**
  String get mediaSettingsDelete;

  /// No description provided for @mediaSettingsDeleteTitle.
  ///
  /// In zh, this message translates to:
  /// **'删除「{name}」？'**
  String mediaSettingsDeleteTitle(String name);

  /// No description provided for @mediaSettingsDeleteBody.
  ///
  /// In zh, this message translates to:
  /// **'只会从这台主机的设置里删掉这个服务，API Key 会保留；指向它的默认模型会一并清空。'**
  String get mediaSettingsDeleteBody;

  /// No description provided for @mediaSettingsNoImageModels.
  ///
  /// In zh, this message translates to:
  /// **'目录里还没有图像模型'**
  String get mediaSettingsNoImageModels;

  /// No description provided for @mediaSettingsNoAvailableService.
  ///
  /// In zh, this message translates to:
  /// **'还没有可用的服务（先添加并填好 Key）'**
  String get mediaSettingsNoAvailableService;

  /// No description provided for @mediaSettingsNoImageService.
  ///
  /// In zh, this message translates to:
  /// **'还没有可用的图像服务（先添加并填好 Key）'**
  String get mediaSettingsNoImageService;

  /// No description provided for @mediaSettingsNoVideoService.
  ///
  /// In zh, this message translates to:
  /// **'还没有可用的视频服务（先添加并填好 Key）'**
  String get mediaSettingsNoVideoService;

  /// No description provided for @mediaSettingsKeyExternal.
  ///
  /// In zh, this message translates to:
  /// **'由其它设置管理，这里只引用'**
  String get mediaSettingsKeyExternal;

  /// No description provided for @mediaSettingsEnabledHint.
  ///
  /// In zh, this message translates to:
  /// **'关闭后不再用这个服务生成'**
  String get mediaSettingsEnabledHint;

  /// No description provided for @nearbyThisChat.
  ///
  /// In zh, this message translates to:
  /// **'本对话'**
  String get nearbyThisChat;

  /// No description provided for @nearbyPermissionTitle.
  ///
  /// In zh, this message translates to:
  /// **'本对话的权限'**
  String get nearbyPermissionTitle;

  /// No description provided for @nearbyNewChatDefault.
  ///
  /// In zh, this message translates to:
  /// **'新对话默认：{name}'**
  String nearbyNewChatDefault(String name);

  /// No description provided for @nearbySetAsDefault.
  ///
  /// In zh, this message translates to:
  /// **'设为新对话默认'**
  String get nearbySetAsDefault;

  /// No description provided for @nearbyManageModels.
  ///
  /// In zh, this message translates to:
  /// **'管理模型'**
  String get nearbyManageModels;

  /// No description provided for @nearbyPermissionPill.
  ///
  /// In zh, this message translates to:
  /// **'本对话的权限：{name}'**
  String nearbyPermissionPill(String name);

  /// No description provided for @nearbyChange.
  ///
  /// In zh, this message translates to:
  /// **'更换'**
  String get nearbyChange;

  /// No description provided for @performanceTitle.
  ///
  /// In zh, this message translates to:
  /// **'性能'**
  String get performanceTitle;

  /// No description provided for @performanceAuto.
  ///
  /// In zh, this message translates to:
  /// **'自动'**
  String get performanceAuto;

  /// No description provided for @performanceFull.
  ///
  /// In zh, this message translates to:
  /// **'完整'**
  String get performanceFull;

  /// No description provided for @performanceLight.
  ///
  /// In zh, this message translates to:
  /// **'轻量'**
  String get performanceLight;

  /// No description provided for @performanceAutoHint.
  ///
  /// In zh, this message translates to:
  /// **'按设备调整默认效果'**
  String get performanceAutoHint;

  /// No description provided for @performanceFullHint.
  ///
  /// In zh, this message translates to:
  /// **'保留模糊与动效'**
  String get performanceFullHint;

  /// No description provided for @performanceLightHint.
  ///
  /// In zh, this message translates to:
  /// **'减少常驻效果和资源占用'**
  String get performanceLightHint;

  /// No description provided for @performanceChoiceHint.
  ///
  /// In zh, this message translates to:
  /// **'手动选择的宠物和引擎设置优先'**
  String get performanceChoiceHint;

  /// No description provided for @performanceCooling.
  ///
  /// In zh, this message translates to:
  /// **'正在减少效果，降温后恢复'**
  String get performanceCooling;

  /// No description provided for @performanceEffects.
  ///
  /// In zh, this message translates to:
  /// **'界面效果'**
  String get performanceEffects;

  /// No description provided for @performanceBlur.
  ///
  /// In zh, this message translates to:
  /// **'玻璃模糊'**
  String get performanceBlur;

  /// No description provided for @performanceAnimations.
  ///
  /// In zh, this message translates to:
  /// **'界面动效'**
  String get performanceAnimations;

  /// No description provided for @performanceSystemMotion.
  ///
  /// In zh, this message translates to:
  /// **'同时遵循系统的移除动画设置'**
  String get performanceSystemMotion;

  /// No description provided for @performanceFollowMode.
  ///
  /// In zh, this message translates to:
  /// **'效果跟随性能模式'**
  String get performanceFollowMode;

  /// No description provided for @performanceRemoteHint.
  ///
  /// In zh, this message translates to:
  /// **'推荐连接电脑或服务器，减少本机负担'**
  String get performanceRemoteHint;

  /// No description provided for @performanceRefresh.
  ///
  /// In zh, this message translates to:
  /// **'刷新率'**
  String get performanceRefresh;

  /// No description provided for @performanceRefreshMax.
  ///
  /// In zh, this message translates to:
  /// **'最高'**
  String get performanceRefreshMax;

  /// No description provided for @performanceRefreshSystem.
  ///
  /// In zh, this message translates to:
  /// **'系统'**
  String get performanceRefreshSystem;

  /// No description provided for @performanceRefreshHint.
  ///
  /// In zh, this message translates to:
  /// **'自动：动时用最高刷新率，停下交回系统；系统：完全由系统决定。'**
  String get performanceRefreshHint;

  /// No description provided for @searchKwRefreshRate.
  ///
  /// In zh, this message translates to:
  /// **'刷新率 高刷 120Hz 90Hz 流畅'**
  String get searchKwRefreshRate;

  /// No description provided for @petActionSending.
  ///
  /// In zh, this message translates to:
  /// **'正在发送…'**
  String get petActionSending;

  /// No description provided for @petActionTargetChanged.
  ///
  /// In zh, this message translates to:
  /// **'主机已变化，重新打开「问一句」；文字已保留'**
  String get petActionTargetChanged;

  /// No description provided for @petActionSendFailed.
  ///
  /// In zh, this message translates to:
  /// **'没能发出，文字已保留，请重试'**
  String get petActionSendFailed;

  /// No description provided for @petActionBusy.
  ///
  /// In zh, this message translates to:
  /// **'这个对话正在忙，请选择「新对话」'**
  String get petActionBusy;

  /// No description provided for @petActionVoiceMissing.
  ///
  /// In zh, this message translates to:
  /// **'先到 App 下载离线语音模型'**
  String get petActionVoiceMissing;

  /// No description provided for @petActionVoiceTitle.
  ///
  /// In zh, this message translates to:
  /// **'语音问一句'**
  String get petActionVoiceTitle;

  /// No description provided for @petActionVoiceReturn.
  ///
  /// In zh, this message translates to:
  /// **'返回桌宠'**
  String get petActionVoiceReturn;

  /// No description provided for @petActionVoiceStop.
  ///
  /// In zh, this message translates to:
  /// **'结束录音'**
  String get petActionVoiceStop;

  /// No description provided for @petActionVoiceStart.
  ///
  /// In zh, this message translates to:
  /// **'开始录音'**
  String get petActionVoiceStart;

  /// No description provided for @phoneDiagnosticsCollecting.
  ///
  /// In zh, this message translates to:
  /// **'正在收集…'**
  String get phoneDiagnosticsCollecting;

  /// No description provided for @phoneDiagnosticsPacking.
  ///
  /// In zh, this message translates to:
  /// **'正在打包…'**
  String get phoneDiagnosticsPacking;

  /// No description provided for @phoneDiagnosticsSharing.
  ///
  /// In zh, this message translates to:
  /// **'正在打开分享…'**
  String get phoneDiagnosticsSharing;

  /// No description provided for @phoneDiagnosticsSaving.
  ///
  /// In zh, this message translates to:
  /// **'正在存到「下载」…'**
  String get phoneDiagnosticsSaving;

  /// No description provided for @phoneDiagnosticsShare.
  ///
  /// In zh, this message translates to:
  /// **'分享诊断包'**
  String get phoneDiagnosticsShare;

  /// No description provided for @phoneDiagnosticsShareHint.
  ///
  /// In zh, this message translates to:
  /// **'附在问题反馈里'**
  String get phoneDiagnosticsShareHint;

  /// No description provided for @phoneDiagnosticsSave.
  ///
  /// In zh, this message translates to:
  /// **'存到「下载」'**
  String get phoneDiagnosticsSave;

  /// No description provided for @phoneDiagnosticsSaveHint.
  ///
  /// In zh, this message translates to:
  /// **'存进 下载/DSH-Go'**
  String get phoneDiagnosticsSaveHint;

  /// No description provided for @phoneDiagnosticsNote.
  ///
  /// In zh, this message translates to:
  /// **'含版本、设备、日志和最近一次崩溃，不含 Key 和令牌'**
  String get phoneDiagnosticsNote;

  /// No description provided for @phoneDiagnosticsExport.
  ///
  /// In zh, this message translates to:
  /// **'导出诊断包'**
  String get phoneDiagnosticsExport;

  /// No description provided for @phoneSafeMode.
  ///
  /// In zh, this message translates to:
  /// **'安全模式'**
  String get phoneSafeMode;

  /// No description provided for @phoneEngineStartingSafeEllipsis.
  ///
  /// In zh, this message translates to:
  /// **'正在以安全模式启动…'**
  String get phoneEngineStartingSafeEllipsis;

  /// No description provided for @phoneEngineStartingEllipsis.
  ///
  /// In zh, this message translates to:
  /// **'正在启动…'**
  String get phoneEngineStartingEllipsis;

  /// No description provided for @phoneEngineTidyingFilesEllipsis.
  ///
  /// In zh, this message translates to:
  /// **'正在整理插件文件…'**
  String get phoneEngineTidyingFilesEllipsis;

  /// No description provided for @phoneEngineStoppingEllipsis.
  ///
  /// In zh, this message translates to:
  /// **'正在停止…'**
  String get phoneEngineStoppingEllipsis;

  /// No description provided for @phoneEngineStoppedNextSafe.
  ///
  /// In zh, this message translates to:
  /// **'已停止 · 下次以安全模式启动'**
  String get phoneEngineStoppedNextSafe;

  /// No description provided for @phoneEngineInstallingRuntime.
  ///
  /// In zh, this message translates to:
  /// **'正在安装运行环境…'**
  String get phoneEngineInstallingRuntime;

  /// No description provided for @phoneEngineRuntimeNotInstalled.
  ///
  /// In zh, this message translates to:
  /// **'运行环境未安装'**
  String get phoneEngineRuntimeNotInstalled;

  /// No description provided for @phoneEngineErrorSeeLogs.
  ///
  /// In zh, this message translates to:
  /// **'引擎出错了，日志里有详情'**
  String get phoneEngineErrorSeeLogs;

  /// No description provided for @phoneEngineTitle.
  ///
  /// In zh, this message translates to:
  /// **'本机引擎'**
  String get phoneEngineTitle;

  /// No description provided for @phoneEngineLocal.
  ///
  /// In zh, this message translates to:
  /// **'本机引擎'**
  String get phoneEngineLocal;

  /// No description provided for @phoneEngineLogs.
  ///
  /// In zh, this message translates to:
  /// **'日志'**
  String get phoneEngineLogs;

  /// No description provided for @phoneEngineAutoStart.
  ///
  /// In zh, this message translates to:
  /// **'打开 App 时自动启动'**
  String get phoneEngineAutoStart;

  /// No description provided for @phoneEngineKeepAlive.
  ///
  /// In zh, this message translates to:
  /// **'后台运行'**
  String get phoneEngineKeepAlive;

  /// No description provided for @phoneEngineKeepAliveHint.
  ///
  /// In zh, this message translates to:
  /// **'防止引擎被系统结束'**
  String get phoneEngineKeepAliveHint;

  /// No description provided for @phoneEngineDiagnostics.
  ///
  /// In zh, this message translates to:
  /// **'诊断'**
  String get phoneEngineDiagnostics;

  /// No description provided for @phoneEngineDiagnosticsHint.
  ///
  /// In zh, this message translates to:
  /// **'运行信息与问题反馈'**
  String get phoneEngineDiagnosticsHint;

  /// No description provided for @phoneEngineRuntime.
  ///
  /// In zh, this message translates to:
  /// **'运行环境'**
  String get phoneEngineRuntime;

  /// No description provided for @phoneEngineArchitecture.
  ///
  /// In zh, this message translates to:
  /// **'架构'**
  String get phoneEngineArchitecture;

  /// No description provided for @phoneEngineStopTitle.
  ///
  /// In zh, this message translates to:
  /// **'停止引擎？'**
  String get phoneEngineStopTitle;

  /// No description provided for @phoneEngineStopBody.
  ///
  /// In zh, this message translates to:
  /// **'进行中的对话会中断，随时可以再启动。'**
  String get phoneEngineStopBody;

  /// No description provided for @phoneEngineInstallRuntime.
  ///
  /// In zh, this message translates to:
  /// **'安装运行环境'**
  String get phoneEngineInstallRuntime;

  /// No description provided for @phoneEngineStartAgain.
  ///
  /// In zh, this message translates to:
  /// **'重新启动'**
  String get phoneEngineStartAgain;

  /// No description provided for @phoneEngineStart.
  ///
  /// In zh, this message translates to:
  /// **'启动'**
  String get phoneEngineStart;

  /// No description provided for @phoneEngineRestart.
  ///
  /// In zh, this message translates to:
  /// **'重启'**
  String get phoneEngineRestart;

  /// No description provided for @phoneEngineResetFailed.
  ///
  /// In zh, this message translates to:
  /// **'没能重置'**
  String get phoneEngineResetFailed;

  /// No description provided for @phoneEngineReset.
  ///
  /// In zh, this message translates to:
  /// **'重置运行环境'**
  String get phoneEngineReset;

  /// No description provided for @phoneEngineResetHint.
  ///
  /// In zh, this message translates to:
  /// **'删除对话和文件后重新解压'**
  String get phoneEngineResetHint;

  /// No description provided for @phoneEngineResetTitle.
  ///
  /// In zh, this message translates to:
  /// **'重置运行环境？'**
  String get phoneEngineResetTitle;

  /// No description provided for @phoneEngineKeepUiSkills.
  ///
  /// In zh, this message translates to:
  /// **'保留界面配置和技能'**
  String get phoneEngineKeepUiSkills;

  /// No description provided for @phoneEngineKeepPluginsSettings.
  ///
  /// In zh, this message translates to:
  /// **'保留已装插件和设置'**
  String get phoneEngineKeepPluginsSettings;

  /// No description provided for @phoneEngineDeleteReset.
  ///
  /// In zh, this message translates to:
  /// **'删除并重置'**
  String get phoneEngineDeleteReset;

  /// No description provided for @phoneEngineNotInstalled.
  ///
  /// In zh, this message translates to:
  /// **'未安装'**
  String get phoneEngineNotInstalled;

  /// No description provided for @phoneEngineInstalling.
  ///
  /// In zh, this message translates to:
  /// **'正在安装'**
  String get phoneEngineInstalling;

  /// No description provided for @phoneEngineStoppedSafe.
  ///
  /// In zh, this message translates to:
  /// **'已停止 · 安全模式'**
  String get phoneEngineStoppedSafe;

  /// No description provided for @phoneEngineStartingSafe.
  ///
  /// In zh, this message translates to:
  /// **'正在以安全模式启动'**
  String get phoneEngineStartingSafe;

  /// No description provided for @phoneEngineStarting.
  ///
  /// In zh, this message translates to:
  /// **'正在启动'**
  String get phoneEngineStarting;

  /// No description provided for @phoneEngineTidyingFiles.
  ///
  /// In zh, this message translates to:
  /// **'正在整理插件文件'**
  String get phoneEngineTidyingFiles;

  /// No description provided for @phoneEngineRunningProbation.
  ///
  /// In zh, this message translates to:
  /// **'运行中 · 试用'**
  String get phoneEngineRunningProbation;

  /// No description provided for @phoneEngineStartupFailed.
  ///
  /// In zh, this message translates to:
  /// **'启动失败'**
  String get phoneEngineStartupFailed;

  /// No description provided for @phoneEngineCrashed.
  ///
  /// In zh, this message translates to:
  /// **'已崩溃'**
  String get phoneEngineCrashed;

  /// No description provided for @phoneEngineKilled.
  ///
  /// In zh, this message translates to:
  /// **'被系统结束'**
  String get phoneEngineKilled;

  /// No description provided for @phoneEngineError.
  ///
  /// In zh, this message translates to:
  /// **'出错了'**
  String get phoneEngineError;

  /// No description provided for @phoneEngineRuntimeCorrupt.
  ///
  /// In zh, this message translates to:
  /// **'App 内的运行环境包已损坏，请重新安装 App'**
  String get phoneEngineRuntimeCorrupt;

  /// No description provided for @phoneEngineExited.
  ///
  /// In zh, this message translates to:
  /// **'引擎意外退出了'**
  String get phoneEngineExited;

  /// No description provided for @phoneEngineRuntimeMissing.
  ///
  /// In zh, this message translates to:
  /// **'运行环境还没有安装'**
  String get phoneEngineRuntimeMissing;

  /// No description provided for @phoneEngineSafeUnsupported.
  ///
  /// In zh, this message translates to:
  /// **'这个版本的运行环境不支持安全模式，请更新 App'**
  String get phoneEngineSafeUnsupported;

  /// No description provided for @phoneEngineRuntimeIncomplete.
  ///
  /// In zh, this message translates to:
  /// **'App 内的运行环境包不完整，请重新安装 App'**
  String get phoneEngineRuntimeIncomplete;

  /// No description provided for @phoneLogEmpty.
  ///
  /// In zh, this message translates to:
  /// **'还没有日志'**
  String get phoneLogEmpty;

  /// No description provided for @phoneLogShareTitle.
  ///
  /// In zh, this message translates to:
  /// **'DSH 引擎日志'**
  String get phoneLogShareTitle;

  /// No description provided for @phoneLogCopyAll.
  ///
  /// In zh, this message translates to:
  /// **'复制全部'**
  String get phoneLogCopyAll;

  /// No description provided for @phoneBackgroundAllow.
  ///
  /// In zh, this message translates to:
  /// **'去放行'**
  String get phoneBackgroundAllow;

  /// No description provided for @phoneToolScreen.
  ///
  /// In zh, this message translates to:
  /// **'看屏幕'**
  String get phoneToolScreen;

  /// No description provided for @phoneToolCollect.
  ///
  /// In zh, this message translates to:
  /// **'滚动收集'**
  String get phoneToolCollect;

  /// No description provided for @phoneToolTap.
  ///
  /// In zh, this message translates to:
  /// **'点按'**
  String get phoneToolTap;

  /// No description provided for @phoneToolType.
  ///
  /// In zh, this message translates to:
  /// **'输入'**
  String get phoneToolType;

  /// No description provided for @phoneToolScroll.
  ///
  /// In zh, this message translates to:
  /// **'滑动'**
  String get phoneToolScroll;

  /// No description provided for @phoneToolKey.
  ///
  /// In zh, this message translates to:
  /// **'按键'**
  String get phoneToolKey;

  /// No description provided for @phoneToolTapCoordinates.
  ///
  /// In zh, this message translates to:
  /// **'点坐标'**
  String get phoneToolTapCoordinates;

  /// No description provided for @phoneToolHandoff.
  ///
  /// In zh, this message translates to:
  /// **'交还给你'**
  String get phoneToolHandoff;

  /// No description provided for @phoneToolOpenApp.
  ///
  /// In zh, this message translates to:
  /// **'打开 App'**
  String get phoneToolOpenApp;

  /// No description provided for @phoneToolListApps.
  ///
  /// In zh, this message translates to:
  /// **'查看应用'**
  String get phoneToolListApps;

  /// No description provided for @phoneToolIntent.
  ///
  /// In zh, this message translates to:
  /// **'系统动作'**
  String get phoneToolIntent;

  /// No description provided for @phoneToolNotify.
  ///
  /// In zh, this message translates to:
  /// **'发通知'**
  String get phoneToolNotify;

  /// No description provided for @phoneToolClipboard.
  ///
  /// In zh, this message translates to:
  /// **'剪贴板'**
  String get phoneToolClipboard;

  /// No description provided for @phoneToolAction.
  ///
  /// In zh, this message translates to:
  /// **'操作'**
  String get phoneToolAction;

  /// No description provided for @phoneDecisionContinued.
  ///
  /// In zh, this message translates to:
  /// **'你点了继续'**
  String get phoneDecisionContinued;

  /// No description provided for @phoneDecisionDone.
  ///
  /// In zh, this message translates to:
  /// **'已执行'**
  String get phoneDecisionDone;

  /// No description provided for @phoneDecisionAllowed.
  ///
  /// In zh, this message translates to:
  /// **'你允许了'**
  String get phoneDecisionAllowed;

  /// No description provided for @phoneDecisionPauseExpired.
  ///
  /// In zh, this message translates to:
  /// **'暂停太久'**
  String get phoneDecisionPauseExpired;

  /// No description provided for @phoneDecisionBlocked.
  ///
  /// In zh, this message translates to:
  /// **'已拦下'**
  String get phoneDecisionBlocked;

  /// No description provided for @phoneDecisionTimeout.
  ///
  /// In zh, this message translates to:
  /// **'超时'**
  String get phoneDecisionTimeout;

  /// No description provided for @phoneDecisionUnavailable.
  ///
  /// In zh, this message translates to:
  /// **'不可用'**
  String get phoneDecisionUnavailable;

  /// No description provided for @phoneDecisionScreenChanged.
  ///
  /// In zh, this message translates to:
  /// **'屏幕变了'**
  String get phoneDecisionScreenChanged;

  /// No description provided for @phoneDecisionFailed.
  ///
  /// In zh, this message translates to:
  /// **'没成功'**
  String get phoneDecisionFailed;

  /// No description provided for @phoneActionLogTitle.
  ///
  /// In zh, this message translates to:
  /// **'操作记录'**
  String get phoneActionLogTitle;

  /// No description provided for @phoneActionLogSubtitle.
  ///
  /// In zh, this message translates to:
  /// **'只记做了什么，不记屏幕内容'**
  String get phoneActionLogSubtitle;

  /// No description provided for @phoneActionLogRefresh.
  ///
  /// In zh, this message translates to:
  /// **'刷新'**
  String get phoneActionLogRefresh;

  /// No description provided for @phoneActionLogEmpty.
  ///
  /// In zh, this message translates to:
  /// **'还没有记录'**
  String get phoneActionLogEmpty;

  /// No description provided for @phoneActionLogEmptyHint.
  ///
  /// In zh, this message translates to:
  /// **'DSH 在手机上的每一步都会记在这里'**
  String get phoneActionLogEmptyHint;

  /// No description provided for @phoneAppRuleDeny.
  ///
  /// In zh, this message translates to:
  /// **'不碰'**
  String get phoneAppRuleDeny;

  /// No description provided for @phoneAppRuleConfirm.
  ///
  /// In zh, this message translates to:
  /// **'每一步都确认'**
  String get phoneAppRuleConfirm;

  /// No description provided for @phoneAppRuleNormal.
  ///
  /// In zh, this message translates to:
  /// **'照常'**
  String get phoneAppRuleNormal;

  /// No description provided for @phoneAppRuleDenyHint.
  ///
  /// In zh, this message translates to:
  /// **'不读也不点，银行、支付类默认如此'**
  String get phoneAppRuleDenyHint;

  /// No description provided for @phoneAppRuleConfirmHint.
  ///
  /// In zh, this message translates to:
  /// **'可以读，点按和输入前先问你'**
  String get phoneAppRuleConfirmHint;

  /// No description provided for @phoneAppRuleNormalHint.
  ///
  /// In zh, this message translates to:
  /// **'只有发送这类敏感操作先问你'**
  String get phoneAppRuleNormalHint;

  /// No description provided for @phoneAppRulesTitle.
  ///
  /// In zh, this message translates to:
  /// **'应用名单'**
  String get phoneAppRulesTitle;

  /// No description provided for @phoneAppRulesSubtitle.
  ///
  /// In zh, this message translates to:
  /// **'没列出的 App 照常处理，敏感操作仍先问你'**
  String get phoneAppRulesSubtitle;

  /// No description provided for @phoneAppRulesUnavailable.
  ///
  /// In zh, this message translates to:
  /// **'读不到应用名单'**
  String get phoneAppRulesUnavailable;

  /// No description provided for @phoneTryLater.
  ///
  /// In zh, this message translates to:
  /// **'稍后再试'**
  String get phoneTryLater;

  /// No description provided for @phoneAppRulesChanged.
  ///
  /// In zh, this message translates to:
  /// **'照常 · 你改过的'**
  String get phoneAppRulesChanged;

  /// No description provided for @phoneAppRulesAdd.
  ///
  /// In zh, this message translates to:
  /// **'添加 App'**
  String get phoneAppRulesAdd;

  /// No description provided for @phoneAppRulesAddHint.
  ///
  /// In zh, this message translates to:
  /// **'按包名添加'**
  String get phoneAppRulesAddHint;

  /// No description provided for @phoneSensitiveActionsNote.
  ///
  /// In zh, this message translates to:
  /// **'密码、验证码、付款和系统设置都由你来'**
  String get phoneSensitiveActionsNote;

  /// No description provided for @phoneAppRulesSaveFailed.
  ///
  /// In zh, this message translates to:
  /// **'没有保存成功，稍后再试'**
  String get phoneAppRulesSaveFailed;

  /// No description provided for @phoneAppRulesAcceptRisk.
  ///
  /// In zh, this message translates to:
  /// **'我知道风险，仍然修改'**
  String get phoneAppRulesAcceptRisk;

  /// No description provided for @phoneAppRulesPackage.
  ///
  /// In zh, this message translates to:
  /// **'包名'**
  String get phoneAppRulesPackage;

  /// No description provided for @phoneAppRulesPackageHint.
  ///
  /// In zh, this message translates to:
  /// **'在「设置 → 应用 → 应用信息」里能找到'**
  String get phoneAppRulesPackageHint;

  /// No description provided for @phoneDndRequiresAndroid.
  ///
  /// In zh, this message translates to:
  /// **'需要 Android 14 及以上'**
  String get phoneDndRequiresAndroid;

  /// No description provided for @phoneDndHiddenScreen.
  ///
  /// In zh, this message translates to:
  /// **'在看不见的屏幕上操作'**
  String get phoneDndHiddenScreen;

  /// No description provided for @phoneNotReadyYet.
  ///
  /// In zh, this message translates to:
  /// **'还没准备好'**
  String get phoneNotReadyYet;

  /// No description provided for @phoneActionFailedLater.
  ///
  /// In zh, this message translates to:
  /// **'没有成功，稍后再试'**
  String get phoneActionFailedLater;

  /// No description provided for @phoneDndDisabled.
  ///
  /// In zh, this message translates to:
  /// **'不打扰模式已关闭'**
  String get phoneDndDisabled;

  /// No description provided for @phoneDndEnabled.
  ///
  /// In zh, this message translates to:
  /// **'不打扰模式已启用'**
  String get phoneDndEnabled;

  /// No description provided for @phoneDndShizukuPermissionFailed.
  ///
  /// In zh, this message translates to:
  /// **'没有拿到授权。可以在 Shizuku 的「应用管理」里给 DSH Go 授权'**
  String get phoneDndShizukuPermissionFailed;

  /// No description provided for @phoneDndPairedConnect.
  ///
  /// In zh, this message translates to:
  /// **'配对成功，点「连接」'**
  String get phoneDndPairedConnect;

  /// No description provided for @phoneDndTitle.
  ///
  /// In zh, this message translates to:
  /// **'不打扰模式'**
  String get phoneDndTitle;

  /// No description provided for @phoneDndSubtitle.
  ///
  /// In zh, this message translates to:
  /// **'在看不见的屏幕上操作，不耽误你用手机'**
  String get phoneDndSubtitle;

  /// No description provided for @phoneDndUnsupported.
  ///
  /// In zh, this message translates to:
  /// **'这台手机用不了：需要 Android 14 及以上。'**
  String get phoneDndUnsupported;

  /// No description provided for @phoneDndRequirements.
  ///
  /// In zh, this message translates to:
  /// **'使用条件'**
  String get phoneDndRequirements;

  /// No description provided for @phoneDndKeepUnlocked.
  ///
  /// In zh, this message translates to:
  /// **'保持亮屏、解锁。'**
  String get phoneDndKeepUnlocked;

  /// No description provided for @phoneDndReactivate.
  ///
  /// In zh, this message translates to:
  /// **'重启手机后重新激活。'**
  String get phoneDndReactivate;

  /// No description provided for @phoneDndKeepDebugging.
  ///
  /// In zh, this message translates to:
  /// **'用 Shizuku 或自连 ADB 时，连接 Wi‑Fi 并保持无线调试开启。'**
  String get phoneDndKeepDebugging;

  /// No description provided for @phoneReady.
  ///
  /// In zh, this message translates to:
  /// **'可以用了'**
  String get phoneReady;

  /// No description provided for @phoneDndDirectAdb.
  ///
  /// In zh, this message translates to:
  /// **'自连 ADB'**
  String get phoneDndDirectAdb;

  /// No description provided for @phoneDndChannels.
  ///
  /// In zh, this message translates to:
  /// **'通道'**
  String get phoneDndChannels;

  /// No description provided for @phoneDndShizukuFor.
  ///
  /// In zh, this message translates to:
  /// **'装了 Shizuku App 的手机'**
  String get phoneDndShizukuFor;

  /// No description provided for @phoneDndSuiFor.
  ///
  /// In zh, this message translates to:
  /// **'Magisk 或 KernelSU 装了 Sui 模块'**
  String get phoneDndSuiFor;

  /// No description provided for @phoneDndRootFor.
  ///
  /// In zh, this message translates to:
  /// **'已 root 的手机'**
  String get phoneDndRootFor;

  /// No description provided for @phoneDndAdbFor.
  ///
  /// In zh, this message translates to:
  /// **'不装别的 App，用无线调试'**
  String get phoneDndAdbFor;

  /// No description provided for @phoneDndStateInUse.
  ///
  /// In zh, this message translates to:
  /// **'使用中'**
  String get phoneDndStateInUse;

  /// No description provided for @phoneDndStateNotReady.
  ///
  /// In zh, this message translates to:
  /// **'未就绪'**
  String get phoneDndStateNotReady;

  /// No description provided for @phoneDndStateUsable.
  ///
  /// In zh, this message translates to:
  /// **'可以用'**
  String get phoneDndStateUsable;

  /// No description provided for @phoneDndStateNeedsGrant.
  ///
  /// In zh, this message translates to:
  /// **'待授权'**
  String get phoneDndStateNeedsGrant;

  /// No description provided for @phoneDndStateNotRunning.
  ///
  /// In zh, this message translates to:
  /// **'未运行'**
  String get phoneDndStateNotRunning;

  /// No description provided for @phoneDndStateNotInstalled.
  ///
  /// In zh, this message translates to:
  /// **'未安装'**
  String get phoneDndStateNotInstalled;

  /// No description provided for @phoneDndStateNotFound.
  ///
  /// In zh, this message translates to:
  /// **'未检测到'**
  String get phoneDndStateNotFound;

  /// No description provided for @phoneDndStateViaSui.
  ///
  /// In zh, this message translates to:
  /// **'由 Sui 提供'**
  String get phoneDndStateViaSui;

  /// No description provided for @phoneDndStateWaiting.
  ///
  /// In zh, this message translates to:
  /// **'等待授权'**
  String get phoneDndStateWaiting;

  /// No description provided for @phoneDndStateDisconnected.
  ///
  /// In zh, this message translates to:
  /// **'未连接'**
  String get phoneDndStateDisconnected;

  /// No description provided for @phoneDndStateNotPaired.
  ///
  /// In zh, this message translates to:
  /// **'未配对'**
  String get phoneDndStateNotPaired;

  /// No description provided for @phoneDndShizukuViaSui.
  ///
  /// In zh, this message translates to:
  /// **'这台手机的 Shizuku 接口由 Sui 提供，请改用 Sui。'**
  String get phoneDndShizukuViaSui;

  /// No description provided for @phoneDndSuiMissing.
  ///
  /// In zh, this message translates to:
  /// **'没有检测到 Sui。在 Magisk 或 KernelSU 里装好 Sui 模块并重启手机，再回到这里。'**
  String get phoneDndSuiMissing;

  /// No description provided for @phoneDndSuiRunning.
  ///
  /// In zh, this message translates to:
  /// **'Sui 接口可用'**
  String get phoneDndSuiRunning;

  /// No description provided for @phoneDndSuiStopped.
  ///
  /// In zh, this message translates to:
  /// **'Sui 接口当前不可用。确认 Sui 模块已启用，重启手机后再试。'**
  String get phoneDndSuiStopped;

  /// No description provided for @phoneDndSuiAllSet.
  ///
  /// In zh, this message translates to:
  /// **'Sui 这边准备好了。'**
  String get phoneDndSuiAllSet;

  /// No description provided for @phoneDndSuiPermissionFailed.
  ///
  /// In zh, this message translates to:
  /// **'没能请求 Sui 授权。确认 Sui 模块已启用后再试。'**
  String get phoneDndSuiPermissionFailed;

  /// No description provided for @phoneDndRootWaiting.
  ///
  /// In zh, this message translates to:
  /// **'正在等待 root 授权，请在 root 管理器的弹窗里选择。'**
  String get phoneDndRootWaiting;

  /// No description provided for @phoneDndRootConnected.
  ///
  /// In zh, this message translates to:
  /// **'root 已连接。断开后要回到这里再选一次；打开上面的「保持 root 通道」，DSH Go 才会自己再去申请。'**
  String get phoneDndRootConnected;

  /// No description provided for @phoneDndRootConnectedKept.
  ///
  /// In zh, this message translates to:
  /// **'root 已连接。断开后 DSH Go 会自己向 root 管理器再次申请。'**
  String get phoneDndRootConnectedKept;

  /// No description provided for @phoneDndRootRetry.
  ///
  /// In zh, this message translates to:
  /// **'重新申请 root 授权'**
  String get phoneDndRootRetry;

  /// No description provided for @phoneDndInstallShizuku.
  ///
  /// In zh, this message translates to:
  /// **'先装 Shizuku（免费、开源）。已经在用冰箱、黑阈这类工具的话，多半已经装了。'**
  String get phoneDndInstallShizuku;

  /// No description provided for @phoneDndOpenShizukuSite.
  ///
  /// In zh, this message translates to:
  /// **'打开 Shizuku 官网'**
  String get phoneDndOpenShizukuSite;

  /// No description provided for @phoneDndStartShizuku.
  ///
  /// In zh, this message translates to:
  /// **'打开 Shizuku，按里面「通过无线调试启动」的说明做一遍（要连 Wi‑Fi）。回到这里会自动刷新。'**
  String get phoneDndStartShizuku;

  /// No description provided for @phoneDndGrantShizukuHint.
  ///
  /// In zh, this message translates to:
  /// **'Shizuku 已在运行，还要给 DSH Go 授权。'**
  String get phoneDndGrantShizukuHint;

  /// No description provided for @phoneDndGrantShizuku.
  ///
  /// In zh, this message translates to:
  /// **'授权给 DSH Go'**
  String get phoneDndGrantShizuku;

  /// No description provided for @phoneDndShizukuAllSet.
  ///
  /// In zh, this message translates to:
  /// **'Shizuku 这边准备好了。'**
  String get phoneDndShizukuAllSet;

  /// No description provided for @phoneDndShizukuInstalled.
  ///
  /// In zh, this message translates to:
  /// **'已安装 Shizuku'**
  String get phoneDndShizukuInstalled;

  /// No description provided for @phoneDndShizukuRunning.
  ///
  /// In zh, this message translates to:
  /// **'Shizuku 正在运行'**
  String get phoneDndShizukuRunning;

  /// No description provided for @phoneDndShizukuGranted.
  ///
  /// In zh, this message translates to:
  /// **'已授权给 DSH Go'**
  String get phoneDndShizukuGranted;

  /// No description provided for @phoneDndShizukuCompatibility.
  ///
  /// In zh, this message translates to:
  /// **'这版 Android 与官方版 Shizuku 存在兼容问题。'**
  String get phoneDndShizukuCompatibility;

  /// No description provided for @phoneDndWirelessDebuggingOn.
  ///
  /// In zh, this message translates to:
  /// **'无线调试已打开'**
  String get phoneDndWirelessDebuggingOn;

  /// No description provided for @phoneDndPaired.
  ///
  /// In zh, this message translates to:
  /// **'已配对'**
  String get phoneDndPaired;

  /// No description provided for @phoneDndConnected.
  ///
  /// In zh, this message translates to:
  /// **'已连接'**
  String get phoneDndConnected;

  /// No description provided for @phoneDndDeveloperOptionsStep.
  ///
  /// In zh, this message translates to:
  /// **'打开开发者选项：在「关于手机」里连点「版本号」7 次。小米在「我的设备 → 全部参数与信息」里点「OS 版本」，vivo 点「软件版本号」。'**
  String get phoneDndDeveloperOptionsStep;

  /// No description provided for @phoneDndWirelessDebuggingStep.
  ///
  /// In zh, this message translates to:
  /// **'在开发者选项里打开「无线调试」，要连着 Wi‑Fi。开发者选项一般在「系统」或「其他设置」里。'**
  String get phoneDndWirelessDebuggingStep;

  /// No description provided for @phoneDndStartPairingStep.
  ///
  /// In zh, this message translates to:
  /// **'回到这里点「开始配对」，DSH 会发一条通知。'**
  String get phoneDndStartPairingStep;

  /// No description provided for @phoneDndGetPairingCodeStep.
  ///
  /// In zh, this message translates to:
  /// **'在「无线调试」里点「使用配对码配对设备」，屏幕上会出现 6 位配对码。'**
  String get phoneDndGetPairingCodeStep;

  /// No description provided for @phoneDndEnterPairingCodeStep.
  ///
  /// In zh, this message translates to:
  /// **'下拉通知栏，把配对码填进 DSH 的通知。配对成功后点「连接」。'**
  String get phoneDndEnterPairingCodeStep;

  /// No description provided for @phoneDndStartPairing.
  ///
  /// In zh, this message translates to:
  /// **'开始配对'**
  String get phoneDndStartPairing;

  /// No description provided for @phoneDndPairingNotificationSent.
  ///
  /// In zh, this message translates to:
  /// **'通知已发出，去「无线调试」里拿配对码'**
  String get phoneDndPairingNotificationSent;

  /// No description provided for @phoneDndManualEntry.
  ///
  /// In zh, this message translates to:
  /// **'手动填写'**
  String get phoneDndManualEntry;

  /// No description provided for @phoneDndConnect.
  ///
  /// In zh, this message translates to:
  /// **'连接'**
  String get phoneDndConnect;

  /// No description provided for @phoneDndManualEntryHint.
  ///
  /// In zh, this message translates to:
  /// **'通知里没有输入框时，用「手动填写」'**
  String get phoneDndManualEntryHint;

  /// No description provided for @phoneDndXiaomiUsbHint.
  ///
  /// In zh, this message translates to:
  /// **'打开「USB 调试（安全设置）」需插入 SIM 卡并登录小米账号。'**
  String get phoneDndXiaomiUsbHint;

  /// No description provided for @phoneDndEnterCodeTitle.
  ///
  /// In zh, this message translates to:
  /// **'填写配对码'**
  String get phoneDndEnterCodeTitle;

  /// No description provided for @phoneDndCodeLabel.
  ///
  /// In zh, this message translates to:
  /// **'6 位配对码'**
  String get phoneDndCodeLabel;

  /// No description provided for @phoneDndPortLabel.
  ///
  /// In zh, this message translates to:
  /// **'端口（可不填）'**
  String get phoneDndPortLabel;

  /// No description provided for @phoneDndPortHint.
  ///
  /// In zh, this message translates to:
  /// **'配对码下面「IP 地址和端口」冒号后的数字'**
  String get phoneDndPortHint;

  /// No description provided for @phoneDndPair.
  ///
  /// In zh, this message translates to:
  /// **'配对'**
  String get phoneDndPair;

  /// No description provided for @phoneConfirmAsk.
  ///
  /// In zh, this message translates to:
  /// **'每次都询问'**
  String get phoneConfirmAsk;

  /// No description provided for @phoneConfirmTask.
  ///
  /// In zh, this message translates to:
  /// **'本任务免确认'**
  String get phoneConfirmTask;

  /// No description provided for @phoneConfirmAlways.
  ///
  /// In zh, this message translates to:
  /// **'始终免确认'**
  String get phoneConfirmAlways;

  /// No description provided for @phoneConfirmAskHint.
  ///
  /// In zh, this message translates to:
  /// **'进新 App、发送、删除、付款前先问你'**
  String get phoneConfirmAskHint;

  /// No description provided for @phoneConfirmTaskHint.
  ///
  /// In zh, this message translates to:
  /// **'每个任务只问一次'**
  String get phoneConfirmTaskHint;

  /// No description provided for @phoneConfirmAlwaysHint.
  ///
  /// In zh, this message translates to:
  /// **'从不询问，直接操作'**
  String get phoneConfirmAlwaysHint;

  /// No description provided for @phoneConfirmTitle.
  ///
  /// In zh, this message translates to:
  /// **'确认方式'**
  String get phoneConfirmTitle;

  /// No description provided for @phoneConfirmAlwaysTitle.
  ///
  /// In zh, this message translates to:
  /// **'始终免确认？'**
  String get phoneConfirmAlwaysTitle;

  /// No description provided for @phoneConfirmAlwaysBody.
  ///
  /// In zh, this message translates to:
  /// **'打开 App、点按、发送、删除都直接做，不再问你。'**
  String get phoneConfirmAlwaysBody;

  /// No description provided for @phoneConfirmSaveFailed.
  ///
  /// In zh, this message translates to:
  /// **'没改成，稍后再试'**
  String get phoneConfirmSaveFailed;

  /// No description provided for @phoneEnableFailed.
  ///
  /// In zh, this message translates to:
  /// **'没能开启，稍后再试'**
  String get phoneEnableFailed;

  /// No description provided for @phoneDisableFailed.
  ///
  /// In zh, this message translates to:
  /// **'没能关闭，稍后再试'**
  String get phoneDisableFailed;

  /// No description provided for @phoneEnabled.
  ///
  /// In zh, this message translates to:
  /// **'已开启'**
  String get phoneEnabled;

  /// No description provided for @phoneDisabled.
  ///
  /// In zh, this message translates to:
  /// **'已关闭'**
  String get phoneDisabled;

  /// No description provided for @phoneOpenAccessibilityFailed.
  ///
  /// In zh, this message translates to:
  /// **'打不开系统设置，请到「设置 → 无障碍」里找到 DSH'**
  String get phoneOpenAccessibilityFailed;

  /// No description provided for @phoneOpenAppInfoFailed.
  ///
  /// In zh, this message translates to:
  /// **'打不开应用信息，请到「设置 → 应用」里找到 DSH Go'**
  String get phoneOpenAppInfoFailed;

  /// No description provided for @phoneStopFailed.
  ///
  /// In zh, this message translates to:
  /// **'没能停止，可以点悬浮条或通知上的「停止」'**
  String get phoneStopFailed;

  /// No description provided for @phoneControlTitle.
  ///
  /// In zh, this message translates to:
  /// **'手机操控'**
  String get phoneControlTitle;

  /// No description provided for @phoneControlSubtitle.
  ///
  /// In zh, this message translates to:
  /// **'看屏幕、帮你点按，随时可以停'**
  String get phoneControlSubtitle;

  /// No description provided for @phoneControlWorking.
  ///
  /// In zh, this message translates to:
  /// **'正在操作手机'**
  String get phoneControlWorking;

  /// No description provided for @phoneControlTaskNoConfirmHint.
  ///
  /// In zh, this message translates to:
  /// **'本任务免确认 · 悬浮条上也能暂停或停止'**
  String get phoneControlTaskNoConfirmHint;

  /// No description provided for @phoneControlFloatingBarHint.
  ///
  /// In zh, this message translates to:
  /// **'悬浮条上也能暂停或停止'**
  String get phoneControlFloatingBarHint;

  /// No description provided for @phoneControlAdvanced.
  ///
  /// In zh, this message translates to:
  /// **'进阶'**
  String get phoneControlAdvanced;

  /// No description provided for @phoneControlKeepAliveHint.
  ///
  /// In zh, this message translates to:
  /// **'防止系统关掉无障碍'**
  String get phoneControlKeepAliveHint;

  /// No description provided for @phoneControlReadingEllipsis.
  ///
  /// In zh, this message translates to:
  /// **'正在读取…'**
  String get phoneControlReadingEllipsis;

  /// No description provided for @phoneControlNotReady.
  ///
  /// In zh, this message translates to:
  /// **'未就绪'**
  String get phoneControlNotReady;

  /// No description provided for @phoneControlNotEnabled.
  ///
  /// In zh, this message translates to:
  /// **'未开启'**
  String get phoneControlNotEnabled;

  /// No description provided for @phoneControlSafeModeNotLoaded.
  ///
  /// In zh, this message translates to:
  /// **'安全模式下不加载'**
  String get phoneControlSafeModeNotLoaded;

  /// No description provided for @phoneControlLocalOnly.
  ///
  /// In zh, this message translates to:
  /// **'只在本机引擎可用'**
  String get phoneControlLocalOnly;

  /// No description provided for @phoneControlAfterEngineStarts.
  ///
  /// In zh, this message translates to:
  /// **'引擎启动后生效'**
  String get phoneControlAfterEngineStarts;

  /// No description provided for @phoneControlNeedsAccessibility.
  ///
  /// In zh, this message translates to:
  /// **'还差一步：打开无障碍'**
  String get phoneControlNeedsAccessibility;

  /// No description provided for @phoneControlReady.
  ///
  /// In zh, this message translates to:
  /// **'可以操作手机'**
  String get phoneControlReady;

  /// No description provided for @phoneControlSetup.
  ///
  /// In zh, this message translates to:
  /// **'准备'**
  String get phoneControlSetup;

  /// No description provided for @phoneControlAccessibilityService.
  ///
  /// In zh, this message translates to:
  /// **'无障碍服务'**
  String get phoneControlAccessibilityService;

  /// No description provided for @phoneControlAccessibilityReady.
  ///
  /// In zh, this message translates to:
  /// **'能看屏幕、帮你点按了'**
  String get phoneControlAccessibilityReady;

  /// No description provided for @phoneControlAccessibilityReconnect.
  ///
  /// In zh, this message translates to:
  /// **'服务没连上，关掉再打开一次'**
  String get phoneControlAccessibilityReconnect;

  /// No description provided for @phoneControlAccessibilityHint.
  ///
  /// In zh, this message translates to:
  /// **'看屏幕和点按都靠它'**
  String get phoneControlAccessibilityHint;

  /// No description provided for @phoneControlGoSettings.
  ///
  /// In zh, this message translates to:
  /// **'去设置'**
  String get phoneControlGoSettings;

  /// No description provided for @phoneControlGoEnable.
  ///
  /// In zh, this message translates to:
  /// **'去开启'**
  String get phoneControlGoEnable;

  /// No description provided for @phoneControlAccessibilityBlocked.
  ///
  /// In zh, this message translates to:
  /// **'无障碍开关点不动？'**
  String get phoneControlAccessibilityBlocked;

  /// No description provided for @phoneControlRestrictedAfterAttempt.
  ///
  /// In zh, this message translates to:
  /// **'看起来没开成。侧载的 App 要先「允许受限制的设置」'**
  String get phoneControlRestrictedAfterAttempt;

  /// No description provided for @phoneControlRestrictedHint.
  ///
  /// In zh, this message translates to:
  /// **'侧载安装的 App 要先「允许受限制的设置」'**
  String get phoneControlRestrictedHint;

  /// No description provided for @phoneControlNotifications.
  ///
  /// In zh, this message translates to:
  /// **'通知'**
  String get phoneControlNotifications;

  /// No description provided for @phoneControlNotificationsPairingHint.
  ///
  /// In zh, this message translates to:
  /// **'确认、停止和配对码都走通知'**
  String get phoneControlNotificationsPairingHint;

  /// No description provided for @phoneControlNotificationsHint.
  ///
  /// In zh, this message translates to:
  /// **'确认和「停止」按钮要用到'**
  String get phoneControlNotificationsHint;

  /// No description provided for @phoneControlAllowed.
  ///
  /// In zh, this message translates to:
  /// **'已允许'**
  String get phoneControlAllowed;

  /// No description provided for @phoneControlTry.
  ///
  /// In zh, this message translates to:
  /// **'试一下'**
  String get phoneControlTry;

  /// No description provided for @phoneControlReadScreen.
  ///
  /// In zh, this message translates to:
  /// **'读一下当前屏幕'**
  String get phoneControlReadScreen;

  /// No description provided for @phoneControlReadScreenHint.
  ///
  /// In zh, this message translates to:
  /// **'看看 DSH 读到了什么，不发给模型'**
  String get phoneControlReadScreenHint;

  /// No description provided for @phoneControlEnableAccessibilityFirst.
  ///
  /// In zh, this message translates to:
  /// **'先打开无障碍服务'**
  String get phoneControlEnableAccessibilityFirst;

  /// No description provided for @phoneControlLoading.
  ///
  /// In zh, this message translates to:
  /// **'读取中'**
  String get phoneControlLoading;

  /// No description provided for @phoneControlRules.
  ///
  /// In zh, this message translates to:
  /// **'规则'**
  String get phoneControlRules;

  /// No description provided for @phoneControlRecentActions.
  ///
  /// In zh, this message translates to:
  /// **'最近操作'**
  String get phoneControlRecentActions;

  /// No description provided for @phoneControlRecentActionsHint.
  ///
  /// In zh, this message translates to:
  /// **'每一步都会记下，不含屏幕内容'**
  String get phoneControlRecentActionsHint;

  /// No description provided for @phoneControlAllActions.
  ///
  /// In zh, this message translates to:
  /// **'全部记录'**
  String get phoneControlAllActions;

  /// No description provided for @phoneControlModuleNotReady.
  ///
  /// In zh, this message translates to:
  /// **'这个版本里，手机操控模块还没有就绪'**
  String get phoneControlModuleNotReady;

  /// No description provided for @phoneControlSafeModeUnavailable.
  ///
  /// In zh, this message translates to:
  /// **'安全模式下不可用'**
  String get phoneControlSafeModeUnavailable;

  /// No description provided for @phoneControlSafeModeHint.
  ///
  /// In zh, this message translates to:
  /// **'安全模式不加载插件，恢复正常模式后可用'**
  String get phoneControlSafeModeHint;

  /// No description provided for @phoneControlRemoteHost.
  ///
  /// In zh, this message translates to:
  /// **'当前连的是远程主机'**
  String get phoneControlRemoteHost;

  /// No description provided for @phoneControlCapabilities.
  ///
  /// In zh, this message translates to:
  /// **'开启后能做什么'**
  String get phoneControlCapabilities;

  /// No description provided for @phoneControlIntents.
  ///
  /// In zh, this message translates to:
  /// **'定闹钟、建日程、导航、分享'**
  String get phoneControlIntents;

  /// No description provided for @phoneControlNoExtraPermissions.
  ///
  /// In zh, this message translates to:
  /// **'不用额外权限'**
  String get phoneControlNoExtraPermissions;

  /// No description provided for @phoneControlReadToTable.
  ///
  /// In zh, this message translates to:
  /// **'读屏幕，整理成表格或待办'**
  String get phoneControlReadToTable;

  /// No description provided for @phoneControlNeedsAccessibilityHint.
  ///
  /// In zh, this message translates to:
  /// **'需要打开无障碍'**
  String get phoneControlNeedsAccessibilityHint;

  /// No description provided for @phoneControlTapType.
  ///
  /// In zh, this message translates to:
  /// **'帮你点按、输入'**
  String get phoneControlTapType;

  /// No description provided for @phoneControlSensitiveHint.
  ///
  /// In zh, this message translates to:
  /// **'发送、下单前先问你，付款由你来'**
  String get phoneControlSensitiveHint;

  /// No description provided for @phoneDisclosureWhatTitle.
  ///
  /// In zh, this message translates to:
  /// **'读什么'**
  String get phoneDisclosureWhatTitle;

  /// No description provided for @phoneDisclosureWhatBody.
  ///
  /// In zh, this message translates to:
  /// **'当前屏幕上的文字。用能看图的模型时，可能附一张截图。'**
  String get phoneDisclosureWhatBody;

  /// No description provided for @phoneDisclosureWhenTitle.
  ///
  /// In zh, this message translates to:
  /// **'什么时候读'**
  String get phoneDisclosureWhenTitle;

  /// No description provided for @phoneDisclosureWhenBody.
  ///
  /// In zh, this message translates to:
  /// **'只在你发起任务，或点「读一下当前屏幕」时。平时不读。'**
  String get phoneDisclosureWhenBody;

  /// No description provided for @phoneDisclosureWhoTitle.
  ///
  /// In zh, this message translates to:
  /// **'发给谁'**
  String get phoneDisclosureWhoTitle;

  /// No description provided for @phoneDisclosureWhoBody.
  ///
  /// In zh, this message translates to:
  /// **'发给你选的 DeepSeek 模型（云端）。银行卡号、身份证号会先打码。'**
  String get phoneDisclosureWhoBody;

  /// No description provided for @phoneDisclosureNeverTitle.
  ///
  /// In zh, this message translates to:
  /// **'默认不做'**
  String get phoneDisclosureNeverTitle;

  /// No description provided for @phoneDisclosureNeverBody.
  ///
  /// In zh, this message translates to:
  /// **'不输密码和验证码，不改系统设置，遇到就交还给你。银行、支付类 App 也不碰。'**
  String get phoneDisclosureNeverBody;

  /// No description provided for @phoneDisclosureStopTitle.
  ///
  /// In zh, this message translates to:
  /// **'你随时能停'**
  String get phoneDisclosureStopTitle;

  /// No description provided for @phoneDisclosureStopBody.
  ///
  /// In zh, this message translates to:
  /// **'操作时屏幕上有悬浮条，可以暂停、停止或插话。手机要亮屏、解锁。'**
  String get phoneDisclosureStopBody;

  /// No description provided for @phoneDisclosureTitle.
  ///
  /// In zh, this message translates to:
  /// **'开启手机操控前'**
  String get phoneDisclosureTitle;

  /// No description provided for @phoneDisclosureIntro.
  ///
  /// In zh, this message translates to:
  /// **'DSH 会像你一样看屏幕、点按，帮你把事办完。开启前，先了解这几点：'**
  String get phoneDisclosureIntro;

  /// No description provided for @phoneDisclosureRestartNote.
  ///
  /// In zh, this message translates to:
  /// **'开启后引擎会重启一次，进行中的回复会中断'**
  String get phoneDisclosureRestartNote;

  /// No description provided for @phoneDisclosureNotNow.
  ///
  /// In zh, this message translates to:
  /// **'先不开'**
  String get phoneDisclosureNotNow;

  /// No description provided for @phoneDisclosureAgreeEnable.
  ///
  /// In zh, this message translates to:
  /// **'同意并开启'**
  String get phoneDisclosureAgreeEnable;

  /// No description provided for @phoneCheckUnknown.
  ///
  /// In zh, this message translates to:
  /// **'不确定'**
  String get phoneCheckUnknown;

  /// No description provided for @phoneCheckYes.
  ///
  /// In zh, this message translates to:
  /// **'是'**
  String get phoneCheckYes;

  /// No description provided for @phoneCheckNotYet.
  ///
  /// In zh, this message translates to:
  /// **'还没有'**
  String get phoneCheckNotYet;

  /// No description provided for @phoneRomStock.
  ///
  /// In zh, this message translates to:
  /// **'原生 / 其他'**
  String get phoneRomStock;

  /// No description provided for @phoneRestrictedAccessibility.
  ///
  /// In zh, this message translates to:
  /// **'无障碍'**
  String get phoneRestrictedAccessibility;

  /// No description provided for @phoneRestrictedOpenAccessibility.
  ///
  /// In zh, this message translates to:
  /// **'去开无障碍'**
  String get phoneRestrictedOpenAccessibility;

  /// No description provided for @phoneRestrictedOverlay.
  ///
  /// In zh, this message translates to:
  /// **'悬浮窗'**
  String get phoneRestrictedOverlay;

  /// No description provided for @phoneRestrictedOpenOverlay.
  ///
  /// In zh, this message translates to:
  /// **'去开悬浮窗'**
  String get phoneRestrictedOpenOverlay;

  /// No description provided for @phoneRestrictedTryAccessibility.
  ///
  /// In zh, this message translates to:
  /// **'先去「无障碍」里点一次 DSH 的开关，看到「受限制的设置」提示后点「确定」。做过这一步，下面的选项才会出现。'**
  String get phoneRestrictedTryAccessibility;

  /// No description provided for @phoneRestrictedOpenInfoStep.
  ///
  /// In zh, this message translates to:
  /// **'回到这里，点「打开应用信息」。'**
  String get phoneRestrictedOpenInfoStep;

  /// No description provided for @phoneRestrictedBackAccessibility.
  ///
  /// In zh, this message translates to:
  /// **'回到「无障碍」，打开 DSH。'**
  String get phoneRestrictedBackAccessibility;

  /// No description provided for @phoneRestrictedMenuStep.
  ///
  /// In zh, this message translates to:
  /// **'点右上角的三个点，选「允许受限制的设置」，按提示验证锁屏密码。'**
  String get phoneRestrictedMenuStep;

  /// No description provided for @phoneRestrictedTryOverlay.
  ///
  /// In zh, this message translates to:
  /// **'先去「悬浮窗」设置里点一次 DSH Go 的开关，看到「受限制的设置」提示后点「确定」。做过这一步，下面的选项才会出现。'**
  String get phoneRestrictedTryOverlay;

  /// No description provided for @phoneRestrictedBackOverlay.
  ///
  /// In zh, this message translates to:
  /// **'回到「悬浮窗」设置，打开 DSH Go。'**
  String get phoneRestrictedBackOverlay;

  /// No description provided for @phoneRestrictedHuaweiOverlay.
  ///
  /// In zh, this message translates to:
  /// **'华为 HarmonyOS 4 及更早的系统大多没有这一步，直接去「悬浮窗」设置打开 DSH Go。'**
  String get phoneRestrictedHuaweiOverlay;

  /// No description provided for @phoneRestrictedHuaweiAccessibility.
  ///
  /// In zh, this message translates to:
  /// **'华为 HarmonyOS 4 及更早的系统大多没有这一步，直接去「无障碍」打开 DSH。'**
  String get phoneRestrictedHuaweiAccessibility;

  /// No description provided for @phoneRestrictedVivoNote.
  ///
  /// In zh, this message translates to:
  /// **'不同 OriginOS 版本位置可能不同。右上角没有三个点时，把应用信息页往下翻到底找一找。'**
  String get phoneRestrictedVivoNote;

  /// No description provided for @phoneRestrictedAdvancedStep.
  ///
  /// In zh, this message translates to:
  /// **'在「高级设置」里找到「允许受限制的设置」，打开它。'**
  String get phoneRestrictedAdvancedStep;

  /// No description provided for @phoneRestrictedOppoNote.
  ///
  /// In zh, this message translates to:
  /// **'ColorOS 有时找不到这个选项。这时用系统自带的「文件管理」找到 DSH 的安装包，点它覆盖安装一次（不用卸载，对话和设置都在），再去开无障碍。'**
  String get phoneRestrictedOppoNote;

  /// No description provided for @phoneRestrictedHuaweiNote.
  ///
  /// In zh, this message translates to:
  /// **'如果在无障碍里看到「受限制的设置」提示，按「原生 / 其他」的步骤做。'**
  String get phoneRestrictedHuaweiNote;

  /// No description provided for @phoneRestrictedTitle.
  ///
  /// In zh, this message translates to:
  /// **'允许受限制的设置'**
  String get phoneRestrictedTitle;

  /// No description provided for @phoneRestrictedSteps.
  ///
  /// In zh, this message translates to:
  /// **'步骤'**
  String get phoneRestrictedSteps;

  /// No description provided for @phoneRestrictedDiagram.
  ///
  /// In zh, this message translates to:
  /// **'图示'**
  String get phoneRestrictedDiagram;

  /// No description provided for @phoneRestrictedOpenInfo.
  ///
  /// In zh, this message translates to:
  /// **'打开应用信息'**
  String get phoneRestrictedOpenInfo;

  /// No description provided for @phoneRestrictedOpenOverlayFailed.
  ///
  /// In zh, this message translates to:
  /// **'打不开悬浮窗设置，请到「设置」里搜索「悬浮窗」'**
  String get phoneRestrictedOpenOverlayFailed;

  /// No description provided for @phoneRestrictedOpenAccessibilityFailed.
  ///
  /// In zh, this message translates to:
  /// **'打不开无障碍设置，请到「设置」里搜索「无障碍」'**
  String get phoneRestrictedOpenAccessibilityFailed;

  /// No description provided for @phoneRestrictedFootnote.
  ///
  /// In zh, this message translates to:
  /// **'名称因系统而异，找不到就在设置里搜「受限制」；仍打不开时重启手机再试'**
  String get phoneRestrictedFootnote;

  /// No description provided for @phoneRestrictedAppInfo.
  ///
  /// In zh, this message translates to:
  /// **'应用信息'**
  String get phoneRestrictedAppInfo;

  /// No description provided for @phoneRestrictedPermissionsManager.
  ///
  /// In zh, this message translates to:
  /// **'权限管理'**
  String get phoneRestrictedPermissionsManager;

  /// No description provided for @phoneRestrictedBatterySaver.
  ///
  /// In zh, this message translates to:
  /// **'省电策略'**
  String get phoneRestrictedBatterySaver;

  /// No description provided for @phoneRestrictedAdvanced.
  ///
  /// In zh, this message translates to:
  /// **'高级设置'**
  String get phoneRestrictedAdvanced;

  /// No description provided for @phoneRestrictedPermissions.
  ///
  /// In zh, this message translates to:
  /// **'权限'**
  String get phoneRestrictedPermissions;

  /// No description provided for @phoneRestrictedBattery.
  ///
  /// In zh, this message translates to:
  /// **'电池'**
  String get phoneRestrictedBattery;

  /// No description provided for @phoneRestrictedDiagramAdvanced.
  ///
  /// In zh, this message translates to:
  /// **'图示：应用信息页里点「高级设置」，再打开「允许受限制的设置」'**
  String get phoneRestrictedDiagramAdvanced;

  /// No description provided for @phoneRestrictedDiagramMenu.
  ///
  /// In zh, this message translates to:
  /// **'图示：应用信息页点右上角三个点，再选「允许受限制的设置」'**
  String get phoneRestrictedDiagramMenu;

  /// No description provided for @phoneRestrictedCaptionAdvanced.
  ///
  /// In zh, this message translates to:
  /// **'① 点「高级设置」'**
  String get phoneRestrictedCaptionAdvanced;

  /// No description provided for @phoneRestrictedCaptionMenu.
  ///
  /// In zh, this message translates to:
  /// **'① 点右上角三个点'**
  String get phoneRestrictedCaptionMenu;

  /// No description provided for @phoneRestrictedCaptionToggle.
  ///
  /// In zh, this message translates to:
  /// **'② 打开这个开关'**
  String get phoneRestrictedCaptionToggle;

  /// No description provided for @phoneRestrictedCaptionOption.
  ///
  /// In zh, this message translates to:
  /// **'② 选这一项'**
  String get phoneRestrictedCaptionOption;

  /// No description provided for @phoneScreenReadFailed.
  ///
  /// In zh, this message translates to:
  /// **'没能读到屏幕'**
  String get phoneScreenReadFailed;

  /// No description provided for @phoneScreenUnknownReason.
  ///
  /// In zh, this message translates to:
  /// **'原因不明'**
  String get phoneScreenUnknownReason;

  /// No description provided for @phoneScreenReadFailedHint.
  ///
  /// In zh, this message translates to:
  /// **'确认无障碍已开启。密码、支付这类页面系统不让读'**
  String get phoneScreenReadFailedHint;

  /// No description provided for @phoneScreenCurrent.
  ///
  /// In zh, this message translates to:
  /// **'当前屏幕'**
  String get phoneScreenCurrent;

  /// No description provided for @phoneScreenEmpty.
  ///
  /// In zh, this message translates to:
  /// **'（屏幕上没有可读的文字）'**
  String get phoneScreenEmpty;

  /// No description provided for @phoneScreenReadNote.
  ///
  /// In zh, this message translates to:
  /// **'模型看到的就是这些文字，这次读取没有发给模型'**
  String get phoneScreenReadNote;

  /// No description provided for @phoneFailureSafeStartup.
  ///
  /// In zh, this message translates to:
  /// **'安全模式也没能启动'**
  String get phoneFailureSafeStartup;

  /// No description provided for @phoneFailureSafeStartupHint.
  ///
  /// In zh, this message translates to:
  /// **'问题多半在全局配置或运行环境'**
  String get phoneFailureSafeStartupHint;

  /// No description provided for @phoneFailureKilled.
  ///
  /// In zh, this message translates to:
  /// **'引擎被系统结束了'**
  String get phoneFailureKilled;

  /// No description provided for @phoneFailureKilledHint.
  ///
  /// In zh, this message translates to:
  /// **'多半是内存不足或系统省电'**
  String get phoneFailureKilledHint;

  /// No description provided for @phoneFailureLaunch.
  ///
  /// In zh, this message translates to:
  /// **'本机运行环境未能启动'**
  String get phoneFailureLaunch;

  /// No description provided for @phoneFailureLaunchHint.
  ///
  /// In zh, this message translates to:
  /// **'查看日志了解原因，或连接远程主机继续使用'**
  String get phoneFailureLaunchHint;

  /// No description provided for @phoneFailureNoSpaceHint.
  ///
  /// In zh, this message translates to:
  /// **'清理一些空间后重试'**
  String get phoneFailureNoSpaceHint;

  /// No description provided for @phoneFailureStartup.
  ///
  /// In zh, this message translates to:
  /// **'DSH 启动失败'**
  String get phoneFailureStartup;

  /// No description provided for @phoneFailureCrashedEarly.
  ///
  /// In zh, this message translates to:
  /// **'DSH 启动后很快崩溃了'**
  String get phoneFailureCrashedEarly;

  /// No description provided for @phoneFailureCrashedLate.
  ///
  /// In zh, this message translates to:
  /// **'DSH 运行中崩溃了'**
  String get phoneFailureCrashedLate;

  /// No description provided for @phoneFailureFatal.
  ///
  /// In zh, this message translates to:
  /// **'引擎报告了致命错误'**
  String get phoneFailureFatal;

  /// No description provided for @phoneFailureRestore.
  ///
  /// In zh, this message translates to:
  /// **'恢复配置'**
  String get phoneFailureRestore;

  /// No description provided for @phoneFailureEnterSafe.
  ///
  /// In zh, this message translates to:
  /// **'进入安全模式'**
  String get phoneFailureEnterSafe;

  /// No description provided for @phoneFailureStartNormal.
  ///
  /// In zh, this message translates to:
  /// **'正常启动'**
  String get phoneFailureStartNormal;

  /// No description provided for @phoneFailureGlobalPatch.
  ///
  /// In zh, this message translates to:
  /// **'全局补丁'**
  String get phoneFailureGlobalPatch;

  /// No description provided for @phoneFailureEnvironment.
  ///
  /// In zh, this message translates to:
  /// **'环境变量'**
  String get phoneFailureEnvironment;

  /// No description provided for @phoneSafeMoveAsideTitle.
  ///
  /// In zh, this message translates to:
  /// **'先移开这些文件？'**
  String get phoneSafeMoveAsideTitle;

  /// No description provided for @phoneSafeMoveAsideIntro.
  ///
  /// In zh, this message translates to:
  /// **'它们对所有配置都生效，安全模式也会受影响：'**
  String get phoneSafeMoveAsideIntro;

  /// No description provided for @phoneSafeMoveAsideNote.
  ///
  /// In zh, this message translates to:
  /// **'只是改名（加上 .off-时间），不会删除，修好后可以改回来。'**
  String get phoneSafeMoveAsideNote;

  /// No description provided for @phoneSafeStartDirectly.
  ///
  /// In zh, this message translates to:
  /// **'直接启动'**
  String get phoneSafeStartDirectly;

  /// No description provided for @phoneSafeMoveAsideStart.
  ///
  /// In zh, this message translates to:
  /// **'移开并启动'**
  String get phoneSafeMoveAsideStart;

  /// No description provided for @phoneSafeNoRestoreNeeded.
  ///
  /// In zh, this message translates to:
  /// **'配置和上次正常时一样，无需恢复'**
  String get phoneSafeNoRestoreNeeded;

  /// No description provided for @phoneSafeNoRestoreRecord.
  ///
  /// In zh, this message translates to:
  /// **'还没有正常运行过的配置记录'**
  String get phoneSafeNoRestoreRecord;

  /// No description provided for @phoneSafeRestoreTitle.
  ///
  /// In zh, this message translates to:
  /// **'恢复上次正常的配置？'**
  String get phoneSafeRestoreTitle;

  /// No description provided for @phoneSafeRestoreStart.
  ///
  /// In zh, this message translates to:
  /// **'恢复并启动'**
  String get phoneSafeRestoreStart;

  /// No description provided for @phoneSafeRestoredStarting.
  ///
  /// In zh, this message translates to:
  /// **'已恢复上次正常的配置，正在启动…'**
  String get phoneSafeRestoredStarting;

  /// No description provided for @phoneSafeRestoreFailed.
  ///
  /// In zh, this message translates to:
  /// **'没能恢复'**
  String get phoneSafeRestoreFailed;

  /// No description provided for @phoneSafeRestoreIntro.
  ///
  /// In zh, this message translates to:
  /// **'DSH 会回到上次正常运行时的配置：'**
  String get phoneSafeRestoreIntro;

  /// No description provided for @phoneSafeRestoreSettings.
  ///
  /// In zh, this message translates to:
  /// **'• 设置恢复到当时的版本（现在的另存为备份）'**
  String get phoneSafeRestoreSettings;

  /// No description provided for @phoneSafeRestoreNote.
  ///
  /// In zh, this message translates to:
  /// **'不会卸载任何插件，也不需要联网。停用的插件以后可以重新打开。'**
  String get phoneSafeRestoreNote;

  /// No description provided for @phoneSafeLeaveTitle.
  ///
  /// In zh, this message translates to:
  /// **'恢复正常模式？'**
  String get phoneSafeLeaveTitle;

  /// No description provided for @phoneSafeLeaveBody.
  ///
  /// In zh, this message translates to:
  /// **'用原来的配置和插件启动。安全模式期间改的网页版设置不会保留。'**
  String get phoneSafeLeaveBody;

  /// No description provided for @phoneSafeLeave.
  ///
  /// In zh, this message translates to:
  /// **'恢复正常模式'**
  String get phoneSafeLeave;

  /// No description provided for @phoneSafeMovePatch.
  ///
  /// In zh, this message translates to:
  /// **'移开补丁'**
  String get phoneSafeMovePatch;

  /// No description provided for @phoneSafeMoveFiles.
  ///
  /// In zh, this message translates to:
  /// **'移开文件'**
  String get phoneSafeMoveFiles;

  /// No description provided for @phoneSafeFailureLog.
  ///
  /// In zh, this message translates to:
  /// **'失败前后的日志'**
  String get phoneSafeFailureLog;

  /// No description provided for @phoneSafeFailureLogEmpty.
  ///
  /// In zh, this message translates to:
  /// **'没有记录到失败时的输出'**
  String get phoneSafeFailureLogEmpty;

  /// No description provided for @phoneSafeBannerTitle.
  ///
  /// In zh, this message translates to:
  /// **'安全模式 · 插件没有加载'**
  String get phoneSafeBannerTitle;

  /// No description provided for @phoneSafeBannerProbation.
  ///
  /// In zh, this message translates to:
  /// **'正在试用正常模式'**
  String get phoneSafeBannerProbation;

  /// No description provided for @phoneSafeBannerProbationHint.
  ///
  /// In zh, this message translates to:
  /// **'2 分钟内不再出错就算恢复，否则自动回到安全模式'**
  String get phoneSafeBannerProbationHint;

  /// No description provided for @phoneSafeBannerRunningHint.
  ///
  /// In zh, this message translates to:
  /// **'对话都在，修好配置后恢复正常模式'**
  String get phoneSafeBannerRunningHint;

  /// No description provided for @phoneSafeBannerFailedHint.
  ///
  /// In zh, this message translates to:
  /// **'安全模式也没能启动，去引擎页查看'**
  String get phoneSafeBannerFailedHint;

  /// No description provided for @phoneSafeBannerStoppedHint.
  ///
  /// In zh, this message translates to:
  /// **'引擎已停止，下次启动仍是安全模式'**
  String get phoneSafeBannerStoppedHint;

  /// No description provided for @phoneSafeRepair.
  ///
  /// In zh, this message translates to:
  /// **'帮我修复'**
  String get phoneSafeRepair;

  /// No description provided for @phoneSafeReasonStartup.
  ///
  /// In zh, this message translates to:
  /// **'连续两次启动失败'**
  String get phoneSafeReasonStartup;

  /// No description provided for @phoneSafeReasonProbation.
  ///
  /// In zh, this message translates to:
  /// **'恢复正常后又崩溃了'**
  String get phoneSafeReasonProbation;

  /// No description provided for @phoneSafeReasonManual.
  ///
  /// In zh, this message translates to:
  /// **'手动开启'**
  String get phoneSafeReasonManual;

  /// No description provided for @phoneSafeNormalSettingsHint.
  ///
  /// In zh, this message translates to:
  /// **'用原有配置和插件重启'**
  String get phoneSafeNormalSettingsHint;

  /// No description provided for @phoneSafeStartSettings.
  ///
  /// In zh, this message translates to:
  /// **'以安全模式启动'**
  String get phoneSafeStartSettings;

  /// No description provided for @phoneSafeStartSettingsHint.
  ///
  /// In zh, this message translates to:
  /// **'不加载插件，排查启动问题'**
  String get phoneSafeStartSettingsHint;

  /// No description provided for @phoneSafeAutoSettings.
  ///
  /// In zh, this message translates to:
  /// **'自动进入安全模式'**
  String get phoneSafeAutoSettings;

  /// No description provided for @phoneSafeAutoSettingsHint.
  ///
  /// In zh, this message translates to:
  /// **'连续启动失败时自动启用'**
  String get phoneSafeAutoSettingsHint;

  /// No description provided for @phoneAccentMist.
  ///
  /// In zh, this message translates to:
  /// **'雾蓝'**
  String get phoneAccentMist;

  /// No description provided for @phoneAccentDaiqing.
  ///
  /// In zh, this message translates to:
  /// **'黛青'**
  String get phoneAccentDaiqing;

  /// No description provided for @phoneAccentDusk.
  ///
  /// In zh, this message translates to:
  /// **'暮紫'**
  String get phoneAccentDusk;

  /// No description provided for @phoneAccentTurquoise.
  ///
  /// In zh, this message translates to:
  /// **'松石'**
  String get phoneAccentTurquoise;

  /// No description provided for @phoneAccentAmber.
  ///
  /// In zh, this message translates to:
  /// **'琥珀'**
  String get phoneAccentAmber;

  /// No description provided for @phoneAccentGraphite.
  ///
  /// In zh, this message translates to:
  /// **'石墨'**
  String get phoneAccentGraphite;

  /// No description provided for @phoneAccentCustom.
  ///
  /// In zh, this message translates to:
  /// **'自定义'**
  String get phoneAccentCustom;

  /// No description provided for @phoneEngineInstallPercent.
  ///
  /// In zh, this message translates to:
  /// **'正在安装 · {percent}%'**
  String phoneEngineInstallPercent(int percent);

  /// No description provided for @phoneEngineStatusSemantics.
  ///
  /// In zh, this message translates to:
  /// **'{prefix}引擎：{status}'**
  String phoneEngineStatusSemantics(String prefix, String status);

  /// No description provided for @phoneLogLineCount.
  ///
  /// In zh, this message translates to:
  /// **'{count} 行'**
  String phoneLogLineCount(int count);

  /// No description provided for @phoneLogCopiedLines.
  ///
  /// In zh, this message translates to:
  /// **'已复制 {count} 行'**
  String phoneLogCopiedLines(int count);

  /// No description provided for @phoneAppRuleDefault.
  ///
  /// In zh, this message translates to:
  /// **'默认：{rule}'**
  String phoneAppRuleDefault(String rule);

  /// No description provided for @phoneAppRulesLoosenTitle.
  ///
  /// In zh, this message translates to:
  /// **'让 DSH 操作「{app}」？'**
  String phoneAppRulesLoosenTitle(String app);

  /// No description provided for @phoneAppRulesSkipStepsTitle.
  ///
  /// In zh, this message translates to:
  /// **'「{app}」不再逐步确认？'**
  String phoneAppRulesSkipStepsTitle(String app);

  /// No description provided for @phoneDndBrowserFailed.
  ///
  /// In zh, this message translates to:
  /// **'打不开浏览器。网址：{url}'**
  String phoneDndBrowserFailed(String url);

  /// No description provided for @phoneDndChannelReady.
  ///
  /// In zh, this message translates to:
  /// **'{channel} · 可以用了'**
  String phoneDndChannelReady(String channel);

  /// No description provided for @phoneDndChannelStatus.
  ///
  /// In zh, this message translates to:
  /// **'{channel} · {reason}'**
  String phoneDndChannelStatus(String channel, String reason);

  /// No description provided for @phoneDndUsing.
  ///
  /// In zh, this message translates to:
  /// **'正在使用：{channel}'**
  String phoneDndUsing(String channel);

  /// No description provided for @phoneDndEnableWith.
  ///
  /// In zh, this message translates to:
  /// **'{mode, select, shizuku{用 Shizuku 开启} sui{用 Sui 开启} root{用 Root 开启} adb{用自连 ADB 开启} other{启用不打扰模式}}'**
  String phoneDndEnableWith(String mode);

  /// No description provided for @phoneDndSwitchTo.
  ///
  /// In zh, this message translates to:
  /// **'{mode, select, shizuku{改用 Shizuku} sui{改用 Sui} root{改用 Root} adb{改用自连 ADB} other{改用这个通道}}'**
  String phoneDndSwitchTo(String mode);

  /// No description provided for @phoneControlWorkingApp.
  ///
  /// In zh, this message translates to:
  /// **'正在操作「{app}」'**
  String phoneControlWorkingApp(String app);

  /// No description provided for @phoneControlPolicySummary.
  ///
  /// In zh, this message translates to:
  /// **'{denied} 个不碰 · {confirmed} 个每步确认'**
  String phoneControlPolicySummary(int denied, int confirmed);

  /// No description provided for @phoneControlRemoteHint.
  ///
  /// In zh, this message translates to:
  /// **'「{host}」上的 DSH 操作不了这台手机，切回「本机」后可用'**
  String phoneControlRemoteHint(String host);

  /// No description provided for @phoneRestrictedSubtitle.
  ///
  /// In zh, this message translates to:
  /// **'侧载的 App 要先放行这一项，{place}开关才点得动'**
  String phoneRestrictedSubtitle(String place);

  /// No description provided for @phoneRestrictedDone.
  ///
  /// In zh, this message translates to:
  /// **'{place}已开好，可以返回了'**
  String phoneRestrictedDone(String place);

  /// No description provided for @phoneFailurePlugins.
  ///
  /// In zh, this message translates to:
  /// **'可能和插件「{plugins}」有关'**
  String phoneFailurePlugins(String plugins);

  /// No description provided for @phoneFailureRequired.
  ///
  /// In zh, this message translates to:
  /// **'必需组件 {components} 没通过启动检查'**
  String phoneFailureRequired(String components);

  /// No description provided for @phoneSafeRestoreAt.
  ///
  /// In zh, this message translates to:
  /// **'DSH 会回到 {when} 正常运行时的配置：'**
  String phoneSafeRestoreAt(String when);

  /// No description provided for @phoneSafeRestoreDisable.
  ///
  /// In zh, this message translates to:
  /// **'• 停用：{plugins}'**
  String phoneSafeRestoreDisable(String plugins);

  /// No description provided for @phoneSafeRestoreChanged.
  ///
  /// In zh, this message translates to:
  /// **'  （{plugins} 之后升级过，只能先停用）'**
  String phoneSafeRestoreChanged(String plugins);

  /// No description provided for @phoneSafeRestoreEnable.
  ///
  /// In zh, this message translates to:
  /// **'• 重新启用：{plugins}'**
  String phoneSafeRestoreEnable(String plugins);

  /// No description provided for @phoneSafeTodayTime.
  ///
  /// In zh, this message translates to:
  /// **'今天 {time}'**
  String phoneSafeTodayTime(String time);

  /// No description provided for @phoneSafeReasonPlugins.
  ///
  /// In zh, this message translates to:
  /// **'连续两次启动失败，可疑插件：{plugins}'**
  String phoneSafeReasonPlugins(String plugins);

  /// No description provided for @phoneListSeparator.
  ///
  /// In zh, this message translates to:
  /// **'、'**
  String get phoneListSeparator;

  /// No description provided for @phonePluginQuoteSeparator.
  ///
  /// In zh, this message translates to:
  /// **'」「'**
  String get phonePluginQuoteSeparator;

  /// No description provided for @phoneEngineRunningAt.
  ///
  /// In zh, this message translates to:
  /// **'运行中 · {address}'**
  String phoneEngineRunningAt(String address);

  /// No description provided for @phoneEngineSafeAt.
  ///
  /// In zh, this message translates to:
  /// **'安全模式 · {address}'**
  String phoneEngineSafeAt(String address);

  /// No description provided for @phoneAppRulesLoosenBody.
  ///
  /// In zh, this message translates to:
  /// **'银行、支付类 App 会检测自动操作，可能限制登录甚至冻结账号；DSH 默认不输密码、不付款。'**
  String get phoneAppRulesLoosenBody;

  /// No description provided for @phoneAppRulesSkipStepsBody.
  ///
  /// In zh, this message translates to:
  /// **'微信这类 App 有风控，曾有手机助手操作后账号被强制下线。改成照常后，只有发消息这类操作还会先问你。'**
  String get phoneAppRulesSkipStepsBody;

  /// No description provided for @phoneResetDeletesChatsWorkspaces.
  ///
  /// In zh, this message translates to:
  /// **'对话和工作区'**
  String get phoneResetDeletesChatsWorkspaces;

  /// No description provided for @phoneResetBodyChatsWorkspaces.
  ///
  /// In zh, this message translates to:
  /// **'会删除对话和工作区，然后重新安装运行环境。'**
  String get phoneResetBodyChatsWorkspaces;

  /// No description provided for @phoneResetDeletesWithPlugins.
  ///
  /// In zh, this message translates to:
  /// **'对话、工作区、插件和设置'**
  String get phoneResetDeletesWithPlugins;

  /// No description provided for @phoneResetBodyWithPlugins.
  ///
  /// In zh, this message translates to:
  /// **'会删除对话、工作区、插件和设置，然后重新安装运行环境。'**
  String get phoneResetBodyWithPlugins;

  /// No description provided for @phoneResetDeletesWithUi.
  ///
  /// In zh, this message translates to:
  /// **'对话、工作区、界面配置和技能'**
  String get phoneResetDeletesWithUi;

  /// No description provided for @phoneResetBodyWithUi.
  ///
  /// In zh, this message translates to:
  /// **'会删除对话、工作区、界面配置和技能，然后重新安装运行环境。'**
  String get phoneResetBodyWithUi;

  /// No description provided for @phoneResetDeletesEverything.
  ///
  /// In zh, this message translates to:
  /// **'对话、工作区、插件、设置、界面配置和技能'**
  String get phoneResetDeletesEverything;

  /// No description provided for @phoneResetBodyEverything.
  ///
  /// In zh, this message translates to:
  /// **'会删除对话、工作区、插件、设置、界面配置和技能，然后重新安装运行环境。'**
  String get phoneResetBodyEverything;

  /// No description provided for @phoneEngineStorageDetails.
  ///
  /// In zh, this message translates to:
  /// **'存储空间不足：需要约 {needed} MB，当前可用 {free} MB'**
  String phoneEngineStorageDetails(String needed, String free);

  /// No description provided for @phoneControlEnabledRestarting.
  ///
  /// In zh, this message translates to:
  /// **'已开启，引擎正在重启'**
  String get phoneControlEnabledRestarting;

  /// No description provided for @phoneControlDisabledRestarting.
  ///
  /// In zh, this message translates to:
  /// **'已关闭，引擎正在重启'**
  String get phoneControlDisabledRestarting;

  /// No description provided for @phoneControlEnabledPending.
  ///
  /// In zh, this message translates to:
  /// **'已开启，引擎启动后生效'**
  String get phoneControlEnabledPending;

  /// No description provided for @phoneReturnAfterDone.
  ///
  /// In zh, this message translates to:
  /// **'完成后返回 DSH Go'**
  String get phoneReturnAfterDone;

  /// No description provided for @phoneReturnAfterDoneHint.
  ///
  /// In zh, this message translates to:
  /// **'收起悬浮条，回到对话看结果'**
  String get phoneReturnAfterDoneHint;

  /// No description provided for @phoneFloatingBar.
  ///
  /// In zh, this message translates to:
  /// **'悬浮条'**
  String get phoneFloatingBar;

  /// No description provided for @phoneIdleOpacity.
  ///
  /// In zh, this message translates to:
  /// **'闲置时不透明度'**
  String get phoneIdleOpacity;

  /// No description provided for @phoneAutoCollapse.
  ///
  /// In zh, this message translates to:
  /// **'闲置时自动收起'**
  String get phoneAutoCollapse;

  /// No description provided for @phoneAutoCollapseHint.
  ///
  /// In zh, this message translates to:
  /// **'收成小球，点按展开'**
  String get phoneAutoCollapseHint;

  /// No description provided for @phoneDeveloperOptions.
  ///
  /// In zh, this message translates to:
  /// **'开发者选项'**
  String get phoneDeveloperOptions;

  /// No description provided for @phoneDirectEngine.
  ///
  /// In zh, this message translates to:
  /// **'直接启动本机引擎'**
  String get phoneDirectEngine;

  /// No description provided for @phoneDirectHint.
  ///
  /// In zh, this message translates to:
  /// **'实验功能，默认关闭，下次启动生效。部分手机（例如 Android 16）会拦截直接启动，届时自动改用兼容启动，数据不受影响。'**
  String get phoneDirectHint;

  /// No description provided for @phoneDirectFailedHint.
  ///
  /// In zh, this message translates to:
  /// **'这台手机上直接启动没有成功，已改用兼容启动。停止引擎后打开可再试一次。'**
  String get phoneDirectFailedHint;

  /// No description provided for @phoneDirectCompatibleHint.
  ///
  /// In zh, this message translates to:
  /// **'这次用了兼容启动，原因见上方。已保留此选项，下次启动会再试。'**
  String get phoneDirectCompatibleHint;

  /// No description provided for @phoneDirectStopFirst.
  ///
  /// In zh, this message translates to:
  /// **'请先停止本机引擎，再切换启动方式。'**
  String get phoneDirectStopFirst;

  /// No description provided for @phoneDirectSafeHint.
  ///
  /// In zh, this message translates to:
  /// **'安全模式使用兼容启动；恢复正常模式后应用此选项。'**
  String get phoneDirectSafeHint;

  /// No description provided for @phoneDirectNeedsRuntime.
  ///
  /// In zh, this message translates to:
  /// **'此选项需要支持直接启动的运行环境。'**
  String get phoneDirectNeedsRuntime;

  /// No description provided for @phoneDirectChangeFailed.
  ///
  /// In zh, this message translates to:
  /// **'未能切换启动方式，请停止本机引擎后重试。'**
  String get phoneDirectChangeFailed;

  /// No description provided for @phoneActualLaunchMode.
  ///
  /// In zh, this message translates to:
  /// **'当前运行方式'**
  String get phoneActualLaunchMode;

  /// No description provided for @phoneLaunchNotObserved.
  ///
  /// In zh, this message translates to:
  /// **'未运行'**
  String get phoneLaunchNotObserved;

  /// No description provided for @phoneLastLaunchSelection.
  ///
  /// In zh, this message translates to:
  /// **'上次启动方式'**
  String get phoneLastLaunchSelection;

  /// No description provided for @phoneDirectRejectedReason.
  ///
  /// In zh, this message translates to:
  /// **'兼容启动原因'**
  String get phoneDirectRejectedReason;

  /// No description provided for @phoneLaunchFailureReason.
  ///
  /// In zh, this message translates to:
  /// **'上次启动失败'**
  String get phoneLaunchFailureReason;

  /// No description provided for @phoneReturnCompatible.
  ///
  /// In zh, this message translates to:
  /// **'切回兼容启动'**
  String get phoneReturnCompatible;

  /// No description provided for @phoneLaunchDirect.
  ///
  /// In zh, this message translates to:
  /// **'直接启动'**
  String get phoneLaunchDirect;

  /// No description provided for @phoneLaunchCompatible.
  ///
  /// In zh, this message translates to:
  /// **'兼容启动'**
  String get phoneLaunchCompatible;

  /// No description provided for @phoneDirectIncompatibleFiles.
  ///
  /// In zh, this message translates to:
  /// **'插件文件待整理，暂用兼容启动'**
  String get phoneDirectIncompatibleFiles;

  /// No description provided for @phoneDirectNotEnoughSpace.
  ///
  /// In zh, this message translates to:
  /// **'空间不足，暂用兼容启动'**
  String get phoneDirectNotEnoughSpace;

  /// No description provided for @phoneDirectMigrationFailed.
  ///
  /// In zh, this message translates to:
  /// **'文件整理未完成，暂用兼容启动'**
  String get phoneDirectMigrationFailed;

  /// No description provided for @phoneDirectLaunchFailed.
  ///
  /// In zh, this message translates to:
  /// **'直接启动未成功'**
  String get phoneDirectLaunchFailed;

  /// No description provided for @phoneLaunchStartFailed.
  ///
  /// In zh, this message translates to:
  /// **'未能完成启动'**
  String get phoneLaunchStartFailed;

  /// No description provided for @phoneLaunchExited.
  ///
  /// In zh, this message translates to:
  /// **'退出码 {code}'**
  String phoneLaunchExited(String code);

  /// No description provided for @phoneDndManualConnect.
  ///
  /// In zh, this message translates to:
  /// **'按端口连接'**
  String get phoneDndManualConnect;

  /// No description provided for @phoneDndConnectPortLabel.
  ///
  /// In zh, this message translates to:
  /// **'连接端口'**
  String get phoneDndConnectPortLabel;

  /// No description provided for @phoneDndConnectPortHint.
  ///
  /// In zh, this message translates to:
  /// **'在系统「无线调试」首页查看「IP 地址和端口」，填写冒号后的端口。请不要使用配对码页面的端口。'**
  String get phoneDndConnectPortHint;

  /// No description provided for @phoneTaskResultReady.
  ///
  /// In zh, this message translates to:
  /// **'任务完成 · 查看结果'**
  String get phoneTaskResultReady;

  /// No description provided for @phoneTaskEndedResult.
  ///
  /// In zh, this message translates to:
  /// **'任务已结束 · 查看结果'**
  String get phoneTaskEndedResult;

  /// No description provided for @phoneBackgroundGuideTitle.
  ///
  /// In zh, this message translates to:
  /// **'后台确认与返回'**
  String get phoneBackgroundGuideTitle;

  /// No description provided for @phoneBackgroundGuideSubtitle.
  ///
  /// In zh, this message translates to:
  /// **'让确认卡和任务结果及时出现'**
  String get phoneBackgroundGuideSubtitle;

  /// No description provided for @phoneBackgroundGuideBody.
  ///
  /// In zh, this message translates to:
  /// **'需要你确认时，会显示 DSH Go 卡片。卡片不可用时会尝试通知或回到 App。请在系统设置中允许手机操控通知和弹出提醒。'**
  String get phoneBackgroundGuideBody;

  /// No description provided for @phoneBackgroundOemHint.
  ///
  /// In zh, this message translates to:
  /// **'在 DSH Go 的系统权限页检查「后台弹出界面」（若提供）。允许后可改善自动返回；菜单名称随系统版本变化。'**
  String get phoneBackgroundOemHint;

  /// No description provided for @phoneBackgroundReturnHint.
  ///
  /// In zh, this message translates to:
  /// **'如果任务完成后没有自动返回，可点通知「任务完成 · 查看结果」。系统关闭通知或限制后台弹出时，可能需要手动打开 DSH Go。'**
  String get phoneBackgroundReturnHint;

  /// No description provided for @phoneBackgroundGotIt.
  ///
  /// In zh, this message translates to:
  /// **'知道了'**
  String get phoneBackgroundGotIt;

  /// No description provided for @phoneBackgroundOpenSettings.
  ///
  /// In zh, this message translates to:
  /// **'打开系统设置'**
  String get phoneBackgroundOpenSettings;

  /// No description provided for @phoneBackgroundNotificationBlocked.
  ///
  /// In zh, this message translates to:
  /// **'请允许手机操控通知的弹出提醒'**
  String get phoneBackgroundNotificationBlocked;

  /// No description provided for @phonePrivilegedUpgrade.
  ///
  /// In zh, this message translates to:
  /// **'此版本尚不支持该特权通道，请更新 DSH Go 后使用。'**
  String get phonePrivilegedUpgrade;

  /// No description provided for @phonePrivilegedSui.
  ///
  /// In zh, this message translates to:
  /// **'Sui'**
  String get phonePrivilegedSui;

  /// No description provided for @phonePrivilegedRoot.
  ///
  /// In zh, this message translates to:
  /// **'Root'**
  String get phonePrivilegedRoot;

  /// No description provided for @phonePrivilegedSuiDescription.
  ///
  /// In zh, this message translates to:
  /// **'使用 Sui 模块提供的接口，仅在主动点击时申请授权。'**
  String get phonePrivilegedSuiDescription;

  /// No description provided for @phonePrivilegedRootDescription.
  ///
  /// In zh, this message translates to:
  /// **'适用于 Magisk、KernelSU 或 APatch；只有主动选择后才首次执行 root 命令。'**
  String get phonePrivilegedRootDescription;

  /// No description provided for @phonePrivilegedRootPrepare.
  ///
  /// In zh, this message translates to:
  /// **'申请 root 授权'**
  String get phonePrivilegedRootPrepare;

  /// No description provided for @phonePrivilegedRootUnchecked.
  ///
  /// In zh, this message translates to:
  /// **'尚未检查'**
  String get phonePrivilegedRootUnchecked;

  /// No description provided for @phonePrivilegedGrantRoot.
  ///
  /// In zh, this message translates to:
  /// **'通过 root 授予'**
  String get phonePrivilegedGrantRoot;

  /// No description provided for @phonePrivilegedGrantSui.
  ///
  /// In zh, this message translates to:
  /// **'通过 Sui 授予'**
  String get phonePrivilegedGrantSui;

  /// No description provided for @phonePrivilegedGrantSuiPermission.
  ///
  /// In zh, this message translates to:
  /// **'先授权 Sui，再授予权限'**
  String get phonePrivilegedGrantSuiPermission;

  /// No description provided for @phonePrivilegedSuggested.
  ///
  /// In zh, this message translates to:
  /// **'建议'**
  String get phonePrivilegedSuggested;

  /// No description provided for @phonePrivilegedRootRiskTitle.
  ///
  /// In zh, this message translates to:
  /// **'给 DSH Go root 权限？'**
  String get phonePrivilegedRootRiskTitle;

  /// No description provided for @phonePrivilegedRootRiskBody.
  ///
  /// In zh, this message translates to:
  /// **'root 管理器（Magisk、KernelSU 或 APatch）会弹窗问你。允许后，DSH Go 以 root 运行自己的后台服务；只有打开「保持 root 通道」，断开或重启后才会自己再去申请。'**
  String get phonePrivilegedRootRiskBody;

  /// No description provided for @phoneKeepTitle.
  ///
  /// In zh, this message translates to:
  /// **'{mode, select, shizuku{保持 Shizuku 通道} sui{保持 Sui 通道} root{保持 root 通道} adb{保持自连 ADB 通道} other{保持这个通道}}'**
  String phoneKeepTitle(String mode);

  /// No description provided for @phoneKeepRootDescription.
  ///
  /// In zh, this message translates to:
  /// **'断开、重开 App 或重启手机后，DSH Go 会自己再向 root 管理器申请；给不给仍由管理器决定。'**
  String get phoneKeepRootDescription;

  /// No description provided for @phoneKeepSharedDescription.
  ///
  /// In zh, this message translates to:
  /// **'断开、重开 App 或重启手机后，DSH Go 用已有的授权自己连回去，不会替你申请授权。'**
  String get phoneKeepSharedDescription;

  /// No description provided for @phoneKeepAdbDescription.
  ///
  /// In zh, this message translates to:
  /// **'断开、重开 App 或重启手机后，DSH Go 用已有的配对在 Wi‑Fi 下自己连回去；有「自动恢复无障碍」的权限时，还会试着打开一次无线调试。'**
  String get phoneKeepAdbDescription;

  /// No description provided for @phoneKeepRestoring.
  ///
  /// In zh, this message translates to:
  /// **'正在重新连接'**
  String get phoneKeepRestoring;

  /// No description provided for @phoneKeepWaiting.
  ///
  /// In zh, this message translates to:
  /// **'等通道可用后再连'**
  String get phoneKeepWaiting;

  /// No description provided for @phoneKeepWaitingService.
  ///
  /// In zh, this message translates to:
  /// **'等所选服务运行后再连'**
  String get phoneKeepWaitingService;

  /// No description provided for @phoneKeepWaitingPermission.
  ///
  /// In zh, this message translates to:
  /// **'还没有授权；授权后会自己连上'**
  String get phoneKeepWaitingPermission;

  /// No description provided for @phoneKeepWaitingNetwork.
  ///
  /// In zh, this message translates to:
  /// **'等连上 Wi‑Fi 后再连'**
  String get phoneKeepWaitingNetwork;

  /// No description provided for @phoneKeepNotPaired.
  ///
  /// In zh, this message translates to:
  /// **'还没有配对，请先完成无线调试配对'**
  String get phoneKeepNotPaired;

  /// No description provided for @phoneKeepFailed.
  ///
  /// In zh, this message translates to:
  /// **'没连上；下次打开 App 或开始操控时再试'**
  String get phoneKeepFailed;

  /// No description provided for @phoneModeTitle.
  ///
  /// In zh, this message translates to:
  /// **'选择确认方式'**
  String get phoneModeTitle;

  /// No description provided for @phoneModeMessage.
  ///
  /// In zh, this message translates to:
  /// **'随时可在设置里更改'**
  String get phoneModeMessage;

  /// No description provided for @phoneModeAsk.
  ///
  /// In zh, this message translates to:
  /// **'关键步骤先问我'**
  String get phoneModeAsk;

  /// No description provided for @phoneModeAskHint.
  ///
  /// In zh, this message translates to:
  /// **'进新 App、发送、删除、付款前先问'**
  String get phoneModeAskHint;

  /// No description provided for @phoneModeAuto.
  ///
  /// In zh, this message translates to:
  /// **'全程自动'**
  String get phoneModeAuto;

  /// No description provided for @phoneModeAutoHint.
  ///
  /// In zh, this message translates to:
  /// **'不再询问，全程免打扰'**
  String get phoneModeAutoHint;

  /// No description provided for @phoneModeAutoNoteTitle.
  ///
  /// In zh, this message translates to:
  /// **'这些仍由你来操作'**
  String get phoneModeAutoNoteTitle;

  /// No description provided for @phoneModeAutoNote.
  ///
  /// In zh, this message translates to:
  /// **'系统设置和权限页面、密码和验证码、DSH Go 自身仍由你来操作；银行、支付类 App 默认不碰，可在设置里调整。'**
  String get phoneModeAutoNote;

  /// No description provided for @phoneModeAutoUnlockNote.
  ///
  /// In zh, this message translates to:
  /// **'如需让 AI 操作系统设置、密码等，可在 设置 › 手机操控 › 解除限制 中开启。'**
  String get phoneModeAutoUnlockNote;

  /// No description provided for @phoneModeConfirmAuto.
  ///
  /// In zh, this message translates to:
  /// **'开启全程自动'**
  String get phoneModeConfirmAuto;

  /// No description provided for @phoneYoursTitle.
  ///
  /// In zh, this message translates to:
  /// **'这些由你来操作'**
  String get phoneYoursTitle;

  /// No description provided for @phoneYoursSystem.
  ///
  /// In zh, this message translates to:
  /// **'系统设置和权限页面'**
  String get phoneYoursSystem;

  /// No description provided for @phoneYoursSecrets.
  ///
  /// In zh, this message translates to:
  /// **'密码和验证码'**
  String get phoneYoursSecrets;

  /// No description provided for @phoneYoursOwnApp.
  ///
  /// In zh, this message translates to:
  /// **'DSH Go 自身'**
  String get phoneYoursOwnApp;

  /// No description provided for @phoneYoursDenyList.
  ///
  /// In zh, this message translates to:
  /// **'应用名单里「不碰」的 App，默认含银行、支付类'**
  String get phoneYoursDenyList;

  /// No description provided for @phoneUnlockTitle.
  ///
  /// In zh, this message translates to:
  /// **'解除限制'**
  String get phoneUnlockTitle;

  /// No description provided for @phoneUnlockSubtitle.
  ///
  /// In zh, this message translates to:
  /// **'让 AI 去做默认由你来做的事'**
  String get phoneUnlockSubtitle;

  /// No description provided for @phoneUnlockSystem.
  ///
  /// In zh, this message translates to:
  /// **'系统设置'**
  String get phoneUnlockSystem;

  /// No description provided for @phoneUnlockSystemHint.
  ///
  /// In zh, this message translates to:
  /// **'含权限页、安装器、安全中心、通知栏'**
  String get phoneUnlockSystemHint;

  /// No description provided for @phoneUnlockSecrets.
  ///
  /// In zh, this message translates to:
  /// **'密码和验证码'**
  String get phoneUnlockSecrets;

  /// No description provided for @phoneUnlockSecretsHint.
  ///
  /// In zh, this message translates to:
  /// **'填写密码、验证码和支付密码'**
  String get phoneUnlockSecretsHint;

  /// No description provided for @phoneUnlockOwnApp.
  ///
  /// In zh, this message translates to:
  /// **'DSH Go 自身'**
  String get phoneUnlockOwnApp;

  /// No description provided for @phoneUnlockOwnAppHint.
  ///
  /// In zh, this message translates to:
  /// **'在 DSH Go 里点按和输入'**
  String get phoneUnlockOwnAppHint;

  /// No description provided for @phoneUnlockBusy.
  ///
  /// In zh, this message translates to:
  /// **'任务进行中，结束后才能开启'**
  String get phoneUnlockBusy;

  /// No description provided for @phoneUnlockFootnote.
  ///
  /// In zh, this message translates to:
  /// **'开启后的后果由你承担。建议只在需要时开启，用完关闭。'**
  String get phoneUnlockFootnote;

  /// No description provided for @phoneUnlockBanks.
  ///
  /// In zh, this message translates to:
  /// **'银行、支付类 App'**
  String get phoneUnlockBanks;

  /// No description provided for @phoneUnlockBanksHint.
  ///
  /// In zh, this message translates to:
  /// **'在应用名单里调整'**
  String get phoneUnlockBanksHint;

  /// No description provided for @phoneUnlockNone.
  ///
  /// In zh, this message translates to:
  /// **'均未开启'**
  String get phoneUnlockNone;

  /// No description provided for @phoneUnlockCount.
  ///
  /// In zh, this message translates to:
  /// **'{count, plural, other{已开启 {count} 项}}'**
  String phoneUnlockCount(int count);

  /// No description provided for @phoneUnlockedBadge.
  ///
  /// In zh, this message translates to:
  /// **'已解除限制'**
  String get phoneUnlockedBadge;

  /// No description provided for @phoneUnlockConfirmSystemTitle.
  ///
  /// In zh, this message translates to:
  /// **'允许 AI 操作系统设置？'**
  String get phoneUnlockConfirmSystemTitle;

  /// No description provided for @phoneUnlockConfirmSecretsTitle.
  ///
  /// In zh, this message translates to:
  /// **'允许 AI 填写密码和验证码？'**
  String get phoneUnlockConfirmSecretsTitle;

  /// No description provided for @phoneUnlockConfirmOwnAppTitle.
  ///
  /// In zh, this message translates to:
  /// **'允许 AI 操作 DSH Go 自身？'**
  String get phoneUnlockConfirmOwnAppTitle;

  /// No description provided for @phoneUnlockCanTitle.
  ///
  /// In zh, this message translates to:
  /// **'开启后，AI 可以'**
  String get phoneUnlockCanTitle;

  /// No description provided for @phoneUnlockRiskTitle.
  ///
  /// In zh, this message translates to:
  /// **'可能出什么事'**
  String get phoneUnlockRiskTitle;

  /// No description provided for @phoneUnlockDisclaimerTitle.
  ///
  /// In zh, this message translates to:
  /// **'免责声明'**
  String get phoneUnlockDisclaimerTitle;

  /// No description provided for @phoneUnlockSystemCan1.
  ///
  /// In zh, this message translates to:
  /// **'打开和更改系统设置，包括权限、无障碍和开发者选项'**
  String get phoneUnlockSystemCan1;

  /// No description provided for @phoneUnlockSystemCan2.
  ///
  /// In zh, this message translates to:
  /// **'在安装器里安装、更新或卸载应用'**
  String get phoneUnlockSystemCan2;

  /// No description provided for @phoneUnlockSystemCan3.
  ///
  /// In zh, this message translates to:
  /// **'在安全中心和通知栏里点按，包括通知上的按钮'**
  String get phoneUnlockSystemCan3;

  /// No description provided for @phoneUnlockSystemRisk1.
  ///
  /// In zh, this message translates to:
  /// **'网页、消息或文件里的恶意指令可能诱导 AI 关掉保护、给其他应用授权或安装应用'**
  String get phoneUnlockSystemRisk1;

  /// No description provided for @phoneUnlockSystemRisk2.
  ///
  /// In zh, this message translates to:
  /// **'改错的网络、账号或安全设置，需要你自己改回来'**
  String get phoneUnlockSystemRisk2;

  /// No description provided for @phoneUnlockSecretsCan1.
  ///
  /// In zh, this message translates to:
  /// **'在密码、验证码和支付密码框里输入'**
  String get phoneUnlockSecretsCan1;

  /// No description provided for @phoneUnlockSecretsCan2.
  ///
  /// In zh, this message translates to:
  /// **'用它在对话、短信或通知里看到的验证码完成登录或验证'**
  String get phoneUnlockSecretsCan2;

  /// No description provided for @phoneUnlockSecretsCan3.
  ///
  /// In zh, this message translates to:
  /// **'操作记录里只显示 ••••，不记下填写的内容'**
  String get phoneUnlockSecretsCan3;

  /// No description provided for @phoneUnlockSecretsRisk1.
  ///
  /// In zh, this message translates to:
  /// **'恶意指令可能诱导 AI 把验证码填到别处，让他人登录你的账号'**
  String get phoneUnlockSecretsRisk1;

  /// No description provided for @phoneUnlockSecretsRisk2.
  ///
  /// In zh, this message translates to:
  /// **'可能完成你并不想要的付款或转账'**
  String get phoneUnlockSecretsRisk2;

  /// No description provided for @phoneUnlockOwnAppCan1.
  ///
  /// In zh, this message translates to:
  /// **'在 DSH Go 里点按和输入，包括修改设置'**
  String get phoneUnlockOwnAppCan1;

  /// No description provided for @phoneUnlockOwnAppCan2.
  ///
  /// In zh, this message translates to:
  /// **'读取 DSH Go 界面上的对话和设置'**
  String get phoneUnlockOwnAppCan2;

  /// No description provided for @phoneUnlockOwnAppRisk1.
  ///
  /// In zh, this message translates to:
  /// **'恶意指令可能诱导 AI 批准它自己发起的操作，或关掉确认'**
  String get phoneUnlockOwnAppRisk1;

  /// No description provided for @phoneUnlockOwnAppRisk2.
  ///
  /// In zh, this message translates to:
  /// **'这些界面上的内容会发给模型'**
  String get phoneUnlockOwnAppRisk2;

  /// No description provided for @phoneUnlockDisclaimer1.
  ///
  /// In zh, this message translates to:
  /// **'开启后，AI 可以在无人确认的情况下执行上述操作。'**
  String get phoneUnlockDisclaimer1;

  /// No description provided for @phoneUnlockDisclaimer2.
  ///
  /// In zh, this message translates to:
  /// **'AI 可能被网页、消息或文件中的内容误导。'**
  String get phoneUnlockDisclaimer2;

  /// No description provided for @phoneUnlockDisclaimer3.
  ///
  /// In zh, this message translates to:
  /// **'由此造成的账号、资金、数据或设备损失由你自行承担，DSH Go 及其开发者不承担责任。'**
  String get phoneUnlockDisclaimer3;

  /// No description provided for @phoneUnlockDisclaimer4.
  ///
  /// In zh, this message translates to:
  /// **'建议只在需要时临时开启，用完关闭。'**
  String get phoneUnlockDisclaimer4;

  /// No description provided for @phoneUnlockDisclaimer5.
  ///
  /// In zh, this message translates to:
  /// **'不建议在存有支付或银行信息的设备上开启。'**
  String get phoneUnlockDisclaimer5;

  /// No description provided for @phoneUnlockHold.
  ///
  /// In zh, this message translates to:
  /// **'我了解风险，开启'**
  String get phoneUnlockHold;

  /// No description provided for @phoneUnlockHoldHint.
  ///
  /// In zh, this message translates to:
  /// **'按住按钮约 1.5 秒'**
  String get phoneUnlockHoldHint;

  /// No description provided for @phoneUnlockOnNotice.
  ///
  /// In zh, this message translates to:
  /// **'已开启「{name}」'**
  String phoneUnlockOnNotice(String name);

  /// No description provided for @phoneUnlockOffNotice.
  ///
  /// In zh, this message translates to:
  /// **'已关闭「{name}」'**
  String phoneUnlockOffNotice(String name);

  /// No description provided for @searchKwPhoneUnlock.
  ///
  /// In zh, this message translates to:
  /// **'解除限制,放开限制,密码,验证码,系统设置,自身,风险,免责'**
  String get searchKwPhoneUnlock;

  /// No description provided for @pluginConfigUnsaved.
  ///
  /// In zh, this message translates to:
  /// **'未保存'**
  String get pluginConfigUnsaved;

  /// No description provided for @pluginConfigSecretSet.
  ///
  /// In zh, this message translates to:
  /// **'已设置'**
  String get pluginConfigSecretSet;

  /// No description provided for @pluginConfigAdvanced.
  ///
  /// In zh, this message translates to:
  /// **'高级'**
  String get pluginConfigAdvanced;

  /// No description provided for @pluginConfigSearchHint.
  ///
  /// In zh, this message translates to:
  /// **'搜索设置'**
  String get pluginConfigSearchHint;

  /// No description provided for @pluginConfigNoMatch.
  ///
  /// In zh, this message translates to:
  /// **'没有匹配的设置'**
  String get pluginConfigNoMatch;

  /// No description provided for @pluginConfigOpenWeb.
  ///
  /// In zh, this message translates to:
  /// **'在网页版设置'**
  String get pluginConfigOpenWeb;

  /// No description provided for @pluginConfigOpenWebHint.
  ///
  /// In zh, this message translates to:
  /// **'插件自带的设置页'**
  String get pluginConfigOpenWebHint;

  /// No description provided for @pluginConfigResetAll.
  ///
  /// In zh, this message translates to:
  /// **'全部恢复默认'**
  String get pluginConfigResetAll;

  /// No description provided for @pluginConfigResetAllTitle.
  ///
  /// In zh, this message translates to:
  /// **'全部恢复默认？'**
  String get pluginConfigResetAllTitle;

  /// No description provided for @pluginConfigReset.
  ///
  /// In zh, this message translates to:
  /// **'恢复'**
  String get pluginConfigReset;

  /// No description provided for @pluginConfigChanges.
  ///
  /// In zh, this message translates to:
  /// **'{count} 项更改'**
  String pluginConfigChanges(int count);

  /// No description provided for @pluginConfigAppliesOnReload.
  ///
  /// In zh, this message translates to:
  /// **'保存后重新载入插件'**
  String get pluginConfigAppliesOnReload;

  /// No description provided for @pluginConfigSaving.
  ///
  /// In zh, this message translates to:
  /// **'正在保存…'**
  String get pluginConfigSaving;

  /// No description provided for @pluginConfigReloading.
  ///
  /// In zh, this message translates to:
  /// **'正在重新载入…'**
  String get pluginConfigReloading;

  /// No description provided for @pluginConfigApplied.
  ///
  /// In zh, this message translates to:
  /// **'已生效'**
  String get pluginConfigApplied;

  /// No description provided for @pluginConfigFailed.
  ///
  /// In zh, this message translates to:
  /// **'没能生效'**
  String get pluginConfigFailed;

  /// No description provided for @pluginConfigRestored.
  ///
  /// In zh, this message translates to:
  /// **'已恢复原设置'**
  String get pluginConfigRestored;

  /// No description provided for @pluginConfigStopped.
  ///
  /// In zh, this message translates to:
  /// **'没能生效，原设置也没能恢复'**
  String get pluginConfigStopped;

  /// No description provided for @pluginConfigRestore.
  ///
  /// In zh, this message translates to:
  /// **'恢复原设置'**
  String get pluginConfigRestore;

  /// No description provided for @pluginConfigDiscard.
  ///
  /// In zh, this message translates to:
  /// **'放弃'**
  String get pluginConfigDiscard;

  /// No description provided for @pluginConfigNotStarted.
  ///
  /// In zh, this message translates to:
  /// **'插件没有启动'**
  String get pluginConfigNotStarted;

  /// No description provided for @pluginConfigNone.
  ///
  /// In zh, this message translates to:
  /// **'没有可设置的项'**
  String get pluginConfigNone;

  /// No description provided for @pluginConfigInvalidOperation.
  ///
  /// In zh, this message translates to:
  /// **'这项改动无法应用'**
  String get pluginConfigInvalidOperation;

  /// No description provided for @pluginConfigGone.
  ///
  /// In zh, this message translates to:
  /// **'插件已不在运行，已刷新'**
  String get pluginConfigGone;

  /// No description provided for @pluginConfigUnknown.
  ///
  /// In zh, this message translates to:
  /// **'连接中断，已重新读取'**
  String get pluginConfigUnknown;

  /// No description provided for @pluginConfigUnsupported.
  ///
  /// In zh, this message translates to:
  /// **'暂不支持在这里设置'**
  String get pluginConfigUnsupported;

  /// No description provided for @pluginConfigSecretUnbound.
  ///
  /// In zh, this message translates to:
  /// **'需插件适配后设置'**
  String get pluginConfigSecretUnbound;

  /// No description provided for @pluginConfigListFailed.
  ///
  /// In zh, this message translates to:
  /// **'插件清单读取失败，稍后重试'**
  String get pluginConfigListFailed;

  /// No description provided for @pluginConfigListUpdating.
  ///
  /// In zh, this message translates to:
  /// **'插件清单正在更新，请稍后再试'**
  String get pluginConfigListUpdating;

  /// No description provided for @pluginConfigFixed.
  ///
  /// In zh, this message translates to:
  /// **'由配置文件固定'**
  String get pluginConfigFixed;

  /// No description provided for @pluginConfigFixedNote.
  ///
  /// In zh, this message translates to:
  /// **'由配置文件固定，这里只能查看'**
  String get pluginConfigFixedNote;

  /// No description provided for @pluginConfigReadOnly.
  ///
  /// In zh, this message translates to:
  /// **'只读'**
  String get pluginConfigReadOnly;

  /// No description provided for @pluginConfigEntryTitle.
  ///
  /// In zh, this message translates to:
  /// **'{bundle} · {entry}'**
  String pluginConfigEntryTitle(String bundle, String entry);

  /// No description provided for @pluginConfigNameSpeechToText.
  ///
  /// In zh, this message translates to:
  /// **'语音识别'**
  String get pluginConfigNameSpeechToText;

  /// No description provided for @pluginConfigNameSenseVoice.
  ///
  /// In zh, this message translates to:
  /// **'SenseVoice 识别'**
  String get pluginConfigNameSenseVoice;

  /// No description provided for @pluginConfigNameSpeechApi.
  ///
  /// In zh, this message translates to:
  /// **'转写接口'**
  String get pluginConfigNameSpeechApi;

  /// No description provided for @pluginConfigNameTranslator.
  ///
  /// In zh, this message translates to:
  /// **'翻译服务'**
  String get pluginConfigNameTranslator;

  /// No description provided for @pluginConfigNameSessionIndex.
  ///
  /// In zh, this message translates to:
  /// **'会话索引'**
  String get pluginConfigNameSessionIndex;

  /// No description provided for @pluginConfigNameSessionSearchTool.
  ///
  /// In zh, this message translates to:
  /// **'会话搜索工具'**
  String get pluginConfigNameSessionSearchTool;

  /// No description provided for @pluginConfigNameTerminalService.
  ///
  /// In zh, this message translates to:
  /// **'终端服务'**
  String get pluginConfigNameTerminalService;

  /// No description provided for @pluginConfigNameTerminalBash.
  ///
  /// In zh, this message translates to:
  /// **'Bash 终端'**
  String get pluginConfigNameTerminalBash;

  /// No description provided for @pluginConfigNameTerminalPwsh.
  ///
  /// In zh, this message translates to:
  /// **'PowerShell 终端'**
  String get pluginConfigNameTerminalPwsh;

  /// No description provided for @pluginConfigNameTerminalTools.
  ///
  /// In zh, this message translates to:
  /// **'终端工具'**
  String get pluginConfigNameTerminalTools;

  /// No description provided for @pluginConfigNameWorktree.
  ///
  /// In zh, this message translates to:
  /// **'工作树管理'**
  String get pluginConfigNameWorktree;

  /// No description provided for @pluginConfigNameWorktreeTools.
  ///
  /// In zh, this message translates to:
  /// **'工作树工具'**
  String get pluginConfigNameWorktreeTools;

  /// No description provided for @pluginConfigNameRalphWorkflow.
  ///
  /// In zh, this message translates to:
  /// **'工作流引擎'**
  String get pluginConfigNameRalphWorkflow;

  /// No description provided for @pluginConfigNameRalphTools.
  ///
  /// In zh, this message translates to:
  /// **'Ralph 工具'**
  String get pluginConfigNameRalphTools;

  /// No description provided for @plugInputRequired.
  ///
  /// In zh, this message translates to:
  /// **'请填写此项'**
  String get plugInputRequired;

  /// No description provided for @plugInputInvalidValue.
  ///
  /// In zh, this message translates to:
  /// **'此处的值无效'**
  String get plugInputInvalidValue;

  /// No description provided for @plugInputNumber.
  ///
  /// In zh, this message translates to:
  /// **'请输入有效数字'**
  String get plugInputNumber;

  /// No description provided for @plugInputBounds.
  ///
  /// In zh, this message translates to:
  /// **'请输入 {min}–{max} 之间的值'**
  String plugInputBounds(String min, String max);

  /// No description provided for @plugInputLength.
  ///
  /// In zh, this message translates to:
  /// **'长度需为 {min}–{max} 个字符'**
  String plugInputLength(int min, int max);

  /// No description provided for @plugInputPattern.
  ///
  /// In zh, this message translates to:
  /// **'格式不正确'**
  String get plugInputPattern;

  /// No description provided for @plugInputDate.
  ///
  /// In zh, this message translates to:
  /// **'请选择有效日期'**
  String get plugInputDate;

  /// No description provided for @plugInputTime.
  ///
  /// In zh, this message translates to:
  /// **'请选择有效时间'**
  String get plugInputTime;

  /// No description provided for @plugInputUnavailable.
  ///
  /// In zh, this message translates to:
  /// **'此处不支持这个组件'**
  String get plugInputUnavailable;

  /// No description provided for @plugInputNoPassword.
  ///
  /// In zh, this message translates to:
  /// **'插件不能使用密码输入框'**
  String get plugInputNoPassword;

  /// No description provided for @plugInputBadBinding.
  ///
  /// In zh, this message translates to:
  /// **'输入绑定必须是 data 下的字段路径'**
  String get plugInputBadBinding;

  /// No description provided for @plugInputDuplicateBinding.
  ///
  /// In zh, this message translates to:
  /// **'一个字段只能绑定一个输入组件'**
  String get plugInputDuplicateBinding;

  /// No description provided for @plugInputNamedPattern.
  ///
  /// In zh, this message translates to:
  /// **'只支持内置的格式校验'**
  String get plugInputNamedPattern;

  /// No description provided for @plugInputNestedForm.
  ///
  /// In zh, this message translates to:
  /// **'表单不能嵌套'**
  String get plugInputNestedForm;

  /// No description provided for @plugInputSubmitMissing.
  ///
  /// In zh, this message translates to:
  /// **'表单缺少提交动作'**
  String get plugInputSubmitMissing;

  /// No description provided for @plugInputTooLarge.
  ///
  /// In zh, this message translates to:
  /// **'内容过多，请缩短后重试'**
  String get plugInputTooLarge;

  /// No description provided for @plugInputCheckFields.
  ///
  /// In zh, this message translates to:
  /// **'请检查标出的项目'**
  String get plugInputCheckFields;

  /// No description provided for @plugInputFailed.
  ///
  /// In zh, this message translates to:
  /// **'未保存，请重试'**
  String get plugInputFailed;

  /// No description provided for @plugInputSubmit.
  ///
  /// In zh, this message translates to:
  /// **'保存'**
  String get plugInputSubmit;

  /// No description provided for @plugInputChoose.
  ///
  /// In zh, this message translates to:
  /// **'选择'**
  String get plugInputChoose;

  /// No description provided for @plugInputPrevious.
  ///
  /// In zh, this message translates to:
  /// **'上一页'**
  String get plugInputPrevious;

  /// No description provided for @plugInputNext.
  ///
  /// In zh, this message translates to:
  /// **'下一页'**
  String get plugInputNext;

  /// No description provided for @plugInputDecrease.
  ///
  /// In zh, this message translates to:
  /// **'减少{label}'**
  String plugInputDecrease(String label);

  /// No description provided for @plugInputIncrease.
  ///
  /// In zh, this message translates to:
  /// **'增加{label}'**
  String plugInputIncrease(String label);

  /// No description provided for @plugInputRating.
  ///
  /// In zh, this message translates to:
  /// **'{label}：{value} 分，共 {max} 分'**
  String plugInputRating(String label, int value, int max);

  /// No description provided for @plugInputFormula.
  ///
  /// In zh, this message translates to:
  /// **'公式无效或超出上限'**
  String get plugInputFormula;

  /// No description provided for @plugInputDatePicker.
  ///
  /// In zh, this message translates to:
  /// **'插件日期'**
  String get plugInputDatePicker;

  /// No description provided for @plugInputTimePicker.
  ///
  /// In zh, this message translates to:
  /// **'插件时间'**
  String get plugInputTimePicker;

  /// No description provided for @plugInputChoices.
  ///
  /// In zh, this message translates to:
  /// **'插件选项'**
  String get plugInputChoices;

  /// No description provided for @plugInputGestureRequired.
  ///
  /// In zh, this message translates to:
  /// **'该效果需要用户点按'**
  String get plugInputGestureRequired;

  /// No description provided for @pluginsOperationHostChanged.
  ///
  /// In zh, this message translates to:
  /// **'主机已切换，未执行'**
  String get pluginsOperationHostChanged;

  /// No description provided for @pluginsReloadLocal.
  ///
  /// In zh, this message translates to:
  /// **'重启内核以重载'**
  String get pluginsReloadLocal;

  /// No description provided for @pluginsReloadInterrupts.
  ///
  /// In zh, this message translates to:
  /// **'会中断正在运行的任务'**
  String get pluginsReloadInterrupts;

  /// No description provided for @pluginsReloadConfirm.
  ///
  /// In zh, this message translates to:
  /// **'重载「{name}」？'**
  String pluginsReloadConfirm(String name);

  /// No description provided for @pluginsReloadExplanation.
  ///
  /// In zh, this message translates to:
  /// **'将重启本机内核，重新加载插件。正在运行的任务会中断。'**
  String get pluginsReloadExplanation;

  /// No description provided for @pluginsReloadProceed.
  ///
  /// In zh, this message translates to:
  /// **'重启并重载'**
  String get pluginsReloadProceed;

  /// No description provided for @pluginsReloadRequested.
  ///
  /// In zh, this message translates to:
  /// **'已请求重启内核'**
  String get pluginsReloadRequested;

  /// No description provided for @pluginsReloadChanged.
  ///
  /// In zh, this message translates to:
  /// **'主机或插件状态已变化，请重试'**
  String get pluginsReloadChanged;

  /// No description provided for @pluginsReloadFailed.
  ///
  /// In zh, this message translates to:
  /// **'未能重启内核，请查看引擎日志'**
  String get pluginsReloadFailed;

  /// No description provided for @pluginsFile.
  ///
  /// In zh, this message translates to:
  /// **'文件'**
  String get pluginsFile;

  /// No description provided for @pluginsChat.
  ///
  /// In zh, this message translates to:
  /// **'对话'**
  String get pluginsChat;

  /// No description provided for @pluginsImage.
  ///
  /// In zh, this message translates to:
  /// **'图片'**
  String get pluginsImage;

  /// No description provided for @pluginsNamespaceDefaultModel.
  ///
  /// In zh, this message translates to:
  /// **'默认模型'**
  String get pluginsNamespaceDefaultModel;

  /// No description provided for @pluginsNamespaceDefaultPreset.
  ///
  /// In zh, this message translates to:
  /// **'默认预设'**
  String get pluginsNamespaceDefaultPreset;

  /// No description provided for @pluginsNamespaceAgent.
  ///
  /// In zh, this message translates to:
  /// **'智能体'**
  String get pluginsNamespaceAgent;

  /// No description provided for @pluginsNamespaceSubagent.
  ///
  /// In zh, this message translates to:
  /// **'子代理'**
  String get pluginsNamespaceSubagent;

  /// No description provided for @pluginsNamespaceSubagentModels.
  ///
  /// In zh, this message translates to:
  /// **'子代理模型'**
  String get pluginsNamespaceSubagentModels;

  /// No description provided for @pluginsNamespaceDeepSeekModel.
  ///
  /// In zh, this message translates to:
  /// **'DeepSeek 模型'**
  String get pluginsNamespaceDeepSeekModel;

  /// No description provided for @pluginsNamespaceAccountModel.
  ///
  /// In zh, this message translates to:
  /// **'DeepSeek 账号模型'**
  String get pluginsNamespaceAccountModel;

  /// No description provided for @pluginsNamespaceCustomModels.
  ///
  /// In zh, this message translates to:
  /// **'自定义模型服务'**
  String get pluginsNamespaceCustomModels;

  /// No description provided for @pluginsNamespaceNetwork.
  ///
  /// In zh, this message translates to:
  /// **'联网'**
  String get pluginsNamespaceNetwork;

  /// No description provided for @pluginsNamespaceWebSearch.
  ///
  /// In zh, this message translates to:
  /// **'联网搜索'**
  String get pluginsNamespaceWebSearch;

  /// No description provided for @pluginsNamespaceSearchApi.
  ///
  /// In zh, this message translates to:
  /// **'联网搜索接口'**
  String get pluginsNamespaceSearchApi;

  /// No description provided for @pluginsNamespaceCommands.
  ///
  /// In zh, this message translates to:
  /// **'命令执行'**
  String get pluginsNamespaceCommands;

  /// No description provided for @pluginsNamespacePermissions.
  ///
  /// In zh, this message translates to:
  /// **'权限'**
  String get pluginsNamespacePermissions;

  /// No description provided for @pluginsNamespaceChatLog.
  ///
  /// In zh, this message translates to:
  /// **'对话日志'**
  String get pluginsNamespaceChatLog;

  /// No description provided for @pluginsNamespaceThinkingTranslation.
  ///
  /// In zh, this message translates to:
  /// **'思考翻译'**
  String get pluginsNamespaceThinkingTranslation;

  /// No description provided for @pluginsNamespaceTranslation.
  ///
  /// In zh, this message translates to:
  /// **'翻译'**
  String get pluginsNamespaceTranslation;

  /// No description provided for @pluginsNamespaceLanguage.
  ///
  /// In zh, this message translates to:
  /// **'语言'**
  String get pluginsNamespaceLanguage;

  /// No description provided for @pluginsNamespaceWebAppearance.
  ///
  /// In zh, this message translates to:
  /// **'网页版外观'**
  String get pluginsNamespaceWebAppearance;

  /// No description provided for @pluginsNamespaceWebChat.
  ///
  /// In zh, this message translates to:
  /// **'网页版对话'**
  String get pluginsNamespaceWebChat;

  /// No description provided for @pluginsNamespaceWebInput.
  ///
  /// In zh, this message translates to:
  /// **'网页版输入'**
  String get pluginsNamespaceWebInput;

  /// No description provided for @pluginsNamespaceWebSettings.
  ///
  /// In zh, this message translates to:
  /// **'网页版设置'**
  String get pluginsNamespaceWebSettings;

  /// No description provided for @pluginsNamespaceWebGeneral.
  ///
  /// In zh, this message translates to:
  /// **'网页版通用'**
  String get pluginsNamespaceWebGeneral;

  /// No description provided for @pluginsNamespaceAutoReview.
  ///
  /// In zh, this message translates to:
  /// **'自动审查'**
  String get pluginsNamespaceAutoReview;

  /// No description provided for @pluginsNamespaceAgentTeam.
  ///
  /// In zh, this message translates to:
  /// **'智能体团队'**
  String get pluginsNamespaceAgentTeam;

  /// No description provided for @pluginsNamespaceVoiceInput.
  ///
  /// In zh, this message translates to:
  /// **'语音输入'**
  String get pluginsNamespaceVoiceInput;

  /// No description provided for @pluginsOfficialPlugin.
  ///
  /// In zh, this message translates to:
  /// **'官方插件'**
  String get pluginsOfficialPlugin;

  /// No description provided for @pluginsLocalUnshareable.
  ///
  /// In zh, this message translates to:
  /// **'本地安装，无法分享'**
  String get pluginsLocalUnshareable;

  /// No description provided for @pluginsIncludesPresets.
  ///
  /// In zh, this message translates to:
  /// **'含预设「{names}」'**
  String pluginsIncludesPresets(String names);

  /// No description provided for @pluginsSecretsUnshareable.
  ///
  /// In zh, this message translates to:
  /// **'含有密钥，无法分享'**
  String get pluginsSecretsUnshareable;

  /// No description provided for @pluginsLineCount.
  ///
  /// In zh, this message translates to:
  /// **'{count} 行'**
  String pluginsLineCount(int count);

  /// No description provided for @pluginsEmptyValue.
  ///
  /// In zh, this message translates to:
  /// **'空'**
  String get pluginsEmptyValue;

  /// No description provided for @pluginsOnValue.
  ///
  /// In zh, this message translates to:
  /// **'开'**
  String get pluginsOnValue;

  /// No description provided for @pluginsOffValue.
  ///
  /// In zh, this message translates to:
  /// **'关'**
  String get pluginsOffValue;

  /// No description provided for @pluginsOfficialUnavailable.
  ///
  /// In zh, this message translates to:
  /// **'这台主机没有这个官方插件'**
  String get pluginsOfficialUnavailable;

  /// No description provided for @pluginsEnabled.
  ///
  /// In zh, this message translates to:
  /// **'已启用'**
  String get pluginsEnabled;

  /// No description provided for @pluginsVersionMismatch.
  ///
  /// In zh, this message translates to:
  /// **'与分享时的版本不一致'**
  String get pluginsVersionMismatch;

  /// No description provided for @pluginsCurrentVersion.
  ///
  /// In zh, this message translates to:
  /// **'当前版本'**
  String get pluginsCurrentVersion;

  /// No description provided for @pluginsNewVersion.
  ///
  /// In zh, this message translates to:
  /// **'新版本'**
  String get pluginsNewVersion;

  /// No description provided for @pluginsAddedWith.
  ///
  /// In zh