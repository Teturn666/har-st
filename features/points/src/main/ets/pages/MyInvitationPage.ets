import { TitleBar } from 'widget/Index'
import router from '@ohos.router';

@Entry
@Component
struct MyInvitationPage {
  @State title:string = "我的邀请码";

  build() {
    Column() {
      TitleBar({
        title: this.title, backClick: () => {
          router.back()
        }
      })
        .width('100%')
    }
    .backgroundColor('##fff9ed')
    .height('100%')
    .width('100%')
  }
}