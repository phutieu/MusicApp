import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:just_audio/just_audio.dart';
import 'package:t4/models/song.dart';

class LyricsScreen extends StatefulWidget {
  final Song song;
  final Duration position;
  final Duration duration;
  final AudioPlayer audioPlayer;

  const LyricsScreen({
    Key? key,
    required this.song,
    required this.position,
    required this.duration,
    required this.audioPlayer,
  }) : super(key: key);

  @override
  State<LyricsScreen> createState() => _LyricsScreenState();
}

class _LyricsScreenState extends State<LyricsScreen> {
  List<LyricLine> _lyrics = [];
  int _currentLineIndex = 0;
  final ScrollController _scrollController = ScrollController();

  @override
  void initState() {
    super.initState();
    _loadLyrics();
    _setupPositionListener();
  }

  Future<void> _loadLyrics() async {
    try {
      // Tách tên file từ đường dẫn file âm thanh
      final filename = widget.song.assetPath.split('/').last.split('.').first;
      final lyricsPath = 'assets/lyrics/$filename.lrc';

      try {
        final lyricsText = await rootBundle.loadString(lyricsPath);
        setState(() {
          _lyrics = parseLyrics(lyricsText);
        });
      } catch (e) {
        // Nếu không tìm thấy file LRC, sử dụng lyrics từ model Song và chia theo dòng
        setState(() {
          final lines = widget.song.lyrics.split('\n');
          final duration = widget.duration.inMilliseconds;
          final timePerLine = duration ~/ (lines.length > 0 ? lines.length : 1);

          _lyrics = List.generate(
            lines.length,
            (index) => LyricLine(
              time: Duration(milliseconds: index * timePerLine),
              text: lines[index],
            ),
          );
        });
      }
    } catch (e) {
      print('Lỗi khi tải lời bài hát: $e');
    }
  }

  void _setupPositionListener() {
    widget.audioPlayer.positionStream.listen((position) {
      if (_lyrics.isEmpty) return;

      int newLineIndex = 0;
      for (int i = 0; i < _lyrics.length; i++) {
        if (position >= _lyrics[i].time) {
          newLineIndex = i;
        } else {
          break;
        }
      }

      if (newLineIndex != _currentLineIndex) {
        setState(() {
          _currentLineIndex = newLineIndex;
        });

        _scrollToCurrentLine();
      }
    });
  }

  void _scrollToCurrentLine() {
    if (_scrollController.hasClients && _lyrics.isNotEmpty) {
      final itemHeight = 50.0; // Chiều cao ước tính của mỗi dòng lời
      final offset = (_currentLineIndex * itemHeight) -
          150; // 150 là để dòng hiện tại ở giữa màn hình

      final maxScroll = _scrollController.position.maxScrollExtent;
      final clampedOffset =
          offset < 0 ? 0.0 : (offset > maxScroll ? maxScroll : offset);

      _scrollController.animateTo(
        clampedOffset,
        duration: const Duration(milliseconds: 300),
        curve: Curves.easeInOut,
      );
    }
  }

  List<LyricLine> parseLyrics(String lyricsText) {
    final lines = lyricsText.split('\n');
    final regex = RegExp(r'\[(\d+):(\d+)\.(\d+)\](.*)');
    final lyrics = <LyricLine>[];

    for (var line in lines) {
      final match = regex.firstMatch(line);
      if (match != null) {
        final minutes = int.parse(match.group(1)!);
        final seconds = int.parse(match.group(2)!);
        final milliseconds =
            int.parse(match.group(3)!) * 10; // Thường là centiseconds
        final text = match.group(4)!.trim();

        final time = Duration(
          minutes: minutes,
          seconds: seconds,
          milliseconds: milliseconds,
        );

        lyrics.add(LyricLine(time: time, text: text));
      }
    }

    lyrics.sort((a, b) => a.time.compareTo(b.time));
    return lyrics;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF1A1A1A),
      appBar: AppBar(
        title: Text(widget.song.title),
        backgroundColor: Colors.transparent,
        foregroundColor: Colors.white,
        centerTitle: true,
      ),
      body: _lyrics.isEmpty
          ? const Center(child: CircularProgressIndicator())
          : ListView.builder(
              controller: _scrollController,
              padding:
                  const EdgeInsets.symmetric(vertical: 100, horizontal: 24),
              itemCount: _lyrics.length,
              itemBuilder: (context, index) {
                if (index >= _lyrics.length) {
                  return const SizedBox.shrink();
                }

                final isCurrentLine = index == _currentLineIndex;

                return AnimatedContainer(
                  duration: const Duration(milliseconds: 300),
                  padding: const EdgeInsets.symmetric(vertical: 10),
                  transform: isCurrentLine
                      ? (Matrix4.identity()..scale(1.05))
                      : Matrix4.identity(),
                  child: Text(
                    _lyrics[index].text,
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      color: isCurrentLine
                          ? const Color(0xFF31C934)
                          : Colors.white70,
                      fontSize: isCurrentLine ? 20 : 16,
                      fontWeight:
                          isCurrentLine ? FontWeight.bold : FontWeight.normal,
                    ),
                  ),
                );
              },
            ),
    );
  }
}

class LyricLine {
  final Duration time;
  final String text;

  LyricLine({required this.time, required this.text});
}
