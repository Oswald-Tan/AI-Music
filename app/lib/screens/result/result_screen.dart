import 'dart:async';
import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:just_audio/just_audio.dart';
import '../../providers/audio_provider.dart';
import '../../config/app_colors.dart';
import '../../models/result.dart';

class ResultScreen extends StatefulWidget {
  const ResultScreen({super.key});

  @override
  State<ResultScreen> createState() => _ResultScreenState();
}

class _ResultScreenState extends State<ResultScreen> {
  final AudioPlayer _player = AudioPlayer();
  // Multiple players for stem separation
  final Map<String, AudioPlayer> _stemPlayers = {
    'vocals': AudioPlayer(),
    'drums': AudioPlayer(),
    'bass': AudioPlayer(),
    'other': AudioPlayer(),
  };
  
  final ScrollController _chordScrollController = ScrollController();
  
  double _currentPosition = 0;
  String? _currentUrl;
  int _lastBeatIdx = -1;
  final Map<int, GlobalKey> _beatKeys = {};

  // Controls
  double? _currentBpm;
  double _pitch = 0.0;
  
  // Stem Volumes (0.0 to 1.0)
  final Map<String, double> _stemVolumes = {
    'original': 0.0,
    'vocals': 1.0,
    'drums': 1.0,
    'bass': 1.0,
    'other': 1.0,
  };

  Timer? _positionTimer;
  bool _isDraggingSlider = false;

