import { AMapPrivacyAgreeStatus, AMapPrivacyInfoStatus, AMapPrivacyShowStatus } from '@amap/amap_lbs_common';
import {
  AMapLocationManagerImpl,
  AMapLocationOption,
  AMapLocationReGeocodeLanguage,
  AMapLocationType,
  IAMapLocationListener
} from '@amap/amap_lbs_location';
import {
  AMap,
  BitmapDescriptorFactory,
  CameraPosition,
  CameraUpdateFactory,
  LatLng,
  MapsInitializer,
  MapView,
  MapViewComponent,
  MapViewCreateCallback,
  MapViewManager,
  MarkerOptions,
  OnCameraChangeListener,
  Poi
} from '@amap/amap_lbs_map3d';
import { abilityAccessCtrl, common, PermissionRequestResult, Permissions } from '@kit.AbilityKit';
import bundleManager from '@ohos.bundle.bundleManager';
import { BusinessError } from '@kit.BasicServicesKit';
import { geoLocationManager } from '@kit.LocationKit';
import { router } from '@kit.ArkUI';
import { NaviLatLng } from '@amap/amap_lbs_navi';

@Entry
@Component
struct Index {
  mapView?: MapView;
  aMap?: AMap;
  @Provide center: LatLng | undefined = undefined;
  locationManger?: AMapLocationManagerImpl;

  onPageShow() {
    // 地图
    MapsInitializer.setApiKey("33016c711af0aa3084bc5a456833b788");
    MapViewManager.getInstance().registerMapViewCreatedCallback(this.mapViewCreateCallback);
    // 定位
    AMapLocationManagerImpl.setApiKey("33016c711af0aa3084bc5a456833b788");
    AMapLocationManagerImpl.updatePrivacyShow(AMapPrivacyShowStatus.DidShow, AMapPrivacyInfoStatus.DidContain,
      getContext(this))
    AMapLocationManagerImpl.updatePrivacyAgree(AMapPrivacyAgreeStatus.DidAgree, getContext(this))
    if (this.locationManger === undefined) {
      this.locationManger = new AMapLocationManagerImpl(getContext(this));
    }
    this.checkPermissions();
  }

  private mapViewCreateCallback: MapViewCreateCallback = (mapview?: MapView, mapViewName?: string) => {
    console.log("mapViewCreateCallback", mapview)
    if (!mapview) {
      return;
    }
    this.mapView = mapview;
    this.mapView.onCreate();
    this.mapView.getMapAsync(async (map) => {
      this.aMap = map;

      this.addCenterIcon()
    })

  }

  async checkAccessToken(permission: Permissions): Promise<abilityAccessCtrl.GrantStatus> {
    let atManager: abilityAccessCtrl.AtManager = abilityAccessCtrl.createAtManager();
    let grantStatus: abilityAccessCtrl.GrantStatus = abilityAccessCtrl.GrantStatus.PERMISSION_DENIED;

    // 获取应用程序的accessTokenID
    let tokenId: number = 0;
    try {
      let bundleInfo: bundleManager.BundleInfo =
        await bundleManager.getBundleInfoForSelf(bundleManager.BundleFlag.GET_BUNDLE_INFO_WITH_APPLICATION);
      let appInfo: bundleManager.ApplicationInfo = bundleInfo.appInfo;
      tokenId = appInfo.accessTokenId;
    } catch (error) {
      let err: BusinessError = error as BusinessError;
      console.error(`Failed to get bundle info for self. Code is ${err.code}, message is ${err.message}`);
    }

    // 校验应用是否被授予权限
    try {
      grantStatus = await atManager.checkAccessToken(tokenId, permission);
    } catch (error) {
      let err: BusinessError = error as BusinessError;
      console.error(`Failed to check access token. Code is ${err.code}, message is ${err.message}`);
    }

    return grantStatus;
  }

  async checkPermissions(): Promise<void> {
    const permissions: Array<Permissions> = ['ohos.permission.LOCATION'];

    // 检查应用是否授予权限
    let grantStatus: abilityAccessCtrl.GrantStatus = await this.checkAccessToken(permissions[0]);

    if (grantStatus === abilityAccessCtrl.GrantStatus.PERMISSION_GRANTED) {
      // 已经授权，可以继续访问目标操作
      this.initLocation()
    } else {
      // 申请定位权限
      this.reqPermissionsFromUser([
        'ohos.permission.APPROXIMATELY_LOCATION',
        'ohos.permission.LOCATION',
      ]);
    }
  }

