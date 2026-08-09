// T-024 文本框逻辑（§30 TextBlockInfo 简化版，纯逻辑禁止平台 import）
import { TextBlockElement, ElementType } from '../core/model/ElementTypes';
import { Point2D } from '../core/model/GeometryTypes';

export class TextBlockTool {
  // 创建文本框（双击位置）
  createTextBlock(position: Point2D, color: number, fontSize: number): TextBlockElement {
    return {
      id: this.generateId(),
      type: ElementType.TEXT,
      transform: [1, 0, 0, 0, 1, 0, 0, 0, 1],
      bounds: {
        left: position.x,
        top: position.y,
        right: position.x + 200,
        bottom: position.y + 40,
      },
      richText: '',
      textOrigin: position,
      blockWidth: 200,
      blockHeight: 40,
      rotationRadians: 0,
      contentLeftInset: 4,
      contentTopInset: 4,
      fontSize: fontSize,
      fontColor: color,
    };
  }

  // 更新文本内容（重算 bounds 高度按行数自适应，最少 40）
  updateText(element: TextBlockElement, text: string): TextBlockElement {
    const lines: number = text.split('\n').length;
    const height: number = Math.max(40, lines * (element.fontSize + 8) + element.contentTopInset * 2);
    return {
      id: element.id,
      type: ElementType.TEXT,
      transform: element.transform,
      bounds: {
        left: element.bounds.left,
        top: element.bounds.top,
        right: element.bounds.left + element.blockWidth,
        bottom: element.bounds.top + height,
      },
      richText: text,
      textOrigin: element.textOrigin,
      blockWidth: element.blockWidth,
      blockHeight: height,
      rotationRadians: element.rotationRadians,
      contentLeftInset: element.contentLeftInset,
      contentTopInset: element.contentTopInset,
      fontSize: element.fontSize,
      fontColor: element.fontColor,
    };
  }

  private generateId(): string {
    const timePart: string = Date.now().toString(36);
    const randPart: string = Math.random().toString(36).slice(2, 8);
    return timePart + randPart;
  }
}
