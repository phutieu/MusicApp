import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:t4/models/playlist.dart';
import 'package:t4/models/song.dart';
import 'package:t4/presentation/screen/now_playing_screen.dart';

class PlaylistDetailScreen extends StatefulWidget {
  final Playlist playlist;

  const PlaylistDetailScreen({Key? key, required this.playlist})
      : super(key: key);

  @override
  State<PlaylistDetailScreen> createState() => _PlaylistDetailScreenState();
}

class _PlaylistDetailScreenState extends State<PlaylistDetailScreen> {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  List<Song> _songs = [];
  List<Song> _allSongs = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadSongs();
  }

  Future<void> _loadSongs() async {
    setState(() {
      _isLoading = true;
    });

    try {
      // Tải tất cả bài hát
      final allSongsSnapshot = await _firestore.collection('songs').get();
      final allSongs = allSongsSnapshot.docs.map((doc) {
        return Song.fromMap(doc.data(), doc.id);
      }).toList();

      // Lọc các bài hát trong playlist
      final playlistSongs = allSongs
          .where((song) => widget.playlist.songIds.contains(song.id))
          .toList();

      setState(() {
        _songs = playlistSongs;
        _allSongs = allSongs;
        _isLoading = false;
      });
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Lỗi khi tải danh sách bài hát: $e')),
      );
      setState(() {
        _isLoading = false;
      });
    }
  }

  Future<void> _addSongsToPlaylist() async {
    // Danh sách bài hát chưa có trong playlist
    final availableSongs = _allSongs
        .where((song) => !widget.playlist.songIds.contains(song.id))
        .toList();

    if (availableSongs.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Không có bài hát nào có sẵn để thêm')),
      );
      return;
    }

    final result = await showDialog<List<String>>(
      context: context,
      builder: (context) => _AddSongsDialog(songs: availableSongs),
    );

    if (result != null && result.isNotEmpty) {
      setState(() {
        _isLoading = true;
      });

      try {
        // Cập nhật danh sách ID bài hát trong playlist
        final updatedSongIds = [...widget.playlist.songIds, ...result];

        await _firestore
            .collection('playlists')
            .doc(widget.playlist.id)
            .update({
          'songIds': updatedSongIds,
          'updatedAt': FieldValue.serverTimestamp(),
        });

        // Cập nhật model và UI
        final newSongs =
            _allSongs.where((song) => result.contains(song.id)).toList();

        setState(() {
          _songs.addAll(newSongs);
          widget.playlist.songIds.addAll(result);
          _isLoading = false;
        });

        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
              content:
                  Text('Đã thêm ${result.length} bài hát vào danh sách phát')),
        );
      } catch (e) {
        setState(() {
          _isLoading = false;
        });
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Lỗi khi thêm bài hát: $e')),
        );
      }
    }
  }

  Future<void> _removeSongFromPlaylist(Song song) async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Xác nhận xóa'),
        content: Text(
            'Bạn có chắc muốn xóa bài hát "${song.title}" khỏi danh sách phát không?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Hủy'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            style: TextButton.styleFrom(
              foregroundColor: Colors.red,
            ),
            child: const Text('Xóa'),
          ),
        ],
      ),
    );

    if (confirm == true) {
      setState(() {
        _isLoading = true;
      });

      try {
        // Xóa ID bài hát khỏi danh sách
        final updatedSongIds =
            widget.playlist.songIds.where((id) => id != song.id).toList();

        await _firestore
            .collection('playlists')
            .doc(widget.playlist.id)
            .update({
          'songIds': updatedSongIds,
          'updatedAt': FieldValue.serverTimestamp(),
        });

        setState(() {
          _songs.removeWhere((s) => s.id == song.id);
          widget.playlist.songIds.remove(song.id);
          _isLoading = false;
        });

        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Đã xóa "${song.title}" khỏi danh sách phát')),
        );
      } catch (e) {
        setState(() {
          _isLoading = false;
        });
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Lỗi khi xóa bài hát: $e')),
        );
      }
    }
  }

  Future<void> _playAllSongs() async {
    if (_songs.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Danh sách phát trống')),
      );
      return;
    }

    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => NowPlayingScreen(
          song: _songs[0],
          songList: _songs,
          initialIndex: 0,
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        title: Text(
          widget.playlist.name,
          style: const TextStyle(fontWeight: FontWeight.bold),
        ),
        backgroundColor: Colors.white,
        elevation: 0,
        actions: [
          IconButton(
            icon:
                const Icon(Icons.play_circle_filled, color: Color(0xFF31C934)),
            onPressed: _playAllSongs,
            tooltip: 'Phát tất cả',
          ),
        ],
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : _songs.isEmpty
              ? Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      const Icon(
                        Icons.music_note,
                        size: 80,
                        color: Colors.grey,
                      ),
                      const SizedBox(height: 16),
                      const Text(
                        'Danh sách phát trống',
                        style: TextStyle(
                          fontSize: 18,
                          color: Colors.grey,
                        ),
                      ),
                      const SizedBox(height: 24),
                      ElevatedButton(
                        onPressed: _addSongsToPlaylist,
                        style: ElevatedButton.styleFrom(
                          backgroundColor: const Color(0xFF31C934),
                          foregroundColor: Colors.white,
                          padding: const EdgeInsets.symmetric(
                            horizontal: 32,
                            vertical: 12,
                          ),
                        ),
                        child: const Text('Thêm bài hát'),
                      ),
                    ],
                  ),
                )
              : Column(
                  children: [
                    // Thông tin playlist
                    Container(
                      width: double.infinity,
                      padding: const EdgeInsets.all(16),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          if (widget.playlist.description != null &&
                              widget.playlist.description!.isNotEmpty)
                            Padding(
                              padding: const EdgeInsets.only(bottom: 8),
                              child: Text(
                                widget.playlist.description!,
                                style: const TextStyle(
                                  color: Colors.grey,
                                  fontSize: 14,
                                ),
                              ),
                            ),
                          Text(
                            '${_songs.length} bài hát',
                            style: TextStyle(
                              color: Colors.grey[700],
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                        ],
                      ),
                    ),

                    // Danh sách bài hát
                    Expanded(
                      child: ListView.builder(
                        itemCount: _songs.length,
                        itemBuilder: (context, index) {
                          final song = _songs[index];
                          return ListTile(
                            leading: Container(
                              width: 50,
                              height: 50,
                              decoration: BoxDecoration(
                                borderRadius: BorderRadius.circular(8),
                                image: DecorationImage(
                                  image: AssetImage(song.coverImage),
                                  fit: BoxFit.cover,
                                ),
                              ),
                            ),
                            title: Text(
                              song.title,
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            ),
                            subtitle: Text(
                              song.artist,
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              style: TextStyle(color: Colors.grey[600]),
                            ),
                            trailing: IconButton(
                              icon: const Icon(Icons.remove_circle_outline,
                                  color: Colors.red),
                              onPressed: () => _removeSongFromPlaylist(song),
                            ),
                            onTap: () {
                              Navigator.push(
                                context,
                                MaterialPageRoute(
                                  builder: (_) => NowPlayingScreen(
                                    song: song,
                                    songList: _songs,
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
      floatingActionButton: _songs.isNotEmpty
          ? FloatingActionButton(
              backgroundColor: const Color(0xFF31C934),
              child: const Icon(Icons.add),
              onPressed: _addSongsToPlaylist,
              tooltip: 'Thêm bài hát',
            )
          : null,
    );
  }
}

class _AddSongsDialog extends StatefulWidget {
  final List<Song> songs;

  const _AddSongsDialog({Key? key, required this.songs}) : super(key: key);

  @override
  State<_AddSongsDialog> createState() => _AddSongsDialogState();
}

class _AddSongsDialogState extends State<_AddSongsDialog> {
  final Set<String> _selectedSongIds = {};
  String _searchQuery = '';

  List<Song> get _filteredSongs {
    if (_searchQuery.isEmpty) {
      return widget.songs;
    }

    final query = _searchQuery.toLowerCase();
    return widget.songs.where((song) {
      return song.title.toLowerCase().contains(query) ||
          song.artist.toLowerCase().contains(query);
    }).toList();
  }

  @override
  Widget build(BuildContext context) {
    return Dialog(
      insetPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 24),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Thêm bài hát',
              style: TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 16),

            // Thanh tìm kiếm
            TextField(
              decoration: const InputDecoration(
                hintText: 'Tìm kiếm bài hát...',
                prefixIcon: Icon(Icons.search),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.all(Radius.circular(20)),
                ),
                contentPadding: EdgeInsets.symmetric(vertical: 12),
              ),
              onChanged: (value) {
                setState(() {
                  _searchQuery = value;
                });
              },
            ),

            const SizedBox(height: 8),

            Expanded(
              child: _filteredSongs.isEmpty
                  ? const Center(
                      child: Text(
                        'Không tìm thấy bài hát phù hợp',
                        style: TextStyle(color: Colors.grey),
                      ),
                    )
                  : ListView.builder(
                      itemCount: _filteredSongs.length,
                      itemBuilder: (context, index) {
                        final song = _filteredSongs[index];
                        final isSelected = _selectedSongIds.contains(song.id);

                        return CheckboxListTile(
                          value: isSelected,
                          onChanged: (value) {
                            setState(() {
                              if (value == true) {
                                _selectedSongIds.add(song.id);
                              } else {
                                _selectedSongIds.remove(song.id);
                              }
                            });
                          },
                          title: Text(
                            song.title,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                          subtitle: Text(
                            song.artist,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                          secondary: Container(
                            width: 40,
                            height: 40,
                            decoration: BoxDecoration(
                              borderRadius: BorderRadius.circular(6),
                              image: DecorationImage(
                                image: AssetImage(song.coverImage),
                                fit: BoxFit.cover,
                              ),
                            ),
                          ),
                          activeColor: const Color(0xFF31C934),
                        );
                      },
                    ),
            ),

            Padding(
              padding: const EdgeInsets.only(top: 16),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.end,
                children: [
                  TextButton(
                    onPressed: () => Navigator.pop(context),
                    child: const Text('Hủy'),
                  ),
                  const SizedBox(width: 16),
                  ElevatedButton(
                    onPressed: _selectedSongIds.isEmpty
                        ? null
                        : () {
                            Navigator.pop(context, _selectedSongIds.toList());
                          },
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFF31C934),
                    ),
                    child: Text('Thêm (${_selectedSongIds.length})'),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
