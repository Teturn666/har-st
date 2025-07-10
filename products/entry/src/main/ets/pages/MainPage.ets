import { uniformTypeDescriptor as utd } from '@kit.ArkData';
import { HomePage } from 'home/Index';
import { CustomizedBankPage } from 'home/src/main/ets/pages/CustomizedBankPage'
import { BankPage } from 'bank/Index';
import { MinePage } from 'mine/Index';
import { CustomTabBar } from '../components/CustomTabBar';
import { AppConstants } from '../constants/AppConstants';
import { TabBarType } from '../model/TabBarModel';
import { common, Want, } from '@kit.AbilityKit';
import { init } from '@umeng/analytics';
import { MainModel } from '../model/MainModel';
import { preferencesUtils, PreferencesConstants, EmitterConstants, webType } from 'utils/Index'
import { BusinessError,emitter } from '@kit.BasicServicesKit';
import { splashAd } from '../utils/SplashAd';
import { ConfigRes } from 'utils/src/main/ets/model/ConfigRes';
import { HmAdInfo } from 'utils/src/main/ets/model/HmAdInfo';
import { Customized } from 'home/src/main/ets/model/NavGenericType';
import HomeConstants from 'home/src/main/ets/Constants/HomeConstants';

import { UpdateRes } from 'home/src/main/ets/model/UpdateRes';
import { HomeNet } from 'home/src/main/ets/service/HomeNet'
import { hilog } from '@kit.PerformanceAnalysisKit';
import { systemShare } from '@kit.ShareKit';
import MineConstants from 'mine/src/main/ets/Constants/MineConstants';

const context = (getContext(this) as common.UIAbilityContext)

@Entry
@Component
struct MainPage {
  @LocalStorageLink('mainTabIndex') currentIndex: TabBarType = TabBarType.HOME;
  @Provide appPathStack: NavPathStack = new NavPathStack();
  @State showDialog: boolean = false
  @State mainModel: MainModel = MainModel.getInstance()
  @State isShow: boolean = false
  @State timer: number = 0
  @State CsjCode: number = 0
  @State configRes: ConfigRes = new ConfigRes()
  @State isVip: number = 0
  @State CsjHmAD: ConfigRes = {
    hmAd: new HmAdInfo()
  }
  @StorageProp("isCustomizedBankPage") want: boolean = false
  @State HomeNet: HomeNet = new HomeNet()
  @State vipTime: string = ''
  @State vipRemainingDays: number = 0
  // 添加一个统一的弹窗显示标识
  @State hasShownDialogToday: boolean = false
  // 添加升级相关状态
  @State updateInfo: UpdateRes | null = null
  @State needUpdate: boolean = false

  //优先级：升级 > 公告 > 会员提醒 > 分享
  checkAndShowDialogs(): void {
    if (this.hasShownAnyDialogToday()) {
      console.log('今天已经显示过弹窗，跳过所有弹窗检查')
      return
    }
    // 优先级1：升级弹窗（最高优先级，强制升级时不受日期限制）
    if (this.shouldShowUpdateDialog()) {
      console.log('显示升级弹窗（优先级1 - 最高）')
      this.showUpdateDialog()
      // 强制升级时不标记今天已显示，允许一直显示
      if (!this.updateInfo?.forceUpdate) {
        this.markAnyDialogShownToday()
      }
      return
    }

    if (this.shouldShowNoticeDialog()) {
      console.log('显示公告弹窗（优先级2）')
      this.showNoticeDialog()
      this.markAnyDialogShownToday()
      return
    }

    if (this.shouldShowVipExpireDialog()) {
      console.log('显示会员提醒弹窗（优先级3）')
      this.showVipExpireReminder()
      this.markAnyDialogShownToday()
      return
    }

    if (this.shouldShowShareDialog()) {
      console.log('显示分享弹窗（优先级4）')
      this.showShareDialog()
      this.markAnyDialogShownToday()
      return
    }

    console.log('今天无需显示任何弹窗')
  }

