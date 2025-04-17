import axios, { AxiosInstance } from '@ohos/axios'

export class HttpUtils {
  public static readonly Success_code: number = 0
  public static readonly READ_TIME_OUT = 60 * 1000
  private static mBaseUrl: string = "https://ti.iksdt.com"

  public static setBaseUrl(baseUrl: string) {
    HttpUtils.mBaseUrl = baseUrl
  }

  public static getInstance(): AxiosInstance {
    return axios.create({
      baseURL: HttpUtils.mBaseUrl,
      timeout: HttpUtils.READ_TIME_OUT,
      headers: {
        'union-id': '',
        'device-id': '',
        'apk-channel': 'harmony',
        'apk-name': 'harmony',
        'apk-version': '1.0.0'
      }
    })
  }
}