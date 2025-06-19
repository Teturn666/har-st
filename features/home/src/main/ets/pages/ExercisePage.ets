import { router } from '@kit.ArkUI'
import promptAction from '@ohos.promptAction';
import { QuestionRes } from 'db';
import HomeConstants from '../Constants/HomeConstants';
import { HomeModel } from '../model/HomeModel';

import('./ExerciseCommonPage')

interface questionSelections {
  selectedOption: string;
  selectedOptions: string[];
  hasSubmitted: boolean;
}

const TAG = 'ExercisePage';

@Entry({ routeName: 'exercisePage' })
@Component
struct ExercisePage {
  @State qid: number = -1
  @State homeModel: HomeModel = HomeModel.getInstance()
  @State questions: QuestionRes[] = [];
  @State selectedIndex: number = 0; // 0 答题, 1 背题
  @State currentQuestionIndex: number = 0; // 当前问题索引
  @State currentProgress: number = 1; // 目前进度
  @State isStarred: boolean = false; //
  @State questionType: string = 'multiple';
  @State hasSubmitted: boolean = false;
  @State selectedOption: string = ''; // 单选
  @State selectedOptions: string[] = []; // 多选
  @State questionSelections: Record<number, questionSelections> = {}; // 记录每题选择
  @State totalProgress: number = this.questions.length;
  @State favoriteStatus: Record<number, boolean> = {}; // 按 questionID 存储收藏状态

  private async saveToWrongTable(question: QuestionRes, wrongAnswer: string) {
    try {
      const existingWrongQuestions = await this.homeModel.getWrongQuestionList(question.qId);
      const isAlreadyInWrongTable = existingWrongQuestions.some(item => item.questionID === question.questionID);
      if (isAlreadyInWrongTable) {
        console.log(`题目 ${question.questionID} 已存在于错题表中`);
        return;
      }

      // 如果题目不在错题表中，继续插入
      let questionDb = new QuestionRes();
      questionDb.qId = question.qId;
      questionDb.question = question.question;
      questionDb.answer = question.answer;
      questionDb.option = question.option;
      questionDb.wrongAnswer = wrongAnswer;
      questionDb.questionID = question.questionID;
      await this.homeModel.WrongInserDataAwait(questionDb);
      this.homeModel.getWrongQuestionList(question.qId);
      console.log(`题目 ${question.questionID} 已添加到错题表`);

    } catch (err) {
      console.error('插入错题表失败:', err);
      promptAction.showToast({ message: '保存错题失败', duration: 1500 });
    }
  }