  @override
  void initState() {
    super.initState();
    
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final String jobId = ModalRoute.of(context)!.settings.arguments as String;
      Provider.of<AudioProvider>(context, listen: false).fetchResult(jobId);
    });

    _positionTimer = Timer.periodic(const Duration(milliseconds: 16), (timer) {
      if (!mounted) return;

      final double pos = _player.position.inMilliseconds / 1000.0;
      
      // Update UI if:
      // 1. Not dragging the slider (to avoid feedback loop jitter)
      // 2. AND (playing OR if we just seeked/pos changed)
      if (!_isDraggingSlider && (_player.playing || pos != _currentPosition)) {
        setState(() {
          _currentPosition = pos;
        });
        
        final provider = Provider.of<AudioProvider>(context, listen: false);
        if (provider.currentResult != null) {
          _scrollToActiveBeat(provider.currentResult!.result.resultJson);
        }
      }
    });
  }

  @override
  void dispose() {
    _positionTimer?.cancel();
    _player.dispose();
    for (var p in _stemPlayers.values) {
      p.dispose();
    }
    _chordScrollController.dispose();
    super.dispose();
  }

  bool _isMixerLoading = false;

  Future<void> _play(String url, Map<String, dynamic>? stems) async {
    final bool hasStems = stems != null && stems.isNotEmpty;
    
    String fullUrl = url;
    if (!url.startsWith('http')) {
      fullUrl = 'http://10.150.164.53:8087/$url';
    }

    try {
      if (_player.playing) {
        await _player.pause();
        for (var p in _stemPlayers.values) {
          await p.pause();
        }
        print("VOXORA DEBUG: All tracks paused");
      } else {
        if (_currentUrl != fullUrl) {
          _currentUrl = fullUrl;
          setState(() => _isMixerLoading = true);
          
          final encodedMainUrl = Uri.encodeFull(fullUrl);
          print("VOXORA DEBUG: Loading Main Track: $encodedMainUrl");
          
          final List<Future> loadTasks = [];
          
          // Main track
          loadTasks.add(_player.setUrl(encodedMainUrl).then((_) {
            print("VOXORA DEBUG: Main Track Ready (Duration: ${_player.duration})");
          }));
          
          // Stems
          if (hasStems) {
            for (var key in _stemPlayers.keys) {
              if (stems.containsKey(key)) {
                String stemUrl = stems[key];
                if (!stemUrl.startsWith('http')) {
                  stemUrl = 'http://10.150.164.53:8087$stemUrl';
                }
                
                final encodedStemUrl = Uri.encodeFull(stemUrl);
                print("VOXORA DEBUG: Queueing Stem [$key]: $encodedStemUrl");
                
                loadTasks.add(
                  _stemPlayers[key]!.setUrl(encodedStemUrl).then((_) {
                    print("VOXORA DEBUG: Stem [$key] Ready");
                  }).catchError((e) {
                    print("VOXORA DEBUG ERROR: Stem [$key] failed: $e");
                  })
                );
              }
            }
          }
          
          await Future.wait(loadTasks);
          
          // Initial volumes
          await _player.setVolume(_stemVolumes['original'] ?? 0.0);
          if (hasStems) {
            for (var key in _stemPlayers.keys) {
              await _stemPlayers[key]!.setVolume(_stemVolumes[key] ?? 1.0);
            }
          }
          
          setState(() => _isMixerLoading = false);
        }
        
        // --- APPLY CURRENT TEMPO & PITCH BEFORE PLAY ---
        final provider = Provider.of<AudioProvider>(context, listen: false);
        final currentResult = provider.currentResult;
        final double resultBpm = (currentResult?.result.resultJson['bpm'] as num?)?.toDouble() ?? 120.0;
        final double speed = (_currentBpm ?? resultBpm) / resultBpm;
        final double pitchFactor = math.pow(2, _pitch / 12).toDouble();
        
        print("VOXORA DEBUG: Applying Speed: $speed, Pitch: $pitchFactor");
        
        await _player.setSpeed(speed);
        await _player.setPitch(pitchFactor);
        
        if (hasStems) {
          for (var p in _stemPlayers.values) {
            if (p.audioSource != null) {
              await p.setSpeed(speed);
              await p.setPitch(pitchFactor);
            }
          }
        }

        // Final check: Sync positions before play
        final currentPos = _player.position;
        print("VOXORA DEBUG: Starting playback from ${currentPos.inSeconds}s at speed $speed");
        
        if (hasStems) {
          // Prepare all play tasks to run simultaneously
          final List<Future> playTasks = [];
          
          for (var entry in _stemPlayers.entries) {
            if (entry.value.audioSource != null) {
               // We seek and then trigger play without awaiting each one individually in the loop
               // This ensures they all start as fast as possible
               entry.value.seek(currentPos);
               playTasks.add(entry.value.play());
            }
          }
          
          // Trigger all stem playbacks and master playback in one go
          playTasks.add(_player.play());
          await Future.wait(playTasks);
        } else {
          await _player.play();
        }
      }
    } catch (e) {
      setState(() => _isMixerLoading = false);
      print("VOXORA PLAY ERROR: $e");
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Audio Error: $e')),
      );
    }
    setState(() {});
  }

  void _scrollToActiveBeat(Map<String, dynamic> resultJson) {
    if (!_chordScrollController.hasClients) return;

    final List flatBeats = [];
    final List bars = resultJson['bars'] ?? [];
    for (var bar in bars) {
      for (var beat in bar) {
        flatBeats.add(beat);
      }
    }

    if (flatBeats.isEmpty) return;

    // Latency compensation for the visual focus
    final double adjustedPos = _currentPosition + 0.05;

    int currentIdx = -1;
    double progressInBeat = 0.0;

    for (int i = 0; i < flatBeats.length; i++) {
      final double time = (flatBeats[i]['time'] as num).toDouble();
      final double nextTime = i < flatBeats.length - 1 
          ? (flatBeats[i + 1]['time'] as num).toDouble() 
          : time + 0.5;

      if (adjustedPos >= time && adjustedPos < nextTime) {
        currentIdx = i;
        // Calculate how far we are through this specific beat (0.0 to 1.0)
        progressInBeat = (adjustedPos - time) / (nextTime - time);
        break;
      }
    }

    if (currentIdx != -1) {
      if (currentIdx != _lastBeatIdx) {
        setState(() => _lastBeatIdx = currentIdx);
      }

      // 88px is the total width (80 width + 4 margin left + 4 margin right)
      const double beatTotalWidth = 88.0;
      final double screenWidth = MediaQuery.of(context).size.width;
      
      // Calculate target offset to center the active part of the chord
      // (Index + Progress) * Width - (Screen Center)
      final double targetOffset = (currentIdx + progressInBeat) * beatTotalWidth - (screenWidth / 2) + (beatTotalWidth / 2);

      // Use jumpTo for continuous, frame-by-frame updates (very smooth at 60fps)
      _chordScrollController.jumpTo(
        targetOffset.clamp(0, _chordScrollController.position.maxScrollExtent),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final String jobId = ModalRoute.of(context)!.settings.arguments as String;
    final audioProvider = Provider.of<AudioProvider>(context);
    final result = audioProvider.currentResult;

    if (result == null || result.job.id != jobId) {
      return const Scaffold(body: Center(child: CircularProgressIndicator()));
    }

    final double originalBpm = (result.result.resultJson['bpm'] as num?)?.toDouble() ?? 120.0;
    if (_currentBpm == null) _currentBpm = originalBpm;

    final stems = result.result.resultJson['stems'] as Map<String, dynamic>?;

    return Scaffold(
      backgroundColor: Colors.black, // Dark theme like the screenshot
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        title: Text(result.job.originalFileName, style: const TextStyle(fontSize: 14, color: Colors.white70)),
        centerTitle: true,
        leading: IconButton(icon: const Icon(Icons.keyboard_arrow_down, color: Colors.white), onPressed: () => Navigator.pop(context)),
        actions: [IconButton(icon: const Icon(Icons.menu, color: Colors.white), onPressed: () {})],
      ),
      body: Column(
        children: [
          // Horizontal Chords
          _buildHorizontalChords(result.result.resultJson),
          
          Expanded(
            child: SingleChildScrollView(
              padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 32),
              child: Column(
                children: [
                  // Mixer Section
                  _buildMixer(stems),
                ],
              ),
            ),
          ),
          
          _buildBottomPlaybackBar(result, audioProvider, stems),
        ],
      ),
    );
  }

  Widget _buildHorizontalChords(Map<String, dynamic> resultJson) {
    final List bars = resultJson['bars'] ?? [];
    final List flatBeats = [];
    for (var bar in bars) {
      for (var beat in bar) {
        flatBeats.add(beat);
      }
    }

    return Container(
      height: 80,
      margin: const EdgeInsets.symmetric(vertical: 8),
      decoration: BoxDecoration(
        color: Colors.grey[900],
        border: Border.symmetric(horizontal: BorderSide(color: Colors.white10)),
      ),
      child: ListView.builder(
        controller: _chordScrollController,
        scrollDirection: Axis.horizontal,
        padding: EdgeInsets.symmetric(horizontal: MediaQuery.of(context).size.width / 2 - 40),
        itemCount: flatBeats.length,
        itemBuilder: (context, index) {
          final beat = flatBeats[index];
          final bool isCurrent = _lastBeatIdx == index;
          
          String chordToShow = "";
          final currentChord = beat['chord'] ?? "";
          
          // Only show chord if it's different from the previous beat
          if (index == 0 || currentChord != flatBeats[index - 1]['chord']) {
            chordToShow = currentChord.isNotEmpty ? _transposeChord(currentChord, _pitch.toInt()) : "";
          }
          
          _beatKeys[index] = GlobalKey();

          return GestureDetector(
            onTap: () async {
              final double targetTime = (beat['time'] as num).toDouble();
              final duration = Duration(milliseconds: (targetTime * 1000).toInt());
              
              // Update state immediately for visual feedback
              setState(() {
                _currentPosition = targetTime;
              });
              
              // Seek master and all stems in parallel
              final List<Future> seekTasks = [_player.seek(duration)];
              for (var p in _stemPlayers.values) {
                if (p.audioSource != null) seekTasks.add(p.seek(duration));
              }
              await Future.wait(seekTasks);
              
              // Force scroll update
              _scrollToActiveBeat(resultJson);
            },
            child: Container(
              key: _beatKeys[index],
              width: 80,
              margin: const EdgeInsets.all(4),
              decoration: BoxDecoration(
                color: isCurrent ? Colors.white : Colors.grey[850],
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: isCurrent ? Colors.white : Colors.white10),
              ),
              alignment: Alignment.center,
              child: Text(
                chordToShow,
                style: TextStyle(
                  color: isCurrent ? Colors.black : Colors.white,
                  fontWeight: FontWeight.bold,
                  fontSize: 20,
                ),
              ),
            ),
          );
        },
      ),
    );
  }

  Widget _buildMixer(Map<String, dynamic>? stems) {
    // If no stems, show placeholder or info
    if (stems == null || stems.isEmpty) {
      return Center(
        child: Container(
          padding: const EdgeInsets.all(24),
          decoration: BoxDecoration(color: Colors.grey[900], borderRadius: BorderRadius.circular(24)),
          child: const Column(
            children: [
              Icon(Icons.auto_awesome, color: AppColors.primary, size: 48),
              SizedBox(height: 16),
              Text('WANT TO SPLIT TRACKS?', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
              SizedBox(height: 8),
              Text('Re-upload this song using the "Separate" tool to control individual track volumes.', 
                   textAlign: TextAlign.center, style: TextStyle(color: Colors.white54, fontSize: 12)),
            ],
          ),
        ),
      );
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Pro-Mixer',
          style: TextStyle(
            color: Colors.white,
            fontSize: 20,
            fontWeight: FontWeight.bold,
          ),
        ),
        if (_isMixerLoading) ...[
          const SizedBox(height: 8),
          Row(
            children: const [
              SizedBox(
                width: 12,
                height: 12,
                child: CircularProgressIndicator(strokeWidth: 2, color: Colors.blueAccent),
              ),
              SizedBox(width: 8),
              Text('Loading tracks...', style: TextStyle(color: Colors.blueAccent, fontSize: 12)),
            ],
          ),
        ],
        const SizedBox(height: 20),
        _mixerRow('original', Icons.music_note_rounded, 'Original'),
        const Divider(color: Colors.white10, height: 32),
        _mixerRow('vocals', Icons.mic_none_rounded, 'Vocals'),
        _mixerRow('drums', Icons.album_rounded, 'Drums'), // Using available icon
        _mixerRow('bass', Icons.music_note_rounded, 'Bass'),
        _mixerRow('other', Icons.music_video_rounded, 'Other'),
      ],
    );
  }

  Widget _mixerRow(String key, IconData icon, String label) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 12),
      child: Row(
        children: [
          Icon(icon, color: Colors.white70, size: 24),
          const SizedBox(width: 16),
          Expanded(
            child: SliderTheme(
              data: SliderTheme.of(context).copyWith(
                trackHeight: 2,
                thumbShape: const RoundSliderThumbShape(enabledThumbRadius: 6),
                activeTrackColor: const Color(0xFF50E3C2),
                inactiveTrackColor: Colors.white10,
                thumbColor: Colors.white,
              ),
              child: Slider(
                value: _stemVolumes[key]!,
                onChanged: (val) {
                  setState(() => _stemVolumes[key] = val);
                  if (key == 'original') {
                    _player.setVolume(val);
                  } else {
                    _stemPlayers[key]?.setVolume(val);
                  }
                },
              ),
            ),
          ),
          IconButton(icon: const Icon(Icons.more_vert, color: Colors.white30), onPressed: () {}),
        ],
      ),
    );
  }

  Widget _buildBottomPlaybackBar(FullResultModel result, AudioProvider provider, Map<String, dynamic>? stems) {
    return Container(
      padding: const EdgeInsets.fromLTRB(20, 12, 20, 32),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          SliderTheme(
            data: SliderTheme.of(context).copyWith(
              trackHeight: 2,
              thumbShape: const RoundSliderThumbShape(enabledThumbRadius: 4),
              activeTrackColor: Colors.white,
              inactiveTrackColor: Colors.white10,
              thumbColor: Colors.white,
            ),
            child: Slider(
              value: _currentPosition.clamp(0, _player.duration?.inSeconds.toDouble() ?? 100),
              max: _player.duration?.inSeconds.toDouble() ?? 100,
              onChangeStart: (val) {
                setState(() => _isDraggingSlider = true);
              },
              onChangeEnd: (val) {
                setState(() => _isDraggingSlider = false);
              },
              onChanged: (val) async {
                final duration = Duration(seconds: val.toInt());
                
                // Update state immediately
                setState(() {
                  _currentPosition = val;
                });

                // Seek master and stems in parallel
                final List<Future> seekTasks = [_player.seek(duration)];
                for (var p in _stemPlayers.values) {
                  if (p.audioSource != null) seekTasks.add(p.seek(duration));
                }
                await Future.wait(seekTasks);
                
                // Force scroll update
                final provider = Provider.of<AudioProvider>(context, listen: false);
                if (provider.currentResult != null) {
                  _scrollToActiveBeat(provider.currentResult!.result.resultJson);
                }
              },
            ),
          ),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(_formatDuration(_player.position), style: const TextStyle(fontSize: 10, color: Colors.white30)),
                Text(_formatDuration(_player.duration ?? Duration.zero), style: const TextStyle(fontSize: 10, color: Colors.white30)),
              ],
            ),
          ),
          const SizedBox(height: 16),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceEvenly,
            children: [
              _controlIconButton(icon: Icons.timer_outlined, onTap: () => _showTempoModal(result, provider)),
              _controlIconButton(icon: Icons.fast_rewind_rounded, onTap: () => _player.seek(Duration(seconds: (_player.position.inSeconds - 10).clamp(0, 999999)))),
              IconButton(
                icon: Icon(_player.playing ? Icons.pause_circle_filled_rounded : Icons.play_circle_fill_rounded, color: Colors.white, size: 72),
                onPressed: () => _play(_currentUrl ?? result.job.filePath, stems),
              ),
              _controlIconButton(icon: Icons.fast_forward_rounded, onTap: () => _player.seek(Duration(seconds: (_player.position.inSeconds + 10).clamp(0, _player.duration?.inSeconds ?? 999999)))),
              _controlIconButton(icon: Icons.music_note_rounded, onTap: () => _showKeyModal(result, provider)),
            ],
          ),
        ],
      ),
    );
  }

  Widget _controlIconButton({required IconData icon, required VoidCallback onTap}) {
    return IconButton(icon: Icon(icon, color: Colors.white, size: 28), onPressed: onTap);
  }

  void _showTempoModal(FullResultModel result, AudioProvider provider) {
    final double originalBpm = (result.result.resultJson['bpm'] as num?)?.toDouble() ?? 120.0;
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.grey[900],
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(32))),
      builder: (context) => StatefulBuilder(builder: (context, setModalState) => Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Text('TEMPO', style: TextStyle(fontWeight: FontWeight.bold, color: Colors.white)),
            const SizedBox(height: 32),
            _buildSliderRowInModal(
              label: 'BPM',
              value: _currentBpm ?? originalBpm,
              min: originalBpm * 0.5,
              max: originalBpm * 1.5,
              displayValue: '${(_currentBpm ?? originalBpm).toInt()} BPM',
              onChanged: (val) {
                setState(() => _currentBpm = val);
                setModalState(() {});
                _player.setSpeed(val / originalBpm);
                for (var p in _stemPlayers.values) {
                  p.setSpeed(val / originalBpm);
                }
              },
              icon: Icons.speed_rounded,
            ),
          ],
        ),
      )),
    );
  }

  void _showKeyModal(FullResultModel result, AudioProvider provider) {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.grey[900],
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(32))),
      builder: (context) => StatefulBuilder(builder: (context, setModalState) => Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Text('KEY', style: TextStyle(fontWeight: FontWeight.bold, color: Colors.white)),
            const SizedBox(height: 32),
            _buildSliderRowInModal(
              label: 'PITCH',
              value: _pitch,
              min: -12,
              max: 12,
              divisions: 24,
              displayValue: _transposeChord(result.result.resultJson['key'] ?? 'C', _pitch.toInt()),
              onChanged: (val) {
                setState(() {
                  _pitch = val;
                  _player.setPitch(math.pow(2, val / 12).toDouble());
                  for (var p in _stemPlayers.values) {
                    p.setPitch(math.pow(2, val / 12).toDouble());
                  }
                });
                setModalState(() {});
              },
              icon: Icons.height_rounded,
            ),
          ],
        ),
      )),
    );
  }

  Widget _buildSliderRowInModal({required String label, required double value, required double min, required double max, required String displayValue, required ValueChanged<double> onChanged, required IconData icon, int? divisions}) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(label, style: const TextStyle(color: Colors.white54)),
            Text(displayValue, style: const TextStyle(fontWeight: FontWeight.bold, color: Colors.white, fontSize: 18)),
          ],
        ),
        const SizedBox(height: 16),
        Row(
          children: [
            _modalStepButton(icon: Icons.remove, onTap: () => onChanged((value - 1).clamp(min, max))),
            Expanded(
              child: Slider(value: value, min: min, max: max, divisions: divisions, activeColor: Colors.white, onChanged: onChanged),
            ),
            _modalStepButton(icon: Icons.add, onTap: () => onChanged((value + 1).clamp(min, max))),
          ],
        ),
      ],
    );
  }

  Widget _modalStepButton({required IconData icon, required VoidCallback onTap}) {
    return IconButton(icon: Icon(icon, color: Colors.white, size: 20), onPressed: onTap);
  }

  String _formatDuration(Duration duration) {
    String twoDigits(int n) => n.toString().padLeft(2, '0');
    final minutes = twoDigits(duration.inMinutes.remainder(60));
    final seconds = twoDigits(duration.inSeconds.remainder(60));
    return "$minutes:$seconds";
  }

  String _transposeChord(String chord, int semitones) {
    if (chord.isEmpty || chord == "•" || chord == "N/A") return chord;
    if (semitones == 0) return chord;
    const notes = ['C', 'C#', 'D', 'D#', 'E', 'F', 'F#', 'G', 'G#', 'A', 'A#', 'B'];
    String root = ""; String suffix = "";
    if (chord.length >= 2 && (chord[1] == '#' || chord[1] == 'b')) { root = chord.substring(0, 2); suffix = chord.substring(2); }
    else { root = chord.substring(0, 1); suffix = chord.substring(1); }
    if (root == 'Db') root = 'C#'; if (root == 'Eb') root = 'D#'; if (root == 'Gb') root = 'F#'; if (root == 'Ab') root = 'G#'; if (root == 'Bb') root = 'A#';
    int index = notes.indexOf(root);
    if (index == -1) return chord;
    int newIndex = (index + semitones) % 12;
    if (newIndex < 0) newIndex += 12;
    return notes[newIndex] + suffix;
  }
}
