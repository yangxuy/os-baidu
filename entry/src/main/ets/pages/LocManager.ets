import { LatLng } from '@bdmap/base';
import { BDLocation, BDLocationListener, LocationClient, LocationClientOption, LocationMode, Poi } from '@bdmap/locsdk'
import { Context, WantAgent } from '@kit.AbilityKit';

export class LocManager {
  private client: LocationClient | null = null;
  private static instance: LocManager;

  public static getInstance(): LocManager {
    if (!LocManager.instance) {
      LocManager.instance = new LocManager();
    }
    return LocManager.instance;
  }

  center?: LatLng

  constructor() {

  }

  init(context: Context) {
    if (this.client == null) {
      try {
        this.client = new LocationClient(context);
      } catch (error) {
        console.error("harmony_baidu_location error: " + error.message);
      }
    }
    if (this.client != null) {
      this.client.setLocOption(this.getDefaultLocationOption());

      this.registerListener({
        onReceiveLocation(bdLocation: BDLocation): void {
          this.center = new LatLng(bdLocation.getLatitude(), bdLocation.getLongitude())
          console.log('onReceiveLocation', this.center)
          AppStorage.setOrCreate('center', this.center);
        }
      })

      this.requestSingleLocation()
    }
  }

  start() {
    if (this.client != null) {
      this.client.start();
    }
  }

  stop() {
    if (this.client != null) {
      this.client.stop();
    }
  }

  requestSingleLocation() {
    if (this.client != null) {
      this.client.requestSingleLocation();
    }
  }

  registerListener(listener: BDLocationListener): boolean {
    let isSuccess: boolean = false;
    if (this.client != null && listener != null) {
      this.client.registerLocationListener(listener);
      isSuccess = true;
    }
    return isSuccess;
  }

  unRegisterListener(listener: BDLocationListener) {
    if (this.client != null && listener != null) {
      this.client.unRegisterLocationListener(listener);
    }
  }

  getSDKVersion(): string {
    let version: string = "";
    if (this.client != null) {
      version = this.client.getVersion();
    }
    return version;
  }

  enableLocInBackground(wantAgent: WantAgent) {
    if (this.client != null) {
      this.client.enableLocInBackground(wantAgent);
    }
  }

  disableLocInBackground() {
    if (this.client != null) {
      this.client.disableLocInBackground();
    }
  }

  getDefaultLocationOption() {
    let option = new LocationClientOption();
    option.setCoorType("bd09ll"); // 可选，默认为gcj02，设置返回的定位结果坐标系
    option.setTimeInterval(3); // 可选，默认1秒，设置连续定位请求的时间间隔
    option.setDistanceInterval(0); // 可选，默认0米，设置连续定位的距离间隔
    option.setIsNeedAddress(true); // 可选，设置是否需要地址信息，默认不需要
    option.setIsNeedLocationDescribe(true); // 可选，默认为false，设置是否需要地址描述
    option.setIsNeedLocationPoiList(true); // 可选，默认能为false，设置是否需要POI结果
    option.setLocationMode(LocationMode.High_Accuracy); // 可选，默认高精度，设置定位模式，高精度、低功耗、仅设备
    option.setSingleLocatingTimeout(3000); // 可选，仅针对单次定位生效，设置单次定位的超时时间

    return option;
  }
}