  //检查今天是否已经显示过任何弹窗
  hasShownAnyDialogToday(): boolean {
    const today = new Date().toDateString()
    const lastShownDate = preferencesUtils.getString(PreferencesConstants.SP_ANY_DIALOG_SHOWN_TODAY)
    const hasShown = lastShownDate === today
    console.log(`检查今天是否已显示任何弹窗: ${hasShown}, 今天: ${today}, 上次显示: ${lastShownDate}`)
    return hasShown
  }

  //标记今天已显示任何弹窗
  markAnyDialogShownToday(): void {
    const today = new Date().toDateString()
    preferencesUtils.putString(PreferencesConstants.SP_ANY_DIALOG_SHOWN_TODAY, today)
    console.log(`标记今天已显示弹窗: ${today}`)
    this.hasShownDialogToday = true
  }

  //升级弹窗
  shouldShowUpdateDialog(): boolean {
    if (!this.updateInfo) {
      console.log('没有升级信息，不显示升级弹窗')
      return false
    }

    const shouldShow = this.checkNeedUpdate(this.updateInfo)
    return shouldShow
  }

  showUpdateDialog(): void {
    if (!this.updateInfo) {
      return
    }

    setTimeout(() => {
      this.updateDialogController = new CustomDialogController({
        builder: UpdateDialog({
          ClickEvent: this.jumpToApplication,
          isForceUpdate: this.updateInfo!.forceUpdate,
        }),
        customStyle: true,
        alignment: DialogAlignment.Center,
        offset: { dx: 0, dy: 0 },
        maskColor: 0x33000000,
        autoCancel: !this.updateInfo!.forceUpdate, // 强制更新时不能点击遮罩关闭
        cancel: () => {
          console.log('升级弹窗被取消')
        }
      })
      this.updateDialogController.open()
    }, 500) // 比其他弹窗更早显示
  }


  //公告弹窗
  shouldShowNoticeDialog(): boolean {
    // 检查是否有公告内容
    if (!this.CsjHmAD?.hmAd?.board?.desc) {
      console.log('没有公告内容，不显示公告弹窗')
      return false
    }

    let flag = this.CsjHmAD?.hmAd?.board?.flag || 0
    console.log(`公告弹窗flag: ${flag}`)

    if (flag === 0) {
      // flag=0 表示一直弹
      console.log('flag=0，需要显示公告弹窗')
      return true
    } else if (flag > 0) {
      // flag>0 表示按天数间隔弹窗
      const shouldShow = this.shouldShowNoticeByInterval(flag)
      // 记录本次显示时间
      this.markNoticeShown()
      console.log(`按${flag}天间隔，${shouldShow ? '需要' : '不需要'}显示公告弹窗`)
      return shouldShow
    }

    return false
  }


  //显示VIP到期提醒弹窗
  shouldShowVipExpireDialog(): boolean {
    if (!this.isVip) {
      console.log('用户不是VIP，不显示VIP提醒')
      return false
    }

    this.vipRemainingDays = this.calculateVipRemainingDays()
    if (this.vipRemainingDays === -1) {
      console.log('VIP时间计算失败，不显示VIP提醒')
      return false
    }

    console.log(`VIP剩余天数: ${this.vipRemainingDays}`)

    // 需要提醒的天数：0（今日到期）、1、2、5
    const reminderDays = [0, 1, 2, 5]
    const shouldShow = reminderDays.includes(this.vipRemainingDays)

    console.log(`${shouldShow ? '需要' : '不需要'}显示VIP提醒弹窗`)
    return shouldShow
  }

  //分享弹窗
  shouldShowShareDialog(): boolean {
    // 检查是否有分享内容
    if (!this.CsjHmAD?.hmAd?.share?.poptext) {
      console.log('没有分享内容，不显示分享弹窗')
      return false
    }

    const popday = this.CsjHmAD?.hmAd?.share?.popday || 0
    console.log(`分享弹窗popday: ${popday}`)

    if (popday === 0) {
      // popday=0 表示一直弹
      console.log('popday=0，需要显示分享弹窗')
      return true
    } else if (popday > 0) {
      // popday>0 表示按天数间隔弹窗
      const shouldShow = this.shouldShowShareByInterval(popday)
      console.log(`按${popday}天间隔，${shouldShow ? '需要' : '不需要'}显示分享弹窗`)
      return shouldShow
    }

    return false
  }


