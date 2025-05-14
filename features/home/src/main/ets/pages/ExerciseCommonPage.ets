import router from '@ohos.router';
import promptAction from '@ohos.promptAction';
import { QuestionRes } from 'db';
import { TitleBar } from 'widget/Index'

//模拟考试、错题练习、收藏练习题目共用页面
interface OptionStyle {
  bg: string;
  text: string;
  border: string;
}

@Entry({routeName:"exerciseCommonPage"})
@Component
struct ExerciseCommonPage {
  @State selectedIndex: number = 0;
  @State currentQuestionIndex: number = 0;
  @State currentProgress: number = 1;
  @State isStarred: boolean = false;
  @State selectedOption: string = '';
  @State hasSubmitted: boolean = false;
  @State selectedOptions: string[] = [];

  @State practicetest: boolean = true; //模拟考试
  @State errorpractice: boolean = false; //错题练习
  @State collectexercises: boolean = false;//收藏练习

  private questions: QuestionRes[] = [
    {
      qId: 1,
      question: "根据收费公路车辆通行费减免政策，政府还免公路收费，免除的范围是？",
      option: ["30", "25", "15", "10"],
      answer: "C",
      wrongAnswer: ""
    },
    {
      qId: 1004,
      question: "地球是平的吗？",
      option: ["是", "不是"],
      answer: "不是",
      wrongAnswer: ""
    },
    // {
    //   qId: 1002,
    //   question: "下列属于常见交通标志的是？",
    //   option: ["禁令标志", "警告标志", "指示标志", "导航标志"],
    //   answer: "禁令标志, 警告标志, 指示标志",
    //   wrongAnswer: ""
    // },
    //
    // // 新增题目
    // {
    //   qId: 1005,
    //   question: "党的最高理想和最终目标是？",
    //   option: ["实现共产主义", "建设小康社会", "实现现代化", "发展经济"],
    //   answer: "A",
    //   wrongAnswer: ""
    // },
    // {
    //   qId: 1006,
    //   question: "中华人民共和国国歌是？",
    //   option: ["义勇军进行曲", "没有共产党就没有新中国", "歌唱祖国", "东方红"],
    //   answer: "A",
    //   wrongAnswer: ""
    // },
    // {
    //   qId: 1007,
    //   question: "四个全面战略布局不包括以下哪项？",
    //   option: ["全面建成小康社会", "全面深化改革", "全面依法治国", "全面发展教育"],
    //   answer: "D",
    //   wrongAnswer: ""
    // },
    // {
    //   qId: 1008,
    //   question: "社会主义核心价值观中的国家层面价值是？",
    //   option: ["富强、民主、文明、和谐", "自由、平等、公正、法治", "爱国、敬业、诚信、友善", "和平、发展、公平、正义"],
    //   answer: "A",
    //   wrongAnswer: ""
    // },
    // {
    //   qId: 1009,
    //   question: "下列哪项不属于党的十九大提出的新时代中国特色社会主义基本方略？",
    //   option: ["坚持党的全面领导", "坚持依法治国", "坚持文化自信", "坚持资本主义发展方向"],
    //   answer: "D",
    //   wrongAnswer: ""
    // }
  ];
  @State totalProgress: number = this.questions.length;


  // 返回选项对应字母
  private getOptionLabel(index: number): string {
    return String.fromCharCode(65 + index); // 'A', 'B', ...
  }


  private goToPreviousQuestion() {
    if (this.currentQuestionIndex > 0) {
      this.currentQuestionIndex--;
      this.selectedOption = '';
      this.selectedOptions = [];
      this.hasSubmitted = false;
      this.currentProgress = this.currentQuestionIndex + 1;
    } else {
      promptAction.showToast({ message: '已经是第一题', duration: 1500 });
    }
  }

