/// Service pour gérer les bips sonores dans l'application
/// 
/// Génère des bips en PCM directement dans le code (sans fichier audio)
library;

import 'dart:typed_data';
import 'dart:math' as math;
import 'dart:io';
import 'package:audioplayers/audioplayers.dart';
import 'package:path_provider/path_provider.dart';
import 'package:path/path.dart' as path;

/// Types de bips disponibles
enum BeepType {
  /// Bip de succès (validation, confirmation)
  success,
  
  /// Bip d'erreur (saisie invalide, erreur)
  error,
  
  /// Bip d'information (notification, scan)
  info,
  
  /// Bip de warning (avertissement)
  warning,
}

/// Service centralisé pour gérer les bips sonores
class BeepService {
  static final BeepService _instance = BeepService._internal();
  factory BeepService() => _instance;
  BeepService._internal();

  final AudioPlayer _audioPlayer = AudioPlayer();
  
  /// Indique si les bips sont activés
  bool _enabled = true;

  /// Active ou désactive les bips
  void setEnabled(bool enabled) {
    _enabled = enabled;
  }

  /// Vérifie si les bips sont activés
  bool get isEnabled => _enabled;

  /// Génère un signal PCM (onde sinusoïdale) et le convertit en WAV
  Uint8List _generateBeepWave({
    required double frequency,
    required double duration,
    double volume = 0.5,
    int sampleRate = 44100,
  }) {
    final int numSamples = (sampleRate * duration).round();
    final int numChannels = 1; // Mono
    final int bitsPerSample = 16;
    final int byteRate = sampleRate * numChannels * bitsPerSample ~/ 8;
    final int blockAlign = numChannels * bitsPerSample ~/ 8;
    final int dataSize = numSamples * numChannels * bitsPerSample ~/ 8;
    final int fileSize = 36 + dataSize;

    // Générer les échantillons PCM
    final List<int> samples = [];
    for (int i = 0; i < numSamples; i++) {
      final double t = i / sampleRate;
      // Onde sinusoïdale avec enveloppe (fade in/out pour éviter les clics)
      double envelope = 1.0;
      if (i < numSamples * 0.1) {
        // Fade in
        envelope = i / (numSamples * 0.1);
      } else if (i > numSamples * 0.9) {
        // Fade out
        envelope = (numSamples - i) / (numSamples * 0.1);
      }
      
      // Augmenter l'amplitude pour un son plus fort (volume max = 1.0)
      final double amplitude = volume.clamp(0.0, 1.0);
      final double sample = math.sin(2 * math.pi * frequency * t) * envelope * amplitude;
      final int intSample = (sample * 32767).round().clamp(-32768, 32767);
      samples.add(intSample);
    }

    // Créer le header WAV
    final ByteData header = ByteData(44);
    int offset = 0;

    // RIFF header
    header.setUint8(offset++, 0x52); // 'R'
    header.setUint8(offset++, 0x49); // 'I'
    header.setUint8(offset++, 0x46); // 'F'
    header.setUint8(offset++, 0x46); // 'F'
    header.setUint32(offset, fileSize, Endian.little);
    offset += 4;

    // WAVE header
    header.setUint8(offset++, 0x57); // 'W'
    header.setUint8(offset++, 0x41); // 'A'
    header.setUint8(offset++, 0x56); // 'V'
    header.setUint8(offset++, 0x45); // 'E'

    // fmt chunk
    header.setUint8(offset++, 0x66); // 'f'
    header.setUint8(offset++, 0x6D); // 'm'
    header.setUint8(offset++, 0x74); // 't'
    header.setUint8(offset++, 0x20); // ' '
    header.setUint32(offset, 16, Endian.little); // fmt chunk size
    offset += 4;
    header.setUint16(offset, 1, Endian.little); // audio format (PCM)
    offset += 2;
    header.setUint16(offset, numChannels, Endian.little);
    offset += 2;
    header.setUint32(offset, sampleRate, Endian.little);
    offset += 4;
    header.setUint32(offset, byteRate, Endian.little);
    offset += 4;
    header.setUint16(offset, blockAlign, Endian.little);
    offset += 2;
    header.setUint16(offset, bitsPerSample, Endian.little);
    offset += 2;

    // data chunk
    header.setUint8(offset++, 0x64); // 'd'
    header.setUint8(offset++, 0x61); // 'a'
    header.setUint8(offset++, 0x74); // 't'
    header.setUint8(offset++, 0x61); // 'a'
    header.setUint32(offset, dataSize, Endian.little);

    // Convertir les échantillons en bytes (little-endian)
    final ByteData sampleData = ByteData(dataSize);
    for (int i = 0; i < samples.length; i++) {
      sampleData.setInt16(i * 2, samples[i], Endian.little);
    }

    // Combiner header + data
    final Uint8List waveFile = Uint8List(fileSize + 8);
    waveFile.setRange(0, 44, header.buffer.asUint8List());
    waveFile.setRange(44, 44 + dataSize, sampleData.buffer.asUint8List());

    return waveFile;
  }

