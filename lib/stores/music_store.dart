import 'package:flutter/material.dart';
import 'package:just_audio/just_audio.dart';

class Song {
  final String id;
  final String title;
  final String artist;
  final String coverUrl;
  final String audioUrl;

  Song({
    required this.id,
    required this.title,
    required this.artist,
    required this.coverUrl,
    required this.audioUrl,
  });
}

class MusicStore extends ChangeNotifier {
  final AudioPlayer audioPlayer = AudioPlayer();
  
  Song? _currentSong;
  List<Song> _playlist = [];
  int _currentIndex = 0;
  bool _isPlaying = false;

  Song? get currentSong => _currentSong;
  List<Song> get playlist => _playlist;
  int get currentIndex => _currentIndex;
  bool get isPlaying => _isPlaying;

  MusicStore() {
    audioPlayer.playerStateStream.listen((state) {
      _isPlaying = state.playing;
      notifyListeners();
    });

    audioPlayer.processingStateStream.listen((state) {
      if (state == ProcessingState.completed) {
        playNext();
      }
    });
  }

  void setCurrentSong(Song song, {List<Song>? playlist}) {
    _currentSong = song;
    
    if (playlist != null) {
      _playlist = playlist;
      _currentIndex = playlist.indexWhere((s) => s.id == song.id);
    }
    
    audioPlayer.setUrl(song.audioUrl);
    audioPlayer.play();
    notifyListeners();
  }

  void play() {
    audioPlayer.play();
    notifyListeners();
  }

  void pause() {
    audioPlayer.pause();
    notifyListeners();
  }

  void playNext() {
    if (_playlist.isNotEmpty && _currentIndex < _playlist.length - 1) {
      _currentIndex++;
      _currentSong = _playlist[_currentIndex];
      audioPlayer.setUrl(_currentSong!.audioUrl);
      audioPlayer.play();
      notifyListeners();
    }
  }

  void playPrev() {
    if (_playlist.isNotEmpty && _currentIndex > 0) {
      _currentIndex--;
      _currentSong = _playlist[_currentIndex];
      audioPlayer.setUrl(_currentSong!.audioUrl);
      audioPlayer.play();
      notifyListeners();
    }
  }

  @override
  void dispose() {
    audioPlayer.dispose();
    super.dispose();
  }
}
