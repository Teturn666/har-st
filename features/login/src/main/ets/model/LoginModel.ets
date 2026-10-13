import { BankListRes, questionBankTable } from "db"
import { LoginNet } from "../service/LoginNet"
import { UserDetailRes } from "./UserDetailRes"

@Observed
export class LoginModel {
  private loginNet: LoginNet
  private static instance: LoginModel

  private constructor() {
    this.loginNet = new LoginNet()
  }

  public static getInstance(): LoginModel {
    if (!LoginModel.instance) {
      LoginModel.instance = new LoginModel()
    }
    return LoginModel.instance
  }

  //获取用户信息
  public async getUser(): Promise<UserDetailRes> {
    try {
      let data = await this.loginNet.getUser()
      return data
    } catch (e) {
      return new UserDetailRes()
    }
  }

  //获取数据库下载的题库
  public async getBankList(): Promise<BankListRes[]> {
    let bankResultList = await questionBankTable.querySync(0) ?? [];
    return bankResultList
  }
}