  reqPermissionsFromUser(permissions: Array<Permissions>): void {
    let context: Context = getContext(this) as common.UIAbilityContext;
    let atManager: abilityAccessCtrl.AtManager = abilityAccessCtrl.createAtManager();
    // requestPermissionsFromUser会判断权限的授权状态来决定是否唤起弹窗
    atManager.requestPermissionsFromUser(context, permissions).then((data: PermissionRequestResult) => {
      let grantStatus: Array<number> = data.authResults;
      let length: number = grantStatus.length;
      for (let i = 0; i < length; i++) {
        if (grantStatus[i] === 0) {
          // 用户授权，可以继续访问目标操作
        } else {
          // 用户拒绝授权，提示用户必须授权才能访问当前页面的功能，并引导用户到系统设置中打开相应的权限
          // this.openPermissionsInSystemSettings()
          return;
        }
      }
      this.initLocation()
      // 授权成功
    }).catch((err: BusinessError) => {
      console.error(`Failed to request permissions from user. Code is ${err.code}, message is ${err.message}`);
    })
  }

  initLocation() {
    let listener: IAMapLocationListener = {
      onLocationChanged: (location) => {
        console.error('onCurrentLocationChanged  ' + JSON.stringify(location))
        this.center = new LatLng(location.latitude, location.longitude)
        this.addCenterIcon()
      }, onLocationError: (error) => {
        console.error('error  ' + JSON.stringify(error))
      }
    };

    let options: AMapLocationOption = {
      priority: geoLocationManager.LocationRequestPriority.FIRST_FIX,
      scenario: geoLocationManager.LocationRequestScenario.UNSET,
      maxAccuracy: 0,
      singleLocationTimeout: 3000,
      allowsBackgroundLocationUpdates: false,
      locatingWithReGeocode: false,
      reGeocodeLanguage: AMapLocationReGeocodeLanguage.Chinese,
      isOffset: false
    }

    this.locationManger?.setLocationListener(AMapLocationType.Single, listener)
    this.locationManger?.setLocationOption(AMapLocationType.Single, options)
    this.locationManger?.requestSingleLocation()
  }

  async addCenterIcon() {
    this.aMap?.moveCamera(CameraUpdateFactory.newLatLngZoom(
      this.center, 18
    ));
    let options: MarkerOptions = new MarkerOptions();
    options.setPosition(this.center);

    options.setIcon(await BitmapDescriptorFactory.fromView(() => {
      this.customMarkerBuilder();
    }));

    this.aMap?.addMarker(options);
  }

  @Builder
  customMarkerBuilder() {
    Image($r("app.media.dingwei"))
      .width(30)
      .height(30)
  }

  build() {
    Stack({ alignContent: Alignment.Bottom }) {
      MapViewComponent()
        .width('100%')
        .height('100%')

      Swiper() {
        Row({ space: 12 }) {
          Image("https://ai-public.mastergo.com/ai/img_res/a6c757d1c9ef122ba2d4dd9d56decff9.jpg")
            .width(90)
            .height(90)
            .borderRadius(90)

          Column({ space: 6 }) {
            Text("第一教学楼")
              .fontWeight(FontWeight.Bold)
              .fontSize(20)
            Text("6:20-22:00")
            Text("主要用于理工科专业课程教学，配备多媒体教室和实验室")
            Text("饮水机、自习室、打印室")
          }
          .alignItems(HorizontalAlign.Start)
        }
        .onClick(() => {
          router.pushUrl({
            url: "pages/Nav",
            params: {
              start: new NaviLatLng(this.center?.latitude,this.center?.longitude), //38.292231, 109.722679
              end: new NaviLatLng(31.26942, 121.574758)
            }
          })
        })

        Row({ space: 12 }) {
          Image("https://ai-public.mastergo.com/ai/img_res/7886de666d9be81dd04d83e71b7dcaaa.jpg")
            .width(90)
            .height(90)
            .borderRadius(90)

          Column({ space: 6 }) {
            Text("中心食堂")
              .fontWeight(FontWeight.Bold)
              .fontSize(20)
            Text("06:30-20:00")
            Text("学校主要餐饮场所，提供多样化的饮食选择")
            Text("自助打饭、微波炉、洗手间")
          }
          .alignItems(HorizontalAlign.Start)
        }
        .onClick(() => {
          router.pushUrl({
            url: "pages/Nav",
            params: {
              start: this.center,
              end: new LatLng(38.292231, 109.722679)
            }
          })
        })

        Row({ space: 12 }) {
          Image("https://ai-public.mastergo.com/ai/img_res/2a1eb6cb9790bbd2e49cd652d2928dc4.jpg")
            .width(90)
            .height(90)
            .borderRadius(90)

          Column({ space: 6 }) {
            Text("综合体育场")
              .fontWeight(FontWeight.Bold)
              .fontSize(20)
            Text("全天开放")
            Text("标准400米跑道，内设足球场，配备看台和夜间照明")
            Text("更衣室、器材室、饮水站")
          }
          .alignItems(HorizontalAlign.Start)
        }
        .onClick(() => {
          router.pushUrl({
            url: "pages/Nav",
            params: {
              start: this.center,
              position: new LatLng(38.292231, 109.722679)
            }
          })
        })
      }
      .height(200)
      .loop(false)
    }
    .height('100%')
    .width('100%')
  }
}