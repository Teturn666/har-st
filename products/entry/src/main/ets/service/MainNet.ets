import { MainTrigger } from './MainTrigger';
import { BaseResponse, HttpUtils } from 'network/Index';
import { AxiosResponse } from '@ohos/axios';
import { BusinessError } from '@kit.BasicServicesKit';
import { ConfigRes } from 'utils/src/main/ets/model/ConfigRes';

import { PreferencesConstants, preferencesUtils } from 'utils';

const TAG = '[MainNet]'

export class MainNet {
  //配置接口
  public async getConfigList(): Promise<ConfigRes> {

    return new Promise((resolve: Function, reject: Function) => {
      HttpUtils.getInstance()
        .get(MainTrigger.CONFIG_LIST_URL)
        .then((res: AxiosResponse<BaseResponse<string>>) => {
          const code = res.data.code
          if (code === "0" && res.data.data) {
            let jsonObj = JSON.parse(res.data.data) as ConfigRes

            //TODO 上线需注释，切记！！！！广告测试开关及数据。
            // this.testAd(jsonObj)

            preferencesUtils.putGenerics(PreferencesConstants.CSJ_AD_PARAMS, jsonObj)
            resolve(jsonObj)
          } else {
            reject(new Error(`Request failed with code: ${code}`))
          }
        })
        .catch((error: BusinessError) => {
          reject(error)
        })
    })
  }

  //广告测试数据
  private testAd(jsonObj: ConfigRes) {
    jsonObj.hmAd.adconfig.csjAppId = '5477447'
    jsonObj.hmAd.rewardScan.csj = '955804646'
    jsonObj.hmAd.rewardScan.switchOff = true
    jsonObj.hmAd.rewardRead.csj = '955804646'
    jsonObj.hmAd.rewardRead.switchOff = true
    jsonObj.hmAd.rewardPoint.csj = '955804646'
    jsonObj.hmAd.rewardPoint.switchOff = false
  }
}
