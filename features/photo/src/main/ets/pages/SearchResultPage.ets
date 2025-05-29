import { CommonConstants, Logger } from 'utils/Index'
import { TitleBar } from 'widget/Index'
import { SearchModel } from '../model/SearchModel'
import { SearchResultRes } from '../model/SearchResultRes'
import { router } from '@kit.ArkUI'
import { BankListRes, QuestionRes } from 'db'
import { SearchEngine } from 'search'
import { emitter } from '@kit.BasicServicesKit'
import { ProgressLoading } from 'utils/src/main/ets/components/ProgressLoading'

@Entry({ routeName: 'searchResultPage' })
@Component
export struct SearchResultPage {
aboutToDisappear(): void {
  AppStorage.delete("ocr")
}
  controller: TabsController = new TabsController()
  list: string[] = ["题库广场", "本地题库"]
  @State activeTabIndex: number = 0 // 当前激活的 tab 索引

  @Builder
  getTabItemBuilder(item: string, index: number) {
    Column() {
      Text(item)
        .fontColor(this.activeTabIndex === index ? $r('app.color.c_f75a23') : Color.Black)
    }
    .justifyContent(FlexAlign.SpaceEvenly)

  }

  build() {
    Flex({ direction: FlexDirection.Column }) {
      TitleBar({
        title: '搜索结果',
        backClick: () => {
          router.back()
        }
      })

      Tabs({
        controller: this.controller,
        index: this.activeTabIndex
      }) {
        ForEach(this.list, (item: string, index: number) => {
          TabContent() {
            // 根据索引切换内容
            if (index === 0) {
              Column() {
                ListView()
              }
              .height("100%")
              .justifyContent(FlexAlign.Start)
            } else {

              Column() {
                LocalView()
              }
              .height("100%")
              .justifyContent(FlexAlign.Start)
            }
          }
          .tabBar(this.getTabItemBuilder(item, index))
        })
      }
      // .barMode(BarMode.Fixed)
      .onChange((index: number) => {
        this.activeTabIndex = index
      })
    }
  }
}


//本地题库
@Component
struct LocalView {
  @State isLoading:boolean=true
  @State dataValue: string = ""
  @State resultData: QuestionRes[] = []
  @StorageProp("ocr")
  text:string=""

  aboutToAppear(): void {
    this.getLocal()
  }

  getLocal() {

    SearchEngine.getInstance().queryQuestionsWithText(this.text.replace(/\r?\n/g, '')).then((data) => {
      this.resultData = data
      this.isLoading = false

    })

  }

  build() {
    if (this.isLoading) {
      ProgressLoading()
    } else {
    if (this.resultData.length > 0) {

      List() {

        ForEach(this.resultData,
          (item: QuestionRes) => {
            ListItem() {
              Column() {
                Text("答案: " + item.answer)
                  .fontSize(16)
                  .fontColor($r('app.color.c_f75a23'))
                  .margin({ bottom: 15 })
                  .align(Alignment.Start)
                Text(item.question)
                  .fontSize(16)
                  .align(Alignment.Start)
                ForEach(item.option, (optionTxt: string, index: number) => {
                  Text(`${String.fromCharCode(65 + index)}、${optionTxt}`)
                    .fontSize(16)
                    .fontColor(
                      item.answer.toLowerCase().includes(String.fromCharCode(97 + index))
                        ? $r('app.color.c_f75a23')
                        : $r('app.color.c_3e3e3e')
                    )
                    .margin({ top: 10 })
                })
                Flex({
                  direction: FlexDirection.Row,
                  justifyContent: FlexAlign.SpaceBetween,
                  alignItems: ItemAlign.Center,
                  wrap: FlexWrap.Wrap
                }) {

                  Text(item.qName)
                    .fontSize(14)
                    .fontColor($r('app.color.c_3e3e3e'))
                    .margin({ top: 30 })
                    .align(Alignment.Start)
                    .width('100%')
                }
              }
              .padding(15)
              .alignItems(HorizontalAlign.Start)

            }
            .width('92%')
            .shadow({
              radius: 15,
              color: $r('app.color.c_d3d3d3'),
            })
            .borderRadius(10)
            .margin({ left: 15, top: 15 })
            .align(Alignment.Start)
          }
        )
        ListItem() {
          BottomBar({
            searchClick: () => {
              router.back()
            }
          })
        }
      }
      .cachedCount(5)
    } else {
      Text($r('app.string.search_nodata'))
        .fontSize(16)
        .align(Alignment.Start)
        .fontColor($r('app.color.c_f75a23'))
    }
  }
  }
}

