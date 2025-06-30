import { QuestionRes } from "db";

@Component
export struct QuestionContent {
  @Prop question: QuestionRes;
  @Prop isStarred: boolean;
  onToggleStar: () => void = () => {
  };

  build() {
    Column() {
      Row() {
        Image(this.getQuestionTypeImage())
          .height($r('app.float.float_24vp'))
          .objectFit(ImageFit.Cover)

        Blank()

        Row() {
          Image(this.isStarred ? $r('app.media.stared') : $r('app.media.star'))
            .width($r('app.float.float_18vp'))
            .height($r('app.float.float_18vp'))
            .margin({ right: 5 })

          Text(this.isStarred ? "已收藏" : "收藏")
            .fontSize($r('app.float.font_size_14fp'))
        }
        .onClick(() => this.onToggleStar())
      }
      .justifyContent(FlexAlign.SpaceBetween)
      .padding(10)
      .backgroundColor($r('app.color.c_white'))
      .borderRadius(8)
      .margin({ top: 20, left: 15, right: 15 })
      .width('90%')

      Text(this.question.question)
        .fontSize(16)
        .padding({ left: 15, right: 15, top: 10 })
        .textAlign(TextAlign.Start)
        .width('90%')
    }
  }

  private getQuestionTypeImage(): Resource {
    const options = this.question.option;
    const answer = this.question.answer;

    const isTrueFalse = options.length === 2 && options.includes('正确') && options.includes('错误');
    const isMultiple = answer.length > 1 && /^[A-D]+$/.test(answer);

    if (isMultiple) {
      return $r('app.media.ic_mu');
    } else if (isTrueFalse) {
      return $r('app.media.ic_es');
    } else {
      return $r('app.media.ic_ch');
    }
  }
}