import 'dart:convert';

class SetlistModel {
  final String id;
  final String title;
  final List<String> songIds; // IDs of AudioJobModel

  SetlistModel({
    required this.id,
    required this.title,
    required this.songIds,
  });

  Map<String, dynamic> toJson() => {
        'id': id,
        'title': title,
        'songIds': songIds,
      };

  factory SetlistModel.fromJson(Map<String, dynamic> json) {
    return SetlistModel(
      id: json['id'],
      title: json['title'],
      songIds: List<String>.from(json['songIds']),
    );
  }
}
