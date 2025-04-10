import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:just_audio/just_audio.dart';
import 'package:t4/data/song_list.dart';
import 'package:t4/models/song.dart';
import 'package:t4/presentation/screen/home_screen.dart';

import 'now_playing_screen.dart';
import 'search_screen.dart';

class FavoriteScreen extends StatefulWidget {
  @override
  State<FavoriteScreen> createState() => _FavoriteScreenState();
}

class _FavoriteScreenState extends State<FavoriteScreen> {
  final User? user = FirebaseAuth.instance.currentUser;
  late List<Song> favoriteSongs;
  final Map<String, Duration> _durations = {};
  int _selectedIndex = 2;

  @override
  void initState() {
    super.initState();
    favoriteSongs = songList.where((s) => s.isFavorite).toList();
    _loadDurations();
  }

  Future<void> _loadDurations() async {
    for (var song in favoriteSongs) {
      if (!_durations.containsKey(song.assetPath)) {
        final player = AudioPlayer();
        try {
          await player.setAsset(song.assetPath);
          final duration = player.duration;
          if (duration != null) {
            setState(() {
              _durations[song.assetPath] = duration;
            });
          }
        } catch (e) {
          print("Lỗi khi load duration: $e");
        } finally {
          player.dispose();
        }
      }
    }
  }

  String _formatDuration(Duration duration) {
    String twoDigits(int n) => n.toString().padLeft(2, '0');
    return "${twoDigits(duration.inMinutes)}:${twoDigits(duration.inSeconds % 60)}";
  }

  void _toggleFavorite(Song song) {
    setState(() {
      song.isFavorite = false;
      favoriteSongs = songList.where((s) => s.isFavorite).toList();
    });

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text('Đã xoá khỏi yêu thích')),
    );
  }

  void _onItemTapped(int index) {
    setState(() {
      _selectedIndex = index;
    });

    if (index == 0) {
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(builder: (context) => HomeScreen()),
      );
    } else if (index == 1) {
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(builder: (context) => SearchScreen()),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(20),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  IconButton(
                    icon: Icon(Icons.arrow_back),
                    onPressed: () => Navigator.pop(context),
                  ),
                  Spacer(),
                  Icon(Icons.more_vert),
                ],
              ),
              SizedBox(height: 10),
              Center(child: Icon(Icons.account_circle, size: 100)),
              SizedBox(height: 10),
              Center(
                child: Text(user?.email ?? '', style: TextStyle(fontSize: 16)),
              ),
              Center(
                child: Text(
                  user?.displayName ?? 'Không rõ tên',
                  style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
                ),
              ),
              SizedBox(height: 30),
              Text(
                'Bài hát ưa thích',
                style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
              ),
              SizedBox(height: 15),
              Expanded(
                child: favoriteSongs.isEmpty
                    ? Center(child: Text('Không có bài hát yêu thích.'))
                    : ListView.builder(
                        itemCount: favoriteSongs.length,
                        itemBuilder: (context, index) {
                          final song = favoriteSongs[index];
                          final duration = _durations[song.assetPath];
                          return ListTile(
                            leading: ClipRRect(
                              borderRadius: BorderRadius.circular(8),
                              child: Image.asset(song.coverImage,
                                  width: 50, height: 50, fit: BoxFit.cover),
                            ),
                            title: Text(song.title,
                                style: TextStyle(fontWeight: FontWeight.bold)),
                            subtitle: Text(song.artist),
                            trailing: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Text(
                                  duration != null
                                      ? _formatDuration(duration)
                                      : "--:--",
                                  style: TextStyle(fontSize: 14),
                                ),
                                IconButton(
                                  icon: Icon(Icons.favorite_border),
                                  iconSize: 24,
                                  onPressed: () => _toggleFavorite(song),
                                ),
                              ],
                            ),
                            onTap: () {
                              Navigator.push(
                                context,
                                MaterialPageRoute(
                                  builder: (context) => NowPlayingScreen(
                                    song: song,
                                    songList: favoriteSongs,
                                    initialIndex: index,
                                  ),
                                ),
                              );
                            },
                          );
                        },
                      ),
              ),
            ],
          ),
        ),
      ),
      bottomNavigationBar: BottomNavigationBar(
        currentIndex: _selectedIndex,
        onTap: _onItemTapped,
        selectedItemColor: Colors.green,
        unselectedItemColor: Colors.grey,
        items: const [
          BottomNavigationBarItem(icon: Icon(Icons.home), label: ''),
          BottomNavigationBarItem(icon: Icon(Icons.search), label: ''),
          BottomNavigationBarItem(icon: Icon(Icons.favorite), label: ''),
        ],
      ),
    );
  }
}
