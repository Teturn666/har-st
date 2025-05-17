export default class SettingConstants {
  /**
   * 路由跳转的页面名称
   */
  //搜索结果页
  static readonly ROUTER_ABOUT_US = 'aboutUsPage'
  // setting 持久化数据名称
  static readonly ROUTER_SETTING_NAME = 'settingData'

  // setting 持久化数据名称，题的数量
  static readonly ROUTER_SETTING_NAME_NUMBERS_QUESTIONS = 'countQuestion'

  // setting 持久化数据名称，题的数量-全局使用
  static readonly ROUTER_SETTING_NAME_NUMBERS_QUESTIONS_GLOBAL = 'countQuestion_global'


  // setting 题数量
  static readonly ROUTER_SETTING_NUMBERS_QUESTIONS =['5', '10', '15', '20', '25'];
  //登录页面
  static readonly LOGIN = 'login'
  //H5页面
  static readonly ROUTER_WEB = 'webPage'
  //隐私政策链接
  static readonly USER_PRIVACY_URL = 'https://ti.iksdt.com/static/doc/yszc.html'
  //用户协议链接
  static readonly USER_AGREEMENT_URL = 'https://ti.iksdt.com/static/doc/yhxy.html'
  //意见反馈
  static readonly FEEDBACK_URL =
    'https://crmeb.yweiai.com/chat/pc?noCanClose=1&kefu_id=12&token=075774b0dae195a3b971d8f98388d502&openid=harmony&nickName=harmony'
}