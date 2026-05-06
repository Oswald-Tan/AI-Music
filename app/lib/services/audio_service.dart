import 'dart:convert';
import 'package:http/http.dart' as http;
import 'api_service.dart';
import '../config/api_config.dart';
import '../models/audio_job.dart';
import '../models/result.dart';

class AudioService {
  final ApiService _api = ApiService();

  Future<String?> uploadAudio(String filePath, JobType type) async {
    final response = await _api.multipartPost(
      ApiConfig.upload,
      filePath,
      {'type': type.name},
    );

    if (response.statusCode == 201) {
      final respStr = await response.stream.bytesToString();
      final data = jsonDecode(respStr);
      return data['jobId'];
    }
    return null;
  }

  Future<String?> reuseFile(String originalJobId, JobType type) async {
    final response = await _api.post(
      ApiConfig.jobsReuse,
      {
        'originalJobId': originalJobId,
        'type': type.name,
      },
    );

    if (response.statusCode == 201) {
      final data = jsonDecode(response.body);
      return data['jobId'];
    }
    return null;
  }

  Future<bool> startProcessing(String jobId, JobType type, {String? prompt, String? modelId, double? tempo, double? pitch}) async {
    String endpoint;
    switch (type) {
      case JobType.separate: endpoint = ApiConfig.processSeparate; break;
      case JobType.chord: endpoint = ApiConfig.processChord; break;
      case JobType.beat: endpoint = ApiConfig.processBeat; break;
      case JobType.voice: endpoint = ApiConfig.processVoice; break;
      case JobType.analyze: endpoint = ApiConfig.processAnalyze; break;
      case JobType.process: endpoint = ApiConfig.processAudio; break;
    }

    final response = await _api.post(endpoint, {
      'jobId': jobId,
      if (prompt != null) 'prompt': prompt,
      if (modelId != null) 'modelId': modelId,
      if (tempo != null) 'tempo': tempo,
      if (pitch != null) 'pitch': pitch,
    });

    return response.statusCode == 200;
  }

  Future<List<AudioJobModel>> getMyJobs() async {
    final response = await _api.get(ApiConfig.jobs);
    if (response.statusCode == 200) {
      final List data = jsonDecode(response.body);
      return data.map((json) => AudioJobModel.fromJson(json)).toList();
    }
    return [];
  }

  Future<AudioJobModel?> getJobStatus(String jobId) async {
    final response = await _api.get('${ApiConfig.jobs}/$jobId');
    if (response.statusCode == 200) {
      return AudioJobModel.fromJson(jsonDecode(response.body));
    }
    return null;
  }

  Future<FullResultModel?> getResult(String jobId) async {
    final response = await _api.get('${ApiConfig.result}/$jobId');
    if (response.statusCode == 200) {
      return FullResultModel.fromJson(jsonDecode(response.body));
    }
    return null;
  }

  Future<bool> deleteJob(String jobId) async {
    final response = await _api.delete('${ApiConfig.jobs}/$jobId');
    return response.statusCode == 200;
  }
}
