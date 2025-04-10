class Song {
  final String id;
  final String title;
  final String artist;
  final String coverImage;
  final String assetPath;
  final String lyrics;
  final String? albumId;
  final String? albumName;
  bool isFavorite;

  Song({
    required this.id,
    required this.title,
    required this.artist,
    required this.coverImage,
    required this.assetPath,
    required this.lyrics,
    this.albumId,
    this.albumName,
    this.isFavorite = false,
  });

  // Tạo một bản sao của đối tượng song với các thuộc tính có thể thay đổi
  Song copyWith({
    String? title,
    String? artist,
    String? coverImage,
    String? assetPath,
    String? lyrics,
    String? albumId,
    String? albumName,
    bool? isFavorite,
  }) {
    return Song(
      id: this.id,
      title: title ?? this.title,
      artist: artist ?? this.artist,
      coverImage: coverImage ?? this.coverImage,
      assetPath: assetPath ?? this.assetPath,
      lyrics: lyrics ?? this.lyrics,
      albumId: albumId ?? this.albumId,
      albumName: albumName ?? this.albumName,
      isFavorite: isFavorite ?? this.isFavorite,
    );
  }

  // Chuyển đổi từ Map/JSON
  factory Song.fromMap(Map<String, dynamic> map, String documentId) {
    return Song(
      id: documentId,
      title: map['title'] ?? '',
      artist: map['artist'] ?? '',
      coverImage: map['coverImage'] ?? '',
      assetPath: map['assetPath'] ?? '',
      lyrics: map['lyrics'] ?? '',
      albumId: map['albumId'],
      albumName: map['albumName'],
      isFavorite: map['isFavorite'] ?? false,
    );
  }

  // Chuyển đổi sang Map để lưu vào Firebase
  Map<String, dynamic> toMap() {
    return {
      'title': title,
      'artist': artist,
      'coverImage': coverImage,
      'assetPath': assetPath,
      'lyrics': lyrics,
      'albumId': albumId,
      'albumName': albumName,
      'isFavorite': isFavorite,
    };
  }
}
