# Fluent Learning 改造实施 Plan（给代码 AI 直接执行）

> **产品名**：Fluent Learning（用户文案偶发拼写 Fluent Learing；代码/显示名统一用 **Fluent Learning**）  
> **基线仓库**：`https://github.com/t66666t/Video-master`（本地已复制并改名/封面）  
> **旧包名**：`video_player_app`（`pubspec.yaml`）  
> **状态管理现状**：`provider`  
> **播放核心**：`media_kit` + `MediaPlaybackService`（**非必要不改**）  
> **本 Plan 读者**：Flutter 代码改写助手。按阶段落地；每阶段可独立验收。不要整仓重写。

---

## 0. 最高设计规则（所有实现必须遵守）

1. **系统级可复用能力优先于页面私有实现**（Apple Music 式：资料库能力可在任意场景调用）  
   - 媒体选择、模型解析、下载入队、处理入队、反馈提示，一律做成 **系统服务 + 统一 UI 入口**。  
   - 禁止在首页/处理中心/任务创建页各写一套选文件逻辑。
2. **播放页是能力入口，不是能力实现处**  
   - 播放页点「AI 字幕」→ 调用处理中心队列 API → 处理中心可见同一任务。  
   - 播放页点「下载相关」→ 下载中心队列。  
   - 播放页用的模型 → 只读模型中心当前配置。
3. **播放链路非必要不改**  
   - 保护：`MediaPlaybackService`、`video_player_screen.dart` / `portrait_video_screen.dart` / `music_player_screen.dart`、字幕叠加与弹幕核心路径。  
   - 允许改动的边界：入口接线、导航壳、入队 API、媒体元数据扩展、数据库 schema 迁移时的读写适配。
4. **反馈不用悬浮 Toast/SnackBar 轰炸**  
   - 旧 `app_toast.dart` 逐步收敛为：页面内联状态、中心队列状态、轻量顶部/工具栏内联提示。默认禁止随机悬浮通知。
5. **为同步预留**  
   - 实体一律：稳定 `id`（UUID）、`updatedAt`、`deletedAt?`（软删）、可选 `deviceId`/`revision`。  
   - 本地路径与可同步元数据分离；blob（视频文件）与 metadata 分层。

---

## 1. 产品信息架构（IA）

底部/主导航 **5 Tab**（名称可本地化，路由 id 固定）：

| Tab | Route id | 职责 |
|-----|----------|------|
| 首页 | `home` | 继续学、推荐学习单元、快捷入口 |
| 媒体库 | `library` | 媒体树/列表、导入、属性、回收站入口 |
| 日历 | `calendar` | 学习看板：单元日程、完成度、热力/时间线 |
| 中心 | `centers` | 中心大厅：模型 / 下载 / 处理（可扩展） |
| 我的 | `mine` | 设置、外观、存储、关于、同步占位 |

**叠层路由（非 Tab）**：播放器、学习单元详情/执行页、系统媒体选择器（modal）、媒体属性页、各中心子页。

推荐路由方案：在现有 `Navigator` 上逐步引入 **GoRouter**（或等价），但 **P0 可用 `IndexedStack` + 命名路由** 先落地壳，避免一次改爆。

---

## 2. 目标架构（分层）

在现有 `lib/` 上 **渐进迁移**，目标目录（新建优先，旧文件搬家而非复制两套）：

```
lib/
  app/                 # MaterialApp、主题、根导航壳
  core/                # 主题、响应式、结果反馈、常量、错误类型
  domain/              # 纯模型与用例接口（Media、LearningUnit、Job…）
  data/                # Repository、本地 DB、DTO、迁移
  system/              # ★ 系统级服务（最高优先级）
    media_picker/      # 统一媒体选择
    model_center/      # 模型注册与解析
    download_center/   # 下载队列门面
    processing_center/ # 处理队列门面
    feedback/          # 非悬浮反馈
  features/
    home/
    library/
    calendar/
    centers/
    learning_unit/     # 「任务」学习单元
    player/            # 仅壳与接线；核心仍用现有 playback
    mine/
  legacy/ 或保持现路径直至迁完  # screens/services 逐步收缩
```

**依赖方向**：`features → system/domain → data`；`player` 可依赖 `system`，`system` **不得**依赖具体 feature UI。

状态管理：P0 **继续 Provider**，新模块用细粒度 `ChangeNotifier`/`Listenable`；若某模块状态爆炸再局部引入 Riverpod（不强制全仓切换）。

---

## 3. 系统级能力规格（必须先做）

### 3.1 Media Picker（P0，最高优先级 UI）

**目标**：全 App 唯一的「从软件媒体库选媒体/文件夹」体验。

