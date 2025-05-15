import router from '@ohos.router';
import promptAction from '@ohos.promptAction';
import { QuestionRes } from 'db';

// 根据题目类型返回对应图标
// private getQuestionIcon(): Resource {
//   switch (this.questionType) {
//     case 'single':
//       return $r('app.media.ic_ch'); // 单选题图标
//     case 'multiple':
//       return $r('app.media.ic_mu'); // 多选题图标
//     case 'truefalse':
//       return $r('app.media.ic_es'); // 判断题图标
//     default:
//       return $r('app.media.ic_ch'); // 默认单选题图标
//   }
// }
// Sample question data (mocked based on QuestionRes)
const questions: QuestionRes[] = [
  {
    qId: 1,
    question: "根据收费公路车辆通行费减免政策，政府还免公路收费，免除的范围是？",
    option: ["30", "25", "15", "10"],
    answer: "C",
  },
  {
    qId: 2,
    question: "以下哪个选项是正确的？",
    option: ["选项A", "选项B", "选项C", "选项D"],
    answer: "B",
  },
];

// Reusable Option Component (as provided)
@Component
struct OptionItem {
  label?: string;
  text?: string;
  isSelected?: boolean;
  isCorrect?: boolean;
  onSelect?: (label: string) => void;

  build() {
    Row() {
      Text(this.label)
        .fontSize(16)
        .fontColor('#000000')
        .width(30)
        .height(30)
        .borderRadius(15)
        .backgroundColor(
          this.isSelected
            ? (this.isCorrect ? '#DFF5E3' : '#FDECEC')
            : '#FFFFFF'
        )
        .textAlign(TextAlign.Center)
        .margin({ right: 18 })
        .shadow({ radius: 6, color: '#E0E0E0', offsetX: 2, offsetY: 2 })

      Text(this.text)
        .fontSize(16)
        .padding(10)
        .width('80%')
        .borderRadius(8)
        .backgroundColor(
          this.isSelected
            ? (this.isCorrect ? '#DFF5E3' : '#FDECEC')
            : '#f2f2f2'
        )
        .shadow({ radius: 6, color: '#E0E0E0', offsetX: 2, offsetY: 2 })
    }
    .width('90%')
    .height(50)
    .borderRadius(10)
    .alignItems(VerticalAlign.Center)
    .padding(5)
    .margin({ top: 10 })
    .onClick(() => this.onSelect!(this.label!))
  }
}


@Entry({ routeName: 'exercisePage' })
@Component
struct ExercisePage {
  @State selectedIndex: number = 0; // 0 for 答题, 1 for 背题
  @State currentQuestionIndex: number = 0; // Current question index
  @State currentProgress: number = 1; // Current progress
  @State totalProgress: number = questions.length; // Total questions
  @State isStarred: boolean = false; // Starred status
  @State selectedOption: string = ''; // Selected option
  @State questionType: string = 'multiple'; // Placeholder for question type

  // Get question icon based on question type
  private getQuestionIcon(questionType: string): Resource {
    switch (questionType) {
      case 'single':
        return $r('app.media.ic_ch');
      case 'multiple':
        return $r('app.media.ic_mu');
      case 'truefalse':
        return $r('app.media.ic_es');
      default:
        return $r('app.media.ic_ch');
    }
  }

  // Reset progress with confirmation dialog
  private resetProgress() {
    promptAction.showDialog({
      title: '提示',
      message: '重置进度后将从第一题重新开始练习',
      buttons: [
        {
          text: '取消',
          color: '#666666',
        },
        {
          text: '确定',
          color: '#d2a129',

        },
      ],

      // success: (data) => {
      //   if (data.index === 1) { // Confirm button
      //     this.currentProgress = 1;
      //     this.currentQuestionIndex = 0;
      //     this.selectedOption = '';
      //     promptAction.showToast({ message: '进度已重置', duration: 1500 });
      //   }
      // },
    })
      .then((data =>{
        if (data.index === 1) { // Confirm button
          this.currentProgress = 1;
          this.currentQuestionIndex = 0;
          this.selectedOption = '';
          promptAction.showToast({ message: '进度已重置', duration: 1500 });
        }
      }));
  }

  // Navigate to previous question
  private goToPreviousQuestion() {
    if (this.currentQuestionIndex > 0) {
      this.currentQuestionIndex--;
      this.selectedOption = '';
      this.currentProgress = this.currentQuestionIndex + 1;
      promptAction.showToast({ message: '已切换到上一题', duration: 1500 });
    } else {
      promptAction.showToast({ message: '已经是第一题', duration: 1500 });
    }
  }

  // Navigate to next question
  private goToNextQuestion() {
    if (this.currentQuestionIndex < questions.length - 1) {
      this.currentQuestionIndex++;
      this.selectedOption = '';
      this.currentProgress = this.currentQuestionIndex + 1;
      promptAction.showToast({ message: '已切换到下一题', duration: 1500 });
    } else {
      promptAction.showToast({ message: '已经是最后一题', duration: 1500 });
    }
  }

