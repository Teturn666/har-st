import { BankListRes } from 'db'
import { Logger } from 'utils'
import { cameraAppStorage } from '../Constants/CameraAppStorage'
import HomeConstants from '../Constants/HomeConstants'
import { HomeModel } from '../model/HomeModel'
import { NavChangeString, NavDoubleString, NavQid } from '../model/NavGenericType'
import { HomeNet } from '../service/HomeNet'


//我的下载、题库练习、错题练习、收藏练习列表共用的页面

@Component
export struct BankListPage {
  title = ''
  @State questionBanks: BankListRes[] = [];
  @State type: number = 1 // 1=题库练习, 2=错题练习, 3=收藏练习
  @State homeModel: HomeModel = HomeModel.getInstance()
  @StorageProp(cameraAppStorage.SELECT_CHANGE_TEXT) @Watch('ChangeTxt') text: number = 0
  @Consume appPathStack: NavPathStack

  ChangeTxt() {
    if (this.text === 1) {
      this.homeModel.getBankList()
        .then(banks => {
          this.questionBanks = banks;
        })
        .catch((error: Error) => {
          console.error("Error fetching bank list:", error);
        });
    } else if (this.text === 2) {
      this.homeModel.getWrongBankList()
        .then(banks => {
          this.questionBanks = banks;
        })
        .catch((error: Error) => {
          console.error("Error fetching wrong bank list:", error);
        });
    } else if (this.text === 3) {
      this.homeModel.getCollectionBankList()
        .then(banks => {
          this.questionBanks = banks;
        })
        .catch((error: Error) => {
          console.error("Error fetching collection bank list:", error);
        });
    }
    AppStorage.setOrCreate('ChangeText', 0)
  }

  aboutToAppear(): void {
    const res = this.appPathStack.getParamByName(HomeConstants.ROUTER_BANK_LIST) as NavDoubleString[]
    if (res && res.length) {
      const params = res[0]
      // 解析 title 和 type
      if (params.title) {
        this.title = params.title
      }
      if (params.type) {
        this.type = parseInt(params.type, 10) || 1
      }
      if (this.type === 1) {
        this.homeModel.getBankList()
          .then(banks => {
            this.questionBanks = banks
          })
      } else if (this.type === 2) {
        this.homeModel.getWrongBankList()
          .then(banks => {
            this.questionBanks = banks
          })
      } else {
        this.homeModel.getCollectionBankList()
          .then(banks => {
            this.questionBanks = banks
          })
      }
    }

  }

  // 题库
  private onQuestionBankTap(qid: BankListRes): void {

    if (this.type === 1) {
      this.appPathStack.pushPathByName(HomeConstants.ROUTER_EXERCISE_LIST, {
        qid: qid.qid,
        positions:qid.position
      } as NavQid)

    } else if (this.type === 2 || this.type === 3) {
      // this.appPathStack.pushPathByName(HomeConstants.ROUTER_EXERCISE_COMMON_LIST, {
      //   practiceMode: this.type,
      //   qid: qid
      // } as NavQid)

    }

  }

  build() {
    NavDestination() {
      Column() {
        PageHeader({
          title: this.title,
          onBack: () => this.appPathStack.pop()
        })

        if (this.questionBanks.length > 0) {
          BankList({
            banks: this.questionBanks,
            onItemTap: (qid) => this.onQuestionBankTap(qid)
          })
        } else {
          // 无数据，渲染空状态
          EmptyState({ type: this.type })
        }


      }.alignItems(HorizontalAlign.Center)
      .width('100%')
      .height('100%')
    }
    .hideTitleBar(true)

  }
}

@Component
struct PageHeader {
  @Prop title: string = ''
  onBack: () => void = () => {
  }

  build() {
    Row() {
      Image($r('app.media.ic_back'))
        .objectFit(ImageFit.Contain)
        .size({ width: $r('app.float.float_48vp'), height: $r('app.float.float_48vp') })
        .margin({ left: 15, right: 15 })
        .align(Alignment.TopStart)
        .onClick(() => this.onBack())

      Text(this.title)
        .fontSize($r('app.float.font_size_18fp'))
        .fontColor($r('app.color.c_black'))
        .textAlign(TextAlign.Center)
        .width('60%')
    }
    .margin({ top: 15 })
    .width('100%')
  }
}

@Component
struct EmptyState {
  @Prop type: number = 1

  private getEmptyMessage(): string {
    switch (this.type) {
      case 2:
        return '暂无错题，请先去题库练习做题，或选择题库进行模拟考试'
      case 3:
        return '暂无收藏，请先去练习或考试中添加'
      default:
        return '暂无可练题库，您可以去题库广场下载'
    }
  }

  build() {
    Column() {
      Image($r('app.media.ic_no'))
        .width(117)
        .height(100)

      Text(this.getEmptyMessage())
        .fontSize($r('app.float.font_size_16fp'))
        .fontColor('#9D9D9D')
        .fontSize(14)
        .margin({ top: 20 })
        .textAlign(TextAlign.Center)
    }
    .alignItems(HorizontalAlign.Center)
    .justifyContent(FlexAlign.Center)
    .padding({ left: 20, right: 20 })
    .width('100%')
    .height('100%')
  }
}

@Component
struct BankList {
  @Prop banks: BankListRes[] = []
  onItemTap: (qid: BankListRes) => void = () => {
  }

  build() {
    List({ space: 10 }) {
      ForEach(this.banks, (bank: BankListRes) => {
        ListItem() {
          Column() {
            Row() {
              Text(bank.name)
                .fontSize(12)
                .fontColor('#060606')
                .margin({ left: 16, right: 16 })
                .width('80%')

              Blank()

              Image($r('app.media.ic_r'))
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
          .onClick(() => this.onItemTap(bank))
        }
      }, (bank: BankListRes) => String(bank.qid))
    }
    .layoutWeight(1)
    .width('100%')
    .padding({
      left: 12,
      right: 12,
      top: 8,
      bottom: 8
    })
  }
}

@Builder
function BankListPageBuilder() {
  BankListPage()
}
