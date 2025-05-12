import router from '@ohos.router'
import { BankListRes } from '../model/BankListRes'
import HomeConstants from '../Constants/HomeConstants'

import('./ExercisePage')

//我的下载、题库练习、错题练习、收藏练习列表共用的页面
@Entry({ routeName: 'bankListPage' })
@Component
export struct BankListPage {
  title = ''

  aboutToAppear(): void {
    const params = router.getParams() as Record<string, string>
    if (params) {
      this.title = params.title as string
    }
  }

  @State questionBanks: BankListRes[] = [
    { qid: 1, name: '数数学题数学题库学题库学题库数学题库数学题库库数学题库数学题库学题库', desc: '高考数学', time: '2025-05-09', url: 'https://example.com/math', num: '100', version: '1.0', position: 1, downloadedState: 1 },
    { qid: 2, name: '英语题库', desc: 'CET-4', time: '2025-05-09', url: 'https://example.com/english', num: '200', version: '1.1', position: 2, downloadedState: 2 },
    { qid: 3, name: '物理题库', desc: '高中物理', time: '2025-05-09', url: 'https://example.com/physics', num: '150', version: '1.0', position: 3, downloadedState: 2 }
  ];

  // 题库
  private onQuestionBankTap(qid: number): void {
    router.pushNamedRoute({
      name: HomeConstants.ROUTER_EXERCISE_LIST
    }, router.RouterMode.Single)
  }

  build() {
    Column() {
      Row() {
        Image($r('app.media.ic_back'))
          .objectFit(ImageFit.Contain)
          .size({ width: $r('app.float.float_48vp'), height: $r('app.float.float_48vp') })
          .margin({ left: 15, right: 15 })
          .align(Alignment.TopStart)
          .onClick(() =>  router.back())
        Text(this.title)
          .fontSize($r('app.float.font_size_18fp'))
          .fontColor($r('app.color.c_black'))
          .textAlign(TextAlign.Center)
          .width('60%')
      }
      .margin({ top: 15 })
      .width('100%')

      List({ space: 10 }) {
        ForEach(this.questionBanks, (bank: BankListRes) => {
          ListItem() {
            Column() {
              Row() {
                Text(bank.name)
                  .fontSize(12)
                  .fontColor('#060606')
                  .margin({ left: 16, right: 16 })
                  .width('80%')
                Blank()
                Image($r('app.media.ic_right'))
                  .width(12)
                  .height(12)
                  .fillColor('#666666')
                  .margin({ right: 16 })
              }
              .width('100%')
              .height(48)
              .alignItems(VerticalAlign.Center)
            }
            .borderRadius(10)
            .backgroundColor('#F6F6F6')
            .onClick(() => {
              this.onQuestionBankTap(bank.qid);
            })
          }
        }, (bank: BankListRes) => String(bank.qid))
      }
      .width('100%')
      .padding({ left: 12, right: 12, top: 8, bottom: 8 })



    }.alignItems(HorizontalAlign.Center)
    .width('100%')
    .height('100%')
  }
}