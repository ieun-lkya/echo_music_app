import 'package:flutter/material.dart';
import 'package:just_audio/just_audio.dart';

class MusicStore extends ChangeNotifier {
  final AudioPlayer audioPlayer = AudioPlayer();
  
  Map<String, dynamic>? currentSong;
  
  Future<void> playSong(Map<String, dynamic> song) async {
    currentSong = song;
    notifyListeners();

    try {
      final audioUrl = song['audioUrl'];
      if (audioUrl != null && audioUrl.isNotEmpty) {
        await audioPlayer.setUrl(audioUrl);
        audioPlayer.play();
      }
    } catch (e) {
      debugPrint("音频加载失败: $e");
    }
  }

  void togglePlay() {
    if (audioPlayer.playing) {
      audioPlayer.pause();
    } else {
      audioPlayer.play();
    }
  }

  @override
  void dispose() {
    audioPlayer.dispose();
    super.dispose();
  }
}
