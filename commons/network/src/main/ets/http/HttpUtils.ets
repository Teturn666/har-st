import axios, { AxiosInstance } from '@ohos/axios'

export class HttpUtils {
  public static readonly Success_code: number = 0
  public static readonly READ_TIME_OUT = 60 * 1000
  // private static mBaseUrl: string = "http://xfjf2.chznai.com"
  private static mBaseUrl: string = "https://ti.iksdt.com"

  public static setBaseUrl(baseUrl: string) {
    HttpUtils.mBaseUrl = baseUrl
  }

  public static getInstance(): AxiosInstance {
    return axios.create({
      baseURL: HttpUtils.mBaseUrl,
      timeout: HttpUtils.READ_TIME_OUT,
      headers: {
        'open-id': 'application/json',
        'union-id': 'application/json',
        'device-id': 'application/json',
        'device-model': 'application/json',
        'apk-channel': 'application/json',
        'apk-version': 'application/json'
      }
    })
  }
}