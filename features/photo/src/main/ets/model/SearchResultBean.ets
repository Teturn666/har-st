//存储转换后搜索结果的对象
export class SearchResultBean {
  //问题
  question: string = ''
  //选项
  optionAry: string[] = []
  //答案,存在多选答案的情况,存储正确选项的位置
  answerAry: number[] = []
  //答案
  answer: string = ''
  //图片
  questionImg: string = ''
}