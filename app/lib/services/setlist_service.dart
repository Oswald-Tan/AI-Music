import 'dart:convert';
import 'api_service.dart';
import '../config/api_config.dart';
import '../models/setlist.dart';

class SetlistService {
  final ApiService _api = ApiService();

  Future<List<SetlistModel>> getMySetlists() async {
    final response = await _api.get(ApiConfig.setlists);
    if (response.statusCode == 200) {
      final List data = jsonDecode(response.body);
      return data.map((json) => SetlistModel.fromJson(json)).toList();
    }
    return [];
  }

  Future<SetlistModel?> createSetlist(String title) async {
    final response = await _api.post(ApiConfig.setlists, {'title': title});
    if (response.statusCode == 201) {
      final data = jsonDecode(response.body);
      // Backend returns setlist without songs initially
      return SetlistModel(
        id: data['id'],
        title: data['title'],
        songIds: [],
      );
    }
    return null;
  }

  Future<bool> deleteSetlist(String id) async {
    final response = await _api.delete('${ApiConfig.setlists}/$id');
    return response.statusCode == 200;
  }

  Future<bool> addSongToSetlist(String setlistId, String audioJobId) async {
    final response = await _api.post(ApiConfig.setlistSongs, {
      'setlistId': setlistId,
      'audioJobId': audioJobId,
    });
    return response.statusCode == 201;
  }

  Future<bool> removeSongFromSetlist(String setlistId, String songId) async {
    final response = await _api.delete('${ApiConfig.setlists}/$setlistId/songs/$songId');
    return response.statusCode == 200;
  }

  Future<bool> reorderSetlist(String setlistId, List<String> songIds) async {
    final response = await _api.post('${ApiConfig.setlists}/reorder', {
      'setlistId': setlistId,
      'songIds': songIds,
    });
    return response.statusCode == 200;
  }
}
