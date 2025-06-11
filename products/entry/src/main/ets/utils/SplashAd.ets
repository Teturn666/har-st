import {
  AdSlot,
  AdSlotBuilder,
  CSJAdCreator,
  CSJAdSdk,
  CSJSplashAd,
  CSJSplashAdCloseType,
  CSJSplashAdInteractionListener,
  CSJSplashAdLoadListener,
  CSJSplashAdLoadParam
} from "@csj/openadsdk"

import { Content, window } from "@kit.ArkUI"
import { DemoConstants, PreferencesConstants, preferencesUtils, UIUtil } from "utils"



export class SplashAd {
  private mAdCreator: CSJAdCreator | null = null
  private screenWidth: number = UIUtil.getScreenWidthVp()
  private screenHeight: number = UIUtil.getScreenHeightVp()
  private adWidth: number = Math.round(this.screenWidth)
  private adHeight: number = Math.round(this.screenHeight)
  private mLoadListener: CSJSplashAdLoadListener | null = null
  private mSplashAdInteractionListener: CSJSplashAdInteractionListener | null = null
  private splashAd: CSJSplashAd | undefined
  private adLoadSuccess: Boolean = false
  private mWindow: window.Window | undefined = undefined
  globalBuilder: WrappedBuilder<[]> = wrapBuilder(bottomViewBuilder)
  globalCloseBtnBuilder: WrappedBuilder<[closeBlock: () => Promise<void>]> = wrapBuilder(closeBtnBuilder)
  ctx?: Content
  adSlot: AdSlot | undefined = undefined
  TimeOut: number = 3000
  useCustomCloseBtn: boolean = false
  mBiddingAdm: string = '' //服务端bidding才需要设置

  startLoad: boolean = false;

  ShowSplash(callback: (ids: boolean) => void) {
    this.mAdCreator = CSJAdSdk.getAdCreator() //初始化广告创建器
    this.adLoadSuccess = false;
    this.startLoad = true;

    this.asSLOTaD(callback)
    let param = new CSJSplashAdLoadParam(this.adSlot!, this.mLoadListener!, this.ctx as UIContext, this.TimeOut!)
    this.mAdCreator.loadSplashAd(param)


  }

  private asSLOTaD(callback: (ids: boolean) => void) {
  let res=  preferencesUtils.getGenerics(PreferencesConstants.CSJ_AD_PARAMS)
    this.adSlot = new AdSlotBuilder()
      .setCodeId(res?.hmAd?.splash?.csj)
      .setAcceptSize(this.adWidth, this.adHeight)
      .setBidAdm(this.mBiddingAdm)
      .build()
    this.InteractionListener()
    this.Listener(callback)
  }

  isShowAd() {

    this.splashAd!.setInteractionListener(this.mSplashAdInteractionListener)

    if (this.adHeight < this.screenHeight) {
      this.splashAd?.showSplashAd(DemoConstants.windowStage, this.globalBuilder,
        this.useCustomCloseBtn ? this.globalCloseBtnBuilder : undefined)
    } else {
      this.splashAd?.showSplashAd(DemoConstants.windowStage, undefined,
        this.useCustomCloseBtn ? this.globalCloseBtnBuilder : undefined)
    }
  }

  //开启监听
  Listener(callback: (ids: boolean) => void) {
    this.mLoadListener = {
      onAdLoaded: (splashAd: CSJSplashAd) => {
        console.log("开屏回调 - onAdLoaded")
        this.splashAd = splashAd;
        this.adLoadSuccess = true;
        this.startLoad = false;
        this.InteractionListener()
        this.isShowAd()
        callback(true)
      },

      onError: (code: number, message: string) => {


        callback(true)
      },
      // 开屏渲染成功
      onRenderSuccess: (splashAd: CSJSplashAd) => {

      },
      // 开屏渲染失败
      onRenderFail: (code: number, message: string) => {
        callback(true)

      }
    }
  }

  //开屏回调
  InteractionListener() {
    this.mSplashAdInteractionListener = {
      onDidShow: () => {
        console.log("开屏回调 - onDidShow")

      },

      onDidClose: (closeType: CSJSplashAdCloseType) => {
        console.log(`开屏回调 - onDidClose 关闭原因：${closeType.value}`)
        this.splashAd = undefined
        this.mWindow?.destroyWindow()
      },

      onDidClick: () => {
        console.log("开屏回调 - onDidClick")
      },

      onVideoDidPlayFinish: () => {
        console.log("开屏回调 - onVideoDidPlayFinish")
      },

      onVideoDidPlayFail: () => {
        console.log("开屏回调 - onVideoDidPlayFail")
      }
    }
  }
}

export const splashAd = new SplashAd()

// 创建Builder函数用于展示底部View
@Builder
function bottomViewBuilder() {
  Text('Bottom View')
    .backgroundColor(Color.Yellow)
    .width(UIUtil.getScreenWidthVp())
    .height(UIUtil.getScreenHeightVp())
}

//自定义关闭按钮
@Builder
function closeBtnBuilder(closeBlock: () => Promise<void>) {
  Text('close')
    .textAlign(TextAlign.Center)
    .backgroundColor(Color.Pink)
    .width(60)
    .height(60)
    .borderRadius(30)
    .margin({ top: 50, right: 40 })
    .onClick((event) => {
      closeBlock().then(() => {
        console.log("开屏自定义按钮广告关闭成功")
      }).catch((err: Error) => {
        console.log("开屏自定义按钮广告关闭失败：" + err.message)
      })
    })
}