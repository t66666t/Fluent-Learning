# Sync Strategy (Phase 12 prep)

## Scope

Phase 12 prepares **metadata-only** sync. It does **not** move video/audio blobs,
thumbnails as binaries, or download caches.

Included today:

- LearningUnit records (`id`, `updatedAt`, `deletedAt?`, `revision?`, schedule,
  progress, itemRefs, …)
- Optional lightweight media metadata rows (id/title/type/duration/path hint…)

Excluded:

- Media files, OCR models, yt-dlp binaries, danmaku/subtitle file bodies

## Entity contract

Every syncable row aligns to `SyncEntity`:

| Field | Role |
| --- | --- |
| `id` | Stable primary key |
| `updatedAt` | Last meaningful write time (LWW primary) |
| `deletedAt?` | Soft-delete / tombstone |
| `revision?` | Tie-break / future vector clock hint |
| `toSyncJson()` | Metadata JSON (no blobs) |

`LearningUnit` implements this directly. Media uses `MediaSyncMetadata` derived
from `VideoItem` (`syncRevision` / `syncDeletedAt` optional on the model).

## Merge rule (local import)

Last-write-wins:

1. Prefer higher `updatedAt`
2. If equal, prefer higher `revision` (missing treated as `0`)
3. Soft-deleted units are kept so tombstones can propagate

Media metadata rows in the bundle are recorded for future library merge; Phase 12
import applies LearningUnits only and does not rewrite `LibraryService` storage.

## Transport (future)

Suggested next steps (not implemented here):

1. Cloud object store for the JSON bundle + optional end-to-end encryption
2. Device pairing / account-bound sync channel
3. Optional media blob sync behind an explicit user opt-in (separate from metadata)

Export entry: **我的 → 导出学习元数据**  
Import entry: **我的 → 导入学习元数据**

Bundle format id: `fluent_learning_metadata_v1`
