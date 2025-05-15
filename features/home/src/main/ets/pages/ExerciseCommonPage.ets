import router from '@ohos.router';
import promptAction from '@ohos.promptAction';
import { QuestionRes, questionCollectionTable, questionTable,questionWrongTable } from 'db';
import { TitleBar } from 'widget/Index'
import { HomeModel } from '../model/HomeModel';

//模拟考试、错题练习、收藏练习题目共用页面

interface questionSelections {
  selectedOption: string;
  selectedOptions: string[];
  hasSubmitted: boolean;
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

  @State qid: number = -1
  @State homeModel: HomeModel = HomeModel.getInstance()
  @State questionType: string = 'multiple';
  @State questionSelections: Record<number, questionSelections> = {}; // 记录每题选择
  @State favoriteStatus: Record<number, boolean> = {}; // 按 questionID 存储收藏状态


  private questions: QuestionRes[] = [
    {"questionID":1,"qId":1735007905,"question":"在道路等开阔地带开展训练时，应做好（）。","answer":"A","option":["安全警戒","后勤保障","着装","准备活动"],"wrongAnswer":""},
    {"questionID":2, "qId":1735007905,"question":"使用绳索开展高空救援时，绳索应避开（）等高温、尖锐部位。","answer":"AB","option":["墙角","烟火","梁、柱","管线井"],"wrongAnswer":""},
    {"questionID":3,"qId":1735007905,"question":"总队、支队安全助理对灭火救援现场安全员实行统一管理。","answer":"A","option":["正确","错误"],"wrongAnswer":""}
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


  private isMultipleAnswer(question: QuestionRes): boolean {
    return question.answer.includes(',');
  }


  private isMultipleChoice(): boolean {
    const answer = this.questions[this.currentQuestionIndex].answer;
    return answer.length > 1 && /^[A-D]+$/.test(answer);
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
      ForEach(this.questions[this.currentQuestionIndex].option, (item: string, idx: number) => {
        Row() {
          Text(this.getOptionLabel(idx))
            .width(30)
            .height(30)
            .textAlign(TextAlign.Center)
            .fontSize(16)
            .fontColor('#000000')
            .borderRadius(15)
            .backgroundColor(
              this.selectedIndex === 1
                ? (this.questions[this.currentQuestionIndex].answer.includes(this.getOptionLabel(idx)) ? '#DFF5E3' :
                '#F2F2F2')
                : (this.hasSubmitted
                ? (this.questions[this.currentQuestionIndex].answer.includes(this.getOptionLabel(idx))
                  ? '#DFF5E3'
                  : (this.isMultipleChoice()
                    ? (this.selectedOptions.includes(this.getOptionLabel(idx)) ? '#FDECEC' : '#F2F2F2')
                    : (this.selectedOption === this.getOptionLabel(idx) ? '#FDECEC' : '#F2F2F2')))
                : (this.isMultipleChoice()
                  ? (this.selectedOptions.includes(this.getOptionLabel(idx)) ? '#B3E5FC' : '#F2F2F2')
                  : (this.selectedOption === this.getOptionLabel(idx) ? '#E0E0E0' : '#F2F2F2')))
            )
            .margin({ right: 10 })
          Text(item)
            .fontSize(16)
            .padding(10)
            .width('80%')
            .borderRadius(8)
            .backgroundColor(
              this.selectedIndex === 1
                ? (this.questions[this.currentQuestionIndex].answer.includes(this.getOptionLabel(idx)) ? '#DFF5E3' :
                '#F2F2F2')
                : (this.hasSubmitted
                ? (this.questions[this.currentQuestionIndex].answer.includes(this.getOptionLabel(idx))
                  ? '#DFF5E3'
                  : (this.isMultipleChoice()
                    ? (this.selectedOptions.includes(this.getOptionLabel(idx)) ? '#FDECEC' : '#F2F2F2')
                    : (this.selectedOption === this.getOptionLabel(idx) ? '#FDECEC' : '#F2F2F2')))
                : (this.isMultipleChoice()
                  ? (this.selectedOptions.includes(this.getOptionLabel(idx)) ? '#B3E5FC' : '#F2F2F2')
                  : (this.selectedOption === this.getOptionLabel(idx) ? '#E0E0E0' : '#F2F2F2')))
            )
        }
        .onClick(() => this.handleOptionClick(this.getOptionLabel(idx)))
        .margin({ top: 12, left: 16, right: 16 })
      })

    }
    .width('100%')
    .height('100%')
    .backgroundColor(Color.White)
  }

