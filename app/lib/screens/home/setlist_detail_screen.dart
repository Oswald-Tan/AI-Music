import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../providers/setlist_provider.dart';
import '../../providers/audio_provider.dart';
import '../../models/setlist.dart';
import '../../models/audio_job.dart';
import '../../config/app_colors.dart';

class SetlistDetailScreen extends StatelessWidget {
  const SetlistDetailScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final setlistId = ModalRoute.of(context)!.settings.arguments as String;
    final setlistProvider = Provider.of<SetlistProvider>(context);
    final audioProvider = Provider.of<AudioProvider>(context);

    final setlist = setlistProvider.setlists.firstWhere((s) => s.id == setlistId);
    final songs = audioProvider.jobs.where((job) => setlist.songIds.contains(job.id)).toList();

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        title: Text(
          setlist.title,
          style: const TextStyle(fontWeight: FontWeight.bold),
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.delete_outline_rounded, color: AppColors.error),
            onPressed: () => _showDeleteSetlistConfirm(context, setlistProvider, setlist),
          ),
        ],
      ),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.all(24),
            child: _buildAddSongButton(context, setlistProvider, setlistId),
          ),
          Expanded(
            child: songs.isEmpty
                ? _buildEmptyState()
                : ReorderableListView.builder(
                    itemCount: songs.length,
                    onReorder: (oldIndex, newIndex) {
                      setlistProvider.reorderSongs(setlistId, oldIndex, newIndex);
                    },
                    itemBuilder: (context, index) {
                      final song = songs[index];
                      return _buildSongTile(context, song, setlistProvider, setlistId, index);
                    },
                  ),
          ),
        ],
      ),
    );
  }

  Widget _buildAddSongButton(BuildContext context, SetlistProvider provider, String setlistId) {
    return InkWell(
      onTap: () => _showAddSongOptions(context, provider, setlistId),
      borderRadius: BorderRadius.circular(16),
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 20),
        decoration: BoxDecoration(
          color: AppColors.surface,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: AppColors.primary.withOpacity(0.3)),
        ),
        child: const Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.add_rounded, color: AppColors.primary),
            SizedBox(width: 12),
            Text(
              'ADD A SONG',
              style: TextStyle(
                color: AppColors.primary,
                fontWeight: FontWeight.bold,
                letterSpacing: 1.2,
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _showAddSongOptions(BuildContext context, SetlistProvider provider, String setlistId) {
    showModalBottomSheet(
      context: context,
      backgroundColor: AppColors.surface,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (context) => Container(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Text(
              'Add Song to Setlist',
              style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 24),
            ListTile(
              leading: Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: AppColors.primary.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: const Icon(Icons.library_music_rounded, color: AppColors.primary),
              ),
              title: const Text('From My Library'),
              subtitle: const Text('Choose from your existing songs'),
              onTap: () {
                Navigator.pop(context);
                _showLibraryPicker(context, provider, setlistId);
              },
            ),
            const Divider(color: AppColors.border),
            ListTile(
              leading: Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: AppColors.secondary.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: const Icon(Icons.cloud_upload_rounded, color: AppColors.secondary),
              ),
              title: const Text('Upload New Song'),
              subtitle: const Text('Process a new audio file'),
              onTap: () {
                Navigator.pop(context);
                Navigator.pushNamed(context, '/upload', arguments: {
                  'type': JobType.analyze,
                  'setlistId': setlistId,
                });
              },
            ),
            const SizedBox(height: 24),
          ],
        ),
      ),
    );
  }

  void _showLibraryPicker(BuildContext context, SetlistProvider provider, String setlistId) {
    final audioProvider = Provider.of<AudioProvider>(context, listen: false);
    final setlist = provider.setlists.firstWhere((s) => s.id == setlistId);
    final availableSongs = audioProvider.jobs
        .where((job) => job.status == JobStatus.done && !setlist.songIds.contains(job.id))
        .toList();

    showModalBottomSheet(
      context: context,
      backgroundColor: AppColors.background,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (context) => DraggableScrollableSheet(
        initialChildSize: 0.7,
        maxChildSize: 0.9,
        minChildSize: 0.5,
        expand: false,
        builder: (context, scrollController) => Column(
          children: [
            const SizedBox(height: 12),
            Container(
              width: 40,
              height: 4,
              decoration: BoxDecoration(
                color: AppColors.border,
                borderRadius: BorderRadius.circular(2),
              ),
            ),
            const Padding(
              padding: EdgeInsets.all(24),
              child: Text(
                'Select Song',
                style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
              ),
            ),
            Expanded(
              child: availableSongs.isEmpty
                  ? const Center(child: Text('No songs in library'))
                  : ListView.builder(
                      controller: scrollController,
                      itemCount: availableSongs.length,
                      itemBuilder: (context, index) {
                        final song = availableSongs[index];
                        return ListTile(
                          leading: const Icon(Icons.music_note_rounded, color: AppColors.primary),
                          title: Text(song.originalFileName),
                          subtitle: Text(song.type.name.toUpperCase()),
                          onTap: () {
                            provider.addSongToSetlist(setlistId, song.id);
                            Navigator.pop(context);
                          },
                        );
                      },
                    ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSongTile(BuildContext context, AudioJobModel job, SetlistProvider provider, String setlistId, int index) {
    return Dismissible(
      key: ValueKey('dismiss_${job.id}'),
      direction: DismissDirection.endToStart,
      background: Container(
        alignment: Alignment.centerRight,
        padding: const EdgeInsets.only(right: 24),
        color: AppColors.error.withOpacity(0.8),
        child: const Icon(Icons.delete_outline_rounded, color: Colors.white),
      ),
      onDismissed: (direction) {
        provider.removeSongFromSetlist(setlistId, job.id);
      },
      child: Theme(
        data: Theme.of(context).copyWith(
          splashColor: Colors.transparent,
          highlightColor: Colors.transparent,
        ),
        child: ListTile(
          key: ValueKey(job.id),
          contentPadding: const EdgeInsets.symmetric(horizontal: 24, vertical: 8),
          leading: Container(
            width: 48,
            height: 48,
            decoration: BoxDecoration(
              color: AppColors.primary.withOpacity(0.1),
              borderRadius: BorderRadius.circular(12),
            ),
            child: const Icon(Icons.music_note_rounded, color: AppColors.primary),
          ),
          title: Text(
            job.originalFileName,
            style: const TextStyle(fontWeight: FontWeight.bold),
          ),
          subtitle: Text(
            job.type.name.toUpperCase(),
            style: const TextStyle(fontSize: 12, color: AppColors.textMuted),
          ),
          onTap: () => Navigator.pushNamed(context, '/result', arguments: job.id),
        ),
      ),
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.playlist_add_rounded, size: 64, color: AppColors.textMuted.withOpacity(0.3)),
          const SizedBox(height: 16),
          const Text(
            'No songs in this setlist',
            style: TextStyle(color: AppColors.textMuted),
          ),
        ],
      ),
    );
  }

  void _showDeleteSetlistConfirm(BuildContext context, SetlistProvider provider, SetlistModel setlist) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: AppColors.surface,
        title: const Text('Delete Setlist?'),
        content: Text('Are you sure you want to delete "${setlist.title}"?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () {
              provider.deleteSetlist(setlist.id);
              Navigator.pop(context); // Close dialog
              Navigator.pop(context); // Go back to home
            },
            child: const Text('Delete', style: TextStyle(color: AppColors.error)),
          ),
        ],
      ),
    );
  }
}
