import ChRdb from '../ChRdb';
import DbConstants from '../constants/DbConstants';
import { relationalStore } from '@kit.ArkData';
import { Logger } from 'utils';
import { QuestionRes } from '../model/QuestionRes';

//收藏题目表
class QuestionCollectionTable {
  private accountTable =
    new ChRdb(DbConstants.QUESTION_COLLECTION_TABLE.tableName, DbConstants.QUESTION_COLLECTION_TABLE.sqlCreate,
      DbConstants.QUESTION_COLLECTION_TABLE.columns);

  constructor() {

  }

  getRdbStore(callback: Function = () => {
  }) {
    this.accountTable.getRdbStore(callback);
  }

  insertData(account: QuestionRes, callback: Function) {
    const valueBucket: relationalStore.ValuesBucket = generateBucket(account);
    this.accountTable.insertData(valueBucket, callback);
  }

  async insertDataAwait(account: QuestionRes) {
    const valueBucket: relationalStore.ValuesBucket = generateBucket(account);
    return await this.accountTable.insertDataAwait(valueBucket);
  }

  async deleteData(account: QuestionRes, callback: Function, rdb?: relationalStore.RdbStore) {
    let predicates = new relationalStore.RdbPredicates(DbConstants.QUESTION_COLLECTION_TABLE.tableName);
    predicates.equalTo('qId', account.qId);
    if (rdb) {
      await this.accountTable.deleteDataTask(rdb, predicates);
    } else {
      this.accountTable.deleteData(predicates, callback);
    }
  }

  async deleteDataByQuestionID(questionID: number): Promise<void> {
    try {
      let predicates = new relationalStore.RdbPredicates(DbConstants.QUESTION_COLLECTION_TABLE.tableName);
      predicates.equalTo('questionID', questionID);
      const affectedRows = await this.accountTable.deleteDataAwait(predicates);
      Logger.info(`已删除收藏表中 questionID=${questionID} 的记录，影响行数: ${affectedRows}`);
    } catch (err) {
      Logger.error(`删除 questionID=${questionID} 的收藏记录失败: ${err}`);
    }
  }

  updateData(account: QuestionRes, callback: Function) {
    const valueBucket: relationalStore.ValuesBucket = generateBucket(account);
    let predicates = new relationalStore.RdbPredicates(DbConstants.QUESTION_COLLECTION_TABLE.tableName);
    predicates.equalTo('id', account.qId);
    this.accountTable.updateData(predicates, valueBucket, callback);
  }

  // 抽取的公共查询函数 - QuestionCollectionRes
  private async executeQuestionCollectionQuery(rdbStore: relationalStore.RdbStore, id: number, isAll: boolean = true): Promise<Array<QuestionRes>> {
    let predicates = new relationalStore.RdbPredicates(DbConstants.QUESTION_COLLECTION_TABLE.tableName);

    if (!isAll) {
      predicates.equalTo('qId', id);
    }

    let resultSet = await this.accountTable.querySync(rdbStore, predicates);
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
            tmp.question = resultSet.getString(resultSet.getColumnIndex('question'));
            tmp.answer = resultSet.getString(resultSet.getColumnIndex('answer'));
            tmp.wrongAnswer = resultSet.getString(resultSet.getColumnIndex('wrongAnswer'));
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

  // 重构后的 QuestionCollection 查询函数
  async querySync(id: number, isAll: boolean = true): Promise<Array<QuestionRes>> {
    let rdb = await relationalStore.getRdbStore(getContext(), DbConstants.STORE_CONFIG)
    return this.executeQuestionCollectionQuery(rdb, id, isAll);
  }

  async querySyncTaskPool(rdbStore: relationalStore.RdbStore, id: number,
    isAll: boolean = true): Promise<Array<QuestionRes>> {
    return this.executeQuestionCollectionQuery(rdbStore, id, isAll);
  }
}

function generateBucket(account: QuestionRes): relationalStore.ValuesBucket {
  let obj: relationalStore.ValuesBucket = {};
  obj.qId = account.qId;
  obj.question = account.question;
  obj.answer = account.answer;
  obj.wrongAnswer = account.wrongAnswer;
  obj.option = (account.option ?? []).join(DbConstants.SEPARATOR)
  obj.questionID = account.questionID;

  return obj;
}

export const questionCollectionTable = new QuestionCollectionTable()