@Component
struct ListView {
  @State isLoading: boolean = true
  @State resultList: SearchResultRes[] = []
  @StorageProp("ocr")
  text: string = ""

  aboutToAppear(): void {
    // const params = router.getParams() as Record<string, string>
    // if (params) {
    //   let ocrTxtParam = params.ocrTxt as string
    //   this.text = ocrTxtParam.replaceAll("\n", "")
    // }
    this.getData()

  }

  getData() {
    SearchModel.getInstance().searchResultList(this.text.replace(/\r?\n/g, '')).then((data) => {
      this.resultList = data
      this.isLoading = false

    })
  }
  build() {
    if (this.isLoading) {
      ProgressLoading()
    } else {
     if (this.resultList.length > 0) {

      // ListItem() {
      //   //TODO 显示ocr识别后的文本，上线后需删除
      //   Text(this.ocrTxt)
      //     .fontSize(14)
      //     .align(Alignment.Start)
      //     .fontColor($r('app.color.c_ff0000'))
      // }


      List() {

        ForEach(this.resultList,
          (item: SearchResultRes, index: number) => {
            ListItem() {
              Column() {
                Text("答案: " + item.ans)
                  .fontSize(16)
                  .fontColor($r('app.color.c_f75a23'))
                  .margin({ bottom: 15 })
                  .align(Alignment.Start)
                Text(item.q)
                  .fontSize(16)
                  .align(Alignment.Start)
                ForEach(item.ASlice, (optionTxt: string, index: number) => {
                  Text(`${String.fromCharCode(65 + index)}、${optionTxt}`)
                    .fontSize(16)
                    .fontColor(
                      item.ans.toLowerCase().includes(String.fromCharCode(97 + index))
                        ? $r('app.color.c_f75a23')
                        : $r('app.color.c_3e3e3e')
                    )
                    .margin({ top: 10 })
                })
                Flex({
                  direction: FlexDirection.Row,
                  justifyContent: FlexAlign.SpaceBetween,
                  alignItems: ItemAlign.Center,
                  wrap: FlexWrap.Wrap
                }) {

                  Text(item.Name)
                    .fontSize(14)
                    .fontColor($r('app.color.c_3e3e3e'))
                    .margin({ top: 30 })
                    .align(Alignment.Start)
                    .width('100%')
                }
              }
              .padding(15)
              .alignItems(HorizontalAlign.Start)

            }
            .width('92%')
            .shadow({
              radius: 15,
              color: $r('app.color.c_d3d3d3'),
            })
            .borderRadius(10)
            .margin({ left: 15, top: 15 })
            .align(Alignment.Start)
            .onAppear(() => {
              if (index === this.resultList.length - 1) {
                this.isLoading = false
              }
            })
          }
        )
        //  }
        ListItem() {
          BottomBar({
            searchClick: () => {
              router.back()
            }
          })
        }
      }
      .cachedCount(5)

    } else {
      if (!this.resultList.length) {
        ProgressLoading()
      }
      Text($r('app.string.search_nodata'))
        .fontSize(16)
        .align(Alignment.Start)
        .fontColor($r('app.color.c_f75a23'))
        .onAppear(() => {
          this.isLoading = false
        })
    }
  }
  }
}

@Component
struct BottomBar {
  searchClick: () => void = () => {
  }

  build() {
    Stack() {
      Text($r('app.string.search_again'))
        .fontSize($r('app.float.font_size_18fp'))
        .fontColor($r('app.color.start_window_background'))
        .borderRadius(50)
        .textAlign(TextAlign.Center)
        .align(Alignment.Center)
        .width(CommonConstants.EIGHTY_PERCENT)
        .height($r('app.float.float_48vp'))
        .margin({ left: '10%', right: '10%' })
        .backgroundColor($r('app.color.c_f75a23'))
        .onClick(() => this.searchClick())
    }
    .padding({ top: $r('app.float.float_20vp') })
    .align(Alignment.BottomStart)
    .alignContent(Alignment.Center)
  }
}

