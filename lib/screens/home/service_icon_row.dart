import 'dart:async';
import 'dart:convert';
import 'dart:io';
import 'dart:math';

import 'package:audioplayers/audioplayers.dart';

import 'package:sms_sender_background/sms_sender.dart';
import 'package:camera/camera.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:dotted_border/dotted_border.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:flutter_tts/flutter_tts.dart';
import 'package:fluttertoast/fluttertoast.dart';
import 'package:geoflutterfire_plus/geoflutterfire_plus.dart';
import 'package:geolocator/geolocator.dart';
import 'package:google_generative_ai/google_generative_ai.dart';
import 'package:lottie/lottie.dart';
import 'package:mailer/mailer.dart';
import 'package:mailer/smtp_server/gmail.dart';
import 'package:path_provider/path_provider.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:rakshak/screens/calls/calling.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:speech_to_text/speech_to_text.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:vibration/vibration.dart';
import 'package:video_player/video_player.dart';
import 'shield_container.dart';


class IconRow extends StatefulWidget {
  final cameras;
  final controller;
  final sms_sender;
  final videoController;
  final bool isConnected;
  const IconRow({
    super.key,
    this.cameras,
    this.controller,
    this.sms_sender,
    this.videoController,
    required this.isConnected,
  });

  @override
  State<IconRow> createState() => _IconRowState();
}

class _IconRowState extends State<IconRow> {
  // final stt.SpeechToText _speech = stt.SpeechToText();

  String sta = "done";
  String out = "0";
  int threat = 0;
  late String filePath = "";
  int isfallen = 0;
  bool canShowAppPrompt = true;
  bool isRunning = false;
  late Timer cooldowntimer;
  bool onchange = false;
  late Timer timer;
  late double latitude;
  late double longitude;
  late String userName;
  bool langLoad = false;
  String lang = "";
  Color shieldContainerColor = Colors.pink.shade400;
  Color shieldColor = Colors.pink.shade900;
  bool isActivated = false;
  List contacts = [];
  int _counter = 0;
  bool _muted = false;
  bool _speaker = false;
  Timer? _timer;
  int duration = 0;
  int originalDuration = 0;
  int count = 0;
  int checkupCallStatusRed = 0;
  int checkupCallStatusYellow = 0;
  int checkupCallStatusGreen = 0;
  int checkupCallpickedStatus = 0;
  int checkupCallUnpickedStatus = 0;
  bool unpickHandled = false;
  AudioPlayer player = AudioPlayer();
  int checkupCallScreenPickedStatus = 0;
  bool checkUpCallEnabled = false;
  bool checkupFeatureEnabled=false;

  @override
  void initState() {
    // TODO: implement initState
    super.initState();
  }

  _getPermission() {
    return Permission.sms.request();
  }

  Future<bool> _isPermissionGranted() {
    return Permission.sms.status.isGranted;
  }

  // Future<bool?> get _supportCustomSim {
  //   return BackgroundSms.isSupportCustomSim;
  // }


  Future<GeoPoint> fetchUserLocation() async {
    Position position = await Geolocator.getCurrentPosition(
        desiredAccuracy: LocationAccuracy.best);
    return GeoPoint(position.latitude, position.longitude);
  }

  add_threat_data() async {
    final _userId = await FirebaseAuth.instance.currentUser!.uid;
    final _dbref = FirebaseFirestore.instance.collection('userData');
    DocumentSnapshot document = await _dbref.doc(_userId).get();
    final map = document.data() as Map;
    debugPrint(map.toString());
    GeoPoint userLoc = await fetchUserLocation();
    FirebaseFirestore.instance.collection('sos_generation').doc().set({
      "email": map["email"],
      "Name": map["fname"] + " " + map["lname"],
      "phone": map["phno"],
      "position": userLoc,
      "time": DateTime.now(),
    });
    print("updated sos");
  }

  Future<void> _startRecording() async {
    if (!widget.controller.value.isInitialized) {
      return;
    }

    final Directory appDirectory = await getApplicationDocumentsDirectory();
    final String videoDirectory = '${appDirectory.path}/Videos';
    await Directory(videoDirectory).create(recursive: true);

    final String currentTime = DateTime.now().millisecondsSinceEpoch.toString();
    filePath = '$videoDirectory/$currentTime.mp4';

    try {
      await widget.controller.startVideoRecording();
      cooldowntimer = Timer(const Duration(seconds: 10), () {
        _stopRecording(filePath);
      });
    } catch (error) {
      print(error);
    }
  }

