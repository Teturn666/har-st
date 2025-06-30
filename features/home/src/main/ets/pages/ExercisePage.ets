import promptAction from '@ohos.promptAction';
import { QuestionRes } from 'db';
import { HeaderComponent } from '../components/HeaderComponent';
import { NavigationButtons } from '../components/NavigationButtons';
import { OptionList } from '../components/OptionList';
import { ProgressBar } from '../components/ProgressBar';
import { QuestionContent } from '../components/QuestionContent';
import HomeConstants from '../Constants/HomeConstants';
import { HomeModel } from '../model/HomeModel';
import { NavQid } from '../model/NavGenericType';

interface questionSelections {
  selectedOption: string;
  selectedOptions: string[];
  hasSubmitted: boolean;
}

const TAG = 'ExercisePage';


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
  @Consume appPathStack: NavPathStack

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

    // 检查是否为2个选项
    if (options.length !== 2) {
      return false;
    }

    // 定义所有可能的判断题选项组合
    const trueFalsePatterns = [
      ['正确', '错误'],
      ['√', '×'],
      ['对', '错'],
      ['Y', 'N'],
      ['A', 'B']// 当选项就是A/B时
    ];

    // 检查选项是否匹配任何一种判断题模式
    return trueFalsePatterns.some(pattern => {
      return (options.includes(pattern[0]) && options.includes(pattern[1])) ||
        (options.includes(pattern[1]) && options.includes(pattern[0]));
    });
  }

  private getTrueFalseCorrectOptionLabel(answer: string): string {
    const currentQuestion = this.questions[this.currentQuestionIndex];
    const options = currentQuestion.option;

    // 如果答案直接是选项标签(A/B)，直接返回
    if (answer === 'A' || answer === 'B') {
      return answer;
    }

    // 定义答案映射关系
    interface AnswerMapping {
      trueValues?: string[];
      falseValues?: string[];
    }

    const answerMappings: AnswerMapping[] = [
      { trueValues: ['正确', '√', '对', 'Y'] },
      { falseValues: ['错误', '×', '错', 'N'] }
    ];

    // 查找答案对应的选项索引
    for (let i = 0; i < options.length; i++) {
      const option = options[i];

      // 检查当前选项是否与答案匹配
      if (option === answer) {
        return String.fromCharCode(65 + i); // 返回A或B
      }

      // 检查答案是否为true类型的值
      if (answerMappings[0].trueValues?.includes(answer) &&
      answerMappings[0].trueValues.includes(option)) {
        return String.fromCharCode(65 + i);
      }

      // 检查答案是否为false类型的值
      if (answerMappings[1].falseValues &&
      answerMappings[1].falseValues.includes(answer) &&
      answerMappings[1].falseValues.includes(option)) {
        return String.fromCharCode(65 + i);
      }
    }

    return answer;
  }

  private async handleOptionClick(optionLabel: string) {
    if (this.selectedIndex === 0 && !this.hasSubmitted) {
      const currentQuestion = this.questions[this.currentQuestionIndex];

      if (this.isMultipleChoice()) {
        // 多选逻辑保持不变
        if (this.selectedOptions.includes(optionLabel)) {
          this.selectedOptions = this.selectedOptions.filter(opt => opt !== optionLabel);
        } else {
          this.selectedOptions = [...this.selectedOptions, optionLabel];
          const correctAnswers = currentQuestion.answer.split('');

          if (!correctAnswers.includes(optionLabel)) {
            this.hasSubmitted = true;
            await this.saveToWrongTable(currentQuestion, optionLabel);
            this.saveQuestionState();
          } else {
            const allCorrectSelected = correctAnswers.every(ans => this.selectedOptions.includes(ans)) &&
            this.selectedOptions.every(opt => correctAnswers.includes(opt));
            if (allCorrectSelected) {
              this.hasSubmitted = true;
              this.saveQuestionState();
            }
          }
        }
        this.saveQuestionState();
      } else {
        // 单选：设置选项并提交
        this.selectedOption = optionLabel;
        this.hasSubmitted = true;

        // 修复后的答案判断逻辑
        let isCorrect = false;
        let wrongAnswer = optionLabel;

        if (this.isTrueFalseQuestion()) {
          // 判断题：获取正确答案的选项标签
          const correctOptionLabel = this.getTrueFalseCorrectOptionLabel(currentQuestion.answer);
          isCorrect = optionLabel === correctOptionLabel;

          // 对于判断题，错误答案记录选项内容而不是标签
          if (!isCorrect) {
            const optionIndex = optionLabel.charCodeAt(0) - 65;
            wrongAnswer = currentQuestion.option[optionIndex];
          }

          // 添加调试日志
          console.log('判断题调试信息:', {
            selectedOption: optionLabel,
            answerInDB: currentQuestion.answer,
            correctOptionLabel: correctOptionLabel,
            selectedContent: currentQuestion.option[optionLabel.charCodeAt(0) - 65],
            isCorrect: isCorrect,
            options: currentQuestion.option
          });
        } else {
          // 普通单选题：比较选项标签与答案
          isCorrect = optionLabel === currentQuestion.answer;
          wrongAnswer = optionLabel;
        }

        if (!isCorrect) {
          await this.saveToWrongTable(currentQuestion, wrongAnswer);
        }
        this.saveQuestionState();
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

  aboutToAppear(): void {
    const res = this.appPathStack.getParamByName(HomeConstants.ROUTER_EXERCISE_LIST) as NavQid[]
    if (res && res.length&& res[0].qid) {
      const params = res[0]
      this.qid = parseInt(params.qid!.toString(), 10);
      console.log(TAG, 'Received qid =' + this.qid);
      if (this.qid > 0) {
        this.getBankQuestionList(this.qid).then(() => {
          this.checkFavoriteStatus(); // 初始化第一题的收藏状态
        });
      }
    }
  }

  build() {
    if (this.questions.length > 0)
    NavDestination() {
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
          List() {
            ListItem() {
              QuestionContent({
                question: this.questions[this.currentQuestionIndex],
                isStarred: this.isQuestionStarred(this.currentQuestionIndex),
                onToggleStar: () => {
                  this.toggleFavorite()
                }
              })
            }

            ListItem() {
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

            ListItem() {
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
    }.hideTitleBar(true)
  }
}

@Builder
function ExercisePageBuilder() {
  ExercisePage()
}