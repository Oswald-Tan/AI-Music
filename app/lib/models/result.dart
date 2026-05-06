import 'audio_job.dart';

class ResultModel {
  final String id;
  final String jobId;
  final Map<String, dynamic> resultJson;
  final List<String> fileUrls;

  ResultModel({
    required this.id,
    required this.jobId,
    required this.resultJson,
    required this.fileUrls,
  });

  factory ResultModel.fromJson(Map<String, dynamic> json) {
    return ResultModel(
      id: json['id'],
      jobId: json['jobId'],
      resultJson: json['resultJson'] ?? {},
      fileUrls: List<String>.from(json['fileUrls'] ?? []),
    );
  }
}

class FullResultModel {
  final AudioJobModel job;
  final ResultModel result;

  FullResultModel({required this.job, required this.result});

  factory FullResultModel.fromJson(Map<String, dynamic> json) {
    return FullResultModel(
      job: AudioJobModel.fromJson(json['job']),
      result: ResultModel.fromJson(json['result']),
    );
  }
}
