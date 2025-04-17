import 'dart:async';
import 'dart:convert';
import 'dart:io';
// import 'package:background_sms/background_sms.dart';
import 'package:camera/camera.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:dotted_border/dotted_border.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:fluttertoast/fluttertoast.dart';
import 'package:geoflutterfire_plus/geoflutterfire_plus.dart';
import 'package:geolocator/geolocator.dart';
import 'package:internet_connection_checker_plus/internet_connection_checker_plus.dart';
import 'package:noise_meter/noise_meter.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:rakshak/screens/home/contact_container.dart';
import 'package:rakshak/screens/home/service_icon_row.dart';
import 'package:rakshak/screens/home/shield_container.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:video_player/video_player.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  final List<ContactData> contacts = [];

  Future<void> _saveContacts(ContactData contactData) async {
    final prefs = await SharedPreferences.getInstance();
    contacts.add(contactData);
    final encodedContacts =
        jsonEncode(contacts.map((c) => c.toJson()).toList());
    await prefs.setString('contacts', encodedContacts);
    debugPrint('Contact: $encodedContacts');
  }

  Future<void> _loadContacts() async {
    final prefs = await SharedPreferences.getInstance();
    final encodedContacts = prefs.getString('contacts');
    if (encodedContacts != null) {
      final decodedContacts = jsonDecode(encodedContacts) as List;
      setState(() {
        contacts.clear();
        contacts.addAll(
            decodedContacts.map((c) => ContactData.fromJson(c)).toList());
      });
    }
  }

  void _showAddContactDialog() {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        final nameController = TextEditingController();
        final phoneController = TextEditingController();
        final emailController = TextEditingController();

        return AlertDialog(
          title: const Text('Add Contact'),
          content: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                TextField(
                  controller: nameController,
                  decoration: const InputDecoration(hintText: 'Name'),
                ),
                TextField(
                  controller: phoneController,
                  decoration: const InputDecoration(hintText: 'Phone'),
                ),
                TextField(
                  controller: emailController,
                  decoration: const InputDecoration(hintText: 'Email'),
                ),
              ],
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('Cancel'),
            ),
            TextButton(
              onPressed: () {
                final name = nameController.text;
                final phone = phoneController.text;
                final email = emailController.text;
                if (name.isNotEmpty && phone.isNotEmpty && email.isNotEmpty) {
                  _saveContacts(
                      ContactData(name: name, phone: phone, email: email));
                  setState(() {});
                  Navigator.pop(context);
                } else {
                  // Show snackbar or other error message for missing data
                }
              },
              child: const Text('Save'),
            ),
          ],
        );
      },
    );
  }

  void _removeContact(int index) {
    if (index >= 0 && index < contacts.length) {
      setState(() {
        contacts.removeAt(index);
        _saveContactsAfterDelete(contacts);
      });
    }
  }

  Future<void> _saveContactsAfterDelete(List<ContactData> contacts) async {
    final prefs = await SharedPreferences.getInstance();
    final encodedContacts =
        jsonEncode(contacts.map((c) => c.toJson()).toList());
    await prefs.setString('contacts', encodedContacts);
    debugPrint('Updated Contact List: $encodedContacts');
  }

  void activateServices() {
    debugPrint('activated');
  }

  List<CameraDescription> cameras = [];
  late CameraController _controller;
  late VideoPlayerController _videoController =
      VideoPlayerController.file(File(''));
  bool langload = false;
  int val = 0;
  String number1 = "";
  String name1 = "";
  String email1 = "";
  String number2 = "";
  String name2 = "";
  String email2 = "";
  String number3 = "";
  String name3 = "";
  String email3 = "";
  String number = "";
  String name = "";
  String email = "";
  String lang = "";
  // bool _validate = false;
  final _formKey = GlobalKey<FormState>();
  TextEditingController editname = TextEditingController();
  TextEditingController editnumber = TextEditingController();
  TextEditingController editemail = TextEditingController();
  late SharedPreferences prefs;
  bool contactpckd = false;
  bool emailpckd = false;
  bool isloading = false;
  bool connectionstate = false;
  NoiseMeter? _noiseMeter;
  bool isConnected = false;

  num? safetyScore;
  StreamSubscription<List<GeoDocumentSnapshot<Map<String, dynamic>>>>?
      safetyStream;

  camsetup() async {
    cameras = await availableCameras();
    _controller = CameraController(
      cameras[0],
      ResolutionPreset.medium,
    );
    await _controller.initialize();
    setState(() {
      val = 1;
    });
    print("camera done");
  }

  locsetup() async {
    bool serviceEnabled = await Geolocator.isLocationServiceEnabled();
    if (!serviceEnabled) {
      bool serviceRequested = await Geolocator.openLocationSettings();
      if (!serviceRequested) {
        return;
      }
    }
    print("loc done");
  }

  getid() async {
    prefs = await SharedPreferences.getInstance();
    contactpckd = await prefs.getBool('contactpckd') ?? false;
    emailpckd = await prefs.getBool('emailpckd') ?? false;

    if (emailpckd) {
      email1 = await prefs.getString('email1').toString();
      email2 = await prefs.getString('email2').toString();
      email3 = await prefs.getString('email3').toString();
    }

    if (contactpckd) {
      name1 = await prefs.getString('name1').toString();
      name2 = await prefs.getString('name2').toString();
      name3 = await prefs.getString('name3').toString();
      number1 = await prefs.getString('number1').toString();
      number2 = await prefs.getString('number2').toString();
      number3 = await prefs.getString('number3').toString();
    }
    isloading = true;
  }

  void initSafetyScore() async {
    print("init safety score");
    if (await Geolocator.checkPermission() == LocationPermission.denied) {
      await Geolocator.requestPermission();
    }
    Position position = await Geolocator.getCurrentPosition();
    GeoPoint currentPos = GeoPoint(position.latitude, position.longitude);
    print("currentPos = ${currentPos.latitude} ${currentPos.longitude}");
    GeoFirePoint center = GeoFirePoint(currentPos);

    final geo =
        GeoCollectionReference(FirebaseFirestore.instance.collection("audit"));
    print(geo);
    geo
        .subscribeWithinWithDistance(
      center: center,
      radiusInKm: 5,
      field: "position",
      geopointFrom: (obj) {
        print("obj = ${obj['position']['geopoint']}");
        return obj['position']['geopoint'];
      },
      // strictMode: true,
    )
        .listen((data) {
      num total = 0;
      print("calcuating safety score from docs: ${data.length}");
      if (data.length < 1) {
        return;
      }
      for (var i = 0; i < data.length; i++) {
        print("dis : ${data[i].distanceFromCenterInKm}");
        print("doc : ${data[i].documentSnapshot.data()}");
        total = total + data[i].documentSnapshot.data()!['score'];
      }
      setState(() {
        safetyScore = total / data.length;
        print("Safety Score: $safetyScore/10");
      });
    });
  }

  // Future<GeoPoint> fetchUserLocation() async {
  //   Position position = await Geolocator.getCurrentPosition(
  //       desiredAccuracy: LocationAccuracy.best);
  //   return GeoPoint(position.latitude, position.longitude);
  // }

  // updateUserInCommunity() async {
  //   final _userId = await FirebaseAuth.instance.currentUser!.uid;
  //   final _dbref = FirebaseFirestore.instance.collection('userData');
  //   DocumentSnapshot document = await _dbref.doc(_userId).get();
  //   final map = document.data() as Map;
  //   GeoPoint userLoc = await fetchUserLocation();

  //   Map<String, dynamic> mapWithUpdatedLocation = {
  //     "email": map["email"],
  //     "Name": map["fname"] + " " + map["lname"],
  //     "phone": map["phno"],
  //     "position": userLoc,
  //     "time": DateTime.now(),
  //   };
  //   await FirebaseFirestore.instance
  //       .collection("community")
  //       .doc(_userId)
  //       .set(mapWithUpdatedLocation);
  // }

  // Position? _currentPosition;
  // String userId = FirebaseAuth.instance.currentUser!.uid;

  // final geo = GeoFlutterFire();
  // Future<bool> _handleLocationPermission() async {
  //   bool serviceEnabled;
  //   LocationPermission permission;

  //   serviceEnabled = await Geolocator.isLocationServiceEnabled();
  //   if (!serviceEnabled) {
  //     ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
  //         content: Text(
  //             'Location services are disabled. Please enable the services')));
  //     return false;
  //   }
  //   permission = await Geolocator.checkPermission();
  //   if (permission == LocationPermission.denied) {
  //     permission = await Geolocator.requestPermission();
  //     if (permission == LocationPermission.denied) {
  //       ScaffoldMessenger.of(context).showSnackBar(
  //           const SnackBar(content: Text('Location permissions are denied')));
  //       return false;
  //     }
  //   }
  //   if (permission == LocationPermission.deniedForever) {
  //     ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
  //         content: Text(
  //             'Location permissions are permanently denied, we cannot request permissions.')));
  //     return false;
  //   }
  //   return true;
  // }

