import { CommonConstants, Logger } from '@ohos/utils/Index'
import { TitleBar } from '@ohos/widget/Index'
import router from '@ohos.router'
import { SearchModel } from '../model/SearchModel'
import { QuestionRes } from '@ohos/db'
import { SearchDecryptUtils } from '@ohos/search'
import { SearchResultBean } from '../model/SearchResultBean'


@Entry({ routeName: 'searchResultPage' })
@Component
export struct SearchResultPage {
  build() {
    Flex({ direction: FlexDirection.Column }) {
      TitleBar({
        title: '搜索结果', backClick: () => {
          router.back()
        }
      })
      ListView()
      BottomBar({
        findClick: () => {
          //TODO 找不到题的监听
        },
        payClick: () => {

        },
        searchClick: () => {

        }
      })
    }
  }
}

@Component
struct ListView {
  @State resultData: SearchResultBean[] = []
  ocrTxt = '驾驶人'

  aboutToAppear(): void {
    const params = router.getParams() as Record<string, string>
    if (params) {
      let ocrTxtParam = params.ocrTxt as string
      this.ocrTxt = ocrTxtParam.replaceAll("\n", "")
    }


    // SearchModel.getInstance().searchResultList(this.ocrTxt).then(async (value: QuestionRes[]) => {

    // for (let i = 0; i < value.length; i++) {
    //   let res = value[i]
    //
    //   let question = await SearchDecryptUtils.getQuestionWithPrefix(3, res.question, res.questionCase)
    //   let optionAry = await SearchDecryptUtils.getOptionsWithPrefix(".", res.option)
    //
    //   let searchResultBean = new SearchResultBean()
    //   searchResultBean.question = question
    //   searchResultBean.optionAry = optionAry
    //   searchResultBean.answer = res.answer
    //   for (let index = 0; index < optionAry.length; index++) {
    //     let pos = SearchDecryptUtils.isCorrectAnswer(index, res.answer)
    //     if (pos != -1) {
    //       searchResultBean.answerAry.push(pos)
    //     }
    //   }
    //   this.resultData.push(searchResultBean)
    // }
    // })

    for (let i = 0; i < 20; i++) {
      let searchResultBean = new SearchResultBean()
      this.resultData.push(searchResultBean)
    }
  }

  build() {
    List() {
      ListItem() {
        //TODO 显示ocr识别后的文本，上线后需删除
        Text(this.ocrTxt)
          .fontSize(14)
          .align(Alignment.Start)
          .fontColor($r('app.color.c_ff0000'))
      }

      ForEach(this.resultData,
        (item: SearchResultBean) => {
          ListItem() {
            Column() {
              Text("答案：" + item.answer)
                .fontSize(16)
                .fontColor($r('app.color.c_f75a23'))
                .margin({ bottom: 15 })
                .align(Alignment.Start)
              Text(item.question)
                .fontSize(16)
                .align(Alignment.Start)

              ForEach(item.optionAry, (optionTxt: string, index: number) => {
                if (item.answerAry.includes(index)) {
                  Text(optionTxt).fontSize(16).fontColor($r('app.color.c_f75a23')).margin({ top: 10 })
                } else {
                  Text(optionTxt).fontSize(16).fontColor($r('app.color.c_3f3f3f')).margin({ top: 10 })
                }
              })
              Flex({
                direction: FlexDirection.Row,
                justifyContent: FlexAlign.SpaceBetween,
                alignItems: ItemAlign.Center,
                wrap: FlexWrap.Wrap
              }) {
                Row() {
                  Text("题库名称")
                    .fontSize(14)
                    .fontColor($r('app.color.c_3e3e3e'))
                    .margin({ top: 30 })
                    .align(Alignment.Start)
                  Text("（下载状态）")
                    .fontSize(14)
                    .fontColor($r('app.color.c_9d9d9d'))
                    .margin({ top: 30 })
                    .align(Alignment.Start)
                }

                Text("去下载")
                  .fontSize(14)
                  .fontColor($r('app.color.c_1f59a8'))
                  .margin({ top: 30 })
                  .align(Alignment.End)
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
    }
    .cachedCount(5)
  }
}

@Component
struct BottomBar {
  findClick: () => void = () => {
  }
  payClick: () => void = () => {
  }
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