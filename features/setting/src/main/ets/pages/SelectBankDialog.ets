import { promptAction, router } from '@kit.ArkUI';
import { preferencesUtils, PreferencesConstants } from 'utils/Index';
import { BankListRes } from 'db';
import { SearchMapManage } from 'search/src/main/ets/manage/SearchMapManage';
import { SearchEngine } from 'search';
import SearchConstants from 'search/src/main/ets/constants/SearchConstants';


const TAG = 'SelectBankDialog';

@CustomDialog
export struct selectBankDialog {
  controller?: CustomDialogController;
  @Prop bankList: BankListRes[];
  @Prop isVip: boolean = false; // 从外部传入VIP状态
  onConfirm: (selectedIds: string[], agreementChecked: boolean) => void = () => {
  };
  @State agreementChecked: boolean = false;
  @State selectedBankIds: string[] = []; // 统一管理选中的题库ID
  isVipDialog?: () => void = () => {
  }
  isChangeText?: () => void = () => {
  }
  @State loginState: string = ''

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
    if (customBanks.length === 0) {
      return false;
    }
    return customBanks.every(bank => this.selectedBankIds.includes(String(bank.id || '')));
  }

  // 检查下载题库是否全选
  private isDownloadBanksAllSelected(): boolean {
    const downloadBanks = this.getDownloadBanks();
    if (downloadBanks.length === 0) {
      return false;
    }
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
      this.selectedBankIds = [...this.selectedBankIds.filter(id => !downloadBankIds.includes(id))];
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

  // 保存选中的题库ID到本地
  private saveSelectedBankIds(selectedIds: string[]) {
    try {
      const idsJson = JSON.stringify(selectedIds);
      preferencesUtils.putString(PreferencesConstants.SP_QUESTION_BANK, idsJson);
      console.info(TAG, `Saved selected bank IDs: ${idsJson}`);

      //保存是否全选
      if (this.selectedBankIds.length === this.bankList.length) {
        preferencesUtils.putString(PreferencesConstants.SP_QUESTION_BANK_ALL, '1')
      } else {
        preferencesUtils.putString(PreferencesConstants.SP_QUESTION_BANK_ALL, '0')
      }
    } catch (error) {
      console.error(TAG, 'Error saving selected bank IDs:', error);
    }
  }

  // 从本地读取选中的题库ID
  private getSelectedBankIds(): string[] {
    try {
      const idsJson = preferencesUtils.getString(PreferencesConstants.SP_QUESTION_BANK, '[]');
      const savedIds = JSON.parse(idsJson) as string[];
      console.info(TAG, `Loaded selected bank IDs: ${idsJson}`);

      // 验证保存的ID是否在当前题库列表中存在
      const currentBankIds = this.bankList.map(bank => String(bank.id || ''));
      const validIds = savedIds.filter(id => currentBankIds.includes(id));

      // 如果没有有效的保存记录，默认选中所有题库
      if (validIds.length === 0) {
        return currentBankIds;
      }

      return validIds;
    } catch (error) {
      console.error(TAG, 'Error loading selected bank IDs:', error);
      // 出错时默认选中所有题库
      return this.bankList.map(bank => String(bank.id || ''));
    }
  }

  aboutToAppear() {
    this.getIsVip()
    // 从本地读取选中的题库ID，如果没有则默认选中所有  //一：登录 是会员 显示本地存储的  二：登录 非会员  默认全选 三：退出登录的话默认选中所有题库
    this.loginState = preferencesUtils.getString(PreferencesConstants.SP_IS_LOGIN, '0')
    if (this.loginState === '1') {
      if (this.isVip) {
        this.selectedBankIds = this.getSelectedBankIds();

      } else {
        this.selectedBankIds = this.bankList.map(bank => String(bank.id || ''));
      }
    } else {
      this.selectedBankIds = this.bankList.map(bank => String(bank.id || ''));
    }
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
                .onClick(() => {
                  // 切换全选状态
                  const isCurrentlyAllSelected = this.isAllSelected();
                  this.handleSelectAll(!isCurrentlyAllSelected);
                })

              Text("全选")
                .fontSize(14)
                .fontColor(this.isVip ? "#3e3e3e" : "#cccccc")
                .margin({ left: 8 })
            }
            .width('100%')
          }
          .onClick(() => {
            this.handleNonVipClick();
          })

          // 自定义题库分组
          if (this.getCustomBanks().length > 0) {
            ListItem() {
              Column({ space: 8 }) {
                // 自定义题库标题
                Row() {
                  Checkbox({ name: 'customBanks', })
                    .select(this.isCustomBanksAllSelected())
                    .selectedColor(0xed6f21)
                    .shape(CheckBoxShape.CIRCLE)
                    .enabled(this.isVip)
                    .onClick(() => {
                      // 切换自定义题库全选状态
                      const isCurrentlyAllSelected = this.isCustomBanksAllSelected();
                      this.handleCustomBanksSelectAll(!isCurrentlyAllSelected);
                    })

                  Text("自定义题库")
                    .fontSize(14)
                    .fontColor(this.isVip ? "#3e3e3e" : "#cccccc")
                    .fontWeight(FontWeight.Bold)
                    .margin({ left: 8 })
                }
                .width('100%')

                // 自定义题库列表
                ForEach(this.getCustomBanks(), (bank: BankListRes) => {
                  Row() {
                    Checkbox({ name: `custom_${bank.id}`, })
                      .select(this.selectedBankIds.includes(String(bank.id || '')))
                      .selectedColor(0xed6f21)
                      .shape(CheckBoxShape.CIRCLE)
                      .enabled(this.isVip)
                      .onClick(() => {
                        const bankId = String(bank.id || '');
                        const isSelected = this.selectedBankIds.includes(bankId);
                        this.handleBankSelect(bankId, !isSelected);
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

                })
              }
              .alignItems(HorizontalAlign.Start)
            }.margin({ left: 18 })
            .onClick(() => {
              this.handleNonVipClick();
            })

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
                    .onClick(() => {
                      // 切换下载题库全选状态
                      const isCurrentlyAllSelected = this.isDownloadBanksAllSelected();
                      this.handleDownloadBanksSelectAll(!isCurrentlyAllSelected);
                    })

                  Text("我的下载")
                    .fontSize(14)
                    .fontColor(this.isVip ? "#3e3e3e" : "#cccccc")
                    .fontWeight(FontWeight.Bold)
                    .margin({ left: 8 })
                }
                .width('100%')


                // 下载题库列表
                ForEach(this.getDownloadBanks(), (bank: BankListRes) => {
                  Row() {
                    Checkbox({ name: `download_${bank.id}`, })
                      .select(this.selectedBankIds.includes(String(bank.id || '')))
                      .selectedColor(0xed6f21)
                      .shape(CheckBoxShape.CIRCLE)
                      .enabled(this.isVip)
                      .onClick(() => {
                        const bankId = String(bank.id || '');
                        const isSelected = this.selectedBankIds.includes(bankId);
                        this.handleBankSelect(bankId, !isSelected);
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
                })
              }
              .alignItems(HorizontalAlign.Start)
            }.margin({ left: 18 })
            .onClick(() => {
              this.handleNonVipClick();
            })

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
          .onClick(async () => {
            if (this.isVip) {
              // 用户必须勾选至少一个题库
              if (this.selectedBankIds.length === 0) {
                promptAction.showToast({
                  message: '请至少选择一个题库进行扫描题库',
                  duration: 2000
                });
                return;
              }
              //将选择的题库列表存入本地
              this.saveSelectedBankIds(this.selectedBankIds);
            }
            // 去重并返回选中的题库ID
            const uniqueSelectedIds = Array.from(new Set(this.selectedBankIds));
            this.onConfirm(uniqueSelectedIds, this.agreementChecked);
            this.controller?.close();

            if (!this.isVip) {
              if (this.isVipDialog) {
                this.isVipDialog()
              }
            } else {
              if (this.isChangeText) {
                this.isChangeText()
              }

            }
            // 判断选择部分题库进行初始化
            if (this.selectedBankIds.length > 0 && this.selectedBankIds.length !== this.bankList.length) {
              await SearchMapManage.getInstance()
                .clearTreeMapFileContent(getContext(this), SearchConstants.SEARCH_FILE_SOME)
              const selectedBankQIds = this.bankList
                .filter(bank => this.selectedBankIds.includes(String(bank.id)))
                .map(bank => bank.qid)

              await SearchEngine.getInstance()
                .findQuestionInitEngine(getContext(this), selectedBankQIds.map(Number))
            }
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