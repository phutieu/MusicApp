import 'package:flutter/material.dart';
import 'package:just_audio/just_audio.dart';
import 'package:audio_service/audio_service.dart';
import 'package:audio_session/audio_session.dart';
import 'package:rxdart/rxdart.dart';
import 'package:t4/models/song.dart';
import 'package:t4/presentation/screen/lyric_screen.dart';

class NowPlayingScreen extends StatefulWidget {
  final Song song;
  final List<Song> songList;
  final int initialIndex;

  const NowPlayingScreen({
    Key? key,
    required this.song,
    required this.songList,
    required this.initialIndex,
  }) : super(key: key);

  @override
  State<NowPlayingScreen> createState() => _NowPlayingScreenState();
}

class _NowPlayingScreenState extends State<NowPlayingScreen>
    with WidgetsBindingObserver {
  late AudioPlayer _audioPlayer;
  late Song _currentSong;
  late int _currentIndex;

  Duration _currentPosition = Duration.zero;
  Duration _totalDuration = const Duration(seconds: 100); // default ban đầu
  bool _isPlaying = false;
  LoopMode _loopMode = LoopMode.off;
  bool _shuffleEnabled = false;
  bool _isAudioServiceInitialized = false;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    _audioPlayer = AudioPlayer();
    _currentIndex = widget.initialIndex;
    _currentSong = widget.song;
    _initAudioService();
  }

  Future<void> _initAudioService() async {
    try {
      // Cấu hình audio session
      final session = await AudioSession.instance;
      await session.configure(const AudioSessionConfiguration.music());

      // Khởi tạo AudioService
      await AudioService.init(
        builder: () => MyAudioHandler(_audioPlayer),
        config: AudioServiceConfig(
          androidNotificationChannelId: 't4.music.channel.id',
          androidNotificationChannelName: 'T4 Music',
          androidNotificationOngoing: true,
          androidStopForegroundOnPause: false,
        ),
      );

      setState(() {
        _isAudioServiceInitialized = true;
      });

      await _initializePlayer();
      _setupAudioListeners();
    } catch (e) {
      print('Lỗi khởi tạo AudioService: $e');
    }
  }

  void _setupAudioListeners() {
    // Nghe sự kiện thời lượng và vị trí
    _audioPlayer.positionStream.listen((position) {
      if (mounted) {
        setState(() {
          _currentPosition = position;
        });
      }
    });

    _audioPlayer.durationStream.listen((duration) {
      if (duration != null && mounted) {
        setState(() {
          _totalDuration = duration;
        });
      }
    });

    // Nghe sự kiện phát nhạc
    _audioPlayer.playerStateStream.listen((playerState) {
      final isPlaying = playerState.playing;
      final processingState = playerState.processingState;

      if (mounted) {
        setState(() {
          _isPlaying = isPlaying;
        });
      }

      // Tự động chuyển bài tiếp theo khi kết thúc bài hiện tại
      if (processingState == ProcessingState.completed && mounted) {
        _playNextSong();
      }
    });

    // Nghe sự kiện khi index thay đổi
    _audioPlayer.currentIndexStream.listen((index) {
      if (index != null && mounted && index != _currentIndex) {
        setState(() {
          _currentIndex = index;
          _currentSong = widget.songList[index];
        });
      }
    });
  }

  Future<void> _initializePlayer() async {
    try {
      // Cấu hình tính năng shuffle và repeat
      await _audioPlayer.setLoopMode(_loopMode);
      await _audioPlayer.setShuffleModeEnabled(_shuffleEnabled);

      // Tạo danh sách bài hát
      final playlist = ConcatenatingAudioSource(
        children: widget.songList
            .map((song) => AudioSource.asset(
                  song.fullAssetPath,
                  tag: MediaItem(
                    id: song.id,
                    title: song.title,
                    artist: song.artist,
                    artUri: Uri.parse('asset:///${song.fullCoverPath}'),
                  ),
                ))
            .toList(),
      );

      // In ra để debug
      print(
          'Đang cố gắng tải bài hát từ: ${widget.songList[_currentIndex].fullAssetPath}');
      print('Tên bài hát: ${widget.songList[_currentIndex].title}');

      // Thiết lập nguồn âm thanh và chơi
      await _audioPlayer.setAudioSource(playlist, initialIndex: _currentIndex);

      // Đảm bảo volume được thiết lập
      await _audioPlayer.setVolume(1.0);

      // Bắt đầu phát nhạc sau khi tải xong
      await _audioPlayer.play();

      setState(() {
        _isPlaying = true;
      });

      // Thiết lập bộ đệm và cấu hình hiệu suất
      await _audioPlayer.setAutomaticallyWaitsToMinimizeStalling(true);
    } catch (e) {
      print('Lỗi khi tải file audio: $e');
      // Hiển thị thông báo lỗi
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Lỗi khi phát nhạc: $e')),
        );
      }
    }
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.paused) {
      // App đang ở chế độ background - tiếp tục phát nhạc
    } else if (state == AppLifecycleState.resumed) {
      // App trở lại foreground
      if (_audioPlayer.playing) {
        setState(() {
          _isPlaying = true;
        });
      }
    }
  }

  void _playNextSong() {
    _audioPlayer.seekToNext();
  }

  void _playPreviousSong() {
    _audioPlayer.seekToPrevious();
  }

  void _togglePlay() {
    if (_isPlaying) {
      _audioPlayer.pause();
    } else {
      _audioPlayer.play();
    }
  }

  void _toggleShuffle() {
    setState(() {
      _shuffleEnabled = !_shuffleEnabled;
    });
    _audioPlayer.setShuffleModeEnabled(_shuffleEnabled);

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(_shuffleEnabled
            ? 'Đã bật phát ngẫu nhiên'
            : 'Đã tắt phát ngẫu nhiên'),
        duration: const Duration(seconds: 1),
      ),
    );
  }

  void _toggleLoopMode() {
    late LoopMode newMode;
    late String message;

    switch (_loopMode) {
      case LoopMode.off:
        newMode = LoopMode.all;
        message = 'Lặp lại tất cả';
        break;
      case LoopMode.all:
        newMode = LoopMode.one;
        message = 'Lặp lại một bài';
        break;
      case LoopMode.one:
        newMode = LoopMode.off;
        message = 'Tắt lặp lại';
        break;
    }

    setState(() {
      _loopMode = newMode;
    });

    _audioPlayer.setLoopMode(newMode);

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        duration: const Duration(seconds: 1),
      ),
    );
  }

  String _formatDuration(Duration duration) {
    String twoDigits(int n) => n.toString().padLeft(2, '0');
    return "${twoDigits(duration.inMinutes)}:${twoDigits(duration.inSeconds % 60)}";
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    _audioPlayer.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF1A1A1A),
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 24.0, vertical: 16.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Header
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  IconButton(
                    icon: const Icon(Icons.arrow_back_ios, color: Colors.white),
                    onPressed: () => Navigator.pop(context),
                  ),
                  const Text(
                    'Đang Phát',
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  IconButton(
                    icon: const Icon(Icons.more_vert, color: Colors.white),
                    onPressed: () {},
                  ),
                ],
              ),
              const SizedBox(height: 40),

              // Album image
              Expanded(
                child: Center(
                  child: Container(
                    width: double.infinity,
                    height: 350,
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(20),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withOpacity(0.3),
                          spreadRadius: 5,
                          blurRadius: 15,
                          offset: const Offset(0, 10),
                        ),
                      ],
                      image: DecorationImage(
                        image: AssetImage(_currentSong.fullCoverPath),
                        fit: BoxFit.cover,
                      ),
                    ),
                  ),
                ),
              ),
              const SizedBox(height: 40),

              // Song info
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          _currentSong.title,
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 24,
                            fontWeight: FontWeight.bold,
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                        const SizedBox(height: 4),
                        Text(
                          _currentSong.artist,
                          style: const TextStyle(
                            color: Colors.grey,
                            fontSize: 16,
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ],
                    ),
                  ),
                  IconButton(
                    onPressed: () {
                      final wasFavorite = _currentSong.isFavorite;
                      setState(() {
                        _currentSong.isFavorite = !wasFavorite;
                        widget.songList[_currentIndex].isFavorite =
                            _currentSong.isFavorite;
                      });

                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(
                          content: Text(
                            wasFavorite
                                ? 'Đã xoá khỏi yêu thích'
                                : 'Đã thêm vào yêu thích',
                          ),
                          duration: const Duration(seconds: 1),
                        ),
                      );
                    },
                    icon: Icon(
                      _currentSong.isFavorite
                          ? Icons.favorite
                          : Icons.favorite_border,
                      color:
                          _currentSong.isFavorite ? Colors.red : Colors.white,
                    ),
                  ),
                ],
              ),

              // Slider
              Slider(
                value: _currentPosition.inSeconds
                    .toDouble()
                    .clamp(0.0, _totalDuration.inSeconds.toDouble()),
                min: 0,
                max: _totalDuration.inSeconds.toDouble(),
                activeColor: const Color(0xFF31C934),
                inactiveColor: Colors.grey.shade800,
                onChanged: (value) {
                  final position = Duration(seconds: value.toInt());
                  _audioPlayer.seek(position);
                },
              ),
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16.0),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      _formatDuration(_currentPosition),
                      style: const TextStyle(color: Colors.grey, fontSize: 12),
                    ),
                    Text(
                      _formatDuration(_totalDuration),
                      style: const TextStyle(color: Colors.grey, fontSize: 12),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 24),

              // Controls
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                children: [
                  IconButton(
                    icon: Icon(Icons.shuffle,
                        color: _shuffleEnabled
                            ? const Color(0xFF31C934)
                            : Colors.white),
                    onPressed: _toggleShuffle,
                  ),
                  IconButton(
                    icon: const Icon(Icons.skip_previous,
                        color: Colors.white, size: 36),
                    onPressed: _playPreviousSong,
                  ),
                  Container(
                    width: 64,
                    height: 64,
                    decoration: const BoxDecoration(
                      shape: BoxShape.circle,
                      color: Color(0xFF31C934),
                    ),
                    child: IconButton(
                      icon: Icon(
                        _isPlaying ? Icons.pause : Icons.play_arrow,
                        color: Colors.white,
                        size: 32,
                      ),
                      onPressed: _togglePlay,
                    ),
                  ),
                  IconButton(
                    icon: const Icon(Icons.skip_next,
                        color: Colors.white, size: 36),
                    onPressed: _playNextSong,
                  ),
                  IconButton(
                    icon: Icon(
                      _loopMode == LoopMode.off
                          ? Icons.repeat
                          : _loopMode == LoopMode.one
                              ? Icons.repeat_one
                              : Icons.repeat,
                      color: _loopMode != LoopMode.off
                          ? const Color(0xFF31C934)
                          : Colors.white,
                    ),
                    onPressed: _toggleLoopMode,
                  ),
                ],
              ),
              const SizedBox(height: 16),
              // Nút xem lời bài hát
              Center(
                child: ElevatedButton(
                  onPressed: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (_) => LyricsScreen(
                          song: _currentSong,
                          position: _currentPosition,
                          duration: _totalDuration,
                          audioPlayer: _audioPlayer,
                        ),
                      ),
                    );
                  },
                  style: ElevatedButton.styleFrom(
                    foregroundColor: Colors.white,
                    backgroundColor: Colors.grey.shade900,
                    padding: const EdgeInsets.symmetric(
                        horizontal: 32, vertical: 12),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(30),
                    ),
                  ),
                  child: const Text('Lời bài hát'),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

