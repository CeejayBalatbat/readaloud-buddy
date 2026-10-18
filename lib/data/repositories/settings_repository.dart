import '../db/app_database.dart';

/// Well-known keys for the `settings` table.
abstract final class SettingKeys {
  static const parentPin = 'parent_pin';
  static const consentDate = 'consent_date';
  static const activeLearnerId = 'active_learner_id';
  static const speechMode = 'speech_mode'; // "vosk" or "tap" (developer)
  static const hintMode = 'hint_mode'; // "automatic" or "helpOnly"
  static const feedbackMode = 'feedback_mode'; // "review" or "live"
  static const voskActive = 'vosk_active'; // ms since epoch while English Vosk runs
  static const voskFailed = 'vosk_failed'; // why English Vosk was turned off
  static const voskFilActive = 'vosk_fil_active'; // the same for Filipino
  static const voskFilFailed = 'vosk_fil_failed';
  static const filipinoModelDeclined = 'fil_model_declined'; // "Not now" on the setup screen

  /// The keys of Vosk's crash protection for [language] ("EN" or "FIL").
  static (String active, String failed) vosk(String language) =>
      language == 'FIL' ? (voskFilActive, voskFilFailed) : (voskActive, voskFailed);
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
