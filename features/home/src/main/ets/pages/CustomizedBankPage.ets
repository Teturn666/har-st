import { TitleBar } from 'widget'
import { router } from '@kit.ArkUI'

@Entry({routeName:"customizedBankPage"})
@Component
struct CustomizedBankPage {
  @State textValue: string = '';
  @State isRemarkBank:boolean = false;
  @State textContent:string = '';
  dialogController: CustomDialogController | null = new CustomDialogController({
    builder: CustomDialogExample({
      confirm: () => {
        this.onAccept()
      },
      textValue: this.textValue,
      isRemarkBank:this.isRemarkBank,
      textContent:this.textContent
    })
  });

  // 在自定义组件即将析构销毁时将dialogController置空
  aboutToDisappear() {
    this.dialogController = null;
  }


  onPageShow() {
    const params = this.getUIContext().getRouter().getParams() as Record<string, string>; // 获取传递过来的参数对象
    if (params) {
      this.dialogController?.open();
      this.textValue = params.info as string; // 获取info属性的值
    }
  }

  onAccept() {
    console.info('Callback when the second button is clicked');
  }

  build() {
    Column(){
      TitleBar({
        title: '自定义题库',
        backClick: () => {
          router.back()
          // this.textValue = "备注导入的题库名称"
          // this.textContent = "导入成功：导入数据129条"
          // this.isRemarkBank = true
          // this.dialogController?.open();
        },
      }).width('100%')

      Column(){
      Text("个人制作和导入题库遇到问题\n请联系QQ：2885403085")
        .fontSize($r('app.float.float_12vp'))
        .fontColor($r('app.color.c_f2f7ff'))
      }
      .justifyContent(FlexAlign.Center)
      .width('100%')
      .height($r('app.float.float_50vp'))
      .backgroundColor($r('app.color.c_F75A23'))

      // 文件路径信息
      Text("开始解析Excel文件：/storage/emulated/0/Android/data/com.questions.tcache/importxlsx")
        .fontSize(12)
        .fontColor($r('app.color.c_9d9d9d'))
        .margin({ top: 10, bottom: 10,left:20,right:20})
        .textAlign(TextAlign.Start)

      List({ space: 5 }) {
        ForEach(
          [
            "Sheet 1: 第2行，元数据取数目录",
            "Sheet 1: 第3行，元数据取数目录",
            "Sheet 1: 第4行，元数据取数目录",
            "Sheet 1: 第5行，元数据取数目录",
            "Sheet 1: 第6行，元数据取数目录",
            "Sheet 1: 第7行，元数据取数目录",
            "Sheet 1: 第8行，元数据取数目录",
            "Sheet 1: 第9行，元数据取数目录",
            "Sheet 1: 第10行，元数据取数目录",
            "Sheet 1: 第11行，元数据取数目录",
            "Sheet 1: 第12行，元数据取数目录",
            "Sheet 1: 第13行，元数据取数目录",
            "Sheet 1: 第14行，元数据取数目录",
            "Sheet 1: 第15行，元数据取数目录",
            "Sheet 1: 第16行，元数据取数目录",
            "Sheet 1: 第17行，元数据取数目录",
            "Sheet 1: 第18行，元数据取数目录",
            "Sheet 1: 第19行，元数据取数目录",
            "Sheet 1: 第20行，元数据取数目录",
            "Sheet 1: 第21行，元数据取数目录",
            "Sheet 1: 第22行，元数据取数目录",
            "Sheet 1: 第23行，元数据取数目录"
          ],
          (item: string) => {
            ListItem() {
              Text(item)
                .fontSize(12)
                .fontColor($r('app.color.c_9d9d9d'))
                .margin({bottom: 10 ,left:20,right:20})
                .textAlign(TextAlign.Start)
            }
          },
          (item: string) => item
        )
      }
      .height("80%")
      .width("100%")

    }

    .alignItems(HorizontalAlign.Start)
  }
}


@CustomDialog
struct CustomDialogExample {
  @Link textValue: string;
  @Link textContent: string;
  @Prop isRemarkBank : boolean;
  controller?: CustomDialogController;
  confirm: () => void = () => {
  }

  build() {
    Column({ space: 20 }) {
      if(this.isRemarkBank){
        Row(){
          Text(`${this.textValue}`)
            .fontSize($r('app.float.font_size_18fp'))
            .fontColor($r('app.color.c_9d9d9d'))
          Image($r('app.media.ic_cha'))
            .size({width:$r('app.float.font_size_16fp'),height:$r('app.float.font_size_16fp')})
            .onClick(() =>{
              this.controller?.close()
            })
        }
        .padding({left:18,top:8,right:18})
        .width('100%')
        .justifyContent(FlexAlign.SpaceBetween)
      }else {
        Row(){
          Text(`${this.textValue}`)
            .fontSize($r('app.float.font_size_18fp'))
            .fontColor($r('app.color.c_9d9d9d'))
        }
        .padding({left:18,top:8,right:18})
        .width('100%')
        .justifyContent(FlexAlign.SpaceBetween)
      }

      if(this.isRemarkBank){
        TextInput({ placeholder: '215051451510251'})
          .height(50)
          .fontSize($r('app.float.font_size_14fp'))
          .placeholderColor('#ffcbcac6')
          .backgroundColor($r('app.color.c_f3f3f3'))
          .borderRadius(5)
          .margin({left:25,right:25})
      }else {
        Text(`${this.textContent}`)
          .fontSize($r('app.float.font_size_18fp'))
          .fontColor($r('app.color.c_3f3f3f'))
          .width('90%')
          .align(Alignment.Start)

      }


      if(!this.isRemarkBank){
        Blank()
      }


      Flex({ justifyContent: FlexAlign.Center }) {
        Image($r('app.media.ic_confirm'))
          .size({ width: $r('app.float.float_106vp'), height: $r('app.float.float_40vp') })
          .onClick(() => {
            this.controller?.close();
          })
      }
      if(!this.isRemarkBank){
        Blank()
      }

    }
    .height(200)
    .padding({ top: 20 })
  }
}
