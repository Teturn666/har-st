import { preferences } from '@kit.ArkData';
import { Logger } from 'utils';
import { common } from '@kit.AbilityKit';

const context = (getContext(this) as common.UIAbilityContext)
const TAG = '[BankList]'

// NEW标识状态管理器
export  class NewFlagManager {
  private static instance: NewFlagManager;
  private dataStore: preferences.Preferences | null = null;
  private readonly STORE_NAME = 'bank_new_flag_store';
  private readonly VIEWED_KEY_PREFIX = 'viewed_'; // 查看状态前缀
  private readonly VERSION_KEY_PREFIX = 'version_'; // 版本号前缀

  static getInstance(): NewFlagManager {
    if (!NewFlagManager.instance) {
      NewFlagManager.instance = new NewFlagManager();
    }
    return NewFlagManager.instance;
  }

  async init(): Promise<void> {
    try {
      this.dataStore = await preferences.getPreferences(context, this.STORE_NAME);
    } catch (error) {
      Logger.error(TAG, `初始化NewFlagManager失败: ${error}`);
    }
  }

  // 标记题库为已查看（下载或跳转详情时调用）
  async markAsViewed(qid: number, version: string): Promise<void> {
    if (!this.dataStore) await this.init();
    if (!this.dataStore) return;

    try {
      await this.dataStore.put(`${this.VIEWED_KEY_PREFIX}${qid}`, true);
      await this.dataStore.put(`${this.VERSION_KEY_PREFIX}${qid}`, version);
      await this.dataStore.flush();
      Logger.info(TAG, `标记题库${qid}为已查看，版本: ${version}`);
    } catch (error) {
      Logger.error(TAG, `标记题库${qid}为已查看失败: ${error}`);
    }
  }

  // 检查是否应该显示NEW标识
  async shouldShowNew(qid: number, currentVersion: string, originalNewFlag: boolean): Promise<boolean> {
    // 如果原本就没有NEW标识，直接返回false
    if (!originalNewFlag) {
      return false;
    }

    if (!this.dataStore) await this.init();
    if (!this.dataStore) return originalNewFlag; // 如果无法获取存储，返回原始状态

    try {
      const hasViewed = await this.dataStore.get(`${this.VIEWED_KEY_PREFIX}${qid}`, false) as boolean;
      const lastViewedVersion = await this.dataStore.get(`${this.VERSION_KEY_PREFIX}${qid}`, '') as string;

      // 如果从未查看过，显示NEW（保持原有的NewFlag状态）
      if (!hasViewed) {
        return true;
      }

      // 如果已经查看过，检查是否有新版本
      if (lastViewedVersion && currentVersion && Number(currentVersion) > Number(lastViewedVersion)) {
        Logger.info(TAG, `题库${qid}有新版本，当前: ${currentVersion}, 上次查看: ${lastViewedVersion}`);
        return true;
      }

      // 如果已经查看过且没有新版本，不显示NEW
      return false;
    } catch (error) {
      Logger.error(TAG, `检查题库${qid}NEW状态失败: ${error}`);
      return originalNewFlag; // 出错时返回原始状态
    }
  }

  // 清空所有记录（可选，用于测试或重置）
  async clearAll(): Promise<void> {
    if (!this.dataStore) await this.init();
    if (!this.dataStore) return;

    try {
      await this.dataStore.clear();
      await this.dataStore.flush();
      Logger.info(TAG, 'NEW标识记录已清空');
    } catch (error) {
      Logger.error(TAG, `清空NEW标识记录失败: ${error}`);
    }
  }
}