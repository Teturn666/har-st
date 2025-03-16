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

    SearchModel.getInstance().searchResultList(this.ocrTxt).then(async (value: QuestionRes[]) => {

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
    })
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
              Text(item.question)
                .fontSize(14)
                .align(Alignment.Start)
              //测试看高亮的文本是否和答案一致
              // Text(item.answer)
              //   .fontSize(14)
              //   .align(Alignment.Start)
              Image(item.questionImg)
                .objectFit(ImageFit.Contain)
                .size({ width: 100 })
                .margin({ left: $r('app.float.float_20vp'), bottom: $r('app.float.float_20vp') })
              ForEach(item.optionAry, (optionTxt: string, index: number) => {

                if (item.answerAry.includes(index)) {
                  Text(optionTxt).fontSize(14).fontColor($r('app.color.c_1f59a8'))
                } else {
                  Text(optionTxt).fontSize(14).fontColor($r('app.color.c_3f3f3f'))
                }
              })
            }
            .padding(15)
            .alignItems(HorizontalAlign.Start)
          }
          .width('92%')
          .backgroundColor($r('app.color.c_f4f4f4'))
          .borderRadius(10)
          .margin({ left: 15, top: 15 })
          .align(Alignment.Start)

        })
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
      Row() {
        Column() {
          Image($r('app.media.ic_cant_find'))
            .objectFit(ImageFit.Contain)
            .size({ width: $r('app.float.float_24vp'), height: $r('app.float.float_24vp') })
          Text($r('app.string.not_find_question'))
            .fontSize($r('app.float.font_size_12fp'))
            .fontColor($r('app.color.c_3f3f3f'))
            .textAlign(TextAlign.Center)
        }
        .width(CommonConstants.TWENTY_FIVE_PERCENT)
        .onClick(() => this.findClick())

        Column() {
          Image($r('app.media.ic_recharge_times'))
            .objectFit(ImageFit.Contain)
            .size({ width: $r('app.float.float_24vp'), height: $r('app.float.float_24vp') })
          Text($r('app.string.pay_times'))
            .fontSize($r('app.float.font_size_12fp'))
            .fontColor($r('app.color.c_3f3f3f'))
            .textAlign(TextAlign.Center)
        }
        .width(CommonConstants.TWENTY_PERCENT)
        .onClick(() => this.payClick())

        Stack({ alignContent: Alignment.Center }) {
          Image($r('app.media.bg_btn'))
            .objectFit(ImageFit.Contain)
            .size({ width: $r('app.float.float_140vp'), height: $r('app.float.float_48vp') })
          Column() {
            Text($r('app.string.continue_search'))
              .fontSize($r('app.float.font_size_16fp'))
              .fontColor($r('app.color.start_window_background'))
            Text($r('app.string.residue_times'))
              .fontSize($r('app.float.font_size_10fp'))
              .fontColor($r('app.color.start_window_background'))
          }
        }
        .width(CommonConstants.SIXTY_PERCENT)
        .onClick(() => this.searchClick())
      }
    }
    .padding({ top: $r('app.float.float_10vp') })
    .align(Alignment.BottomStart)
  }
}