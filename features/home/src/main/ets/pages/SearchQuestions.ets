import { emitter } from "@kit.BasicServicesKit";
import { display, router, window as kitWindow } from "@kit.ArkUI";
import { accessManager } from "../utils/AccessManager";
import { cameraManager } from "../utils/CameraManager";
import window from '@ohos.window';
import { SearchEngine } from "search";
import { QuestionRes } from "db";
import { SearchMapManage } from "search/src/main/ets/manage/SearchMapManage";
import SearchConstants from "search/src/main/ets/constants/SearchConstants";
import { preferences } from "@kit.ArkData";

const TAG = "SearchQuestions";

@Entry({ routeName: "searchQuestionsPage" })
@Component
export struct SearchQuestions {
  @State dataValue: string = ""
  @State resultSearchRes: QuestionRes | null = null
  @State CameraChange: boolean = true
  @State isPortrait: boolean = true;
  @State orientation: number = display.Orientation.LANDSCAPE;
  controller: XComponentController = new XComponentController()
  win: window.Window | null = null
  map: PixelMap | null = null

  async aboutToAppear() {
    // 做分词处理，处理完毕后再搜索
    // 判断从哪个文件里取 mDataText 以及 mDataSize
    let mDataText: SharedArrayBuffer | null = null

    let sp = preferences.getPreferencesSync(getContext(this), SearchConstants.SEARCH_OPTIONS)
    if (sp.getSync(SearchConstants.isAll, true)) {
      mDataText =
        await SearchMapManage.getInstance()
          .loadSharedArrayBufferFromFile(getContext(this), SearchConstants.SEARCH_FILE_ALL)
    } else {
      mDataText =
        await SearchMapManage.getInstance()
          .loadSharedArrayBufferFromFile(getContext(this), SearchConstants.SEARCH_FILE_SOME)
    }

    console.debug(TAG, '分词处理数据已拿到')
    emitter.on("dataText", async (event) => {
      this.dataValue = event.data!["text"].replace(/\r?\n/g, '')
      // this.dataValue = "1415A 模拟考试 重置进度 0/119 ☆ 保守国家秘密法》自 G 2010年1月1日 2010年4月29日 2010年5月1日 2010年10月1日"
      if (mDataText && mDataText?.byteLength !== 0) {
        await this.searchResult(mDataText)
      }
    })
  }

  aboutToDisappear(): void {
    cameraManager.releaseCamera()
    emitter.off("dataText")
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
    Column() {

      RelativeContainer() {
        Column() {
          XComponent({
            type: XComponentType.SURFACE,
            controller: this.controller
          })
            .width("100%")
            .height("100%")
            .onLoad(() => {
              accessManager.CheckCamera(["ohos.permission.CAMERA"], () => {
                cameraManager.initCamera(this.controller.getXComponentSurfaceId())
              })
            })
        }

        // .rotate({ angle: 90 }) // 旋转45度

        Row() {
          Column() {
            Image($r("sys.media.ohos_ic_public_arrow_left"))
              .fillColor(Color.White)
              .width(25)
              .aspectRatio(1)
              .borderRadius(15)
              .backgroundColor("#504F4E")
              .onClick(() => {
                router.back()
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
                            this.isRightAnswer(this.answerTr(index, item), this.resultSearchRes?.answer) ? '#D87147' :
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
              Text(this.CameraChange ? "锁定题目" : "解锁题目")
                .backgroundColor("#ffe74c13")
                .width(this.isPortrait ? 280 : 320)
                .height(this.isPortrait ? 55 : 35)
                .borderRadius(6)
                .fontColor(Color.White)
                .textAlign(TextAlign.Center)
                .fontSize(this.isPortrait ? 20 : 14)
                .onClick(() => {
                  //TODO  解锁题目
                  if (this.CameraChange) {
                    this.CameraChange = false
                    cameraManager.releaseCamera()
                    // emitter.off('dataText')
                  } else {
                    this.CameraChange = true
                    cameraManager.initCamera(this.controller.getXComponentSurfaceId())
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
  }
}