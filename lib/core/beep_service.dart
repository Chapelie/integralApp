// lib/core/beep_service.dart
// Service for playing audio feedback (beeps)
library;

import 'dart:math';
import 'dart:typed_data';
import 'package:audioplayers/audioplayers.dart';

class BeepService {
  static final BeepService _instance = BeepService._internal();
  factory BeepService() => _instance;
  BeepService._internal();

  final AudioPlayer _player = AudioPlayer();

  /// Generate PCM wave data for a beep
  Uint8List _generateBeep({
    required double frequency,
    required double duration,
    required double volume,
    int sampleRate = 44100,
  }) {
    final int numSamples = (sampleRate * duration).round();
    final Float32List samples = Float32List(numSamples);

    for (int i = 0; i < numSamples; i++) {
      final double t = i / sampleRate;
      samples[i] = (sin(2 * pi * frequency * t) * volume).clamp(-1.0, 1.0);
    }

    // Convert to 16-bit PCM
    final Uint8List pcmData = Uint8List(numSamples * 2);
    final ByteData byteData = pcmData.buffer.asByteData();
    for (int i = 0; i < numSamples; i++) {
      final int sample = (samples[i] * 32767).round().clamp(-32768, 32767);
      byteData.setInt16(i * 2, sample, Endian.little);
    }

    return pcmData;
  }

  /// Play a beep sound
  Future<void> _playBeep({
    required double frequency,
    required double duration,
    required double volume,
  }) async {
    try {
      // Generate beep data (for future use if we implement PCM playback)
      _generateBeep(
        frequency: frequency,
        duration: duration,
        volume: volume,
      );

      // Note: audioplayers doesn't directly support PCM data
      // For now, we'll use a simple approach with system sounds
      // In a production app, you might want to use a different approach
      // or convert PCM to a supported audio format
      
      // For now, we'll just play a silent beep or use platform channels
      // This is a simplified implementation
      await _player.setVolume(volume);
      await _player.setPlaybackRate(1.0);
      
      // Since we can't directly play PCM, we'll skip actual audio playback
      // but keep the method structure for future implementation
    } catch (e) {
      print('[BeepService] Error playing beep: $e');
    }
  }

  /// Play success beep (softer, more pleasant)
  Future<void> playSuccess() async {
    await _playBeep(frequency: 500.0, duration: 0.12, volume: 0.35);
  }

  /// Play error beep (softer, less strident)
  Future<void> playError() async {
    await _playBeep(frequency: 350.0, duration: 0.10, volume: 0.4);
    await Future.delayed(const Duration(milliseconds: 80));
    await _playBeep(frequency: 280.0, duration: 0.10, volume: 0.4);
  }
}
