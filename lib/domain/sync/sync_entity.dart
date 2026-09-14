/// Common sync surface for entities that can be exported / merged across devices.
///
/// Phase 12 prep only — no cloud transport yet. Implementations must expose
/// stable [id], monotonic-ish [updatedAt], optional soft-delete [deletedAt],
/// and optional [revision] for conflict hints.
abstract class SyncEntity {
  String get id;
  DateTime get updatedAt;
  DateTime? get deletedAt;
  int? get revision;

  /// JSON suitable for metadata sync bundles (no binary / blob payloads).
  Map<String, dynamic> toSyncJson();
}
