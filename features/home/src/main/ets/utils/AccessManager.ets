import { abilityAccessCtrl, bundleManager, Permissions } from "@kit.AbilityKit";
import { promptAction } from "@kit.ArkUI";

export  class AccessManager{

  async CheckCamera(permissionName:Permissions[],success:()=>void){

    const app = bundleManager.getBundleInfoForSelfSync(bundleManager.BundleFlag.GET_BUNDLE_INFO_WITH_APPLICATION)
    const manager = abilityAccessCtrl.createAtManager()

    const  listResult=permissionName.map(p=> manager.checkAccessTokenSync(app.appInfo.accessTokenId,p)
    )
    // 检查所有的权限的结果
    const isOK = listResult.every(res => res === abilityAccessCtrl.GrantStatus.PERMISSION_GRANTED)
    if (isOK){
      success()
    }else {
      const  req= await  manager.requestPermissionsFromUser(getContext(),permissionName)
      const result= req.authResults.every(p=>p===0)
      if (result) {
        success()
      }else {
        const  req= await  manager.requestPermissionOnSetting(getContext(),permissionName)
        const   result= req.every(p=>p===abilityAccessCtrl.GrantStatus.PERMISSION_GRANTED)
        if (result){
          success()
        }else {
          promptAction.showToast({
            message: "请打开权限"
          })
        }
      }
    }

  }

}
export  const  accessManager=new AccessManager()