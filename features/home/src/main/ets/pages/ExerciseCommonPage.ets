import router from '@ohos.router';
import promptAction from '@ohos.promptAction';
import { QuestionRes, questionCollectionTable, questionWrongTable, } from 'db';
import { TitleBar } from 'widget/Index';
import { HomeModel } from '../model/HomeModel';
import HomeConstants from '../Constants/HomeConstants'
import { preferencesUtils, PreferencesConstants } from 'utils/Index'


import('./ExerciseDetailsPage')
// 模拟考试、错题练习、收藏练习题目共用页面
interface questionSelections {
  selectedOption: string;
  selectedOptions: string[];
  hasSubmitted: boolean;
}

// 定义路由参数的接口
interface RouteParams {
  practiceMode?: number;
  qid?: number;
  backindex?: number;
}

@Entry({ routeName: "exerciseCommonPage" })
@Component
struct ExerciseCommonPage {
  @State selectedIndex: number = 0;
  @State currentQuestionIndex: number = 0;
  @State currentProgress: number = 1;
  @State isStarred: boolean = false;
  @State selectedOption: string = '';
  @State hasSubmitted: boolean = false;
  @State selectedOptions: string[] = [];
  @State practiceMode: number = -1; // 1: 模块考试, 2: 错题练习, 3: 收藏练习
  @State getQuestionCount: number = 0; //获取题目数量
  @State qid: number = -1;
  @State homeModel: HomeModel = HomeModel.getInstance();
  @State questionType: string = 'multiple';
  @State questionSelections: Record<number, questionSelections> = {}; // 记录每题选择
  @State favoriteStatus: Record<number, boolean> = {}; // 按 questionID 存储收藏状态
  @State questions: QuestionRes[] = [];
  @State totalProgress: number = this.questions.length;
  @State isLoading: boolean = false;
  @State questionBankName: string = ''; // 存储题库名字
  @State elapsedSeconds: number = 0; // 经过的秒数
  @State timerText: string = '00:00'; // 格式化时间
  private timerId: number | null = null; // 计时器 ID
  @State backindex: number = -1; //路由页数
  @State isBankData: boolean = false;

  // 添加判断题答案标准化方法
  private normalizeTrueFalseAnswer(answer: string): string {
    // 将各种格式的答案标准化为统一格式
    const upperAnswer = answer.toUpperCase().trim();

    // 处理 A/B 格式 - A通常表示正确，B表示错误
    if (upperAnswer === 'A' || upperAnswer === '√' || upperAnswer === '正确' ||
      upperAnswer === 'Y' || upperAnswer === '对') {
      return '正确';
    }

    if (upperAnswer === 'B' || upperAnswer === '×' || upperAnswer === '错误' ||
      upperAnswer === 'N' || upperAnswer === '错') {
      return '错误';
    }

    // 如果是选项内容本身，直接返回
    return answer;
  }

  // 格式化时间为 MM:SS
  private formatTime(seconds: number): string {
    const minutes = Math.floor(seconds / 60);
    const secs = seconds % 60;
    return `${minutes.toString().padStart(2, '0')}:${secs.toString().padStart(2, '0')}`;
  }

  private isTrueFalseQuestion(): boolean {
    const currentQuestion = this.questions[this.currentQuestionIndex];
    const options = currentQuestion.option;
    return options.length === 2 &&
    options.includes('正确') &&
    options.includes('错误');
  }

  // 启动正向计时器
  private startTimer(): void {
    if (this.timerId !== null) {
      clearInterval(this.timerId); // 清理现有计时器
    }
    this.timerId = setInterval(() => {
      this.elapsedSeconds++;
      this.timerText = this.formatTime(this.elapsedSeconds);
    }, 1000);
  }

  // 销毁页面调用
  async aboutToDisappear(): Promise<void> {
    if (this.timerId !== null) {
      clearInterval(this.timerId);
      this.timerId = null;
    }

  }

