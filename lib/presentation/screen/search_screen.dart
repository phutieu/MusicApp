import 'package:flutter/material.dart';
import 'package:t4/data/song_list.dart';
import 'package:t4/models/song.dart';
import 'package:t4/presentation/screen/now_playing_screen.dart';

class SearchScreen extends StatefulWidget {
  @override
  _SearchScreenState createState() => _SearchScreenState();
}

class _SearchScreenState extends State<SearchScreen> {
  TextEditingController _controller = TextEditingController();
  List<Song> _filteredSongs = songList;

  void _filterSongs(String query) {
    final results = songList.where((song) {
      final lowerQuery = query.toLowerCase();
      return song.title.toLowerCase().contains(lowerQuery) ||
          song.artist.toLowerCase().contains(lowerQuery);
    }).toList();

    setState(() {
      _filteredSongs = results;
    });
  }

  void _onSongTapped(Song song, int index) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => NowPlayingScreen(
          song: song,
          songList: _filteredSongs,
          initialIndex: index,
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Thanh tìm kiếm có nút quay lại bên trong container bo tròn
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 16),
                height: 50,
                decoration: BoxDecoration(
                  border: Border.all(
                      color: const Color.fromARGB(255, 0, 0, 0), width: 2),
                  borderRadius: BorderRadius.circular(25),
                ),
                child: Row(
                  children: [
                    GestureDetector(
                      onTap: () => Navigator.pop(context),
                      child: const Icon(Icons.arrow_back_ios_new, size: 20),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: TextField(
                        controller: _controller,
                        onChanged: _filterSongs,
                        decoration: const InputDecoration(
                          border: InputBorder.none,
                          hintText: 'Bạn muốn nghe gì?',
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 20),
              const Text(
                'Kết quả tìm kiếm',
                style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 10),
              Expanded(
                child: _filteredSongs.isEmpty
                    ? const Center(child: Text('Không tìm thấy bài hát nào.'))
                    : ListView.builder(
                        itemCount: _filteredSongs.length,
                        itemBuilder: (context, index) {
                          final song = _filteredSongs[index];
                          return ListTile(
                            leading: Image.asset(
                              song.coverImage,
                              width: 50,
                              height: 50,
                              fit: BoxFit.cover,
                            ),
                            title: Text(
                              song.title,
                              style: const TextStyle(
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                            subtitle: Text(song.artist),
                            onTap: () => _onSongTapped(song, index),
                          );
                        },
                      ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
