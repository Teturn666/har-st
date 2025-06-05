import { promptAction } from "@kit.ArkUI";
import { BusinessError } from "@kit.BasicServicesKit";
import { Logger } from "../../../../Index";

export class ToastUtils {
  static showToast(resource: string, duration: number = 2000) {
    try {
      promptAction.showToast({
        message: resource,
        duration: duration
      });
    } catch (error) {
      const message = (error as BusinessError).message
      const code = (error as BusinessError).code
      Logger.error(`showToast args  errCode is ${code}, errMessage is ${message}`)
    }
  }
}