  showNoticeDialog(): void {
    // 延迟显示，确保其他初始化完成
    setTimeout(() => {
      this.dialogController.open()
      // 记录具体的公告显示时间（用于间隔计算）
      if (this.CsjHmAD?.hmAd?.board?.flag > 0) {
        this.markNoticeShown()
      }
    }, 1000)
  }

  showVipExpireReminder(): void {
    setTimeout(() => {
      if (this.vipRemainingDays === 0) {
        this.memberExpireDialog.open()
      } else {
        this.vipExpireDialog.open()
      }
    }, 1000)
  }

  showShareDialog(): void {
    // 延迟显示，确保其他初始化完成
    setTimeout(() => {
      this.dialogControllers.open()
      // 记录具体的分享显示时间（用于间隔计算）
      if (this.CsjHmAD?.hmAd?.share?.popday > 0) {
        this.markShareShown()
      }
    }, 1500)
  }

  //检查是否应该按间隔显示公告
  shouldShowNoticeByInterval(intervalDays: number): boolean {
    const lastShownDate = preferencesUtils.getString(PreferencesConstants.SP_NOTICE_LAST_SHOWN_DATE)
    if (!lastShownDate) {
      // 如果没有记录，说明是第一次，应该显示
      return true
    }

    try {
      const lastShown = new Date(lastShownDate)
      const now = new Date()

      // 计算距离上次显示的天数
      const diffTime = now.getTime() - lastShown.getTime()
      const diffDays = Math.floor(diffTime / (1000 * 60 * 60 * 24))

      console.log(`距离上次显示公告已过去${diffDays}天，间隔要求${intervalDays}天`)

      // 如果超过间隔天数，则应该显示
      return diffDays >= intervalDays
    } catch (error) {
      console.error('解析上次显示公告时间失败:', error)
      // 解析失败则显示公告
      return true
    }
  }

  //记录公告显示时间（用于间隔天数计算）
  markNoticeShown(): void {
    const now = new Date().toISOString()
    preferencesUtils.putString(PreferencesConstants.SP_NOTICE_LAST_SHOWN_DATE, now)
    console.log(`记录公告显示时间: ${now}`)
  }


  //检查是否应该按间隔显示分享弹窗
  shouldShowShareByInterval(intervalDays: number): boolean {
    const lastShownDate = preferencesUtils.getString(PreferencesConstants.SP_SHARE_LAST_SHOWN_DATE)

    if (!lastShownDate) {
      // 如果没有记录，说明是第一次，应该显示
      return true
    }

    try {
      const lastShown = new Date(lastShownDate)
      const now = new Date()

      // 计算距离上次显示的天数
      const diffTime = now.getTime() - lastShown.getTime()
      const diffDays = Math.floor(diffTime / (1000 * 60 * 60 * 24))

      console.log(`距离上次显示分享弹窗已过去${diffDays}天，间隔要求${intervalDays}天`)

      // 如果超过间隔天数，则应该显示
      return diffDays >= intervalDays
    } catch (error) {
      console.error('解析上次显示分享弹窗时间失败:', error)
      // 解析失败则显示弹窗
      return true
    }
  }

  markShareShown(): void {
    const now = new Date().toISOString()
    preferencesUtils.putString(PreferencesConstants.SP_SHARE_LAST_SHOWN_DATE, now)
    console.log(`记录分享弹窗显示时间: ${now}`)
  }

  //计算VIP剩余天数
  calculateVipRemainingDays(): number {
    if (!this.vipTime) {
      return -1
    }
    try {
      // 假设vipTime格式为 "2024-12-31"
      let expireDate: Date
      if (this.vipTime.includes('-')) {
        // 日期格式
        expireDate = new Date(this.vipTime)
      } else {
        // 时间戳格式
        expireDate = new Date(parseInt(this.vipTime))
      }
      const today = new Date()
      today.setHours(0, 0, 0, 0) // 设置为当天0点
      const expireDateTime = new Date(expireDate)
      expireDateTime.setHours(0, 0, 0, 0) // 设置为到期日0点
      const diffTime = expireDateTime.getTime() - today.getTime()
      const diffDays = Math.ceil(diffTime / (1000 * 60 * 60 * 24))
      return Math.max(0, diffDays) // 确保不返回负数
    } catch (error) {
      console.error('计算VIP剩余天数失败:', error)
      return -1
    }
  }

