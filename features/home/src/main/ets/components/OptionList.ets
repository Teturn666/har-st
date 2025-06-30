@Component
export struct OptionList {
  @Prop options: string[];
  @Prop selectedOptions: string[];
  @Prop selectedOption: string;
  @Prop hasSubmitted: boolean;
  @Prop isMultipleChoice: boolean;
  @Prop correctAnswers: string;
  @Prop isReviewMode: boolean; // 新增：是否为背题模式
  onOptionClick: (option: string) => void = () => {
  };

  build() {
    Column() {
      ForEach(this.options, (item: string, idx: number) => {
        Row() {
          Text(String.fromCharCode(65 + idx))
            .width(30)
            .height($r('app.float.float_30vp'))
            .textAlign(TextAlign.Center)
            .fontSize($r('app.float.font_size_16fp'))
            .fontColor($r('app.color.c_black'))
            .borderRadius(15)
            .backgroundColor(
              this.getOptionBackgroundColor(idx)
            )
            .margin({ right: 10 })

          Text(item)
            .fontSize($r('app.float.font_size_16fp'))
            .padding(10)
            .width('80%')
            .borderRadius(8)
            .backgroundColor(
              this.getOptionBackgroundColor(idx)
            )
        }
        .onClick(() => this.onOptionClick(String.fromCharCode(65 + idx)))
        .margin({ top: 12, left: 16, right: 16 })
      })
    }
    .width('100%')
  }

  private isTrueFalseQuestion(): boolean {
    // 检查是否为2个选项
    if (this.options.length !== 2) {
      return false;
    }

    // 定义所有可能的判断题选项组合
    const trueFalsePatterns: string[][] = [
      ['正确', '错误'],
      ['√', '×'],
      ['对', '错'],
      ['Y', 'N'],
      ['A', 'B']// 当选项就是A/B时需要结合其他条件判断
    ];

    // 检查选项是否匹配任何一种判断题模式
    return trueFalsePatterns.some(pattern => {
      return (this.options.includes(pattern[0]) && this.options.includes(pattern[1])) ||
        (this.options.includes(pattern[1]) && this.options.includes(pattern[0]));
    });
  }

  private getOptionBackgroundColor(idx: number): ResourceStr {
    const optionLabel = String.fromCharCode(65 + idx);
    const isSelected = this.isMultipleChoice
      ? this.selectedOptions.includes(optionLabel)
      : this.selectedOption === optionLabel;

    let isCorrect = false;

    // 修复判断题的正确答案判断逻辑
    if (this.isTrueFalseQuestion()) {
      // 对于判断题，需要通过选项内容或答案格式来判断
      const optionContent = this.options[idx];

      // 如果答案是选项标签格式(A/B)
      if (this.correctAnswers === 'A' || this.correctAnswers === 'B') {
        isCorrect = optionLabel === this.correctAnswers;
      } else {
        // 如果答案是选项内容格式
        isCorrect = optionContent === this.correctAnswers;
      }
    } else {
      // 普通单选题和多选题
      isCorrect = this.correctAnswers.includes(optionLabel);
    }

    if (this.isReviewMode) {
      return isCorrect ? '#DFF5E3' : '#F2F2F2';
    }

    if (this.hasSubmitted) {
      if (isCorrect) {
        return '#DFF5E3';
      }
      if (isSelected && !isCorrect) {
        return '#FDECEC';
      }
      return '#F2F2F2';
    } else {
      return isSelected ? '#B3E5FC' : '#F2F2F2';
    }
  }
}