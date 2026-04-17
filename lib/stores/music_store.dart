import 'package:flutter/material.dart';
import 'package:just_audio/just_audio.dart';

class MusicStore extends ChangeNotifier {
  final AudioPlayer audioPlayer = AudioPlayer();
  
  Map<String, dynamic>? currentSong;
  List<dynamic> currentPlaylist = [];
  int currentIndex = -1;

  MusicStore() {
    audioPlayer.playerStateStream.listen((state) {
      if (state.processingState == ProcessingState.completed) {
        playNext();
      }
    });
  }
  
  Future<void> playPlaylist(List<dynamic> playlist, int index) async {
    currentPlaylist = playlist;
    currentIndex = index;
    await _playCurrentIndex();
  }

  Future<void> _playCurrentIndex() async {
    if (currentIndex < 0 || currentIndex >= currentPlaylist.length) return;
    
    currentSong = currentPlaylist[currentIndex];
    notifyListeners();

    try {
      final audioUrl = currentSong!['audioUrl'];
      if (audioUrl != null && audioUrl.isNotEmpty) {
        await audioPlayer.setUrl(audioUrl);
        audioPlayer.play();
      }
    } catch (e) {
      debugPrint("音频加载失败: $e");
    }
  }

  void playNext() {
    if (currentPlaylist.isEmpty) return;
    currentIndex = (currentIndex + 1) % currentPlaylist.length;
    _playCurrentIndex();
  }

  void playPrevious() {
    if (currentPlaylist.isEmpty) return;
    currentIndex = (currentIndex - 1 + currentPlaylist.length) % currentPlaylist.length;
    _playCurrentIndex();
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
