import { BankTrigger } from './BankTrigger';
import { BaseResponse, HttpUtils } from '@ohos/network/Index';
import { AxiosResponse } from '@ohos/axios';
import { BankCategory } from '../model/BankCategory';
import { BusinessError } from '@kit.BasicServicesKit';
import TiKuRes from '../model/TikuRes';

export class BankNet {
  //获取题库tab类型列表
  public getBankTypeList(): Promise<BankCategory[]> {
    return new Promise((resolve: Function, reject: Function) => {
      HttpUtils.getInstance().get(BankTrigger.HOME_CATEGORY_LIST_URL)
        .then((res: AxiosResponse<BaseResponse<BankCategory[]>>) => {
          let code = res.data.code
          if (code === "0") {
            resolve(res.data.data);
          } else {
            reject("data is null");
          }
        }).catch((error: BusinessError) => {
        reject(error);
      })
    })
  }

  //获取题库列表
  public getBankList(aid: string, pageSize: number, pageNo: number): Promise<TiKuRes[]> {
    return new Promise((resolve: Function, reject: Function) => {
      HttpUtils.getInstance()
        .get(BankTrigger.HOME_BANK_LIST_URL, { params: { "aid": aid, "pageSize": pageSize, "pageNo": pageNo } })
        .then((res: AxiosResponse<BaseResponse<TiKuRes[]>>) => {
          let code = res.data.code
          if (code === "0") {
            resolve(res.data.data);
          } else {
            reject("data is null");
          }
        })
        .catch((error: BusinessError) => {
          reject(error);
        })
    })
  }
}