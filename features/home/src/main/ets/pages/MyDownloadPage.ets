import { TitleBar } from 'widget'
import { router } from '@kit.ArkUI'
import { HomeModel } from '../model/HomeModel'
import { BankListRes } from 'db'
import { BankList } from 'bank/Index'


@Component
struct MyDownloadPage {
  @State homeModel: HomeModel = HomeModel.getInstance()
  @State questionBanks: BankListRes[] = []

  build() {
    NavDestination() {
      Column() {
        // TitleBar({
        //   title: '我的下载', backClick: () => {
        //     router.back()
        //   }
        // }).width('100%')
        BankList({
          fromType: 2
        })
      }

    }
    .hideTitleBar( true)
  }
}
@Builder
function MyDownloadPageBuilder() {
  MyDownloadPage()
}