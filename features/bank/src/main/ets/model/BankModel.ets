import { BankNet } from '../service/BankNet'
import { BankCategory } from './BankCategory'
import TikuRes from './TikuRes'

const TAG = '[BankModel]'

@Observed
export class BankModel {
  private funNetwork: BankNet
  private static instance: BankModel

  // loadingStatus: LoadingStatus = LoadingStatus.OFF
  // private sp: preferences.Preferences | null = null


  private constructor() {
    this.funNetwork = new BankNet()
  }

  public static getInstance(): BankModel {
    if (!BankModel.instance) {
      BankModel.instance = new BankModel()
    }
    return BankModel.instance
  }

  //获取题库tab类型目录列表
  public async getBankTypeList(): Promise<BankCategory[]> {
    try {
      let data = await this.funNetwork.getBankTypeList()
      return data
    } catch (e) {
      return []
    }
  }

  //获取题库列表详情
  public async getBankList(aid: string, pageSize: number, pageNo: number): Promise<TikuRes[]> {
    try {
      let data = await this.funNetwork.getBankList(aid, pageSize, pageNo)
      return data
    } catch (e) {
      return []
    }
  }
}