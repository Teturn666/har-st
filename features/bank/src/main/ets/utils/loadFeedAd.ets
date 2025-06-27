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

export class CSJLoadFeedAD {
  dislikeStatus: boolean = false
  AdList: (adArray: CSJFeedAd[]) => void = () => {
  }
  UiContext?: UIContext

  async loadFeedAd(callback: (adArray: CSJFeedAd[]) => void) {
    // if (this.isLoadingAd) return;
    this.AdList = callback
    // this.isLoadingAd = true;
    try {
      let adCreator = CSJAdSdk.getAdCreator()
      let adSlot: AdSlot = new AdSlotBuilder().setCodeId("955804860")
        .setAcceptSize(350, 200)
        .setAdCount(2)// .setBidAdm(this.mBiddingAdm)
        .setSupportRenderControl(true)
        .build();

      adCreator.loadFeedAd(adSlot, this.feedAdListener)
    } finally {
      //this.isLoadingAd = false;
    }
  }

  /**
   * 广告加载监听器
   */
  private feedAdListener: CSJFeedAdListener = {
    onError: (code: number, message: string) => {
      console.log("FeedNativeAdPage==code=" + code + ",message-" + message);
      // this.error = "error code = " + code + ",message-" + message;
    },
    /**
     * 广告加载成功的回调，接入方可以在这个回调中进行渲染
     *
     * @param ads 返回的广告列表
     */
    onFeedAdLoad: (ads: ArrayList<CSJFeedAd>) => {
      console.log("FeedNativeAdPage==onFeedAdLoad......success");
      if (ads && ads.length > 0) {

        const adArray = ads.convertToArray();
        //  this.ads = adArray;

        // 先整合广告和内容数据
        this.AdList(adArray)
        // this.getAdList(adArray);

        // 再渲染每个广告
        adArray.forEach((ad: CSJFeedAd, idx: number) => {
          ad.setExpressRenderListener({
            onRenderSuccess: (width: number, height: number, isExpress: boolean) => {
              console.log("广告渲染成功，宽度：", width, "高度：", height);
              // this.loadMore = false;
            }
          });

          this.setAdInteractionListener(ad);
          this.setVideoListener(ad);
          this.setDislikeCallback(ad);

          // 渲染广告
          ad.render(this.UiContext)
        })
      }
    }
  }

  /**
   * 设置广告交互监听
   * @param ad
   */
  setAdInteractionListener(ad: CSJFeedAd) {
    ad?.setAdInteractionListener({
      onAdClicked: (ad: CSJNativeAd) => {
        console.log("FeedNativeAdPage==onAdClicked......");
      },

      /**
       * 创意点击事件
       * @param ad
       */
      onAdCreativeClick: (ad: CSJNativeAd) => {
        console.log("FeedNativeAdPage==onAdCreativeClick......");
      },

      /**
       * show展示回调
       * @param ad
       */
      onAdShow: (ad: CSJNativeAd) => {
        console.log("FeedNativeAdPage==onAdShow......");
      }
    })
  }

  private setDislikeCallback(ad: CSJFeedAd) {
    ad.setDislikeCallback({
      /**
       * dislike show
       */
      onShow: () => {
        console.log("FeedNativeAdPage==dislike......show");
      },

      /**
       * @param position 选择的位置
       * @param value 选择的内容
       * @param enforceRemove 是否强制关闭广告
       */
      onSelected: (position: number, value: string, enforceRemove: boolean) => {
        this.dislikeStatus = enforceRemove;
        console.log("FeedNativeAdPage==dislike......onSelected:position=" + position + ",value:" + value + ",enforce=" +
          enforceRemove);
      },

      /**
       * 点击取消
       */
      onCancel: () => {
        console.log("FeedNativeAdPage==dislike......onCancel");
      }
    })
  }

  /**
   * 设置视频监听
   * @param ad
   */
  private setVideoListener(ad: CSJFeedAd) {
    if (ad.getImageMode() == CSJConstant.IMAGE_MODE_VIDEO ||
      ad.getImageMode() == CSJConstant.IMAGE_MODE_VIDEO_VERTICAL) {
      ad.setVideoAdListener({
        onVideoLoad: () => {
          console.log("FeedNativeAdPage==onVideoLoad......");
        },
        /**
         * 视频广告加载失败
         * @param errorCode 错误类型：
         *
         */
        onVideoError: (errorCode: number, errorMsg: string) => {
          console.log("FeedNativeAdPage==onVideoError......errorCode=" + errorCode + ",errorMsg=" + errorMsg);
        },

        /**
         * 视频广告播放回调
         *
         * @param ad
         */
        onVideoAdStartPlay: () => {
          console.log("FeedNativeAdPage==onVideoAdStartPlay......");
        },

        /**
         * 视频广告暂停回调
         *
         * @param ad
         */
        onVideoAdPaused: () => {
          console.log("FeedNativeAdPage==onVideoAdPaused......");
        },

        /**
         * 视频广告续播
         *
         * @param ad
         */
        onVideoAdContinuePlay: () => {
          console.log("FeedNativeAdPage==onVideoAdContinuePlay......");
        },

        /**
         * 视频播放进度
         *
         * @param current
         * @param duration
         */
        onProgressUpdate: (current: number, duration: number) => {
          // console.log("FeedNativeAdPage==onProgressUpdate......current=" + current + ",duration=" + duration);
        },

        /**
         * 视频广告播放完成回调
         *
         * @param ad
         */
        onVideoAdComplete: () => {
          console.log("FeedNativeAdPage==onVideoAdComplete......");
        }
      })
    }
  }
}

export const cSJLoadFeedAD = new CSJLoadFeedAD()