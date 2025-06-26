import photoAccessHelper from '@ohos.file.photoAccessHelper';
import { BusinessError } from '@ohos.base';
import image from '@ohos.multimedia.image';
import { promptAction } from "@kit.ArkUI";
import display from '@ohos.display';
import { PreferencesConstants, preferencesUtils } from 'utils';

const TAG = 'ScreenReadSetting';

@Component
export struct ScreenReadSetting {
  @Consume('pathStack') pathStack: NavPathStack;
  @State title: string = '读屏设置';
  @State selectedImageUri: string = '';
  // 识别相关状态
  @State startPoint: Position = { x: 0, y: 0 }; // 起始点
  @State cropAreaY: number = 60; // 识别区域Y坐标，默认60
  @State cropAreaHeight: number = 200; // 识别区域高度，默认200
  @State isDragging: boolean = false;
  @State pageHeight: number = 0; // 页面高度

  // 组件即将出现时的回调
  aboutToAppear() {
    this.loadSettings();
  }

  // 加载之前保存的设置
  private async loadSettings() {
    try {
      const savedSettings = preferencesUtils.getString(PreferencesConstants.SCREEN_READ_SETTING, '');
      let region: image.Region
      if (savedSettings) {
        region = JSON.parse(savedSettings);
      } else {
        region =
          { x: 0, y: 0.0721, size: { width: 0, height: 0.493 } }
        console.log(TAG, '没有找到保存的设置，使用默认值');
      }

      console.log(TAG, '加载保存的设置:', JSON.stringify(region));

      // 获取屏幕高度
      const displayInfo = display.getDefaultDisplaySync();
      const screenHeight = displayInfo.height;

      // 将归一化的坐标转换回像素值，再转换为vp
      this.cropAreaY = px2vp(region.y * screenHeight);
      this.cropAreaHeight = px2vp(region.size.height * screenHeight);

      console.log(TAG, '恢复的识别区域 - Y:', this.cropAreaY, 'Height:', this.cropAreaHeight);
    } catch (error) {
      console.error(TAG, '加载设置失败:', error);
      // 如果加载失败，保持默认值
    }
  }

  // 从相册选取
  private async selectFromGallery() {
    console.log('从相册选取');

    try {
      const photoSelectOptions = new photoAccessHelper.PhotoSelectOptions();
      photoSelectOptions.MIMEType = photoAccessHelper.PhotoViewMIMETypes.IMAGE_TYPE;
      photoSelectOptions.maxSelectNumber = 1;

      const photoPicker = new photoAccessHelper.PhotoViewPicker();
      let photoSelectResult = await photoPicker.select(photoSelectOptions);

      if (photoSelectResult && photoSelectResult.photoUris && photoSelectResult.photoUris.length > 0) {
        this.selectedImageUri = photoSelectResult.photoUris[0];
        console.log('选择的图片URI:', this.selectedImageUri);
      } else {
        console.log('用户取消了图片选择');
      }
    } catch (error) {
      const err = error as BusinessError;
      console.error('选择图片失败:', err.code, err.message);
    }
  }

  // 保存设置
  private saveSettings() {
    console.log('保存设置');

    // 获取屏幕宽度
    const displayInfo = display.getDefaultDisplaySync();
    const screenHeight = displayInfo.height;

    console.log(TAG, 'screenHeight =' + JSON.stringify(screenHeight))


    // 输出符合image.Region格式的区域信息
    let region: image.Region = {
      x: 0,
      y: vp2px(this.cropAreaY) / screenHeight, // 区域左上角纵坐标
      size: {
        width: 0,
        height: vp2px(this.cropAreaHeight) / screenHeight
      }
    };

    // 存入首选项
    preferencesUtils.putString(PreferencesConstants.SCREEN_READ_SETTING, JSON.stringify(region))
    console.log(TAG, 'region =' + JSON.stringify(region))

    promptAction.showToast({
      message: '保存成功',
    })
    // 返回上一页
    this.pathStack.pop();
  }

