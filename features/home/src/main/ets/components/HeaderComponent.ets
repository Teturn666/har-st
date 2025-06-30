import { promptAction, } from '@kit.ArkUI';
import HomeConstants from '../Constants/HomeConstants';
import { NavQid } from '../model/NavGenericType';

@Component
export  struct HeaderComponent {
  @Prop selectedIndex: number = 0;
  @Prop qid: number = 0;
  @Consume appPathStack: NavPathStack
  onModeChange: (index: number) => void = () => {

  };

  build() {
    NavDestination() {
      Flex({ direction: FlexDirection.Row, alignItems: ItemAlign.Center }) {
        Image($r('app.media.ic_back'))
          .objectFit(ImageFit.Contain)
          .size({ width: $r('app.float.float_48vp'), height: $r('app.float.float_48vp') })
          .margin({ left: 15, right: 75 })
          .align(Alignment.TopStart)
          .onClick(() => {
           this.appPathStack.pop();
          })

        Flex({ direction: FlexDirection.Row, alignItems: ItemAlign.Center }) {
          Button() {
            Row() {
              Button('答题')
                .fontColor(this.selectedIndex === 0 ? '#d2a129' : '#FFFFFF')
                .fontSize($r('app.float.font_size_12fp'))
                .border({ width: 1, color: '#d2a129' })
                .width(60)
                .height(28)
                .backgroundColor(this.selectedIndex === 0 ? '#FFFFFF' : '#d2a129')
                .borderRadius(6)
                .padding({ left: 12, right: 12 })
                .onClick(() => {
                  this.onModeChange(0);
                  promptAction.showToast({ message: '切换到答题' });
                })
              Button('背题')
                .fontColor(this.selectedIndex === 1 ? '#d2a129' : '#FFFFFF')
                .fontSize($r('app.float.font_size_12fp'))
                .border({ width: 1, color: '#d2a129' })
                .width(60)
                .height(28)
                .backgroundColor(this.selectedIndex === 1 ? '#FFFFFF' : '#d2a129')
                .borderRadius(6)
                .padding({ left: 12, right: 12 })
                .onClick(() => {
                  this.onModeChange(1);
                  promptAction.showToast({ message: '切换到背题' });
                })
            }
            .justifyContent(FlexAlign.SpaceBetween)
            .alignItems(VerticalAlign.Center)
          }
          .backgroundColor('#d2a129')

          Blank()
          Button('模拟考试')
            .width(70)
            .height(28)
            .backgroundColor('#d2a129')
            .borderRadius(6)
            .padding({ left: 12, right: 12 })
            .margin({ right: 12 })
            .onClick(() => {
              this.appPathStack.pushPathByName(HomeConstants.ROUTER_EXERCISE_COMMON_LIST,{
                practiceMode: 1,
                qid: this.qid
              } as  NavQid)

            })
        }
      }
    }
    .hideTitleBar( true)
  }
}