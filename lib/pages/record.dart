import 'dart:io';

import 'package:flutter/material.dart';
import 'package:coin_app/design/colors.dart';
import 'package:coin_app/design/dimensions.dart';
import 'package:coin_app/design/widgets/accent_button.dart';
import 'package:coin_app/pages/result.dart';

import 'package:record/record.dart';
import 'package:audioplayers/audioplayers.dart';
import 'package:path_provider/path_provider.dart';
import 'package:path/path.dart' as p;
import 'package:http/http.dart' as http;

class RecordPage extends StatelessWidget {
  RecordPage({super.key});
  // ignore: library_private_types_in_public_api
  final GlobalKey<_RecordState> recordStateKey = GlobalKey<_RecordState>();

  Future<String> uploadAudioFile(String filePath) async {
    File audioFile = File(filePath);
    List<int> audioBytes = await audioFile.readAsBytes();

    var client = http.Client();

    var domain =
        'https://ds02.wim.uni-koeln.de/coin-audio/classify'; //'http://172.28.12.123:5000/classify';
    var url = Uri.parse(domain);

    try {
      var response = await client.post(
        url,
        headers: {'Content-Type': 'application/octet-stream'},
        body: audioBytes,
      );
      print(response);
      if (response.statusCode == 200) {
        print('Audio file uploaded successfully!');
      } else {
        print(
            'Failed to upload audio file. Status code: ${response.statusCode}');
      }
      return response.body;
    } catch (e) {
      print('Error uploading audio file: $e');
    } finally {
      client.close();
    }
    return "Error";
  }

  @override
  Widget build(BuildContext context) {
    return Stack(children: <Widget>[
      _first(),
      Align(alignment: Alignment.bottomCenter, child: _sendButton(context))
    ]);
  }

  Widget _first() {
    return Scaffold(
      body: RecordWidget(
        key: recordStateKey,
        title: 'Make an audio-clip of your cat',
      ),
    );
  }

  Widget _sendButton(context) {
    return SafeArea(
      child: Padding(
        padding: const EdgeInsets.only(
          left: padding16,
          right: padding16,
          bottom: padding8,
        ),
        child: AccentButton(
          title: 'Send',
          onTap: () async {
            _RecordState? recordState = recordStateKey.currentState;
            if (recordState != null) {
              // Access state and perform actions
              final audioPath = recordState.getAudioPath();
              final String predictedClass = await uploadAudioFile(audioPath);
              print(predictedClass);

              Navigator.push(
                context,
                MaterialPageRoute(
                    builder: (context) => ResultPage(result: predictedClass)),
              );
            }
          },
        ),
      ),
    );
  }
}

class RecordWidget extends StatefulWidget {
  const RecordWidget({super.key, required this.title});

  final String title;

  @override
  State<RecordWidget> createState() => _RecordState();
}

class _RecordState extends State<RecordWidget> {
  late AudioRecorder audioRecord;
  late AudioPlayer audioPlayer;
  bool isRecording = false;
  String audioPath = '';

  String getAudioPath() {
    return audioPath;
  }

  @override
  void initState() {
    audioPlayer = AudioPlayer();
    audioRecord = AudioRecorder();
    super.initState();
  }

  @override
  void dispose() {
    audioRecord.dispose();
    audioPlayer.dispose();
    super.dispose();
  }

  Future<void> startRecording() async {
    try {
      if (await audioRecord.hasPermission()) {
        const config = RecordConfig(encoder: AudioEncoder.wav, numChannels: 1);
        await audioRecord.start(config, path: await _getPath());
        setState(() {
          isRecording = true;
        });
      }
    } catch (e) {
      print('Error Start Recording : $e');
    }
  }

  Future<void> stopRecording() async {
    try {
      String? path = await audioRecord.stop();
      setState(() {
        isRecording = false;
        audioPath = path!;
      });
    } catch (e) {
      print('Error Stopping record: $e');
    }
  }

  Future<void> playRecording() async {
    try {
      Source urlSource = UrlSource(audioPath);
      await audioPlayer.play(urlSource);
    } catch (e) {
      print('Error playing Recording : $e');
    }
  }

  Future<String> _getPath() async {
    final dir = await getApplicationDocumentsDirectory();
    return p.join(
      dir.path,
      'audio_${DateTime.now().millisecondsSinceEpoch}.wav',
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        backgroundColor: primaryColor,
        leading: Icon(Icons.pets, color: Colors.white),
      ),
      body: Column(
        children: [
          const SizedBox(
            height: 100,
          ),
          const Center(
            child: Text(
              'Make an Audio-Clip of your Cat',
              textAlign: TextAlign.center,
              style: TextStyle(
                color: secondaryTextColor,
                fontSize: fontSize35,
                fontWeight: FontWeight.w500,
                fontFamily: AutofillHints.familyName,
              ),
            ),
          ),
          const SizedBox(
            height: 110,
          ),
          Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: <Widget>[
                if (isRecording)
                  const Text(
                    'Recording in Progress',
                    style: TextStyle(
                      fontSize: 20,
                      color: primaryColor,
                      fontWeight: FontWeight.w500,
                      fontFamily: AutofillHints.familyName,
                    ),
                  ),
                const SizedBox(
                  height: 20,
                ),
                ElevatedButton(
                  onPressed: isRecording ? stopRecording : startRecording,
                  child: Icon(isRecording ? Icons.stop : Icons.mic, size: 40),
                ),
                const SizedBox(
                  height: 50,
                ),
                if (!isRecording && audioPath != '')
                  ElevatedButton(
                      onPressed: playRecording,
                      child: const Icon(Icons.play_arrow_rounded, size: 40)),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
