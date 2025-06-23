import { Decimal } from '@kit.ArkTS';
import { sensor } from '@kit.SensorServiceKit';

function getRealData(data: sensor.GravityResponse): number {
  let getDeviceDegree: number = 0;
  let x = data.x;
  let y = data.y;
  let z = data.z;
  if ((x * x + y * y) * 3 < z * z) {
    return getDeviceDegree;
  } else {
    let sd: Decimal = Decimal.atan2(y, -x);
    let sc: Decimal = Decimal.round(Number(sd) / 3.141592653589 * 180)
    getDeviceDegree = 90 - Number(sc);
    getDeviceDegree = getDeviceDegree >= 0 ? getDeviceDegree % 360 : getDeviceDegree % 360 + 360;
  }
  return getDeviceDegree;
}

export async function getGravity(): Promise<number> {
  let isSupported: boolean = false
  const data = await sensor.getSensorList()
  for (let i = 0; i < data.length; i++) {
    if (data[i].sensorId === sensor.SensorId.GRAVITY) {
      isSupported = true;
      break;
    }
  }
  if (!isSupported) {
    return 0;
  } else {
    const promise: Promise<number> = new Promise((resolve) => {
      sensor.once(sensor.SensorId.GRAVITY, (data: sensor.GravityResponse) => {
        resolve(getRealData(data));
      });
    })
    return promise;
  }
}