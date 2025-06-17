import { HomePage } from 'home/Index';
import { BankPage } from 'bank/Index';
import { MinePage } from 'mine/Index';
import { CustomTabBar } from '../components/CustomTabBar';
import { AppConstants } from '../constants/AppConstants';
import { TabBarType } from '../model/TabBarModel';
import router from '@ohos.router'
import { common } from '@kit.AbilityKit';
import { init } from '@umeng/analytics';
import { MainModel } from '../model/MainModel';
import { preferencesUtils, PreferencesConstants, EmitterConstants } from 'utils/Index'
import { emitter } from '@kit.BasicServicesKit';
import { splashAd } from '../utils/SplashAd';
import { ConfigRes } from 'utils/src/main/ets/model/ConfigRes';
import { HmAdInfo } from 'utils/src/main/ets/model/HmAdInfo';
import { CSJStartResult } from 'utils/src/main/ets/model/StartResult';

const context = (getContext(this) as common.UIAbilityContext)

@Entry
@Component
struct MainPage {
  @LocalStorageLink('mainTabIndex') currentIndex: TabBarType = TabBarType.HOME;
  @Provide('appPathStack') appPathStack: NavPathStack = new NavPathStack();
  @State showDialog: boolean = false
  @State mainModel: MainModel = MainModel.getInstance()
  @State isShow: boolean = false
  @State timer: number = 0
  @State configRes: ConfigRes = new ConfigRes()
  @State isVip: number = 0
  @State csjFail: boolean = false
  @State CsjHmAD: ConfigRes = {
    hmAd: new HmAdInfo()
  }
  @StorageProp("isInit")
  AdInit: CSJStartResult = {
    code: 0,
    msg: ""
  }

  private initPreferences() {
    //初始化sp实例
    preferencesUtils.setContext(context)
    this.showDialog = preferencesUtils.getBoolean(PreferencesConstants.SP_IS_FIRST_INSTALL, true)
  }

  // 修改布尔值的方法
  updateBooleanValue(newValue: boolean) {
    preferencesUtils.putBoolean(PreferencesConstants.SP_IS_FIRST_INSTALL, newValue)
  }

  aboutToAppear(): void {
    splashAd.ctx = this.getUIContext()
    this.initPreferences()
    this.mainModel.initDb()
    this.CsjHmAD = preferencesUtils.getGenerics(PreferencesConstants.CSJ_AD_PARAMS);
    this.isVip = preferencesUtils.getNumber(PreferencesConstants.SP_IS_VIP);
    this.csjFail = preferencesUtils.getBoolean(PreferencesConstants.CSJ_INIT_FAIL);

    this.getCSJ()
    this.ShowSplash()
  }

  async getCSJ() {
    await MainModel.getInstance().getConfigList()


  }

  ShowSplash() {
    if (this.CsjHmAD?.hmAd?.splash?.switchOff && !this.AdInit?.code && !this.isVip) {
      this.timer = setTimeout(() => {
        splashAd.ShowSplash((ids: boolean) => {
          this.isShow = ids
        })
      })
    } else {
      this.isShow = true
    }
  }

  onPageHide(): void {
    clearTimeout(this.timer)
  }

  build() {
    if (!!this.isVip || this.isShow) {
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
              if (index === TabBarType.HOME) {
                emitter.emit(EmitterConstants.EM_REFRESH_HOME)
              }else if(index === TabBarType.BANK) {
                emitter.emit(EmitterConstants.EM_REFRESH_BANK)
              }
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
                      url: "https://ti.iksdt.com/static/doc/yhxy.html",
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
                      title: "隐私政策"
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
                    context.terminateSelf()
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
                    this.updateBooleanValue(false)
                    init(); // 在用户同意隐私政策后再调用此方法
                    // onEventObject("eventA", {
                    //   "key": "value"
                    // }); // 埋个点
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
    } else {
      Image($r('app.media.block_img'))
        .width('100%')
        .height('100%')
        .expandSafeArea()
    }
  }
}
