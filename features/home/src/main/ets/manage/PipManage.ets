// 画中画控制器单例
import { BuilderNode, NodeController, PiPWindow } from '@kit.ArkUI';
import { BusinessError } from '@kit.BasicServicesKit';
import { PreferencesConstants, preferencesUtils } from 'utils';

const TAG = 'PipManager';

// 自定义XComponentController
class CustomXComponentController extends XComponentController {
}

interface ParamsData {
  answer: string;
  question: string;
}

export class Params {
  answer: string = '';
  question: string = '';

  constructor(data: ParamsData) {
    this.answer = data.answer;
    this.question = data.question;
  }
}

// 开发者可以通过@Builder装饰器实现布局构建
@Builder
function buildPipUI(params: Params) {
  Column() {
    Text(params.answer)
      .fontSize(PipManager.fontSize || 20)
      .fontColor(PipManager.optionColor || '#fffadf07')
      .minFontSize(PipManager.fontSize || 15)
      .maxFontSize(PipManager.fontSize || 30)
      .maxLines(2)
      .textOverflow({ overflow: TextOverflow.Ellipsis })
      .heightAdaptivePolicy(TextHeightAdaptivePolicy.MAX_LINES_FIRST)
    Text(params.question)
      .fontSize(PipManager.fontSize || 20)
      .fontColor(PipManager.titleColor || Color.Red)
      .minFontSize(PipManager.fontSize || 12)
      .maxFontSize(PipManager.fontSize || 30)
      .maxLines(5)
      .textOverflow({ overflow: TextOverflow.Ellipsis })
      .heightAdaptivePolicy(TextHeightAdaptivePolicy.MAX_LINES_FIRST)
      .layoutWeight(1)
  }
  .width('100%')
  .height('100%')
  .padding(15)
  .backgroundColor(PipManager.floatingColor || Color.Black)
  .alignItems(HorizontalAlign.Center)
  .justifyContent(FlexAlign.Center)
}

// 开发者可通过继承NodeController实现自定义UI控制器
class TextNodeController extends NodeController {
  private message: Params;
  private textNode: BuilderNode<[Params]> | null = null;

  constructor(message: Params) {
    super();
    this.message = message;
  }

  // 通过BuilderNode加载自定义布局
  makeNode(context: UIContext): FrameNode | null {
    this.textNode = new BuilderNode(context);
    this.textNode.build(wrapBuilder<[Params]>(buildPipUI), this.message);
    return this.textNode.getFrameNode();
  }

  // 开发者可自定义该方法实现布局更新
  update(param: Params): void {
    console.log(`update param: ${param}`);
    if (this.textNode !== null) {
      this.textNode.update(param);
    }
  }
}

export class PipManager {
  private static instance: PipManager = new PipManager();
  private pipController?: PiPWindow.PiPController;
  private nodeController?: TextNodeController;
  private readonly mXComponentController: CustomXComponentController;
  private curState: string = '';
  static titleColor: string = '';
  static optionColor: string = '';
  static floatingColor: string = '';
  static fontSize: number = 0;
  stopCallBack: Function = () => {
  };

  public static getInstance(): PipManager {
    return PipManager.instance;
  }

  private constructor() {
    this.mXComponentController = new CustomXComponentController();
  }

  private onActionEvent(control: PiPWindow.ControlEventParam): void {
    switch (control.controlType) {
      case PiPWindow.PiPControlType.VIDEO_PLAY_PAUSE:
        if (control.status === PiPWindow.PiPControlStatus.PAUSE) {
          // 停止视频
        } else if (control.status === PiPWindow.PiPControlStatus.PLAY) {
          // 播放视频
        }
        break;
      case PiPWindow.PiPControlType.VIDEO_NEXT:
        // 切换到下一个视频
        break;
      case PiPWindow.PiPControlType.VIDEO_PREVIOUS:
        // 切换到上一个视频
        break;
      case PiPWindow.PiPControlType.FAST_FORWARD:
        // 视频进度快进
        break;
      case PiPWindow.PiPControlType.FAST_BACKWARD:
        // 视频进度后退
        break;
      default:
        console.warn(TAG, `Unhandled control type: ${control.controlType}`);
        break;
    }
    console.info(TAG, `onActionEvent, controlType: ${control.controlType}, status: ${control.status}`);
  }