  // 随机抽取题目
  private getRandomQuestions(list: QuestionRes[], maxCount: number): QuestionRes[] {
    const shuffled = [...list]; // 复制数组以避免修改原数据
    for (let i = shuffled.length - 1; i > 0; i--) {
      const j = Math.floor(Math.random() * (i + 1));
      // 使用临时变量交换元素
      const temp = shuffled[i];
      shuffled[i] = shuffled[j];
      shuffled[j] = temp;
    }
    return shuffled.slice(0, Math.min(maxCount, shuffled.length)); // 取前 maxCount 条或全部
  }

  // 题目列表获取
  async getBankQuestionList(qid: number): Promise<void> {
    this.isLoading = true;
    try {
      const list = await this.homeModel.getBankQuestionList(qid);
      console.log("题目: " + JSON.stringify(list));
      if (list.length > 0) {
        // 模拟考试模式：随机抽取题目
        if (this.practiceMode === 1) {
          // 读取 Preferences 中的题目数量
          const count = preferencesUtils.getString(PreferencesConstants.SP_SELECT_VALUE, "10")
          let countNum = Number(count)
          if (list.length < countNum) {
            this.getQuestionCount = list.length
          } else {
            this.getQuestionCount = countNum
          }
          this.questions = this.getRandomQuestions(list, this.getQuestionCount);
          console.log("模拟考试随机抽取题目: ", this.questions.length);
        } else {
          this.questions = list; // 其他模式使用全部题目
        }
        this.totalProgress = this.questions.length;
        this.currentQuestionIndex = 0;
        this.currentProgress = 1;
        this.questionSelections = {};
        this.favoriteStatus = {};
      } else {
        promptAction.showToast({ message: '暂无题目数据', duration: 2000 });
      }
    } catch (err) {
      console.error('获取题目失败:', err);
      promptAction.showToast({ message: '题目加载失败', duration: 2000 });
    } finally {
      this.isLoading = false;
    }
  }

