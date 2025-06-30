import { TitleBar } from 'widget/Index';
import { promptAction, router } from '@kit.ArkUI';
import { QuestionRes } from 'db';
import HomeConstants from '../Constants/HomeConstants';
import { HomeModel } from '../model/HomeModel';
import { DetailParams, NavQid } from '../model/NavGenericType';


@Component
struct ExerciseDetailsPage {
  @State title: string = ''; // 题目标题
  @State correctCount: number = 0; // 正确题数
  @State wrongCount: number = 0; // 错误题数
  @State timeSpent: string = '00:00'; // 花费时间
  @State isLoading: boolean = true;
  @State questions: QuestionRes[] = [];
  @State typepage: number = -1; //模拟考试 1 错题练习 2 收藏练习 3
  @State backindex: number = 2; //返回的页数
  @State isBankData: boolean = false;
  @Consume appPathStack: NavPathStack

  onBackPress(): boolean | void {
    this.quitRouter()
    return true;
  }

  aboutToAppear(): void {
    const res = this.appPathStack.getParamByName(HomeConstants.ROUTER_EXERCISE_DETAILS_LIST) as DetailParams[]
    if (res && res.length) {
      const params = res[0]
      this.backindex = params.backIndex || 2;
      this.typepage = params.typePage;
      this.title = params.title || '未知题库';
      this.correctCount = params.correctCount || 0;
      this.wrongCount = params.wrongCount || 0;
      this.timeSpent = params.timeSpent || '00:00';
      this.questions = params.questions || [];
      this.isBankData = params.isBankData;
      console.log("返回的backindex：" + JSON.stringify(this.isBankData))
      setTimeout(() => {
        console.log('两秒后执行');
        this.isLoading = false;
      }, 2000);
    } else {
      setTimeout(() => {
        console.log('两秒后执行');
        this.isLoading = false;
      }, 2000);
      promptAction.showToast({ message: '未接收到练习数据', duration: 2000 });
      this.appPathStack.pop()
    }
  }

  private continueRouter() {
    this.appPathStack.pushPathByName(HomeConstants.ROUTER_EXERCISE_COMMON_LIST,{
      practiceMode: this.typepage,
      qid: this.questions[0]?.qId || -1,
      backIndex: this.backindex += 2
    } as NavQid )
    // router.pushNamedRoute({
    //   name: HomeConstants.ROUTER_EXERCISE_COMMON_LIST,
    //   params: {
    //     practiceMode: this.typepage,
    //     qid: this.questions[0]?.qId || -1,
    //     backindex: this.backindex += 2
    //   }
    // });
  }

  quitRouter() {
    let index = Number(router.getLength()) - this.backindex;
    router.back(index, {
      refresh: "1",
      type: this.typepage.toString()
    });
  }

  private showDialog(tContent: string) {
    promptAction.showDialog({
      title: '温馨提示',
      message: `${tContent}`,
      buttons: [
        { text: '我知道了', color: '#d2a129' },
      ],
    }).then((data) => {
      this.quitRouter()
    });
  }

  // 判断是否为判断题
  private isTrueFalseQuestion(question: QuestionRes): boolean {
    const options = question.option;
    return options.length === 2 &&
    options.includes('正确') &&
    options.includes('错误');
  }

  // 将判断题的答案内容转换为选项标签
  private convertAnswerToLabel(question: QuestionRes, answer: string): string {
    if (this.isTrueFalseQuestion(question)) {
      // 判断题：将"正确"/"错误"转换为"A"/"B"
      const correctIndex = question.option.findIndex(option => option === answer);
      if (correctIndex !== -1) {
        return String.fromCharCode(65 + correctIndex);
      }
    }
    return answer; // 非判断题直接返回原答案
  }

  // 将用户答案转换为显示格式
  private convertUserAnswerToLabel(question: QuestionRes, userAnswer: string): string {
    if (!userAnswer || userAnswer === '未答') {
      return '未答';
    }

    if (this.isTrueFalseQuestion(question)) {
      // 判断题：如果用户答案是选项内容，转换为标签
      if (userAnswer === '正确' || userAnswer === '错误') {
        const answerIndex = question.option.findIndex(option => option === userAnswer);
        if (answerIndex !== -1) {
          return String.fromCharCode(65 + answerIndex);
        }
      }
      // 如果用户答案已经是标签格式（A、B），直接返回
      if (/^[A-Z]$/.test(userAnswer)) {
        return userAnswer;
      }
    }

    return userAnswer; // 非判断题或其他情况直接返回
  }

  private isAnswerCorrect(question: QuestionRes, userAnswer: string): boolean {
    if (!userAnswer || userAnswer === '未答') {
      return false;
    }

    if (this.isTrueFalseQuestion(question)) {
      // 判断题：需要特殊处理
      const correctAnswerLabel = this.convertAnswerToLabel(question, question.answer);
      const userAnswerLabel = this.convertUserAnswerToLabel(question, userAnswer);
      return correctAnswerLabel === userAnswerLabel;
    } else if (question.answer.length > 1 && userAnswer.includes(',')) {
      // 多选题
      const correctAnswers = question.answer
        .split('')
        .sort()
        .join('');

      const userAnswers = userAnswer
        .split(',')
        .map(answer => answer.trim())
        .filter(answer => answer.length > 0)
        .sort()
        .join('');
      return correctAnswers === userAnswers;
    } else {
      // 单选题
      return question.answer === userAnswer;
    }
  }

