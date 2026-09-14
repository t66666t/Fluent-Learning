# Fluent Learning 深度完善 Plan（Phase 6+）

> 读者：Flutter 代码助手 / 调试助手  
> 工程：`/workspace/fluent-learning/repo` → 同步到 https://github.com/t66666t/Fluent-Learning  
> 已完成：Phase 0–5（五 Tab、Media Picker、三中心骨架、LearningUnit 闭环、媒体属性、包名 `fluent_learning`）  
> 交付物：**每阶段验收通过后推 GitHub `main`**（不要求 APK）  
> 硬约束：播放核心非必要不改；系统能力复用（选片/模型/下载/处理）；禁止新悬浮 Toast；小圆角、跨端适配

---

## 产品一句话（给人对齐）

用视频学东西：资料库管媒体，中心干处理，学习单元管计划，日历看进度。能共用的能力做成系统服务。

---

## 总路线图

| 阶段 | 目标 | 验收要点 |
|------|------|----------|
| **6** | 学习单元做深（进度/完成/推荐） | 播放推进单元进度；推荐不全是空壳 |
| **7** | 中心闭环（队列可见 + 播放页同步） | 播放页入队后处理中心能看到；队列可管理 |
| **8** | 媒体库 + Media Picker 打磨 | 搜索/筛选/属性入口顺；选片体验一致 |
| **9** | 反馈与 UI 治理 | 关键路径无新悬浮通知；双 Scaffold 收敛 |
| **10** | 模型中心可用化 | 切换模型真影响转录/翻译；问答占位清晰 |
| **11** | 日历看板增强 | 热力/完成率/日详情可用 |
| **12** | 数据层与同步预备 | SyncEntity、导出导入 metadata |
| **13** | 旧能力入口收拢 + 回归 | 导入/下载/OCR/合成入口统一；播放无回归 |
| **R** | GitHub 同步 | `main` 含本阶段提交 |

每阶段循环：架构开工单 → 代码助手实现 → 调试助手验收 → 架构开下一阶段 → **推 GitHub**。

---

## Phase 6 — 学习单元做深（优先）

**问题**：现在能建单元、进详情、日历能见，但和「学完」绑定偏浅，推荐偏启发式占位。

**要做**：
1. 进度真相：媒体 `lastPositionMs`/`lastPlayedAt` 变化时，回写对应 `LearningUnit.progress`（按 mediaId 聚合 percent）
2. 完成规则（先简单可配）：默认「进度≥90% 或手动标记完成」算该媒体完成；全部叶子完成 → 单元 `completed`
3. 执行页：显示每项进度条/百分比；一键继续播未完成项（走现有 PlaybackNavigation）
4. 推荐升级：`LearningUnitRecommender` 输出带理由（临近 due / 昨日学过未完成 / 新导入可生成单元建议）
5. 首页：推荐卡展示理由一行；空状态引导「新建单元」

**不改**：播放器内部逻辑，只接线进度回调。

**验收**：播一段后单元进度变化；推荐卡有理由；analyze 无新 error。

---

## Phase 7 — 中心闭环

**要做**：
1. ProcessingCenter：真实队列列表 UI（状态：排队/进行/成功/失败）；`enqueueProcessingJob` 与 `transcription_manager`/batch 对齐
2. 播放页 AI 字幕：入队后处理中心立即可见同一 job（同一 id）
3. DownloadCenter：队列摘要（B站+yt-dlp 进行中数量）；设置入口不丢
4. 去掉 `video_action_buttons` 残留直达 B站页（统一进下载中心）
5. ModelCenter：播放/处理路径禁止硬编码 ASR；一律 resolve

**验收**：播放页点生成 → 处理中心有记录；下载只从中心进主路径。

---

## Phase 8 — 媒体库与选片打磨

**要做**：
1. Media Picker：库内搜索、类型过滤 UI 完善、大屏双栏（若现有布局允许）
2. 媒体库：属性页入口更明显；补齐属性展示（字幕概况、软件内路径面包屑）
3. 导入入口收拢到库 Tab（batch import 可达）
4. 双 Scaffold：库页多选底栏与 MainShell 底栏冲突收敛（至少一种模式不叠两层）

**验收**：选片可搜；属性好找；手机底栏不严重打架。

---

## Phase 9 — 反馈与视觉

**要做**：
1. 关键路径替换 `app_toast` 为页内/按钮态反馈（至少：入队成功、保存单元、下载开始）
2. 主题：默认圆角 8–12；统一动效时长短
3. 「我的」：设置入口整理（原 settings 能力逐步迁入，可先做导航壳）

**验收**：上述三处操作无新悬浮 Toast；主题常量有一处维护。

---

## Phase 10 — 模型中心可用化

**要做**：
1. 转录/翻译切换后，下一次任务用新模型（写集成测试或手动路径说明）
2. 问答：占位 +「未配置」明确态；`MediaPromptBuilder` 接到问答入口（可先只生成 prompt 文本预览）
3. 预留本地模型/API 配置字段（可存不实现）

**验收**：切换翻译/转录选项后行为有可见差异或日志/设置回读正确。

---

## Phase 11 — 日历增强

**要做**：
1. 月视图标记：有 due / 有学习活动 / 已完成
2. 日详情：当天单元列表 + 完成率
3. 与单元 schedule 编辑打通（改 due 日历马上变）

**验收**：改 due → 日历位置更新；点日期能进单元。

---

## Phase 12 — 数据与同步预备

**要做**：
1. 统一：`id` / `updatedAt` / `deletedAt?` / `revision?`（LearningUnit 已有则对齐 Media 扩展）
2. `SyncEntity` 接口 + metadata 导出/导入 JSON（不含大视频文件）
3. 「我的」里：导出/导入入口
4. 文档：同步策略备注（云端/端到端后续）→ 见 [SYNC_STRATEGY.md](./SYNC_STRATEGY.md)

**验收**：导出再导入学习单元不丢关键字段。

---

## Phase 13 — 收拢与回归

**要做**：
1. OCR / 视频合成入口挂到处理中心（可二级入口，不重写引擎）
2. 冒烟清单：播、选片、建单元、入队、下载入口、属性
3. 修 Phase 6–12 遗留小问题

**验收**：调试助手按冒烟清单过；推 GitHub。

---

## Phase R — 每阶段 Git 同步（贯穿）

每阶段验收通过后：
1. 在 `/workspace/fluent-learning/repo` commit（清晰 message：`Phase N: ...`）
2. push `origin main`（https://github.com/t66666t/Fluent-Learning）
3. 群里贴 commit SHA

架构专家负责提醒；代码助手执行 commit/push（Token 由环境/已有密钥提供时直接用，缺权限再找用户）。

---

## 给代码助手的总约束

1. 切口接线，不重写 `MediaPlaybackService` / 巨型 download service  
2. 不新建第二套选片 UI  
3. 新功能走 `lib/system/*`  
4. 保持 Provider；新状态细粒度 notifier  
5. 每阶段可编译、`flutter analyze` 无新 error  
6. 推 GitHub，不默认打 APK  

---

## 建议开工顺序

先发 **Phase 6**，通过后 7 → 8 → … → 13。  
若用户中途改优先级，以群里最新开工单为准。
