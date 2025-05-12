import router from '@ohos.router';
import promptAction from '@ohos.promptAction';

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


@Entry({ routeName: 'exercisePage' })
@Component
struct ExercisePage {
  @State selectedIndex: number = 0;
  @State currentProgress: number = 50;
  @State totalProgress: number = 100;
  @State isStarred: boolean = false;
  @State questionType: string = 'multiple';
  @State selectedOption: string = '';
  @State correctOption: string = 'C';

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
            promptAction.showToast({
              message: '刷新中...',
              duration: 2000
            });
            this.currentProgress = 0;
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


      // 选项列表（内联实现）
      Column() {
        // 选项 A
        Row() {
          Text('A')
            .fontSize(16)
            .fontColor('#000000')
            .width(30)
            .height(30)
            .borderRadius(15)
            .backgroundColor(
              this.selectedOption === 'A'
              ? ('A' === this.correctOption ? '#DFF5E3' : '#FDECEC')
              : '#FFFFFF')
            .textAlign(TextAlign.Center)
            .margin({ right: 18 })
            .shadow({ radius: 6, color: '#E0E0E0', offsetX: 2, offsetY: 2 });
          Text('30')
            .fontSize(16)
            .padding(10)
            .width('80%')
            .borderRadius(8)
            .backgroundColor(
              this.selectedOption === 'A'
                ? ('A' === this.correctOption ? '#DFF5E3' : '#FDECEC')
                : '#f2f2f2'
            )
            .shadow({ radius: 6, color: '#E0E0E0', offsetX: 2, offsetY: 2 });
        }
        .width('90%')
        .height(50)
        .borderRadius(10)
        .alignItems(VerticalAlign.Center)
        .padding(5)
        .onClick(() => { this.selectedOption = 'A'; })

        // 选项 B
        Row() {
          Text('B')
            .fontSize(16)
            .fontColor('#000000')
            .width(30)
            .height(30)
            .borderRadius(15)
            .backgroundColor(
              this.selectedOption === 'B'
                ? ('B' === this.correctOption ? '#DFF5E3' : '#FDECEC')
                : '#FFFFFF'
            )
            .textAlign(TextAlign.Center)
            .margin({ right: 18 })
            .shadow({ radius: 6, color: '#E0E0E0', offsetX: 2, offsetY: 2 });
          Text('25')
            .fontSize(16)
            .padding(10)
            .width('80%')
            .borderRadius(8)
            .backgroundColor(
              this.selectedOption === 'B'
                ? ('B' === this.correctOption ? '#DFF5E3' : '#FDECEC')
                : '#f2f2f2'
            )
            .shadow({ radius: 6, color: '#E0E0E0', offsetX: 2, offsetY: 2 });
        }
        .width('90%')
        .height(50)
        .borderRadius(10)
        .alignItems(VerticalAlign.Center)
        .padding(5)
        .margin({ top: 10 })
        .onClick(() => { this.selectedOption = 'B'; })

        // 选项 C
        Row() {
          Text('C')
            .fontSize(16)
            .fontColor('#000000')
            .width(30)
            .height(30)
            .borderRadius(15)
            .backgroundColor(
              this.selectedOption === 'C'
                ? ('C' === this.correctOption ? '#DFF5E3' : '#FDECEC')
                : '#FFFFFF'
            )
            .textAlign(TextAlign.Center)
            .margin({ right: 18 })
            .shadow({ radius: 6, color: '#E0E0E0', offsetX: 2, offsetY: 2 });
          Text('15')
            .fontSize(16)
            .padding(10)
            .width('80%')
            .borderRadius(8)
            .backgroundColor(
              this.selectedOption === 'C'
                ? ('C' === this.correctOption ? '#DFF5E3' : '#FDECEC')
                : '#f2f2f2'
            )
            .shadow({ radius: 6, color: '#E0E0E0', offsetX: 2, offsetY: 2 });
        }
        .width('90%')
        .height(50)
        .borderRadius(10)
        .alignItems(VerticalAlign.Center)
        .padding(5)
        .margin({ top: 10 })
        .onClick(() => { this.selectedOption = 'C'; })

        // 选项 D
        Row() {
          Text('D')
            .fontSize(16)
            .fontColor('#000000')
            .width(30)
            .height(30)
            .borderRadius(15)
            .backgroundColor(
              this.selectedOption === 'D'
              ? ('D' === this.correctOption ? '#DFF5E3' : '#FDECEC')
              : '#FFFFFF')
            .textAlign(TextAlign.Center)
            .margin({ right: 18 })
            .shadow({ radius: 6, color: '#E0E0E0', offsetX: 2, offsetY: 2 });
          Text('10')
            .fontSize(16)
            .padding(10)
            .width('80%')
            .borderRadius(8)
            .backgroundColor(
              this.selectedOption === 'D'
                ? ('D' === this.correctOption ? '#DFF5E3' : '#FDECEC')
                : '#f2f2f2'
            )
            .shadow({ radius: 6, color: '#E0E0E0', offsetX: 2, offsetY: 2 });
        }
        .width('90%')
        .height(50)
        .borderRadius(10)
        .alignItems(VerticalAlign.Center)
        .padding(5)
        .margin({ top: 10, bottom: 50 })
        .onClick(() => { this.selectedOption = 'D'; })
      }
      .padding({ left: 10, right: 10 })
      .margin({top:20})

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
        .onClick(() => {
          // $raw.showToast({ message: '上一题', duration: 2000 });
        })

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
        .onClick(() => {
          // $raw.showToast({ message: '下一题', duration: 2000 });
        })
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