  dialogController: CustomDialogController = new CustomDialogController({
    builder: ImportantNoticeDialog({
      noticeContent: this.CsjHmAD?.hmAd?.board.desc
    }),
    autoCancel: false,
    alignment: DialogAlignment.Center,
    customStyle: true,
    backgroundColor: '#80000000'
  })
  dialogControllers: CustomDialogController = new CustomDialogController({
    builder: ShareDialog({
      noticeContent: this.CsjHmAD?.hmAd?.share.poptext,
      onCancel: () => {
        console.log('用户点击了取消')
      },
      onConfirm: () => {
        console.log('用户点击了确定')
        this.share()
      }
    }),
    alignment: DialogAlignment.Center,
    customStyle: true,
    autoCancel: true,
    cancel: () => {
      console.log('点击遮罩关闭弹窗')
    }
  })

  private async share() {
    let shareData: systemShare.SharedData = new systemShare.SharedData({
      utd: utd.UniformDataType.TEXT,
      content: '我正在使用快搜答题神器，支持各类答题平台，快来一起轻松答题吧!官方下载链接:' + MineConstants.APP_STORE_URL,
      title: '快搜搜题',
      description: '我正在使用快搜答题神器，支持各类答题平台，快来一起轻松答题吧！',
      thumbnail: new Uint8Array()
    });

    let controller: systemShare.ShareController = new systemShare.ShareController(shareData);
    let context = getContext(this) as common.UIAbilityContext;
    controller.show(context, {
      selectionMode: systemShare.SelectionMode.SINGLE,
      previewMode: systemShare.SharePreviewMode.DEFAULT,
    }).then(() => {

    }).catch((error: BusinessError) => {

    });
  }

  // 会员今日到期弹窗
  memberExpireDialog: CustomDialogController = new CustomDialogController({
    builder: VipNoticeDialog({
      content: '您的VIP会员今日到期，到期后您将无法享受免费广告提醒等权益。',
      buttonText: '去续费',
      onButtonClick: () => {
        console.log('用户点击了去续费')
        this.goToRenewVip()
      }
    }),
    autoCancel: true,
    alignment: DialogAlignment.Center,
    customStyle: true,
    backgroundColor: '#80000000'
  })
  // VIP剩余天数提醒弹窗
  vipExpireDialog: CustomDialogController = new CustomDialogController({
    builder: VipNoticeDialog({
      content: this.getVipReminderContent(),
      buttonText: '我知道了',
      onButtonClick: () => {
        console.log(`VIP剩余${this.vipRemainingDays}天，用户点击了${this.vipRemainingDays === 0 ? '去续费' :
          '我知道了'}`)
      }
    }),
    autoCancel: true,
    alignment: DialogAlignment.Center,
    customStyle: true,
    backgroundColor: '#80000000'
  })

  goToRenewVip(): void {
    this.appPathStack.pushPathByName(MineConstants.ROUTER_VIP,null)

  }

  //获取VIP提醒内容
  getVipReminderContent(): string {
    if (this.vipRemainingDays === 0) {
      return '您的VIP会员今日到期，到期后您将无法享受免费广告提醒等权益。'
    } else if (this.vipRemainingDays === 1) {
      return '您的VIP会员有效期剩余1天，请及时充值，继续享会员权益。'
    } else if (this.vipRemainingDays === 2) {
      return '您的VIP会员有效期剩余2天，请及时充值，继续享会员权益。'
    } else if (this.vipRemainingDays === 5) {
      return '您的VIP会员有效期剩余5天，请及时充值，继续享会员权益。'
    }
    return '您的VIP会员即将到期，请及时续费。'
  }