**已有可复用资产**：
- `lib/models/video_picker_tree_node.dart`（树选择、半选、已入队标记）
- `lib/widgets/internal_video_picker_dialog.dart`
- `LibraryService` 媒体树 / `parentId` 文件夹模型
- `collection_screen.dart` / 媒体库 list tile 交互

**目标 API（示例，实现时可微调命名）**：

```dart
class MediaPickerRequest {
  final bool multiSelect;
  final bool allowFolders;          // 选文件夹=选其下全部叶子（可嵌套）
  final Set<MediaType>? typeFilter; // video/audio
  final Set<String> excludeIds;     // 已在队列等
  final String? title;
  final String? confirmLabel;
}

class MediaPickerResult {
  final List<String> mediaIds;      // 展开后的叶子
  final List<String> folderIds;     // 用户显式选中的文件夹（可选保留）
}

Future<MediaPickerResult?> showAppMediaPicker(
  BuildContext context,
  MediaPickerRequest request,
);
```

**必须接入的调用点**：
1. 创建学习单元  
2. 处理中心批量加入  
3. 播放页「添加到…」类动作（若有）  
4. 任何旧 `internal_video_picker_dialog` 调用点 → 全部改为新 API  

**体验要求**：搜索、面包屑/层级、多选、文件夹半选、已选计数、大屏双栏可选、小圆角、无悬浮 Toast。

### 3.2 Model Center（P0 骨架，能力可瘦）

**职责**：统一注册「转录 / 翻译 / 问答 /（预留 OCR）」模型；提供当前选用与解析。

**MVP 内置**：
- 转录：现有在线接口（`bcut_asr_service` / `transcription_manager` 所用）打成 `TranscriptionModelProvider`
- 翻译：谷歌翻译（`subtitle_translation_service`）打成 `TranslationModelProvider`
- 问答：空列表 +「即将支持」占位（UI 有，运行时清晰失败）

**API 概念**：
- `ModelCatalog.list(ModelKind kind)`
- `ModelSettings.getActive(kind)` / `setActive(kind, modelId)`
- `ModelRouter.resolve(kind)` → 可执行 runner

播放页/处理中心 **禁止硬编码** 具体 ASR/翻译实现，只问 Model Center。

### 3.3 Download Center（P0 入口重挂）

**迁入**：
- `bilibili_download_screen.dart` + `services/bilibili/*`
- `features/youtube_download/**`（yt-dlp）

**中心页**：队列总览、设置（保存路径、并发、二进制管理入口）、入口卡片（B 站 / yt-dlp）。  
旧首页/设置里的下载入口改为 `context.push` 到 Download Center 子路由。

### 3.4 Processing Center（P0，UI 可先包旧屏）

**MVP**：外壳 + 直接嵌入/导航到现有 `batch_subtitle_screen.dart`。  
同时抽象队列门面：

```dart
enum ProcessingJobType { transcription, translation, ocr, compose, custom }

Future<String> enqueueProcessingJob({
  required ProcessingJobType type,
  required List<String> mediaIds,
  Map<String, dynamic>? params,
});
```

播放页「生成 AI 字幕」→ `enqueueProcessingJob(transcription, …)`，处理中心列表同步出现（可先映射到现有 `transcription_manager` / batch 队列）。

### 3.5 Feedback（P1 可并行，但新 UI 禁止新 Toast）

用 `AppFeedback.showInline` / 中心角标 / 按钮 loading；逐步替换关键路径的 `app_toast`。

---

## 4. 领域模型

### 4.1 Media（扩展现有 `VideoItem`）

保留现有字段与 JSON 兼容；**增量**（可空，迁移填充）：

| 字段 | 说明 |
|------|------|
| `displayName` | 软件内名称（默认同 title） |
| `libraryPath` | 软件内逻辑路径（由 parent 链推导亦可） |
| `fileName` / `filePath` | 文件系统名与路径（path 已有） |
| `importedAt` | 导入时间 |
| `publishedAt` | 发布日期（B 站等来源） |
| `lastPlayedAt` | 上次播放时刻 |
| `width`/`height`/`frameRate`/`bitRate` | 媒体技术属性（probe 填充） |
| `tags` / `notes` | 预留 |
| `syncRevision` | 同步用 |

提供 `MediaPromptBuilder.from(VideoItem)`：把标题、时长、章节、字幕摘要等拼成问答/分类用的 prompt 片段（P2 可用）。

**文件夹**：继续用 `parentId` 树；回收站逻辑保留。

### 4.2 Learning Unit（原「任务」，产品暂名；代码建议 `LearningUnit`）

用户确认语义：**学习单元 = 选定媒体/文件夹，有计划地看完学完，与日历深度绑定**。

