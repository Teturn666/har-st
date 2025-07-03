import { AdConfigInfo } from "./AdConfigInfo"
import { AdInfo } from "./AdInfo"


export class HmAdInfo {
  //开屏
  splash: AdInfo = new AdInfo()
  //激励-扫描搜题
  rewardScan: AdInfo = new AdInfo()
  //激励-积分-看广告
  rewardPoint: AdInfo = new AdInfo()
  //激励-读屏搜题
  rewardRead: AdInfo = new AdInfo()
  //信息流-热门
  informationHot: AdInfo = new AdInfo()
  //信息流-公职
  informationOffice: AdInfo = new AdInfo()
  //信息流-消防
  informationFire: AdInfo = new AdInfo()
  //信息流-煤矿
  informationCoalMine: AdInfo = new AdInfo()
  //信息流-国网
  informationNetwork: AdInfo = new AdInfo()
  //信息流-医护
  informationDoctor: AdInfo = new AdInfo()
  //信息流-交管
  informationTraffic: AdInfo = new AdInfo()
  //广告key配置
  adconfig: AdConfigInfo = new AdConfigInfo()
}