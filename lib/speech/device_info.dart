import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

/// The phone's memory and this app's share of it, in MB.
class MemoryInfo {
  const MemoryInfo({required this.totalMb, required this.freeMb, required this.appMb});

  final int totalMb;

  /// What Android says is available to apps right now.
  final int freeMb;

  /// This app's memory use (PSS).
  final int appMb;

  @override
  String toString() => '$appMb MB used by the app, $freeMb of $totalMb MB free';
}

/// Memory and storage numbers from MainActivity.kt (so tests can fake them).
abstract class DeviceInfo {
  /// Null when the phone can't say.
  Future<MemoryInfo?> memory();

  /// Free space where the app keeps its files, or null when unknown.
  Future<int?> freeSpaceMb();
}

class PlatformDeviceInfo implements DeviceInfo {
  const PlatformDeviceInfo();
  static const _channel = MethodChannel('readaloud/device');

  @override
  Future<MemoryInfo?> memory() async {
    try {
      final m = await _channel.invokeMapMethod<String, Object?>('memory');
      if (m == null) return null;
      return MemoryInfo(
        totalMb: (m['totalMb'] as num).toInt(),
        freeMb: (m['availMb'] as num).toInt(),
        appMb: (m['appPssMb'] as num).toInt(),
      );
    } catch (_) {
      return null;
    }
  }

  @override
  Future<int?> freeSpaceMb() async {
    try {
      return (await _channel.invokeMethod<num>('freeSpaceMb'))?.toInt();
    } catch (_) {
      return null;
    }
  }
}

final deviceInfoProvider = Provider<DeviceInfo>((ref) => const PlatformDeviceInfo());
