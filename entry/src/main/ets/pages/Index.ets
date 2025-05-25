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

interface ISearchProp {
  name?: string,
  location?: LatLng | null | undefined
}

@Entry
@Component
struct Index {
  mapController: MapController | null = null;
  mapOpt: MapOptions = new MapOptions({
    mapStatus: new MapStatus({ zoom: 16 }),
    shows: { satelliteMap: SysEnum.ESatelliteLayerType.NONE, trafficMap: true }
  });
  @State showPoiDetail: boolean = false;
  @State limitZoomCenter: boolean = false;
  @State com: Visibility = Visibility.Visible;
  @StorageProp('center') @Watch('onCenter') center: LatLng | undefined = undefined;
  @StorageProp('topHeight') topHeight: number | undefined = 0;
  @State searchList: Array<ISearchProp> = []
  @State isShowSearch: boolean = false
  private mS?: Marker
  private mE?: Marker
  private line?: Polyline
  private textInput: string = ''

  onCenter() {
    console.log("onCenter", this.center)
    if (this.center && this.mapController) {
      this.mapController?.setMapCenter(this.center, 18)
      let marker = new Marker({
        position: this.center,
        icon: new ImageEntity('rawfile://dw.png'),
        scaleX: 0.3,
        scaleY: 0.3,
      })
      this.mapController?.addOverlay(marker)
    }
  }

  // 步行导航规划
  walkPlanning(poi: LatLng) {
    if (this.mapController) {
      this.mapController.removeOverlay(this.mS)
      this.mapController.removeOverlay(this.mE)
      this.mapController.removeOverlay(this.line)

      const fromArr: LatLng = this.center!;
      const toArr: LatLng = poi;
      // 绘制起点
      let image: ImageEntity = new ImageEntity('rawfile://start.png', 50, 81);
      this.mS = new Marker({
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
      this.mapController?.addOverlay(this.mS);
      // 绘制终点
      let image2: ImageEntity = new ImageEntity('rawfile://end.png', 50, 81);
      this.mE = new Marker({
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
      this.mapController?.addOverlay(this.mE);
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

          this.line = new Polyline({
            points: resultLine,
            fillcolor: '#6af',
            width: 10,
            join: SysEnum.LineJoinType.ROUND,
            cap: SysEnum.LineCapType.ROUND,
            isThined: true,
            isGeodesic: true
          });
          this.mapController?.addOverlay(this.line);
        })
    }
  }

  // 周边检索
  searchInNearby(s?: string) {
    let search: PoiSearch = PoiSearch.newInstance();
    let opParams: PoiNearbySearchOptionParams = {
      keyword: s ?? this.textInput,
      location: this.center!,
      radius: 1000
    }
    this.searchList = []
    let option = new PoiNearbySearchOption(opParams)
    search.searchNearby(option)
      .then((res: PoiResult) => {
        if (typeof res.arrayPoiInfo != "undefined") {
          for (let i = 0; i < res.arrayPoiInfo.length; i++) {
            let poiInfo = res.arrayPoiInfo[i]
            this.searchList.push({
              name: poiInfo.name,
              location: poiInfo.location
            })
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

      Column() {
        Row({ space: 12 }) {
          Image($r('app.media.search'))
            .width('20')
          Text("周边检索")
            .fontColor("#ccc")
        }
        .onClick(() => {
          this.isShowSearch = true
        })
        .padding({ left: 16 })
        .width('100%')
        .height(40)
        .border({
          width: 1,
          color: "#ccc"
        })

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
            // 31.27570,121.580936 38.298122, 109.726588
            this.walkPlanning(new LatLng(38.298122, 109.726588))
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
            this.walkPlanning(new LatLng(38.298122, 109.726588))
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
            this.walkPlanning(new LatLng(38.300373, 109.726004))
          })
        }
        .height(200)
        .loop(false)
      }
      .backgroundColor('#fff')

      if (this.isShowSearch) {
        Column() {
          Row() {
            Image($r('app.media.back'))
              .width(18)
              .onClick(() => this.isShowSearch = false)
            TextInput({ placeholder: "操场" })
              .focusable(true)
              .backgroundColor('transparent')
              .layoutWeight(1)
              .onChange((e) => {
                this.textInput = e
              })
            Text("搜索")
              .fontColor("blue")
              .fontSize(18)
              .onClick(() => {
                this.searchInNearby()
              })
          }
          .backgroundColor('#fff')

          Row({ space: 8 }) {
            Column({ space: 4 }) {
              Image($r('app.media.ms'))
                .width(32)
              Text('美食')
            }
            .onClick(() => {
              this.searchInNearby('美食')
            })

            Column({ space: 4 }) {
              Image($r('app.media.jd'))
                .width(32)
              Text('酒店')
            }
            .onClick(() => {
              this.searchInNearby('酒店')
            })


            Column({ space: 4 }) {
              Image($r('app.media.jindin'))
                .width(32)
              Text('景点')
            }
            .onClick(() => {
              this.searchInNearby('景点')
            })
          }
          .width('100%')
          .margin({ top: 18, bottom: 10 })
          .justifyContent(FlexAlign.Start)

          List({ space: 12 }) {
            ForEach(this.searchList, (item: ISearchProp, index) => {
              ListItem() {
                Row() {
                  Image($r('app.media.dingwei')).width(12)
                  Text(item.name)
                }
                .onClick(() => {
                  this.isShowSearch = false
                  this.walkPlanning(item.location!)
                })
              }
            })
          }
        }
        .padding({ top: this.topHeight, left: 16, right: 16 })
        .width('100%')
        .height('100%')
        .backgroundColor('#fff')
      }
    }
    .height('100%')
    .width('100%')
  }
}