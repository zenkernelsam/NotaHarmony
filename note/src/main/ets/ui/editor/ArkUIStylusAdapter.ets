export interface ArkUIStylusSample {
  pressure: number;
  altitudeAngleRadians: number;
  orientationRadians: number;
  toolType: number;
}

export class ArkUIStylusAdapter {
  static fromTouch(touch: TouchObject, event?: TouchEvent): ArkUIStylusSample {
    const rawPressure: number = touch.pressure !== undefined ? touch.pressure :
      (event !== undefined ? event.pressure : -1);
    const pressure: number = rawPressure > 0 ? Math.min(rawPressure, 1) : -1;
    if (event === undefined || event.sourceTool !== SourceTool.Pen) {
      return {
        pressure: pressure,
        altitudeAngleRadians: -1,
        orientationRadians: -1,
        toolType: ArkUIStylusAdapter.mapToolType(event),
      };
    }

    // ArkUI tiltX/tiltY use degrees in the same [-90, 90] range as InputKit Touch.
    const tiltX: number = ArkUIStylusAdapter.toRadians(event.tiltX);
    const tiltY: number = ArkUIStylusAdapter.toRadians(event.tiltY);
    const projectionX: number = Math.tan(tiltX);
    const projectionY: number = Math.tan(tiltY);
    const projectionLength: number = Math.sqrt(
      projectionX * projectionX + projectionY * projectionY);
    if (!Number.isFinite(projectionLength) || projectionLength <= 0.000001) {
      return {
        pressure: pressure,
        altitudeAngleRadians: Math.PI / 2,
        orientationRadians: -1,
        toolType: 0,
      };
    }
    const altitude: number = Math.atan2(1, projectionLength);
    // InkInputProviderImpl converts orientation to (-sin(o), cos(o)), matching original cd0.b()/c().
    const orientation: number = Math.atan2(-projectionX, projectionY);
    return {
      pressure: pressure,
      altitudeAngleRadians: altitude,
      orientationRadians: orientation,
      toolType: 0,
    };
  }

  private static mapToolType(event?: TouchEvent): number {
    if (event !== undefined && event.sourceTool === SourceTool.Pen) {
      return 0;
    }
    if (event !== undefined && event.sourceTool === SourceTool.MOUSE) {
      return 1;
    }
    return 2;
  }

  private static toRadians(degrees: number): number {
    return Math.max(-90, Math.min(90, degrees)) * Math.PI / 180;
  }
}
