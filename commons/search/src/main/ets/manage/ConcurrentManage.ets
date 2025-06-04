import { SearchEngine } from "../engine/SearchEngine";
import { common } from "@kit.AbilityKit";

const TAG = 'ConcurrentManage'

/**
 * 返回一个最匹配的结果
 * @param qStr 搜索内容
 * @returns 返回结果
 */
// @Concurrent
// export async function searchTask(qStr: string, context: common.Context): Promise<QuestionRes | null> {
//   try {
//     // 注意：在并发函数中需要重新获取单例实例
//     let id = await SearchEngine.getInstance().searchTextWithIndex(qStr);  // 获取题目的id
//     if (id === -1) {
//       return null;
//     }
//
//     // 获取 QuestionTable.getInstance() 实例并查询
//     let rdbStore = await relationalStore.getRdbStore(context, DbConstants.STORE_CONFIG);
//     let result = await QuestionTable.getInstance()?.querySyncTaskPool(rdbStore, id, true, false) ?? [];
//     if (result.length > 0) {
//       return result[0];
//     }
//   } catch (e) {
//     return null;
//   }
//   return null;
// }

/**
 * 返回一个最匹配的结果
 * @param qStr 搜索内容
 * @returns 返回结果
 */
@Concurrent
export async function searchInitCurrent(context: common.Context, qid: number, type: number): Promise<void> {
  // 注意：在并发函数中需要重新获取单例实例
  await SearchEngine.getInstance().indexFromDatabase(context, qid, type)
}


