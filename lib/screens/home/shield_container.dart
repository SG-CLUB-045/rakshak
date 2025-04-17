import 'dart:convert';

import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:fluttertoast/fluttertoast.dart';
import 'package:geoflutterfire_plus/geoflutterfire_plus.dart';
import 'package:geolocator/geolocator.dart';
import 'package:rakshak/screens/home/nearby_users.dart';
import 'package:speech_to_text/speech_to_text.dart';
import 'dart:async';
import 'dart:io';
import 'dart:math';
import 'package:sms_sender_background/sms_sender.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:csv/csv.dart';
import 'package:flutter/services.dart';
import 'package:lottie/lottie.dart';
import 'package:mailer/mailer.dart';
import 'package:mailer/smtp_server/gmail.dart';
import 'package:path_provider/path_provider.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:sensors_plus/sensors_plus.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:speech_to_text/speech_to_text.dart' as stt;
import 'package:audioplayers/audioplayers.dart';
import 'package:string_similarity/string_similarity.dart';
import 'package:vibration/vibration.dart';

class ShieldContainer extends StatefulWidget {
  final cameras;
  final controller;
  final sms_sender;
  final videoController;
  final isConnected;
  const ShieldContainer({
    super.key,
    this.cameras,
    this.controller,
    this.sms_sender,
    this.videoController,
    this.isConnected,
  });

  @override
  State<ShieldContainer> createState() => _ShieldContainerState();
}

class _ShieldContainerState extends State<ShieldContainer> {
  final stt.SpeechToText _speech = stt.SpeechToText();

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
  String shieldText = "Shield Off";
  String shieldSubText = "Tap to activate \nservices.";
  String shieldSubTextAlt = "Tap to activate \nlimited services.";
  bool isActivated = false;
  List contacts = [];
  bool continuedListening = true;

  // This function ask for Permissions and give status of it
  Future<void> _setupSpeechRecognition() async {
    fall_detection();
    bool available = await _speech.initialize(
      onStatus: (status) {
        // print('Speech recognition status: $status');
      },
      onError: (error) {
        // print('Speech recognition error: $error');
        _startListening();
      },
    );
    if (available) {
      print('Speech recognition is available');
      _startListening();
    } else {
      // print('Speech recognition is not available');
    }
  }

  // This function is to SEND DATA AND RECIEVE THE PREDICTED OUTPUT
  Future<void> data_from_api(String text) async {
    print("data from api reached");
    final csvString =
        await rootBundle.loadString('assets/Women_Safety_dataset.csv');
    final csvData = const CsvToListConverter().convert(csvString);
    for (final row in csvData) {
      if (row.isNotEmpty) {
        String string1 = row[0].toString().toLowerCase();
        var similarity = text.similarityTo(string1);
        if (similarity >= 0.6 && canShowAppPrompt == true) {
          print(similarity);
          startTimer();
          startCooldown();
          break;
        }
      }
    }
  }

  Future<GeoPoint> fetchUserLocation() async {
    Position position = await Geolocator.getCurrentPosition(
        desiredAccuracy: LocationAccuracy.best);
    latitude = position.latitude;
    longitude = position.longitude;
    return GeoPoint(position.latitude, position.longitude);
  }

  // THIS FUNCTION LISTEN TO THE MICROPHONE AND GIVE THE TEXT GENERATED
  Future<void> _startListening() async {
    print("started listening");
    _speech.listen(
      listenFor: const Duration(seconds: 5),
      onResult: (result) {
        print(result.recognizedWords);
        if (result.finalResult) {
          print("result final block");
          String text = result.recognizedWords;
          print('Recognized text: $text');
          Fluttertoast.showToast(msg: "$text");
          data_from_api(text.toLowerCase());
        }
        if (!_speech.isListening && continuedListening || sta == "done") {
          _startListening();
        }
      },
    );
  }

