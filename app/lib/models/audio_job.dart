enum JobStatus { pending, processing, done, failed }
enum JobType { separate, chord, beat, voice, analyze, process }

class AudioJobModel {
  final String id;
  final String userId;
  final String originalFileName;
  final String filePath;
  final JobType type;
  final JobStatus status;
  final int progress;
  final String? statusMessage;
  final DateTime createdAt;

  AudioJobModel({
    required this.id,
    required this.userId,
    required this.originalFileName,
    required this.filePath,
    required this.type,
    required this.status,
    required this.progress,
    this.statusMessage,
    required this.createdAt,
  });

  factory AudioJobModel.fromJson(Map<String, dynamic> json) {
    return AudioJobModel(
      id: json['id'],
      userId: json['userId'],
      originalFileName: json['originalFileName'],
      filePath: json['filePath'],
      type: _parseJobType(json['type']),
      status: _parseJobStatus(json['status']),
      progress: json['progress'] ?? 0,
      statusMessage: json['statusMessage'],
      createdAt: DateTime.parse(json['createdAt']),
    );
  }

  static JobType _parseJobType(String type) {
    switch (type) {
      case 'separate': return JobType.separate;
      case 'chord': return JobType.chord;
      case 'beat': return JobType.beat;
      case 'voice': return JobType.voice;
      case 'analyze': return JobType.analyze;
      case 'process': return JobType.process;
      default: return JobType.separate;
    }
  }

  static JobStatus _parseJobStatus(String status) {
    switch (status) {
      case 'pending': return JobStatus.pending;
      case 'processing': return JobStatus.processing;
      case 'done': return JobStatus.done;
      case 'failed': return JobStatus.failed;
      default: return JobStatus.pending;
    }
  }
}
