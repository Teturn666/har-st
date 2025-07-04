import { HomeModel } from '../model/HomeModel'
import { BankListRes } from 'db'
import { BankList } from 'bank/Index'
import HomeConstants from '../Constants/HomeConstants'
import { NavQid } from '../model/NavGenericType'


@Component
struct MyDownloadPage {
  @State homeModel: HomeModel = HomeModel.getInstance()
  @State questionBanks: BankListRes[] = []
  @Consume appPathStack: NavPathStack
  @State myDown: string = ''

  aboutToAppear(): void {
    const res = this.appPathStack.getParamByName(HomeConstants.ROUTER_MY_DOWNLOAD) as NavQid[]
    if (res && res.length > 0 && res[0].bankPage) {
      this.myDown = res[0].bankPage
    }
  }

  build() {
    NavDestination() {
      Column() {
        // TitleBar({
        //   title: '我的下载', backClick: () => {
        //     router.back()
        //   }
        // }).width('100%')
        BankList({
          fromType: 2,
          myDown: this.myDown
        })
      }

    }
    .hideTitleBar(true)
  }
}

@Builder
function MyDownloadPageBuilder() {
  MyDownloadPage()
}