  private async handleOptionClick(optionLabel: string) {

    if (this.selectedIndex === 0 && !this.hasSubmitted) {
      const currentQuestion = this.questions[this.currentQuestionIndex];
      if (this.isMultipleChoice()) {
        // 多选：切换选项状态
        if (this.selectedOptions.includes(optionLabel)) {
          this.selectedOptions = this.selectedOptions.filter(opt => opt !== optionLabel);
        } else {
          this.selectedOptions = [...this.selectedOptions, optionLabel];
          const correctAnswers = currentQuestion.answer.split('');

          // 检查是否选择了错误选项
          if (!correctAnswers.includes(optionLabel)) {
            this.hasSubmitted = true;
            setTimeout((): void => this.goToNextQuestion(), 2000);
            promptAction.showToast({ message: '回答错误', duration: 1500 });
            // 插入错题表
            // await this.saveToWrongTable(currentQuestion, optionLabel);
            // this.saveQuestionState(); // 记录错误提交状态
          } else {
            // 检查是否选中了全部正确答案
            const allCorrectSelected = correctAnswers.every(ans => this.selectedOptions.includes(ans)) &&
            this.selectedOptions.every(opt => correctAnswers.includes(opt));
            if (allCorrectSelected) {
              this.hasSubmitted = true;
              setTimeout((): void => this.goToNextQuestion(), 2000);
              promptAction.showToast({ message: '回答正确', duration: 1500 });
              this.saveQuestionState(); // 记录正确提交状态
            }
          }
        }
        this.saveQuestionState(); // 记录多选过程中的选择
      } else {
        // 单选：设置选项并提交
        this.selectedOption = optionLabel;
        this.hasSubmitted = true;
        setTimeout((): void => this.goToNextQuestion(), 2000);
        const isCorrect = optionLabel === currentQuestion.answer;
        promptAction.showToast({
          message: isCorrect ? '回答正确' : '回答错误',
          duration: 1500
        });
        if (!isCorrect) {
          // 插入错题表
          await this.saveToWrongTable(currentQuestion, optionLabel);
        }
        this.saveQuestionState(); // 记录单选提交状态
      }
    }
  }

  // 在 ExercisePage 组件内添加以下方法
  private async saveToWrongTable(question: QuestionRes, wrongAnswer: string) {
    try {
      let questionDb = new QuestionRes();
      questionDb.qId = question.qId;
      questionDb.question = question.question;
      questionDb.answer = question.answer;
      questionDb.option = question.option;
      questionDb.wrongAnswer = wrongAnswer;

      await questionWrongTable.insertDataAwait(questionDb);
      this.homeModel.getWrongQuestionList(question.qId)

    } catch (err) {
      console.error('插入错题表失败:', err);
      promptAction.showToast({ message: '保存错题失败', duration: 1500 });
    }
  }

  private async saveQuestionState() {
    // 保存当前题目的选择状态到内存
    this.questionSelections[this.currentQuestionIndex] = {
      selectedOption: this.selectedOption,
      selectedOptions: [...this.selectedOptions],
      hasSubmitted: this.hasSubmitted
    };
    console.log('Saved state for question', this.currentQuestionIndex,
      this.questionSelections[this.currentQuestionIndex]);
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