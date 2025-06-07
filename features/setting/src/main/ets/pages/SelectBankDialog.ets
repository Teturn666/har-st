import { promptAction } from '@kit.ArkUI';
import { preferencesUtils, PreferencesConstants } from 'utils/Index';
import { BankListRes } from 'db';

@CustomDialog
export struct selectBankDialog {
  controller?: CustomDialogController;
  @Prop bankList: BankListRes[];
  onConfirm: (selectedIds: string[], agreementChecked: boolean) => void = () => {
  };
  @State agreementChecked: boolean = false;
  @State allSelectedBankIds: string[] = [];
  @State customSelectedBankIds: string[] = [];
  @State downloadSelectedBankIds: string[] = [];
  @State isVip: boolean = false;

  private getDownloadBanks(): BankListRes[] {
    return this.bankList.filter(bank => bank.bankType === 0);
  }

  private getCustomBanks(): BankListRes[] {
    return this.bankList.filter(bank => bank.bankType === 2);
  }

  setDialogShow(newValue: boolean) {
    preferencesUtils.putBoolean(PreferencesConstants.SP_SELECT_DIALOG_SHOW, newValue)
  }

  aboutToAppear() {
    // 初始化默认选中所有题库
    this.allSelectedBankIds = this.bankList.map(bank => String(bank.id || ''));
    this.customSelectedBankIds = this.getCustomBanks().map(bank => String(bank.id || ''));
    this.downloadSelectedBankIds = this.getDownloadBanks().map(bank => String(bank.id || ''));
    this.isVip = this.getParentVipStatus();
  }

  private getParentVipStatus(): boolean {
    return this.isVip;
  }

