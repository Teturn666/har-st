import { relationalStore } from '@kit.ArkData';
import { DbTableBean } from '../model/DbTableBean';

export default class DbConstants {
  /**
   * Rdb database config.
   */
  static readonly STORE_CONFIG: relationalStore.StoreConfig = {
    name: 'question.db',
    securityLevel: relationalStore.SecurityLevel.S1
  };
  /**
   * Account table config.
   */
  //题库表
  static readonly QUESTION_BANK_TABLE: DbTableBean = {
    tableName: 'questionBank',
    sqlCreate: 'CREATE TABLE IF NOT EXISTS questionBank(id INTEGER PRIMARY KEY AUTOINCREMENT, bankId INTEGER, ' +
      'name TEXT, version TEXT)',
    columns: ['id', 'bankId', 'name', 'version']
  };
  //题目表
  static readonly QUESTION_TABLE: DbTableBean = {
    tableName: 'question',
    sqlCreate: 'CREATE TABLE IF NOT EXISTS question(id INTEGER PRIMARY KEY AUTOINCREMENT, questionId INTEGER, ' +
      'chapterId INTEGER, questionCase TEXT, question TEXT, option TEXT, answer TEXT, questionImg TEXT)',
    columns: ['id', 'questionId', 'chapterId', 'questionCase', 'question', 'option', 'answer', 'questionImg']
  };
  /**
   * Log tag.
   */
  static readonly RDB_TAG = '[Debug.ChRdb]';
  static readonly TABLE_TAG = '[Debug.AccountTable]';
  //选项拼接的间隔符
  static readonly SEPARATOR: string = "~~~"
}