  // 弹出框控制器
  updateDialogController: CustomDialogController = new CustomDialogController({
    builder: UpdateDialog({
      // 可以传入更新信息
      ClickEvent: this.jumpToApplication,
      isForceUpdate: false,
    }),
    customStyle: true, // 使用自定义样式
    alignment: DialogAlignment.Center, // 居中显示
    offset: { dx: 0, dy: 0 },
    maskColor: 0x33000000, // 半透明遮罩
    autoCancel: false, // 点击遮罩不自动关闭
    cancel: () => {
      console.log('弹出框被取消')
    }
  })

  jumpToApplication() {
    let link = `store://appgallery.huawei.com/app/detail?id=com.chznai.ikst`
    let want: Want = {
      action: 'ohos.want.action.appdetail',
      uri: link,
    };
    let context = getContext(this) as common.UIAbilityContext
    context.startAbility(want).then(async () => {
      hilog.info(0x0001, 'TAG', "Succeeded in starting Ability successfully.")

    }).catch((error: BusinessError) => {
      hilog.error(0x0001, 'TAG', `Failed to startAbility.Code: ${error.code}, message is ${error.message}`);
    });
  }

  //比较两个版本号
  compare(version1: string, version2: string): number {
    const v1Parts = version1.split('.').map(Number);
    const v2Parts = version2.split('.').map(Number);
    const maxLength = Math.max(v1Parts.length, v2Parts.length);

    for (let i = 0; i < maxLength; i++) {
      const v1 = v1Parts[i] || 0;
      const v2 = v2Parts[i] || 0;

      if (v1 < v2) {
        return -1;
      }
      if (v1 > v2) {
        return 1;
      }
    }
    return 0;
  }

  checkNeedUpdate(updateRes: UpdateRes): boolean {
    const currentVersion = updateRes.clientVersion;
    // 强制更新：当前版本 < 最小版本
    if (updateRes.forceUpdate &&
      this.compare(currentVersion, updateRes.minVersion) < 0) {
      return true;
    }

    // 建议更新：当前版本 < 最大版本
    if (updateRes.adviceUpdate &&
      this.compare(currentVersion, updateRes.maxVersion) < 0) {
      return true;
    }

    return false;
  }

  handleUpdate(updateRes: UpdateRes): void {
    if (this.checkNeedUpdate(updateRes)) {
      this.updateDialogController = new CustomDialogController({
        builder: UpdateDialog({
          ClickEvent: this.jumpToApplication,
          isForceUpdate: updateRes.forceUpdate,
        }),
        customStyle: true,
        alignment: DialogAlignment.Center,
        offset: { dx: 0, dy: 0 },
        maskColor: 0x33000000,
        autoCancel: !updateRes.forceUpdate, // 强制更新时不能点击遮罩关闭
        cancel: () => {

        }
      });
      // 需要升级，调用跳转方法
      this.updateDialogController.open();
    } else {
      console.log('当前版本无需更新');
    }
  }


  //获取并检查升级信息
  private async fetchAndCheckUpdate(): Promise<void> {
    try {
      // 升级死数据
      const updateRes: UpdateRes = {
        adviceUpdate: true,
        forceUpdate: false,
        clientVersion: '1.2.0',
        defaultUrl: 'store://xxx',
        maxVersion: '1.2.0',
        minVersion: '1.1.0',
        urlMode: 'store',
        hintText: '发现新版本'
      };

      // 存储升级信息，不直接显示弹窗
      this.updateInfo = updateRes;
      this.needUpdate = this.checkNeedUpdate(updateRes);

      console.log('升级信息获取完成:', this.updateInfo);
      console.log('是否需要升级:', this.needUpdate);

    } catch (error) {
      console.error('获取升级信息失败:', error);
      this.updateInfo = null;
      this.needUpdate = false;
    }
  }

  private initPreferences() {
    //初始化sp实例
    preferencesUtils.setContext(context)
    this.showDialog = preferencesUtils.getBoolean(PreferencesConstants.SP_IS_FIRST_INSTALL, true)
  }

  // 修改布尔值的方法
  updateBooleanValue(newValue: boolean) {
    preferencesUtils.putBoolean(PreferencesConstants.SP_IS_FIRST_INSTALL, newValue)
  }

