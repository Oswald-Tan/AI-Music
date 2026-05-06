import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../providers/auth_provider.dart';
import '../../providers/audio_provider.dart';
import '../../config/app_colors.dart';
import '../../models/audio_job.dart';
import '../../models/setlist.dart';
import '../../providers/setlist_provider.dart';
import 'dart:ui';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  int _currentIndex = 0;

  @override
  void initState() {
    super.initState();
    // Fetch songs on start
    WidgetsBinding.instance.addPostFrameCallback((_) {
      Provider.of<AudioProvider>(context, listen: false).fetchMyJobs();
    });
  }

  @override
  Widget build(BuildContext context) {
    final authProvider = Provider.of<AuthProvider>(context);
    final audioProvider = Provider.of<AudioProvider>(context);

    return Scaffold(
      backgroundColor: AppColors.background,
      body: SafeArea(
        child: IndexedStack(
          index: _currentIndex,
          children: [
            _buildSongsView(audioProvider),
            _buildSetlistView(audioProvider),
            _buildProfileView(authProvider),
          ],
        ),
      ),
      bottomNavigationBar: _buildBottomBar(),
    );
  }

  Widget _buildBottomBar() {
    return Container(
      decoration: BoxDecoration(
        color: AppColors.surface,
        border: Border(top: BorderSide(color: AppColors.border, width: 0.5)),
      ),
      child: BottomNavigationBar(
        currentIndex: _currentIndex,
        onTap: (index) => setState(() => _currentIndex = index),
        backgroundColor: AppColors.surface,
        selectedItemColor: AppColors.primary,
        unselectedItemColor: AppColors.textMuted,
        showSelectedLabels: true,
        showUnselectedLabels: true,
        type: BottomNavigationBarType.fixed,
        items: const [
          BottomNavigationBarItem(
            icon: Icon(Icons.music_note_rounded),
            label: 'Songs',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.playlist_play_rounded),
            label: 'Setlist',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.person_rounded),
            label: 'Profile',
          ),
        ],
      ),
    );
  }

  // --- SONGS VIEW ---
  Widget _buildSongsView(AudioProvider provider) {
    final songs = provider.jobs
        .where(
          (j) =>
              j.status == JobStatus.done ||
              j.status == JobStatus.processing ||
              j.status == JobStatus.pending,
        )
        .toList();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                'My Library',
                style: TextStyle(
                  fontSize: 28,
                  fontWeight: FontWeight.w900,
                  letterSpacing: -0.5,
                ),
              ),
              const SizedBox(height: 24),
              _buildAddSongButton(),
            ],
          ),
        ),
        Expanded(
          child: RefreshIndicator(
            onRefresh: () => provider.fetchMyJobs(),
            child: songs.isEmpty
                ? _buildEmptyState(
                    'No songs yet',
                    'Upload your first track to start practicing.',
                  )
                : ListView.builder(
                    padding: const EdgeInsets.symmetric(horizontal: 0),
                    itemCount: songs.length,
                    itemBuilder: (context, index) =>
                        _buildSongTile(songs[index]),
                  ),
          ),
        ),
      ],
    );
  }

  Widget _buildAddSongButton() {
    return InkWell(
      onTap: () => Navigator.pushNamed(context, '/upload', arguments: {'type': JobType.analyze}),
      borderRadius: BorderRadius.circular(16),
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 20),
        decoration: BoxDecoration(
          gradient: LinearGradient(
            colors: [AppColors.primary, AppColors.primary.withOpacity(0.8)],
          ),
          borderRadius: BorderRadius.circular(16),
          boxShadow: [
            BoxShadow(
              color: AppColors.primary.withOpacity(0.3),
              blurRadius: 10,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: const Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.add_circle_outline_rounded, color: Colors.white),
            SizedBox(width: 12),
            Text(
              'ADD NEW SONG',
              style: TextStyle(
                color: Colors.white,
                fontWeight: FontWeight.bold,
                letterSpacing: 1.2,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSongTile(AudioJobModel job) {
    final bool isProcessing =
        job.status == JobStatus.processing || job.status == JobStatus.pending;

    return Opacity(
      opacity: isProcessing ? 0.7 : 1.0,
      child: Column(
        children: [
          ListTile(
            contentPadding: const EdgeInsets.symmetric(
              horizontal: 24,
              vertical: 0,
            ),
            leading: Container(
              width: 48,
              height: 48,
              decoration: BoxDecoration(
                color: (isProcessing ? Colors.grey : AppColors.primary)
                    .withOpacity(0.1),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Icon(
                isProcessing
                    ? Icons.hourglass_top_rounded
                    : Icons.music_note_rounded,
                color: isProcessing ? Colors.grey : AppColors.primary,
              ),
            ),
            title: Text(
              job.originalFileName,
              style: const TextStyle(fontWeight: FontWeight.bold),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
            subtitle: Text(
              isProcessing
                  ? (job.statusMessage != null 
                      ? '${job.statusMessage!.toUpperCase()} (${job.progress}%)'
                      : 'PROCESSING AI (${job.progress}%)')
                  : job.type.name.toUpperCase(),
              style: TextStyle(
                fontSize: 10,
                letterSpacing: 1,
                color: isProcessing ? AppColors.primary : AppColors.textMuted,
                fontWeight: isProcessing ? FontWeight.bold : FontWeight.normal,
              ),
            ),
            trailing: isProcessing
                ? const SizedBox(
                    width: 24,
                    height: 24,
                    child: CircularProgressIndicator(strokeWidth: 2),
                  )
                : PopupMenuButton<String>(
                    icon: const Icon(
                      Icons.more_vert_rounded,
                      color: AppColors.textMuted,
                    ),
                    onSelected: (value) {
                      if (value == 'delete') {
                        _showDeleteConfirm(context, job);
                      }
                    },
                    itemBuilder: (context) => [
                      const PopupMenuItem(
                        value: 'delete',
                        child: Row(
                          children: [
                            Icon(Icons.delete_outline_rounded, color: Colors.red, size: 20),
                            SizedBox(width: 8),
                            Text('Delete', style: TextStyle(color: Colors.red)),
                          ],
                        ),
                      ),
                    ],
                  ),
            onTap: isProcessing
                ? null
                : () => Navigator.pushNamed(
                    context,
                    '/result',
                    arguments: job.id,
                  ),
          ),
          if (isProcessing)
            ClipRRect(
              borderRadius: const BorderRadius.only(
                bottomLeft: Radius.circular(16),
                bottomRight: Radius.circular(16),
              ),
              child: LinearProgressIndicator(
                value: job.progress / 100,
                backgroundColor: Colors.transparent,
                color: AppColors.primary,
                minHeight: 4,
              ),
            ),
        ],
      ),
    );
  }

  // --- SETLIST VIEW ---
  Widget _buildSetlistView(AudioProvider audioProvider) {
    final setlistProvider = Provider.of<SetlistProvider>(context);
    final setlists = setlistProvider.setlists;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.all(24),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text(
                'Setlists',
                style: TextStyle(
                  fontSize: 28,
                  fontWeight: FontWeight.w900,
                  letterSpacing: -0.5,
                ),
              ),
              IconButton(
                icon: const Icon(
                  Icons.add_box_rounded,
                  color: AppColors.primary,
                  size: 32,
                ),
                onPressed: () => _showCreateSetlistDialog(context, setlistProvider),
              ),
            ],
          ),
        ),
        Expanded(
          child: RefreshIndicator(
            onRefresh: () => setlistProvider.loadSetlists(),
            child: setlists.isEmpty
                ? ListView(
                    children: [
                      const SizedBox(height: 100),
                      _buildEmptyState(
                        'No Setlists',
                        'Create your first setlist to organize your practice sessions.',
                      ),
                    ],
                  )
                : ListView.builder(
                    padding: const EdgeInsets.symmetric(horizontal: 24),
                    itemCount: setlists.length,
                    itemBuilder: (context, index) {
                      final setlist = setlists[index];
                      return _buildSetlistTile(setlist);
                    },
                  ),
          ),
        ),
      ],
    );
  }

  Widget _buildSetlistTile(SetlistModel setlist) {
    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.border, width: 0.5),
      ),
      child: Theme(
        data: Theme.of(context).copyWith(
          splashColor: Colors.transparent,
          highlightColor: Colors.transparent,
        ),
        child: ListTile(
          contentPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
          leading: Container(
            width: 48,
            height: 48,
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: [AppColors.primary.withOpacity(0.2), AppColors.secondary.withOpacity(0.2)],
              ),
              borderRadius: BorderRadius.circular(12),
            ),
            child: const Icon(Icons.playlist_play_rounded, color: AppColors.primary),
          ),
          title: Text(
            setlist.title,
            style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 18),
          ),
          subtitle: Text(
            '${setlist.songIds.length} songs',
            style: const TextStyle(color: AppColors.textMuted),
          ),
          trailing: const Icon(Icons.chevron_right_rounded, color: AppColors.textMuted),
          onTap: () => Navigator.pushNamed(
            context,
            '/setlist-detail',
            arguments: setlist.id,
          ),
        ),
      ),
    );
  }

  void _showCreateSetlistDialog(BuildContext context, SetlistProvider provider) {
    final controller = TextEditingController();
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: AppColors.surface,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: const Text('New Setlist'),
        content: TextField(
          controller: controller,
          autofocus: true,
          decoration: const InputDecoration(
            hintText: 'Enter setlist title',
            focusedBorder: UnderlineInputBorder(borderSide: BorderSide(color: AppColors.primary)),
          ),
          onSubmitted: (value) {
            if (value.isNotEmpty) {
              provider.addSetlist(value);
              Navigator.pop(context);
            }
          },
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel', style: TextStyle(color: AppColors.textMuted)),
          ),
          TextButton(
            onPressed: () {
              if (controller.text.isNotEmpty) {
                provider.addSetlist(controller.text);
                Navigator.pop(context);
              }
            },
            child: const Text('Create', style: TextStyle(fontWeight: FontWeight.bold, color: AppColors.primary)),
          ),
        ],
      ),
    );
  }

  // --- PROFILE VIEW ---
  Widget _buildProfileView(AuthProvider auth) {
    final name = auth.user?.name ?? "Musician";
    final initial = name.isNotEmpty ? name[0].toUpperCase() : "M";

    return Padding(
      padding: const EdgeInsets.all(24),
      child: Column(
        children: [
          const SizedBox(height: 40),
          Center(
            child: Container(
              width: 100,
              height: 100,
              decoration: BoxDecoration(
                gradient: const LinearGradient(
                  colors: [AppColors.primary, AppColors.secondary],
                ),
                shape: BoxShape.circle,
                boxShadow: [
                  BoxShadow(
                    color: AppColors.primary.withOpacity(0.3),
                    blurRadius: 20,
                  ),
                ],
              ),
              child: Center(
                child: Text(
                  initial,
                  style: const TextStyle(
                    fontSize: 40,
                    fontWeight: FontWeight.bold,
                    color: Colors.white,
                  ),
                ),
              ),
            ),
          ),
          const SizedBox(height: 24),
          Text(
            name,
            style: const TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
          ),
          Text(
            auth.user?.email ?? "",
            style: const TextStyle(color: AppColors.textMuted),
          ),
          const SizedBox(height: 40),
          const Divider(color: AppColors.border),
          const SizedBox(height: 20),
          ListTile(
            leading: const Icon(Icons.logout_rounded, color: AppColors.error),
            title: const Text(
              'Logout',
              style: TextStyle(
                color: AppColors.error,
                fontWeight: FontWeight.bold,
              ),
            ),
            onTap: () async {
              await auth.logout();
              if (mounted) {
                Navigator.pushNamedAndRemoveUntil(context, '/login', (route) => false);
              }
            },
          ),
        ],
      ),
    );
  }

  void _showDeleteConfirm(BuildContext context, AudioJobModel job) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: AppColors.surface,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: const Text('Delete Song?'),
        content: Text(
          'This will permanently delete "${job.originalFileName}" and all its AI results from the server.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text(
              'Cancel',
              style: TextStyle(color: AppColors.textMuted),
            ),
          ),
          TextButton(
            onPressed: () async {
              Navigator.pop(context);
              final provider =
                  Provider.of<AudioProvider>(context, listen: false);
              final success = await provider.deleteJob(job.id);
              if (success) {
                if (mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text('Song deleted successfully')),
                  );
                }
              } else {
                if (mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text('Failed to delete song')),
                  );
                }
              }
            },
            child: const Text(
              'Delete',
              style: TextStyle(color: Colors.red, fontWeight: FontWeight.bold),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildEmptyState(String title, String message) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.library_music_outlined,
            size: 80,
            color: AppColors.textMuted.withOpacity(0.2),
          ),
          const SizedBox(height: 16),
          Text(
            title,
            style: const TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
              color: AppColors.textSecondary,
            ),
          ),
          const SizedBox(height: 8),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 40),
            child: Text(
              message,
              textAlign: TextAlign.center,
              style: const TextStyle(color: AppColors.textMuted),
            ),
          ),
        ],
      ),
    );
  }
}
