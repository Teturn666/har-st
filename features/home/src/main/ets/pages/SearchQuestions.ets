import { emitter } from "@kit.BasicServicesKit";
import { display, window as kitWindow } from "@kit.ArkUI";
import { accessManager } from "../utils/AccessManager";
import { cameraManager } from "../utils/CameraManager";
import { ocrToText } from "../utils/OcrToText";
import window from '@ohos.window';
// import "./SearchIntroductionPage"; // 如需副作用引入可取消注释

@Entry({ routeName: "searchQuestionsPage" })
@Component
export struct SearchQuestions {
  @State TopHeight:number=0
  @State dataValue:string=""
  @State CameraChange:boolean=false
  @State isPortrait: boolean = true;
  controller: XComponentController = new XComponentController()
  win:kitWindow.Window|null=null
  map: PixelMap | null = null
  aboutToAppear(): void {
    emitter.on("dataText", (event) => {
      this.dataValue = event.data!["text"].replace(/\r?\n/g, '')
    })

    this.getWindow()

  }
  aboutToDisappear(): void {
  this.win?.setWindowLayoutFullScreen(false)
    cameraManager.releaseCamera()
  }

  async getWindow(){
    this.win =await kitWindow.getLastWindow(getContext())
    this.TopHeight=this.win.getWindowAvoidArea(kitWindow.AvoidAreaType.TYPE_SYSTEM).topRect.height
    this.win.setWindowLayoutFullScreen(true)
  }

  async setScreenOrientation(isPortrait: boolean) {
    if (this.win) {
      await this.win.setPreferredOrientation(
        isPortrait ? window.Orientation.PORTRAIT : window.Orientation.LANDSCAPE
      );
    }
  }
  build() {
    Column() {

      RelativeContainer() {
Column(){
  XComponent({
    type: XComponentType.SURFACE,
    controller: this.controller
  }).width("100%")
    .height('100%')
    // .transform({ rotate: 90 })

    .onLoad(() => {

      accessManager.CheckCamera(["ohos.permission.CAMERA"], () => {
        cameraManager.initCamera(this.controller.getXComponentSurfaceId())

      })
    })
}
// .rotate({ angle: 90 }) // 旋转45度

        Row(){
         Column(){
           Image($r("sys.media.ohos_ic_public_arrow_left" ))
             .fillColor(Color.White)
             .width(25)
             .aspectRatio(1)
             .borderRadius(15)
             .backgroundColor("#504F4E")
         }
         .width(50)
         .aspectRatio(1)
         Column(){
           Image($r("app.media.screen_rotation"))
             .fillColor(Color.White)
             .width(25)
             .aspectRatio(1)
             .borderRadius(15)
             .backgroundColor("#504F4E")
             .onClick(() => {
               this.isPortrait = !this.isPortrait;
               this.setScreenOrientation(this.isPortrait);
             })
         }
         .width(50)
         .aspectRatio(1)
        }

        .width('100%')
        .height(30)
        .padding({
          left:15,right:15
        })
        .alignRules({
          top: { anchor: '__container__', align: VerticalAlign.Top },

        })
        .margin({top:px2vp(this.TopHeight)+10})
        .justifyContent(FlexAlign.SpaceBetween)
        Column() {
          if (this.dataValue) {
            Column({ space: 10 }) {
              Row() {
                Text("答案")
                  .fontColor('#D87147')
                  .fontSize(this.isPortrait ? 20 : 14)
                Text("C")
                  .fontColor('#D87147')
                  .fontSize(this.isPortrait ? 20 : 14)
              }
              .padding(this.isPortrait ? 10 : 5)

              Text('新设备、新材料的同时，应制定相应的（）依据配电安规，在试验和推广新技术、新工艺、本单位批准后执行。')
                .fontSize(this.isPortrait ? 18 : 13)
                .padding({
                  top: this.isPortrait ? 5 : 2,
                  bottom: this.isPortrait ? 5 : 2
                })
              Text("A-组织措施")
                .fontSize(this.isPortrait ? 18 : 13)
              Text("A-组织措施")
                .fontSize(this.isPortrait ? 18 : 13)
              Text("A-组织措施")
                .fontSize(this.isPortrait ? 18 : 13)
              Text("A-组织措施")
                .fontSize(this.isPortrait ? 18 : 13)
            }
            .alignItems(HorizontalAlign.Start)
            .padding(this.isPortrait ? 20 : 10)
            .margin({
              left: this.isPortrait ? 20 : 0,
              right: this.isPortrait ? 20 : 40,
              bottom: this.isPortrait ? 0 : 40
            })
            .opacity(0.9 )
            .borderRadius(6)
            .width(this.isPortrait ? '90%' : '45%')
            .height(this.isPortrait ? 300 : '45%')
            .backgroundColor(Color.White)
            .alignRules(
              this.isPortrait
                ? {
                    bottom: {
                      anchor: "ct",
                      align: VerticalAlign.Top
                    }
                  }
                : {
                    right: { anchor: "__container__", align: HorizontalAlign.End },
                    bottom: { anchor: "__container__", align: VerticalAlign.Bottom }
                  }
            )

            Column() {
              Text( this.CameraChange? "锁定题目":"解锁题目")
                .backgroundColor("#ffe74c13")
                .width(this.isPortrait ? 280 : 200)
                .height(this.isPortrait ? 55 : 35)
                .borderRadius(6)
                .fontColor(Color.White)
                .textAlign(TextAlign.Center)
                .fontSize(this.isPortrait ? 20 : 14)
                .onClick(() => {
                  //TODO  解锁题目
                  if (!this.CameraChange){
                    this.CameraChange=true
                    cameraManager.releaseCamera()
                  }else {
                    this.CameraChange=false
                    cameraManager.initCamera(this.controller.getXComponentSurfaceId())
                  }

                })
            }
             .margin({
               bottom: this.isPortrait ? 20 : 10
             })
            .id('ct')
            .opacity(0.7)
            .padding(this.isPortrait ? 20 : 10)
            .alignRules({

              bottom: {
                anchor: "__container__",
                align: VerticalAlign.Bottom
              }
            })
          }
        }
        .alignRules(
          this.isPortrait?
          {

          bottom: {
            anchor: "__container__",
            align: VerticalAlign.Bottom
          }
        }
        :  {

            bottom: {
              anchor: "__container__",
              align: VerticalAlign.Bottom
            },
            right: {
              anchor: "__container__",
              align:HorizontalAlign.End
            }
          }
        )

      }
      .width("100%")
      .height("100%")

    }
    .width("100%")
    .height("100%")
  }
}