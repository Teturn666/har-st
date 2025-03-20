import dataPreferences from '@ohos.data.preferences';

export default class HomeConstants {
  /**
   * sp config.
   */
  static readonly SP_OPTIONS: dataPreferences.Options = {
    name: 'myFirstDb',
  }
  static readonly HAS_DATA = 'hasData'
  /**
   * 路由跳转的页面名称
   */
  //搜索结果页
  static readonly ROUTER_SEARCH_RESULT = 'searchResultPage'
  //web页面
  static readonly ROUTER_WEB = 'webPage'
  //解密字符串的正则
  static readonly IMAGE_REGEX = /\$\{.*?\}/g
  //使用教程链接
  static readonly USE_TEACH_URL = 'https://ti.iksdt.com/static/doc/stjc.webm'
}