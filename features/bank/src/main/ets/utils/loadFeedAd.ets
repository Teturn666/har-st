import {
  AdSlot,
  AdSlotBuilder,
  CSJAdSdk,
  CSJConstant,
  CSJFeedAd,
  CSJFeedAdListener,
  CSJNativeAd
} from "@csj/openadsdk";
import { ArrayList } from "@kit.ArkTS";
import { UIContext } from "@ohos.arkui.UIContext";
import { PreferencesConstants, preferencesUtils } from "utils";

export class CSJLoadFeedAD {
  dislikeStatus: boolean = false
  AdList: (adArray: CSJFeedAd[]) => void = () => {
  }
  UiContext?: UIContext
  AdIndex: number = 0

  async loadFeedAd(callback: (adArray: CSJFeedAd[]) => void,) {

    this.AdList = callback
    try {
      let adCreator = CSJAdSdk.getAdCreator()
      let adSlot: AdSlot = new AdSlotBuilder().setCodeId(this.getAdIndex())//955804860
        .setAcceptSize(350, 200)
        .setAdCount(2)// .setBidAdm(this.mBiddingAdm)
        .setSupportRenderControl(true)
        .build();

      adCreator.loadFeedAd(adSlot, this.feedAdListener)
    } finally {
    }
  }

  private getAdIndex() {
    const res = preferencesUtils.getGenerics(PreferencesConstants.CSJ_AD_PARAMS)
    switch (this.AdIndex) {
      case 0:
        return res?.hmAd?.informationHot?.csj

      case 1:
        return res?.hmAd?.informationOffice?.csj

      case 2:
        return res?.hmAd?.informationFire?.csj

      case 3:
        return res?.hmAd?.informationCoalMine?.csj

      case 4:
        return res?.hmAd?.informationNetwork?.csj

      case 5:
        return res?.hmAd?.informationDoctor?.csj

      case 6:
        return res?.hmAd?.informationTraffic?.csj

      default:
        return ''

    }
  }
  private feedAdListener: CSJFeedAdListener = {
    onError: (code: number, message: string) => {

    },
    onFeedAdLoad: (ads: ArrayList<CSJFeedAd>) => {
      console.log("FeedNativeAdPage==onFeedAdLoad......success");
      if (ads && ads.length > 0) {
        const adArray = ads.convertToArray();
        this.AdList(adArray)
        adArray.forEach((ad: CSJFeedAd, idx: number) => {
          ad.setExpressRenderListener({
            onRenderSuccess: (width: number, height: number, isExpress: boolean) => {
            }
          });
          this.setAdInteractionListener(ad);
          this.setVideoListener(ad);
          this.setDislikeCallback(ad);
          ad.render(this.UiContext)
        })
      }
    }
  }

  setAdInteractionListener(ad: CSJFeedAd) {
    ad?.setAdInteractionListener({
      onAdClicked: (ad: CSJNativeAd) => {
        console.log("FeedNativeAdPage==onAdClicked......");
      },

      onAdCreativeClick: (ad: CSJNativeAd) => {
        console.log("FeedNativeAdPage==onAdCreativeClick......");
      },
      onAdShow: (ad: CSJNativeAd) => {
        console.log("FeedNativeAdPage==onAdShow......");
      }
    })
  }

  private setDislikeCallback(ad: CSJFeedAd) {
    ad.setDislikeCallback({
      onShow: () => {

      },
      onSelected: (position: number, value: string, enforceRemove: boolean) => {
        this.dislikeStatus = enforceRemove;
      },
      onCancel: () => {

      }
    })
  }

  private setVideoListener(ad: CSJFeedAd) {
    if (ad.getImageMode() == CSJConstant.IMAGE_MODE_VIDEO ||
      ad.getImageMode() == CSJConstant.IMAGE_MODE_VIDEO_VERTICAL) {
      ad.setVideoAdListener({
        onVideoLoad: () => {
        },

        onVideoError: (errorCode: number, errorMsg: string) => {
        },

        onVideoAdStartPlay: () => {

        },

        onVideoAdPaused: () => {

        },

        onVideoAdContinuePlay: () => {

        },
        onProgressUpdate: (current: number, duration: number) => {
        },
        onVideoAdComplete: () => {

        }
      })
    }
  }
}

export const cSJLoadFeedAD = new CSJLoadFeedAD()