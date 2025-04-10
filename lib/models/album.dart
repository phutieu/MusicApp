class Album {
  final String id;
  final String name;
  final String artist;
  final String coverImage;
  final List<String> songIds;

  Album({
    required this.id,
    required this.name,
    required this.artist,
    required this.coverImage,
    required this.songIds,
  });

  // Tạo một bản sao của đối tượng album với các thuộc tính có thể thay đổi
  Album copyWith({
    String? name,
    String? artist,
    String? coverImage,
    List<String>? songIds,
  }) {
    return Album(
      id: this.id,
      name: name ?? this.name,
      artist: artist ?? this.artist,
      coverImage: coverImage ?? this.coverImage,
      songIds: songIds ?? List.from(this.songIds),
    );
  }

  // Chuyển đổi từ Map/JSON
  factory Album.fromMap(Map<String, dynamic> map, String documentId) {
    return Album(
      id: documentId,
      name: map['name'] ?? '',
      artist: map['artist'] ?? '',
      coverImage: map['coverImage'] ?? '',
      songIds: List<String>.from(map['songIds'] ?? []),
    );
  }

  // Chuyển đổi sang Map để lưu vào Firebase
  Map<String, dynamic> toMap() {
    return {
      'name': name,
      'artist': artist,
      'coverImage': coverImage,
      'songIds': songIds,
    };
  }
}
