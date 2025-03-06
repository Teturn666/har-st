import { HomePage } from '@ohos/home/Index';
import { MinePage } from '@ohos/mine/Index';
import { CustomTabBar } from '../components/CustomTabBar';
import { AppConstants } from '../constants/AppConstants';
import { TabBarType } from '../model/TabBarModel';

@Entry
@Component
struct MainPage {
  @LocalStorageLink('mainTabIndex') currentIndex: TabBarType = TabBarType.HOME;
  @Provide('appPathStack') appPathStack: NavPathStack = new NavPathStack();

  build() {
    Navigation(this.appPathStack) {
      Flex({
        direction: FlexDirection.Column,
      }) {
        Tabs({ index: this.currentIndex }) {
          TabContent() {
            HomePage()
          }

          TabContent() {
            MinePage()
          }
        }
        .layoutWeight(1)
        .barHeight(0)
        .scrollable(false)
        .onChange((index) => {
          this.currentIndex = index
        })

        CustomTabBar({ currentIndex: $currentIndex })
      }
      .width(AppConstants.FULL_PERCENT)
      .height(AppConstants.FULL_PERCENT)
      .backgroundColor($r('app.color.start_window_background'))
    }
    .hideTitleBar(true)
    // .navDestination(this.appRouter)
    .mode(NavigationMode.Stack)
  }
}

// function HomePage() {
//   throw new Error('Function not implemented.');
// }
