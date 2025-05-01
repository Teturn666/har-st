import { TitleBar } from 'widget/Index'
import router from '@ohos.router'

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

  build() {
    Column() {
      TitleBar({
        title: this.title, backClick: () => {
          router.back()
        }
      }).width('100%')

    }.alignItems(HorizontalAlign.Center)
    .width('100%')
    .height('100%')
  }
}