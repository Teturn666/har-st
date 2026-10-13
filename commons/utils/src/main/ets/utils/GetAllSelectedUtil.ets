import { PreferencesConstants } from "../common/PreferencesConstants";
import { preferencesUtils } from "../common/PreferencesUtils";

interface UserBankSelection {
  uid: string;
  selectedBankIds: string[];
  isAllSelected: boolean;
  lastModified: number;
}


export class GetAllSelectedUtil {
  /**
   * 检查用户是否全选
   * @returns boolean - 如果未登录返回true，已登录返回用户的isAllSelected状态
   */
  static isUserBankAllSelected(ctx?: Context): boolean {
    // 先判断是否已登录
    const loginState = preferencesUtils.getString(PreferencesConstants.SP_IS_LOGIN, '0', ctx);

    // 如果未登录，返回true
    if (loginState === '0') {
      return true;
    }

    // 如果已登录，获取当前用户ID
    const currentUid = preferencesUtils.getString(PreferencesConstants.SP_U_ID, 'guest', ctx);
    try {
      const key = `${currentUid}`;
      const raw = preferencesUtils.getString(PreferencesConstants.SP_QUESTION_BANK_ + `${key}`, '', ctx);

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