  //判断是否为判断题的方法
  private isTrueFalseQuestion(): boolean {
    const currentQuestion = this.questions[this.currentQuestionIndex];
    const options = currentQuestion.option;
    return options.length === 2 &&
    options.includes('正确') &&
    options.includes('错误');
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
            // 插入错题表
            await this.saveToWrongTable(currentQuestion, optionLabel);
            this.saveQuestionState();
          } else {
            // 检查是否选中了全部正确答案
            const allCorrectSelected = correctAnswers.every(ans => this.selectedOptions.includes(ans)) &&
            this.selectedOptions.every(opt => correctAnswers.includes(opt));
            if (allCorrectSelected) {
              this.hasSubmitted = true;
              this.saveQuestionState(); // 记录正确提交状态
            }
          }
        }
        this.saveQuestionState(); // 记录多选过程中的选择
      } else {
        // 单选：设置选项并提交
        this.selectedOption = optionLabel;
        this.hasSubmitted = true;

        // 修复：根据题目类型判断答案
        let isCorrect = false;

        if (this.isTrueFalseQuestion()) {
          // 判断题：比较选项内容与答案
          const optionIndex = optionLabel.charCodeAt(0) - 65; // A=0, B=1
          const selectedContent = currentQuestion.option[optionIndex];
          isCorrect = selectedContent === currentQuestion.answer;
        } else {
          // 单选题：比较选项标签与答案
          isCorrect = optionLabel === currentQuestion.answer;
        }

        if (!isCorrect) {
          // 插入错题表时，对于判断题传递选项内容
          const wrongAnswer = this.isTrueFalseQuestion()
            ? currentQuestion.option[optionLabel.charCodeAt(0) - 65]
            : optionLabel;
          await this.saveToWrongTable(currentQuestion, wrongAnswer);
        }
        this.saveQuestionState(); // 记录单选提交状态
      }
    }
  }

  private isMultipleChoice(): boolean {
    const answer = this.questions[this.currentQuestionIndex].answer;
    return answer.length > 1 && /^[A-D]+$/.test(answer);
  }

  private resetQuestionState() {
    this.selectedOption = '';
    this.selectedOptions = [];
    this.hasSubmitted = false;
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

  private restoreQuestionState() {
    const state = this.questionSelections[this.currentQuestionIndex];
    if (state) {
      this.selectedOption = state.selectedOption;
      this.selectedOptions = [...state.selectedOptions];
      this.hasSubmitted = state.hasSubmitted;
      console.log('Restored state for question', this.currentQuestionIndex, state);
    } else {
      this.resetQuestionState();
    }
    this.checkFavoriteStatus(); // 恢复当前题目的收藏状态
  }

  // 检查收藏状态
  private async checkFavoriteStatus() {
    const currentQuestion = this.questions[this.currentQuestionIndex];
    const questionID = currentQuestion.questionID;
    try {
      const existedList = await this.homeModel.getCollectionQuestionList(currentQuestion.qId);
      const isCollected = existedList.some(item => item.questionID === questionID)
      this.favoriteStatus[questionID] = isCollected;
    } catch (err) {
      console.error('检查收藏状态失败:', err);
      this.favoriteStatus[questionID] = false;
    }
  }

  private async toggleFavorite() {
    const currentQuestion: QuestionRes = this.questions[this.currentQuestionIndex];
    const questionID = currentQuestion.questionID;
    try {
      const result = await this.homeModel.getCollectionQuestionList(currentQuestion.qId)
      const isFavorited = result.some(item => item.questionID === questionID);

      if (isFavorited) {
        // 取消收藏
        await this.homeModel.deleteDataByQuestionID(questionID);
        this.favoriteStatus[questionID] = false;
        console.log(`取消收藏，题目 ${questionID} 已从收藏表移除`);
        promptAction.showToast({ message: '已取消收藏', duration: 1500 });
      } else {
        // 添加收藏
        let questionDb = new QuestionRes();
        questionDb.qId = currentQuestion.qId;
        questionDb.question = currentQuestion.question;
        questionDb.answer = currentQuestion.answer;
        questionDb.option = currentQuestion.option;
        questionDb.wrongAnswer = currentQuestion.wrongAnswer || '';
        questionDb.questionID = questionID;
        await this.homeModel.collectInserDataAwait(questionDb);
        this.favoriteStatus[questionID] = true;
        console.log(`添加收藏，题目 ${questionID} 已添加到收藏表`);
        promptAction.showToast({ message: '收藏成功', duration: 1500 });
      }
    } catch (err) {
      console.error('收藏操作失败:', err);
      promptAction.showToast({ message: '收藏操作失败', duration: 1500 });
    }
  }

  // 题目列表获取
  async getBankQuestionList(qid: number): Promise<void> {
    try {
      const list = await this.homeModel.getBankQuestionList(qid);
      if (list.length > 0) {
        this.questions = list;
        this.totalProgress = list.length;
        this.currentQuestionIndex = 0;
        this.currentProgress = 1;
        this.questionSelections = {};
        this.favoriteStatus = {};
        this.resetQuestionState();
        // 批量检查收藏状态
        const existedList = await this.homeModel.getCollectionQuestionList(qid);
        list.forEach((question) => {
          this.favoriteStatus[question.questionID] = existedList.some(item => item.questionID === question.questionID);
        });
      } else {
        promptAction.showToast({ message: '暂无题目数据', duration: 2000 });
      }
    } catch (err) {
      console.error('获取题目失败:', err);
      promptAction.showToast({ message: '题目加载失败', duration: 2000 });
    }
  }

  private resetProgress() {
    promptAction.showDialog({
      title: '提示',
      message: '重置进度后将从第一题重新开始练习',
      buttons: [
        { text: '取消', color: '#666666' },
        { text: '确定', color: '#d2a129' },
      ],
    }).then((data) => {
      if (data.index === 1) {
        this.currentProgress = 1;
        this.currentQuestionIndex = 0;
        this.questionSelections = {};
        this.resetQuestionState();
        promptAction.showToast({ message: '进度已重置', duration: 1500 });
      }
    });
  }

  private goToPreviousQuestion() {
    if (this.currentQuestionIndex > 0) {
      this.currentQuestionIndex--;
      this.currentProgress = this.currentQuestionIndex + 1;
      this.restoreQuestionState();
    } else {
      promptAction.showToast({ message: '已经是第一题', duration: 1500 });
    }
  }

  private goToNextQuestion() {
    if (this.currentQuestionIndex < this.questions.length - 1) {
      this.currentQuestionIndex++;
      this.currentProgress = this.currentQuestionIndex + 1;
      this.restoreQuestionState();
    } else {
      promptAction.showToast({ message: '已经是最后一题', duration: 1500 });
    }
  }

  isQuestionStarred(index: number): boolean {
    const question = this.questions[index];
    return this.favoriteStatus[question.questionID] || false;
  }

  build() {
    if (this.questions.length > 0)
    Column() {
      HeaderComponent({
        qid: this.qid,
        selectedIndex: this.selectedIndex,
        onModeChange: (index: number) => {
          this.selectedIndex = index;
        }
      })


      // 进度条部分
      ProgressBar({
        current: this.currentQuestionIndex + 1,
        total: this.questions.length,
        onReset: () => {
          this.resetProgress()
        }
      })

      if (this.questions.length > 0) {
        List(){
          ListItem(){
            QuestionContent({
              question: this.questions[this.currentQuestionIndex],
              isStarred: this.isQuestionStarred(this.currentQuestionIndex),
              onToggleStar: () => {
                this.toggleFavorite()
              }
            })
          }
          ListItem(){
            OptionList({
              options: this.questions[this.currentQuestionIndex].option,
              selectedOptions: this.selectedOptions,
              selectedOption: this.selectedOption,
              hasSubmitted: this.hasSubmitted,
              isMultipleChoice: this.isMultipleChoice(),
              correctAnswers: this.questions[this.currentQuestionIndex].answer,
              isReviewMode: this.selectedIndex === 1,
              onOptionClick: (option) => {
                this.handleOptionClick(option)
              }
            })
          }
          ListItem(){
            NavigationButtons({
              canGoPrevious: this.currentQuestionIndex > 0,
              canGoNext: this.currentQuestionIndex < this.questions.length - 1,
              onPrevious: () => {
                this.goToPreviousQuestion()
              },
              onNext: () => {
                this.goToNextQuestion()
              }
            })
          }
        }
        .width('100%')
        .layoutWeight(1)
      }
    }
    .width('100%')
    .height('100%')
    .backgroundColor(Color.White)
  }

  aboutToAppear(): void {
    const params = router.getParams() as Record<string, string>;
    if (params.qid) {
      this.qid = parseInt(params.qid, 10);
    }
    console.log(TAG, 'Received qid =' + this.qid);
    if (this.qid > 0) {
      this.getBankQuestionList(this.qid).then(() => {
        this.checkFavoriteStatus(); // 初始化第一题的收藏状态
      });
    }
  }
}


