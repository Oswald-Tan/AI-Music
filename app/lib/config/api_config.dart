class ApiConfig {
  // Use localhost for emulator or actual IP for real device
  // 10.0.2.2 is usually localhost for Android Emulator
  static const String baseUrl = "http://10.150.164.53:8087/api";

  // Endpoints
  static const String login = "/auth/login";
  static const String register = "/auth/register";
  static const String profile = "/auth/profile";

  static const String upload = "/upload";
  static const String processSeparate = "/process/separate";
  static const String processChord = "/process/chord";
  static const String processBeat = "/process/beat";
  static const String processVoice = "/process/voice";
  static const String processAnalyze = "/process/analyze";
  static const String processAudio = "/process/audio";

  static const String jobs = "/jobs";
  static const String jobsReuse = "/jobs/reuse";
  static const String result = "/result";
  
  static const String setlists = "/setlists";
  static const String setlistSongs = "/setlists/songs";
}
