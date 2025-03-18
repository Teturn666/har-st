import { ChAesUtils } from '@ohos/encryption';

//搜索后解密的工具类
export class SearchDecryptUtils {
  /**
   * 获取解密后的文本
   */
  static async getTrText(suffix: string, message: string, name: string): Promise<string> {
    return await ChAesUtils.getAesStr(suffix, message, name)
  }
}