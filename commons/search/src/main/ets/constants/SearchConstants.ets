import dataPreferences from '@ohos.data.preferences';

export default class SearchConstants {
  // 选项拼接的间隔符
  static readonly SEPARATOR: string = "~~~"
  // 解密字符串的正则
  static readonly IMAGE_REGEX = /\$\{.*?\}/g
  // 文件路径
  static readonly SEARCH_FILE_ALL = '/search_file_all.json'
  static readonly SEARCH_FILE_SOME = '/search_file_some.json'

}