  Future<void> _stopRecording(String filePath) async {
    if (!widget.controller.value.isRecordingVideo) {
      return;
    }

    try {
      final newpath = await widget.controller.stopVideoRecording();
      await _sendEmailWithVideo(newpath.path);
    } catch (error) {
      print("e,e,fefefe");
    } finally {
      _startRecording(); // Dispose the camera controller
    }
  }

  Future<void> _sendEmailWithVideo(String filePath) async {
    final smtpServer = gmail('csaiml22209@glbitm.ac.in', 'gitcondimheqgdbs');
    SharedPreferences prefs = await SharedPreferences.getInstance();
    final encodedContacts = prefs.getString('contacts');
    List<String> ccList = [];
    // print(encodedContacts);
    final decodedContacts = jsonDecode(encodedContacts!) as List;
    contacts
        .addAll(decodedContacts.map((c) => ContactData.fromJson(c)).toList());
    Position position = await Geolocator.getCurrentPosition(
        desiredAccuracy: LocationAccuracy.best);
    double lat = position.latitude;
    double lng = position.longitude;
    for (var i = 0; i < contacts.length; i++) {
      print(contacts[i].email);
      ccList.add(contacts[i].email);
    }
    try {
      final _userId = await FirebaseAuth.instance.currentUser!.uid;
      final _dbref = FirebaseFirestore.instance.collection('userData');
      DocumentSnapshot document = await _dbref.doc(_userId).get();
      final map = document.data() as Map;
      String username = map["fname"] + " " + map["lname"];
      final message = Message()
        ..from = const Address('csaiml22209@glbitm.ac.in', 'Team rakshak')
        ..recipients.add('jsatyam045@gmail.com')
        ..subject = 'Video Email'
        ..html =
            "<p>Hey! We identified that rakshak user: $username is in some trouble and needs your help!</p><br><b><a href='https://maps.google.com/?q=$lat,$lng'>View her location on Google Maps.</a></b><br><br>A short video we captured of the incident has been attached below. Please help her out.<br>Regards.<br>Team rakshak";

      if (ccList.isNotEmpty) {
        message.ccRecipients.addAll(ccList);
      }

      final videoFile = File(filePath);
      if (videoFile.existsSync()) {
        message.attachments.add(FileAttachment(videoFile));
      } else {
        print('Video file does not exist: $filePath');
        return;
      }

      try {
        final sendReport = await send(message, smtpServer);
        print("mail sent");
        Fluttertoast.showToast(msg: "EMERGENCY CONTACTS MAILED WITH VIDEO");
        // audioPlayer.play(AssetSource('siren.mp3'));
        // await Future.delayed(const Duration(seconds: 10));
        // audioPlayer.stop();
      } catch (error) {
        print('Error sending email: $error');
      }
    } catch (e) {
      print("ERROR IN SENDING FUNCTION" + e.toString());
    }
  }

  _sendMessage() async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    final encodedContacts = prefs.getString('contacts');

