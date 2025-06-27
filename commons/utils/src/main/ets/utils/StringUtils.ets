import { util } from '@kit.ArkTS';

export class StringUtils {
  static stringToUint8Array(str: String) {
    let arr: number[] = new Array();
    for (let i = 0, j = str.length; i < j; ++i) {
      arr.push(str.charCodeAt(i));
    }
    let tmpArray = new Uint8Array(arr);
    return tmpArray;
  }

  static uint8ArrayToString(array: Uint8Array): string {
    let textDecoder = util.TextDecoder.create("utf-8", { ignoreBOM: true })
    let arrayString = textDecoder.decodeToString(array, { stream: false })
    return arrayString
  }

  static stringToUint8ArrayUtf8(str: string) {
    //编码
    let strBuff = new util.TextEncoder().encodeInto(str) //utf-8
    //解码
    let newStr = util.TextDecoder.create("utf-8").decodeToString(new Uint8Array(strBuff))
    console.info(newStr)
    return newStr
  }

  static isNullOrEmpty(str: string): boolean {
    if (str === null || str.length === 0 || str.trim().length === 0) {
      return true
    }
    return false
  }

  static subUrl(url: string): string {
    return url.substring(url.lastIndexOf('/') + 1)
  }

  static subLastIndex(str: string, s: string): string {
    return str.substring(str.lastIndexOf(s))
  }

  /**
   * 过滤字符串，只保留白名单中的字符
   * @param str 原始字符串
   * @param allowedChars 允许的字符集合
   * @returns 过滤后的字符串
   */
  static filterStringByWhitelist(str: string, allowedChars: string): string {
    if (!str || !allowedChars) {
      return '';
    }

    const charSet = new Set(allowedChars.split(''));
    let result = '';

    for (let char of str) {
      if (charSet.has(char)) {
        result += char;
      }
    }

    return result;
  }
}