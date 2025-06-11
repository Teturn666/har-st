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
}
