import { PayTrigger } from './PayTrigger'
import { HttpUtils } from 'network/Index'
import { AxiosResponse } from '@ohos/axios'
import { BusinessError } from '@kit.BasicServicesKit'
import { PayPriceRes } from '../model/PayPriceRes'
import { PriceInfoRes } from '../model/PriceInfoRes'
import { CreatePayInfoRes } from '../model/CreatePayInfoRes'
import { CreatePayRes } from '../model/CreatePayRes'
import { PreferencesConstants, preferencesUtils } from 'utils'
import { UserDetailRes } from '../model/UserDetailRes'
import { UserRes } from '../model/UserRes'

const TAG = '[PayNet]'

export class PayNet {
  //获取支付价格
  public getPriceList(): Promise<PriceInfoRes[]> {
    let udid = '0'
    let data = "api=products&id=" + udid
    return new Promise((resolve: Function, reject: Function) => {
      HttpUtils.getVipInstance()
        .post(PayTrigger.PAY_PRICE_URL, data)
        .then((res: AxiosResponse<PayPriceRes>) => {
          let code = res.data.errno
          let data = res.data.data
          if (code === 0 && data != null && data.length > 0) {
            resolve(data);
          } else {
            reject("data is null")
          }
        }).catch((error: BusinessError) => {
        reject(error)
      })
    })
  }

  //获取创建支付的信息，传给微信支付
  public getCreatePay(pId: string): Promise<CreatePayInfoRes> {
    let uid = preferencesUtils.getString(PreferencesConstants.SP_U_ID)
    let openid = preferencesUtils.getString(PreferencesConstants.SP_OPEN_ID)
    let unionid = preferencesUtils.getString(PreferencesConstants.SP_UNION_ID)
    let udid = preferencesUtils.getString(PreferencesConstants.SP_UUID)
    let data = "api=wxcreate&pid=" + pId + "&uid=" + uid + "&openid=" + openid
      + "&unionid=" + unionid + "&wxid=wx4f844b28fe56146f&id=" + udid
    return new Promise((resolve: Function, reject: Function) => {
      HttpUtils.getVipInstance()
        .post(PayTrigger.PAY_PRICE_URL, data)
        .then((res: AxiosResponse<CreatePayRes>) => {
          let code = res.data.errno
          let data = res.data.data
          if (code === 0) {
            resolve(data)
          } else {
            reject("data is null")
          }
        }).catch((error: BusinessError) => {
        reject(error)
      })
    })
  }

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
        .post(PayTrigger.PAY_PRICE_URL, data)
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


