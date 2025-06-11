import {
  CSJAdSdk,
  MediationConfigBuilder,
  MediationUserInfoForSegmentBuilder,
  SDKConfig,
  SDKConfigBuilder,
  StartResult,
} from "@csj/openadsdk"
import { PreferencesConstants, preferencesUtils } from "utils"
import { CSJStartResult } from "utils/src/main/ets/model/StartResult";


export class CSJAdSdkAd {
  ctx?: Context

  //初始化SDK
  ConfigSDK() {
    let res = preferencesUtils.getGenerics(PreferencesConstants.CSJ_AD_PARAMS)

    let adConfigBuilder = new SDKConfigBuilder()
    let config: SDKConfig = adConfigBuilder
      .appId(res?.hmAd?.adconfig?.csjAppId)
      .appName("快搜搜题")
      .allowShowNotify(true)
      .debug(true)
      .setMediationConfig(
        new MediationConfigBuilder()
          .useMediation(true)
          .setCustomLocalConfig("GroMore-config.json")
          .infoForSegment(
            new MediationUserInfoForSegmentBuilder()
              //流量分组
              .userId('xxx_user_id')
              .channel('xxx_channel')
              .build()
          )
          .build()
      )
      .build()
    CSJAdSdk.init(this.ctx, config)
    CSJAdSdk.start().then((res) => {
      AppStorage.setOrCreate('isInit', res as CSJStartResult) // StartResult
    }) //启动sdk

  }
}

export const cSJAdSdkAd = new CSJAdSdkAd()
