import { ChAesUtils } from '@ohos/encryption';
import SearchConstants from '../constants/SearchConstants';


//搜索后解密的工具类
export class SearchDecryptUtils {
  /**
   * 获取题目文本（不包含图片插值语句）
   */
  static async getQuestionText(question: string, id: number): Promise<string> {

    let res = await ChAesUtils.aesDecryptSync(question, id)
    return res.replaceAll(SearchConstants.IMAGE_REGEX, "") ?? ""
  }

  /**
   * 获取选项内容
   * @returns Array<string> 选项列表
   */
  static async getOptions(list: string[], id: number): Promise<Array<string>> {
    let res = new Array<string>()
    for (let option of list) {
      res.push(await ChAesUtils.aesDecryptSync(option, id))
    }
    return res
  }

  /**
   * 获取题目中的图片
   * @returns 图片列表
   */
  static async getQuestionImages(question: string, id: number): Promise<Array<string>> {
    let res = new Array<string>()
    let questionText = await SearchDecryptUtils.getQuestionText(question, id)
    let images = SearchConstants.IMAGE_REGEX.exec(questionText)
    for (let imagesElement of images ?? []) {
      res.push(imagesElement.replace("${", "").replace("}", ""))
    }
    return res
  }

  /**
   * 获取答案内容
   * @returns 答案文本
   */
  static async getQuestionAnswer(answer: string, id: number): Promise<string> {
    let res = await ChAesUtils.aesDecryptSync(answer, id)
    return res
  }

  /**
   * 获取答案内容
   * @returns 答案文本
   */
  async getQuestionAnswerArray(answer: string, id: number): Promise<Array<string>> {
    let answerArray: string[] = []
    let answerText = await SearchDecryptUtils.getQuestionAnswer(answer, id)

    //拆分答案
    for (let i = 0; i < answerText.length; i++) {
      answerArray[i] = answerText.charAt(i)
    }
    return answerArray
  }

  /**
   * 获取用前缀拼接的选项
   * @param separator 自定义分隔符，这里默认用.
   * @returns 拼接后的选项列表
   */
  static async getOptionsWithPrefix(separator: string = ".", optionsList: string[]): Promise<string[]> {
    let res = Array<string>()
    for (let i = 0; i < optionsList.length; i++) {
      let prefix = String.fromCharCode('A'.charCodeAt(0) + i)
      res.push(prefix + separator + optionsList[i])
    }
    return res
  }

  /**
   * 获取拼接的问题
   * 选项是拼接在前面、中间、后面,目前使用数字1，2，3依次递增，后面有多个类型在添加。默认是3的样式
   */
  static async getQuestionWithPrefix(location: number = 3, question: string, questionCase: string): Promise<string> {
    let res = question
    switch (location) {
      case 3:
        res = question + '【' + questionCase + '】'
        break
    }

    return res
  }

  /**
   * 判断给到的选项下标是不是正确选项
   * 然后返回位置存储
   */
  static isCorrectAnswer(position: number, answer: string): number {
    let prefix = String.fromCharCode('A'.charCodeAt(0) + position)
    if (answer.includes(prefix)) {
      return position
    }
    return -1
  }
}