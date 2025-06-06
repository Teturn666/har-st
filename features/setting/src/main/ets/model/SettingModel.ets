import {
  BankListRes,
  questionBankTable,
} from 'db'
import { LoadingStatus, Logger } from 'utils/Index'

const TAG = '[SettingModel]'

@Observed
export class SettingModel {
  private static instance: SettingModel
  loadingStatus: LoadingStatus = LoadingStatus.OFF

  private constructor() {
  }

  public static getInstance(): SettingModel {
    if (!SettingModel.instance) {
      SettingModel.instance = new SettingModel()
    }
    return SettingModel.instance
  }

  //获取数据库下载的题库
  public async getBankList(): Promise<BankListRes[]> {
    let bankResultList = await questionBankTable.querySync(0) ?? [];

    Logger.info(TAG, '下载的题库--------' + bankResultList.length)
    return bankResultList
  }
}