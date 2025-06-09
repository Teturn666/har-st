import ChRdb from '../ChRdb';
import DbConstants from '../constants/DbConstants';
import { relationalStore } from '@kit.ArkData';
import { BankListRes } from '../model/BankListRes';
import { Logger } from 'utils';

const TAG = 'QuestionBankTable'

//题库表
class QuestionBankTable {
  private accountTable = new ChRdb(DbConstants.QUESTION_BANK_TABLE.tableName, DbConstants.QUESTION_BANK_TABLE.sqlCreate,
    DbConstants.QUESTION_BANK_TABLE.columns);

  constructor() {

  }

  getRdbStore(callback: Function = () => {
  }) {
    this.accountTable.getRdbStore(callback);
  }

  insertData(account: BankListRes, callback: Function) {
    const valueBucket: relationalStore.ValuesBucket = generateBucket(account);
    this.accountTable.insertData(valueBucket, callback);
  }

  /**
   * 异步插入方法
   */
  async insertDataAwait(account: BankListRes): Promise<number> {
    const valueBucket: relationalStore.ValuesBucket = generateBucket(account)
    return await this.accountTable.insertDataAwait(valueBucket)
  }

  async deleteData(account: BankListRes, callback: Function, rdb?: relationalStore.RdbStore) {
    let predicates = new relationalStore.RdbPredicates(DbConstants.QUESTION_BANK_TABLE.tableName);
    predicates.equalTo('qid', account.qid);
    if (rdb) {
      console.info(TAG, 'deleteData() has rdbStore!');
      await this.accountTable.deleteDataTask(rdb, predicates);
    } else {
      console.info(TAG, 'deleteData() no rdbStore!');
      this.accountTable.deleteData(predicates, callback);
    }
  }

  updateData(account: BankListRes, callback: Function) {
    const valueBucket: relationalStore.ValuesBucket = generateBucket(account);
    let predicates = new relationalStore.RdbPredicates(DbConstants.QUESTION_BANK_TABLE.tableName);
    predicates.equalTo('id', account.qid);
    this.accountTable.updateData(predicates, valueBucket, callback);
  }

  // 抽取的公共查询函数
  private async executeBankQuery(rdbStore: relationalStore.RdbStore, qid: number,
    isAll: boolean = true): Promise<Array<BankListRes>> {
    let predicates = new relationalStore.RdbPredicates(DbConstants.QUESTION_BANK_TABLE.tableName);

    if (!isAll) {
      predicates.equalTo('qid', qid);
    }

    let resultSet = rdbStore.querySync(predicates)
    if (resultSet == null) {
      return []
    } else {
      try {
        let count: number = resultSet.rowCount;
        if (count === 0 || typeof count === 'string') {
          console.log(`${DbConstants.TABLE_TAG}` + 'Query no results!');
          return []
        } else {
          resultSet.goToFirstRow();
          const result: BankListRes[] = [];
          for (let i = 0; i < count; i++) {
            let tmp: BankListRes = {
              id: -1,
              qid: 0,
              name: '',
              desc: '',
              time: '',
              url: '',
              num: '',
              version: '',
              position: 0,
              downloadedState: 2,
              bankType: 0,
              NewFlag: false
            };
            tmp.id = resultSet.getDouble(resultSet.getColumnIndex('id'))
            tmp.qid = resultSet.getDouble(resultSet.getColumnIndex('qid'))
            //这个升级后插入的列
            tmp.num = resultSet.getString(resultSet.getColumnIndex('num'))
            tmp.name = resultSet.getString(resultSet.getColumnIndex('name'))
            tmp.desc = resultSet.getString(resultSet.getColumnIndex('desc'))
            tmp.time = resultSet.getString(resultSet.getColumnIndex('time'))
            tmp.url = resultSet.getString(resultSet.getColumnIndex('url'))
            tmp.version = resultSet.getString(resultSet.getColumnIndex('version'))
            tmp.position = resultSet.getDouble(resultSet.getColumnIndex('position'))
            tmp.downloadedState = resultSet.getDouble(resultSet.getColumnIndex('downloadedState'))
            //这个升级后插入的列
            tmp.bankType = resultSet.getDouble(resultSet.getColumnIndex('bankType'))
            tmp.NewFlag = resultSet.getDouble(resultSet.getColumnIndex('NewFlag')) === 1; // 转换为布尔值
            result[i] = tmp
            resultSet.goToNextRow();
          }
          return result
        }
      } catch (e) {
        Logger.error(e)
        return []
      }
    }
  }

  // 数据查询
  async querySync(qid: number, isAll: boolean = true): Promise<Array<BankListRes>> {
    let rdb = await relationalStore.getRdbStore(getContext(), DbConstants.STORE_CONFIG)
    return this.executeBankQuery(rdb, qid, isAll);
  }

  // 多线程数据查询
  async querySyncTaskPool(rdbStore: relationalStore.RdbStore, qid: number,
    isAll: boolean = true): Promise<Array<BankListRes>> {
    return this.executeBankQuery(rdbStore, qid, isAll);
  }
}

function generateBucket(account: BankListRes): relationalStore.ValuesBucket {
  let obj: relationalStore.ValuesBucket = {}
  obj.qid = account.qid
  obj.name = account.name
  //这个升级后插入的列
  obj.num = account.num
  obj.desc = account.desc
  obj.time = account.time
  obj.url = account.url
  obj.position = account.position
  obj.version = account.version
  obj.downloadedState = account.downloadedState
  //这个升级后插入的列
  obj.bankType = account.bankType
  obj.NewFlag = account.NewFlag ? 1 : 0
  return obj;
}

export const questionBankTable = new QuestionBankTable()