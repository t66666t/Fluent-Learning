# Fluent Learning 体验深化 Plan（Phase 14+）

> 读者：Flutter 代码助手 / 调试助手  
> 工程：`/workspace/fluent-learning/repo` → https://github.com/t66666t/Fluent-Learning  
> 基线：Phase 18 收口于 `e9662ab` 之上（含 Phase 14–17）  
> 前置：Phase 0–13 已合入；本轮聚焦「对照最初提示词补齐 + 体验做到最好」  
> 交付：每阶段验收后推 `main`（不打 APK）；**Phase 18 本机收口不自动 push**（由调试助手签收后再推）

---

## 0. 最初提示词对照（缺口清单）

| # | 要求 | 状态 | 说明 |
|---|------|------|------|
| 1 | 五 Tab：首页 / 媒体库 / 日历 / 中心 / 我的 | ✅ | `MainShell` IndexedStack |
| 2 | **冷启进首页**（不要媒体库） | ✅ | `main.dart`：`MainShell()` 默认 `initialIndex: 0`（Phase 14） |
| 3 | 系统级选片 Media Picker | ✅ | `lib/system/media_picker/` → `InternalVideoPickerDialog` |
| 4 | 模型 / 下载 / 处理 三中心可复用 | ✅偏浅 | 大厅徽章 + 重试；统一 download job 队列 / OCR enqueue 门面仍记债 |
| 5 | 学习单元：选媒体/夹、计划学完、绑日历、首页推荐 | ✅偏浅 | 进度/推荐/日历已接线；UI 仅 dueDate（weekday 等见债） |
| 6 | 媒体详细属性 + 可扩展 | ✅ | `media_properties_page` + sync 字段；Phase 18 补 `publishedAt` |
| 7 | Apple Music 气质：干净、小圆角、跨端适配 | ⚠️ | theme 有基础；多路径仍 `app_toast`/悬浮 SnackBar |
| 8 | 保留播放核心 | ✅ | 非必要不改 playback |
| 9 | 数据为未来同步预留 | ✅ | SyncEntity / 导出导入（Mine） |
| 10 | 共用能力系统服务化，非页内各自实现 | ⚠️ | 主路径已收拢；旧 screen 仍散落 toast/入口 |
| 11 | 首页驱动学习（推荐+日历 due） | ✅ | 空态 CTA + 继续学 + 推荐理由；日历「开始学」 |
| 12 | 播放页能力走中心（下载/处理/模型） | ✅偏浅 | 已入队可见；反馈与失败重试体验一般 |

**本轮硬修复**：#2 冷启 ✅（Phase 14）。其余 Phase 14–18 加深后收口。

---

## 总路线图

| 阶段 | 目标 | 验收 |
|------|------|------|
| **14** | 冷启首页 + 首启体验 | ✅ 冷启首页；空首页 CTA |
| **15** | 首页 × 学习单元体验加深 | ✅ 继续学 / 推荐理由 / 页内完成反馈 / 日历返回保日 |
| **16** | 媒体库 / 选片 / 三中心体验 | ✅ 空态组件；大厅徽章；重试；底栏同步 |
| **17** | 日历 × 单元深度绑定 | ✅ 日详情→单元/播放；due 标签；「开始学」 |
| **18** | 对照收口 + 回归 | ✅ 上表无 ❌；冒烟过；`publishedAt`；债记清（推送另签） |

循环：架构开工单 → 代码助手 → 调试助手 → 推 GitHub → 下一阶段。

---

## Phase 14 — 冷启首页 + 首启体验

**状态：✅ 已实现**（`19480d6`）

1. `MainShell(initialIndex: 1)` → 默认 `0` / `const MainShell()`
2. 首页空态：主按钮「新建学习单元」/「从媒体库生成学习单元」+ 次按钮「去媒体库导入」

---

## Phase 15 — 首页 × 学习单元加深

**状态：✅ 已实现**（`d6d9c1e`）

继续学一键可达；推荐理由必显；单元页内成功条；日历返回保持日期。

---

## Phase 16 — 库 / 选片 / 中心体验

**状态：✅ 已实现**（`7502fb5`）

`MediaLibraryEmptyState`；Centers 大厅徽章；处理中心重试/查看结果；`librarySelectionActive` 同步底栏。

---

## Phase 17 — 日历深度

**状态：✅ 已实现**（`e9662ab`）

日详情「开始学」→ `LearningUnitDetailPage.autoContinueLearning`；图例 / `dueRelativeLabel` 对齐。

---

## Phase 18 — 对照收口

**状态：✅ 本机收口**（相对 `e9662ab`；**未 commit/push**）

**要做 / 已做**：
1. ✅ 更新本文件顶部对照表与 Phase 14–18 状态
2. ✅ 冒烟（代码路径核对）：冷启首页、选片、建单元、播+进度回写、入队、下载入口、属性、日历「开始学」、Mine metadata 导出
3. ✅ 小补丁：`VideoItem.publishedAt`（nullable、JSON 兼容）+ `MediaPropertiesPage`「发布时间」
4. ✅ 记债：weekday 日程高级能力 / 统一下载队列 / OCR enqueue 门面（本阶段不实现）
5. ⏭ 推 GitHub：由调试助手签收后再推（本轮约束不 commit/push）

**验收**：调试助手签收；群里贴最终 SHA。

---

## 给代码助手的约束（沿用）

1. 先确认已在既有 Phase 合入点之上开工（禁止盖掉用户本地加料）
2. 切口接线；不重写 `MediaPlaybackService` / 巨型 download
3. 不新建第二套选片 UI
4. 新能力走 `lib/system/*`；Provider 细粒度 notifier
5. 每阶段可编译；推 GitHub；不默认 APK
6. Windows `ffprobe` CMake 修复保留

## 开工顺序

Phase 14 → 15 → 16 → 17 → **18（收口）** — 本轮完成。

---

## 审计补充与技术债（Phase 18 收口后仍有效）

更深缺口（**本轮明确不做**，留给后续）：
- 处理中心：转录队列真；OCR/合成入口页已挂，但 **OCR enqueue 统一门面**仍浅（`ProcessingJobType` 部分「尚未接入」）
- 下载中心：路由大厅，**非统一 download job 队列**
- 学习单元日程：**UI 仅 dueDate**；模型已有 `startDate` / `weekdayMask` / `targetMinutesPerDay`，**weekday 日程高级能力未做**（刻意不做，记债）
- 库 Tab 仍嵌旧 `HomeScreen`；双底栏仅缓解
- 无 GoRouter / 无 arb 国际化（不强制）
- Centers「试用选片」、Model Whisper/Q&A 仍占位
- Apple Music 气质：旧路径 `app_toast` 未清完

Phase 18 已补：媒体属性 `publishedAt`（可空；旧 JSON 无该键 → null）。