  build() {
    if (this.isLoading) {
      Column() {
        Image($r('app.media.ic_lian'))
          .height(24)
          .margin({ top: 58 });
        Image($r('app.media.ic_ok'))
          .width(155)
          .height(155)
          .margin({ top: 68 });
        Text("即将进入练习详情...")
          .fontColor(Color.Grey)
          .fontSize(16)
          .margin({ top: 28 });
      }
      .width('100%')
      .height('100%')
      .justifyContent(FlexAlign.Start)
      .alignItems(HorizontalAlign.Center)
      .backgroundColor(Color.White);
    } else {
      Column() {
        // 头部
        TitleBar({
          title: "练习详情",
          backClick: () => {
            let index = Number(router.getLength()) - this.backindex;
            router.back(index, {
              refresh: "1",
              type: this.typepage.toString()
            });
          }
        })
          .width('100%');

        // 题目信息
        Row() {
          Image($r('app.media.ic_question_bank'))
            .width(18)
            .height(18);
          Text('  题目: ' + this.title)
            .fontColor('#060606')
            .fontSize(14);
        }
        .width('90%')
        .margin({ top: 18, left: 28 });

        // 统计信息
        Column() {
          Row() {
            Text('您答对了')
              .fontColor('#404040')
              .fontSize(14);
            Text(this.correctCount.toString())
              .fontColor('#F75A23')
              .fontSize(14);
            Text('道题目，答错')
              .fontColor('#404040')
              .fontSize(14);
            Text(this.wrongCount.toString())
              .fontColor('#F75A23')
              .fontSize(14);
            Text('道题。')
              .fontColor('#404040')
              .fontSize(14);
          }
          .margin({ top: 8 });

          Row() {
            Text('共花费时间：')
              .fontColor('#404040')
              .fontSize(14);
            Text(this.timeSpent)
              .fontColor('#F75A23')
              .fontSize(14);
          }
          .margin({ top: 8 });
        }
        .padding({ left: 8, top: 8 })
        .margin({ top: 10 })
        .alignItems(HorizontalAlign.Start)
        .width('90%')
        .height(70)
        .backgroundColor('#f3f1f1')
        .borderRadius(8);

        // 内容区域（支持滚动）
        Scroll() {
          Column() {
            ForEach(this.questions, (item: QuestionRes, index: number) => {
              Column() {
                Text(item.question + item.question)// 重复以模拟长文本
                  .fontColor('#333333')
                  .fontSize(12)
                  .margin({ top: 8 });

                Column() {
                  ForEach(item.option, (option: string, idx: number) => {
                    Text(option)
                      .fontColor('#333333')
                      .fontSize(12)
                      .margin({ top: idx === 0 ? 15 : 0 });
                  });
                }
                .width('100%')
                .alignItems(HorizontalAlign.Start);

                Row() {
                  Row() {
                    Text('正确答案：')
                      .fontColor('#333333')
                      .fontSize(14);
                    // Text(item.answer)
                    //   .fontColor(Color.Blue)
                    //   .fontSize(14);
                    Text(this.convertAnswerToLabel(item, item.answer))
                      .fontColor(Color.Blue)
                      .fontSize(14);
                  }
                  .margin({ right: 20 });

                  Row() {
                    Text('您的答案：')
                      .fontColor('#333333')
                      .fontSize(14);
                    Text(item.wrongAnswer || '未答')
                      .fontColor(Color.Red)
                      .fontSize(14);
                  }
                }
                .backgroundColor(this.isAnswerCorrect(item, item.wrongAnswer || '') ? '#ebf4e6' : '#f7e9e9')
                .justifyContent(FlexAlign.SpaceAround)
                .margin({ top: 8 })
                .borderRadius(8)
                .width('100%')
                .height(29);
              }
              .margin({ bottom: 16 });
            });
          }
          .alignItems(HorizontalAlign.Start)
          .justifyContent(FlexAlign.Start)
          .padding({ left: 18, top: 18, right: 18 })
          .width('100%');
        }
        .height('65%')
        .backgroundColor(Color.White)
        .align(Alignment.TopStart);

        // 底部按钮
        Blank()
          .height(20);
        Row() {
          Image($r('app.media.ic_keep_practicing'))
            .width(122)
            .height(40)
            .onClick(() => {
              if (this.typepage === 2) {
                if (this.isBankData) {
                  this.continueRouter()
                } else {
                  this.showDialog("当前没有错题，练习做错的题目将会收录到这里。")
                }
              } else if (this.typepage === 3) {
                if (this.isBankData) {
                  this.continueRouter()
                } else {
                  this.showDialog("暂无收藏，请先去练习或考试中添加。")
                }
              } else {
                this.continueRouter()
              }


            });
          Image($r('app.media.ic_quit_practice'))
            .width(122)
            .height(40)
            .onClick(() => {
              this.quitRouter()
            });
        }
        .justifyContent(FlexAlign.SpaceEvenly)
        .width('100%')
        .height(80)
        .backgroundColor('#ffffff');
      }
      .height('100%')
      .width('100%')
      .backgroundColor(Color.White);
    }
  }
}