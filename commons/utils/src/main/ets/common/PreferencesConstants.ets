//存储持久化数据的常量类
export class PreferencesConstants {
  //UUID
  static readonly SP_UUID = 'uuid'
  //是否第一次安装
  static readonly SP_IS_FIRST_INSTALL = 'isFirstInstall'
  //1=已登录
  static readonly SP_IS_LOGIN = 'isLogin'
  //用户昵称
  static readonly SP_NICK_NAME = 'nickName'
  //用户头像
  static readonly SP_AVATAR_URL = 'avatarUrl'
  //union-id
  static readonly SP_UNION_ID = 'union-id'
  //open-id
  static readonly SP_OPEN_ID = 'open-id'
  //是否是会员
  static readonly SP_IS_VIP = 'isVip'
  //会员到期时间
  static readonly SP_VIP_TIME = 'vipTime'
  // setting 存储题目选择的index
  static readonly SP_SELECT_INDEX = 'select_index'
  // setting 题目选择的index所对应的value
  static readonly SP_SELECT_VALUE = 'select_value'
  // setting 题目选择的弹窗是否显示
  static readonly SP_SELECT_DIALOG_SHOW = 'select_dialog_show'
  //是否是VIP会员
  static readonly SP_IS_VIP = 'is_vip'
}