  aboutToAppear(): void {
    AppStorage.setOrCreate("PathStack", this.appPathStack)
    splashAd.ctx = this.getUIContext()
    this.initPreferences()
    this.mainModel.initDb()
    this.CsjHmAD = preferencesUtils.getGenerics(PreferencesConstants.CSJ_AD_PARAMS);
    this.isVip = preferencesUtils.getNumber(PreferencesConstants.SP_IS_VIP);
    this.CsjCode = preferencesUtils.getNumber(PreferencesConstants.CSJ_AD_CODE)
    this.getCSJ()
    this.ShowSplash()

    //获取vip到期时间
    this.vipTime = preferencesUtils.getString(PreferencesConstants.SP_VIP_TIME)

    // 先获取升级信息
    this.fetchAndCheckUpdate().then(() => {
      // 升级信息获取完成后，延迟执行统一弹窗检查
      setTimeout(() => {
        this.checkAndShowDialogs()
      }, 2000)
    })
  }

  onPageShow(): void {
    if (this.want) {
      this.navCustomized()
    }

  }

  navCustomized() {
    this.appPathStack.pushDestination(new NavPathInfo(HomeConstants.ROUTER_CUSTOMIZED_BANK_PAGE,
      { isShow: false } as Customized));
  }

  async getCSJ() {
    await MainModel.getInstance().getConfigList()

  }

  ShowSplash() {
    if (this.CsjHmAD?.hmAd?.splash?.switchOff && !this.CsjCode && !this.isVip) {
      this.timer = setTimeout(() => {
        splashAd.ShowSplash((ids: boolean) => {
          this.isShow = ids
        })
      })
    } else {
      this.isShow = true
    }
  }

  onPageHide(): void {
    clearTimeout(this.timer)
  }

  build() {
    if (!!this.isVip || this.isShow) {
      RelativeContainer() {
        Navigation(this.appPathStack) {
          Flex({
            direction: FlexDirection.Column,
          }) {
            Tabs({ index: this.currentIndex }) {
              TabContent() {
                HomePage()
              }

              TabContent() {
                BankPage()
              }

              TabContent() {

                MinePage()
              }
            }
            .layoutWeight(1)
            .barHeight(0)
            .scrollable(false)
            .onChange((index) => {
              this.currentIndex = index
              if (index === TabBarType.HOME) {
                emitter.emit(EmitterConstants.EM_REFRESH_HOME)
              } else if (index === TabBarType.BANK) {
                emitter.emit(EmitterConstants.EM_REFRESH_BANK)
              }
            })

            CustomTabBar({ currentIndex: $currentIndex })
          }
          .width(AppConstants.FULL_PERCENT)
          .height(AppConstants.FULL_PERCENT)
          .backgroundColor($r('app.color.start_window_background'))
        }
        .hideTitleBar(true)
        .navDestination(this.navMap)
        .mode(NavigationMode.Stack)

        if (this.showDialog) {
          Column() {
            Blank()
            Column() {
              Row() {
                Text("用户协议").fontColor($r('app.color.c_f75a23'))
                  .fontSize(18).onClick(() => {
                  this.showDialog = false
                  this.appPathStack.pushPathByName("webPage", {
                    url: "https://ti.iksdt.com/static/doc/yhxy.html",
                    title: "用户协议",
                    page: 'mainPage'
                  } as webType, (popInfo: PopInfo) => {
                    this.showDialog = popInfo.result as boolean
                  })
                }).margin({ left: 12 })
                Text("和").fontColor($r('app.color.c_3e3e3e'))
                  .fontSize(18)
                Text("隐私政策").fontColor($r('app.color.c_f75a23'))
                  .fontSize(18).onClick(() => {
                  this.showDialog = false
                  this.appPathStack.pushPathByName("webPage", {
                    url: "https://ti.iksdt.com/static/doc/yszc.html",
                    title: "隐私政策",
                    page: 'mainPage'
                  } as webType, (popInfo: PopInfo) => {
                    this.showDialog = popInfo.result as boolean
                  })
                })
                Blank()
              }.width('100%').margin({ top: 32 })

              Row() {
                Text($r('app.string.privacy_hint'))
                  .fontColor($r('app.color.c_8a8a8a'))
                  .fontSize(14)
                  .padding({ left: 12, right: 12 })
              }.width('100%')

              Row() {
                Blank()
                Text("不同意并退出")
                  .fontColor($r('app.color.c_b1844e'))
                  .fontSize(12)
                  .width('40%')
                  .height(80)
                  .textAlign(TextAlign.Center)
                  .onClick(() => {
                    context.terminateSelf()
                  })
                Blank()
                Text("同意并继续")
                  .fontColor($r('app.color.c_2a5089'))
                  .fontSize(12)
                  .width('40%')
                  .height(80)
                  .textAlign(TextAlign.Center)
                  .onClick(() => {
                    this.showDialog = false
                    this.updateBooleanValue(false)
                    init(); // 在用户同意隐私政策后再调用此方法
                    // onEventObject("eventA", {
                    //   "key": "value"
                    // }); // 埋个点
                  })
                Blank()
              }.width('100%')
            }.width('90%').linearGradient({
              colors: [
                [$r("app.color.c_f6eee3"), 0.0],
                [$r("app.color.c_f4f3fb"), 0.5],
                [$r("app.color.start_window_background"), 1],
              ]
            }).borderRadius(5)

            Blank()
          }.width('100%').height('100%').backgroundColor($r('app.color.c_99000000'))
        }

      }
    } else {
      Image($r('app.media.block_img'))
        .width('100%')
        .height('100%')
        .expandSafeArea()
    }
  }

