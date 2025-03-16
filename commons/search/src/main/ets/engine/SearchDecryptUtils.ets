import { ChAesUtils } from '@ohos/encryption';
import SearchConstants from '../constants/SearchConstants';


//搜索后解密的工具类
export class SearchDecryptUtils {
  /**
   * 获取解密后的文本
   */
  static async getTrText(question: string, name: string): Promise<string> {

    let res = await ChAesUtils.aesDecryptSync(question, name)
    return res
    return res.replaceAll(SearchConstants.IMAGE_REGEX, "") ?? ""
  }
}