// Phase 1406 — 原版计划本目录（x1d / e2d / y1d 枚举等价物）。
// 原版：x1d=Planner 枚举（1.4.2 仅 ACADEMIC_2026_2027），
//   e2d=PlannerWeekStart{MONDAY(0),SUNDAY(1)}（F=文件名段 monday_start/
//   sunday_start），y1d=PlannerCover{PIN/STRIPE/LATTICE/SCALLOP/ARCHES ×4，
//   F=序号,G=ui_planners__cover_*_N.webp drawable,H=cover_* 名字 res}。
//   a2d.a 以 "planners/academic_planner_2026_2027-<e2d.F>.pdf" 读资产进
//   导入管线；d2d(y1d) 默认构造 = 首个封面 + MONDAY。
// Harmony：PDF 与封面 webp 逐字节拷入 rawfile/planners/；封面经
//   cover_preset="planner_<index>" 持久化（见 NoteCoverCatalog 图像源分支）。

export interface PlannerWeekStart {
  // 原版 e2d 序（MONDAY=0,SUNDAY=1）；F=PDF 文件名段。
  key: string;
  fileSegment: string;
  nameRes: Resource;
}

export const PLANNER_WEEK_STARTS: PlannerWeekStart[] = [
  { key: 'monday', fileSegment: 'monday_start',
    nameRes: $r('app.string.planner_week_start_monday') },
  { key: 'sunday', fileSegment: 'sunday_start',
    nameRes: $r('app.string.planner_week_start_sunday') },
];

// 原版 d2d(y1d) 默认构造 —— weekStart 默认 MONDAY。
export const PLANNER_DEFAULT_WEEK_START: PlannerWeekStart =
  PLANNER_WEEK_STARTS[0];

export interface PlannerCover {
  // 原版 y1d 序：PIN/STRIPE=0 LATTICE=1 SCALLOP=2 ARCHES=3；
  // 序号即 drawable 尾标 ui_planners__cover_*_<index>.webp。
  index: number;
  // 持久化键（cover_preset 值），不与 iw2 预设键冲突。
  presetKey: string;
  nameRes: Resource;
  rawfilePath: string;
}

export const PLANNER_COVERS: PlannerCover[] = [
  { index: 0, presetKey: 'planner_0',
    nameRes: $r('app.string.planner_cover_pinstripe'),
    rawfilePath: 'planners/cover_0.webp' },
  { index: 1, presetKey: 'planner_1',
    nameRes: $r('app.string.planner_cover_lattice'),
    rawfilePath: 'planners/cover_1.webp' },
  { index: 2, presetKey: 'planner_2',
    nameRes: $r('app.string.planner_cover_scallop'),
    rawfilePath: 'planners/cover_2.webp' },
  { index: 3, presetKey: 'planner_3',
    nameRes: $r('app.string.planner_cover_arches'),
    rawfilePath: 'planners/cover_3.webp' },
];

export interface PlannerEntry {
  // 原版 x1d.F —— planner id（analytics planner.id 键值）。
  id: string;
  // 原版 ui_planners__planner_academic_2026_2027 标题 res。
  titleRes: Resource;
}

export const ACADEMIC_PLANNER: PlannerEntry = {
  id: 'academic_planner_2026_2027',
  titleRes: $r('app.string.planner_academic_2026_2027'),
};

// 原版 x1d.H 列表（当前仅一项）。
export const PLANNERS: PlannerEntry[] = [ACADEMIC_PLANNER];

// 原版 a2d：planners/<id>-<e2d.F>.pdf 资产路径拼接。
export function plannerPdfPath(entry: PlannerEntry,
  weekStart: PlannerWeekStart): string {
  return `planners/${entry.id}-${weekStart.fileSegment}.pdf`;
}

// 原版 x1d.b() —— 分区卡预览取首个封面（缺封面仅记日志并回退）。
export function plannerDefaultCover(entry: PlannerEntry): PlannerCover {
  return PLANNER_COVERS[0];
}

export function findPlannerCoverByPresetKey(key: string | null | undefined):
  PlannerCover | null {
  if (key === null || key === undefined) {
    return null;
  }
  for (const cover of PLANNER_COVERS) {
    if (cover.presetKey === key) {
      return cover;
    }
  }
  return null;
}
