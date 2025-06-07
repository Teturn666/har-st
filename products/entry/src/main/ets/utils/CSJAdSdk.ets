import {
  CSJAdSdk,MediationConfigBuilder, MediationUserInfoForSegmentBuilder, SDKConfig, SDKConfigBuilder ,} from "@csj/openadsdk"
export  class  CSJAdSdkAd{
  ctx?:Context
  //初始化SDK
  ConfigSDK() {
    //  this.config=  new SDKConfigBuilder()
    let adConfigBuilder = new SDKConfigBuilder()
    let config: SDKConfig = adConfigBuilder
      .appId('5477447')//5708264  5477447
      .appName("穿山甲demo")

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
    CSJAdSdk.start()   //启动sdk

  }
}
export  const  cSJAdSdkAd =new CSJAdSdkAd()