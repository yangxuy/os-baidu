import { abilityAccessCtrl, AbilityConstant, ConfigurationConstant, UIAbility, Want } from '@kit.AbilityKit';
import { hilog } from '@kit.PerformanceAnalysisKit';
import { window } from '@kit.ArkUI';
import { bundleManager } from '@kit.AbilityKit';
import { Initializer } from '@bdmap/base';
import { LocationClient } from '@bdmap/locsdk';
import { LocManager } from '../pages/LocManager';

const DOMAIN = 0x0000;

export default class EntryAbility extends UIAbility {
  onCreate(want: Want, launchParam: AbilityConstant.LaunchParam): void {
    this.context.getApplicationContext().setColorMode(ConfigurationConstant.ColorMode.COLOR_MODE_NOT_SET);
    hilog.info(DOMAIN, 'testTag', '%{public}s', 'Ability onCreate');
    LocationClient.setAgreePrivacy(true); // 设置是否同意隐私政策
    LocManager.getInstance().init(this.context);
  }

  onDestroy(): void {
    hilog.info(DOMAIN, 'testTag', '%{public}s', 'Ability onDestroy');
  }

  onWindowStageCreate(windowStage: window.WindowStage): void {
    let appId = this.getBundleInfoSignatureInfoAppId()
    hilog.info(0x000, 'testTag', 'appId=: %{public}s', appId)
    Initializer.getInstance().initialize("lBuM1IVdkQAtvlX92z6KWcLFmHUq9TR4");
    LocationClient.checkAuthKey("lBuM1IVdkQAtvlX92z6KWcLFmHUq9TR4", (result: string) => {
      console.debug("result = " + result); // 可打印出是否鉴权成功的结果
    });
    windowStage.loadContent('pages/Login', (err) => {
      let windowClass: window.Window = windowStage.getMainWindowSync();
      windowClass.setWindowLayoutFullScreen(true)

      const type = window.AvoidAreaType.TYPE_SYSTEM; // 以状态栏避让为例
      const avoidArea = windowClass.getWindowAvoidArea(type);
      let topRectHeight = avoidArea.topRect.height; // 获取状态栏区域高度
      AppStorage.setOrCreate('topHeight', px2vp(topRectHeight));
    });
  }

  onWindowStageDestroy(): void {
    // Main window is destroyed, release UI related resources
    hilog.info(DOMAIN, 'testTag', '%{public}s', 'Ability onWindowStageDestroy');
  }

  onForeground(): void {
    // Ability has brought to foreground
    hilog.info(DOMAIN, 'testTag', '%{public}s', 'Ability onForeground');
  }

  onBackground(): void {
    // Ability has back to background
    hilog.info(DOMAIN, 'testTag', '%{public}s', 'Ability onBackground');
  }

  //获取appId
  getBundleInfoSignatureInfoAppId(): string {
    let flag = bundleManager.BundleFlag.GET_BUNDLE_INFO_WITH_SIGNATURE_INFO;
    try {
      let bundleInfo = bundleManager.getBundleInfoForSelfSync(flag)
      let appId = bundleInfo.signatureInfo.appIdentifier;
      hilog.info(0x000, 'testTag', 'appId: %{public}s', appId);
      return appId
    } catch (err) {
      hilog.error(0x0000, 'testTag', 'getBundleInfoForSelf failed: %{public}s', err);
    }
    return '';
  }
}