@Component
struct HeaderComponent {
  @Prop selectedIndex: number = 0;
  @Prop qid: number = 0;
  onModeChange: (index: number) => void = () => {

  };

  build() {
    Flex({ direction: FlexDirection.Row, alignItems: ItemAlign.Center }) {
      Image($r('app.media.ic_back'))
        .objectFit(ImageFit.Contain)
        .size({ width: $r('app.float.float_48vp'), height: $r('app.float.float_48vp') })
        .margin({ left: 15, right: 75 })
        .align(Alignment.TopStart)
        .onClick(() => {
          router.back()
        })

      Flex({ direction: FlexDirection.Row, alignItems: ItemAlign.Center }) {
        Button() {
          Row() {
            Button('答题')
              .fontColor(this.selectedIndex === 0 ? '#FFFFFF' : '#d2a129')
              .fontSize($r('app.float.font_size_12fp'))
              .border({ width: 1, color: '#d2a129' })
              .width(60)
              .height(28)
              .backgroundColor(this.selectedIndex === 0 ? '#d2a129' : '#FFFFFF')
              .borderRadius(6)
              .padding({ left: 12, right: 12 })
              .onClick(() => {
                this.onModeChange(0);
                promptAction.showToast({ message: '切换到答题' });
              })
            Button('背题')
              .fontColor(this.selectedIndex === 1 ? '#FFFFFF' : '#d2a129')
              .fontSize($r('app.float.font_size_12fp'))
              .border({ width: 1, color: '#d2a129' })
              .width(60)
              .height(28)
              .backgroundColor(this.selectedIndex === 1 ? '#d2a129' : '#FFFFFF')
              .borderRadius(6)
              .padding({ left: 12, right: 12 })
              .onClick(() => {
                this.onModeChange(1);
                promptAction.showToast({ message: '切换到背题' });
              })
          }
          .justifyContent(FlexAlign.SpaceBetween)
          .alignItems(VerticalAlign.Center)
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
            router.pushNamedRoute({
              name: HomeConstants.ROUTER_EXERCISE_COMMON_LIST,
              params: {
                practiceMode: 1,
                qid: this.qid
              }
            }, router.RouterMode.Single)
          })
      }
    }
  }
}

