//存储持久化数据的常量类
export class PreferencesConstants {
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
  // setting 存储题目选择的index
  static readonly SP_SELECT_INDEX = 'select_index'
  // setting 题目选择的index所对应的value
  static readonly SP_SELECT_VALUE = 'select_value'
}