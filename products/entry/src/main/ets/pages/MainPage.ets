import { HomePage } from '@ohos/home/Index';
import { BankPage } from '@ohos/bank/Index';
import { MinePage } from '@ohos/mine/Index';
import { CustomTabBar } from '../components/CustomTabBar';
import { AppConstants } from '../constants/AppConstants';
import HomeConstants from '../../../../../../features/home/src/main/ets/Constants/HomeConstants';
import { TabBarType } from '../model/TabBarModel';
import router from '@ohos.router'
import { preferences } from '@kit.ArkData';
import { common } from '@kit.AbilityKit';
import hilog from '@ohos.hilog';

const context = (getContext(this) as common.UIAbilityContext)

@Entry
@Component
struct MainPage {
  @LocalStorageLink('mainTabIndex') currentIndex: TabBarType = TabBarType.HOME;
  @Provide('appPathStack') appPathStack: NavPathStack = new NavPathStack();
  @State showDialog: boolean = true
  private sp: preferences.Preferences | null = null

  private initPreferences() {
    this.sp = preferences.getPreferencesSync(context, HomeConstants.SP_OPTIONS)
    let show = this.sp.getSync("isFirstInstall", false)
    if (typeof show === 'boolean') {
      this.showDialog = show
    }
  }

  constructor() {
    super();
    this.initPreferences()
  }

  build() {
    RelativeContainer() {
      Navigation(this.appPathStack) {
        Flex({
          direction: FlexDirection.Column,
        }) {
          Tabs({ index: this.currentIndex }) {
            TabContent() {
              HomePage()
            }

            TabContent() {
              BankPage()
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

      if (this.showDialog) {
        Column() {
          Blank()
          Column() {
            Row() {
              Text("用户协议").fontColor($r('app.color.c_f75a23'))
                .fontSize(18).onClick(() => {
                router.pushNamedRoute({
                  name: "webPage", params: {
                    url: "https://ti.iksdt.com/static/doc/yszc.html",
                    title: "用户协议"
                  }
                })
              }).margin({ left: 12 })
              Text("和").fontColor($r('app.color.c_3e3e3e'))
                .fontSize(18)
              Text("隐私政策").fontColor($r('app.color.c_f75a23'))
                .fontSize(18).onClick(() => {
                router.pushNamedRoute({
                  name: "webPage", params: {
                    url: "https://ti.iksdt.com/static/doc/yszc.html",
                    title: "用户协议"
                  }
                })
              })
              Blank()
            }.width('100%').margin({ top: 32 })

            Row() {
              Text($r('app.string.privacy_hint'))
                .fontColor($r('app.color.c_8a8a8a'))
                .fontSize(14)
                .padding({ left: 12, right: 12 })
            }.width('100%')

            Row() {
              Blank()
              Text("不同意并退出")
                .fontColor($r('app.color.c_b1844e'))
                .fontSize(12)
                .width('40%')
                .height(80)
                .textAlign(TextAlign.Center)
                .onClick(() => {

                })
              Blank()
              Text("同意并继续")
                .fontColor($r('app.color.c_2a5089'))
                .fontSize(12)
                .width('40%')
                .height(80)
                .textAlign(TextAlign.Center)
                .onClick(() => {
                  this.showDialog = false
                })
              Blank()
            }.width('100%')
          }.width('90%').linearGradient({
            colors: [
              [$r("app.color.c_f6eee3"), 0.0],
              [$r("app.color.c_f4f3fb"), 0.5],
              [$r("app.color.start_window_background"), 1],
            ]
          }).borderRadius(5)

          Blank()
        }.width('100%').height('100%').backgroundColor($r('app.color.c_99000000'))
      }

    }
  }
}

// function HomePage() {
//   throw new Error('Function not implemented.');
// }
