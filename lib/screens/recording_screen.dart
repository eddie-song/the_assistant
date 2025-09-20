import 'dart:io';
import 'package:flutter/material.dart';
import 'package:record/record.dart';
import 'package:path_provider/path_provider.dart';
import 'package:path/path.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'package:the_assistant/providers/events_provider.dart';

class RecordingControls extends StatefulWidget {
  const RecordingControls({super.key});

  @override
  State<RecordingControls> createState() => _RecordingControlsState();
}

class _RecordingControlsState extends State<RecordingControls> {
  final record = Record();
  bool isRecording = false;
  String transcript = '';
  String commandResponse = '';
  final EventsProvider _eventsProvider = EventsProvider();

  Future<void> startRecording() async {
    if (await record.hasPermission()) {
      final dir = await getTemporaryDirectory();
      final path = join(dir.path, 'input.wav');
      await record.start(
        path: path,
        encoder: AudioEncoder.wav,
        bitRate: 128000,
        samplingRate: 16000,
      );
      setState(() => isRecording = true);
    }
  }

  Future<void> stopAndSend() async {
    final path = await record.stop();
    setState(() => isRecording = false);

    if (path != null) {
        final file = File(path);

        // Wait until file is fully written (simple retry loop)
        int retry = 0;
        while (!await file.exists() && retry < 10) {
        await Future.delayed(const Duration(milliseconds: 100));
        retry++;
        }

        // Optional: wait an extra bit for larger files
        await Future.delayed(const Duration(milliseconds: 200));

        // Send to server
        final result = await sendToVosk(file);
        setState(() => transcript = result);
        
        // Send to command parser
        if (result.isNotEmpty) {
          final commandResult = await parseCommand(result);
          setState(() => commandResponse = commandResult);
        }
    }
  }

  Future<String> sendToVosk(File audioFile) async {
    final uri = Uri.parse('http://10.172.168.30:5001/transcribe');
    var request = http.MultipartRequest('POST', uri);
    request.files.add(await http.MultipartFile.fromPath('audio', audioFile.path));
    var response = await request.send();
    return await response.stream.bytesToString();
  }

  Future<String> parseCommand(String command) async {
    try {
      final uri = Uri.parse('http://localhost:5000/parse');
      final response = await http.post(
        uri,
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({'command': command}),
      );

      if (response.statusCode == 200) {
        final result = jsonDecode(response.body);

        // Process the action
        switch (result['action']) {
          case 'create_event':
            await _eventsProvider.createEvent(
              title: result['title'],
              date: result['date'],
              time: result['time'],
            );
            break;

          case 'delete_event':
            await _eventsProvider.deleteEvent(
              title: result['title'],
              date: result['date'],
              time: result['time'],
            );
            break;

          case 'get_schedule':
            await _eventsProvider.getSchedule(result['date']);
            break;

          case 'clear_schedule':
            await _eventsProvider.clearSchedule(result['date']);
            break;

          case 'create_reminder':
            // TODO: Implement reminder functionality
            break;

          case 'unknown':
            // No action needed, just show the error message
            break;
        }

        return result['response'] ?? 'No response received';
      } else {
        return 'Error processing command: ${response.statusCode}';
      }
    } catch (e) {
      return 'Error: $e';
    }
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Container(
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.2),
                spreadRadius: 2,
                blurRadius: 8,
                offset: const Offset(0, 2),
              ),
            ],
          ),
          child: Material(
            color: isRecording ? Colors.red : Theme.of(context).colorScheme.primary,
            shape: const CircleBorder(),
            child: InkWell(
              customBorder: const CircleBorder(),
              onTap: isRecording ? stopAndSend : startRecording,
              child: Container(
                width: 56,
                height: 56,
                padding: const EdgeInsets.all(16),
                child: Icon(
                  isRecording ? Icons.stop : Icons.mic,
                  color: Colors.white,
                  size: 24,
                ),
              ),
            ),
          ),
        ),
        const SizedBox(height: 10),
        // if (transcript.isNotEmpty)
        //   Text(
        //     'Transcript:\n$transcript',
        //     style: const TextStyle(fontSize: 14),
        //   ),
        // if (commandResponse.isNotEmpty)
        //   Padding(
        //     padding: const EdgeInsets.only(top: 8.0),
        //     child: Text(
        //       'Response:\n$commandResponse',
        //       style: const TextStyle(fontSize: 14, fontWeight: FontWeight.bold),
        //     ),
        //   ),
      ],
    );
  }
}
