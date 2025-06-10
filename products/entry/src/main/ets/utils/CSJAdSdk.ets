import {
  CSJAdSdk,MediationConfigBuilder, MediationUserInfoForSegmentBuilder, SDKConfig, SDKConfigBuilder,
  StartResult ,} from "@csj/openadsdk"
import {CSJ_State} from 'utils/src/main/ets/constants/CSJState'
import { ConfigRes } from "utils/src/main/ets/model/ConfigRes"

export  class  CSJAdSdkAd{
  ctx?:Context
  //初始化SDK
  ConfigSDK() {
  let res= AppStorage.get(CSJ_State.CSJ_HM_AD) as ConfigRes
    //  this.config=  new SDKConfigBuilder()
    let adConfigBuilder = new SDKConfigBuilder()
    let config: SDKConfig = adConfigBuilder
       .appId(res.hmAd.adconfig.csjAppId)//5708264  5477447
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
    CSJAdSdk.init(getContext()||this.ctx, config)
    CSJAdSdk.start().then((res)=>{
      AppStorage.setOrCreate(CSJ_State.APP_CSJ_STATE,res as  StartResult)//0 成功 4200 重复启动  4100 错误
    })   //启动sdk

  }
}
export  const  cSJAdSdkAd =new CSJAdSdkAd()