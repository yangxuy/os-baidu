import {
  AMapNaviFactory,
  AmapNaviType,
  AMapRoutePlanComponent,
  IAMapCalcRouteResult,
  IAMapNavi,
  INaviInfo,
  LatLng,
  NaviLatLng,
  NaviType
} from '@amap/amap_lbs_navi';
import { router } from '@kit.ArkUI';
import { INav } from './type';

@Entry
@Component
struct Nav {
  naviInstance?: IAMapNavi
  start?: NaviLatLng;
  end?: NaviLatLng;

  onPageShow(): void {
    //
    this.naviInstance =
      AMapNaviFactory.getAMapNaviInstance(getContext().getApplicationContext(), '8b58fddbf5713497053eb85999cfa3c1')

    this.naviInstance.setIsUseInnerVoice(true)

    this.naviInstance.addAMapNaviListener({
      onNaviInfoUpdate: (naviInfo: INaviInfo) => {
        console.info(`naviInfo mCurRoadName: ${naviInfo.mCurRoadName} mNextRoadName: ${naviInfo.mNextRoadName}`)
      },
      onCalculateRouteSuccess: (routeResult: IAMapCalcRouteResult | null) => {
        console.info('算路成功')
        // 开启模拟定位
        // this.naviInstance?.startMockLocation();
      },

      onStartNavi: (type: number) => {
        console.info('onStartNavi: ' + type)
      }
    })
  }

  aboutToAppear(): void {
    const params = router.getParams() as INav;
    console.error('aboutToAppear',JSON.stringify(params))
    this.start = params.start
    this.end = params.end
  }

  goBack() {
    // 停止mock定位信息
    this.naviInstance?.stopMockLocation();
    AMapNaviFactory.destroyAMapNaviInstance()
  }

  build() {
    Column() {
      AMapRoutePlanComponent({
        // routePlanParams: {
        //   mType: AmapNaviType.Driver,
        //   mNaviType: NaviType.GPS,
        //   mRouteStrategy: 10,
        //   start: {
        //     coordinate: this.start,
        //   }, //起点
        //   end: {
        //     coordinate: this.end,
        //   }, //终点
        //   goBack: () => {
        //   },
        //   isNeedCalculateRouteWhenPresent: true
        // }
        routePlanParams: {
          mType: AmapNaviType.Driver,
          mNaviType: NaviType.GPS,
          mRouteStrategy: 10,
          start: {
            coordinate: this.start,
          }, //起点
          end: {
            coordinate: this.end,
          }, //终点
          goBack: () => {
          },
          isNeedCalculateRouteWhenPresent: true
        }
      })
    }
  }
}