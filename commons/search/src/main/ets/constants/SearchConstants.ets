import dataPreferences from '@ohos.data.preferences';

export default class SearchConstants {
  // 选项拼接的间隔符
  static readonly SEPARATOR: string = "~~~"
  // 解密字符串的正则
  static readonly IMAGE_REGEX = /\$\{.*?\}/g

  // 首选项mdataSize数量
  static readonly SEARCH_DATASIZE_ALL = 'Search_dataSize_all'
  static readonly SEARCH_DATASIZE_SOME = 'Search_dataSize_some'

  // 文件路径
  static readonly SEARCH_FILE_ALL = '/search_file_all.json'
  static readonly SEARCH_FILE_SOME = '/search_file_some.json'

}