// NOT REQUIRED ANYMORE
  // Future<void> _getCurrentPosition() async {
  //   final hasPermission = await _handleLocationPermission();

  //   if (!hasPermission) return;
  //   await Geolocator.getCurrentPosition(desiredAccuracy: LocationAccuracy.high)
  //       .then((Position position) {
  //     setState(() => _currentPosition = position);
  //   });
  // }

  // void _updateLocation() async {
  //   final hasPermission = await _handleLocationPermission();
  //   if (!hasPermission) return;
  //   Position position = await Geolocator.getCurrentPosition(
  //       desiredAccuracy: LocationAccuracy.high);

  //   GeoFirePoint userLocation =
  //       geo.point(latitude: position.latitude, longitude: position.longitude);
  //   FirebaseFirestore.instance
  //       .collection('userData')
  //       .doc(userId)
  //       .update({'position': userLocation.data});

  //   print("location updated");
  // }

  // doesHomeExist() async {
  // try {
  // Get reference to Firestore collection
  //   var collectionRef = FirebaseFirestore.instance.collection('community');

  //   var doc = await collectionRef.doc(userId).get();
  //   if (doc.exists) {
  //     return;
  //   } else {
  //     var userData = await FirebaseFirestore.instance
  //         .collection('userData')
  //         .doc(userId)
  //         .get();
  //     Map map = userData.data() as Map;
  //     GeoFirePoint userLocation = geo.point(
  //         latitude: _currentPosition!.latitude,
  //         longitude: _currentPosition!.longitude);
  //     collectionRef.doc(userId).set({
  //       'email': map['email'],
  //       'phone': map['phone'],
  //       'position': userLocation.data,
  //     });
  //   }
  // } catch (e) {
  //   rethrow;
  // }
  // print("done");
  // }

  void updateUserPos() async {
    await Geolocator.checkPermission();
    await Geolocator.requestPermission();
    Position position = await Geolocator.getCurrentPosition(
        desiredAccuracy: LocationAccuracy.best);
    double lat = position.latitude;
    double lng = position.longitude;
    final GeoFirePoint geoFirePoint = GeoFirePoint(GeoPoint(lat, lng));
    var _uid = FirebaseAuth.instance.currentUser!.uid;
    final _dbref = FirebaseFirestore.instance.collection('userData');

    DocumentSnapshot document = await _dbref.doc(_uid).get();
    final map = document.data() as Map;

    GeoCollectionReference(FirebaseFirestore.instance.collection('userData'))
        .set(
      id: _uid,
      data: {'geo': geoFirePoint.data, 'time': DateTime.now()},
      options: SetOptions(merge: true),
    );

    // final Map<String, dynamic> data = geoFirePoint.data;
    // GeoCollectionReference<Map<String, dynamic>>(
    //         FirebaseFirestore.instance.collection('sos_generation'))
    //     .add(<String, dynamic>{
    //   'geo': geoFirePoint.data,
    //   'name': map["fname"] + " " + map["lname"],
    //   "phone": map["phno"],
    //   // 'isVisible': true,
    //   "time": DateTime.now(),
    // });
  }

  Future<void> internetAccessCheck() async {
    bool result = await InternetConnection().hasInternetAccess;
    isConnected = result;
  }

  void internetAlertBox() {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: Text('Offline Mode'),
          content: Text(
            'You dont have an active internet connection. Shield services will be limited. We request you to find an active internet connection as soon as possible.',
            textAlign: TextAlign.justify,
            style: TextStyle(fontFamily: 'Mulish'),
          ),
          actions: [
            ElevatedButton(
              style: ButtonStyle(
                  backgroundColor:
                      WidgetStatePropertyAll(Colors.yellow.shade600)),
              onPressed: () {
                Navigator.pop(context);
              },
              child: const Text(
                'Okay',
                style: TextStyle(
                  fontFamily: 'Mulish',
                  fontWeight: FontWeight.w600,
                  color: Colors.white,
                ),
              ),
            ),
          ],
        );
      },
    );
  }

  Future<void> _getPermission() async {
    await Permission.sms.request();
    await Geolocator.checkPermission();
    await Geolocator.requestPermission();
    await Permission.microphone.request();
    await Permission.camera.request();
    if (await Permission.camera.request().isGranted) {
      camsetup();
    } else {
      Permission.camera.request();
    }
  }

  @override
  void initState() {
    super.initState();
    // updateUserInCommunity();
    _getPermission();
    _loadContacts();
    langload = true;
    // camsetup();
    locsetup();
    getid();
    initSafetyScore();
    _noiseMeter = NoiseMeter();
    updateUserPos();
    internetAccessCheck();
    // Timer.periodic(const Duration(seconds: 5), (timer) {
    //   updateUserPos();
    // });
    // doesHomeExist();
  }

  @override
  Widget build(BuildContext context) {
    debugPrint(contacts.length.toString());
    debugPrint("Network connected : $isConnected");
    if ((val == 1 && isConnected == true)) {
      return Container(
        color: Colors.grey.shade100,
        child: Center(
          child: ListView(
            children: [
              ShieldContainer(
                cameras: cameras,
                controller: _controller,
                videoController: _videoController,
                sms_sender: false,
                isConnected: true,
              ),
              IconRow(
                cameras: cameras,
                controller: _controller,
                videoController: _videoController,
                sms_sender: false,
                isConnected: true,
              ),
              Container(
                margin: const EdgeInsets.only(left: 16, right: 16),
                // height: 120,
                width: double.infinity,
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(20),
                  color: Colors.pink[300],
                ),
                child: Padding(
                  padding: const EdgeInsets.all(12.0),
                  child: Row(
                    children: [
                      const Icon(
                        Icons.safety_check,
                        color: Colors.white,
                        size: 40,
                      ),
                      SizedBox(
                        width: 5,
                      ),
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            "Safety Score",
                            style: TextStyle(
                                fontFamily: 'Mulish',
                                fontSize: 18,
                                fontWeight: FontWeight.w500,
                                color: Colors.white),
                          ),
                          Text(
                            "Based on current location",
                            style: TextStyle(
                                fontFamily: 'Mulish',
                                fontSize: 12,
                                fontWeight: FontWeight.w500,
                                color: Colors.white),
                          ),
                        ],
                      ),
                      Spacer(),
                      (safetyScore == null)
                          ? CircularProgressIndicator(
                              color: Colors.white,
                            )
                          : Text("${safetyScore!.toStringAsFixed(1)} / 10",
                              style: TextStyle(
                                  fontFamily: 'Mulish',
                                  fontSize: 18,
                                  fontWeight: FontWeight.w500,
                                  color: Colors.white))
                    ],
                  ),
                ),
              ),
              Container(
                margin: const EdgeInsets.only(left: 16, top: 10),
                child: const Text(
                  'Emergency Contacts',
                  style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w600,
                      fontFamily: 'Mulish'),
                ),
              ),
              contacts.isEmpty
                  ? Container(
                      margin: const EdgeInsets.all(16),
                      height: 60,
                      decoration: BoxDecoration(
                        borderRadius: BorderRadius.circular(12),
                        color: Colors.pink.shade100,
                      ),
                      child: const Center(
                        child: Text(
                          'Add some emergency contacts',
                          style: TextStyle(fontFamily: 'Mulish'),
                        ),
                      ),
                    )
                  : ListView.builder(
                      shrinkWrap: true,
                      physics: const NeverScrollableScrollPhysics(),
                      itemCount: contacts.length,
                      itemBuilder: (context, index) {
                        return ContactWidget(
                          name: contacts[index].name,
                          phone: contacts[index].phone,
                          email: contacts[index].email,
                          onDelete: _removeContact,
                          index: index,
                        );
                      },
                    ),
              Center(
                child: Container(
                  height: 42,
                  width: 42,
                  margin: const EdgeInsets.only(right: 12, top: 10),
                  child: DottedBorder(
                    color: Colors.pink.shade400,
                    strokeWidth: 1,
                    borderType: BorderType.Circle,
                    dashPattern: const [8, 4],
                    child: IconButton(
                      color: Colors.pink.shade400,
                      onPressed: _showAddContactDialog,
                      icon: const Icon(
                        Icons.add,
                        size: 20,
                      ),
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      );
      //OFFLINE SECTION
    } else if (val == 1 && isConnected == false) {
      return Container(
        color: Colors.grey.shade100,
        child: Center(
          child: ListView(
            children: [
              Stack(
                children: [
                  Padding(
                    padding: EdgeInsets.only(top: 10),
                    child: ShieldContainer(
                      cameras: cameras,
                      controller: _controller,
                      videoController: _videoController,
                      sms_sender: false,
                      isConnected: false,
                    ),
                  ),
                  Positioned(
                    top: -MediaQuery.of(context).size.height / 100,
                    left: MediaQuery.of(context).size.width / 1.1,
                    // child: IconButton(
                    //     onPressed: internetAlertBox,
                    //     color: Colors.yellow.shade800,
                    //     icon: Icon(Icons
                    //         .signal_wifi_connected_no_internet_4_rounded))),\
                    child: InkWell(
                      onTap: internetAlertBox,
                      child: Container(
                          height: 40,
                          padding: EdgeInsets.all(4),
                          decoration: BoxDecoration(
                            shape: BoxShape.circle,
                            color: Colors.yellow.shade800,
                          ),
                          child: Icon(
                            Icons
                                .signal_cellular_connected_no_internet_4_bar_rounded,
                            size: 20,
                            color: Colors.white,
                          )),
                    ),
                  ),
                ],
              ),
              IconRow(
                cameras: cameras,
                controller: _controller,
                videoController: _videoController,
                sms_sender: false,
                isConnected: false,
              ),
              Container(
                margin: const EdgeInsets.only(left: 16, top: 10),
                child: const Text(
                  'Emergency Contacts',
                  style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w600,
                      fontFamily: 'Mulish'),
                ),
              ),
              contacts.isEmpty
                  ? Container(
                      margin: const EdgeInsets.all(16),
                      height: 60,
                      decoration: BoxDecoration(
                        borderRadius: BorderRadius.circular(12),
                        color: Colors.pink.shade100,
                      ),
                      child: const Center(
                        child: Text(
                          'Add some emergency contacts',
                          style: TextStyle(fontFamily: 'Mulish'),
                        ),
                      ),
                    )
                  : ListView.builder(
                      shrinkWrap: true,
                      physics: const NeverScrollableScrollPhysics(),
                      itemCount: contacts.length,
                      itemBuilder: (context, index) {
                        return ContactWidget(
                          name: contacts[index].name,
                          phone: contacts[index].phone,
                          email: contacts[index].email,
                          onDelete: _removeContact,
                          index: index,
                        );
                      },
                    ),
              Center(
                child: Container(
                  height: 42,
                  width: 42,
                  margin: const EdgeInsets.only(right: 12, top: 10),
                  child: DottedBorder(
                    color: Colors.pink.shade400,
                    strokeWidth: 1,
                    borderType: BorderType.Circle,
                    dashPattern: const [8, 4],
                    child: IconButton(
                      color: Colors.pink.shade400,
                      onPressed: _showAddContactDialog,
                      icon: const Icon(
                        Icons.add,
                        size: 20,
                      ),
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      );
    } else {
      return Center(
        child: CircularProgressIndicator(color: Colors.pink.shade400),
      );
    }
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
