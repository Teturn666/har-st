import web_webview from '@ohos.web.webview'
import { TitleBar } from 'widget/Index'
import { webType } from '../model/webType'

@Builder
function ChWebPageBuilder() {
  ChWebPage()
}

@Component
export struct ChWebPage {
  @Consume appPathStack: NavPathStack
  controller: web_webview.WebviewController = new web_webview.WebviewController()
  webUrl = ''
  title = ''
  page = ''

  aboutToAppear(): void {
    const res = this.appPathStack.getParamByName('webPage') as webType[]
    if (res && res.length > 0) {
      const params = res[0]
      this.webUrl = params.url as string
      this.title = params.title as string
      if (params.page) {
        this.page = params.page
      }
    }
  }

  build() {
    NavDestination() {
      Column() {
        TitleBar({
          title: this.title, backClick: () => {
            if (this.page === 'mainPage') {
              this.appPathStack.popToIndex(-1, { mainShow: true })
              console.log("接受的参数，true");
            } else {
              this.appPathStack.pop()
            }
          }
        })
          .width('100%')
        Web({ src: this.webUrl, controller: this.controller })
          .layoutWeight(1)
      }
    }
    .hideTitleBar(true)
  }
}