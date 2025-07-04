import promptAction from '@ohos.promptAction';
import { BankListRes, QuestionRes } from 'db';
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
  @State bankPage: string = ''
  @Consume appPathStack: NavPathStack
  @State positions: number = -1 // 当前进度位置
  @State bankInfo: BankListRes | null = null; // 存储当前题库信息

  //更新当前进度位置
  private updateCurrentPosition(newPosition: number) {
    this.positions = newPosition;
    console.log(`进度更新: 当前位置 ${this.positions}`);

    // 异步保存进度到数据库
    this.saveProgressToDatabase();
  }

  // 保存进度到数据库
  private async saveProgressToDatabase() {
    if (!this.bankInfo) {
      console.error('题库信息不存在，无法保存进度');
      return;
    }

    try {
      // 更新题库信息中的 position 字段
      const updatedBankInfo: BankListRes = {
        id: this.bankInfo.id,
        qid: this.bankInfo.qid,
        name: this.bankInfo.name,
        desc: this.bankInfo.desc,
        time: this.bankInfo.time,
        url: this.bankInfo.url,
        num: this.bankInfo.num,
        version: this.bankInfo.version,
        position: this.positions, // 更新进度位置
        downloadedState: this.bankInfo.downloadedState,
        bankType: this.bankInfo.bankType,
        NewFlag: this.bankInfo.NewFlag
      };
      // 调用 homeModel 中的更新方法保存到数据库
      await this.homeModel.updateBankPosition(updatedBankInfo);
      console.log(`进度已保存到数据库: qid=${this.qid}, position=${this.positions}`);

    } catch (error) {
      console.error('保存进度失败:', error);
    }
  }

  //从数据库加载进度
  private async loadProgressFromDatabase(): Promise<number> {
    try {
      // 获取当前题库信息
      const bankList = await this.homeModel.getBankListById(this.qid);
      if (bankList && bankList.length > 0) {
        this.bankInfo = bankList[0];
        const savedPosition = this.bankInfo.position || 0;
        console.log(`从数据库加载进度: position=${savedPosition}`);
        return Math.max(0, savedPosition); // 确保不小于0
      }
    } catch (error) {
      console.error('加载进度失败:', error);
    }
    return 0; // 默认从第一题开始
  }

  //从题目数据中恢复之前的答题状态
  private restoreAnsweredStates() {
    this.questions.forEach((question, index) => {
      if (question.wrongAnswer && question.wrongAnswer.trim() !== '') {
        console.log(`恢复第${index + 1}题的答题状态, wrongAnswer: ${question.wrongAnswer}`);

        // 判断是否为多选题
        const isMultiple = this.isMultipleChoiceForQuestion(question);

        if (isMultiple) {
          // 多选题：wrongAnswer可能是单个选项或多个选项
          // 如果wrongAnswer是多个字符，按字符拆分；如果是单个字符，直接使用
          let selectedOptions: string[] = [];
          if (question.wrongAnswer.length > 1 && /^[A-Z]+$/.test(question.wrongAnswer)) {
            // 如果是ABC这样的格式，按字符拆分
            selectedOptions = question.wrongAnswer.split('');
          } else {
            // 如果是单个选项，直接使用
            selectedOptions = [question.wrongAnswer];
          }

          this.questionSelections[index] = {
            selectedOption: '',
            selectedOptions: selectedOptions,
            hasSubmitted: true
          };
        } else {
          // 单选题或判断题：wrongAnswer是单个选项
          let selectedOption = question.wrongAnswer;

          // 对于判断题，如果wrongAnswer是选项内容而不是标签，需要转换为标签
          if (this.isTrueFalseQuestionForQuestion(question)) {
            selectedOption = this.getOptionLabelFromContent(question, question.wrongAnswer);
          }

          this.questionSelections[index] = {
            selectedOption: selectedOption,
            selectedOptions: [],
            hasSubmitted: true
          };
        }
      }
    });
  }

  //判断指定题目是否为多选题
  private isMultipleChoiceForQuestion(question: QuestionRes): boolean {
    const answer = question.answer;
    return answer.length > 1 && /^[A-Z]+$/.test(answer);
  }

  //判断指定题目是否为判断题
  private isTrueFalseQuestionForQuestion(question: QuestionRes): boolean {
    const options = question.option;

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

  //根据选项内容获取选项标签
  private getOptionLabelFromContent(question: QuestionRes, content: string): string {
    const options = question.option;
    for (let i = 0; i < options.length; i++) {
      if (options[i] === content) {
        return String.fromCharCode(65 + i); // 返回A、B、C等
      }
    }
    // 如果找不到匹配的内容，可能传入的就是标签，直接返回
    return content;
  }

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
      let wrongAnswer = optionLabel;

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

            // 答题完成，更新进度
            this.saveProgressAfterAnswer();
          } else {
            const allCorrectSelected = correctAnswers.every(ans => this.selectedOptions.includes(ans)) &&
            this.selectedOptions.every(opt => correctAnswers.includes(opt));
            if (allCorrectSelected) {
              this.hasSubmitted = true;
              this.saveQuestionState();

              // 答题完成，更新进度
              this.saveProgressAfterAnswer();
            }
          }
        }

        // 更新wrongAnswer为所有选中的选项
        wrongAnswer = this.selectedOptions.join('');
        this.saveQuestionState();
      } else {
        // 单选：设置选项并提交
        this.selectedOption = optionLabel;
        this.hasSubmitted = true;

        // 修复后的答案判断逻辑
        let isCorrect = false;

        if (this.isTrueFalseQuestion()) {
          // 判断题：获取正确答案的选项标签
          const correctOptionLabel = this.getTrueFalseCorrectOptionLabel(currentQuestion.answer);
          isCorrect = optionLabel === correctOptionLabel;

          // 对于判断题，错误答案记录选项内容而不是标签
          if (!isCorrect) {
            const optionIndex = optionLabel.charCodeAt(0) - 65;
            wrongAnswer = currentQuestion.option[optionIndex];
          }
        } else {
          // 普通单选题：比较选项标签与答案
          isCorrect = optionLabel === currentQuestion.answer;
          wrongAnswer = optionLabel;
        }

        if (!isCorrect) {
          await this.saveToWrongTable(currentQuestion, wrongAnswer);
        }

        // 答题完成，更新进度
        this.saveProgressAfterAnswer();
      }

      //提交后的选项保存在wrongAnswer中，不管对错的选项都保存到wrongAnswer中
      const updateQuetsionInfo: QuestionRes = {
        id: currentQuestion.id,
        qId: currentQuestion.qId,
        qName: currentQuestion.qName,
        question: currentQuestion.question,
        option: currentQuestion.option,
        answer: currentQuestion.answer,
        wrongAnswer: wrongAnswer,
        questionID: currentQuestion.questionID
      };
      this.homeModel.updateQuestion(updateQuetsionInfo)
      this.saveQuestionState();

    }
  }

  private isMultipleChoice(): boolean {
    const answer = this.questions[this.currentQuestionIndex].answer;
    return answer.length > 1 && /^[A-Z]+$/.test(answer);
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
        this.questionSelections = {};
        this.favoriteStatus = {};

        // 从数据库加载进度
        const savedPosition = await this.loadProgressFromDatabase();

        // 重置当前状态
        this.resetQuestionState();

        // 恢复之前的答题状态
        this.restoreAnsweredStates();

        // 智能设置当前题目位置（考虑未答题情况）
        this.setCurrentQuestionPosition(savedPosition);

        // 批量检查收藏状态
        const existedList = await this.homeModel.getCollectionQuestionList(qid);
        list.forEach((question) => {
          this.favoriteStatus[question.questionID] = existedList.some(item => item.questionID === question.questionID);
        });

        // 恢复当前题目的状态
        this.restoreQuestionState();

        console.log(`题目加载完成，定位到第 ${this.currentProgress} 题`);

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
    }).then(async (data) => {
      if (data.index === 1) {
        try {
          // 只清空已经答过题目的wrongAnswer（wrongAnswer不为空的题目）
          for (let i = 0; i < this.questions.length; i++) {
            const currentQuestion = this.questions[i];
            // 检查是否已经答过这道题（wrongAnswer不为空且不只是空白字符）
            if (currentQuestion.wrongAnswer && currentQuestion.wrongAnswer.trim() !== '') {
              const updateQuestionInfo: QuestionRes = {
                id: currentQuestion.id,
                qId: currentQuestion.qId,
                qName: currentQuestion.qName,
                question: currentQuestion.question,
                option: currentQuestion.option,
                answer: currentQuestion.answer,
                wrongAnswer: '', // 清空wrongAnswer
                questionID: currentQuestion.questionID
              };
              await this.homeModel.updateQuestion(updateQuestionInfo);
              // 同时更新内存中的题目数据
              this.questions[i].wrongAnswer = '';
              console.log(`清空第${i + 1}题的答题记录`);
            }
          }

          // 重置进度相关状态
          this.currentProgress = 1;
          this.currentQuestionIndex = 0;
          this.questionSelections = {};
          this.resetQuestionState();

          // 重置进度位置并保存到数据库
          this.updateCurrentPosition(0);

        } catch (error) {
          console.error('重置进度失败:', error);
          promptAction.showToast({ message: '重置进度失败', duration: 1500 });
        }
      }
    });
  }

  private findFirstUnansweredQuestion(): number {
    for (let i = 0; i < this.questions.length; i++) {
      const question = this.questions[i];
      // 检查题目是否未答过（wrongAnswer为空或只有空白字符）
      if (!question.wrongAnswer || question.wrongAnswer.trim() === '') {
        console.log(`找到第一个未答题: 第${i + 1}题`);
        return i;
      }
    }
    // 如果所有题目都答过了，返回最后一题的位置
    console.log('所有题目都已答过，定位到最后一题');
    return this.questions.length - 1;
  }

  private setCurrentQuestionPosition(savedPosition: number) {
    // 首先尝试从保存的位置开始找未答题
    let targetPosition = savedPosition;

    // 确保保存的位置不超出范围
    targetPosition = Math.min(Math.max(0, targetPosition), this.questions.length - 1);

    // 从保存的位置开始，查找第一个未答题
    let foundUnanswered = false;
    for (let i = targetPosition; i < this.questions.length; i++) {
      const question = this.questions[i];
      if (!question.wrongAnswer || question.wrongAnswer.trim() === '') {
        targetPosition = i;
        foundUnanswered = true;
        console.log(`从保存位置${savedPosition}开始，找到未答题位置: 第${i + 1}题`);
        break;
      }
    }

    // 如果从保存位置往后没找到未答题，从头开始找
    if (!foundUnanswered) {
      targetPosition = this.findFirstUnansweredQuestion();
    }

    // 设置当前位置
    this.currentQuestionIndex = targetPosition;
    this.currentProgress = targetPosition + 1;
    this.positions = targetPosition;

    console.log(`最终定位到第${this.currentProgress}题`);
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

  //答题完成后保存进度
  private saveProgressAfterAnswer() {
    // 如果不是最后一题，保存下一题的位置
    if (this.currentQuestionIndex < this.questions.length - 1) {
      this.updateCurrentPosition(this.currentQuestionIndex + 1);
      console.log(`答题完成，进度保存为下一题: ${this.currentQuestionIndex + 1}`);
    } else {
      // 如果是最后一题，保存当前位置（表示全部完成）
      this.updateCurrentPosition(this.currentQuestionIndex);
      console.log('最后一题答完，进度保存完成状态');

    }
  }

  isQuestionStarred(index: number): boolean {
    const question = this.questions[index];
    return this.favoriteStatus[question.questionID] || false;
  }

  build() {
    NavDestination() {
      if (this.questions.length > 0) {
        Column() {
          HeaderComponent({
            bankPage: this.bankPage,
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
                  canGoPrevious: this.currentQuestionIndex > 0 && (this.selectedIndex === 1 || this.hasSubmitted),
                  canGoNext: this.currentQuestionIndex < this.questions.length - 1 &&
                    (this.selectedIndex === 1 || this.hasSubmitted),
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


    }.hideTitleBar(true)
  }

  aboutToAppear(): void {
    const res = this.appPathStack.getParamByName(HomeConstants.ROUTER_EXERCISE_LIST) as NavQid[]
    if (res && res.length && res[0].qid) {
      const params = res[0]
      if (params.bankPage) {
        this.bankPage = params.bankPage
      }
      this.qid = parseInt(params.qid!.toString(), 10);
      if (params.positions) {
        this.positions = parseInt(params.positions.toString(), 10)
      }
      console.log(TAG, 'Received qid =' + this.qid);
      if (this.qid > 0) {
        this.getBankQuestionList(this.qid).then(() => {
          this.checkFavoriteStatus(); // 初始化第一题的收藏状态
        });
      }
    }
  }


  aboutToDisappear(): void {
    // 页面销毁前最后一次保存进度
    if (this.positions >= 0) {
      this.saveProgressToDatabase();
      console.log('页面销毁，最终保存进度:', this.positions);
    }
  }
}


@Builder
function ExercisePageBuilder() {
  ExercisePage()
}






