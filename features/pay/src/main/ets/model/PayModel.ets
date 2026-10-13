import { PayNet } from "../service/PayNet"
import { CreatePayInfoRes } from "./CreatePayInfoRes"
import { PriceInfoRes } from "./PriceInfoRes"
import { UserDetailRes } from "./UserDetailRes"

@Observed
export class PayModel {
  private payNet: PayNet
  private static instance: PayModel

  private constructor() {
    this.payNet = new PayNet()
  }

  public static getInstance(): PayModel {
    if (!PayModel.instance) {
      PayModel.instance = new PayModel()
    }
    return PayModel.instance
  }

  //获取会员价格列表
  public async getPayPriceList(): Promise<PriceInfoRes[]> {
    try {
      let data = await this.payNet.getPriceList()
      return data
    } catch (e) {
      return []
    }
  }

  //获取创建订单的参数，给微信支付调用
  public async getCreatePay(pId: string): Promise<CreatePayInfoRes> {
    try {
      let data = await this.payNet.getCreatePay(pId)
      return data
    } catch (e) {
      return new CreatePayInfoRes()
    }
  }

  //获取用户信息
  public async getUser(): Promise<UserDetailRes> {
    try {
      let data = await this.payNet.getUser()
      return data
    } catch (e) {
      return new UserDetailRes()
    }
  }
}