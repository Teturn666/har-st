import { Context } from "@kit.AbilityKit"
import {  window } from "@kit.ArkUI"

export class ScreenManager {
 // 全屏
  async full(ctx:Context) {
    const win =await window.getLastWindow(ctx || getContext())
    win.setWindowLayoutFullScreen(true)
   return  px2vp(win.getWindowAvoidArea(window.AvoidAreaType.TYPE_SYSTEM).topRect.height)

  }

  // 退出全屏
  async exitFull(ctx:Context) {
    const win =await window.getLastWindow(ctx || getContext())
    win.setWindowLayoutFullScreen(false)

  }



}

export const screenManager = new ScreenManager()