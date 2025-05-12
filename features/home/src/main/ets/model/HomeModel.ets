import { BankListRes, questionBankTable, questionTable } from 'db'
import { LoadingStatus, Logger } from 'utils/Index'

const TAG = '[HomeModel]'

@Observed
export class HomeModel {
  private static instance: HomeModel
  loadingStatus: LoadingStatus = LoadingStatus.OFF

  private constructor() {
  }

  public static getInstance(): HomeModel {
    if (!HomeModel.instance) {
      HomeModel.instance = new HomeModel()
    }
    return HomeModel.instance
  }

  //获取数据库已经下载的题库
  public async getBankList():
    Promise<BankListRes[]> {
    let bankResultList = await questionBankTable.querySync(0) ?? [];

    Logger.info(TAG, '下载的题库--------' + bankResultList.length)
    return bankResultList
  }
}