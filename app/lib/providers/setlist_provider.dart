import 'package:flutter/material.dart';
import '../models/setlist.dart';
import '../services/setlist_service.dart';

class SetlistProvider with ChangeNotifier {
  final SetlistService _setlistService = SetlistService();
  List<SetlistModel> _setlists = [];
  bool _isLoading = false;

  List<SetlistModel> get setlists => _setlists;
  bool get isLoading => _isLoading;

  SetlistProvider() {
    loadSetlists();
  }

  Future<void> loadSetlists() async {
    _isLoading = true;
    notifyListeners();

    _setlists = await _setlistService.getMySetlists();

    _isLoading = false;
    notifyListeners();
  }

  Future<void> addSetlist(String title) async {
    final newSetlist = await _setlistService.createSetlist(title);
    if (newSetlist != null) {
      _setlists.add(newSetlist);
      notifyListeners();
    }
  }

  Future<void> addSongToSetlist(String setlistId, String songId) async {
    final success = await _setlistService.addSongToSetlist(setlistId, songId);
    if (success) {
      final index = _setlists.indexWhere((s) => s.id == setlistId);
      if (index != -1) {
        if (!_setlists[index].songIds.contains(songId)) {
          _setlists[index].songIds.add(songId);
          notifyListeners();
        }
      }
    }
  }

  Future<void> removeSongFromSetlist(String setlistId, String songId) async {
    final success = await _setlistService.removeSongFromSetlist(setlistId, songId);
    if (success) {
      final index = _setlists.indexWhere((s) => s.id == setlistId);
      if (index != -1) {
        _setlists[index].songIds.remove(songId);
        notifyListeners();
      }
    }
  }

  Future<void> deleteSetlist(String id) async {
    final success = await _setlistService.deleteSetlist(id);
    if (success) {
      _setlists.removeWhere((s) => s.id == id);
      notifyListeners();
    }
  }

  Future<void> reorderSongs(String setlistId, int oldIndex, int newIndex) async {
    final setlistIndex = _setlists.indexWhere((s) => s.id == setlistId);
    if (setlistIndex == -1) return;

    if (newIndex > oldIndex) {
      newIndex -= 1;
    }

    final List<String> songIds = List.from(_setlists[setlistIndex].songIds);
    final String movedId = songIds.removeAt(oldIndex);
    songIds.insert(newIndex, movedId);

    // Optimistic update
    _setlists[setlistIndex].songIds.clear();
    _setlists[setlistIndex].songIds.addAll(songIds);
    notifyListeners();

    // Sync with backend
    final success = await _setlistService.reorderSetlist(setlistId, songIds);
    if (!success) {
      // Rollback if failed
      await loadSetlists();
    }
  }
}
