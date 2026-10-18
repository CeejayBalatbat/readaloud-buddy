import 'package:flutter/services.dart';

/// Asks Android for the microphone (so tests can fake it).
abstract class MicPermission {
  /// Shows Android's permission question if needed. True when the app may
  /// record audio.
  Future<bool> request();
}

/// The real question, through the small channel in MainActivity.kt.
class PlatformMicPermission implements MicPermission {
  const PlatformMicPermission();
  static const _channel = MethodChannel('readaloud/mic');

  @override
  Future<bool> request() async {
    try {
      return await _channel.invokeMethod<bool>('request') ?? false;
    } on PlatformException {
      return false;
    } on MissingPluginException {
      return false;
    }
  }
}
