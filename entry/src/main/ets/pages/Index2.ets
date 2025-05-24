import {
  MapComponent,
  MapController,
  MapOptions,
  MapStatus,
  SysEnum,
  Marker,
  ImageEntity,
  Polyline,
  OverlayEvent
} from '@bdmap/map';
import { LatLng } from '@bdmap/base';
import { promptAction, router } from '@kit.ArkUI';
import {
  parseGeoStr2LLArray,
  PlanNode,
  PoiCitySearchOptionParams,
  PoiNearbySearchOption,
  PoiNearbySearchOptionParams,
  PoiResult,
  PoiSearch,
  RoutePlanSearch,
  WalkingRoutePlanOption,
  WalkingRouteResult
} from '@bdmap/search';

@Entry
@Component
struct Index2 {
  mapController: MapController | null = null;
  mapOpt: MapOptions = new MapOptions({
    mapStatus: new MapStatus({ zoom: 16 }),
    shows: { satelliteMap: SysEnum.ESatelliteLayerType.NONE, trafficMap: true }
  });
  @State showPoiDetail: boolean = false;
  @State limitZoomCenter: boolean = false;
  @State com: Visibility = Visibility.Visible;
  @StorageProp('center') @Watch('onCenter') center: LatLng | undefined = undefined;

  onCenter() {
    this.mapController?.setMapCenter(this.center, 18)
    let marker = new Marker({
      position: this.center,
      icon: new ImageEntity('rawfile://dingwei.svg', 20, 20)
    })
    this.mapController?.addOverlay(marker)
  }

  // 周边检索
  searchInNearby() {
    let search: PoiSearch = PoiSearch.newInstance();
    let opParams: PoiNearbySearchOptionParams = {
      keyword: "房地产$公司企业$政府机构$生活服务$酒店$教育培训$门址$美食$丽人$医疗",
      location: this.center!,
      radius: 1000
    }
    let option = new PoiNearbySearchOption(opParams)
    search.searchNearby(option)
      .then((res: PoiResult) => {

        console.log('search',JSON.stringify(res))
        if (typeof res.arrayPoiInfo != "undefined") {
          for (let i = 0; i < res.arrayPoiInfo.length; i++) {
            let poiInfo = res.arrayPoiInfo[i]
            if (!!poiInfo) {
              let location = poiInfo.location
              if (!!location) {
                let image: ImageEntity = new ImageEntity('rawfile://poicity.png', 50, 81);
                let marker: Marker = new Marker({
                  position: location,
                  icon: image,
                  yOffset: 0,
                  isFlat: false,
                  isDraggable: true,
                  rotate: 0,
                  alpha: 0.9,
                  scaleX: 1,
                  scaleY: 1,
                  isTop: true
                });

                marker.addEventListener(OverlayEvent.CLICK, () => {
                  promptAction.showToast({
                    message: 'marker点击',
                    duration: 2000
                  })
                  if (!!poiInfo.uid) {
                    this.showPoiDetail = true
                    search.searchPoiDetail({
                      uids: poiInfo.uid,
                      isExtendAdcode: false
                    }).then((res) => {
                      // if (!!res.poiDetailInfoList) {
                      //   let detailInfo = res.poiDetailInfoList[0]
                      //   let name = detailInfo.name || ' '
                      //   let loc = detailInfo.location?.toString() || ' '
                      //   let addr = detailInfo.address || ' '
                      //   let province = detailInfo.province || ' '
                      //   let city = detailInfo.city || ' '
                      //   this.poiDetailStr =
                      //     `省份: ${province}\n城市: ${city}\n地址: ${addr}\n名称: ${name}\n经纬度: ${loc}`
                      // }
                    })
                      .catch(() => {
                        // this.poiDetailStr = '错误'
                      })
                  }
                })
                this.mapController?.addOverlay(marker);
              }
            }
          }
        }
      })
  }

  build() {
    Stack({ alignContent: Alignment.Bottom }) {
      MapComponent({
        onReady: async (err, mapController: MapController) => {
          if (!err) {
            this.mapController = mapController;
          }
        },
        mapOptions: this.mapOpt,
      }).width('100%').height('100%');

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
          if (this.mapController) {
            const fromArr: LatLng = this.center!;
            const toArr: LatLng = new LatLng(31.26942, 121.574758);
            // 绘制起点
            let image: ImageEntity = new ImageEntity('rawfile://start.png', 50, 81);
            let marker: Marker = new Marker({
              position: fromArr,
              icon: image,
              yOffset: 0,
              isFlat: false,
              isDraggable: true,
              rotate: 0,
              alpha: 0.9,
              scaleX: 1,
              scaleY: 1,
              isTop: true
            });
            this.mapController?.addOverlay(marker);
            // 绘制终点
            let image2: ImageEntity = new ImageEntity('rawfile://end.png', 50, 81);
            let marker2: Marker = new Marker({
              position: toArr,
              icon: image2,
              yOffset: 0,
              isFlat: false,
              isDraggable: true,
              rotate: 0,
              alpha: 0.9,
              scaleX: 1,
              scaleY: 1,
              isTop: true
            });
            this.mapController?.addOverlay(marker2);
            console.log('requestlbs ' + "br.getRouteLines")
            // 获取驾车路线规划
            let option: WalkingRoutePlanOption = {
              from: PlanNode.withLocation(fromArr),
              to: PlanNode.withLocation(toArr)
            }
            RoutePlanSearch.newInstance().walkingSearch(option)
              .then((res: WalkingRouteResult) => {
                let resultLine: Array<LatLng> = []
                if (typeof res.routeLines === "undefined") {
                  return
                }
                let line = res.routeLines[0]
                let steps = line.steps
                for (let i = 0; i < steps.length; i++) {
                  let step = steps[i]
                  let llAry: LatLng[] = parseGeoStr2LLArray(step.pathString)
                  llAry.forEach(element => {
                    resultLine.push(element)
                  })
                }

                let polyline: Polyline = new Polyline({
                  points: resultLine,
                  fillcolor: '#6af',
                  width: 10,
                  join: SysEnum.LineJoinType.ROUND,
                  cap: SysEnum.LineCapType.ROUND,
                  isThined: true,
                  isGeodesic: true
                });
                this.mapController?.addOverlay(polyline);
              })
          }
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
          this.searchInNearby()
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

        })
      }
      .backgroundColor('#fff')
      .height(200)
      .loop(false)
    }
    .height('100%')
    .width('100%')
  }
}