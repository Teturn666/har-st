//分词工具
import { List } from '@kit.ArkTS'

export class SegmentEngine {
  private static readonly TYPE_NONE = -1 //不处理
  private static readonly TYPE_ALP = 1 //字母和数字
  private static readonly TYPE_HAN = 2 //汉字
  private static _instance: SegmentEngine | null = null //显式声明可以为null

  private constructor() {
  }

  public static getInstance(): SegmentEngine {
    if (!SegmentEngine._instance) {
      SegmentEngine._instance = new SegmentEngine()
    }
    return SegmentEngine._instance as SegmentEngine
  }

  /**
   * 汉字：[0x4e00,0x9fa5] 或  十进制[19968,40869]
   * 数字：[0x30,0x39] 或   十进制[48, 57]
   * 小写字母：[0x61,0x7a] 或  十进制[97, 122]
   * 大写字母：[0x41,0x5a] 或  十进制[65, 90]
   * @param str
   * @returns
   */
  public cut(content: string): Array<string> {
    let list: Array<string> = []
    let str = "";
    for (let i = 0; i < content.length; i++) {
      //转换成ASCII编码
      // const charCode = content.charCodeAt(i)
      const char = content.charAt(i)
      // let curType = this.getCharType(charCode, char)
      let curType = this.getCharType(char)
      if (curType === SegmentEngine.TYPE_ALP) {
        str += char
      } else if (curType === SegmentEngine.TYPE_HAN) {
        if (str.length > 0) {
          list.push(str)
          str = ''
        }
        list.push('' + char)
      } else {
        if (str.length > 0) {
          list.push(str)
          str = ''
        }
      }

    }
    if (str.length > 0) {
      list.push(str)
    }
    return list
  }

  // //通过ASCII判断是什么类型
  // private getCharType(charCode: number, char: string): number {
  //   if (this.isChinese(charCode, char)) {
  //     return SegmentEngine.TYPE_HAN
  //   } else if (charCode >= 48 && charCode <= 57) {
  //     return SegmentEngine.TYPE_ALP
  //   } else if (charCode >= 65 && charCode <= 90) {
  //     return SegmentEngine.TYPE_ALP
  //   } else if (charCode >= 97 && charCode <= 122) {
  //     return SegmentEngine.TYPE_ALP
  //   }
  //   return SegmentEngine.TYPE_NONE
  // }
  public getCharType(c: string): number {
    if (this.isChinese(c)) {
      return SegmentEngine.TYPE_HAN;
    } else if (c >= "a" && c <= "z") {
      return SegmentEngine.TYPE_ALP;
    } else if (c >= "A" && c <= "Z") {
      return SegmentEngine.TYPE_ALP;
    } else if (c >= "0" && c <= "9") {
      return SegmentEngine.TYPE_ALP;
    }
    return SegmentEngine.TYPE_NONE;
  }

  // //是否是汉字，不包含中文标点符号
  // private isChinese(charCode: number, char: string): boolean {
  //   if (charCode > 127 && !this.isChinesePun(char)) {
  //     return true
  //   }
  //   return false
  // }
  //
  // //判断是否是中文的标点符号，中文的标点符号值也大于127了
  // private isChinesePun(s: string): boolean {
  //   if ('\u3000' <= s && s <= '\u303F') {
  //     return true
  //   }
  //   return false
  // }

  private isChinese(c: string): boolean {
    if (c.length !== 1) {
      return false;
    }
    const code = c.charCodeAt(0);
    if (code >= 0x4e00 && code <= 0x9fa5) {
      return true;
    }
    // 检查扩展字符集
    if (code >= 0x3400 && code <= 0x4dbf) { // CJK统一表意文字扩展A
      return true;
    }
    if (code >= 0x20000 && code <= 0x2A6DF) { // CJK统一表意文字扩展B
      return true;
    }
    if (code >= 0x2A700 && code <= 0x2B73F) { // CJK统一表意文字扩展C
      return true;
    }
    if (code >= 0x2B740 && code <= 0x2B81F) { // CJK统一表意文字扩展D
      return true;
    }
    if (code >= 0xF900 && code <= 0xFAFF) { // CJK兼容表意文字
      return true;
    }
    if (code >= 0x2F800 && code <= 0x2FA1F) { // CJK兼容表意文字补充
      return true;
    }
    return false;
  }
}