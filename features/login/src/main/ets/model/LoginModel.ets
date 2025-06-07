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
}