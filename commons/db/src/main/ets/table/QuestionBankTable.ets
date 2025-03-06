import ChRdb from '../ChRdb';
import DbConstants from '../constants/DbConstants';
import { relationalStore } from '@kit.ArkData';
import { HomeBankListRes } from '../model/HomeBankListRes';

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

  insertData(account: HomeBankListRes, callback: Function) {
    const valueBucket: relationalStore.ValuesBucket = generateBucket(account);
    this.accountTable.insertData(valueBucket, callback);
  }

  /**
   * 异步插入方法
   */
  async insertDataAwait(account: HomeBankListRes): Promise<number> {
    const valueBucket: relationalStore.ValuesBucket = generateBucket(account)
    return await this.accountTable.insertDataAwait(valueBucket)
  }

  deleteData(account: HomeBankListRes, callback: Function) {
    let predicates = new relationalStore.RdbPredicates(DbConstants.QUESTION_BANK_TABLE.tableName);
    predicates.equalTo('id', account.id);
    this.accountTable.deleteData(predicates, callback);
  }

  updateData(account: HomeBankListRes, callback: Function) {
    const valueBucket: relationalStore.ValuesBucket = generateBucket(account);
    let predicates = new relationalStore.RdbPredicates(DbConstants.QUESTION_BANK_TABLE.tableName);
    predicates.equalTo('id', account.id);
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
        const result: HomeBankListRes[] = [];
        for (let i = 0; i < count; i++) {
          let tmp: HomeBankListRes = {
            id: 0,
            name: '',
            desc: '',
            cover: '',
            version: '0'
          };
          tmp.id = resultSet.getDouble(resultSet.getColumnIndex('bankId'));
          tmp.name = resultSet.getString(resultSet.getColumnIndex('name'));
          tmp.version = resultSet.getString(resultSet.getColumnIndex('version'));
          result[i] = tmp;
          resultSet.goToNextRow();
        }
        callback(result);
      }
    });
  }
}

function generateBucket(account: HomeBankListRes): relationalStore.ValuesBucket {
  let obj: relationalStore.ValuesBucket = {};
  obj.bankId = account.id;
  obj.name = account.name;
  obj.version = account.version;
  return obj;
}