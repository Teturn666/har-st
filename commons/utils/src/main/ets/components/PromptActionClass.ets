import { BusinessError } from '@kit.BasicServicesKit';
import { ComponentContent, promptAction, UIContext } from '@kit.ArkUI';
import { hilog } from '@kit.PerformanceAnalysisKit';

export class PromptActionClass {
  static ctx: UIContext;
  static contentNode: ComponentContent<Object>;
  static options: promptAction.BaseDialogOptions;

  public static setContext(context: UIContext) {
    PromptActionClass.ctx = context;
  }


  public static setContentNode(node: ComponentContent<Object>) {
    PromptActionClass.contentNode = node;
  }


  public static setOptions(options: promptAction.BaseDialogOptions) {
    PromptActionClass.options = options;
  }


  public static openDialog() {
    if (PromptActionClass.contentNode !== null) {
      PromptActionClass.ctx.getPromptAction()
        .openCustomDialog(PromptActionClass.contentNode, PromptActionClass.options)
        .then(() => {
          hilog.info(0xFF00, 'TAG', 'OpenCustomDialog complete');
        })
        .catch((error: BusinessError) => {
          let message = (error as BusinessError).message;
          let code = (error as BusinessError).code;
          hilog.info(0xFF00, 'TAG', `OpenCustomDialog args error code is ${code}, message is ${message}`);
        })
    }
  }


  public static closeDialog(contentNode: ComponentContent<Object>) {
    if (PromptActionClass.contentNode !== null) {
      PromptActionClass.ctx.getPromptAction()
        .closeCustomDialog(contentNode)
        .then(() => {
          hilog.info(0xFF00, 'TAG', 'CloseCustomDialog complete');
        })
        .catch((error: BusinessError) => {
          let message = (error as BusinessError).message;
          let code = (error as BusinessError).code;
          hilog.info(0xFF00, 'TAG', `CloseCustomDialog args error code is ${code}, message is ${message}`);
        })
    }
  }


  public static updateDialog(options: promptAction.BaseDialogOptions) {
    if (PromptActionClass.contentNode !== null) {
      PromptActionClass.ctx.getPromptAction()
        .updateCustomDialog(PromptActionClass.contentNode, options)
        .then(() => {
          hilog.info(0xFF00, 'TAG', 'UpdateCustomDialog complete');
        })
        .catch((error: BusinessError) => {
          let message = (error as BusinessError).message;
          let code = (error as BusinessError).code;
          hilog.info(0xFF00, 'TAG', `UpdateCustomDialog args error code is ${code}, message is ${message}`);
        })
    }
  }
}