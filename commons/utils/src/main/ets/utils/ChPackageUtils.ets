import bundleManager from '@ohos.bundle.bundleManager';
import Logger from './Logger';

export class ChPackageUtils {
  static getPackage() {
    bundleManager.getBundleInfoForSelf(bundleManager.BundleFlag.GET_BUNDLE_INFO_WITH_APPLICATION)
      .then(bundleInfo => {
        Logger.info("---->" + bundleInfo.name)
      })
  }
}