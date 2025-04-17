import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_tts/flutter_tts.dart';
import 'package:google_generative_ai/google_generative_ai.dart';
import 'package:speech_to_text/speech_to_text.dart';

class FakeCallScreen extends StatefulWidget {
  final String name;
  final String phone;
  const FakeCallScreen({super.key, required this.name, required this.phone});

  @override
  State<FakeCallScreen> createState() => _FakeCallScreenState();
}

class _FakeCallScreenState extends State<FakeCallScreen> {
  Timer? _timer;

  bool _muted = false;
  bool _speaker = false;
  int _counter = 0;
  static const _apiKey = 'AIzaSyC9nl8DAX5dxW4HxNeg-o390g3W38UxRhc';
  late final GenerativeModel _model;
  SpeechToText speech = SpeechToText();
  bool terminateNow = false;
  FlutterTts tts = FlutterTts();
  String sta = "done";
  String conversationHistory = "";

  void startTimer() {
    _timer = Timer.periodic(const Duration(seconds: 1), (timer) {
      setState(() {
        _counter++;
      });
    });
  }

  Future<void> _startListening() async {
    if (terminateNow == true) {
      speech.stop();
      tts.stop();
      terminateNow=false;
      return;
    }

    tts.getVoices.then((data){
      List<Map> voices = List<Map>.from(data);
      voices = voices.where((voice)=>voice["locale"].contains("en-IN")).toList();
      print(voices);
    });

    bool isReady = await speech.initialize(
          onError: (error) {
          _startListening();
        }
        );
    if (isReady) {
      print("started listening");
      speech.listen(
        listenFor: const Duration(seconds: 5),
        onResult: (result) {
          print(result.recognizedWords);
          if (result.finalResult) {
            // speech.stop();
            print("result final block");
            String text = result.recognizedWords;
            print('Recognized text: $text');
            // Fluttertoast.showToast(msg: "$text");
            
            sendToGemini(text);
            sta = "doing";
          }
          // if (!speech.isListening || sta == "done") {
          //   _startListening();
          // }
        },
      );
    }
  }

  Future<void> sendToGemini(String text) async {
    speech.stop();
    conversationHistory = conversationHistory + "Woman : $text";
    String prompt = """You are a master of conversation to a women in danger. 
        Whenever a girl will feel unsafe and she will give you input you have to act like you both know each other so that others can assume you as her friend. 
        Ask her casual questions about her safety when needed and respond accordingly. 
        Give accurate reponses and dont give any explanations for your response. 
        Dont use emojis. 
        The conversation history has been like this:
        $conversationHistory
        Only give your response after this conversation and dont rewrite the conversation.
        """;
    var content = [Content.text(prompt)];
    final response = await _model.generateContent(content);
    print(response.text);
    // Fluttertoast.showToast(msg: response.text!);
    Map<String,String> voice = {"name": "en-in-x-ene-network", "locale": "en-IN"};
    tts.setVoice(voice);
    await tts.speak(response.text!);
    conversationHistory = conversationHistory + "\nYou: ${response.text}";
    await tts.awaitSpeakCompletion(true);
    // Flowery flowery = const Flowery();
    // final audio = await flowery.tts(text: response.text!, voice: 'Anna');
    // final file = File('audio.mp3')..writeAsBytesSync(audio);
    // final player = AudioPlayer();
    // player.play(AssetSource(file.absolute.path));
    // if (completed == 1) {
    //   print("tts actually completed");
    // }
    print("tts completed");
    // Fluttertoast.showToast(msg: conversationHistory);
    _startListening();
    // testFunction();
  }

  Future<void> testFunction() async {
    if (terminateNow == true) {
      tts.stop();
      return;
    }
    String text = "Hey Mom! Hows it going";
    // Fluttertoast.showToast(msg: text);
    // String prompt =
    //     "you are a master of conversation to a women in danger. whenever a girl will feel unsafe and she will give you input you have to act like you both know each other so that others can assume you as her friend.ask her casual questions about her safety when needed and respond accordingly. Give accurate reponses and dont give any explanations for your response. Dont use emojis. The text starts now: $text";
    // var content = [Content.text(prompt)];
    // final response = await _model.generateContent(content);
    // print(response.text);
    // Fluttertoast.showToast(msg: response.text!);
    // FlutterTts tts = FlutterTts();
    // await tts.speak(response.text!);
    // // print(ttsState.toString());
    // // tts.awaitSpeakCompletion(true);
    // testFunction();
    sendToGemini(text);
  }

  @override
  void initState() {
    _model = GenerativeModel(
      model: 'gemini-1.5-flash',
      apiKey: _apiKey,
    );
    super.initState();

    testFunction();
    // _startListening();

    startTimer();
  }

  @override
  void dispose() {
    super.dispose();
    _timer?.cancel();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Center(
        child: Column(
          children: [
            const SizedBox(height: 100),
            Text(
              'On Call ${widget.name}',
              style: const TextStyle(fontSize: 20),
            ),
            const SizedBox(height: 16),
            Text(
              'Phone: ${widget.phone}',
              style: const TextStyle(fontSize: 15),
            ),
            const SizedBox(height: 16),
            Text(
              (_counter % 60 < 10)
                  ? (_counter ~/ 60 < 10)
                      ? 'Duration: 0${_counter ~/ 60}:0${_counter % 60}'
                      : 'Duration: ${_counter ~/ 60}:0${_counter % 60}'
                  : (_counter ~/ 60 >= 10)
                      ? 'Duration: ${_counter ~/ 60}:${_counter % 60}'
                      : 'Duration: 0${_counter ~/ 60}:${_counter % 60}',
              style: const TextStyle(fontSize: 15),
            ),
            Expanded(
              child: Align(
                  alignment: Alignment.bottomCenter,
                  child: Container(
                    padding: const EdgeInsets.all(20),
                    color: Colors.black87,
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                      children: [
                        CircleAvatar(
                          radius: 25,
                          backgroundColor: Colors.grey.shade400,
                          child: IconButton(
                            onPressed: () {
                              setState(() {
                                _muted = !_muted;
                                _startListening();
                              });
                            },
                            icon: Icon(_muted ? Icons.mic_off : Icons.mic),
                          ),
                        ),
                        CircleAvatar(
                            radius: 30,
                            backgroundColor: Colors.red.shade700,
                            child: IconButton(
                              onPressed: () {
                                speech.stop();
                                terminateNow = true;
                                tts.stop();
                                Navigator.pop(context);
                              },
                              icon: const Icon(Icons.call_end),
                            )),
                        CircleAvatar(
                          radius: 25,
                          backgroundColor: Colors.grey.shade400,
                          child: IconButton(
                            onPressed: () {
                              setState(() {
                                _speaker = !_speaker;
                              });
                            },
                            icon: Icon(
                                _speaker ? Icons.volume_up : Icons.volume_off),
                          ),
                        ),
                      ],
                    ),
                  )),
            )
          ],
        ),
      ),
    );
  }
}
