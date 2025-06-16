export class ColorUtil {
  static rgbToHex(r: number, g: number, b: number): string {
    const toHex = (value: number) => value.toString(16).padStart(2, '0').toUpperCase();
    const result = `#${toHex(Math.floor(r))}${toHex(Math.floor(g))}${toHex(Math.floor(b))}`;
    return result
  }

  static argbToHex(a: number, r: number, g: number, b: number): string {
    const toHex = (value: number) => value.toString(16).padStart(2, '0').toUpperCase();
    const result = `#${toHex(Math.floor(a))}${toHex(Math.floor(r))}${toHex(Math.floor(g))}${toHex(Math.floor(b))}`;
    return result
  }

  static hexToArgb(hex: string): [number, number, number, number] {
    // 确保十六进制字符串以#开头，并且长度正确
    if (hex.startsWith('#')) {
      hex = hex.slice(1);
    }

    if (hex.length !== 6 && hex.length !== 8) {
      throw new Error('Invalid HEX color. It should be in the format #RRGGBB or #AARRGGBB.');
    }

    let a = 255; // 默认透明度为不透明

    // 如果有透明度信息，则解析透明度
    if (hex.length === 8) {
      a = parseInt(hex.slice(0, 2), 16); // 透明度
      hex = hex.slice(2); // 去掉透明度部分
    }

    // 解析红色、绿色和蓝色分量
    const r = parseInt(hex.slice(0, 2), 16);
    const g = parseInt(hex.slice(2, 4), 16);
    const b = parseInt(hex.slice(4, 6), 16);

    return [a, r, g, b]; // 返回ARGB格式
  }

  static hsvToRgb(h: number, s: number, v: number): [number, number, number] {
    // 确保输入值在有效范围内
    h = h % 360; // 色相的范围是0-360度
    s = Math.max(0, Math.min(1, s)); // 饱和度的范围是0-1
    v = Math.max(0, Math.min(1, v)); // 明度的范围是0-1

    let r: number, g: number, b: number;

    const i = Math.floor(h / 60) % 6;
    const f = (h / 60) - i;
    const p = v * (1 - s);
    const q = v * (1 - f * s);
    const t = v * (1 - (1 - f) * s);

    switch (i) {
      case 0:
        r = v;
        g = t;
        b = p;
        break;
      case 1:
        r = q;
        g = v;
        b = p;
        break;
      case 2:
        r = p;
        g = v;
        b = t;
        break;
      case 3:
        r = p;
        g = q;
        b = v;
        break;
      case 4:
        r = t;
        g = p;
        b = v;
        break;
      default:
        r = v;
        g = p;
        b = q; break;
    }

    // 将RGB值从0-1的范围转换到0-255的范围
    return [Math.round(r * 255), Math.round(g * 255), Math.round(b * 255)];
  }

  static rgbToHsv(r: number, g: number, b: number): [number, number, number] {
    // 将RGB值从0-255的范围转换到0-1的范围
    r = r / 255;
    g = g / 255;
    b = b / 255;

    const max = Math.max(r, g, b);
    const min = Math.min(r, g, b);
    let h: number, s: number, v = max;

    const d = max - min;
    s = max === 0 ? 0 : d / max;

    if (max === min) {
      h = 0; // 颜色是灰色时，没有色相
    } else {
      switch (max) {
        case r:
          h = (g - b) / d + (g < b ? 6 : 0);
          break;
        case g:
          h = (b - r) / d + 2;
          break;
        default:
          h = (r - g) / d + 4; break;
      }
      h /= 6;
    }

    // 将色相从0-1的范围转换到0-360的范围
    h = h * 360;

    return [h, s, v];
  }

  static hsvToHex(h: number, s: number, v: number): string {
    let rgb = ColorUtil.hsvToRgb(h, s, v)
    return ColorUtil.rgbToHex(rgb[0], rgb[1], rgb[2])
  }

  static aHsvToHex(a: number, h: number, s: number, v: number): string {
    let rgb = ColorUtil.hsvToRgb(h, s, v)
    return ColorUtil.argbToHex(a, rgb[0], rgb[1], rgb[2])
  }

  static expandHexColor(hex: string): string {
    // 如果已经是六位颜色，则直接返回
    if (hex.length === 6) {
      return hex;
    }

    // 如果是简写的三位颜色，扩展为六位
    if (hex.length === 3) {
      let expandedHex = '';
      for (let i = 0; i < hex.length; i++) {
        expandedHex += hex[i] + hex[i];
      }
      return expandedHex;
    }

    if (hex.length < 3) {
      return 'FFFFFF'
    }

    // 对于长度在3到6之间的颜色，在后面补齐 'F'
    let expandedHex = hex;
    while (expandedHex.length < 6) {
      expandedHex += 'F';
    }

    return expandedHex;
  }
}