  @Builder
  navMap(name: string) {
    if (name === HomeConstants.ROUTER_CUSTOMIZED_BANK_PAGE) {
      CustomizedBankPage()
    }
  }
}

@Builder
function MainPageBuilder() {
  MainPage()
}


//我要分享
@CustomDialog
export struct ShareDialog {
  controller: CustomDialogController
  onCancel?: () => void
  onConfirm?: () => void
  noticeContent: string = ''

  build() {
    Column() {
      // 标题
      Text('我要分享')
        .fontSize(18)
        .fontWeight(FontWeight.Medium)
        .fontColor('#333333')
        .margin({
          top: 24,
          bottom: 16
        })

      // 内容文本
      Text(this.noticeContent)
        .fontSize(14)
        .fontColor('#666666')
        .lineHeight(20)
        .textAlign(TextAlign.Center)
        .margin({
          left: 24,
          right: 24,
          bottom: 24
        })

      // 分割线
      Divider()
        .color('#F0F0F0')
        .strokeWidth(1)

      // 按钮区域
      Row() {
        // 取消按钮
        Text('取消')
          .fontSize(16)
          .fontColor('#999999')
          .width('50%')
          .height(48)
          .textAlign(TextAlign.Center)
          .onClick(() => {
            this.controller.close()
            this.onCancel?.()
          })

        // 垂直分割线
        Line()
          .width(1)
          .height(48)
          .backgroundColor('#F0F0F0')

        // 确定按钮
        Text('确定')
          .fontSize(16)
          .fontColor('#007AFF')
          .fontWeight(FontWeight.Medium)
          .width('50%')
          .height(48)
          .textAlign(TextAlign.Center)
          .onClick(() => {
            this.controller.close()
            this.onConfirm?.()
          })
      }
      .alignItems(VerticalAlign.Center)
    }
    .backgroundColor(Color.White)
    .borderRadius(12)
    .width(280)
    .alignItems(HorizontalAlign.Center)
  }
}

//公告
@CustomDialog
struct ImportantNoticeDialog {
  controller: CustomDialogController
  @State countDown: number = 5
  @State isButtonEnabled: boolean = false
  private timer: number = -1
  noticeContent: string = ''

  aboutToAppear() {
    // 开始倒计时
    this.startCountDown()
  }

  aboutToDisappear() {
    // 清除定时器
    if (this.timer !== -1) {
      clearInterval(this.timer)
    }
  }

  startCountDown() {
    this.timer = setInterval(() => {
      this.countDown--
      if (this.countDown <= 0) {
        this.isButtonEnabled = true
        clearInterval(this.timer)
        this.timer = -1
      }
    }, 1000)
  }

