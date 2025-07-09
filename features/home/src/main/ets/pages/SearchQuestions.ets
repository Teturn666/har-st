import { emitter } from "@kit.BasicServicesKit";
import { display, window as kitWindow } from "@kit.ArkUI";
import { CameraManager, cameraManager } from "../utils/CameraManager";
import { SearchEngine } from "search";
import { QuestionRes } from "db";
import { EmitterConstants } from "utils";
import { MDataTextManage } from "search/src/main/ets/manage/MDataTextManage";
import { abilityAccessCtrl, Permissions } from "@kit.AbilityKit";
import { image } from "@kit.ImageKit";
import { ProgressLoading } from "utils/src/main/ets/components/ProgressLoading";


const TAG = "SearchQuestions";


@Component
export struct SearchQuestions {
  @State dataValue: string = ""
  @State resultSearchRes: QuestionRes | null = null
  @State CameraChange: boolean = true
  @State isPortrait: boolean = true;
  @State Search: boolean = true
  @State orientation: number = display.Orientation.LANDSCAPE;
  @State isOne: boolean = false;
  @State xComponentSurfaceId: string = '';
  @State isShow: boolean = false;
  @State isCamera: boolean = true;
  @State isXCom: boolean = true
  context: Context | undefined = this.getUIContext().getHostContext();
  @Consume appPathStack: NavPathStack
  controller: XComponentController = new XComponentController()
  cameraPermission: Permissions = 'ohos.permission.CAMERA';
  pixelMap: image.PixelMap | null = null

  async aboutToAppear() {
    cameraManager.context = this.context;
    this.requestPermissionsFn();

    // 取出最新的分词处理数据
    let mDataText = MDataTextManage.getInstance().getDataText()
    console.debug(TAG, '分词处理数据已拿到')
    emitter.on(EmitterConstants.EM_DATA_TEXT, async (event) => {
      if (this.Search) {
        this.dataValue = event.data!["text"].replace(/\r?\n/g, '')
        console.debug(TAG, 'dataValue' + this.dataValue)
        // this.dataValue = "1415A 模拟考试 重置进度 0/119 ☆ 保守国家秘密法》自 G 2010年1月1日 2010年4月29日 2010年5月1日 2010年10月1日"
        if (mDataText && mDataText?.byteLength !== 0 && this.dataValue) {
          await this.searchResult(mDataText)
        }
      }
    })
  }

  aboutToDisappear(): void {
    cameraManager.releaseCamera()
    this.resultSearchRes = null
  }

  async requestPermissionsFn(): Promise<void> {
    let atManager = abilityAccessCtrl.createAtManager();
    if (this.context) {
      let res = await atManager.requestPermissionsFromUser(this.context, [this.cameraPermission]);
      for (let i = 0; i < res.permissions.length; i++) {
        if (this.cameraPermission.toString() === res.permissions[i] && res.authResults[i] === 0) {
          this.isShow = true;
        }
      }
    }
  }

  private async searchResult(mDataText: SharedArrayBuffer) {
    this.resultSearchRes = await SearchEngine.getInstance().queryTextWithIndexInThread(this.dataValue, mDataText)
  }

  //转换答案前加ABCD
  private answerTr(index: number, answer: string): string {
    // if (/^[A-D]+$/.test(answer)) {
    //   return answer
    // }
    return String.fromCharCode(65 + index) + "-" + answer
  }

  //判断答案是否是正确答案
  private isRightAnswer(curAnswer: string, rightAnswer: string): boolean {
    return curAnswer.includes(rightAnswer)
  }