```text
LearningUnit
  id, title, notes?
  status: planned | active | paused | completed | archived
  itemRefs: [ { mediaId } | { folderId, includeNested: true } ]
  schedule: { startDate?, dueDate?, targetMinutesPerDay?, weekdayMask? }
  progress: { completedMediaIds[], watchedMsByMedia{}, percent }
  createdAt, updatedAt, completedAt?
```

**页面**：
- 创建流：标题 → Media Picker → 计划（日期/目标）→ 确认  
- 详情/执行页：列表进度、点进播放（走现有播放）、标记完成、设置  
- 首页：推荐卡片一点进入执行页  

**推荐（P1 规则引擎，P2+ 可增强）**：启发式即可，接口化 `LearningUnitRecommender`：
- 未完成且接近 due  
- 最近播放但未完成的单元  
- 新导入媒体可一键「生成单元」  
禁止在 P0 做重 ML；预留接口。

### 4.3 Calendar（学习看板）

- 月/周视图：单元 due、打卡式完成点  
- 日详情：当天相关单元与完成率  
- 数据来源：仅 `LearningUnit` + 播放进度事件（`lastPlayedAt` / progress）

---

## 5. 数据持久化与同步预备

**现状**：大量 JSON + `shared_preferences` / 文件（`LibraryService` 巨型）。  

**改造原则**：
1. P0：LearningUnit / ModelSettings / Job 队列元数据用 **独立 store**（JSON 文件或 `sqlite`/`drift` 其一；推荐 **drift/sqlite** 若引入成本可接受，否则先 `path_provider` JSON + 清晰 Repository）。  
2. Media 库：**优先扩展现有 LibraryService 序列化**，做版本号 `librarySchemaVersion` 与迁移函数；不要一上来重写 20 万行。  
3. 所有新实体带 `updatedAt`；删除用软删。  
4. 定义 `SyncEntity` 接口（id/updatedAt/deletedAt/toSyncJson），即使 P0 不同步。

---

## 6. 旧能力迁移映射

| 旧能力 | 旧位置（参考） | 新归属 |
|--------|----------------|--------|
| 媒体播放 | `MediaPlaybackService`, `video_player_screen`, `portrait_*`, `music_*` | **保留核心**；导航壳接入 |
| 媒体库/收藏夹 | `collection_screen`, `LibraryService` | Tab「媒体库」重构 UI，服务复用 |
| 内部选片 | `internal_video_picker_dialog`, `video_picker_tree_node` | **升级为系统 Media Picker** |
| 批量导入 | `batch_import_screen`, `batch_import_service` | 媒体库「导入」 |
| B 站下载/在线 | `bilibili_download_screen`, `services/bilibili/*` | Download Center |
| yt-dlp | `features/youtube_download/**` | Download Center |
| 批量字幕/转录 | `batch_subtitle_screen`, `transcription_manager`, `bcut_asr_service` | Processing Center + Model Center |
| 翻译 | `subtitle_translation_service` | Model Center（翻译）+ 处理任务 |
| OCR | `ocr_*`, widgets `ocr_*` | Processing Center（后续）；模型进 Model Center |
| 视频合成 | `video_compose_*` | Processing Center 子能力 |
| 设置 | `settings_panel`, `settings_service` | 「我的」+ 各中心设置分区 |
| 回收站 | `recycle_bin_screen` | 媒体库子页 |
| Toast | `app_toast.dart` | 收敛，禁止新悬浮滥用 |

---

## 7. UI / 设计约束

- 圆角：**偏小**（建议组件默认 8–12，避免超大胶囊堆砌）  
- 适配：沿用/加强 `device_form_factor.dart`；手机/平板/桌面断点布局  
- 动效：短、明确（200–280ms），共享元素谨慎  
- **禁止**：随意悬浮通知；阻塞式弹窗仅用于破坏性确认  
- 字体：可继续 Inter / 现有中文字体；风格干净偏 Apple  

主题落在 `lib/app/theme.dart`，Tab 壳统一。

---

## 8. 分阶段实施（严格按序）

### Phase 0 — 工程基线（0.5–1 天）
- [ ] 确认本地工程可 `flutter pub get` / 跑起来  
- [ ] `pubspec` name/显示名与 Fluent Learning 一致（若未改完）  
- [ ] 新增目录骨架 `app/ core/ system/ features/`（可先空）  
- [ ] 文档：本 Plan 放入仓库 `docs/FLUENT_LEARNING_REFACTOR_PLAN.md`

### Phase 1 — 导航壳 + 5 Tab（P0）
- [ ] 根壳：`Home / Library / Calendar / Centers / Mine`  
- [ ] 旧 `home_screen` 媒体库能力迁到 Library Tab（可先整页挪嵌）  
- [ ] 播放入口仍可用  
- [ ] 验收：五 Tab 可切换；旧播放与库不回归

