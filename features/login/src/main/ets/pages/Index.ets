import router from '@ohos.router';
import LoginConstants from '../Constants/LoginConstants';
import bundleManager from '@ohos.bundle.bundleManager';
import * as wxOpenSdk from '@tencent/wechat_open_sdk';
import { OnWXResp, WXApi, WXEventHandler, APP_ID } from '../model/WXApiWrap';
import { hilog } from '@kit.PerformanceAnalysisKit';
import { promptAction } from '@kit.ArkUI';
import common from '@ohos.app.ability.common';
import { BusinessError } from '@kit.BasicServicesKit';
import { ErrCode } from '@tencent/wechat_open_sdk';
import http from '@ohos.net.http';


interface AccessTokenResponse {
  access_token?: string;
  expires_in?: number;
  refresh_token?: string;
  openid?: string;
  scope?: string;
  errcode?: number;
  errmsg?: string;
}

interface UserInfoResponse {
  openid?: string;
  nickname?: string;
  headimgurl?: string;
  sex?: number;
  province?: string;
  city?: string;
  country?: string;
  unionid?: string;
  errcode?: number;
  errmsg?: string;
}


@Entry()
@Component
export struct Index {
  @State agreementChecked: boolean = false;
  private wxApi = WXApi
  @State resultText: string = '';
  @State nickname: string = '';
  @State avatarUrl: string = '';
  private wxEventHandler = WXEventHandler


  aboutToAppear(): void {
    this.wxEventHandler.registerOnWXRespCallback(this.onWXResp);
    hilog.info(0x0000, 'TAG', 'onWXResp callback registered');
  }

  aboutToDisappear(): void {
    this.wxEventHandler.unregisterOnWXRespCallback(this.onWXResp)
  }

  private onWXResp: OnWXResp = async (resp) => {
    if (resp.errCode === ErrCode.ERR_OK) {
      promptAction.showToast({ message: '微信授权成功' });
      const authResp = resp as wxOpenSdk.SendAuthResp;
      if (authResp.code) {
        try {
          await this.fetchUserInfo(authResp.code);
        } catch (err) {
          promptAction.showToast({ message: '获取用户信息失败' });
          hilog.error(0x0000, 'TAG', `获取用户信息失败: ${err}`);
        }
      } else {
        promptAction.showToast({ message: '未获取到授权码' });
        hilog.error(0x0000, 'TAG', '授权响应缺少 code');
      }
    } else {
      promptAction.showToast({ message: `授权失败: ${resp.errStr || '未知错误'}` });
      hilog.error(0x0000, 'TAG', `授权失败: errCode=${resp.errCode}, errStr=${resp.errStr}`);
    }
    this.resultText = JSON.stringify(resp ?? {}, null, 2);
  };

  async fetchUserInfo(code: string) {
    let httpClient = http.createHttp();
    const APP_SECRET = '7c65844efba6af55e632f0145d11962f';
    let accessTokenUrl = `https://api.weixin.qq.com/sns/oauth2/access_token?appid=${APP_ID}&secret=${APP_SECRET}&code=${code}&grant_type=authorization_code`;

    try {
      // 获取 access_token
      let accessTokenResponse = await httpClient.request(accessTokenUrl, {
        method: http.RequestMethod.GET,
        connectTimeout: 10000,
        readTimeout: 10000
      });
      if (!accessTokenResponse.result) {
        throw new Error('获取 access_token 响应失败');
      }
      let tokenData: AccessTokenResponse = JSON.parse(accessTokenResponse.result.toString());
      if (!tokenData.access_token || !tokenData.openid) {
        throw new Error(`获取 access_token 失败: ${tokenData.errcode || '未知错误'}, ${tokenData.errmsg || ''}`);
      }

      // 获取用户信息
      let userInfoUrl = `https://api.weixin.qq.com/sns/userinfo?access_token=${tokenData.access_token}&openid=${tokenData.openid}`;
      let userInfoResponse = await httpClient.request(userInfoUrl, {
        method: http.RequestMethod.GET,
        connectTimeout: 10000,
        readTimeout: 10000
      });
      if (!userInfoResponse.result) {
        throw new Error('无法获取用户信息');
      }
      let userInfo: UserInfoResponse = JSON.parse(userInfoResponse.result.toString());
      if (!userInfo.nickname || !userInfo.headimgurl) {
        throw new Error('用户信息不完整');
      }
      this.nickname = userInfo.nickname;
      this.avatarUrl = userInfo.headimgurl;
      promptAction.showToast({ message: '用户信息获取成功' });
      hilog.info(0x0000, 'TAG', `用户信息: nickname=${userInfo.nickname}, headimgurl=${userInfo.headimgurl}`);
    } catch (err) {
      throw new Error(String(err));
    } finally {
      httpClient.destroy();
    }
  }

