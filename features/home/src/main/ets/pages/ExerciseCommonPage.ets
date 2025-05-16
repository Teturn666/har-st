import router from '@ohos.router';
import promptAction from '@ohos.promptAction';
import { QuestionRes, questionCollectionTable, questionTable, questionWrongTable,questionBankTable,BankListRes } from 'db';
import { TitleBar } from 'widget/Index';
import { HomeModel } from '../model/HomeModel';
import HomeConstants from '../Constants/HomeConstants'
import ('./ExerciseDetailsPage')

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

  // 格式化时间为 MM:SS
  private formatTime(seconds: number): string {
    const minutes = Math.floor(seconds / 60);
    const secs = seconds % 60;
    return `${minutes.toString().padStart(2, '0')}:${secs.toString().padStart(2, '0')}`;
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

  // 清理计时器
  aboutToDisappear(): void {
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
        // 模拟考试模式：随机抽取30条题目
        if (this.practiceMode === 1) {
          this.questions = this.getRandomQuestions(list, 10);
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
      promptAction.showToast({ message: '已切换到上一题', duration: 1000 });
    } else {
      promptAction.showToast({ message: '已经是第一题', duration: 1500 });
    }
  }

  private goToNextQuestion() {
    if (this.currentQuestionIndex < this.questions.length - 1) {
      this.currentQuestionIndex++;
      this.currentProgress = this.currentQuestionIndex + 1;
      this.restoreQuestionState(); // 恢复下一题的选择
      promptAction.showToast({ message: '已切换到下一题', duration: 1000 });
    } else {
      // 停止计时器
      if (this.timerId !== null) {
        clearInterval(this.timerId);
        this.timerId = null;
      }
      // 计算统计数据
      let correctCount = 0;
      this.questions.forEach((question, index) => {
        const selection = this.questionSelections[index];
        if (!selection || !selection.hasSubmitted) return;
        const isMultiple = question.answer.length > 1 && /^[A-D]+$/.test(question.answer);
        if (isMultiple) {
          const correctAnswers = question.answer.split('');
          const allCorrectSelected = correctAnswers.every(ans => selection.selectedOptions.includes(ans)) &&
          selection.selectedOptions.every(opt => correctAnswers.includes(opt));
          if (allCorrectSelected) correctCount++;
        } else {
          if (selection.selectedOption === question.answer) correctCount++;
        }
      });
      const wrongCount = this.questions.length - correctCount;

      // 跳转到详情页面
      router.pushNamedRoute({
        name:HomeConstants.ROUTER_EXERCISE_DETAILS_LIST,
        params: {
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
      if(this.isLoading) {
        Text('加载中...')
          .fontSize(16)
          .fontColor(Color.Gray)
          .margin({ top: 20 });
      }else if (this.questions.length === 0){
        Text('暂无题目数据')
          .fontSize(16)
          .fontColor(Color.Gray)
          .margin({ top: 20 });
      }else  {
        // 头部
        TitleBar({
          title: this.questionBankName,
          backClick: () => {
            router.back();
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

            if (this.practiceMode === 2 || this.practiceMode === 3)
              Text('清空')
                .fontSize(12)
                .fontColor('#F2B771')
                .margin({ left: 10 })
                .onClick(() => {
                  this.clearWrong()
                });
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

        // 内容部分
        Row() {
          Image(this.getQuestionTypeImage())
            .height(24)
            .objectFit(ImageFit.Cover)

          Blank();

          if (this.practiceMode === 1 || this.practiceMode ===3)
          Image(this.favoriteStatus[this.questions[this.currentQuestionIndex].questionID] ? $r('app.media.stared') : $r('app.media.star'))
            .width(18)
            .height(18)
            .onClick(() => {
              this.toggleFavorite();
            })
            .margin({ right: 5 })
          if (this.practiceMode === 1 || this.practiceMode === 3)
          Text(this.favoriteStatus[this.questions[this.currentQuestionIndex].questionID] ? "已收藏" : "收藏")
            .fontSize(12)


          if (this.practiceMode === 2)
            Image($r('app.media.ic_del'))
              .width(18)
              .height(18)
              .onClick(() => {
                // 移除逻辑
              })
              .margin({ right: 5 });

          if (this.practiceMode === 2)
            Text("移除")
              .fontColor('#F2B771')
              .fontSize(12);
        }
        .justifyContent(FlexAlign.SpaceBetween)
        .padding(10)
        .backgroundColor(Color.White)
        .borderRadius(8)
        .margin({ top: 20 })
        .width('90%');

        // 问题描述
        Text(this.questions[this.currentQuestionIndex].question)
          .fontSize(16)
          .padding({ left: 10, right: 10, top: 10 })
          .textAlign(TextAlign.Start)
          .width('90%');

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
                  ? (this.questions[this.currentQuestionIndex].answer.includes(this.getOptionLabel(idx)) ? '#DFF5E3' : '#F2F2F2')
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
              .margin({ right: 10 });
            Text(item)
              .fontSize(16)
              .padding(10)
              .width('80%')
              .borderRadius(8)
              .backgroundColor(
                this.selectedIndex === 1
                  ? (this.questions[this.currentQuestionIndex].answer.includes(this.getOptionLabel(idx)) ? '#DFF5E3' : '#F2F2F2')
                  : (this.hasSubmitted
                  ? (this.questions[this.currentQuestionIndex].answer.includes(this.getOptionLabel(idx))
                    ? '#DFF5E3'
                    : (this.isMultipleChoice()
                      ? (this.selectedOptions.includes(this.getOptionLabel(idx)) ? '#FDECEC' : '#F2F2F2')
                      : (this.selectedOption === this.getOptionLabel(idx) ? '#FDECEC' : '#F2F2F2')))
                  : (this.isMultipleChoice()
                    ? (this.selectedOptions.includes(this.getOptionLabel(idx)) ? '#B3E5FC' : '#F2F2F2')
                    : (this.selectedOption === this.getOptionLabel(idx) ? '#E0E0E0' : '#F2F2F2')))
              );
          }
          .onClick(() => this.handleOptionClick(this.getOptionLabel(idx)))
          .margin({ top: 12, left: 16, right: 16 });
        });
      }



    }
    .width('100%')
    .height('100%')
    .backgroundColor(Color.White);

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
            await this.saveToWrongTable(currentQuestion, optionLabel);
            this.saveQuestionState(); // 记录错误提交状态
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

  private async saveToWrongTable(question: QuestionRes, wrongAnswer: string) {
    try {
      let questionDb = new QuestionRes();
      questionDb.qId = question.qId;
      questionDb.question = question.question;
      questionDb.answer = question.answer;
      questionDb.option = question.option;
      questionDb.wrongAnswer = wrongAnswer;

      await questionWrongTable.insertDataAwait(questionDb);
      this.homeModel.getWrongQuestionList(question.qId);
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
      const existedList = await this.homeModel.getCollectionQuestionList(currentQuestion.qId);
      const isQuestionInCollection = existedList.some(item => item.questionID === questionID);

      if (isQuestionInCollection) {
        await questionCollectionTable.deleteData(currentQuestion, () => {
          this.favoriteStatus[questionID] = false;
          promptAction.showToast({ message: '已取消收藏', duration: 1500 });
        });
      } else {
        let questionDb = new QuestionRes();
        questionDb.qId = currentQuestion.qId;
        questionDb.question = currentQuestion.question;
        questionDb.answer = currentQuestion.answer;
        questionDb.option = currentQuestion.option;
        questionDb.wrongAnswer = "B"; // 如果需要，动态设置
        questionDb.questionID = questionID;

        await questionCollectionTable.insertDataAwait(questionDb);
        this.favoriteStatus[questionID] = true;
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
      this.favoriteStatus[questionID] = existedList.some(item => item.questionID === questionID);
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

  //清空
  private clearWrong() {
    promptAction.showDialog({
      title: '提示',
      message: '确认清空该题库所有错题吗？',
      buttons: [
        { text: '取消', color: '#666666' },
        { text: '确定', color: '#d2a129' },
      ],
    }).then((data) => {
      if (data.index === 1) {
         // questionWrongTable.deleteData(this.questions);

      }
    });
  }


  aboutToAppear(): void {
    const params = router.getParams() as RouteParams | undefined;
    if (params && typeof params.practiceMode === 'number' && typeof params.qid === 'number') {
      this.practiceMode = params.practiceMode;
      this.qid = params.qid;
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
          this.questionBankName = '错题练习';
          Promise.all([
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

// private questions: QuestionRes[] = [
//   {
//     "questionID": 1,
//     "qId": 1735007905,
//     "question": "在道路等开阔地带开展训练时，应做好（）。",
//     "answer": "A",
//     "option": ["安全警戒", "后勤保障", "着装", "准备活动"],
//     "wrongAnswer": ""
//   },
//   {
//     "questionID": 2,
//     "qId": 1735007905,
//     "question": "使用绳索开展高空救援时，绳索应避开（）等高温、尖锐部位。",
//     "answer": "AB",
//     "option": ["墙角", "烟火", "梁、柱", "管线井"],
//     "wrongAnswer": ""
//   },
//   {
//     "questionID": 3,
//     "qId": 1735007905,
//     "question": "总队、支队安全助理对灭火救援现场安全员实行统一管理。",
//     "answer": "A",
//     "option": ["正确", "错误"],
//     "wrongAnswer": ""
//   }
// ];

