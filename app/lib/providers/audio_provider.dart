import 'dart:async';
import 'package:flutter/material.dart';
import '../services/audio_service.dart';
import '../models/audio_job.dart';
import '../models/result.dart';

class AudioProvider with ChangeNotifier {
  final AudioService _audioService = AudioService();
  
  List<AudioJobModel> _jobs = [];
  bool _isLoading = false;
  FullResultModel? _currentResult;
  Timer? _pollingTimer;

  List<AudioJobModel> get jobs => _jobs;
  bool get isLoading => _isLoading;
  FullResultModel? get currentResult => _currentResult;

  AudioProvider() {
    _startPolling();
  }

  void _startPolling() {
    _pollingTimer?.cancel();
    _pollingTimer = Timer.periodic(const Duration(seconds: 2), (timer) {
      final hasActiveJobs = _jobs.any((job) => 
        job.status == JobStatus.processing || job.status == JobStatus.pending
      );
      
      if (hasActiveJobs) {
        fetchMyJobs(silent: true);
      }
    });
  }

  @override
  void dispose() {
    _pollingTimer?.cancel();
    super.dispose();
  }

  void setLoading(bool value) {
    _isLoading = value;
    notifyListeners();
  }

  Future<void> fetchMyJobs({bool silent = false}) async {
    if (!silent) setLoading(true);
    _jobs = await _audioService.getMyJobs();
    if (!silent) setLoading(false);
    notifyListeners();
  }

  Future<String?> uploadAndStart(String filePath, JobType type, {String? prompt, String? modelId}) async {
    setLoading(true);
    final jobId = await _audioService.uploadAudio(filePath, type);
    if (jobId != null) {
      final success = await _audioService.startProcessing(jobId, type, prompt: prompt, modelId: modelId);
      if (success) {
        await fetchMyJobs();
        setLoading(false);
        return jobId;
      }
    }
    setLoading(false);
    return null;
  }

  Future<String?> reuseFileAndStart(String originalJobId, JobType type, {String? prompt, String? modelId}) async {
    setLoading(true);
    final jobId = await _audioService.reuseFile(originalJobId, type);
    if (jobId != null) {
      final success = await _audioService.startProcessing(jobId, type, prompt: prompt, modelId: modelId);
      if (success) {
        await fetchMyJobs();
        setLoading(false);
        return jobId;
      }
    }
    setLoading(false);
    return null;
  }

  Future<void> fetchResult(String jobId) async {
    setLoading(true);
    _currentResult = await _audioService.getResult(jobId);
    setLoading(false);
  }

  Future<String?> processAudio(String originalJobId, double tempo, double pitch) async {
    setLoading(true);
    final jobId = await _audioService.reuseFile(originalJobId, JobType.process);
    if (jobId != null) {
      final success = await _audioService.startProcessing(jobId, JobType.process, tempo: tempo, pitch: pitch);
      if (success) {
        await fetchMyJobs();
        setLoading(false);
        return jobId;
      }
    }
    setLoading(false);
    return null;
  }

  Future<AudioJobModel?> getJobStatus(String jobId) async {
    return await _audioService.getJobStatus(jobId);
  }

  Future<bool> deleteJob(String jobId) async {
    setLoading(true);
    final success = await _audioService.deleteJob(jobId);
    if (success) {
      _jobs.removeWhere((job) => job.id == jobId);
      notifyListeners();
    }
    setLoading(false);
    return success;
  }
}
