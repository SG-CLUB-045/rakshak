import 'package:flutter/material.dart';
import 'dart:async';

import 'package:rakshak/screens/calls/fake_call.dart';


class OutgoingCallScreen extends StatefulWidget {
  final String name;
  final String phone;
  final bool isfake;

  const OutgoingCallScreen(
      {super.key,
      required this.name,
      required this.phone,
      required this.isfake});

  @override
  State<OutgoingCallScreen> createState() => _OutgoingCallScreenState();
}

class _OutgoingCallScreenState extends State<OutgoingCallScreen> {
  bool _muted = false;
  bool _speaker = false;

  void fakeCall() async {
    debugPrint('fake call');
    Future.delayed(const Duration(seconds: 4), () {
      debugPrint('fake call done');
      Navigator.pushReplacement(
          context,
          MaterialPageRoute(
              builder: (context) => FakeCallScreen(
                    name: widget.name,
                    phone: widget.phone,
                  )));
    });
  }

  @override
  void initState() {
    super.initState();
    if (widget.isfake) {
      fakeCall();
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Center(
        child: Column(
          children: [
            const SizedBox(height: 100),
            Text(
              'Calling ${widget.name}',
              style: const TextStyle(fontSize: 20),
            ),
            const SizedBox(height: 16),
            Text(
              'Phone: ${widget.phone}',
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