  build() {
    Column({ space: 16 }) {
      // 顶部
      Row() {
        Text('题库选择')
          .fontSize(16)
          .width('100%')
          .fontColor($r('app.color.c_9d9d9d'))
          .textAlign(TextAlign.Center)
          .margin({ bottom: 8 })
        Blank()
        Image($r('app.media.ic_cha'))
          .width(16)
          .height(16)
          .onClick(() => this.controller?.close());
      }

      if (this.bankList.length > 0) {
        List({ space: 8 }) {
          // 顶部全选
          ListItem() {
            Row() {
              Checkbox({ name: 'checkbox1', group: 'checkboxGroup' })
                .select(
                  this.allSelectedBankIds.length === this.bankList.length &&
                    this.customSelectedBankIds.length === this.getCustomBanks().length &&
                    this.downloadSelectedBankIds.length === this.getDownloadBanks().length
                )
                .selectedColor(0xed6f21)
                .shape(CheckBoxShape.CIRCLE)
                .enabled(this.isVip)// 如果不是 VIP，则禁用
                .onChange((value: boolean) => {
                  // 全选：选中所有题库
                  const allBankIds = this.bankList.map(bank => String(bank.id || ''));
                  const customIds = this.getCustomBanks().map(bank => String(bank.id || ''));
                  const downloadIds = this.getDownloadBanks().map(bank => String(bank.id || ''));

                  if (value) {
                    this.allSelectedBankIds = Array.from(new Set([...this.allSelectedBankIds, ...allBankIds]));
                    this.customSelectedBankIds = Array.from(new Set([...this.customSelectedBankIds, ...customIds]));
                    this.downloadSelectedBankIds =
                      Array.from(new Set([...this.downloadSelectedBankIds, ...downloadIds]));
                  } else {
                    // 取消全选：清空所有选中
                    this.allSelectedBankIds = [];
                    this.customSelectedBankIds = [];
                    this.downloadSelectedBankIds = [];
                  }
                })
              Text("全选")
                .fontSize(14)
                .fontColor("#3e3e3e")
            }
          }
          .onClick((() => {
            if (!this.isVip) {
              promptAction.showToast({ message: '开通会员即可指定搜索题库', duration: 2000 });
              return; // 阻止状态更改
            }
          }))

          // 自定义题库
          if (this.getCustomBanks().length > 0) {
            ListItem() {
              Column() {
                Row() {
                  Checkbox({ name: 'customBanks', group: 'customGroup' })
                    .select(this.getCustomBanks()
                      .every(bank => this.customSelectedBankIds.includes(String(bank.id || ''))))
                    .selectedColor(0xed6f21)
                    .shape(CheckBoxShape.CIRCLE)
                    .enabled(this.isVip)// 如果不是 VIP，则禁用
                    .onChange((value: boolean) => {
                      const customIds = this.getCustomBanks().map(bank => String(bank.id || ''));
                      if (value) {
                        this.customSelectedBankIds = Array.from(new Set([...this.customSelectedBankIds, ...customIds]));
                      } else {
                        this.customSelectedBankIds = [];
                      }
                    })
                  Text("自定义题库")
                    .fontSize(14)
                    .fontColor("#3e3e3e")
                    .fontWeight(FontWeight.Bold)
                }
                .width('100%')
                .onClick((() => {
                  if (!this.isVip) {
                    promptAction.showToast({ message: '开通会员即可指定搜索题库', duration: 2000 });
                    return; // 阻止状态更改
                  }
                }))

                ForEach(this.getCustomBanks(), (bank: BankListRes) => {
                  ListItem() {
                    Row() {
                      Checkbox({ name: `custom_${bank.id}`, group: 'customGroup' })
                        .select(this.customSelectedBankIds.includes(String(bank.id || '')))
                        .selectedColor(0xed6f21)
                        .shape(CheckBoxShape.CIRCLE)
                        .enabled(this.isVip)
                        .onChange((value: boolean) => {
                          if (value) {
                            this.customSelectedBankIds = [...this.customSelectedBankIds, String(bank.id || '')];
                          } else {
                            this.customSelectedBankIds =
                              this.customSelectedBankIds.filter(id => id !== String(bank.id));
                          }
                        })
                      Text(bank.name || "未命名题库")
                        .fontSize(14)
                        .fontColor("#3e3e3e")
                        .maxLines(1)
                        .textOverflow({ overflow: TextOverflow.Ellipsis })
                    }
                    .width('100%')
                    .margin({ left: 30 })
                    .onClick((() => {
                      if (!this.isVip) {
                        promptAction.showToast({ message: '开通会员即可指定搜索题库', duration: 2000 });
                        return; // 阻止状态更改
                      }
                    }))
                  }
                })
              }.justifyContent(FlexAlign.Start)
            }.margin({ left: 18 })
          }

          // 我的下载
          if (this.getDownloadBanks().length > 0) {
            ListItem() {
              Column() {
                Row() {
                  Checkbox({ name: 'downloadBanks', group: 'downloadGroup' })
                    .select(this.getDownloadBanks()
                      .every(bank => this.downloadSelectedBankIds.includes(String(bank.id || ''))))
                    .selectedColor(0xed6f21)
                    .shape(CheckBoxShape.CIRCLE)
                    .enabled(this.isVip)// 如果不是 VIP，则禁用
                    .onChange((value: boolean) => {
                      const downloadIds = this.getDownloadBanks().map(bank => String(bank.id || ''));
                      if (value) {
                        this.downloadSelectedBankIds =
                          Array.from(new Set([...this.downloadSelectedBankIds, ...downloadIds]));
                      } else {
                        this.downloadSelectedBankIds = [];
                      }
                    })
                  Text("我的下载")
                    .fontSize(14)
                    .fontColor("#3e3e3e")
                    .fontWeight(FontWeight.Bold)
                }
                .width('100%')
                .onClick((() => {
                  if (!this.isVip) {
                    promptAction.showToast({ message: '开通会员即可指定搜索题库', duration: 2000 });
                    return; // 阻止状态更改
                  }
                }))
                ForEach(this.getDownloadBanks(), (bank: BankListRes) => {
                  ListItem() {
                    Row() {
                      Checkbox({ name: `download_${bank.id}`, group: 'downloadGroup' })
                        .select(this.downloadSelectedBankIds.includes(String(bank.id || '')))
                        .selectedColor(0xed6f21)
                        .shape(CheckBoxShape.CIRCLE)
                        .enabled(this.isVip)// 如果不是 VIP，则禁用
                        .onChange((value: boolean) => {
                          if (value) {
                            this.downloadSelectedBankIds = [...this.downloadSelectedBankIds, String(bank.id || '')];
                          } else {
                            this.downloadSelectedBankIds =
                              this.downloadSelectedBankIds.filter(id => id !== String(bank.id));
                          }
                        })
                      Text(bank.name || "未命名题库")
                        .fontSize(14)
                        .fontColor("#3e3e3e")
                        .maxLines(1)
                        .textOverflow({ overflow: TextOverflow.Ellipsis })
                    }
                    .width('100%')
                    .margin({ left: 30 })
                    .onClick((() => {
                      if (!this.isVip) {
                        promptAction.showToast({ message: '开通会员即可指定搜索题库', duration: 2000 });
                        return; // 阻止状态更改
                      }
                    }))
                  }
                })
              }.justifyContent(FlexAlign.Start)
            }.margin({ left: 18 })
          }
        }
        .width('100%')
        .height(160)
        .scrollBar(BarState.Auto)

        // 协议行
        Row() {
          Flex({ direction: FlexDirection.Row, wrap: FlexWrap.Wrap }) {
            Image(this.agreementChecked ? $r('app.media.ic_protocoled') : $r('app.media.ic_protocol'))
              .width(12)
              .height(12)
              .margin({ right: 4 })
              .onClick(() => {
                this.agreementChecked = !this.agreementChecked;
                this.setDialogShow(this.agreementChecked);
              })
            Text('不再弹出，后续可操作设置页进行设置')
              .fontSize(12)
              .fontColor($r('app.color.c_9d9d9d'))
              .margin({ right: 4 })
          }
        }
      } else {
        // 无题库提示
        Text('您的题库列表空空如也\n请先下载或导入题库，再去搜题哦')
          .fontSize(16)
          .fontColor($r('app.color.c_9d9d9d'))
          .textAlign(TextAlign.Center)
          .margin({ bottom: 8 })
        Image($r('app.media.ic_nodata'))
          .size({ width: $r('app.float.float_80vp') })
      }

      // 确认按钮
      Flex({ justifyContent: FlexAlign.Center }) {
        Image($r('app.media.ic_confirm'))
          .width(120)
          .height(40)
          .borderRadius(8)
          .onClick(() => {
            const selectedIds = Array.from(new Set([
              ...this.allSelectedBankIds,
              ...this.customSelectedBankIds,
              ...this.downloadSelectedBankIds
            ]));
            this.onConfirm(selectedIds, this.agreementChecked);
            this.controller?.close();

          })
      }
    }
    .width('90%')
    .padding(16)
    .borderRadius(12)
  }
}