  // 处理拖拽手势 - 自由拖拽调整识别区域
  private handlePanGesture = (event: GestureEvent) => {
    if (!this.isDragging) {
      return;
    }

    const currentY = event.fingerList[0].globalY;

    // 计算识别区域参数
    const minY = Math.min(this.startPoint.y, currentY);
    const maxY = Math.max(this.startPoint.y, currentY);

    // 定义底部操作区域高度
    const bottomOperationAreaHeight = 100;
    // 计算可用的最大高度（页面高度减去底部操作区域高度）
    const maxAvailableHeight = this.pageHeight - bottomOperationAreaHeight;

    // 应用边界限制
    this.cropAreaY = Math.max(0, minY);

    // 限制识别区域高度，确保不超过底部操作区域
    const calculatedHeight = maxY - minY;
    const maxAllowedHeight = maxAvailableHeight - this.cropAreaY;
    this.cropAreaHeight = Math.min(calculatedHeight, maxAllowedHeight);

    // 确保识别区域高度不为负数
    if (this.cropAreaHeight < 0) {
      this.cropAreaHeight = 0;
    }
    console.log(TAG, JSON.stringify(this.cropAreaY))
    console.log(TAG, JSON.stringify(this.cropAreaY))
  }

  build() {
    NavDestination() {
      Stack({ alignContent: Alignment.Top }) {
        Column() {
          // 主要识别区域
          Column() {
            // 上部分蒙层
            Row()
              .width('100%')
              .height(this.cropAreaY)

            // 识别区域
            Stack() {
              // 识别区域背景
              Column()
                .width('100%')
                .height('100%')
                .backgroundColor(this.isDragging ? '#fffc8d56' : '#FD7D3F')

              Image($r("app.media.ic_area"))
                .height(this.cropAreaHeight < 50 ? '100%' : 50)
                .objectFit(ImageFit.Contain)
            }
            .width('100%')
            .opacity(this.selectedImageUri ? 0.5 : 1)
            .height(this.cropAreaHeight)

            // 下部分蒙层
            Row()
              .width('100%')
              .layoutWeight(1)
          }
          .layoutWeight(1)
          .gesture(
            PanGesture({ fingers: 1, distance: 1 })
              .onActionStart((event: GestureEvent) => {
                this.isDragging = true;
                this.startPoint = {
                  x: event.fingerList[0].globalX,
                  y: event.fingerList[0].globalY
                };
                console.log('开始拖拽识别');
              })
              .onActionUpdate((event: GestureEvent) => {
                this.handlePanGesture(event);
              })
              .onActionEnd((event: GestureEvent) => {
                this.isDragging = false;
                console.log('结束拖拽识别');
              })
          )

          // 底部操作区域
          Column() {
            Row() {
              // 选取按钮
              Column() {
                Image($r('app.media.ic_photo'))
                  .width(22)
                  .height(22)
                  .fillColor('#333333')
                Text('选取')
                  .fontSize(14)
                  .fontColor('#333333')
                  .margin({ top: 4 })
              }
              .padding({ left: 20 })
              .onClick(() => {
                this.selectFromGallery();
              })

              Blank()

              // 取消按钮
              Button('取消')
                .backgroundColor(Color.White)
                .fontColor('#FF7F50')
                .fontSize(18)
                .borderWidth(2)
                .borderColor('#FF7F50')
                .borderRadius(25)
                .width(152)
                .height(50)
                .onClick(() => {
                  this.pathStack.pop();
                })

              // 保存按钮
              Button('保存')
                .backgroundColor('#FF7F50')
                .fontColor(Color.White)
                .fontSize(18)
                .borderRadius(25)
                .width(152)
                .height(50)
                .margin({ left: 12 })
                .onClick(() => {
                  this.saveSettings();
                })
            }
            .width('100%')
            .height(54)

            Text('提示：先在答题界面截图，选取图片设置题目区域更精确。')
              .fontSize(12)
              .fontWeight(FontWeight.Bold)
              .fontColor('#333333')
              .height(20)
              .textAlign(TextAlign.Center)
              .margin({ top: 8 })
          }
          .width('100%')
          .height(100)
          .backgroundColor(Color.White)
        }
        .width('100%')
        .height('100%')
      }
      .onAreaChange((oldValue: Area, newValue: Area) => {
        // 获取页面尺寸
        this.pageHeight = Number(newValue.height);

        console.log(TAG, '页面尺寸:', this.pageHeight)
      })
    }
    .hideTitleBar(true)
    .backgroundColor(this.selectedImageUri ? Color.Transparent : '')
    .backgroundImage(this.selectedImageUri)
    .backgroundImageSize(ImageSize.Cover)
  }
}

// 位置接口定义
interface Position {
  x: number;
  y: number;
}