  private getQuestionTypeImage(): Resource {
    const question = this.questions[this.currentQuestionIndex];
    const options = question.option;
    const answer = question.answer;

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

  // 返回选项对应字母
  private getOptionLabel(index: number): string {
    return String.fromCharCode(65 + index);
  }

  private goToPreviousQuestion() {
    if (this.currentQuestionIndex > 0) {
      this.currentQuestionIndex--;
      this.currentProgress = this.currentQuestionIndex + 1;
      this.restoreQuestionState(); // 恢复上一题的选择
      // promptAction.showToast({ message: '已切换到上一题', duration: 1000 });
    } else {
      promptAction.showToast({ message: '已经是第一题', duration: 1500 });
    }
  }

  private isQuestionCorrect(question: QuestionRes, selection: questionSelections): boolean {
    const isMultiple = question.answer.length > 1 && /^[A-D]+$/.test(question.answer);

    if (isMultiple) {
      // 多选题逻辑保持不变
      const correctAnswers = question.answer.split('');
      return correctAnswers.every(ans => selection.selectedOptions.includes(ans)) &&
      selection.selectedOptions.every(opt => correctAnswers.includes(opt));
    } else {
      // 单选题和判断题
      const options = question.option;
      const isTrueFalse = options.length === 2 &&
      options.includes('正确') &&
      options.includes('错误');

      if (isTrueFalse) {
        // 判断题：标准化答案后比较
        const optionIndex = selection.selectedOption.charCodeAt(0) - 65; // A=0, B=1
        const selectedContent = question.option[optionIndex];
        const normalizedAnswer = this.normalizeTrueFalseAnswer(question.answer);
        const normalizedSelected = this.normalizeTrueFalseAnswer(selectedContent);
        return normalizedSelected === normalizedAnswer;
      } else {
        // 单选题：比较选项标签与答案
        return selection.selectedOption === question.answer;
      }
    }
  }

  private async goToNextQuestion() {
    if (this.currentQuestionIndex < this.questions.length - 1) {
      this.currentQuestionIndex++;
      this.currentProgress = this.currentQuestionIndex + 1;
      this.restoreQuestionState(); // 恢复下一题的选择
      // promptAction.showToast({ message: '已切换到下一题', duration: 1000 });
    } else {
      // 停止计时器
      if (this.timerId !== null) {
        clearInterval(this.timerId);
        this.timerId = null;
      }

      // 修复后的统计逻辑
      let correctCount = 0;
      this.questions.forEach((question, index) => {
        const selection = this.questionSelections[index];
        if (!selection || !selection.hasSubmitted) {
          return;
        }

        if (this.isQuestionCorrect(question, selection)) {
          correctCount++;
        }
      });

      const wrongCount = this.questions.length - correctCount;

      // 检查是否有剩余的错题或收藏题目
      if (this.practiceMode === 2) {
        this.isBankData = await this.hasWrongQuestions();
      } else if (this.practiceMode === 3) {
        this.isBankData = await this.hasCollectionQuestions();
      } else {
        this.isBankData = true; // 模拟考试模式默认有数据
      }

      // 跳转到详情页面
      router.pushNamedRoute({
        name: HomeConstants.ROUTER_EXERCISE_DETAILS_LIST,
        params: {
          isBankData: this.isBankData,
          backindex: this.backindex,
          typepage: this.practiceMode,
          title: this.questionBankName,
          correctCount: correctCount,
          wrongCount: wrongCount,
          timeSpent: this.formatTime(this.elapsedSeconds),
          questions: this.questions.map((q, index) => {
            let questionRes = new QuestionRes();
            questionRes.qId = q.qId;
            questionRes.question = q.question;
            questionRes.option = q.option;
            questionRes.answer = q.answer;
            questionRes.wrongAnswer = q.wrongAnswer;
            questionRes.questionID = q.questionID;
            // 使用 wrongAnswer 字段存储用户答案
            questionRes.wrongAnswer = this.questionSelections[index]?.selectedOption ||
              (this.questionSelections[index]?.selectedOptions.join(',') || '');
            return questionRes;
          })
        }
      });
    }
  }

  private isMultipleChoice(): boolean {
    const answer = this.questions[this.currentQuestionIndex].answer;
    return answer.length > 1 && /^[A-D]+$/.test(answer);
  }

  build() {
    Column() {
      if (this.isLoading) {
        Text('加载中...')
          .fontSize(16)
          .fontColor(Color.Gray)
          .margin({ top: 20 });
      } else if (this.questions.length === 0) {
        Text('暂无题目数据')
          .fontSize(16)
          .fontColor(Color.Gray)
          .margin({ top: 20 });
      } else {
        // 头部
        TitleBar({
          title: this.practiceMode === 1 ? this.questionBankName :
            this.practiceMode === 2 ? "错题练习" : "收藏练习",
          backClick: () => {
            if (this.practiceMode === 1) {
              promptAction.showDialog({
                title: '提示',
                message: '你还未完成考试，确认退出吗？',
                buttons: [
                  { text: '取消', color: '#666666' },
                  { text: '确定', color: '#d2a129' },
                ],
              }).then((data) => {
                if (data.index === 1) {
                  let index = Number(router.getLength()) - 2
                  router.back(
                    index, {
                    refresh: "1",
                    type: this.practiceMode.toString()
                  })
                }
              });
            } else {
              this.backindex -= 1
              let index = Number(router.getLength()) - this.backindex
              router.back(
                index, {
                refresh: "1",
                type: this.practiceMode.toString()
              })
            }
          }
        })
          .width('100%');
        // 进度条部分
        Flex({ direction: FlexDirection.Column, justifyContent: FlexAlign.SpaceBetween, alignItems: ItemAlign.Start }) {
          Row() {
            Progress({
              type: ProgressType.Linear,
              value: this.currentProgress,
              total: this.totalProgress,
            })
              .color(Color.Orange)
              .width(this.practiceMode === 2 || this.practiceMode === 3 ? '90%' : '100%')
              .height(16)
              .backgroundColor('#dadada')
              .style({ strokeWidth: 15 });

            if (this.practiceMode === 2 || this.practiceMode === 3) {
              Text('清空')
                .fontSize(12)
                .fontColor('#F2B771')
                .margin({ left: 10 })
                .onClick(() => {
                  if (this.practiceMode === 2) {
                    this.clearWrong()
                  } else {
                    this.colletionQuestion()
                  }
                });
            }
          }
          .width('100%');

          Row() {
            Image($r('app.media.ic_clock'))
              .width(16)
              .height(16);
            Text(this.timerText)
              .fontColor('#F2B771')
              .fontSize(12)
              .margin({ left: 8 });

            Blank();
            Text(`${this.currentProgress}/${this.totalProgress}`)
              .fontSize(12)
              .fontColor(Color.Black);
          }
          .width(this.practiceMode === 2 || this.practiceMode === 3 ? '90%' : '100%')
          .margin({ top: 8 })
          .justifyContent(FlexAlign.SpaceBetween);
        }
        .backgroundColor('#f5f3f4')
        .borderRadius(8)
        .width('90%')
        .height(50)
        .margin({ top: 10 })
        .padding(10);

        List() {
          ListItem() {
            // 内容部分
            Row() {
              Image(this.getQuestionTypeImage())
                .height(24)
                .objectFit(ImageFit.Cover)
              Blank();

              if (this.practiceMode === 1 || this.practiceMode === 3) {
                Image(this.favoriteStatus[this.questions[this.currentQuestionIndex].questionID] ?
                $r('app.media.stared') :
                $r('app.media.star'))
                  .width(18)
                  .height(18)
                  .onClick(() => {
                    this.toggleFavorite();
                  })
                  .margin({ right: 5 })
              }
              if (this.practiceMode === 1 || this.practiceMode === 3) {
                Text(this.favoriteStatus[this.questions[this.currentQuestionIndex].questionID] ? "已收藏" : "收藏")
                  .fontSize(12)
              }
              if (this.practiceMode === 2) {
                Image($r('app.media.ic_del'))
                  .width(18)
                  .height(18)
                  .onClick(() => {
                    // 移除逻辑
                    this.removeCurrentQuestion()
                  })
                  .margin({ right: 5 });
              }

              if (this.practiceMode === 2) {
                Text("移除")
                  .fontColor('#F2B771')
                  .fontSize(12);
              }
            }
            .justifyContent(FlexAlign.SpaceBetween)
            .padding(10)
            .backgroundColor(Color.White)
            .borderRadius(8)
            .margin({ top: 20 })
            .width('100%');
          }

          ListItem() {
            // 问题描述
            Text(this.questions[this.currentQuestionIndex].question)
              .fontSize(16)
              .padding({ left: 10, right: 10, top: 10 })
              .textAlign(TextAlign.Start)
              .width('100%');
          }

          ListItem() {
            // 选项列表
            Column() {
              ForEach(this.questions[this.currentQuestionIndex].option, (item: string, idx: number) => {
                Row() {
                  Text(this.getOptionLabel(idx))
                    .width(30)
                    .height(30)
                    .textAlign(TextAlign.Center)
                    .fontSize(16)
                    .fontColor('#000000')
                    .borderRadius(15)
                    .backgroundColor(this.getOptionBackgroundColor(idx))
                    .margin({ right: 10 });
                  Text(item)
                    .fontSize(16)
                    .padding(10)
                    .width('80%')
                    .borderRadius(8)
                    .backgroundColor(this.getOptionBackgroundColor(idx))
                }
                .onClick(() => this.handleOptionClick(this.getOptionLabel(idx)))
                .margin({ top: 12, left: 16, right: 16 });
              });
            }
          }

          ListItem() {
            //按钮
            if (((this.practiceMode === 3 || this.practiceMode === 2) && this.hasSubmitted)) {
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
              .width('100%')
              .margin({ top: 18 })
            }
          }
        }
        .width('90%')
        .layoutWeight(1)
      }
    }
    .width('100%')
    .height('100%')
    .backgroundColor(Color.White);

  }

  private getOptionBackgroundColor(idx: number): string {
    const optionLabel = this.getOptionLabel(idx);
    const currentQuestion = this.questions[this.currentQuestionIndex];

    const isSelected = this.isMultipleChoice()
      ? this.selectedOptions.includes(optionLabel)
      : this.selectedOption === optionLabel;

    // 修复：根据题目类型判断是否正确
    let isCorrect = false;
    if (this.isTrueFalseQuestion()) {
      // 判断题：标准化答案后比较选项内容
      const optionContent = currentQuestion.option[idx];
      const normalizedAnswer = this.normalizeTrueFalseAnswer(currentQuestion.answer);
      const normalizedOption = this.normalizeTrueFalseAnswer(optionContent);
      isCorrect = normalizedOption === normalizedAnswer;
    } else {
      // 单选/多选题：比较选项标签
      isCorrect = currentQuestion.answer.includes(optionLabel);
    }

    if (this.selectedIndex === 1) {
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
      if (this.isMultipleChoice()) {
        return this.selectedOptions.includes(optionLabel) ? '#B3E5FC' : '#F2F2F2';
      } else {
        return this.selectedOption === optionLabel ? '#E0E0E0' : '#F2F2F2';
      }
    }
  }

  private async handleOptionClick(optionLabel: string) {
    if (this.selectedIndex === 0 && !this.hasSubmitted) {
      const currentQuestion = this.questions[this.currentQuestionIndex];
      const isLastQuestion = this.currentQuestionIndex === this.questions.length - 1;

      if (this.isMultipleChoice()) {
        // 多选逻辑保持不变
        if (this.selectedOptions.includes(optionLabel)) {
          this.selectedOptions = this.selectedOptions.filter(opt => opt !== optionLabel);
        } else {
          this.selectedOptions = [...this.selectedOptions, optionLabel];
          const correctAnswers = currentQuestion.answer.split('');
          // 检查是否选择了错误选项
          if (!correctAnswers.includes(optionLabel)) {
            this.hasSubmitted = true;
            if (this.practiceMode !== 2) {
              await this.saveToWrongTable(currentQuestion, optionLabel);
            }
            this.saveQuestionState(); // 记录错误提交状态
            if (isLastQuestion) {
              this.goToNextQuestion();
            } else if (this.practiceMode === 1) {
              setTimeout((): Promise<void> => this.goToNextQuestion(), 2000);
            }
          } else {
            // 检查是否选中了全部正确答案
            const allCorrectSelected = correctAnswers.every(ans => this.selectedOptions.includes(ans)) &&
            this.selectedOptions.every(opt => correctAnswers.includes(opt));
            if (allCorrectSelected) {
              this.hasSubmitted = true;
              if (this.practiceMode === 2) {
                // 在错题练习模式下，如果答对，从错题表中移除
                await this.deleteFromWrongTable(currentQuestion);
              }
              this.saveQuestionState(); // 记录正确提交状态
              if (isLastQuestion) {
                this.goToNextQuestion();
              } else if (this.practiceMode === 1) {
                setTimeout((): Promise<void> => this.goToNextQuestion(), 2000);
              }
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
          // 判断题：标准化答案后比较
          const optionIndex = optionLabel.charCodeAt(0) - 65; // A=0, B=1
          const selectedContent = currentQuestion.option[optionIndex];
          const normalizedAnswer = this.normalizeTrueFalseAnswer(currentQuestion.answer);
          const normalizedSelected = this.normalizeTrueFalseAnswer(selectedContent);
          isCorrect = normalizedSelected === normalizedAnswer;
        } else {
          // 单选题：比较选项标签与答案
          isCorrect = optionLabel === currentQuestion.answer;
        }

        if (isCorrect && this.practiceMode === 2) {
          // 在错题练习模式下，如果答对，从错题表中移除
          await this.deleteFromWrongTable(currentQuestion);
        } else if (!isCorrect && this.practiceMode !== 2) {
          // 插入错题表时，对于判断题传递选项内容
          const wrongAnswer = this.isTrueFalseQuestion()
            ? currentQuestion.option[optionLabel.charCodeAt(0) - 65]
            : optionLabel;
          await this.saveToWrongTable(currentQuestion, wrongAnswer);
        }

        this.saveQuestionState(); // 记录单选提交状态
        if (isLastQuestion) {
          this.goToNextQuestion();
        } else if (this.practiceMode === 1) {
          setTimeout((): Promise<void> => this.goToNextQuestion(), 2000);
        }

      }
    }
  }

  private async deleteFromWrongTable(question: QuestionRes) {
    try {
      console.log(`准备从错题表移除题目: questionID=${question.questionID}`);
      await questionWrongTable.deleteDataByQuestionID(question.questionID);
    } catch (err) {
      console.error('从错题表移除失败:', err);
    }
  }

  private async saveToWrongTable(question: QuestionRes, wrongAnswer: string) {
    try {
      // 检查题目是否已存在于错题表
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
      await questionWrongTable.insertDataAwait(questionDb);
      this.homeModel.getWrongQuestionList(question.qId);
      console.log(`题目 ${question.questionID} 已添加到错题表`);

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

  private async getQuestionBankList(): Promise<void> {
    this.isLoading = true; // 开始加载
    try {
      const list = await this.homeModel.queryQuestionBankList(this.qid);
      console.log("题库信息: " + JSON.stringify(list));
      const questionBank = list.find(item => item.qid === this.qid);
      if (questionBank && questionBank.name) {
        this.questionBankName = questionBank.name;
      } else {
        this.questionBankName = '未知题库';
        promptAction.showToast({ message: '未找到题库信息', duration: 2000 });
      }
    } catch (err) {
      console.error('获取题库信息失败:', err);
      this.questionBankName = '未知题库';
      promptAction.showToast({ message: '加载题库信息失败', duration: 2000 });
    } finally {
      this.isLoading = false; // 加载完成
    }
  }

  //收藏
  private async toggleFavorite() {
    const currentQuestion: QuestionRes = this.questions[this.currentQuestionIndex];
    const questionID = currentQuestion.questionID;
    try {
      const result = await questionCollectionTable.querySync(currentQuestion.qId, false);
      const isFavorited = result.some(item => item.questionID === questionID);

      if (isFavorited) {
        // 取消收藏
        await questionCollectionTable.deleteDataByQuestionID(questionID);
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
        await questionCollectionTable.insertDataAwait(questionDb);
        this.favoriteStatus[questionID] = true;
        console.log(`添加收藏，题目 ${questionID} 已添加到收藏表`);
        promptAction.showToast({ message: '收藏成功', duration: 1500 });
      }
    } catch (err) {
      console.error('收藏操作失败:', err);
      promptAction.showToast({ message: '收藏操作失败', duration: 1500 });
    }
  }

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

  private resetQuestionState() {
    this.selectedOption = '';
    this.selectedOptions = [];
    this.hasSubmitted = false;
  }

  async hasWrongQuestions() {
    try {
      const list = await this.homeModel.getWrongQuestionList(this.qid);
      return Array.isArray(list) && list.length > 0; // 直接返回布尔值
    } catch (error) {
      console.error('获取错题列表失败:', error);
      return false; // 出错时返回false
    }
  }

  async hasCollectionQuestions() {
    try {
      const list = await this.homeModel.getCollectionQuestionList(this.qid);
      return Array.isArray(list) && list.length > 0;
    } catch (error) {
      console.error('获取收藏题目列表失败:', error);
      return false;
    }
  }

  // 获取错题列表
  async getWrongQuestionList(qid: number): Promise<void> {
    this.isLoading = true;
    try {
      const list = await this.homeModel.getWrongQuestionList(qid);
      console.log("错题: " + JSON.stringify(list));
      if (list.length > 0) {
        this.questions = list;
        this.totalProgress = this.questions.length;
        this.currentQuestionIndex = 0;
        this.currentProgress = 1;
        this.questionSelections = {};
        this.favoriteStatus = {}; // 清空收藏状态，但错题模式下不使用
      } else {
        promptAction.showToast({ message: '暂无错题数据', duration: 2000 });
      }
    } catch (err) {
      console.error('获取错题失败:', err);
      promptAction.showToast({ message: '错题加载失败', duration: 2000 });
    } finally {
      this.isLoading = false;
    }
  }

  //清空错题
  private clearWrong() {
    promptAction.showDialog({
      title: '提示',
      message: '确认清空该题库所有错题吗？',
      buttons: [
        { text: '取消', color: '#666666' },
        { text: '确定', color: '#d2a129' },
      ],
    }).then(async (data) => {
      if (data.index === 1) {
        const wrongQuestions = await questionWrongTable.querySync(this.qid, false);
        if (wrongQuestions.length > 0) {
          for (const question of wrongQuestions) {
            await new Promise<void>((resolve) => {
              questionWrongTable.deleteData(question, (error: Error | undefined) => {
                if (error) {
                  console.error('删除错题失败:', error);
                }
                resolve();
              });
            });
          }
          // 清空错题（仅清空本地列表）
          this.questions = [];
          this.totalProgress = this.questions.length;
          this.currentQuestionIndex = 0;
          this.currentProgress = this.questions.length > 0 ? 1 : 0;
          this.questionSelections = {};
          this.favoriteStatus = {};
          // this.yic()
          let index = Number(router.getLength()) - 1
          router.back(
            index, {
            refresh: "1",
            type: this.practiceMode.toString()
          }
          )
        } else {
          promptAction.showToast({ message: '没有错题可清空', duration: 1500 });
        }
      }
    });
  }

  //清空收藏
  private colletionQuestion() {
    promptAction.showDialog({
      title: '提示',
      message: '确认清空该题库所有收藏吗？',
      buttons: [
        { text: '取消', color: '#666666' },
        { text: '确定', color: '#d2a129' },
      ],
    }).then(async (data) => {
      if (data.index === 1) {
        const colletionQuestions = await questionCollectionTable.querySync(this.qid, false);
        if (colletionQuestions.length > 0) {
          for (const question of colletionQuestions) {
            await new Promise<void>((resolve) => {
              questionCollectionTable.deleteData(question, (error: Error | undefined) => {
                if (error) {
                  console.error('删除失败:', error);
                }
                resolve();
              });
            });
          }
          // 清空收藏（仅清空本地列表）
          this.questions = [];
          this.totalProgress = this.questions.length;
          this.currentQuestionIndex = 0;
          this.currentProgress = this.questions.length > 0 ? 1 : 0;
          this.questionSelections = {};
          this.favoriteStatus = {};
          let index = Number(router.getLength()) - 1
          router.back(
            index, {
            refresh: "1",
            type: this.practiceMode.toString()
          }
          )
        } else {
          promptAction.showToast({ message: '没有收藏题目可清空', duration: 1500 });
        }
      }
    });
  }

  private async removeCurrentQuestion() {
    const currentQuestion = this.questions[this.currentQuestionIndex];
    if (!currentQuestion) {
      promptAction.showToast({ message: '没有题目可移除', duration: 1500 });
      return;
    }
    try {
      console.log(`准备移除错题: questionID=${currentQuestion.questionID}`);
      await questionWrongTable.deleteDataByQuestionID(currentQuestion.questionID);
      this.questions.splice(this.currentQuestionIndex, 1);
      this.totalProgress = this.questions.length;
      promptAction.showToast({ message: '已移除错题', duration: 1500 });

      if (this.questions.length === 0) {
        this.currentQuestionIndex = 0;
        this.currentProgress = 0;
        this.questionSelections = {};
        this.favoriteStatus = {};
        if (this.timerId !== null) {
          clearInterval(this.timerId);
          this.timerId = null;
          this.elapsedSeconds = 0;
          this.timerText = '00:00';
        }
        promptAction.showDialog({
          title: '温馨提示',
          message: '当前没有错题，练习做题的题目将会收录到这里。',
          buttons: [
            { text: '我知道了', color: '#d2a129' },
          ],
        }).then(() => {
          let index = Number(router.getLength()) - 1;
          router.back(index, {
            refresh: "1",
            type: this.practiceMode.toString()
          });
        });
      } else {
        if (this.currentQuestionIndex >= this.questions.length) {
          this.currentQuestionIndex = this.questions.length - 1;
        }
        this.currentProgress = this.currentQuestionIndex + 1;
        this.restoreQuestionState();
      }
    } catch (err) {
      console.error('移除错题失败:', err);
      promptAction.showToast({ message: '移除错题失败', duration: 1500 });
    }
  }

  // 获取收藏列表
  async getCollectionQuestionList(qid: number): Promise<void> {
    this.isLoading = true;
    try {
      const list = await this.homeModel.getCollectionQuestionList(qid);
      console.log("错题: " + JSON.stringify(list));
      if (list.length > 0) {
        this.questions = list;
        this.totalProgress = this.questions.length;
        this.currentQuestionIndex = 0;
        this.currentProgress = 1;
        this.questionSelections = {};
        this.favoriteStatus = {}; // 清空收藏状态，但错题模式下不使用
      } else {
        promptAction.showToast({ message: '暂无错题数据', duration: 2000 });
      }
    } catch (err) {
      console.error('获取错题失败:', err);
      promptAction.showToast({ message: '错题加载失败', duration: 2000 });
    } finally {
      this.isLoading = false;
    }
  }

  async aboutToAppear(): Promise<void> {
    const params = router.getParams() as RouteParams | undefined;
    if (params && typeof params.practiceMode === 'number' && typeof params.qid === 'number') {
      this.practiceMode = params.practiceMode;
      this.qid = params.qid;
      if (this.practiceMode === 1) {
        this.backindex = params.backindex || 3;
      } else {
        this.backindex = params.backindex || 2;
      }

      // console.log('aboutToAppear: qid=', this.qid, 'practiceMode=', this.practiceMode);
      if ([1, 2, 3].includes(this.practiceMode)) {
        if (this.practiceMode === 1) {
          // 模拟考试
          this.isLoading = true;
          Promise.all([
            this.getQuestionBankList(),
            this.getBankQuestionList(this.qid).then(() => {
              this.checkFavoriteStatus(); // 初始化第一题的收藏状态
            })
          ]).then(() => {
            this.isLoading = false;
            this.startTimer(); // 数据加载完成后启动计时器
          }).catch((err: Error) => {
            this.isLoading = false;
            console.error('异步加载失败:', err.message || err);
            promptAction.showToast({ message: '数据加载失败', duration: 2000 });
          });
        } else if (this.practiceMode === 2) {
          // 错题练习
          this.isLoading = true;
          Promise.all([
            this.getQuestionBankList(),
            this.getWrongQuestionList(this.qid)
          ]).then(() => {
            this.isLoading = false;
            this.startTimer(); // 数据加载完成后启动计时器
          }).catch((err: Error) => {
            this.isLoading = false;
            console.error('异步加载失败:', err.message || err);
            promptAction.showToast({ message: '数据加载失败', duration: 2000 });
          });
        } else if (this.practiceMode === 3) {
          // 收藏练习
          this.isLoading = true;
          Promise.all([
            this.getQuestionBankList(),
            this.getCollectionQuestionList(this.qid).then(() => {
              this.checkFavoriteStatus(); // 初始化第一题的收藏状态
            })
          ]).then(() => {
            this.isLoading = false;
            this.startTimer(); // 数据加载完成后启动计时器
          }).catch((err: Error) => {
            this.isLoading = false;
            console.error('异步加载失败:', err.message || err);
            promptAction.showToast({ message: '数据加载失败', duration: 2000 });
          });
        }
      } else {
        console.error('Invalid practiceMode received:', this.practiceMode);
        promptAction.showToast({ message: '无效的练习模式', duration: 1500 });
        this.practiceMode = 1;
      }
    } else {
      console.error('No practiceMode parameter received or invalid type');
      promptAction.showToast({ message: '未指定练习模式', duration: 1500 });
      this.practiceMode = 1;
    }
  }
}