  Future<void> startTimer() async {
    _triggerVibration();
    showDialog(
        context: context,
        barrierDismissible: false,
        builder: (BuildContext context) {
          return AlertDialog(
              title: Localizations.override(
                  context: context,
                  locale: (lang == 'english')
                      ? const Locale('en')
                      : const Locale('hi'),
                  child: Builder(builder: (context) {
                    return Text(
                        "Are you safe?"); //return Text(AppLocalizations.of(context)!.areYouSafe);
                  })),
              content: Localizations.override(
                  context: context,
                  locale: (lang == 'english')
                      ? const Locale('en')
                      : const Locale('hi'),
                  child: Builder(builder: (context) {
                    return Text(
                        "We just detected a voice-threat. Tell us if you are safe, otherwise the SOS alert protocol will be executed."); //return Text(AppLocalizations.of(context)!.pressYes);
                  })),
              actions: <Widget>[
                ElevatedButton(
                    child: Localizations.override(
                      context: context,
                      locale: (lang == 'english')
                          ? const Locale('en')
                          : const Locale('hi'),
                      child: Builder(builder: (context) {
                        return Text(
                          "I'm safe", //AppLocalizations.of(context)!.yes,
                          style: const TextStyle(color: Colors.black),
                        );
                      }),
                    ),
                    onPressed: () {
                      Navigator.of(context, rootNavigator: true)
                          .pop(); // close the dialog
                      threat = 1;
                      Vibration.cancel();
                      setState(() {
                        canShowAppPrompt = true;
                      });
                    })
              ]);
        });
    await Future.delayed(const Duration(seconds: 10));

    if (threat == 0) {
      print("VOICE THREAT");
      Fluttertoast.showToast(msg: "VOICE THREAT DETECTED");
      Navigator.of(context, rootNavigator: true).pop();
      Vibration.cancel();
      if (await _isPermissionGranted()) {
        _sendMessage();
        // _showLottieDialog(context);
        _VibConfo();
      }
      if (widget.isConnected == false) {
        return;
      }
      add_threat_data();
      await widget.controller.initialize();
      // await fetchLocation();
      await _sendEmailToCommunity();
      await _startRecording();
    } else {
      print("WRONG DETECTION FOR VOICE");
      threat = 0;
      canShowAppPrompt = true;
      Vibration.cancel();
    }
  }

  // Adding Threat data
  Future<void> add_threat_data() async {
    if (widget.isConnected == false) {
      debugPrint('disconnected');
      return;
    }
    Position position = await Geolocator.getCurrentPosition(
        desiredAccuracy: LocationAccuracy.best);
    double lat = position.latitude;
    double lng = position.longitude;
    final GeoFirePoint geoFirePoint = GeoFirePoint(GeoPoint(lat, lng));
    final _userId = await FirebaseAuth.instance.currentUser!.uid;
    final _dbref = FirebaseFirestore.instance.collection('userData');
    DocumentSnapshot document = await _dbref.doc(_userId).get();
    final map = document.data() as Map;

    // final Map<String, dynamic> data = geoFirePoint.data;
    GeoCollectionReference<Map<String, dynamic>>(
            FirebaseFirestore.instance.collection('sos_generation'))
        .add(<String, dynamic>{
      'geo': geoFirePoint.data,
      'name': map["fname"] + " " + map["lname"],
      "phone": map["phno"],
      // 'isVisible': true,
      "time": DateTime.now(),
    });

    // final map = document.data() as Map;
    // debugPrint(map.toString());
    // GeoPoint userLoc = await fetchUserLocation();
    // FirebaseFirestore.instance.collection('sos_generation').doc().set({
    //   "email": map["email"],
    //   "Name": map["fname"] + " " + map["lname"],
    //   "phone": map["phno"],
    //   "position": userLoc,
    //   "time": DateTime.now(),
    // });
    print("updated sos");
  }