  async wechatLogin() {
    if (!this.agreementChecked) {
      promptAction.showToast({ message: '请先勾选并同意用户协议和隐私政策' });
      return;
    }
    try {
      let link = 'weixin://';
      let data = await bundleManager.canOpenLink(link);
      if (data) {
        let req = new wxOpenSdk.SendAuthReq();
        req.isOption1 = false;
        req.nonAutomatic = true;
        req.scope = 'snsapi_userinfo';
        req.state = 'none';
        req.transaction = 'auth_' + Date.now();

        let finished = await this.wxApi.sendReq(getContext(this) as common.UIAbilityContext, req);
        hilog.info(0x0000, 'TAG', `发送授权请求完成: ${finished}`);
      } else {
        promptAction.showToast({ message: '请安装微信' });
        hilog.warn(0x0000, 'TAG', '微信未安装');
      }
    } catch (err) {
      let message = (err as BusinessError).message;
      hilog.error(0x0000, 'TAG', `canOpenLink 失败: ${message}`);
      promptAction.showToast({ message: '检查微信安装失败' });
    }
  }

  build() {
    Column() {
      Row() {
        Image($r('app.media.ic_back'))
          .width(32)
          .height(32)
          .margin({ left: 16, top: 12 })
          .onClick(() => {
            router.back();
          })
        Text('登录')
          .fontSize(18)
          .textAlign(TextAlign.Center)
          .fontWeight(600)
          .flexGrow(1)
          .margin({ top: 12 })

        Blank()
          .width(32)
          .margin({ right: 16, top: 12 })
      }
      .width('100%')
      .height(48)
      .backgroundColor(Color.White)
      .justifyContent(FlexAlign.SpaceBetween)

      Blank()
      Image($r('app.media.ic_logo'))
        .width(218)
        .height(60)

      Blank()
      Text("195******85")
        .width('80%')
        .height(48)
        .margin({ top: 50 })
        .fontWeight(FontWeight.Bold)
        .textAlign(TextAlign.Center)
        .fontSize(24)
      Text("华为账号绑定号码")
        .width('80%')
        .textAlign(TextAlign.Center)
        .fontSize(12)

      Button('华为账号一键登录', { type: ButtonType.Normal, stateEffect: true })
        .borderRadius(8)
        .backgroundColor('#f64e4d')
        .width('60%')
        .height(48)
        .margin({ top: 20 })

      Button('微信快捷登录', { type: ButtonType.Normal, stateEffect: true })
        .borderRadius(8)
        .backgroundColor('#0ac160')
        .width('60%')
        .height(48)
        .margin({ top: 12 })
        .onClick(()=>{
          this.wechatLogin()
        })

      // 底部协议部分
      Flex({ direction: FlexDirection.Row, wrap: FlexWrap.Wrap }) {
        Image(this.agreementChecked ? $r('app.media.ic_protocoled') : $r('app.media.ic_protocol'))
          .width(12)
          .height(12)
          .margin({ right: 4 })
          .onClick(() => {
            this.agreementChecked = !this.agreementChecked;
          })
        Text('我已阅读并同意')
          .fontSize(12)
          .fontColor(Color.Black)
          .margin({ right: 4 })
        Text('《用户协议》')
          .fontSize(12)
          .fontColor('#007AFF')
            .onClick(() => {
                      router.pushNamedRoute({
                        name: LoginConstants.ROUTER_WEB, params: {
                          url: LoginConstants.USER_AGREEMENT_URL,
                          title: "用户协议"
                        }
                      },router.RouterMode.Single)
                    })
          .margin({ right: 4 })
        Text('《隐私政策》')
          .fontSize(12)
          .fontColor('#007AFF')
          .onClick(() => {
            router.pushNamedRoute({
              name: LoginConstants.ROUTER_WEB, params: {
                url: LoginConstants.USER_PRIVACY_URL,
                title: "隐私政策"
              }
            },router.RouterMode.Single)
          })
          .margin({ right: 4 })
        Text('和')
          .fontSize(12)
          .fontColor(Color.Black)
          .margin({ right: 4 })
        Text('《华为账号用户认证协议》')
          .fontSize(12)
          .fontColor('#007AFF')
          .onClick(() => {
            // router.pushUrl('https://example.com/terms');
          })
      }
      .width('80%')
      .margin({ top: 40, bottom: 40 })


        Text(this.resultText)
          .width('80%')
          .fontSize(17)
          .lineHeight(20)

    }
    .height('100%')
    .width('100%')
  }
}