  private goToNextQuestion() {
    if (this.currentQuestionIndex < this.questions.length - 1) {
      this.currentQuestionIndex++;
      this.selectedOption = '';
      this.selectedOptions = [];
      this.hasSubmitted = false;
      this.currentProgress = this.currentQuestionIndex + 1;
    } else {
      promptAction.showToast({ message: '已经是最后一题', duration: 1500 });
    }
  }

  private getOptionStyle(label: string): OptionStyle {
    let question = this.questions[this.currentQuestionIndex];
    let isCorrect = question.answer.includes(label);
    let isSelected = this.selectedOptions.indexOf(label) !== -1 || this.selectedOption === label;

    if (this.hasSubmitted) {
      if (isCorrect) {
        return {
          bg: '#DFF5E3',
          text: '#4CAF50',
          border: '#4CAF50'
        };
      } else if (isSelected) {
        return {
          bg: '#FDECEC',
          text: '#F4336',
          border: '#F4336'
        };
      } else {
        return {
          bg: '#F3F3F3',
          text: '#9E9E9E',
          border: '#9E9E9E'
        };
      }
    } else {
      if (isSelected) {
        return {
          bg: '#E3F2FD',
          text: '#42A5F5',
          border: '#42A5F5'
        };
      } else {
        return {
          bg: '#F3F3F3',
          text: '#9E9E9E',
          border: '#9E9E9E'
        };
      }
    }
  }

  private isMultipleAnswer(question: QuestionRes): boolean {
    return question.answer.includes(',');
  }



  build() {
    Column() {
      // 头部
      TitleBar({
        title: '二十大党建知识竞赛', backClick: () => {
          router.back()
        }
      })
        .width('100%')

      // 进度条部分
      Flex({ direction: FlexDirection.Column, justifyContent: FlexAlign.SpaceBetween, alignItems: ItemAlign.Start }) {

        Row(){
          Progress({
            type: ProgressType.Linear,
            value: this.currentProgress,
            total: this.totalProgress,
          })
            .color(Color.Orange)
            .width(this.errorpractice || this.collectexercises ? '90%' : '100%')
            .height(16)
            .backgroundColor('#dadada')
            .style({ strokeWidth: 15 })

          if(this.collectexercises || this.errorpractice)
                 Text('清空')
                    .fontSize(12)
                    .fontColor('#F2B771')
                   .margin({left:10})
                    .onClick(() => {

                    })

        }
        .width('100%')


        Row(){
          Image($r('app.media.ic_clock'))
            .width(16)
            .height(16)
          Text("4:00")
            .fontColor('#F2B771')
            .fontSize(12)
            .margin({left:8})

          Blank()
          Text(`${this.currentProgress}/${this.totalProgress}`)
            .fontSize(12)
            .fontColor(Color.Black)


        }
        .width(this.errorpractice || this.collectexercises ? '90%' : '100%')
        .margin({top:8})
        .justifyContent(FlexAlign.SpaceBetween)


      }
      .backgroundColor('#f5f3f4')
      .borderRadius(8)
      .width('90%')
      .height(50)
      .margin({ top: 10 })
      .padding(10)

      // 内容部分
      Row() {
        Image(
          this.questions[this.currentQuestionIndex].answer.includes(',') ?
          $r('app.media.ic_mu') :
            ((this.questions[this.currentQuestionIndex].answer === '是' || this.questions[this.currentQuestionIndex].answer === '不是') ?
            $r('app.media.ic_es') :
            $r('app.media.ic_ch'))
        )
          .height(24)
          .objectFit(ImageFit.Cover)
        Blank()

        if(this.practicetest)
        Image(this.isStarred ? $r('app.media.stared') : $r('app.media.star'))
          .width(18)
          .height(18)
          .onClick(() => {
            this.isStarred = !this.isStarred;
            promptAction.showToast({
              message: this.isStarred ? '已收藏' : '取消收藏',
              duration: 2000
            });
          })
          .margin({ right: 5 })

        if(this.practicetest)
        Text(this.isStarred ? "已收藏" : "收藏")
          .fontSize(12)

        if(this.errorpractice)
          Image($r('app.media.ic_del'))
            .width(18)
            .height(18)
            .onClick(() => {

            })
            .margin({ right: 5 })

        if(this.errorpractice)
          Text("移除")
            .fontColor('#F2B771')
            .fontSize(12)

      }
      .justifyContent(FlexAlign.SpaceBetween)
      .padding(10)
      .backgroundColor(Color.White)
      .borderRadius(8)
      .margin({ top: 20 })
      .width('90%')


      // 问题描述
      Text(this.questions[this.currentQuestionIndex].question)
        .fontSize(16)
        .padding({ left: 10, right: 10,top:10 })
        .textAlign(TextAlign.Start)
        .width('90%')


      // 选项列表
      ForEach(this.questions[this.currentQuestionIndex].option, (items: string, idx: number) => {
        Row() {
          Text(this.getOptionLabel(idx))
            .width(30)
            .height(30)
            .textAlign(TextAlign.Center)
            .fontSize(16)
            .fontColor('#000000')
            .borderRadius(15)
            .backgroundColor(this.getOptionStyle(this.getOptionLabel(idx)).bg)
            .margin({ right: 10 })

          Text(items)
            .fontSize(16)
            .padding(10)
            .width('80%')
            .borderRadius(8)
            .backgroundColor(this.getOptionStyle(this.getOptionLabel(idx)).bg)
        }
        .onClick(() => {
          console.log("查看"+this.questions[this.currentQuestionIndex].option + "---" + items + "===" + idx)
          if (this.hasSubmitted) {
            return;
          }
          // 多选
          if (this.isMultipleAnswer(this.questions[this.currentQuestionIndex])) {
            // 不可变赋值触发渲染
            if (this.selectedOptions.indexOf(this.getOptionLabel(idx)) !== -1) {
              this.selectedOptions = this.selectedOptions.filter(l => l !== this.getOptionLabel(idx));
            } else {
              this.selectedOptions = [...this.selectedOptions, this.getOptionLabel(idx)];
            }
            // 选错后自动提交并跳题
            if (!this.questions[this.currentQuestionIndex].answer.includes(this.getOptionLabel(idx))) {
              this.hasSubmitted = true;
              setTimeout((): void => this.goToNextQuestion(), 2000);
            }
          }
          // 单选
          else {
            this.selectedOption = this.getOptionLabel(idx);
            this.hasSubmitted = true;
            setTimeout((): void => this.goToNextQuestion(), 2000);
          }
        })
        .margin({ top: 12, left: 16, right: 16 })
      })

    }
    .width('100%')
    .height('100%')
    .backgroundColor(Color.White)
  }

}



