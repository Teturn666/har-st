
import { emitter } from "@kit.BasicServicesKit";
import { window } from "@kit.ArkUI";
import { accessManager } from "../utils/AccessManager";
import { cameraManager } from "../utils/CameraManager";
import { ocrToText } from "../utils/OcrToText";

@Entry({ routeName: "searchQuestionsPage" })
@Component
export struct SearchQuestions {
  @State TopHeight:number=0
  @State dataValue:string=""
  @State CameraChange:boolean=false
  controller: XComponentController = new XComponentController()
  win:window.Window|null=null
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
    this.win =await window.getLastWindow(getContext())
    this.TopHeight=this.win.getWindowAvoidArea(window.AvoidAreaType.TYPE_SYSTEM).topRect.height
    this.win.setWindowLayoutFullScreen(true)
  }
  build() {
    Column() {

      RelativeContainer() {

        XComponent({
          type: XComponentType.SURFACE,
          controller: this.controller
        }).width("100%")
          .height('100%')

          .onLoad(() => {

            accessManager.CheckCamera(["ohos.permission.CAMERA"], () => {
           cameraManager.initCamera(this.controller.getXComponentSurfaceId())

            })
          })
        Row(){
          Image($r("sys.media.ohos_ic_public_arrow_left" ))
            .fillColor(Color.White)
            .width(30)
            .aspectRatio(1)
            .borderRadius(15)
            .backgroundColor("#504F4E")
          Image($r("sys.media.ohos_ic_public_web"))
            .fillColor(Color.White)
            .width(30)
            .aspectRatio(1)
            .borderRadius(15)
            .backgroundColor("#504F4E")
        }
        .width('100%')
        .height(30)
        .padding({
          left:20,right:20
        })
        .alignRules({
          top: { anchor: '__container__', align: VerticalAlign.Top },

        })
        .margin({top:px2vp(this.TopHeight)})
        .justifyContent(FlexAlign.SpaceBetween)
        Column() {
          if (this.dataValue) {
          Column({ space: 10 }) {
              Row() {
                Text("答案")
                  .fontColor('#D87147')
                Text("C")
                  .fontColor('#D87147')
              }
              .padding({})

              Text('新设备、新材料的同时，应制定相应的（）依据配电安规，在试验和推广新技术、新工艺、本单位批准后执行。')
                .padding({
                  top: 5,
                  bottom: 5
                })
              Text("A-组织措施")
              Text("A-组织措施")
              Text("A-组织措施")
              Text("A-组织措施")
            }
            .alignItems(HorizontalAlign.Start)
            .padding(20)
            .margin({
              left: 20, right: 20
            })
            .opacity(0.9 )
            .borderRadius(6)
            .width('90%')
            .height(300)
            .backgroundColor(Color.White)

            .alignRules({

              bottom: {
                anchor: "ct",
                align: VerticalAlign.Top
              }
            })

            Column() {
              Text( this.CameraChange? "锁定题目":"解锁题目")
                .backgroundColor("#ffe74c13")
                .width('100%')
                .height(55)
                .borderRadius(6)
                .fontColor(Color.White)
                .textAlign(TextAlign.Center)
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
               bottom:20
             })
            .id('ct')
            .opacity(0.7)
            .padding(20)
            .alignRules({

              bottom: {
                anchor: "__container__",
                align: VerticalAlign.Bottom
              }
            })
          }
        }
        .alignRules({

          bottom: {
            anchor: "__container__",
            align: VerticalAlign.Bottom
          }
        })

      }
      .width("100%")
      .height("100%")

    }
    .width("100%")
    .height("100%")
  }
}