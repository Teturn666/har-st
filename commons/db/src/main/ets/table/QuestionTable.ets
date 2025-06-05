import ChRdb from '../ChRdb';
import DbConstants from '../constants/DbConstants';
import { relationalStore } from '@kit.ArkData';
import { QuestionRes } from '../model/QuestionRes';
import { Logger } from 'utils';

// 题目表（单例模式）
export class QuestionTable {
  private static _instance: QuestionTable;
  private accountTable: ChRdb;

  // 私有构造函数防止外部实例化
  private constructor() {
    this.accountTable = new ChRdb(
      DbConstants.QUESTION_TABLE.tableName,
      DbConstants.QUESTION_TABLE.sqlCreate,
      DbConstants.QUESTION_TABLE.columns
    );
  }

  // 获取单例实例
  public static getInstance(): QuestionTable {
    if (!QuestionTable._instance) {
      QuestionTable._instance = new QuestionTable();
    }
    return QuestionTable._instance;
  }

  getRdbStore(callback: Function = () => {
  }) {
    this.accountTable.getRdbStore(callback);
  }

  insertData(account: QuestionRes, callback: Function) {
    const valueBucket: relationalStore.ValuesBucket = this.generateBucket(account);
    this.accountTable.insertData(valueBucket, callback);
  }

  async insertDataAwait(account: QuestionRes) {
    const valueBucket: relationalStore.ValuesBucket = this.generateBucket(account);
    return await this.accountTable.insertDataAwait(valueBucket);
  }

  deleteData(account: QuestionRes, callback: Function) {
    let predicates = new relationalStore.RdbPredicates(DbConstants.QUESTION_TABLE.tableName);
    predicates.equalTo('qId', account.qId);
    this.accountTable.deleteData(predicates, callback);
  }

  updateData(account: QuestionRes, callback: Function) {
    const valueBucket: relationalStore.ValuesBucket = this.generateBucket(account);
    let predicates = new relationalStore.RdbPredicates(DbConstants.QUESTION_TABLE.tableName);
    predicates.equalTo('id', account.qId);
    this.accountTable.updateData(predicates, valueBucket, callback);
  }

  async querySync(id: number, isSearch: boolean = false, isAll: boolean = true): Promise<Array<QuestionRes>> {
    let predicates = new relationalStore.RdbPredicates(DbConstants.QUESTION_TABLE.tableName);
    let rdb = await relationalStore.getRdbStore(getContext(), DbConstants.STORE_CONFIG)
    if (!isAll) {
      //搜索走的是找id的位置；题库练习走的是根据题库qId找关联的题目
      predicates.equalTo(isSearch ? 'id' : 'qId', id);
    }

    let resultSet = rdb.querySync(predicates)
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
          const result: QuestionRes[] = [];
          for (let i = 0; i < count; i++) {
            let tmp: QuestionRes = {
              id: -1,
              qId: 0,
              qName: '',
              question: '',
              answer: '',
              option: [],
              wrongAnswer: '',
              questionID: 0
            };
            tmp.id = resultSet.getDouble(resultSet.getColumnIndex('id'));
            tmp.qId = resultSet.getDouble(resultSet.getColumnIndex('qId'));
            //这个升级后插入的列
            tmp.qName = resultSet.getString(resultSet.getColumnIndex('qName'));
            tmp.question = resultSet.getString(resultSet.getColumnIndex('question'));
            tmp.answer = resultSet.getString(resultSet.getColumnIndex('answer'));
            tmp.option = resultSet.getString(resultSet.getColumnIndex('option')).split(DbConstants.SEPARATOR);
            tmp.questionID = resultSet.getDouble(resultSet.getColumnIndex('questionID'));
            result[i] = tmp;
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

  async querySyncTaskPool(rdbStore: relationalStore.RdbStore, id: number, isSearch: boolean = false,
    isAll: boolean = true): Promise<Array<QuestionRes>> {
    const predicates = new relationalStore.RdbPredicates(DbConstants.QUESTION_TABLE.tableName);
    if (!isAll) {
      predicates.equalTo(isSearch ? 'id' : 'qId', id);
    }

    const resultSet = rdbStore.querySync(predicates); // 查询到几万条
    if (!resultSet) {
      return [];
    }

    try {
      const count: number = resultSet.rowCount;
      if (count === 0 || typeof count === 'string') {
        console.log(`${DbConstants.TABLE_TAG} Query no results!`);
        return [];
      }

      resultSet.goToFirstRow();
      const result: QuestionRes[] = [];
      for (let i = 0; i < count; i++) {
        const tmp: QuestionRes = {
          id: -1,
          qId: 0,
          qName: '',
          question: '',
          answer: '',
          option: [],
          wrongAnswer: '',
          questionID: 0
        };
        tmp.id = resultSet.getDouble(resultSet.getColumnIndex('id'));
        tmp.qId = resultSet.getDouble(resultSet.getColumnIndex('qId'));
        tmp.qName = resultSet.getString(resultSet.getColumnIndex('qName'));
        tmp.question = resultSet.getString(resultSet.getColumnIndex('question'));
        tmp.answer = resultSet.getString(resultSet.getColumnIndex('answer'));
        tmp.option = resultSet.getString(resultSet.getColumnIndex('option')).split(DbConstants.SEPARATOR);
        tmp.questionID = resultSet.getDouble(resultSet.getColumnIndex('questionID'));
        result[i] = tmp;
        resultSet.goToNextRow();
      }
      return result;
    } catch (e) {
      Logger.error(e);
      return [];
    }
  }

  /**
   * 生成ValuesBucket
   * @param account
   * @returns
   */
  private generateBucket(account: QuestionRes): relationalStore.ValuesBucket {
    return {
      qId: account.qId,
      qName: account.qName,
      question: account.question,
      answer: account.answer,
      option: (account.option ?? []).join(DbConstants.SEPARATOR),
      questionID: account.questionID
    };
  }
}