  build() {
    Column() {
      // 头部
      Flex({ direction: FlexDirection.Row, alignItems: ItemAlign.Center }) {
        Image($r('app.media.ic_back'))
          .objectFit(ImageFit.Contain)
          .size({ width: $r('app.float.float_48vp'), height: $r('app.float.float_48vp') })
          .margin({ left: 15, right: 15 })
          .align(Alignment.TopStart)
          .onClick(() => router.back())
        // 返回按钮
        Button($r('app.media.ic_back'))
          .width(50)
          .height(50)
          .backgroundColor('#FFFFFF')
          .borderRadius(6)
          .onClick(() => {
            router.back();
          })
          .margin({ right: 20 })
        Flex({ direction: FlexDirection.Row, alignItems: ItemAlign.Center }) {
          // 答题按钮
          Button() {
            Row() {
              // 答题按钮
              Button('答题')
                .fontColor(this.selectedIndex == 0 ? '#FFFFFF' : '#d2a129')
                .fontSize(12)
                .border({ width: 1, color: '#d2a129' })
                .width(60)
                .height(28)
                .backgroundColor(this.selectedIndex === 0 ? '#d2a129' : '#FFFFFF')
                .borderRadius(6)
                .padding({ left: 12, right: 12 })
                .onClick(() => {
                  this.selectedIndex = 0;
                  promptAction.showToast({ message: '切换到答题' });
                })

              // 背题按钮
              Button('背题')
                .fontColor(this.selectedIndex == 1 ? '#FFFFFF' : '#d2a129')
                .fontSize(12)
                .border({ width: 1, color: '#d2a129' })
                .width(60)
                .height(28)
                .backgroundColor(this.selectedIndex === 1 ? '#d2a129' : '#FFFFFF')
                .borderRadius(6)
                .padding({ left: 12, right: 12 })
                .onClick(() => {
                  this.selectedIndex = 1;
                  promptAction.showToast({ message: '切换到背题' });
                })
            }
            .justifyContent(FlexAlign.SpaceBetween) // 水平居中对齐
            .alignItems(VerticalAlign.Center) // 垂直居中对齐
          }
          .backgroundColor('#d2a129')

          Blank()

          Button('模拟考试')
            .width(70)
            .height(28)
            .backgroundColor('#d2a129')
            .borderRadius(6)
            .padding({ left: 12, right: 12 })
            .margin({ right: 12 })
            .onClick(() => {
              // 模拟考试逻辑
            })
        }
      }

      // 进度条部分
      Flex({ direction: FlexDirection.Row, justifyContent: FlexAlign.SpaceBetween, alignItems: ItemAlign.Center }) {
        Progress({
          type: ProgressType.Linear,
          value: this.currentProgress,
          total: this.totalProgress,
        })
          .color(Color.Orange)
          .width('60%')
          .height(16)
          .backgroundColor('#dadada')
          .style({ strokeWidth: 15 })

        Text(`${this.currentProgress}/${this.totalProgress}`)
          .fontSize(12)
          .fontColor(Color.Black)

        Text('重置进度')
          .fontSize(12)
          .onClick(() => {

            this.resetProgress()
            // promptAction.showToast({
            //   message: '刷新中...',
            //   duration: 2000
            // });
            // this.currentProgress = 0;
          })
      }
      .backgroundColor('#f5f3f4')
      .borderRadius(8)
      .width('90%')
      .height(50)
      .margin({ top: 10 })
      .padding(10)

      // 内容部分
      Row() {
        Image($r('app.media.ic_ch'))
          .height(24)
          .objectFit(ImageFit.Cover)
        Blank()
        Image(this.isStarred ? $r('app.media.stared') : $r('app.media.star'))
          .width(18)
          .height(18)
          .onClick(() => {
            this.isStarred = !this.isStarred; // 切换收藏状态
            promptAction.showToast({
              message: this.isStarred ? '已收藏' : '取消收藏',
              duration: 2000
            });
          })
          .margin({ right: 5 })

        Text(this.isStarred ? "已收藏" : "收藏")
          .fontSize(12)
      }
      .justifyContent(FlexAlign.SpaceBetween)
      .padding(10)
      .backgroundColor(Color.White)
      .borderRadius(8)
      .margin({ top: 20 })
      .width('90%')


      // 问题描述
      Text('根据收费公路车辆通行费减免政策，政府还免公路收费，免除的免除的范围是免除的范围是范围是？')
        .fontSize(16)
        .padding({ left: 10, right: 10,top:10 })
        .textAlign(TextAlign.Start)
        .width('90%')


      // Options List (using OptionItem)
      Column() {
        ForEach(
          questions[this.currentQuestionIndex].option,
          (opt: string, index: number) => {
            OptionItem({
              label: String.fromCharCode(65 + index), // A, B, C, D
              text: opt,
              isSelected: this.selectedOption === String.fromCharCode(65 + index),
              isCorrect: String.fromCharCode(65 + index) === questions[this.currentQuestionIndex].answer,
              onSelect: (label: string) => {
                this.selectedOption = label;
                promptAction.showToast({
                  message: `选择了选项 ${label}`,
                  duration: 1500,
                });
              },
            });
          },
          (opt: string, index: number) => String(index)
        )
      }
      .padding({ left: 10, right: 10 })
      .margin({ top: 20 })

      // 底部按钮
      Row() {
        Button() {
          Text('上一题')
            .fontSize(16)
            .fontColor('#F2B771')
        }
        .width(100)
        .height(30)
        .backgroundColor(Color.White)
        .borderRadius(20)
        .border({ width: 1, color: '#F2B771' })
        .onClick(() => this.goToPreviousQuestion())

        Button() {
          Text('下一题')
            .fontSize(16)
            .fontColor('#F2B771')
        }
        .backgroundColor(Color.White)
        .width(100)
        .height(30)
        .borderRadius(20)
        .border({ width: 1, color: '#F2B771' })
        .onClick(() => this.goToNextQuestion())
      }
      .justifyContent(FlexAlign.SpaceAround)
      .alignItems(VerticalAlign.Center)
      .padding(10)
      .width('80%')

    }
    .width('100%')
    .height('100%')
    .backgroundColor(Color.White)
  }

}