  // This Function Is For FALL DETECTION
  void fall_detection() {
    accelerometerEvents.listen((AccelerometerEvent event) {
      num _accelX = event.x.abs();
      num _accelY = event.y.abs();
      num _accelZ = event.z.abs();
      num x = pow(_accelX, 2);
      num y = pow(_accelY, 2);
      num z = pow(_accelZ, 2);
      num sum = x + y + z;
      num result = sqrt(sum);
      // print("accz = $_accelZ");
      // print("accx = $_accelX");
      // print("accy = $_accelY");
      if ((result < 1) ||
          (result > 70 && _accelZ > 60 && _accelX > 60) ||
          (result > 70 && _accelX > 60 && _accelY > 60)) {
        // print("res = $result");
        // print("accz = $_accelZ");
        // print("accx = $_accelX");
        // print("accy = $_accelY");
        if (canShowAppPrompt) {
          fallTimer();
          startCooldown();
        }
      }
    });
  }

  // vibrate triggger
  Future<void> _triggerVibration() async {
    final hasVibrator = await Vibration.hasVibrator();

    if (hasVibrator ?? false) {
      Vibration.vibrate(duration: 10000);
    }
  }

  // FAll Timer for fall detection
  Future<void> fallTimer() async {
    // audioPlayer.play(AssetSource('safety.mp3'));
    _triggerVibration();
    showDialog(
        context: context,
        barrierDismissible: false,
        builder: (BuildContext context) {
          return AlertDialog(
              title: Localizations.override(
                  context: context,
                  locale: (lang == 'english')
                      ? const Locale('en')
                      : const Locale('hi'),
                  child: Builder(builder: (context) {
                    return Text(
                        "Are you safe?"); //return Text(AppLocalizations.of(context)!.phoneFallAccident);
                  })),
              content: Localizations.override(
                  context: context,
                  locale: (lang == 'english')
                      ? const Locale('en')
                      : const Locale('hi'),
                  child: Builder(builder: (context) {
                    return Text(
                        "We just detected a fall-threat. Tell us if you are safe, otherwise the SOS alert protocol will be executed."); //return Text(AppLocalizations.of(context)!.pressYesFall);
                  })),
              actions: <Widget>[
                ElevatedButton(
                    child: Localizations.override(
                      context: context,
                      locale: (lang == 'english')
                          ? const Locale('en')
                          : const Locale('hi'),
                      child: Builder(builder: (context) {
                        return Text(
                          "I'm safe", //AppLocalizations.of(context)!.yes,
                          style: const TextStyle(color: Colors.black),
                        );
                      }),
                    ),
                    onPressed: () {
                      Navigator.of(context, rootNavigator: true)
                          .pop(); // close the dialog
                      isfallen = 1;
                      Vibration.cancel();
                      setState(() {
                        canShowAppPrompt = true;
                      });
                    })
              ]);
        });
    await Future.delayed(const Duration(seconds: 10));
    if (isfallen == 0) {
      print("FALL THREAT");
      Navigator.of(context, rootNavigator: true).pop();
      Vibration.cancel();
      if (await _isPermissionGranted()) {
        _sendMessage();
        // audioPlayer.play(AssetSource('siren.mp3'));
        // await Future.delayed(const Duration(seconds: 10));
        // audioPlayer.stop();
        // _showLottieDialog(context);
        _VibConfo();
      }
      if (widget.isConnected == false) {
        return;
      }
      add_threat_data();
      await widget.controller.initialize();
      // await fetchLocation();
      await _sendEmailToCommunity();
      await _startRecording();
    } else {
      print("WRONG DETECTION FOR FALL");
      isfallen = 0;
      canShowAppPrompt = true;
      Vibration.cancel();
    }
  }

