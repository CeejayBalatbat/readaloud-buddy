import '../db/app_database.dart';

/// Well-known keys for the `settings` table.
abstract final class SettingKeys {
  static const parentPin = 'parent_pin';
  static const consentDate = 'consent_date';
  static const activeLearnerId = 'active_learner_id';
  static const speechMode = 'speech_mode'; // "voice" or "tap"
  static const hintMode = 'hint_mode'; // "automatic" or "helpOnly"
  static const feedbackMode = 'feedback_mode'; // "review" or "live"
}

/// App-wide key/value settings (parent PIN, consent date, ...).
class SettingsRepository {
  SettingsRepository(this._db);

  final AppDatabase _db;

  Future<String?> get(String key) async => (await (_db.select(_db.settings)
            ..where((s) => s.key.equals(key)))
          .getSingleOrNull())
      ?.value;

  Future<void> set(String key, String value) => _db
      .into(_db.settings)
      .insertOnConflictUpdate(Setting(key: key, value: value));

  Future<void> remove(String key) =>
      (_db.delete(_db.settings)..where((s) => s.key.equals(key))).go();
}