// Handler cho audio service để phát nhạc nền
class MyAudioHandler extends BaseAudioHandler with SeekHandler {
  final AudioPlayer player;

  MyAudioHandler(this.player) {
    player.playbackEventStream.listen((PlaybackEvent event) {
      playbackState.add(playbackState.value.copyWith(
        controls: [
          MediaControl.skipToPrevious,
          if (player.playing) MediaControl.pause else MediaControl.play,
          MediaControl.skipToNext,
        ],
        systemActions: const {
          MediaAction.seek,
          MediaAction.seekForward,
          MediaAction.seekBackward,
        },
        androidCompactActionIndices: const [0, 1, 2],
        processingState: const {
          ProcessingState.idle: AudioProcessingState.idle,
          ProcessingState.loading: AudioProcessingState.loading,
          ProcessingState.buffering: AudioProcessingState.buffering,
          ProcessingState.ready: AudioProcessingState.ready,
          ProcessingState.completed: AudioProcessingState.completed,
        }[player.processingState]!,
        playing: player.playing,
        updatePosition: player.position,
        bufferedPosition: player.bufferedPosition,
        speed: player.speed,
        queueIndex: player.currentIndex,
      ));
    });
  }

  @override
  Future<void> play() => player.play();

  @override
  Future<void> pause() => player.pause();

  @override
  Future<void> seek(Duration position) => player.seek(position);

  @override
  Future<void> skipToQueueItem(int index) async {
    player.seek(Duration.zero, index: index);
  }

  @override
  Future<void> skipToNext() => player.seekToNext();

  @override
  Future<void> skipToPrevious() => player.seekToPrevious();

  @override
  Future<void> stop() => player.stop();
}