  // Cool Down Code Function For App Prompt
  void startCooldown() {
    setState(() {
      canShowAppPrompt = false;
    });
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
        Fluttertoast.showToast(msg: "EMERGENCY CONTACTS HAVE BEEN MAILED");
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

  Future<void> popdata(BuildContext context) async {
    await Future.delayed(const Duration(seconds: 2));
    Navigator.pop(context);
  }

  Future<void> _VibConfo() async {
    final hasVibrator = await Vibration.hasVibrator();

    if (hasVibrator ?? false) {
      Vibration.vibrate(duration: 2000);
    }
  }

  Future<void> _sendEmailToCommunity() async {
    //saving data
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

  _getPermission() {
    return Permission.sms.request();
  }

  Future<bool> _isPermissionGranted() {
    return Permission.sms.status.isGranted;
  }

  // Future<bool?> get _supportCustomSim {
  //   return BackgroundSms.isSupportCustomSim;
  // }

  Future<void> _sendMessage() async {
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
              """Need help! My location is https://www.google.com/maps/place/$lat+$lng""",
          simSlot: 1);
      print(
          """Need help! My location is https://www.google.com/maps/place/$lat+$lng""");
      // if (result == SmsStatus.sent) {
      //   print("Sent");
      //   Fluttertoast.showToast(msg: "SOS ALERT SENT TO ${contacts[i].name}");
      // } else {
      //   print("Failed");
      // }
    }
  }

  Future<void> _setupcam() async {
    await widget.controller.initialize();
  }

  Future<void> getLang() async {
    SharedPreferences sp = await SharedPreferences.getInstance();
    setState(() {
      if (sp.getString('lang') == 'hindi') {
        lang = "hindi";
        langLoad = false;
      } else {
        lang = "english";
        langLoad = false;
      }
    });
  }

  @override
  void initState() {
    langLoad = false;
    super.initState();
    getLang();
  }

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: () async {
        if (isActivated == false) {
          continuedListening = true;
          await _getPermission();
          await Geolocator.checkPermission();
          await Geolocator.requestPermission();
          try {
            _setupSpeechRecognition();
            // startTimer();
          } catch (e) {
            print("ERROR OCCURED IN SERVICE : " + e.toString());
          }

          print("tapped");
          setState(() {
            shieldContainerColor = Colors.green.shade400;
            shieldColor = Colors.green.shade900;
            shieldText = "Shield On";
            widget.isConnected
                ? shieldSubText = "Services activated."
                : shieldSubTextAlt = "Limited services \nactivated.";
            // shieldSubText = widget.isConnected
            //     ? "Services activated."
            //     : "Limited services \nactivated.";
            isActivated = true;
          });
        } else {
          continuedListening = false;
          await _speech.stop();
          setState(() {
            shieldContainerColor = Colors.pink.shade400;
            shieldColor = Colors.pink.shade900;
            shieldText = "Shield Off";
            widget.isConnected
                ? shieldSubText = "Tap to activate \nservices."
                : shieldSubTextAlt = "Tap to activate \nlimited services.";
            // shieldSubText = widget.isConnected
            //     ? "Tap to activate \nservices."
            //     : "Tap to activate \nlimited services.";
            isActivated = false;
          });
        }
      },
      child: Container(
        padding: const EdgeInsets.only(left: 14),
        margin: const EdgeInsets.symmetric(horizontal: 10),
        decoration: BoxDecoration(
          color: shieldContainerColor,
          borderRadius: BorderRadius.circular(12),
        ),
        height: MediaQuery.sizeOf(context).height / 4,
        child: Row(
          children: [
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Spacer(),
                Text(
                  shieldText,
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 24,
                    fontFamily: 'Mulish',
                  ),
                ),
                Text(
                  widget.isConnected ? shieldSubText : shieldSubTextAlt,
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 16,
                    fontFamily: 'Mulish',
                  ),
                ),
                Spacer(),
              ],
            ),
            const Spacer(),
            Icon(
              Icons.shield_outlined,
              size: MediaQuery.sizeOf(context).height / 4.2,
              color: shieldColor,
            ),
          ],
        ),
      ),
    );
  }
}

class ContactData {
  final String name;
  final String phone;
  final String email;

  const ContactData({
    required this.name,
    required this.phone,
    required this.email,
  });

  Map<String, dynamic> toJson() => {
        'name': name,
        'phone': phone,
        'email': email,
      };

  factory ContactData.fromJson(Map<String, dynamic> json) => ContactData(
        name: json['name'] as String,
        phone: json['phone'] as String,
        email: json['email'] as String,
      );
}
