import { PayTrigger } from './PayTrigger'
import { HttpUtils } from 'network/Index'
import { AxiosResponse } from '@ohos/axios'
import { BusinessError } from '@kit.BasicServicesKit'
import { PayPriceRes } from '../model/PayPriceRes'
import { PriceInfoRes } from '../model/PriceInfoRes'
import { CreatePayInfoRes } from '../model/CreatePayInfoRes'
import { CreatePayRes } from '../model/CreatePayRes'

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
  public getCreatePay(): Promise<CreatePayInfoRes> {
    let pid = '0'
    let uid = '0'
    let openid = '0'
    let unionid = '0'
    let udid = '0'
    let data = "api=wxcreate&pid=" + pid + "&uid=" + uid + "&openid=" + openid
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
}


