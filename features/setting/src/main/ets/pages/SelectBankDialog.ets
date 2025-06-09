import { promptAction } from '@kit.ArkUI';
import { preferencesUtils, PreferencesConstants } from 'utils/Index';
import { BankListRes } from 'db';

@CustomDialog
export struct selectBankDialog {
  controller?: CustomDialogController;
  @Prop bankList: BankListRes[];
  @Prop isVip: boolean = false; // 从外部传入VIP状态
  onConfirm: (selectedIds: string[], agreementChecked: boolean) => void = () => {};

  @State agreementChecked: boolean = false;
  @State selectedBankIds: string[] = []; // 统一管理选中的题库ID

  //获取是否是VIP
  private getIsVip(): boolean {
    try {
      const result = preferencesUtils.getNumber(PreferencesConstants.SP_IS_VIP, 0);
      const vipStatus = result !== 0;
      this.isVip = vipStatus;
      return vipStatus;
    } catch (error) {
      console.error('Error retrieving VIP status from preferences:', error);
      return this.isVip;
    }
  }

  // 获取下载题库
  private getDownloadBanks(): BankListRes[] {
    return this.bankList.filter(bank => bank.bankType === 0);
  }

  // 获取自定义题库
  private getCustomBanks(): BankListRes[] {
    return this.bankList.filter(bank => bank.bankType === 2);
  }

  // 设置对话框显示状态
  setDialogShow(newValue: boolean) {
    preferencesUtils.putBoolean(PreferencesConstants.SP_SELECT_DIALOG_SHOW, newValue);
  }

  // 检查是否全选
  private isAllSelected(): boolean {
    return this.selectedBankIds.length === this.bankList.length && this.bankList.length > 0;
  }

  // 检查自定义题库是否全选
  private isCustomBanksAllSelected(): boolean {
    const customBanks = this.getCustomBanks();
    if (customBanks.length === 0) return false;
    return customBanks.every(bank => this.selectedBankIds.includes(String(bank.id || '')));
  }

  // 检查下载题库是否全选
  private isDownloadBanksAllSelected(): boolean {
    const downloadBanks = this.getDownloadBanks();
    if (downloadBanks.length === 0) return false;
    return downloadBanks.every(bank => this.selectedBankIds.includes(String(bank.id || '')));
  }

  // 处理全选/取消全选 - 只由全选按钮触发
  private handleSelectAll(value: boolean) {
    if (!this.isVip) {
      promptAction.showToast({ message: '开通会员即可指定搜索题库', duration: 2000 });
      return;
    }

    if (value) {
      // 全选：添加所有题库ID
      const allBankIds = this.bankList.map(bank => String(bank.id || ''));
      this.selectedBankIds = allBankIds;
    } else {
      // 取消全选：清空所有选中
      this.selectedBankIds = [];
    }
  }

  // 处理自定义题库全选/取消全选 - 只由自定义题库全选按钮触发
  private handleCustomBanksSelectAll(value: boolean) {
    if (!this.isVip) {
      promptAction.showToast({ message: '开通会员即可指定搜索题库', duration: 2000 });
      return;
    }

    const customBankIds = this.getCustomBanks().map(bank => String(bank.id || ''));

    if (value) {
      // 选中所有自定义题库 - 确保这些ID都在选中列表中
      const newSelectedIds = [...this.selectedBankIds];
      customBankIds.forEach(id => {
        if (!newSelectedIds.includes(id)) {
          newSelectedIds.push(id);
        }
      });
      this.selectedBankIds = newSelectedIds;
    } else {
      // 取消选中所有自定义题库 - 只移除自定义题库的ID
      this.selectedBankIds = this.selectedBankIds.filter(id => !customBankIds.includes(id));
    }
  }

  // 处理下载题库全选/取消全选 - 只由下载题库全选按钮触发
  private handleDownloadBanksSelectAll(value: boolean) {
    if (!this.isVip) {
      promptAction.showToast({ message: '开通会员即可指定搜索题库', duration: 2000 });
      return;
    }

    const downloadBankIds = this.getDownloadBanks().map(bank => String(bank.id || ''));

    if (value) {
      // 选中所有下载题库 - 确保这些ID都在选中列表中
      const newSelectedIds = [...this.selectedBankIds];
      downloadBankIds.forEach(id => {
        if (!newSelectedIds.includes(id)) {
          newSelectedIds.push(id);
        }
      });
      this.selectedBankIds = newSelectedIds;
    } else {
      console.log("查看Bank" + this.selectedBankIds)
      // 取消选中所有下载题库 - 只移除下载题库的ID
      this.selectedBankIds =[...this.selectedBankIds.filter(id => !downloadBankIds.includes(id))] ;

      console.log("查看Bank--" + this.selectedBankIds)
    }
  }