  /// Joue un bip généré en PCM
  Future<void> _playBeep({
    required double frequency,
    required double duration,
    double volume = 0.5,
  }) async {
    if (!_enabled) return;
    
    File? tempFile;
    try {
      final Uint8List waveData = _generateBeepWave(
        frequency: frequency,
        duration: duration,
        volume: volume,
      );
      
      // Créer un fichier temporaire pour jouer le WAV
      final Directory tempDir = await getTemporaryDirectory();
      final String tempPath = path.join(
        tempDir.path,
        'beep_${DateTime.now().millisecondsSinceEpoch}.wav',
      );
      
      tempFile = File(tempPath);
      await tempFile.writeAsBytes(waveData);
      
      // Configurer le volume de l'AudioPlayer (0.0 à 1.0)
      await _audioPlayer.setVolume(1.0); // Volume maximum
      
      // Arrêter toute lecture en cours pour éviter les conflits
      await _audioPlayer.stop();
      
      // Jouer le fichier temporaire
      await _audioPlayer.play(DeviceFileSource(tempPath));
      
      // Attendre la fin de la lecture avant de supprimer
      final durationMs = (duration * 1000).round();
      await Future.delayed(Duration(milliseconds: durationMs + 200));
    } catch (e) {
      print('[BeepService] Erreur lors de la lecture du bip: $e');
    } finally {
      // Supprimer le fichier temporaire
      try {
        if (tempFile != null && await tempFile.exists()) {
          await tempFile.delete();
        }
      } catch (e) {
        print('[BeepService] Erreur lors de la suppression du fichier temporaire: $e');
      }
    }
  }

  /// Joue un bip de succès (validation, confirmation)
  /// 
  /// Utilisé pour :
  /// - Validation de formulaire réussie
  /// - Confirmation de paiement
  /// - Ajout réussi d'un élément
  Future<void> playSuccess() async {
    await _playBeep(frequency: 800.0, duration: 0.2, volume: 0.8);
  }

  /// Joue un bip d'erreur (saisie invalide, erreur)
  /// 
  /// Utilisé pour :
  /// - Erreur de validation de formulaire
  /// - Erreur de saisie
  /// - Échec d'une opération
  Future<void> playError() async {
    // Double bip pour les erreurs (fréquence plus basse)
    await _playBeep(frequency: 400.0, duration: 0.2, volume: 0.9);
    await Future.delayed(const Duration(milliseconds: 100));
    await _playBeep(frequency: 300.0, duration: 0.2, volume: 0.9);
  }

  /// Joue un bip d'information (notification, scan)
  /// 
  /// Utilisé pour :
  /// - Scan de code-barres réussi
  /// - Notification d'information
  /// - Confirmation d'action
  Future<void> playInfo() async {
    await _playBeep(frequency: 600.0, duration: 0.15, volume: 0.7);
  }

  /// Joue un bip d'avertissement
  /// 
  /// Utilisé pour :
  /// - Avertissement avant une action
  /// - Stock faible
  /// - Attention requise
  Future<void> playWarning() async {
    // Bip d'avertissement (fréquence moyenne)
    await _playBeep(frequency: 500.0, duration: 0.25, volume: 0.8);
  }

  /// Joue un bip personnalisé selon le type
  Future<void> play(BeepType type) async {
    switch (type) {
      case BeepType.success:
        await playSuccess();
        break;
      case BeepType.error:
        await playError();
        break;
      case BeepType.info:
        await playInfo();
        break;
      case BeepType.warning:
        await playWarning();
        break;
    }
  }

  /// Joue un bip simple (alias pour playInfo)
  Future<void> beep() async {
    await playInfo();
  }

  /// Libère les ressources
  void dispose() {
    _audioPlayer.dispose();
  }
}
