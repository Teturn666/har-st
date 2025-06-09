import { common } from "@kit.AbilityKit";
import { questionBankTable, questionCollectionTable, QuestionTable, questionWrongTable } from "db";
import { Logger } from "utils";
import { relationalStore } from "@kit.ArkData";
import DbConstants from "db/src/main/ets/constants/DbConstants";
import { BankModel } from '../model/BankModel'

const TAG = 'ConcurrentManage'

/**
 * 返回一个最匹配的结果
 * @param qStr 搜索内容
 * @returns 返回结果
 */
@Concurrent
export async function deleteTableTask(context: common.Context, qid: number): Promise<void> {
  // 只获取一次数据库连接
  let rdbStore = await relationalStore.getRdbStore(context, DbConstants.STORE_CONFIG);

  //删除相应的题库表
  let bankResultList = await questionBankTable.querySyncTaskPool(rdbStore, qid, false) ?? [];
  if (bankResultList.length > 0) {
    let bankRes = bankResultList[0]
    await questionBankTable.deleteData(bankRes, (resFlag: boolean) => {
      Logger.debug('ConcurrentManage', '题库deleteData--------' + resFlag)
    }, rdbStore)
  }

  //删除相应的题目表
  let bankQaResultList = await QuestionTable.getInstance().querySyncTaskPool(rdbStore, qid, false, false) ?? [];
  if (bankQaResultList.length > 0) {
    for (const item of bankQaResultList) {
      await QuestionTable.getInstance().deleteData(item, (resFlag: boolean) => {
        Logger.debug('ConcurrentManage', '题目deleteData--------' + resFlag)
      }, rdbStore)
    }
  }

  //删除相应的收藏表
  let collectionResultList = await questionCollectionTable.querySyncTaskPool(rdbStore, qid, false) ?? [];
  if (collectionResultList.length > 0) {
    for (const item of collectionResultList) {
      await questionCollectionTable.deleteData(item, (resFlag: boolean) => {
        Logger.debug('ConcurrentManage', '收藏题目deleteData--------' + resFlag)
      }, rdbStore)
    }
  }

  //删除相应的错题表
  let wrongResultList = await questionWrongTable.querySyncTaskPool(rdbStore, qid, false) ?? [];
  if (wrongResultList.length > 0) {
    for (const item of wrongResultList) {
      await questionWrongTable.deleteData(item, (resFlag: boolean) => {
        Logger.debug('ConcurrentManage', '错题题目deleteData--------' + resFlag)
      }, rdbStore)
    }
  }

  // 初始化搜索
  await BankModel.getInstance().initSearchEnginTask(context, 0, 0, 2)
  Logger.debug('ConcurrentManage', 'deleteData-------- 删除成功')
}


