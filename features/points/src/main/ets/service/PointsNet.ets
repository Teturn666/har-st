import { PointsTrigger } from './PoinsTrigger';
import { BaseResponse, HttpUtils } from 'network/Index';
import { AxiosResponse } from '@ohos/axios';
import { BusinessError } from '@kit.BasicServicesKit';
import CheckDataRes, { PointEventRes } from '../model/CheckDataRes';
import { ExchangeRes } from '../model/ExchangeRes';
import { PreferencesConstants, preferencesUtils } from 'utils'
import { UserRes } from '../model/UserRes';
import { UserDetailRes } from '../model/UserDetailRes';

const TAG = '[PointsNet]'

export class PointsNet {
  // 获取签到积分列表
  public getListSignMap(vib: boolean): Promise<CheckDataRes[]> {
    return new Promise((resolve: Function, reject: Function) => {
      HttpUtils.getInstance().get(PointsTrigger.URL_SIGN_MAP,
        {
          params: {
            vip: vib
          }
        })
        .then((res: AxiosResponse<BaseResponse<CheckDataRes[]>>) => {
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

  // 获取签到状态
  public getSignState(): Promise<number> {
    return new Promise((resolve: Function, reject: Function) => {
      HttpUtils.getInstance().get(PointsTrigger.URL_SIGN_STATE)
        .then((res: AxiosResponse<BaseResponse<number>>) => {
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

  // 获取我的积分
  public getMyNumb(): Promise<number> {
    return new Promise((resolve: Function, reject: Function) => {
      HttpUtils.getInstance().get(PointsTrigger.URL_POINT_NUMB)
        .then((res: AxiosResponse<BaseResponse<number>>) => {
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

  // 今日签到积分
  public getSigningPoint(): Promise<number> {
    return new Promise((resolve: Function, reject: Function) => {
      HttpUtils.getInstance().get(PointsTrigger.URL_SIGN_ACTION)
        .then((res: AxiosResponse<BaseResponse<number>>) => {
          let code = res.data.code
          if (code === "0") {
            resolve(0);
          } else {
            reject("data is null");
          }
        }).catch((error: BusinessError) => {
        reject(error);
      })
    })
  }

  // 积分历史明细
  public getHistoryPointDetail(): Promise<PointEventRes[]> {
    return new Promise((resolve: Function, reject: Function) => {
      HttpUtils.getInstance().get(PointsTrigger.URL_POINT_HISTORY)
        .then((res: AxiosResponse<BaseResponse<PointEventRes[]>>) => {
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

  // 积分历史增加
  public getHistoryPointIncrease(): Promise<PointEventRes[]> {
    return new Promise((resolve: Function, reject: Function) => {
      HttpUtils.getInstance().get(PointsTrigger.URL_POINT_HISTORY_INCREASE)
        .then((res: AxiosResponse<BaseResponse<PointEventRes[]>>) => {
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

  // 积分历史消耗
  public getHistoryPointConsumer(): Promise<PointEventRes[]> {
    return new Promise((resolve: Function, reject: Function) => {
      HttpUtils.getInstance().get(PointsTrigger.URL_POINT_HISTORY_REDUCE)
        .then((res: AxiosResponse<BaseResponse<PointEventRes[]>>) => {
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

  public getMyInvitePeople(): Promise<PointEventRes[]> {
    return new Promise((resolve: Function, reject: Function) => {
      HttpUtils.getInstance().get(PointsTrigger.URL_INVITE_MY)
        .then((res: AxiosResponse<BaseResponse<PointEventRes[]>>) => {
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

  public getMyInviteCode(): Promise<string> {
    return new Promise((resolve: Function, reject: Function) => {
      HttpUtils.getInstance().get(PointsTrigger.URL_INVITE_CODE)
        .then((res: AxiosResponse<BaseResponse<string>>) => {
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

  public getBoundCode(): Promise<string> {
    return new Promise((resolve: Function, reject: Function) => {
      HttpUtils.getInstance().get(PointsTrigger.URL_INVITE_BOUND)
        .then((res: AxiosResponse<BaseResponse<string>>) => {
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

  // 绑定邀请码
  public submitBoundCode(codeText: string): Promise<string> {
    return new Promise((resolve: Function, reject: Function) => {
      HttpUtils.getInstance().get(PointsTrigger.URL_INVITE_SUBMIT, {
        params: {
          code: codeText
        }
      })
        .then((res: AxiosResponse<BaseResponse<string>>) => {
          let code = res.data.code
          if (code === "0") {
            resolve("done");
          } else if (code === "300") {
            resolve("您已注册超过30天，无法填写邀请码")
          } else {
            resolve("绑定失败，请检查邀请码是否正确")
            // reject("data is null");
          }
        }).catch((error: BusinessError) => {
        reject(error);
      })
    })
  }

  //获取积分兑换列表
  public getExchangeList(): Promise<ExchangeRes[]> {
    return new Promise((resolve: Function, reject: Function) => {
      HttpUtils.getInstance().get(PointsTrigger.URL_POINT_EXCHANGE_RULES)
        .then((res: AxiosResponse<BaseResponse<ExchangeRes[]>>) => {
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

  //积分兑换
  public getExchangeVip(id: string): Promise<string> {
    return new Promise((resolve: Function, reject: Function) => {
      HttpUtils.getInstance().get(PointsTrigger.URL_POINT_USE_VIP, {
        params: {
          id: id
        }
      })
        .then((res: AxiosResponse<BaseResponse<string>>) => {
          let code = res.data.code
          if (code === "0") {
            resolve(res.data.data);
          } else if (code === "300") {
            reject("积分不足");
          } else {
            reject("data is null");
          }
        }).catch((error: BusinessError) => {
        reject(error);
      })
    })
  }

  //查询还有多少次看广告的机会 /m/point/ad/count
  public getAdCount(): Promise<string> {
    return new Promise((resolve: Function, reject: Function) => {
      HttpUtils.getInstance().get(PointsTrigger.URL_POINT_AD_COUNT)
        .then((res: AxiosResponse<BaseResponse<string>>) => {
          let code = res.data.code
          if (code === "0") {
            resolve(res.data.msg);
          } else {
            reject("data is null");
          }
        }).catch((error: BusinessError) => {
        reject(error);
      })
    })
  }

  //看广告领积分 /m/point/ad
  public getAdPoint(): Promise<string> {
    return new Promise((resolve: Function, reject: Function) => {
      HttpUtils.getInstance().get(PointsTrigger.URL_POINT_AD)
        .then((res: AxiosResponse<BaseResponse<string>>) => {
          let code = res.data.code
          if (code === "0") {
            resolve(res.data.msg);
          } else {
            reject("data is null");
          }
        }).catch((error: BusinessError) => {
        reject(error);
      })
    })
  }

  //先判断是否还能跳转应用商店
  public getScoreSelect(): Promise<string> {
    return new Promise((resolve: Function, reject: Function) => {
      HttpUtils.getInstance().get(PointsTrigger.URL_POINT_SCORE_SELECT)
        .then((res: AxiosResponse<BaseResponse<string>>) => {
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

  // 应用商店加分接口：/m/point/score/action
  public getScoreAction(): Promise<string> {
    return new Promise((resolve: Function, reject: Function) => {
      HttpUtils.getInstance().get(PointsTrigger.URL_POINT_SCORE_ACTION)
        .then((res: AxiosResponse<BaseResponse<string>>) => {
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
        .post(PointsTrigger.PAY_PRICE_URL, data)
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