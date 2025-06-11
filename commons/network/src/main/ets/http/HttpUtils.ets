import axios, { AxiosInstance } from '@ohos/axios'
import { ChPackageUtils, PreferencesConstants, preferencesUtils } from 'utils'

export class HttpUtils {
  public static readonly Success_code: number = 0
  public static readonly READ_TIME_OUT = 60 * 1000
  private static mBaseUrl: string = "https://ti.iksdt.com"
  private static mVipBaseUrl: string = "https://kspay.iksdt.com"

  public static setBaseUrl(baseUrl: string) {
    HttpUtils.mBaseUrl = baseUrl
  }

  //通用接口链接
  public static getInstance(): AxiosInstance {
    let deviceId = preferencesUtils.getString(PreferencesConstants.SP_UUID)
    let versionName = preferencesUtils.getString(PreferencesConstants.SP_VERSION_NAME)
    let unionId = ChPackageUtils.getUnionId()
    let openId = ChPackageUtils.getOpenId()
    let channel = ChPackageUtils.getChannel()
    let deviceModel = ChPackageUtils.getDeviceModel()
    return axios.create({
      baseURL: HttpUtils.mBaseUrl,
      timeout: HttpUtils.READ_TIME_OUT,
      headers: {
        'open-id': openId,
        'union-id': unionId,
        'device-id': deviceId,
        'device-model': deviceModel,
        'apk-channel': channel,
        'apk-name': channel,
        'apk-version': versionName
      }
    })
  }

  //VIP接口链接
  public static getVipInstance(): AxiosInstance {
    return axios.create({
      baseURL: HttpUtils.mVipBaseUrl,
      timeout: HttpUtils.READ_TIME_OUT,
    })
  }
}