  build() {
    Column() {
      // 标题
      Text('重要公告')
        .fontSize(18)
        .fontWeight(FontWeight.Bold)
        .fontColor(Color.Black)
        .margin({ top: 20, bottom: 15 })

      // 内容区域
      Scroll() {
        Column() {
          Text(this.noticeContent)
            .fontSize(14)
            .fontColor('#666666')
            .lineHeight(20)
            .padding({ left: 20, right: 20 })
        }
      }
      .height('auto')
      .width('100%')
      .scrollBar(BarState.Auto)

      // 按钮
      Button(this.isButtonEnabled ? '我知道了' : `我知道了 (${this.countDown}s)`)
        .width('90%')
        .height(45)
        .fontSize(16)
        .fontColor(Color.White)
        .backgroundColor(this.isButtonEnabled ? '#FF7043' : '#CCCCCC')
        .borderRadius(8)
        .margin({ top: 20, bottom: 20 })
        .enabled(this.isButtonEnabled)
        .onClick(() => {
          if (this.isButtonEnabled) {
            this.controller.close()
          }
        })
    }
    .width(300)
    .backgroundColor(Color.White)
    .borderRadius(12)
    .shadow({
      radius: 20,
      color: '#33000000',
      offsetX: 0,
      offsetY: 4
    })
  }
}

//会员到期提醒
@CustomDialog
struct VipNoticeDialog {
  controller: CustomDialogController
  @Prop content: string = ''
  @Prop buttonText: string = ''
  @Prop isToday: boolean = false // 是否今日到期
  onButtonClick?: () => void

  build() {
    Stack() {
      Column() {

        // 标题和关闭按钮
        Row() {
          Text('温馨提示')
            .fontSize(16)
            .fontWeight(FontWeight.Medium)
            .fontColor('#333333')

          Blank()

          // 关闭按钮
          Image($r('sys.symbol.xmark'))
            .width(16)
            .height(16)
            .fillColor('#999999')
            .onClick(() => {
              this.controller.close()
            })
        }
        .width('100%')
        .padding({ top: 16, left: 16, right: 16 })

        // 内容区域
        Text(this.content)
          .fontSize(14)
          .fontColor('#666666')
          .lineHeight(22)
          .textAlign(TextAlign.Start)
          .padding({
            left: 16,
            right: 16,
            top: 12,
            bottom: 20
          })
          .width('100%')

        // 按钮区域
        Row() {
          // 普通提醒 - 只显示一个按钮
          Button(this.buttonText)
            .fontSize(14)
            .fontColor('#4A90E2')
            .backgroundColor(Color.Transparent)
            .border({ width: 1, color: '#4A90E2' })
            .borderRadius(20)
            .width('80%')
            .height(40)
            .onClick(() => {
              if (this.onButtonClick) {
                this.onButtonClick()
              }
              this.controller.close()
            })

        }
        .padding({ left: 20, right: 20, bottom: 20 })
      }
      .width(300)
      .backgroundColor(Color.White)
      .borderRadius(12)
      .shadow({
        radius: 16,
        color: '#1A000000',
        offsetX: 0,
        offsetY: 8
      })
    }
  }
}

// 升级
@CustomDialog
struct UpdateDialog {
  controller: CustomDialogController
  ClickEvent: () => void = () => {
  }
  @Prop isForceUpdate: boolean = false

  build() {
    Column() {
      Stack() {
        Image($r('app.media.ic_updatebg'))
          .objectFit(ImageFit.Contain)
          .width(282)
          .height(276)

        if (!this.isForceUpdate) {
          Row() {
            Image($r('app.media.ic_close'))
              .objectFit(ImageFit.Contain)
              .width(24)
              .height(24)
              .onClick(() => {
                this.controller.close()
              })
          }
          .margin({ right: 20, top: 20 })
        }

        Image($r('app.media.ic_experience'))
          .objectFit(ImageFit.Contain)
          .width(210)
          .height(48)
          .margin({ top: 180, right: 30 })
          .onClick(() => this.ClickEvent())
      }
      .alignContent(Alignment.TopEnd)
    }
    .backgroundColor(Color.Transparent) // 透明背景
  }
}