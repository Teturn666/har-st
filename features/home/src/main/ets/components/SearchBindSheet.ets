import { BottomBar } from 'photo/src/main/ets/components/BottomBar'
import { SearchTypeView } from 'photo/src/main/ets/components/SearchTypeView';
import { inputMethod } from '@kit.IMEKit';
import { BusinessError, pasteboard } from '@kit.BasicServicesKit';
import { cameraAppStorage } from '../Constants/CameraAppStorage';
import { JSON } from '@kit.ArkTS';
import { promptAction } from '@kit.ArkUI';


@Component
export struct SearchBindSheet {
  @State isEditing: boolean = false
  @StorageProp(cameraAppStorage.OCR_TEXT) searchText: string = ''
  @State defaultTab: number = 0
  @State SearchIndex: number = 0
  list: string[] = ['全部', '单选题', '多选题', '判断题']
  DialogController = new CustomDialogController({
    builder: KeyboardPromptDialog(),
    cancel: () => {
      focusControl.requestFocus('inputId');
    },
    alignment: DialogAlignment.Center,
    cornerRadius: 5,
    width: 260,
    height: 300,
    maskColor: "#88000000",
    borderStyle: BorderStyle.Dashed,

  });

  onPageHide(): void {
    this.searchText = ''
  }

  @Builder
  SearchTypeBuilder(item: string, index: number) {
    Row() {
      Text(item)
        .fontSize(14)
        .fontColor(this.SearchIndex === index ? $r('app.color.c_f75a23') : Color.Black)
    }
    .margin({ right: 10 })
    .borderRadius(3)
    .border(this.SearchIndex === index ? { width: 1, color: $r('app.color.c_f75a23') } :
      { width: 1, color: '#00000000' })
    .backgroundColor(this.SearchIndex === index ? '#F8F9ED' : '#ECECEC')
    .justifyContent(FlexAlign.Center)
    .padding({
      top: 3,
      bottom: 3,
      left: 6,
      right: 6
    })
  }

  build() {
    Column() {
      Row() {
        Column() {
          TextArea({
            text: $$this.searchText,
          })
            .key('inputId')
            .fontSize(12)
            .height(70)
            .width('100%')
            .maxLines(40)
            .onEditChange((isEditing: boolean) => {
              if (isEditing) {
                this.isEditing = true
              }

            })
            .layoutWeight(1)
            .backgroundColor('#FFFFFF')
            .padding(10)
          if (this.isEditing) {
            Row() {
              Row() {
                PasteButton({ text: PasteDescription.PASTE })
                  .width(30)
                  .height(16)
                  .fontSize(12)
                  .fontWeight(FontWeight.Normal)
                  .fontColor(Color.Black)
                  .backgroundColor($r('app.color.c_ccc'))
                  .onClick((event: ClickEvent, result: PasteButtonOnClickResult) => {
                    if (PasteButtonOnClickResult.SUCCESS === result) {
                      pasteboard.getSystemPasteboard()
                        .getData((err: BusinessError, pasteData: pasteboard.PasteData) => {
                          if (err) {
                            return;
                          }
                          this.searchText = pasteData.getPrimaryText();
                        });
                    } else {
                      inputMethod.getController().stopInputSession();
                      promptAction.showToast({
                        message: '剪切板为空'
                      })
                    }
                  })
              }
              .justifyContent(FlexAlign.Center)
              .borderRadius(3)
              .margin({ left: 10, bottom: 3 })
              .width(30)
              .height(16)
              .backgroundColor('#ECECEC')

              Row() {
                Text('清除')
                  .fontSize(12)
              }
              .onClick(() => {
                this.searchText = ''
              })
              .borderRadius(3)
              .margin({ left: 10, bottom: 3 })
              .width(30)
              .height(16)
              .backgroundColor('#ECECEC')
              .justifyContent(FlexAlign.Center)
            }
          }
        }
        .alignItems(HorizontalAlign.Start)
        .height('100%')
        .width('90%')

        Row() {
          Image($r('app.media.microphone'))
            .width(20)
            .height(20)
        }
        .onClick(() => {
          this.DialogController.open()
        })
      }
      .width('100%')
      .height(this.isEditing ? 120 : 40)
      .border({
        width: 1,
        color: Color.Black
      })
      .borderRadius(6)

      BottomBar({
        searchText: '搜索', searchClick: () => {
          inputMethod.getController().stopInputSession();
          AppStorage.setOrCreate(cameraAppStorage.OCR_TEXT, this.searchText)
        },
        ButtonWidth: '100%'
      })
      Row() {
        ForEach(this.list, (item: string, index: number) => {
          Row() {
            this.SearchTypeBuilder(item, index)
          }
          .onClick(() => {
            this.SearchIndex = index
          })

        }, (item: string, index: number) => JSON.stringify(item) + index)

      }
      .margin({ top: 20 })
      .width('100%')
      .justifyContent(FlexAlign.Start)

      SearchTypeView({ TypeFlex: true })

    }
    .height('100%')
    .backgroundColor(Color.White)
    .padding(20)
  }
}

@CustomDialog
export struct KeyboardPromptDialog {
  controller?: CustomDialogController;

  build() {
    Column() {
      Image($r("app.media.KeyboardPrompt"))
    }
  }
}