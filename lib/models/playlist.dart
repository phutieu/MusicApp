import 'package:cloud_firestore/cloud_firestore.dart';

class Playlist {
  final String id;
  final String name;
  final String? description;
  final String coverImage; // Ảnh bìa của danh sách phát
  final String userId; // ID của người dùng tạo playlist
  final List<String> songIds; // Danh sách các ID bài hát
  final DateTime createdAt;
  final DateTime updatedAt;

  Playlist({
    required this.id,
    required this.name,
    this.description,
    required this.coverImage,
    required this.userId,
    required this.songIds,
    required this.createdAt,
    required this.updatedAt,
  });

  // Tạo một bản sao của đối tượng playlist với các thuộc tính có thể thay đổi
  Playlist copyWith({
    String? name,
    String? description,
    String? coverImage,
    List<String>? songIds,
    DateTime? updatedAt,
  }) {
    return Playlist(
      id: this.id,
      name: name ?? this.name,
      description: description ?? this.description,
      coverImage: coverImage ?? this.coverImage,
      userId: this.userId,
      songIds: songIds ?? List.from(this.songIds),
      createdAt: this.createdAt,
      updatedAt: updatedAt ?? DateTime.now(),
    );
  }

  // Thêm một bài hát vào playlist
  Playlist addSong(String songId) {
    if (songIds.contains(songId)) return this;

    List<String> newSongIds = List.from(songIds);
    newSongIds.add(songId);

    return copyWith(
      songIds: newSongIds,
      updatedAt: DateTime.now(),
    );
  }

  // Xóa một bài hát khỏi playlist
  Playlist removeSong(String songId) {
    if (!songIds.contains(songId)) return this;

    List<String> newSongIds = List.from(songIds);
    newSongIds.remove(songId);

    return copyWith(
      songIds: newSongIds,
      updatedAt: DateTime.now(),
    );
  }

  // Chuyển đổi từ Map/JSON
  factory Playlist.fromMap(Map<String, dynamic> map, String documentId) {
    return Playlist(
      id: documentId,
      name: map['name'] ?? '',
      description: map['description'],
      coverImage: map['coverImage'] ?? '',
      userId: map['userId'] ?? '',
      songIds: List<String>.from(map['songIds'] ?? []),
      createdAt: (map['createdAt'] != null)
          ? (map['createdAt'] as Timestamp).toDate()
          : DateTime.now(),
      updatedAt: (map['updatedAt'] != null)
          ? (map['updatedAt'] as Timestamp).toDate()
          : DateTime.now(),
    );
  }

  // Chuyển đổi sang Map để lưu vào Firebase
  Map<String, dynamic> toMap() {
    return {
      'name': name,
      'description': description,
      'coverImage': coverImage,
      'userId': userId,
      'songIds': songIds,
      'createdAt': Timestamp.fromDate(createdAt),
      'updatedAt': Timestamp.fromDate(updatedAt),
    };
  }
}

// Tạo playlist mới
Playlist createNewPlaylist({
  required String id,
  required String name,
  String? description,
  required String coverImage,
  required String userId,
}) {
  final now = DateTime.now();
  return Playlist(
    id: id,
    name: name,
    description: description,
    coverImage: coverImage,
    userId: userId,
    songIds: [],
    createdAt: now,
    updatedAt: now,
  );
}
