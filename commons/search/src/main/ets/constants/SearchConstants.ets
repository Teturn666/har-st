import dataPreferences from '@ohos.data.preferences';

export default class SearchConstants {
  // 选项拼接的间隔符
  static readonly SEPARATOR: string = "~~~"
  // 解密字符串的正则
  static readonly IMAGE_REGEX = /\$\{.*?\}/g
  // 题库首选项
  static readonly SEARCH_OPTIONS: dataPreferences.Options = {
    name: 'SearchEngine',
  }
  // 首选项mdataSize键值
  static readonly SEARCH_DATASIZE = 'Search_DATASIZE'
  static readonly SEARCH_FILE_NAME = '/treemap_data.json'
}