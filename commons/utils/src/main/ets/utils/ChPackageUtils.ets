import bundleManager from '@ohos.bundle.bundleManager';
import Logger from './Logger';
import { util } from '@kit.ArkTS';

export class ChPackageUtils {
  static getPackage() {
    bundleManager.getBundleInfoForSelf(bundleManager.BundleFlag.GET_BUNDLE_INFO_WITH_APPLICATION)
      .then(bundleInfo => {
        Logger.info("---->" + bundleInfo.name)
      })
  }

  static async getVersionName(): Promise<string> {
    let bundleInfo = await bundleManager.getBundleInfoForSelf(bundleManager.BundleFlag.GET_BUNDLE_INFO_DEFAULT)
    Logger.info("---->" + bundleInfo.versionName)
    return bundleInfo.versionName
  }

  static getDeviceId(): string {
    let uuId = util.generateRandomUUID(true)
    let base64 = new util.Base64Helper()
    let deviceId = base64.encodeToStringSync(base64.decodeSync(uuId))
    return deviceId
  }

  static getChannel(): string {
    let base64 = new util.Base64Helper()
    let deviceId = base64.encodeToStringSync(base64.decodeSync("harmony"))
    return deviceId
  }
}