### Phase 2 — 系统 Media Picker（P0，最高优先级功能）
- [ ] 抽取 `showAppMediaPicker`  
- [ ] 替换所有内部选片调用  
- [ ] 验收：处理中心与「创建学习单元」共用同一选择器

### Phase 3 — Centers 大厅 + 三中心挂载（P0）
- [ ] Centers 首页卡片  
- [ ] Download Center：挂 B 站 + yt-dlp  
- [ ] Processing Center：挂 batch subtitle；播放页 AI 字幕改入队  
- [ ] Model Center：列表+当前选择；接通转录/翻译解析  
- [ ] 验收：播放页生成字幕后处理中心可见；下载只从中心进

### Phase 4 — LearningUnit + 首页推荐 + 日历（P0–P1）
- [ ] 模型与持久化  
- [ ] 创建/详情/执行页  
- [ ] 首页推荐（规则引擎）  
- [ ] 日历看板  
- [ ] 验收：选文件夹建单元 → 播放推进进度 → 日历可见

### Phase 5 — 媒体属性增强（P1）
- [ ] schema 迁移字段  
- [ ] 属性页 UI  
- [ ] probe 补全分辨率等  
- [ ] `MediaPromptBuilder` 初版

### Phase 6 — 体验打磨与反馈治理（P1）
- [ ] 去悬浮通知关键路径  
- [ ] 响应式与动效统一  
- [ ] 设置信息架构整理到「我的」

### Phase 7 — 同步预备（P2，只打基础）
- [ ] SyncEntity / revision  
- [ ] 导出/导入 metadata JSON（可选）  
- [ ] 云同步 UI 占位

---

## 9. 给代码 AI 的硬约束

1. **不要**重写 `MediaPlaybackService` 与播放器大文件，除非编译/接线必须的最小改动。  
2. **不要**新建第二套选文件 UI。  
3. **不要**在 feature 里直接 `new BcutAsr…` / 硬编码谷歌翻译；走 Model Center。  
4. **不要**引入与现有 Provider 并行的全局双状态源导致库数据两份。  
5. 每完成一个 Phase：保证项目可分析通过；提交信息按 Phase 命名。  
6. 大文件（`library_service.dart`、`video_controls_overlay.dart` 等）只做 **切口接线**，不顺手大重构。  
7. 用户本地路径以用户工程为准；远程参考 `t66666t/Video-master@main`。

---

## 10. 验收清单（整体 Done）

- [ ] 5 Tab 信息架构可用  
- [ ] 系统 Media Picker 至少 2 处以上调用且体验一致  
- [ ] 三中心可进入；下载与处理旧功能可达  
- [ ] 播放页 AI 字幕与处理中心队列同步  
- [ ] 可创建学习单元（含文件夹），进度与日历联动  
- [ ] 播放主路径无回归  
- [ ] 无明显悬浮 Toast 滥用  
- [ ] 新数据带 id/updatedAt，具备同步扩展点  

---

## 11. 开放点（已拍板 / 暂定）

| 项 | 决定 |
|----|------|
| 「任务」语义 | 学习单元 `LearningUnit`（UI 文案可先显示「学习」/「单元」，待用户最终命名） |
| 推荐算法 | P0/P1 启发式；接口可替换 |
| 状态管理 | 保持 Provider，局部可演进 |
| Model Center 问答 | 占位 |
| 处理中心 MVP | 包 `batch_subtitle_screen` |
| 包名 | 可保持 `video_player_app` 或后续改 `fluent_learning`（改名单独 PR，避免与功能耦合） |

---

## 12. 建议首周执行顺序（代码 bot 立刻开干）

1. Phase 0 骨架 + 把本文件写入 `docs/`  
2. Phase 1 五 Tab 壳  
3. Phase 2 Media Picker  
4. Phase 3 Centers 挂载  
5. Phase 4 LearningUnit 最小闭环  

遇到旧代码冲突时：**保播放、保库数据、切口接线**，把大重构留到后续 Phase。

---

## 13. 架构体检补充约束（执行必遵）

1. 仓内约 118 个 test，改造时**先保测试再拆文件**。
2. **冻结再增大**：`video_player_screen` / `portrait_video_screen` / `library_service` / `media_playback_service` — 只允许拆出，禁止继续堆逻辑。
3. 切断 `PlaybackNavigationService` → Screen 的 UI 依赖，改由**路由层建页**。
4. **统一实例来源**：去掉 `Provider.value` + 全局 factory 单例双入口。
5. `LibraryService` 里对 `127.0.0.1:7777` 的调试上报删掉或限 `kDebugMode`。
6. 状态层继续 Provider，暂缓全量换 Bloc；YouTube feature 目录作搬迁模板。
