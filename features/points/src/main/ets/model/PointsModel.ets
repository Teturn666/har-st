import { Logger } from 'utils'
import { PointsNet } from '../service/PointsNet'
import CheckDataRes, { PointEventRes } from './CheckDataRes'
import { ExchangeRes } from './ExchangeRes'
import { promptAction } from '@kit.ArkUI'

const TAG = '[PointsModel]'


@Observed
export class PointsModel {
  private PointsNet: PointsNet
  private static instance: PointsModel

  private constructor() {
    this.PointsNet = new PointsNet()
  }

  public static getInstance(): PointsModel {
    if (!PointsModel.instance) {
      PointsModel.instance = new PointsModel()
    }
    return PointsModel.instance
  }


  //获取签到积分list
  public async getSignMapList(): Promise<CheckDataRes[]> {
    try {
      let data = await this.PointsNet.getListSignMap(false)
      // Logger.info(TAG, '返回数据--------' + data)
      return data
    } catch (e) {
      Logger.info(TAG, 'err--------' + e)
      return []
    }
  }

  //获取连续签到天数
  public async getSignState(): Promise<number> {
    try {
      let data = await this.PointsNet.getSignState()
      // Logger.info(TAG, '返回数据--------' + data)
      return data
    } catch (e) {
      Logger.info(TAG, 'err--------' + e)
      return 2
    }
  }

  //获取总积分
  public async getMyNumb(): Promise<string> {
    try {
      let data = await this.PointsNet.getMyNumb()
      Logger.info(TAG, '返回数据--------' + data)
      return String(data)
    } catch (e) {
      Logger.info(TAG, 'err--------' + e)
      return 'wrong'
    }
  }

  //今日签到
  public async getTodayPoint(): Promise<boolean> {
    try {
      let data = await this.PointsNet.getSigningPoint()
      // Logger.info(TAG, '返回数据--------' + data)
      if (data == 0) {
        return true
      } else {
        return false
      }
    } catch (e) {
      Logger.info(TAG, 'err--------' + e)
      return false
    }
  }

  // 历史细节
  public async getHistoryPoint(): Promise<PointEventRes[]> {
    try {
      let data = await this.PointsNet.getHistoryPointDetail()
      // Logger.info(TAG, '返回数据--------' + data)
      return data
    } catch (e) {
      Logger.info(TAG, 'err--------' + e)
      return []
    }
  }

  // 历史增长细节
  public async getHistoryPsIncrease(): Promise<PointEventRes[]> {
    try {
      let data = await this.PointsNet.getHistoryPointIncrease()
      // Logger.info(TAG, '返回数据--------' + data)
      return data
    } catch (e) {
      Logger.info(TAG, 'err--------' + e)
      return []
    }
  }

  // 历史消耗细节
  public async getHistoryPsConsumer(): Promise<PointEventRes[]> {
    try {
      let data = await this.PointsNet.getHistoryPointConsumer()
      // Logger.info(TAG, '返回数据--------' + data)
      return data
    } catch (e) {
      Logger.info(TAG, 'err--------' + e)
      return []
    }
  }

  // 邀请记录
  public async getMyPeople(): Promise<PointEventRes[]> {
    try {
      let data = await this.PointsNet.getMyInvitePeople()
      // Logger.info(TAG, '返回数据--------' + data)
      return data
    } catch (e) {
      Logger.info(TAG, 'err--------' + e)
      return []
    }
  }

  // 我的邀请码
  public async getMyCode(): Promise<string> {
    try {
      let data = await this.PointsNet.getMyInviteCode()
      // Logger.info(TAG, '返回数据--------' + data)
      return data
    } catch (e) {
      Logger.info(TAG, 'err--------' + e)
      return ''
    }
  }

  // 被绑定邀请码是什么
  public async getBoundCode(): Promise<string> {
    try {
      let data = await this.PointsNet.getBoundCode()
      // Logger.info(TAG, '返回数据--------' + data)
      return data
    } catch (e) {
      Logger.info(TAG, 'err--------' + e)
      return ''
    }
  }

  // 绑定邀请码action
  public async submitBoundCode(code: string): Promise<string> {
    try {
      let data = await this.PointsNet.submitBoundCode(code)
      // Logger.info(TAG, '返回数据--------' + data)
      if (data == null) {
        return "绑定失败，请检查邀请码是否正确"
      }
      return data
    } catch (e) {
      Logger.info(TAG, 'err--------' + e)
      return ''
    }
  }

  //获取积分兑换列表
  public async getExchangeList(): Promise<ExchangeRes[]> {
    try {
      let data = await this.PointsNet.getExchangeList()
      return data
    } catch (e) {
      Logger.info(TAG, 'err--------' + e)
      return []
    }
  }

  //积分兑换
  public async getExchangeVip(id: string): Promise<string> {
    try {
      const data = await this.PointsNet.getExchangeVip(id)
      return data
    } catch (e) {
      if (e === '积分不足' || e?.toString().includes('积分不足')) {
        promptAction.showToast({ message: '积分不足，无法兑换会员', duration: 2000 })
      } else {
        Logger.info(TAG, '兑换失败: ' + e)
      }
      return ''
    }
  }

  //查询还有多少次看广告的机会 /m/point/ad/count
  public async getAdCount(): Promise<string> {
    try {
      let data = await this.PointsNet.getAdCount()
      return data
    } catch (e) {
      Logger.info(TAG, 'err--------' + e)
      return ''
    }
  }

  //看广告领积分 /m/point/ad
  public async getAdPoint(): Promise<string> {
    try {
      let data = await this.PointsNet.getAdPoint()
      return data
    } catch (e) {
      Logger.info(TAG, 'err--------' + e)
      return ''
    }
  }

  //先判断是否还能跳转应用商店 /m/point/score/select
  public async getScoreSelect(): Promise<string> {
    try {
      let data = await this.PointsNet.getScoreSelect()
      return data
    } catch (e) {
      Logger.info(TAG, 'err--------' + e)
      return ''
    }
  }

  // 应用商店加分接口：/m/point/score/action
  public async getScoreAction(): Promise<string> {
    try {
      let data = await this.PointsNet.getScoreAction()
      return data
    } catch (e) {
      Logger.info(TAG, 'err--------' + e)
      return ''
    }
  }
}