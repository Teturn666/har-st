import { PreferencesConstants, preferencesUtils } from "utils";
import { UserBankSelection } from "../model/UserBankSelection";

export  class GetAllSelectedUtil {
  /**
   * 检查用户是否全选
   * @returns boolean - 如果未登录返回false，已登录返回用户的isAllSelected状态
   */
  isUserBankAllSelected(): boolean {
    // 先判断是否已登录
    const loginState = preferencesUtils.getString(PreferencesConstants.SP_IS_LOGIN, '0');

    // 如果未登录，返回false
    if (loginState === '0') {
      return false;
    }

    // 如果已登录，获取当前用户ID
    const currentUid = preferencesUtils.getString(PreferencesConstants.SP_U_ID, 'guest');
    try {
      const key = `${currentUid}`;
      const raw = preferencesUtils.getString(PreferencesConstants.SP_QUESTION_BANK_ + `${key}`, '');

      if (raw) {
        const parsed: UserBankSelection = JSON.parse(raw);
        return parsed.isAllSelected;
      } else {
        // 没有记录，默认返回true（全选）
        return true;
      }
    } catch (e) {
      console.error(`[isUserBankAllSelected] 解析失败`, e);
      return false;
    }
  }
}