  build() {
    NavDestination() {
      Stack() {
        Column() {

          RelativeContainer() {
            Column() {
              if (this.isShow) {
                XComponent({
                  id: 'componentId',
                  type: XComponentType.SURFACE,
                  controller: this.controller
                })
                  .onLoad(async () => {
                    this.xComponentSurfaceId = this.controller.getXComponentSurfaceId(); // 获取组件surfaceId。
                    cameraManager.initCamera(this.xComponentSurfaceId).then(() => {
                      this.isXCom = false
                    })
                  })
                  .width('100%')
                  .height('100%')
              }
            }
            .justifyContent(FlexAlign.Center)
            .height('100%')
            .width('100%')

            Row() {
              Column() {
                Image($r("sys.media.ohos_ic_public_arrow_left"))
                  .fillColor(Color.White)
                  .width(25)
                  .aspectRatio(1)
                  .borderRadius(15)
                  .backgroundColor("#504F4E")
                  .onClick(() => {
                    this.appPathStack.pop()
                  })
              }
              .width(50)
              .aspectRatio(1)

              Column() {
                Image($r("app.media.screen_rotation"))
                  .fillColor(Color.White)
                  .width(25)
                  .aspectRatio(1)
                  .borderRadius(15)
                  .backgroundColor("#504F4E")
                  .onClick(() => {
                    this.isPortrait = !this.isPortrait;
                    // this.setScreenOrientation(this.isPortrait);
                  })
              }
              .width(50)
              .aspectRatio(1)
            }
            .width('100%')
            .height(30)
            .padding({
              left: 15, right: 15
            })
            .alignRules({
              top: { anchor: '__container__', align: VerticalAlign.Top },

            })
            .margin({ top: 20 })
            .justifyContent(FlexAlign.SpaceBetween)

            Column() {
              if (this.resultSearchRes != null) {
                Column({ space: 10 }) {
                  Scroll() {
                    Column() {
                      Text("答案：" + this.resultSearchRes.answer)
                        .fontColor('#D87147')
                        .fontSize(this.isPortrait ? 20 : 14)
                        .padding(this.isPortrait ? 10 : 5)

                      Column({ space: 7 }) {
                        Text(this.resultSearchRes.question)
                          .fontSize(this.isPortrait ? 18 : 12)
                          .padding({
                            top: this.isPortrait ? 5 : 2,
                            bottom: this.isPortrait ? 5 : 2
                          })
                        if (this.resultSearchRes.option.length > 0) {
                          ForEach(this.resultSearchRes.option, (item: string, index) => {
                            Text(this.answerTr(index, item))
                              .fontSize(this.isPortrait ? 18 : 12)
                              .fontColor(
                                this.isRightAnswer(this.answerTr(index, item), this.resultSearchRes?.answer) ?
                                  '#D87147' :
                                  '#3e3e3e'
                              )
                          })
                        }
                      }
                      .alignItems(HorizontalAlign.Start)
                    }
                    .width('100%')
                    .justifyContent(FlexAlign.Start)
                    .alignItems(HorizontalAlign.Start)
                  }
                  .scrollBar(BarState.Off)

                }
                .alignItems(HorizontalAlign.Start)

                .padding(this.isPortrait ? 20 : 10)
                .margin({
                  left: this.isPortrait ? 20 : 0,
                  right: this.isPortrait ? 20 : 0,
                  bottom: this.isPortrait ? 0 : 20,

                })
                .opacity(0.9)
                .borderRadius(6)
                .width(this.isPortrait ? '90%' : 320)
                .height(this.isPortrait ? 300 : 180)
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
                  Row() {
                    if (this.isCamera) {
                      Text(this.CameraChange ? "锁定题目" : "解锁题目")
                        .width("100%")
                        .fontColor(Color.White)
                        .textAlign(TextAlign.Center)
                        .fontSize(this.isPortrait ? 20 : 14)
                    } else {
                      ProgressLoading({ showText: false, pWidth: 30 })
                    }

                  }
                  .backgroundColor("#ffe74c13")
                  .width(this.isPortrait ? 280 : 320)
                  .height(this.isPortrait ? 55 : 35)
                  .borderRadius(6)
                  .enabled(this.isCamera)
                  .onClick(() => {
                    //TODO  解锁题目
                    if (this.CameraChange) {
                      this.CameraChange = false
                      this.Search = false
                      this.dataValue = ''
                      cameraManager.releaseCamera()
                    } else {
                      this.isCamera = false
                      cameraManager.initImageReceiver()
                      cameraManager.initCamera(this.xComponentSurfaceId).then(() => {
                        this.Search = true
                        this.CameraChange = true
                        this.isCamera = true
                      })

                    }
                  })

                }
                .margin({
                  bottom: this.isPortrait ? 20 : 20
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
            .justifyContent(FlexAlign.Start)
            .margin({
              right: this.isPortrait ? 0 : 130,
              bottom: this.isPortrait ? 0 : 70
            })
            .rotate({ angle: this.isPortrait ? 0 : 90 }) // 旋转45度
            .alignRules(
              this.isPortrait ?
                {
                  bottom: {
                    anchor: "__container__",
                    align: VerticalAlign.Bottom
                  }
                }
                : {
                bottom: {
                  anchor: "__container__",
                  align: VerticalAlign.Bottom
                },
                right: {
                  anchor: "__container__",
                  align: HorizontalAlign.End
                }
              }
            )

          }

          .width("100%")
          .height("100%")
        }

        .width("100%")
        .height("100%")

        if (this.isXCom) {
          ProgressLoading({ showText: false, pWidth: 30 })
        }
      }
    }
    .hideTitleBar(true)
    .onShown(() => {
      cameraManager.initImageReceiver()
      if (this.xComponentSurfaceId !== '') {
        cameraManager.initCamera(this.xComponentSurfaceId)
      }
    })
    .onDisAppear(() => {
      cameraManager.releaseCamera()
      this.resultSearchRes = null
    })
  }
}

@Builder
function SearchQuestionsBuilder() {
  SearchQuestions()
}