import { AdConfigInfo } from "./AdConfigInfo"
import { AdInfo } from "./AdInfo"


export class HmAdInfo {
  splash: AdInfo = new AdInfo()
  rewardScan: AdInfo = new AdInfo()
  rewardPoint : AdInfo = new AdInfo()
  adconfig: AdConfigInfo = new AdConfigInfo()
}