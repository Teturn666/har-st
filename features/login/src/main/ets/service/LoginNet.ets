import { LoginTrigger } from './LoginTrigger'
import { HttpUtils } from 'network/Index'
import { AxiosResponse } from '@ohos/axios'
import { BusinessError } from '@kit.BasicServicesKit'
import { UserDetailRes } from '../model/UserDetailRes'
import { preferencesUtils, PreferencesConstants } from 'utils/Index'
import { UserRes } from '../model/UserRes'

const TAG = '[LoginNet]'

export class LoginNet {
  //获取用户信息
  public getUser(): Promise<UserDetailRes> {
    let name = preferencesUtils.getString(PreferencesConstants.SP_NICK_NAME)
    let openid = preferencesUtils.getString(PreferencesConstants.SP_OPEN_ID)
    let unionid = preferencesUtils.getString(PreferencesConstants.SP_UNION_ID)
    let udid = preferencesUtils.getString(PreferencesConstants.SP_UUID)
    let data = "api=updateuser&tag=ksst&name=" + name + "&openid=" + openid
      + "&unionid=" + unionid + "&id=" + udid
    return new Promise((resolve: Function, reject: Function) => {
      HttpUtils.getVipInstance()
        .post(LoginTrigger.PAY_PRICE_URL, data)
        .then((res: AxiosResponse<UserRes>) => {
          let data = res.data.data
          if (res.data.errno === 0) {
            resolve(data)
          } else {
            reject("data is null")
          }
        }).catch((error: BusinessError) => {
        reject(error)
      })
    })
  }
}


