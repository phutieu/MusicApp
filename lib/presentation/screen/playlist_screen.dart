import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:t4/models/playlist.dart';
import 'package:t4/models/song.dart';
import 'package:t4/presentation/screen/playlist_detail_screen.dart';

class PlaylistScreen extends StatefulWidget {
  const PlaylistScreen({Key? key}) : super(key: key);

  @override
  State<PlaylistScreen> createState() => _PlaylistScreenState();
}

class _PlaylistScreenState extends State<PlaylistScreen> {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final FirebaseAuth _auth = FirebaseAuth.instance;

  List<Playlist> _playlists = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadPlaylists();
  }

  Future<void> _loadPlaylists() async {
    setState(() {
      _isLoading = true;
    });

    try {
      final userId = _auth.currentUser?.uid;
      if (userId == null) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
              content: Text('Bạn cần đăng nhập để xem danh sách phát')),
        );
        setState(() {
          _isLoading = false;
        });
        return;
      }

      final snapshot = await _firestore
          .collection('playlists')
          .where('userId', isEqualTo: userId)
          .get();

      final playlists = snapshot.docs.map((doc) {
        return Playlist.fromMap(doc.data(), doc.id);
      }).toList();

      setState(() {
        _playlists = playlists;
        _isLoading = false;
      });
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Lỗi khi tải danh sách phát: $e')),
      );
      setState(() {
        _isLoading = false;
      });
    }
  }

  Future<void> _createPlaylist() async {
    final TextEditingController nameController = TextEditingController();
    final TextEditingController descController = TextEditingController();

    final result = await showDialog<Map<String, String>>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Tạo danh sách phát mới'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(
              controller: nameController,
              decoration: const InputDecoration(
                labelText: 'Tên danh sách phát',
                hintText: 'Nhập tên danh sách phát',
              ),
            ),
            const SizedBox(height: 16),
            TextField(
              controller: descController,
              decoration: const InputDecoration(
                labelText: 'Mô tả (tùy chọn)',
                hintText: 'Nhập mô tả',
              ),
              maxLines: 2,
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Hủy'),
          ),
          ElevatedButton(
            onPressed: () {
              final name = nameController.text.trim();
              if (name.isEmpty) {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(
                      content: Text('Vui lòng nhập tên danh sách phát')),
                );
                return;
              }
              Navigator.pop(context, {
                'name': name,
                'description': descController.text.trim(),
              });
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFF31C934),
            ),
            child: const Text('Tạo'),
          ),
        ],
      ),
    );

    if (result != null) {
      final userId = _auth.currentUser?.uid;
      if (userId == null) return;

      setState(() {
        _isLoading = true;
      });

      try {
        final docRef = await _firestore.collection('playlists').add({
          'name': result['name'],
          'description': result['description'],
          'userId': userId,
          'coverImage': 'assets/images/default_playlist.png', // Ảnh mặc định
          'songIds': [],
          'createdAt': FieldValue.serverTimestamp(),
          'updatedAt': FieldValue.serverTimestamp(),
        });

        final newPlaylist = Playlist(
          id: docRef.id,
          name: result['name']!,
          description: result['description'],
          coverImage: 'assets/images/default_playlist.png',
          userId: userId,
          songIds: [],
          createdAt: DateTime.now(),
          updatedAt: DateTime.now(),
        );

        setState(() {
          _playlists.add(newPlaylist);
          _isLoading = false;
        });

        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Đã tạo danh sách phát ${result['name']}')),
        );
      } catch (e) {
        setState(() {
          _isLoading = false;
        });
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Lỗi khi tạo danh sách phát: $e')),
        );
      }
    }
  }

  Future<void> _deletePlaylist(Playlist playlist) async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Xác nhận xóa'),
        content: Text(
            'Bạn có chắc muốn xóa danh sách phát "${playlist.name}" không?'),
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
        await _firestore.collection('playlists').doc(playlist.id).delete();

        setState(() {
          _playlists.removeWhere((item) => item.id == playlist.id);
          _isLoading = false;
        });

        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Đã xóa danh sách phát ${playlist.name}')),
        );
      } catch (e) {
        setState(() {
          _isLoading = false;
        });
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Lỗi khi xóa danh sách phát: $e')),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        title: const Text(
          'Danh sách phát của tôi',
          style: TextStyle(fontWeight: FontWeight.bold),
        ),
        backgroundColor: Colors.white,
        elevation: 0,
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : _playlists.isEmpty
              ? Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      const Icon(
                        Icons.playlist_play,
                        size: 80,
                        color: Colors.grey,
                      ),
                      const SizedBox(height: 16),
                      const Text(
                        'Bạn chưa có danh sách phát nào',
                        style: TextStyle(
                          fontSize: 18,
                          color: Colors.grey,
                        ),
                      ),
                      const SizedBox(height: 24),
                      ElevatedButton(
                        onPressed: _createPlaylist,
                        style: ElevatedButton.styleFrom(
                          backgroundColor: const Color(0xFF31C934),
                          foregroundColor: Colors.white,
                          padding: const EdgeInsets.symmetric(
                            horizontal: 32,
                            vertical: 12,
                          ),
                        ),
                        child: const Text('Tạo danh sách phát mới'),
                      ),
                    ],
                  ),
                )
              : ListView.builder(
                  padding: const EdgeInsets.all(16),
                  itemCount: _playlists.length,
                  itemBuilder: (context, index) {
                    final playlist = _playlists[index];
                    return Card(
                      elevation: 2,
                      margin: const EdgeInsets.only(bottom: 16),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: InkWell(
                        onTap: () {
                          Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (_) =>
                                  PlaylistDetailScreen(playlist: playlist),
                            ),
                          ).then((_) => _loadPlaylists());
                        },
                        borderRadius: BorderRadius.circular(12),
                        child: Padding(
                          padding: const EdgeInsets.all(16),
                          child: Row(
                            children: [
                              Container(
                                width: 60,
                                height: 60,
                                decoration: BoxDecoration(
                                  borderRadius: BorderRadius.circular(8),
                                  image: DecorationImage(
                                    image: AssetImage(playlist.coverImage),
                                    fit: BoxFit.cover,
                                  ),
                                ),
                              ),
                              const SizedBox(width: 16),
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      playlist.name,
                                      style: const TextStyle(
                                        fontSize: 16,
                                        fontWeight: FontWeight.bold,
                                      ),
                                    ),
                                    const SizedBox(height: 4),
                                    Text(
                                      '${playlist.songIds.length} bài hát',
                                      style: TextStyle(
                                        color: Colors.grey[600],
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                              PopupMenuButton(
                                itemBuilder: (context) => [
                                  const PopupMenuItem(
                                    value: 'edit',
                                    child: ListTile(
                                      leading: Icon(Icons.edit),
                                      title: Text('Chỉnh sửa'),
                                      contentPadding: EdgeInsets.zero,
                                    ),
                                  ),
                                  const PopupMenuItem(
                                    value: 'delete',
                                    child: ListTile(
                                      leading:
                                          Icon(Icons.delete, color: Colors.red),
                                      title: Text('Xóa',
                                          style: TextStyle(color: Colors.red)),
                                      contentPadding: EdgeInsets.zero,
                                    ),
                                  ),
                                ],
                                onSelected: (value) {
                                  if (value == 'delete') {
                                    _deletePlaylist(playlist);
                                  } else if (value == 'edit') {
                                    // Xử lý chỉnh sửa
                                  }
                                },
                              ),
                            ],
                          ),
                        ),
                      ),
                    );
                  },
                ),
      floatingActionButton: _playlists.isNotEmpty
          ? FloatingActionButton(
              backgroundColor: const Color(0xFF31C934),
              child: const Icon(Icons.add),
              onPressed: _createPlaylist,
            )
          : null,
    );
  }
}
