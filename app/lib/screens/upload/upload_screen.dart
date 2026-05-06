import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:file_picker/file_picker.dart';
import '../../providers/audio_provider.dart';
import '../../providers/setlist_provider.dart';
import '../../models/audio_job.dart';
import '../../config/app_colors.dart';

class UploadScreen extends StatefulWidget {
  const UploadScreen({super.key});

  @override
  State<UploadScreen> createState() => _UploadScreenState();
}

class _UploadScreenState extends State<UploadScreen> {
  PlatformFile? _selectedFile;
  final _promptController = TextEditingController();

  Future<void> _pickFile() async {
    final result = await FilePicker.platform.pickFiles(
      type: FileType.audio,
      allowMultiple: false,
    );

    if (result != null) {
      setState(() {
        _selectedFile = result.files.first;
      });
    }
  }

  Future<void> _startProcess(JobType type, String? setlistId) async {
    if (_selectedFile == null) return;

    final audioProvider = Provider.of<AudioProvider>(context, listen: false);
    final jobId = await audioProvider.uploadAndStart(
      _selectedFile!.path!,
      type,
      prompt: type == JobType.beat ? _promptController.text : null,
    );

    if (jobId != null && mounted) {
      if (setlistId != null) {
        final setlistProvider = Provider.of<SetlistProvider>(context, listen: false);
        await setlistProvider.addSongToSetlist(setlistId, jobId);
      }
      Navigator.pop(context);
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text('Processing started!')));
    }
  }

  @override
  Widget build(BuildContext context) {
    final args = ModalRoute.of(context)!.settings.arguments as Map<String, dynamic>?;
    final JobType jobType = args?['type'] ?? JobType.analyze;
    final String? setlistId = args?['setlistId'];
    final audioProvider = Provider.of<AudioProvider>(context);

    return Scaffold(
      appBar: AppBar(
        title: const Text(
          'ADD NEW SONG',
          style: TextStyle(fontWeight: FontWeight.w900, letterSpacing: 2),
        ),
        centerTitle: true,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Upload Audio File',
              style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 8),
            const Text(
              'Select an MP3 or WAV file to add to your library and analyze for practice.',
              style: TextStyle(color: AppColors.textSecondary),
            ),
            const SizedBox(height: 32),

            // Upload Area
            InkWell(
              onTap: _pickFile,
              borderRadius: BorderRadius.circular(24),
              child: Container(
                width: double.infinity,
                padding: const EdgeInsets.symmetric(
                  vertical: 60,
                  horizontal: 20,
                ),
                decoration: BoxDecoration(
                  color: AppColors.surface,
                  borderRadius: BorderRadius.circular(24),
                  border: Border.all(
                    color: _selectedFile != null
                        ? AppColors.primary
                        : AppColors.border,
                    width: 2,
                  ),
                ),
                child: Column(
                  children: [
                    Icon(
                      _selectedFile != null
                          ? Icons.audio_file_rounded
                          : Icons.cloud_upload_outlined,
                      size: 64,
                      color: _selectedFile != null
                          ? AppColors.primary
                          : AppColors.textMuted,
                    ),
                    const SizedBox(height: 16),
                    Text(
                      _selectedFile != null
                          ? _selectedFile!.name
                          : 'Tap to select audio file',
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        color: _selectedFile != null
                            ? AppColors.textPrimary
                            : AppColors.textSecondary,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ],
                ),
              ),
            ),

            if (jobType == JobType.beat) ...[
              const SizedBox(height: 32),
              const Text(
                'Prompt (Describe the beat)',
                style: TextStyle(fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 8),
              TextField(
                controller: _promptController,
                decoration: const InputDecoration(
                  hintText: 'e.g. Lo-fi hip hop beat with jazz piano',
                ),
              ),
            ],
            const SizedBox(height: 100), // Space for bottom button
          ],
        ),
      ),
      bottomNavigationBar: _buildBottomButton(audioProvider, jobType, setlistId),
    );
  }

  Widget _buildBottomButton(AudioProvider provider, JobType type, String? setlistId) {
    final bool canProcess = _selectedFile != null && !provider.isLoading;

    return Padding(
      padding: const EdgeInsets.fromLTRB(24, 0, 24, 24),
      child: ElevatedButton(
        style: ElevatedButton.styleFrom(
          padding: const EdgeInsets.symmetric(vertical: 18),
          backgroundColor: AppColors.primary,
          disabledBackgroundColor: AppColors.primary.withOpacity(0.3),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
          ),
        ),
        onPressed: canProcess ? () => _startProcess(type, setlistId) : null,
        child: provider.isLoading
            ? const SizedBox(
                height: 20,
                width: 20,
                child: CircularProgressIndicator(
                  color: Colors.white,
                  strokeWidth: 2,
                ),
              )
            : const Text(
                'Start Processing',
                style: TextStyle(fontWeight: FontWeight.bold),
              ),
      ),
    );
  }
}