  // 处理单个题库选择 - 只处理单个选择逻辑
  private handleBankSelect(bankId: string, value: boolean) {
    if (!this.isVip) {
      promptAction.showToast({ message: '开通会员即可指定搜索题库', duration: 2000 });
      return;
    }

    if (value) {
      // 添加到选中列表
      if (!this.selectedBankIds.includes(bankId)) {
        this.selectedBankIds = [...this.selectedBankIds, bankId];
      }
    } else {
      // 从选中列表移除
      this.selectedBankIds = this.selectedBankIds.filter(id => id !== bankId);
    }

    this.selectedBankIds = [...this.selectedBankIds];
  }

  // 处理非VIP用户点击
  private handleNonVipClick() {
    if (!this.isVip) {
      promptAction.showToast({ message: '开通会员即可指定搜索题库', duration: 2000 });
    }
  }

  aboutToAppear() {
    // 初始化选中所有题库
    this.selectedBankIds = this.bankList.map(bank => String(bank.id || ''));
    this.getIsVip()
  }

  build() {
    Column({ space: 16 }) {
      // 顶部标题
      Row() {
        Text('题库选择')
          .fontSize(16)
          .fontColor($r('app.color.c_9d9d9d'))
          .textAlign(TextAlign.Center)
          .layoutWeight(1)

        Image($r('app.media.ic_cha'))
          .width(16)
          .height(16)
          .onClick(() => this.controller?.close())
      }
      .width('100%')

      if (this.bankList.length > 0) {
        List({ space: 8 }) {
          // 全选选项
          ListItem() {
            Row() {
              Checkbox({ name: 'selectAll', })
                .select(this.isAllSelected())
                .selectedColor(0xed6f21)
                .shape(CheckBoxShape.CIRCLE)
                .enabled(this.isVip)
                .onChange((value: boolean) => {
                  this.handleSelectAll(value);
                })

              Text("全选")
                .fontSize(14)
                .fontColor(this.isVip ? "#3e3e3e" : "#cccccc")
                .margin({ left: 8 })
            }
            .width('100%')
            .onClick(() => {
              if (this.isVip) {
                // 切换全选状态
                const isCurrentlyAllSelected = this.isAllSelected();
                this.handleSelectAll(!isCurrentlyAllSelected);
              } else {
                this.handleNonVipClick();
              }
            })
          }

          // 自定义题库分组
          if (this.getCustomBanks().length > 0) {
            ListItem() {
              Column({ space: 8 }) {
                // 自定义题库标题
                Row() {
                  Checkbox({ name: 'customBanks',  })
                    .select(this.isCustomBanksAllSelected())
                    .selectedColor(0xed6f21)
                    .shape(CheckBoxShape.CIRCLE)
                    .enabled(this.isVip)
                    .onChange((value: boolean) => {
                      this.handleCustomBanksSelectAll(value);
                    })

                  Text("自定义题库")
                    .fontSize(14)
                    .fontColor(this.isVip ? "#3e3e3e" : "#cccccc")
                    .fontWeight(FontWeight.Bold)
                    .margin({ left: 8 })
                }
                .width('100%')
                .onClick(() => {
                  if (this.isVip) {
                    // 切换自定义题库全选状态
                    const isCurrentlyAllSelected = this.isCustomBanksAllSelected();
                    this.handleCustomBanksSelectAll(!isCurrentlyAllSelected);
                  } else {
                    this.handleNonVipClick();
                  }
                })

                // 自定义题库列表
                ForEach(this.getCustomBanks(), (bank: BankListRes) => {
                  Row() {
                    Checkbox({ name: `custom_${bank.id}`, })
                      .select(this.selectedBankIds.includes(String(bank.id || '')))
                      .selectedColor(0xed6f21)
                      .shape(CheckBoxShape.CIRCLE)
                      .enabled(this.isVip)
                      .onChange((value: boolean) => {
                        this.handleBankSelect(String(bank.id || ''), value);
                      })

                    Text(bank.name || "未命名题库")
                      .fontSize(14)
                      .fontColor(this.isVip ? "#3e3e3e" : "#cccccc")
                      .maxLines(1)
                      .textOverflow({ overflow: TextOverflow.Ellipsis })
                      .margin({ left: 8 })
                      .layoutWeight(1)
                  }
                  .width('100%')
                  .margin({ left: 30 })
                  .onClick(() => {
                    if (this.isVip) {
                      const bankId = String(bank.id || '');
                      const isSelected = this.selectedBankIds.includes(bankId);
                      this.handleBankSelect(bankId, !isSelected);
                    } else {
                      this.handleNonVipClick();
                    }
                  })
                })
              }
              .alignItems(HorizontalAlign.Start)
            }.margin({ left: 18 })
          }

          // 我的下载分组
          if (this.getDownloadBanks().length > 0) {
            ListItem() {
              Column({ space: 8 }) {
                // 我的下载标题
                Row() {
                  Checkbox({ name: 'downloadBanks', })
                    .select(this.isDownloadBanksAllSelected())
                    .selectedColor(0xed6f21)
                    .shape(CheckBoxShape.CIRCLE)
                    .enabled(this.isVip)
                    .onChange((value: boolean) => {
                      this.handleDownloadBanksSelectAll(value);
                    })

                  Text("我的下载")
                    .fontSize(14)
                    .fontColor(this.isVip ? "#3e3e3e" : "#cccccc")
                    .fontWeight(FontWeight.Bold)
                    .margin({ left: 8 })
                }
                .width('100%')
                .onClick(() => {
                  if (this.isVip) {
                    // 切换下载题库全选状态
                    const isCurrentlyAllSelected = this.isDownloadBanksAllSelected();
                    this.handleDownloadBanksSelectAll(!isCurrentlyAllSelected);
                  } else {
                    this.handleNonVipClick();
                  }
                })

                // 下载题库列表
                ForEach(this.getDownloadBanks(), (bank: BankListRes) => {
                  Row() {
                    Checkbox({ name: `download_${bank.id}`, })
                      .select(this.selectedBankIds.includes(String(bank.id || '')))
                      .selectedColor(0xed6f21)
                      .shape(CheckBoxShape.CIRCLE)
                      .enabled(this.isVip)
                      .onChange((value: boolean) => {
                        this.handleBankSelect(String(bank.id || ''), value);
                      })

                    Text(bank.name || "未命名题库")
                      .fontSize(14)
                      .fontColor(this.isVip ? "#3e3e3e" : "#cccccc")
                      .maxLines(1)
                      .textOverflow({ overflow: TextOverflow.Ellipsis })
                      .margin({ left: 8 })
                      .layoutWeight(1)
                  }
                  .width('100%')
                  .margin({ left: 30 })
                  .onClick(() => {
                    if (this.isVip) {
                      const bankId = String(bank.id || '');
                      const isSelected = this.selectedBankIds.includes(bankId);
                      this.handleBankSelect(bankId, !isSelected);
                    } else {
                      this.handleNonVipClick();
                    }
                  })
                })
              }
              .alignItems(HorizontalAlign.Start)
            }.margin({ left: 18 })
          }
        }
        .width('100%')
        .height(160)
        .scrollBar(BarState.Auto)

        // 协议行
        Row() {
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
        }
        .width('100%')
      } else {
        // 无题库提示
        Column({ space: 16 }) {
          Text('您的题库列表空空如也\n请先下载或导入题库，再去搜题哦')
            .fontSize(16)
            .fontColor($r('app.color.c_9d9d9d'))
            .textAlign(TextAlign.Center)

          Image($r('app.media.ic_nodata'))
            .width($r('app.float.float_80vp'))
            .height($r('app.float.float_80vp'))
        }
      }

      // 确认按钮
      Row() {
        Image($r('app.media.ic_confirm'))
          .width(120)
          .height(40)
          .borderRadius(8)
          .onClick(() => {
            // 去重并返回选中的题库ID
            const uniqueSelectedIds = Array.from(new Set(this.selectedBankIds));
            this.onConfirm(uniqueSelectedIds, this.agreementChecked);
            this.controller?.close();

          })
      }
      .width('100%')
      .justifyContent(FlexAlign.Center)
    }
    .width('90%')
    .padding(16)
    .borderRadius(12)
  }
}