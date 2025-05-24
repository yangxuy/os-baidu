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
    this.requestPermission()
    LocationClient.setAgreePrivacy(true); // 设置是否同意隐私政策
    LocManager.getInstance().init(this.context);
  }

  onDestroy(): void {
    hilog.info(DOMAIN, 'testTag', '%{public}s', 'Ability onDestroy');
  }


  requestPermission = async () => {
    let permissionRequestResult = await abilityAccessCtrl.createAtManager().requestPermissionsFromUser(this.context,
      [
        'ohos.permission.LOCATION',
        'ohos.permission.APPROXIMATELY_LOCATION',
        'ohos.permission.APP_TRACKING_CONSENT'
      ]);
    // 如果权限列表中有-1，说明用户拒绝了授权
    if (permissionRequestResult.authResults[0] === 0) {
      hilog.info(0x0000, 'testTag', '%{public}s', 'request permission success');
    }
  }
  onWindowStageCreate(windowStage: window.WindowStage): void {
    // Main window is created, set main page for this ability
    hilog.info(DOMAIN, 'testTag', '%{public}s', 'Ability onWindowStageCreate');
    let appId = this.getBundleInfoSignatureInfoAppId()
    hilog.info(0x000, 'testTag', 'appId=: %{public}s', appId)
    Initializer.getInstance().initialize("lBuM1IVdkQAtvlX92z6KWcLFmHUq9TR4");
    LocationClient.checkAuthKey("lBuM1IVdkQAtvlX92z6KWcLFmHUq9TR4", (result: string) => {
      console.debug("result = " + result); // 可打印出是否鉴权成功的结果
    });
    windowStage.loadContent('pages/Index2', (err) => {
      let windowClass: window.Window = windowStage.getMainWindowSync();
      windowClass.setWindowLayoutFullScreen(true)
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