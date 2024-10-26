// ignore_for_file: avoid_print

import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:speech_to_text/speech_to_text.dart' as stt;
import 'package:flutter_tts/flutter_tts.dart';
import 'package:string_similarity/string_similarity.dart';
import 'dart:async';

class Voice extends StatefulWidget {
  final String collectionName;

  const Voice({super.key, required this.collectionName});

  @override
  _VoiceState createState() => _VoiceState();
}

class _VoiceState extends State<Voice> {
  late stt.SpeechToText _speech;
  late FlutterTts _flutterTts;
  bool _isListening = false;
  String _text = "Press the button and start speaking";
  final List<Map<String, String>> _messages = [
    {"type": "response", "text": "Hi, I am Niha"} // Initial default response
  ];
  User? user;
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  late StreamSubscription<QuerySnapshot> _responseSubscription;
  final TextEditingController _textController = TextEditingController();
  List<String> commands = [];

  @override
  void initState() {
    super.initState();
    _initializeSpeechAndTTS();
    user = _auth.currentUser;
    _fetchCommandsFromFirestore();
    _listenForResponses();
    _speak("Hi, I am Niha"); // Speak the initial command
  }

  Future<void> _initializeSpeechAndTTS() async {
    _speech = stt.SpeechToText();
    _flutterTts = FlutterTts();
    await _flutterTts.setLanguage("en-US");
    await _flutterTts.setPitch(1.0);
  }

  Future<void> _fetchCommandsFromFirestore() async {
    try {
      DocumentSnapshot snapshot =
          await _firestore.collection('commands').doc('commandsList').get();
      setState(() {
        commands = List<String>.from(snapshot['commands']);
      });
    } catch (e) {
      print("Error fetching commands: $e");
    }
  }

  void _listen() async {
    if (!_isListening) {
      bool available = await _speech.initialize(
        onStatus: (val) => print('onStatus: $val'),
        onError: (val) => print('onError: $val'),
      );
      if (available) {
        setState(() => _isListening = true);
        _speech.listen(
          onResult: (val) => setState(() {
            _text = val.recognizedWords;
            if (val.hasConfidenceRating && val.confidence > 0) {
              _sendCommandToFirestore(_text);
              _messages.add({"type": "user", "text": _text});
            }
          }),
        );
      }
    } else {
      setState(() => _isListening = false);
      _speech.stop();
    }
  }

  String correctWord(String inputWord, List<String> wordList) {
    String normalizedInput = inputWord.toLowerCase().trim();

    var matches = wordList.map((word) {
      String normalizedWord = word.toLowerCase().trim();
      var similarity = normalizedInput.similarityTo(normalizedWord);
      return {'word': word, 'similarity': similarity};
    }).toList();

    matches.sort((a, b) =>
        (b['similarity'] as double).compareTo(a['similarity'] as double));

    if (matches.isNotEmpty && (matches.first['similarity'] as double) > 0.6) {
      return matches.first['word'] as String;
    } else {
      return inputWord; // Return the original word if no close match found
    }
  }

  String correctCommand(String inputCommand, List<String> commandList) {
    List<String> inputWords = inputCommand.split(' ');
    List<String> correctedWords =
        inputWords.map((word) => correctWord(word, commandList)).toList();
    return correctedWords.join(' ');
  }

  void _sendCommandToFirestore(String command) {
    String correctedCommand = correctCommand(command, commands);
    if (correctedCommand == "No close match found") {
      print("Command not recognized: $command");
      return;
    }

    if (user != null) {
      _firestore.collection(widget.collectionName).add({
        'command': correctedCommand,
        'userId': user!.uid,
        'timestamp': FieldValue.serverTimestamp(),
      });
    } else {
      print("User not authenticated");
    }
  }

  void _listenForResponses() {
    if (user == null) return;

    _responseSubscription = _firestore
        .collection('responses')
        .where('userId', isEqualTo: user?.uid)
        .snapshots()
        .listen((snapshot) {
      for (var doc in snapshot.docs) {
        String responseText = doc['response'];
        setState(() {
          _messages.add({"type": "response", "text": responseText});
        });
        _speak(responseText);
        doc.reference.delete();
      }
    });
  }

  Future<void> _speak(String text) async {
    await _flutterTts.speak(text);
  }

  void _sendManualCommand() {
    String commandText = _textController.text;
    if (commandText.isNotEmpty) {
      _sendCommandToFirestore(commandText);
      setState(() {
        _messages.add({"type": "user", "text": commandText});
      });
      _textController.clear();
    }
  }

  @override
  void dispose() {
    _responseSubscription.cancel();
    _textController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        flexibleSpace: Container(
          decoration: const BoxDecoration(
            color: Color.fromARGB(255, 15, 94, 205),
          ),
        ),
        title: const Text(
          'Niha',
          style: TextStyle(
            color: Color.fromARGB(255, 255, 255, 255),
            fontSize: 30,
            fontWeight: FontWeight.bold,
            fontFamily: 'Cursive',
          ),
        ),
      ),
      body: Column(
        children: [
          Expanded(
            child: ListView.builder(
              itemCount: _messages.length,
              itemBuilder: (context, index) {
                var message = _messages[index];
                bool isUserMessage = message['type'] == 'user';
                return Container(
                  alignment: isUserMessage
                      ? Alignment.centerRight
                      : Alignment.centerLeft,
                  padding:
                      const EdgeInsets.symmetric(vertical: 10, horizontal: 20),
                  child: Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: isUserMessage
                          ? Colors.black
                          : Color.fromARGB(255, 15, 94, 205),
                      borderRadius: BorderRadius.only(
                        topLeft: Radius.circular(12),
                        topRight: Radius.circular(12),
                        bottomLeft:
                            isUserMessage ? Radius.circular(12) : Radius.zero,
                        bottomRight:
                            isUserMessage ? Radius.zero : Radius.circular(12),
                      ),
                    ),
                    child: Text(
                      message['text']!,
                      style: const TextStyle(
                        fontSize: 16,
                        color: Colors.white,
                      ),
                    ),
                  ),
                );
              },
            ),
          ),
          Padding(
            padding: const EdgeInsets.all(8.0),
            child: Row(
              children: [
                FloatingActionButton(
                  onPressed: _listen,
                  backgroundColor: const Color.fromARGB(
                      255, 15, 94, 205), // Mic button color
                  shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(30.0)),
                  child: Icon(
                    _isListening ? Icons.mic : Icons.mic_none,
                    color: const Color.fromARGB(255, 255, 255, 255),
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: TextField(
                    controller: _textController,
                    decoration: InputDecoration(
                      hintText: 'Type your command here',
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(30),
                        borderSide: BorderSide.none,
                      ),
                      fillColor: Colors.grey[200],
                      filled: true,
                    ),
                  ),
                ),
                const SizedBox(width: 6),
                IconButton(
                  icon: const Icon(
                    Icons.send,
                    color: Color.fromARGB(255, 15, 94, 205),
                  ),
                  onPressed: _sendManualCommand,
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
