import { Logger, StringUtils } from 'utils'

export class StringFilter {
  private static readonly ALPLIST: string = "ABCDEFGHIJKLMNOPQRST"

  public static formatString(s: string): string {
    if (!s) {
      return s
    }
    // let newS = s.replace(" ", "_")// 替换不间断空格
    let newS = s.replace(/\u00A0/g, "_")// 替换不间断空格
    // 删除 .之前内容
    // let arr: string[] = newS.split("、", 2)
    // if (arr.length < 1) {
    //   arr = newS.split(".", 2);
    // }
    const arr = newS.split(/[. 、]/, 2);

    // if (arr.length > 1) {
    //   let ary = arr[0].match('\\d+')
    //   let result = StringFilter.ALPLIST.search(arr[0].toUpperCase())
    //   //ary是数字
    //   if (ary != null) {
    //     newS = newS.substring(arr[0].length + 1).trim()
    //   } else if (result != -1) {
    //     //包含搜索的结果
    //     newS = newS.substring(arr[0].length + 1).trim()
    //   }
    // }
    if (arr.length > 1) {
      if (/^\d+$/.test(arr[0])) { // 判断是否全数字
        newS = newS.substring(arr[0].length + 1).trim();
      } else if (StringFilter.ALPLIST.includes(arr[0].toUpperCase())) {
        // 适配答案
        newS = newS.substring(arr[0].length + 1).trim();
      }
    }
    Logger.error("====ary===" + newS)

    return newS
  }
}