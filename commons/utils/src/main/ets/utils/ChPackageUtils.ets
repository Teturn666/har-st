import bundleManager from '@ohos.bundle.bundleManager';
import { buffer, util } from '@kit.ArkTS';
import { PreferencesConstants } from '../common/PreferencesConstants'
import { preferencesUtils } from '../common/PreferencesUtils'

export class ChPackageUtils {
  static getPackage() {
    bundleManager.getBundleInfoForSelf(bundleManager.BundleFlag.GET_BUNDLE_INFO_WITH_APPLICATION)
      .then(bundleInfo => {
        // Logger.info("---->" + bundleInfo.name)
      })
  }

  static async getVersionName(): Promise<string> {
    let bundleInfo = await bundleManager.getBundleInfoForSelf(bundleManager.BundleFlag.GET_BUNDLE_INFO_DEFAULT)
    // Logger.info("---->" + bundleInfo.versionName)
    return bundleInfo.versionName
  }

  static getDeviceId(): string {
    let uuId: string = util.generateRandomUUID(true)
    preferencesUtils.putString(PreferencesConstants.SP_UUID, uuId)
    let base64 = new util.Base64Helper()
    let uint8Array = new Uint8Array(buffer.from(uuId).buffer)
    let deviceId = base64.encodeToStringSync(uint8Array)
    return deviceId
  }

  static getChannel(): string {
    let base64 = new util.Base64Helper()
    let uint8Array = new Uint8Array(buffer.from("harmony").buffer)
    let channel = base64.encodeToStringSync(uint8Array)
    return channel
  }

  static getUnionId(): string {
    let base64 = new util.Base64Helper()
    let unionId = preferencesUtils.getString(PreferencesConstants.SP_UNION_ID)
    if (unionId != '') {
      let uint8Array = new Uint8Array(buffer.from(unionId).buffer)
      return base64.encodeToStringSync(uint8Array)
    }
    return ""
  }

  static getOpenId(): string {
    let base64 = new util.Base64Helper()
    let openId = preferencesUtils.getString(PreferencesConstants.SP_OPEN_ID)

    if (openId != '') {
      let uint8Array = new Uint8Array(buffer.from(openId).buffer)
      return base64.encodeToStringSync(uint8Array)
    }
    return ""
  }
}