@Component
export struct ProgressBar {
  @Prop current: number;
  @Prop total: number;
  onReset: () => void = () => {
  };

  build() {
    Flex({ direction: FlexDirection.Row, justifyContent: FlexAlign.SpaceBetween, alignItems: ItemAlign.Center }) {
      Progress({
        type: ProgressType.Linear,
        value: this.current,
        total: this.total
      })
        .color(Color.Orange)
        .width('60%')
        .height($r('app.float.float_16vp'))
        .backgroundColor($r('app.color.c_dadada'))
        .style({ strokeWidth: 15 })

      Text(`${this.current}/${this.total}`)
        .fontSize($r('app.float.font_size_12fp'))
        .fontColor(Color.Black)

      Text('重置进度')
        .fontSize($r('app.float.font_size_12fp'))
        .onClick(() => this.onReset())
    }
    .backgroundColor($r('app.color.c_f5f3f4'))
    .borderRadius(8)
    .width('90%')
    .height($r('app.float.float_50vp'))
    .margin({ top: 10, left: 15, right: 15 })
    .padding(10)
  }
}

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

  private getOptionBackgroundColor(idx: number): ResourceStr {
    const optionLabel = String.fromCharCode(65 + idx);
    const isSelected = this.isMultipleChoice
      ? this.selectedOptions.includes(optionLabel)
      : this.selectedOption === optionLabel;

    let isCorrect = false;
    if (this.correctAnswers.includes('正确') || this.correctAnswers.includes('错误')) {
      const optionContent = this.options[idx];
      isCorrect = optionContent === this.correctAnswers;
    } else {
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

@Component
export struct NavigationButtons {
  @Prop canGoPrevious: boolean;
  @Prop canGoNext: boolean;
  onPrevious: () => void = () => {
  };
  onNext: () => void = () => {
  };

  build() {
    Row() {
      // 只有当canGoPrevious为true时才显示上一题按钮
      if (this.canGoPrevious) {
        Button() {
          Text('上一题')
            .fontSize($r('app.float.font_size_16fp'))
            .fontColor($r('app.color.c_F2B771'))
        }
        .width(100)
        .height($r('app.float.float_30vp'))
        .backgroundColor(Color.White)
        .borderRadius(20)
        .border({ width: 1, color: $r('app.color.c_F2B771') })
        .margin({left : this.canGoPrevious? 20 : 0})
        .onClick(() => this.onPrevious())
      } else {
        Blank()
      }

      // 只有当canGoNext为true时才显示下一题按钮
      if (this.canGoNext) {
        Button() {
          Text('下一题')
            .fontSize($r('app.float.font_size_16fp'))
            .fontColor($r('app.color.c_F2B771'))
        }
        .backgroundColor(Color.White)
        .width(100)
        .height($r('app.float.float_30vp'))
        .borderRadius(20)
        .border({ width: 1, color: $r('app.color.c_F2B771') })
        .margin({right : this.canGoNext? 20 : 0})
        .onClick(() => this.onNext())
      } else {
        Blank()
      }
    }
    .justifyContent(FlexAlign.SpaceBetween)
    .alignItems(VerticalAlign.Center)
    .padding(10)
    .width('100%')
    .margin({ top: 18, bottom: 20 })
  }
}