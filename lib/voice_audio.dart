import 'dart:io';
import 'package:record/record.dart';
import 'package:http/http.dart' as http;
import 'package:path_provider/path_provider.dart';
import 'package:path/path.dart';

final record = Record();

Future<void> startRecording() async {
  if (await record.hasPermission()) {
    final dir = await getTemporaryDirectory();
    final path = join(dir.path, 'input.wav');
    await record.start(path: path, encoder: AudioEncoder.wav);
    print('Recording started...');
  }
}

Future<void> stopAndSend() async {
  final path = await record.stop();
  print('Recording stopped: $path');
  if (path != null) {
    await sendToVosk(File(path));
  }
}

Future<void> sendToVosk(File file) async {
  var uri = Uri.parse('http://<YOUR-IP>:5000/transcribe'); // Replace with LAN IP
  var request = http.MultipartRequest('POST', uri);
  request.files.add(await http.MultipartFile.fromPath('audio', file.path));
  var response = await request.send();
  var responseText = await response.stream.bytesToString();
  print("Transcript: $responseText");
}
