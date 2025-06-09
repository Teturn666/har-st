import { AdSlot, AdSlotBuilder, CSJAdCreator, CSJAdSdk, CSJRewardAd, RewardAdLoadListener } from "@csj/openadsdk"
import { DemoConstants } from "utils"
import { ToastUtil } from "./ToastUtil"


export class RewardAd {
  private mBiddingAdm = '' //服务端Bidding才需要设置
  private mAdCreator: CSJAdCreator = CSJAdSdk.getAdCreator()
  private mAd: CSJRewardAd | undefined
  private adSlot: AdSlot | null = null
  isClose: boolean = false
  isShow: (isVerify: boolean) => void = () => {
  }

  async AdSlotBuilder(callback: (isVerify: boolean) => void) {
    let adSlot = new AdSlotBuilder()
      .setCodeId("955804646")
      .setRewardName("金币")
      .setRewardAmount(1)
      .setBidAdm(this.mBiddingAdm)
      .build()
    this.loadAd(adSlot, callback)

  }

  loadAd(adSlot: AdSlot, callback: (isVerify: boolean) => void) {
    this.isShow = callback

    this.mAdCreator.loadRewardAd(adSlot, this.mLoadListener) //加载广告
  }

  closeAd() {
    this.isClose = false
    this.adSlot = null
    this.mAd = undefined
  }

  //展示
  private mLoadListener: RewardAdLoadListener = {
    onAdLoaded: (rewardAd: CSJRewardAd) => {
      this.mAd = rewardAd
      if (this.mAd) {
        this.mAd.showRewardAd(DemoConstants.windowStage)

      }
      rewardAd.setInteractionListener({
        onShow: () => {

        },
        onSkip: () => {

        },
        onClick: () => {

        },
        onClose: () => {
          if (this.isClose) {
            this.isShow(this.isClose)
            this.closeAd()
          }

        },
        onComplete: () => {

        },
        onRewardArrived: (isVerify, rewardType, extraInfo) => {
          console.log("广告获得奖励" + isVerify);
          this.isClose = isVerify

          console.log("RewardAdInteractionListener",
            `Callback --> onRewardArrived ${isVerify} ; ${rewardType} ; ${extraInfo}`)
        }
      })
      rewardAd.setPlayAgainListener({
        onShow: (againCount) => {

        },
        onSkip: (againCount) => {

        },
        onClick: (againCount) => {

        },
        onComplete: (againCount) => {

        },
        onRewardArrived: (againCount, isVerify, rewardType, extraInfo) => {

        },
        getPlayAgainCondition: (nextCount) => {

          return new Promise((resolve, reject) => {
            // 进行网络请求等
            let obj = new Object({
              "allow": nextCount <= 2,
              "name": "金币",
              "amount": nextCount
            })
            resolve(obj)
          })
        }
      })
    },
    onAdCached: () => {

      console.log("RewardAdLoadListener", "Callback --> onAdCached")
    },
    onError: (code: number, message: string) => {
      this.closeAd()

    }
  }
}

export const rewardAd = new RewardAd()
