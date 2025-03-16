import ChRdb from '../ChRdb';
import DbConstants from '../constants/DbConstants';
import { relationalStore } from '@kit.ArkData';
import { BankListRes } from '../model/BankListRes';

//题库表
export class QuestionBankTable {
  private accountTable = new ChRdb(DbConstants.QUESTION_BANK_TABLE.tableName, DbConstants.QUESTION_BANK_TABLE.sqlCreate,
    DbConstants.QUESTION_BANK_TABLE.columns);

  constructor(callback: Function = () => {
  }) {
    this.accountTable.getRdbStore(callback);
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

  deleteData(account: BankListRes, callback: Function) {
    let predicates = new relationalStore.RdbPredicates(DbConstants.QUESTION_BANK_TABLE.tableName);
    predicates.equalTo('id', account.qid);
    this.accountTable.deleteData(predicates, callback);
  }

  updateData(account: BankListRes, callback: Function) {
    const valueBucket: relationalStore.ValuesBucket = generateBucket(account);
    let predicates = new relationalStore.RdbPredicates(DbConstants.QUESTION_BANK_TABLE.tableName);
    predicates.equalTo('id', account.qid);
    this.accountTable.updateData(predicates, valueBucket, callback);
  }

  query(amount: number, callback: Function, isAll: boolean = true) {
    let predicates = new relationalStore.RdbPredicates(DbConstants.QUESTION_BANK_TABLE.tableName);
    if (!isAll) {
      predicates.equalTo('amount', amount);
    }
    this.accountTable.query(predicates, (resultSet: relationalStore.ResultSet) => {
      let count: number = resultSet.rowCount;
      if (count === 0 || typeof count === 'string') {
        console.log(`${DbConstants.TABLE_TAG}` + 'Query no results!');
        callback([]);
      } else {
        resultSet.goToFirstRow();
        const result: BankListRes[] = [];
        for (let i = 0; i < count; i++) {
          let tmp: BankListRes = {
            qid: '',
            name: '',
            desc: '',
            time: '',
            url: '',
            version: 0,
            position: 0,

          };
          tmp.qid = resultSet.getString(resultSet.getColumnIndex('qid'));
          tmp.name = resultSet.getString(resultSet.getColumnIndex('name'));
          tmp.desc = resultSet.getString(resultSet.getColumnIndex('desc'));
          tmp.time = resultSet.getString(resultSet.getColumnIndex('time'));
          tmp.url = resultSet.getString(resultSet.getColumnIndex('url'));
          tmp.version = resultSet.getDouble(resultSet.getColumnIndex('version'));
          tmp.position = resultSet.getDouble(resultSet.getColumnIndex('position'));
          result[i] = tmp;
          resultSet.goToNextRow();
        }
        callback(result);
      }
    });
  }
}

function generateBucket(account: BankListRes): relationalStore.ValuesBucket {
  let obj: relationalStore.ValuesBucket = {};
  obj.qid = account.qid;
  obj.name = account.name;
  obj.desc = account.desc;
  obj.time = account.time;
  obj.url = account.url;
  obj.position = account.position;
  obj.version = account.version;
  return obj;
}