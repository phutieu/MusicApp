import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:t4/models/album.dart';
import 'package:t4/models/song.dart';
import 'package:t4/presentation/screen/now_playing_screen.dart';

class AlbumScreen extends StatefulWidget {
  const AlbumScreen({Key? key}) : super(key: key);

  @override
  State<AlbumScreen> createState() => _AlbumScreenState();
}

class _AlbumScreenState extends State<AlbumScreen> {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  List<Album> _albums = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadAlbums();
  }

  Future<void> _loadAlbums() async {
    setState(() {
      _isLoading = true;
    });

    try {
      final snapshot = await _firestore.collection('albums').get();
      final albums = snapshot.docs.map((doc) {
        return Album.fromMap(doc.data(), doc.id);
      }).toList();

      setState(() {
        _albums = albums;
        _isLoading = false;
      });
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Lỗi khi tải album: $e')),
      );
      setState(() {
        _isLoading = false;
      });
    }
  }

  void _navigateToAlbumDetail(Album album) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => AlbumDetailScreen(album: album),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        title: const Text(
          'Album Nghệ Sĩ',
          style: TextStyle(fontWeight: FontWeight.bold),
        ),
        backgroundColor: Colors.white,
        elevation: 0,
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : _albums.isEmpty
              ? const Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(
                        Icons.album,
                        size: 80,
                        color: Colors.grey,
                      ),
                      SizedBox(height: 16),
                      Text(
                        'Không có album nào',
                        style: TextStyle(
                          fontSize: 18,
                          color: Colors.grey,
                        ),
                      ),
                    ],
                  ),
                )
              : GridView.builder(
                  padding: const EdgeInsets.all(16),
                  gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                    crossAxisCount: 2,
                    childAspectRatio: 0.8,
                    crossAxisSpacing: 16,
                    mainAxisSpacing: 16,
                  ),
                  itemCount: _albums.length,
                  itemBuilder: (context, index) {
                    final album = _albums[index];
                    return GestureDetector(
                      onTap: () => _navigateToAlbumDetail(album),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          // Album cover
                          Expanded(
                            child: Container(
                              decoration: BoxDecoration(
                                borderRadius: BorderRadius.circular(8),
                                image: DecorationImage(
                                  image: AssetImage(album.coverImage),
                                  fit: BoxFit.cover,
                                ),
                                boxShadow: [
                                  BoxShadow(
                                    color: Colors.black.withOpacity(0.1),
                                    blurRadius: 5,
                                    offset: const Offset(0, 3),
                                  ),
                                ],
                              ),
                            ),
                          ),
                          const SizedBox(height: 8),
                          // Album name
                          Text(
                            album.name,
                            style: const TextStyle(
                              fontWeight: FontWeight.bold,
                              fontSize: 14,
                            ),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                          // Artist name
                          Text(
                            album.artist,
                            style: TextStyle(
                              color: Colors.grey[600],
                              fontSize: 12,
                            ),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ],
                      ),
                    );
                  },
                ),
    );
  }
}

class AlbumDetailScreen extends StatefulWidget {
  final Album album;

  const AlbumDetailScreen({Key? key, required this.album}) : super(key: key);

  @override
  State<AlbumDetailScreen> createState() => _AlbumDetailScreenState();
}

class _AlbumDetailScreenState extends State<AlbumDetailScreen> {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  List<Song> _songs = [];
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
      final songsSnapshot = await _firestore
          .collection('songs')
          .where('albumId', isEqualTo: widget.album.id)
          .get();

      final songs = songsSnapshot.docs.map((doc) {
        return Song.fromMap(doc.data(), doc.id);
      }).toList();

      setState(() {
        _songs = songs;
        _isLoading = false;
      });
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Lỗi khi tải bài hát: $e')),
      );
      setState(() {
        _isLoading = false;
      });
    }
  }

  void _playAllSongs() {
    if (_songs.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Album không có bài hát nào')),
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
      body: CustomScrollView(
        slivers: [
          // App bar có ảnh bìa album
          SliverAppBar(
            expandedHeight: 200,
            pinned: true,
            flexibleSpace: FlexibleSpaceBar(
              title: Text(
                widget.album.name,
                style: const TextStyle(
                  fontWeight: FontWeight.bold,
                  color: Colors.white,
                  shadows: [
                    Shadow(
                      offset: Offset(1, 1),
                      blurRadius: 2,
                      color: Colors.black,
                    ),
                  ],
                ),
              ),
              background: Stack(
                fit: StackFit.expand,
                children: [
                  // Ảnh bìa album
                  Image.asset(
                    widget.album.coverImage,
                    fit: BoxFit.cover,
                  ),
                  // Gradient overlay để chữ dễ đọc
                  Container(
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        begin: Alignment.topCenter,
                        end: Alignment.bottomCenter,
                        colors: [
                          Colors.transparent,
                          Colors.black.withOpacity(0.7),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),

          // Thông tin album
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Tên nghệ sĩ
                  Text(
                    widget.album.artist,
                    style: const TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                  const SizedBox(height: 16),
                  // Số lượng bài hát
                  Text(
                    '${_songs.length} bài hát',
                    style: TextStyle(
                      color: Colors.grey[700],
                    ),
                  ),
                  const SizedBox(height: 16),
                  // Nút phát tất cả
                  SizedBox(
                    width: double.infinity,
                    child: ElevatedButton.icon(
                      onPressed: _playAllSongs,
                      icon: const Icon(Icons.play_circle_filled),
                      label: const Text('Phát tất cả'),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: const Color(0xFF31C934),
                        foregroundColor: Colors.white,
                        padding: const EdgeInsets.symmetric(vertical: 12),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(24),
                        ),
                      ),
                    ),
                  ),
                  const Divider(
                    height: 32,
                    thickness: 1,
                  ),
                ],
              ),
            ),
          ),

          // Danh sách bài hát
          _isLoading
              ? const SliverFillRemaining(
                  child: Center(child: CircularProgressIndicator()),
                )
              : _songs.isEmpty
                  ? const SliverFillRemaining(
                      child: Center(
                        child: Text(
                          'Album không có bài hát nào',
                          style: TextStyle(color: Colors.grey),
                        ),
                      ),
                    )
                  : SliverList(
                      delegate: SliverChildBuilderDelegate(
                        (context, index) {
                          final song = _songs[index];
                          return ListTile(
                            leading: CircleAvatar(
                              backgroundImage: AssetImage(song.coverImage),
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
                            ),
                            trailing: IconButton(
                              icon: Icon(
                                song.isFavorite
                                    ? Icons.favorite
                                    : Icons.favorite_border,
                                color:
                                    song.isFavorite ? Colors.red : Colors.grey,
                              ),
                              onPressed: () {
                                // Xử lý thích bài hát
                                setState(() {
                                  song.isFavorite = !song.isFavorite;
                                });
                              },
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
                        childCount: _songs.length,
                      ),
                    ),
        ],
      ),
    );
  }
}