// 底部按钮
// Row() {
//   Button() {
//     Text('上一题')
//       .fontSize(16)
//       .fontColor('#F2B771')
//   }
//   .width(100)
//   .height(30)
//   .backgroundColor(Color.White)
//   .borderRadius(20)
//   .border({ width: 1, color: '#F2B771' })
//   .onClick(() => this.goToPreviousQuestion())
//
//   Button() {
//     Text('下一题')
//       .fontSize(16)
//       .fontColor('#F2B771')
//   }
//   .backgroundColor(Color.White)
//   .width(100)
//   .height(30)
//   .borderRadius(20)
//   .border({ width: 1, color: '#F2B771' })
//   .onClick(() => this.goToNextQuestion())
// }
// .justifyContent(FlexAlign.SpaceAround)
// .alignItems(VerticalAlign.Center)
// .padding(10)
// .width('80%')
// .margin({top:18})

// Image(this.isStarred ? $r('app.media.stared') : $r('app.media.star'))
//   .width(18)
//   .height(18)
//   .onClick(() => {
//     this.isStarred = !this.isStarred; // 切换收藏状态
//     promptAction.showToast({
//       message: this.isStarred ? '已收藏' : '取消收藏',
//       duration: 2000
//     });
//   })
//   .margin({ right: 5 })

// Text(this.isStarred ? "已收藏" : "收藏")
//   .fontSize(12)