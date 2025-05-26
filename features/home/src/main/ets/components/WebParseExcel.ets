import { webview } from '@kit.ArkWeb';

export class WebClass {
  static webviewController: webview.WebviewController = new webview.WebviewController();

  constructor() {
  }
}


@Component
export struct WebParseExcel {
  @State webClassObj: WebClass = new WebClass();

  build() {
    Column() {
      Web({ src: $rawfile('webParseExcel.html'), controller: WebClass.webviewController })
        .height(1)
        .visibility(Visibility.Hidden)
    }
  }
}