    // print(encodedContacts);
    final decodedContacts = jsonDecode(encodedContacts!) as List;
    contacts
        .addAll(decodedContacts.map((c) => ContactData.fromJson(c)).toList());
    Position position = await Geolocator.getCurrentPosition(
        desiredAccuracy: LocationAccuracy.best);
    double lat = position.latitude;
    double lng = position.longitude;
    for (var i = 0; i < contacts.length; i++) {
      print(contacts[i].phone);
      var result = await SmsSender().sendSms(
          phoneNumber: "+91${contacts[i].phone}",
          message:
              """Need help My Location is https://www.google.com/maps/place/$lat+$lng""",
          simSlot: 1);
      print(
          """Need help My Location is https://www.google.com/maps/place/$lat+$lng""");
      // if (result == SmsStatus.sent) {
      //   print("Sent");
      //   Fluttertoast.showToast(msg: "SOS ALERT SENT TO ${contacts[i].name}");
      // } else {
      //   print("Failed");
      // }
    }
  }

  _sendEmailToCommunity() async {
    //saving data
    Fluttertoast.showToast(msg: "sending mail to community");
    Position position = await Geolocator.getCurrentPosition(
        desiredAccuracy: LocationAccuracy.best);
    double lat = position.latitude;
    double lng = position.longitude;
    GeoPoint victimPos = GeoPoint(lat, lng);
    final GeoFirePoint center = GeoFirePoint(victimPos);
    const double radiusInKm = 5;
    const String field = 'geo';
    final CollectionReference<Map<String, dynamic>> collectionReference =
        FirebaseFirestore.instance.collection('userData');
    GeoPoint geopointFrom(Map<String, dynamic> data) {
      return (data['geo'] as Map<String, dynamic>)['geopoint'] as GeoPoint;
    }

    final Stream<List<DocumentSnapshot<Map<String, dynamic>>>> stream =
        GeoCollectionReference<Map<String, dynamic>>(collectionReference)
            .subscribeWithin(
      center: center,
      radiusInKm: radiusInKm,
      field: field,
      geopointFrom: geopointFrom,
    );

    // GeoFirePoint center = geo.point(latitude: lat, longitude: lng);
    // NearbyUsers nbyu = NearbyUsers(center);
    // var _currentEntries = nbyu.get();

    stream.listen((listOfSnapshots) async {
      for (DocumentSnapshot snapshot in listOfSnapshots) {
        Map map = snapshot.data() as Map;
        String mail = map['email'];
        final smtpServer =
            gmail('csaiml22209@glbitm.ac.in', 'gitcondimheqgdbs');

        final message = Message()
          ..from = const Address('csaiml22209@glbitm.ac.in', 'Team rakshak')
          ..recipients.add(mail)
          ..subject = 'Need Help'
          ..html =
              "<p>Someone near your locality needs your help.</p><br><b><a href='https://maps.google.com/?q=$lat,$lng'>View Location on Google Maps</a></b><br><br>Any help from your side is highly appriciated!<br>Regards,<br>Team rakshak.";
        try {
          final sendReport = await send(message, smtpServer);
          debugPrint('Mail Sent :)');
          Fluttertoast.showToast(msg: "NEARBY USERS HAVE BEEN NOTIFIED");
        } catch (error) {
          print('Error sending email: $error');
        }
      }
    });
  }

  popdata(BuildContext context) async {
    await Future.delayed(const Duration(seconds: 2));
    Navigator.pop(context);
  }

  void _showLottieDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return Dialog(
          child: Container(
            width: 200,
            height: 200,
            padding: const EdgeInsets.all(16.0),
            child: Lottie.asset(
              'assets/check.json',
              width: 150,
              height: 150,
              onLoaded: (p0) {
                popdata(context);
              },
            ),
          ),
        );
      },
    );
  }

  void _VibConfo() async {
    final hasVibrator = await Vibration.hasVibrator();

    if (hasVibrator ?? false) {
      Vibration.vibrate(duration: 2000);
    }
  }

  void startTimer() {
    Timer.periodic(const Duration(seconds: 1), (timer) {
      setState(() {
        _counter++;
      });
    });
  }

  void checkupCall() {
    if(checkupFeatureEnabled==true){
      Fluttertoast.showToast(msg: "Checkup Call has already been enabled for $duration minute(s)");
      return;
    }
    showDialog(
        context: context,
        builder: (BuildContext context) {
          final durationController = TextEditingController();
          return AlertDialog(
            title: Text("Check-up Call"),
            content: SingleChildScrollView(
              child: Column(
                children: [
                  Text(
                      "This feature schedules mock calls on a regular interval provided by you. The call has three buttons:"),
                  SizedBox(
                    height: 12,
                  ),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceAround,
                    children: [
                      Text(
                        "Green",
                        style: TextStyle(
                            color: Colors.green.shade800,
                            fontWeight: FontWeight.w500),
                      ),
                      Text("-"),
                      Text("You feel safe"),
                    ],
                  ),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceAround,
                    children: [
                      Text(
                        "Yellow",
                        style: TextStyle(
                            color: Colors.yellow.shade800,
                            fontWeight: FontWeight.w500),
                      ),
                      Text("-"),
                      Text("You feel uncomfortable"),
                    ],
                  ),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceAround,
                    children: [
                      Text(
                        "Red",
                        style: TextStyle(
                            color: Colors.red.shade800,
                            fontWeight: FontWeight.w500),
                      ),
                      Text("-"),
                      Text("You are unsafe"),
                    ],
                  ),
                  SizedBox(
                    height: 12,
                  ),
                  Text("Respond to each call appropriately."),
                  SizedBox(
                    height: 18,
                  ),
                  TextField(
                    controller: durationController,
                    decoration:
                        const InputDecoration(hintText: 'Duration (minutes)'),
                    keyboardType: TextInputType.number,
                  )
                ],
              ),
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(context),
                child: Text(
                  'Cancel',
                  style: TextStyle(color: Colors.grey.shade700),
                ),
              ),
              TextButton(
                onPressed: () {
                  if (durationController.text.isEmpty) {
                    Fluttertoast.showToast(msg: "Enter the duration");
                  } else if (int.parse(durationController.text) < 1) {
                    Fluttertoast.showToast(msg: "Minimum duration is 1 minute");
                  } else {
                    // print(durationController.text);
                    setState(() {
                      duration = int.parse(durationController.text);
                      originalDuration = duration;
                      checkUpCallEnabled = true;
                      checkupFeatureEnabled=true;
                    });
                    startCheckupCall();
                    Navigator.pop(context);
                  }
                },
                child: Text(
                  'Enable',
                  style: TextStyle(color: Colors.pink.shade400),
                ),
              ),
            ],
          );
        });
  }

  void checkupCallCloser() async {
    await Future.delayed(Duration(seconds: 30));
    if (checkupCallpickedStatus == 0) {
      // call wasnt picked - handle closing, reschedule, sos
      setState(() {
        checkupCallUnpickedStatus++;
      });

      //call wasnt picked more than once, call sos

      //call rescheduled
      startCheckupCall();
      // close call after 30s
      Navigator.pop(context);
    } else {
      // call was picked, dont do anything
      return;
    }
  }

  void checkupCallScreenCloser() async {
    await Future.delayed(Duration(seconds: 30));
    if (checkupCallScreenPickedStatus == 0) {
      setState(() {
        checkupCallUnpickedStatus++;
        print("unpicked status: $checkupCallUnpickedStatus");
      });
      Navigator.pop(context);
      startCheckupCall();
    }
  }

  void unpickStatusHandler() async {
    if (unpickHandled == true) {
      print("unpick already handled, returning");
      return;
    }
    if (checkupCallUnpickedStatus > 1) {
      unpickHandled = true;
      await _getPermission();
      await Geolocator.checkPermission();
      await Geolocator.requestPermission();
      add_threat_data();
      await widget.controller.initialize();
      await _startRecording();
      if (await _isPermissionGranted()) {
        _sendMessage();
        _VibConfo();
      }
      _sendEmailToCommunity();
      print("unpick handling done");
      return;
    } else {
      await Future.delayed(Duration(seconds: 5));
      unpickStatusHandler();
    }
  }

  void startCheckupCall() async {
    if (duration < 1) {
      duration = 1;
    }
    print(duration);
    unpickStatusHandler();
    await Future.delayed(Duration(minutes: duration));
    if (unpickHandled == true) {
      return;
    }
    checkupCallpickedStatus = 0;
    player.play(AssetSource("ringtone.mp3"));
    showDialog(
      context: context,
      builder: (BuildContext context) {
        checkupCallCloser();
        return Container(
          color: Colors.white,
          child: Column(
            children: [
              Container(
                margin: EdgeInsets.all(8),
                child: Center(
                  child: Text("Incoming call"),
                ),
              ),
              Center(
                child: Text(
                  "Bhaiya",
                  style: TextStyle(fontSize: 20),
                ),
              ),
              Center(
                child: Text(
                  "Mobile +918299210972",
                  style: TextStyle(fontSize: 14),
                ),
              ),
              Spacer(),
              Container(
                margin: EdgeInsets.all(16),
                child: Center(
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceAround,
                    children: [
                      ElevatedButton(
                        onPressed: () {
                          setState(() {
                            checkupCallpickedStatus = 1;
                            checkupCallUnpickedStatus++;
                          });
                          Navigator.pop(context);
                          player.stop();
                          startCheckupCall();
                        },
                        child: Icon(
                          Icons.call,
                          color: Colors.red.shade700,
                        ),
                      ),
                      ElevatedButton(
                        onPressed: () {
                          setState(() {
                            checkupCallpickedStatus = 1;
                          });
                          player.stop();
                          Navigator.pop(context);
                          player.play(AssetSource("checkupcall.mp3"));
                          checkupCallScreenCloser();
                          showDialog(
                            context: context,
                            builder: (BuildContext context) {
                              return Scaffold(
                                body: Center(
                                  child: Column(
                                    children: [
                                      const SizedBox(height: 100),
                                      Text(
                                        'On Call Bhaiya',
                                        style: const TextStyle(fontSize: 20),
                                      ),
                                      const SizedBox(height: 16),
                                      Text(
                                        'Phone: +918299210972',
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
                                              mainAxisAlignment:
                                                  MainAxisAlignment.spaceEvenly,
                                              children: [
                                                CircleAvatar(
                                                  radius: 25,
                                                  backgroundColor:
                                                      Colors.yellow.shade400,
                                                  child: IconButton(
                                                    onPressed: () {
                                                      player.stop();
                                                      setState(() {
                                                        checkupCallScreenPickedStatus =
                                                            1;
                                                        checkupCallStatusYellow++;
                                                        // if(duration<2){
                                                        //   return;
                                                        // }
                                                        _counter = 0;
                                                        duration =
                                                            originalDuration ~/
                                                                (checkupCallStatusYellow *
                                                                    2);
                                                      });
                                                      Navigator.pop(context);
                                                      startCheckupCall();
                                                    },
                                                    icon: Icon(_muted
                                                        ? Icons.mic_off
                                                        : Icons.mic),
                                                  ),
                                                ),
                                                CircleAvatar(
                                                    radius: 30,
                                                    backgroundColor:
                                                        Colors.red.shade700,
                                                    child: IconButton(
                                                      onPressed: () async {
                                                        player.stop();
                                                        setState(() {
                                                          checkupCallScreenPickedStatus =
                                                              1;
                                                        });
                                                        Navigator.pop(context);
                                                        await _getPermission();
                                                        await Geolocator
                                                            .checkPermission();
                                                        await Geolocator
                                                            .requestPermission();
                                                        add_threat_data();
                                                        await widget.controller
                                                            .initialize();
                                                        // await fetchLocation();
                                                        // await _sendEmailToCommunity();
                                                        await _startRecording();
                                                        if (await _isPermissionGranted()) {
                                                          _sendMessage();
                                                          // _showLottieDialog(context);
                                                          _VibConfo();
                                                        }
                                                        _sendEmailToCommunity();
                                                      },
                                                      icon: const Icon(
                                                          Icons.call_end),
                                                    )),
                                                CircleAvatar(
                                                  radius: 25,
                                                  backgroundColor:
                                                      Colors.green.shade400,
                                                  child: IconButton(
                                                    onPressed: () {
                                                      player.stop();
                                                      setState(() {
                                                        _counter = 0;
                                                        checkupCallScreenPickedStatus =
                                                            1;
                                                      });
                                                      Navigator.pop(context);
                                                      startCheckupCall();
                                                    },
                                                    icon: Icon(_speaker
                                                        ? Icons.volume_up
                                                        : Icons.volume_off),
                                                  ),
                                                ),
                                              ],
                                            ),
                                          ),
                                        ),
                                      )
                                    ],
                                  ),
                                ),
                              );
                            },
                          );
                        },
                        child: Icon(
                          Icons.call,
                          color: Colors.green.shade700,
                        ),
                      ),
                    ],
                  ),
                ),
              )
            ],
          ),
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.all(16),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Column(
            children: [
              SizedBox(
                height: 42,
                width: 42,
                child: DottedBorder(
                  color: widget.isConnected
                      ? Colors.pink.shade400
                      : Colors.grey.shade600,
                  strokeWidth: 1,
                  borderType: BorderType.Circle,
                  dashPattern: const [8, 4],
                  child: IconButton(
                    color: widget.isConnected
                        ? Colors.pink.shade400
                        : Colors.grey.shade600,
                    onPressed: widget.isConnected
                        ? () {
                            Navigator.push(context,
                                MaterialPageRoute(builder: (context) {
                              List<String> fakeCallNamesList = [
                                "Bhaiya",
                                "Papa",
                                "Bro",
                                "Dad"
                              ];
                              String fakeCallPhone =
                                  "${Random().nextInt(4) + 6}${List.generate(9, (_) => Random().nextInt(10).toString()).join()}";
                              String fakeCallName = fakeCallNamesList[
                                  Random().nextInt(fakeCallNamesList.length)];
                              return OutgoingCallScreen(
                                  name: fakeCallName,
                                  phone: "+91 $fakeCallPhone",
                                  isfake: true);
                            }));
                          }
                        : () {
                            Fluttertoast.showToast(
                                msg: "Unavailable in Offline Mode");
                          },
                    icon: const Icon(
                      Icons.call,
                      size: 20,
                    ),
                  ),
                ),
              ),
              const Text(
                'Fake call',
                style: TextStyle(fontFamily: 'Mulish', fontSize: 13),
              ),
            ],
          ),
          Column(
            children: [
              Center(
                child: SizedBox(
                  height: 42,
                  width: 42,
                  child: DottedBorder(
                    color: checkUpCallEnabled
                        ? Colors.green.shade600
                        : Colors.pink.shade400,
                    strokeWidth: 1,
                    borderType: BorderType.Circle,
                    dashPattern: const [8, 4],
                    child: IconButton(
                      color: checkUpCallEnabled
                          ? Colors.green.shade600
                          : Colors.pink.shade400,
                      onPressed: checkupCall,
                      icon: const Icon(
                        Icons.phone_callback_rounded,
                        size: 20,
                      ),
                    ),
                  ),
                ),
              ),
              const Text(
                'Checkup',
                style: TextStyle(fontFamily: 'Mulish', fontSize: 13),
              ),
            ],
          ),
          Column(
            children: [
              Center(
                child: SizedBox(
                  height: 42,
                  width: 42,
                  child: DottedBorder(
                    color: Colors.pink.shade400,
                    strokeWidth: 1,
                    borderType: BorderType.Circle,
                    dashPattern: const [8, 4],
                    child: IconButton(
                      color: Colors.pink.shade400,
                      onPressed: widget.isConnected
                          ? () async {
                              await _getPermission();
                              await Geolocator.checkPermission();
                              await Geolocator.requestPermission();
                              add_threat_data();
                              await widget.controller.initialize();
                              // await fetchLocation();
                              // await _sendEmailToCommunity();
                              await _startRecording();
                              if (await _isPermissionGranted()) {
                                _sendMessage();
                                // _showLottieDialog(context);
                                _VibConfo();
                              }
                              _sendEmailToCommunity();
                            }
                          : () async {
                              await _getPermission();
                              await Geolocator.checkPermission();
                              await Geolocator.requestPermission();
                              if (await _isPermissionGranted()) {
                                _sendMessage();
                                // _showLottieDialog(context);
                                _VibConfo();
                              }
                            },
                      icon: const Icon(
                        Icons.sos,
                        size: 20,
                      ),
                    ),
                  ),
                ),
              ),
              const Text(
                'SOS alert',
                style: TextStyle(fontFamily: 'Mulish', fontSize: 13),
              ),
            ],
          ),
          Column(
            children: [
              Center(
                child: SizedBox(
                  height: 42,
                  width: 42,
                  child: DottedBorder(
                    color: Colors.pink.shade400,
                    strokeWidth: 1,
                    borderType: BorderType.Circle,
                    dashPattern: const [8, 4],
                    child: IconButton(
                      color: Colors.pink.shade400,
                      onPressed: () {
                        launchUrl(Uri.parse("tel: 1091"));
                      },
                      icon: const Icon(
                        Icons.health_and_safety_rounded,
                        size: 20,
                      ),
                    ),
                  ),
                ),
              ),
              const Text(
                'Helpline',
                style: TextStyle(fontFamily: 'Mulish', fontSize: 13),
              ),
            ],
          ),
          Column(
            children: [
              SizedBox(
                height: 42,
                width: 42,
                child: DottedBorder(
                  color: widget.isConnected
                      ? Colors.pink.shade400
                      : Colors.grey.shade600,
                  strokeWidth: 1,
                  borderType: BorderType.Circle,
                  dashPattern: const [8, 4],
                  child: IconButton(
                    color: widget.isConnected
                        ? Colors.pink.shade400
                        : Colors.grey.shade600,
                    onPressed: widget.isConnected
                        ? () {
                            Navigator.of(context).pushNamed('/audit');
                          }
                        : () {
                            Fluttertoast.showToast(
                                msg: "Unavailable in Offline Mode");
                          },
                    icon: const Icon(
                      Icons.camera,
                      size: 20,
                    ),
                  ),
                ),
              ),
              const Text(
                'Audit Log',
                style: TextStyle(fontFamily: 'Mulish', fontSize: 13),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
