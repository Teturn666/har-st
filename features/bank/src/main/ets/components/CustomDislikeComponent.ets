import { FilterWord } from '@csj/openadsdk';

import { emitter } from '@kit.BasicServicesKit';

import { EmitterConstants } from 'utils';


@Builder
export function customDislikeComponent(fwList: Array<FilterWord>,
  onSelected: (filterPosition: number, filterName: string) => void,
  onOtherSuggestComment: (suggestionValue: string) => void,
  onUserSuggestDialogCancel: (commentValue: string) => void,
) {
  //自定义Dislike弹窗
  CSJDislikeComponent({
    _fwList: fwList,
    _onSelected: onSelected,
    _onOtherSuggestComment: onOtherSuggestComment,
    _onUserSuggestDialogCancel: onUserSuggestDialogCancel,

  });
}

@Component
export default struct CSJDislikeComponent {
  private _onSelected?: (filterPosition: number, filterName: string) => void;
  private _onOtherSuggestComment?: (suggestionValue: string) => void;
  private _onUserSuggestDialogCancel?: (commentValue: string) => void;
  private _fwList?: Array<FilterWord>;

  build() {
    Column() {
      List() {
        ForEach(this._fwList, (item: FilterWord, index: number) => {
          ListItem() {
            this.filterWordsItem(item, index,)

          }
          .padding({
            left: 8,
            right: 8,
            top: 14,
            bottom: 14
          })
        }, (item: string) => JSON.stringify(item))

        ListItem() {
          UserSuggestComment({
            onOtherSuggestComment: this._onOtherSuggestComment,
            onUserSuggestDialogCancel: this._onUserSuggestDialogCancel
          })
        }
        .padding({
          left: 8,
          right: 8,
          top: 14,
          bottom: 8
        }
        )
      }
      .width("100%")
      .divider({ strokeWidth: '0.5vp', color: '#030161823' })
    }
    .width("100%")
    .padding({
      top: '6vp',
      bottom: '6vp'
    })
    .borderRadius('8vp',)
  }

  @Builder
  filterWordsItem(fw: FilterWord, position: number,) {
    if (fw) {
      if (fw.getOptions() && fw.getOptions().length > 0) {
        Column() {
          //一级item
          this.filterWordOnly(fw.getName(), position,);
          //二级item
          this.optionItem(fw, position);
        }
        .justifyContent(FlexAlign.Start)
      } else {
        this.filterWordOnly(fw.getName(), position,);
      }
    }
  }

  @Builder
  filterWordOnly(name: string, position: number,) {
    Text(name)
      .fontSize('14fp')
      .fontColor("#161823")
      .alignSelf(ItemAlign.Start)
      .padding({
        left: 6
      })
      .onClick(() => {
        // 内容无法显示黑屏
        emitter.emit(EmitterConstants.Delete_ADS)

        if (this._onSelected) {
          this._onSelected(position, name);
        }
      })
  }

  @Builder
  optionItem(fw: FilterWord, position: number) {
    List({ space: 0 }) {
      ForEach(fw.getOptions(), (fwItem: FilterWord) => {
        ListItem() {
          Text(fwItem.getName())
            .fontSize('12fp')
            .fontWeight(FontWeight.Lighter)
        }
        .backgroundColor("#20161823")
        .borderRadius('2vp')
        .margin({ left: 8, top: 8 })
        .padding({
          left: 8,
          right: 8,
          bottom: 4,
          top: 4
        })
        .onClick(() => {
          if (this._onSelected) {
            this._onSelected(position, fwItem.getName());
            emitter.emit(EmitterConstants.Delete_ADS)
          }
        })
      }, (fwItem: FilterWord) => JSON.stringify(fwItem))
    }
    .enableScrollInteraction(false)
    .width("60%")
    .lanes({ minLength: 80, maxLength: 80 })
    .scrollBar(BarState.Off)
  }
}

@Component
export struct UserSuggestComment {
  onOtherSuggestComment?: (suggestionValue: string) => void;
  onUserSuggestDialogCancel?: (commentValue: string) => void;
  //二级弹窗控制器
  private _suggestionDialogController?: CustomDialogController = new CustomDialogController({
    builder: CustomSuggestionDialog({
      _cancelListener: this.onUserSuggestDialogCancel,
      _commitListener: this.onOtherSuggestComment
    }),
    alignment: DialogAlignment.Bottom,
    customStyle: true,
    offset: { dx: 0, dy: -20 }
  });

  build() {
    Row() {
      Image($r('app.media.tt_dislike_suggestion_logo'))
        .size({ width: 12, height: 12 })
        .margin({ left: 6 })

      Text("其它建议")
        .fontSize('12fp')
        .fontColor("#80161823")
        .margin({ left: 4 })
    }
    .width('100%')
    .padding({ top: 10, bottom: 10 })
    .border({ width: 0.5, color: "#10161823" })
    .borderRadius('4vp')
    .onClick((event: ClickEvent) => {
      this._suggestionDialogController?.open();
    })
  }
}

@CustomDialog
export struct CustomSuggestionDialog {
  private _suggestionDialogController: CustomDialogController
  @State _hasContent: boolean = false; //
  private _cancelListener?: (suggestContent: string) => void; //点击close关闭弹窗回调
  private _commitListener?: (suggestContent: string) => void; //内容提交回调
  private _suggestContent: string = ""; //建议内容

  build() {
    Column() {
      Row() {
        //关闭按钮
        Image($r("app.media.tt_dislike"))
          .objectFit(ImageFit.Auto)
          .size({
            width: '20vp',
            height: '20vp'
          })
          .onClick((event: ClickEvent) => {
            this._suggestionDialogController?.close();
          })

        Text("其它建议")
          .fontSize('16fp')
          .fontColor("#80323232")
          .padding({ left: '8vp', right: '8vp' })

        Text("提交")
          .fontSize('16fp')
          .fontColor(this._hasContent ? "#323232" : "#80323232")
          .onClick(() => {
            if (this._hasContent) {
              if (this._commitListener) {
                this._commitListener(this._suggestContent); //提交内容处理【------该回调的执行需要透传给CSJ SDK--------】
              }
              this._suggestionDialogController.close(); //关闭弹窗
              emitter.emit(EmitterConstants.Delete_ADS)
            }
          }).padding({ left: '8vp', right: '8vp' })
      }
      .padding({
        left: '16vp',
        right: '16vp',
        top: '14vp',
        bottom: '14vp',
      })
      .width("100%")
      .justifyContent(FlexAlign.SpaceBetween)

      Divider().strokeWidth(0.5).color('#20161823').width("98%")
      TextArea({ placeholder: "请具体说明问题，我们将尽快处理" })
        .placeholderColor("#57161823")
        .fontSize('16fp')
        .width("100%")
        .maxLines(7)
        .maxLength(500)
        .backgroundColor(Color.White)
        .onChange((value: string) => {
          this._hasContent = (value?.length >= 3) ? true : false;
          this._suggestContent = value;
        })
    }
    .width("94%")
    .height("30%")
    .backgroundColor(Color.White)
    .borderRadius('8vp')
    .onDisAppear(() => {
      if (this._cancelListener) {
        this._cancelListener(this._suggestContent); //【------该回调的执行需要透传给CSJ SDK--------】
      }
    })
  }
}