  // 监听画中画生命周期
  onStateChange(state: PiPWindow.PiPState, reason: string) {
    let curState: string = '';
    switch (state) {
      case PiPWindow.PiPState.ABOUT_TO_START:
        curState = "ABOUT_TO_START";
        break;
      case PiPWindow.PiPState.STARTED:
        curState = "STARTED";
        break;
      case PiPWindow.PiPState.ABOUT_TO_STOP:
        curState = "ABOUT_TO_STOP";
        break;
      case PiPWindow.PiPState.STOPPED:
        curState = "STOPPED";
        this.setAutoStart(false)
        this.stopCallBack()
        break;
      case PiPWindow.PiPState.ABOUT_TO_RESTORE:
        curState = "ABOUT_TO_RESTORE";
        break;
      case PiPWindow.PiPState.ERROR:
        curState = "ERROR";
        break;
      default:
        break;
    }
    this.curState = curState;
    console.info(TAG, `onStateChange: ${curState}, reason: ${reason}`);
  }

  // 解注册监听
  public unregisterPipStateChangeListener(): void {
    console.info(TAG, 'unregisterPipStateChangeListener');
    if (this.pipController) {
      this.pipController.off('stateChange');
      this.pipController.off('controlEvent');
    }
  }

  public getXComponentController(): CustomXComponentController {
    return this.mXComponentController;
  }

  // 步骤1：创建画中画控制器，注册生命周期事件以及控制事件回调
  public async init(ctx: Context, stopCallBack: Function = () => {
  }): Promise<void> {
    if (this.pipController) {
      console.info(TAG, 'PiP controller already initialized');
      return;
    }

    console.info(TAG, 'Initializing PiP controller');

    if (!PiPWindow.isPiPEnabled()) {
      console.error(TAG, 'Picture in picture disabled for current OS');
      return;
    }


    this.nodeController = new TextNodeController(new Params({ answer: '', question: '暂未搜索到该题' }));
    const config: PiPWindow.PiPConfiguration = {
      context: ctx,
      componentController: this.getXComponentController(),
      templateType: PiPWindow.PiPTemplateType.VIDEO_LIVE,
      customUIController: this.nodeController,
      controlGroups: [],
      contentWidth: 1920,
      contentHeight: 1080,
    };

    try {
      this.pipController = await PiPWindow.create(config);
      this.pipController.setAutoStartEnabled(true);

      // 注册事件监听
      this.pipController.on('stateChange', (state: PiPWindow.PiPState, reason: string) => {
        this.onStateChange(state, reason);
      });

      this.pipController.on('controlEvent', (control: PiPWindow.ControlEventParam) => {
        this.onActionEvent(control);
      });

      console.info(TAG, 'PiP controller initialized successfully');
    } catch (err) {
      const error = err as BusinessError;
      console.error(TAG, `Failed to create pip controller. Cause: ${error.code}, message: ${error.message}`);
    }
  }

  // 步骤2：创建画中画控制器实例后，通过startPiP接口启动画中画
  public async startPip(): Promise<void> {
    if (!this.pipController) {
      console.error(TAG, 'PiP controller not initialized');
      return;
    }

    try {
      await this.pipController.startPiP();
      console.info(TAG, 'Succeeded in starting pip');
    } catch (err) {
      const error = err as BusinessError;
      console.error(TAG, `Failed to start pip. Cause: ${error.code}, message: ${error.message}`);
    }
  }

  // 步骤3：更新媒体源尺寸信息
  public updateContentSize(width: number, height: number): void {
    if (this.pipController) {
      this.pipController.updateContentSize(width, height);
    } else {
      console.warn(TAG, 'Cannot update content size: PiP controller not initialized');
    }
  }

  // 步骤4：关闭画中画
  public async stopPip(): Promise<void> {
    if (!this.pipController) {
      console.warn(TAG, 'PiP controller not initialized, nothing to stop');
      return;
    }

    try {
      await this.pipController.stopPiP();
      console.info(TAG, 'Succeeded in stopping pip');
    } catch (err) {
      const error = err as BusinessError;
      console.error(TAG, `Failed to stop pip. Cause: ${error.code}, message: ${error.message}`);
    }
  }

  // 设置后台画中画自动启动
  public setAutoStart(autoStart: boolean): void {
    if (this.pipController) {
      this.pipController.setAutoStartEnabled(autoStart);
    } else {
      console.warn(TAG, 'Cannot set auto start: PiP controller not initialized');
    }
  }

  // 设置更新画中画静态参数
  public updatePipUI(param: Params): void {
    if (this.nodeController) {
      this.nodeController.update(param)
    }
  }

  /**
   * 设置PIP管理器的样式配置
   * 从用户偏好设置中加载悬浮窗的颜色和字体配置
   */
  public setPipManagerStyles(): void {
    PipManager.titleColor = preferencesUtils.getString(PreferencesConstants.TITLE_COLOR_SETTING)
    PipManager.optionColor = preferencesUtils.getString(PreferencesConstants.OPTION_COLOR_SETTING)
    PipManager.floatingColor = preferencesUtils.getString(PreferencesConstants.FLOATING_COLOR_SETTING)
    PipManager.fontSize = preferencesUtils.getNumber(PreferencesConstants.FLOATING_TEXT_SIZE)
  }
}