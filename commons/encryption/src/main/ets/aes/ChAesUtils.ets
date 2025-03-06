import util from '@ohos.util';
import { Logger, StringUtils } from '@ohos/utils'
import cryptoFramework from '@ohos.security.cryptoFramework';
import { ChAesCallBack } from './ChAesCallBack';

const KEY: string = "QGKINVCYHLJXDYHLYYPZJXLLCBFMJHCH"

export class ChAesUtils {
  //加密后的题目
  // static message: string = "ruDehMEITkJu70QrEgGBfuEYk8P3+JFQsywMulQAm2HemRQ0Bw9NR04An/36Kuc/ABpyEsYziqvbzftSsIA8HH7OZqlvV91n/N9a4mDmw/s="
  //解密后的题目
  // static aesMessage: string = "下车时驾驶员应用（）提示乘客勿遗忘随身物品。\n"
  // static iv: string = '49934QGKINVCYHLJ'

  static aesDecrypt(message: string, iv: string, callback: ChAesCallBack) {
    let paramsSpec: cryptoFramework.IvParamsSpec = {
      iv: { data: StringUtils.stringToUint8Array(iv) },
      algName: "IvParamsSpec"
    }

    let aesGenerator = cryptoFramework.createSymKeyGenerator('AES256');
    let cipher = cryptoFramework.createCipher('AES256|CBC|PKCS5');
    let that = new util.Base64Helper();
    let pubKeyBlob: cryptoFramework.DataBlob = { data: StringUtils.stringToUint8Array(KEY) };
    aesGenerator.convertKey(pubKeyBlob, (err, symKey) => {
      if (err) {
        console.error("convertKey: error.");
        callback.aesFail($r('app.string.key_err'))
        return;
      }
      cipher.init(cryptoFramework.CryptoMode.DECRYPT_MODE, symKey, paramsSpec, (err, data) => {
        let newMessage = that.decodeSync(message);
        let input: cryptoFramework.DataBlob = { data: newMessage };
        cipher.doFinal(input, (err, data) => {
          if (err) {
            Logger.info("result is empty");
            callback.aesFail($r('app.string.data_empty'))
          } else {
            Logger.info("DecryptOutPut is " + data.data);
            let result = StringUtils.uint8ArrayToString(data.data)
            Logger.info("result is " + result);
            callback.aesSuccess(result)
            // callback.aesFail($r('app.string.data_empty'))
          }
        })
      })
    })
  }

  /**
   * 解密异步方法
   */
  static async aesDecryptSync(message: string, questionId: number): Promise<string> {

    let iv = (questionId + KEY).substring(0, 16)

    let paramsSpec: cryptoFramework.IvParamsSpec = {
      iv: { data: StringUtils.stringToUint8Array(iv) },
      algName: "IvParamsSpec"
    }

    let aesGenerator = cryptoFramework.createSymKeyGenerator('AES256');
    let cipher = cryptoFramework.createCipher('AES256|CBC|PKCS5');
    let that = new util.Base64Helper();
    let pubKeyBlob: cryptoFramework.DataBlob = { data: StringUtils.stringToUint8Array(KEY) };
    try {
      let symKey = await aesGenerator.convertKey(pubKeyBlob)

      await cipher.init(cryptoFramework.CryptoMode.DECRYPT_MODE, symKey, paramsSpec)

      let newMessage = that.decodeSync(message);
      let input: cryptoFramework.DataBlob = { data: newMessage };

      let data = await cipher.doFinal(input)

      // Logger.info("DecryptOutPut is " + data.data);
      let result = StringUtils.uint8ArrayToString(data.data)
      // Logger.info("result is " + result);
      return result
    } catch (e) {
      Logger.debug("xxx" + e)
      return ""
    }
  }
}