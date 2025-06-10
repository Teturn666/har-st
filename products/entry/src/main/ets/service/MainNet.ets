import { MainTrigger } from './MainTrigger';
import { BaseResponse, HttpUtils } from 'network/Index';
import { AxiosResponse } from '@ohos/axios';
import { BusinessError } from '@kit.BasicServicesKit';
import { ConfigRes } from '../model/ConfigRes';

const TAG = '[MainNet]'

export class MainNet {
  //配置接口
  public getConfigList(): Promise<ConfigRes> {
    return new Promise((resolve: Function, reject: Function) => {
      HttpUtils.getInstance()
        .get(MainTrigger.CONFIG_LIST_URL)
        .then((res: AxiosResponse<BaseResponse<string>>) => {
          const code = res.data.code
          if (code === "0" && res.data.data) {
            let jsonObj = JSON.parse(res.data.data) as ConfigRes
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