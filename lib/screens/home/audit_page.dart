import 'dart:io';
import 'dart:ui';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:fluttertoast/fluttertoast.dart';
import 'package:geoflutterfire_plus/geoflutterfire_plus.dart';
import 'package:geolocator/geolocator.dart';
import 'package:google_generative_ai/google_generative_ai.dart';
import 'package:image_picker/image_picker.dart';


class AuditPage extends StatefulWidget {
  const AuditPage({super.key});

  @override
  State<AuditPage> createState() => _AuditPageState();
}

class _AuditPageState extends State<AuditPage> {
  late File _image;
  bool imageInitialized = false;
  Map<String, dynamic> auditData = {};
  Map<String, dynamic> auditEntry = {};
  bool _loading = false;
  static const _apiKey = 'AIzaSyC9nl8DAX5dxW4HxNeg-o390g3W38UxRhc';
  late final GenerativeModel _model;
  int safetyScore = 0;
  void updateAuditData(String mapString, int level) {
    setState(() {
      auditData[mapString] = level;
    });
  }

  Future<void> getImageCamera() async {
    var image = await ImagePicker().pickImage(source: ImageSource.camera);

    if (image != null) {
      setState(() {
        _image = File(image.path);
        imageInitialized = true;
      });
    } else {
      debugPrint('No image selected.');
    }
  }

  Future<void> _sendChatMessage(Map<String, dynamic> map) async {
    try {
      await Geolocator.checkPermission();
      await Geolocator.requestPermission();
      Position position = await Geolocator.getCurrentPosition(
          desiredAccuracy: LocationAccuracy.best);
      double lat = position.latitude;
      double lng = position.longitude;
      String prompt =
          "You are a master of detecting safety of a woman in danger. She will give you details of the place she is in, in the form of a map with key-value pairs. You have to fetch the values of each key and generate the safety score based on the keys. The keys can be lighting i.e. the brightness around her for clear visibility, walkpath i.e the road quality, openness i.e. if the space she is in is aptly open or not, crowd i.e if the place is deserted or crowdy, diversity i.e if there is presence of women and children around the woman, security i.e if there is police or local authorities near her, transport i.e. if there is public transport like bus, metro, train etc available to her, and finally feeling i.e. how safe she feels. Each value pair in the map is from 1 to 4, 1 meaning very less and 4 meaning sufficient or plenty. You have to respond the safety score out of 10. Just respond the score itself, rounding off to nearest integer. Nothing else. Here is the map: $map";
      setState(() {
        _loading = true;
      });
      var content = [Content.text(prompt)];
      // debugPrint(response);
      final response = await _model.generateContent(content);
      debugPrint("manual response : ${response.text}");
      final GeoFirePoint geoFirePoint = GeoFirePoint(GeoPoint(lat, lng));
      auditEntry.addAll({
        'position': geoFirePoint.data,
        'score': int.parse(response.text!),
      });
      GeoCollectionReference(FirebaseFirestore.instance.collection('audit'))
          .add(auditEntry);
      setState(() {
        _loading = false;
      });
      Fluttertoast.showToast(msg: "Safety audit data submitted. Thanks!");
    } catch (e) {
      // debugPrint(e);
      debugPrint("Error : $e");
    }
  }

  Future<void> _sendImageMessage() async {
    final imgBytes = await _image.readAsBytes();
    String prompt =
        "You are the master in defining safety of a place. Here is a picture of a place and it should be an outside area and not any indoor place. If the place is indoor, just respond indoor and nothing else. But if its outdoor, you have to determine the safety score of the location. The criteria is that how safe this place should be for a woman. Take into account factors such as how open the area is, how good the lighting of the area is, if it has good roads or not, if there is enough crowd with age and gender diversity for the woman to feel safe in, how good the security of the place is, because police station and other local authorities are a plus and if there is local transport available or not. The safety score should be out of 10. If you have a decimal answer, round it off to the nearest integer. Remember, you have to either tell indoor, or generate the safety score, nothing else. ";
    final content = [
      Content.multi([
        TextPart(prompt),
        DataPart('image/jpeg', imgBytes),
      ])
    ];
    setState(() {
      _loading = true;
    });
    final response = await _model.generateContent(content);
    final responseText = response.text?.trim();
    await Geolocator.checkPermission();
    await Geolocator.requestPermission();
    Position position = await Geolocator.getCurrentPosition(
        desiredAccuracy: LocationAccuracy.best);
    double lat = position.latitude;
    double lng = position.longitude;
    setState(() {
      _loading = false;
    });
    // debugPrint('Response:');
    // debugPrint(response.text);
    debugPrint("Response: $responseText");
    if (responseText == "Indoor" ||
        responseText == "indoor" ||
        responseText == "Indoor." ||
        responseText == "indoor.") {
      _image = File('');
      imageInitialized = false;
      Fluttertoast.showToast(msg: "Please take an outdoor image.");
    } else {
      safetyScore = int.parse(responseText!.trim());
      final GeoFirePoint geoFirePoint = GeoFirePoint(GeoPoint(lat, lng));
      auditEntry.addAll({'position': geoFirePoint.data, 'score': safetyScore});
      GeoCollectionReference(FirebaseFirestore.instance.collection('audit'))
          .add(auditEntry);
      // await FirebaseFirestore.instance.collection("audit").add(auditData);
      Fluttertoast.showToast(msg: "Safety audit data submitted. Thanks!");
    }
  }

  @override
  void initState() {
    super.initState();
    _model = GenerativeModel(
      model: 'gemini-1.5-flash',
      apiKey: _apiKey,
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        leading: IconButton(
            onPressed: () {
              Navigator.pop(context);
            },
            icon: Icon(
              Icons.arrow_back_ios_new_rounded,
              color: Colors.pink.shade400,
              size: 20,
            )),
        title: Text(
          'Safety Audit',
          style: TextStyle(
            fontSize: 22,
            fontWeight: FontWeight.bold,
            color: Colors.pink.shade400,
          ),
        ),
      ),
      body: Stack(
        children: [
          ListView(
            children: [
              Container(
                margin: const EdgeInsets.only(left: 8, right: 8, top: 4, bottom: 8),
                padding: const EdgeInsets.only(bottom: 16),
                decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(
                      width: 2,
                      color: Colors.pink.shade400,
                    )),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const AuditHead(
                        title: 'Quick Audit',
                        subtitle: 'Share a quick safety score with camera.'),
                    Divider(
                      color: Colors.pink.shade400,
                    ),
                    imageInitialized
                        ? Center(
                            child: IconButton(
                              icon: Icon(
                                Icons.photo_camera,
                                color: Colors.grey.shade600,
                                size: 32,
                              ),
                              onPressed: getImageCamera, //take photo
                            ),
                          )
                        : Center(
                            child: IconButton(
                              icon: Icon(
                                Icons.add_a_photo_outlined,
                                color: Colors.pink.shade400,
                                size: 30,
                              ),
                              onPressed: getImageCamera, //take photo
                            ),
                          ),
                    const SizedBox(
                      height: 8,
                    ),
                    imageInitialized
                        ? Center(
                            child: ElevatedButton(
                              style: ButtonStyle(
                                  backgroundColor: WidgetStatePropertyAll(
                                      Colors.pink.shade400)),
                              onPressed: _sendImageMessage,
                              child: const Text(
                                'Submit',
                                style: TextStyle(
                                  color: Colors.white,
                                ),
                              ),
                            ),
                          )
                        : Center(
                            child: ElevatedButton(
                              style: ButtonStyle(
                                  backgroundColor: WidgetStatePropertyAll(
                                      Colors.grey.shade600)),
                              onPressed: () {
                                Fluttertoast.showToast(
                                    msg: "Take an outdoor image first.");
                              },
                              child: const Text(
                                'Submit',
                                style: TextStyle(
                                  color: Colors.white,
                                ),
                              ),
                            ),
                          )
                  ],
                ),
              ),

              SizedBox(
                height: 22,
                width: 16,
                child: Center(
                  child: Text(
                    "OR",
                    style: TextStyle(
                        color: Colors.pink.shade400,
                        fontSize: 16,
                        fontWeight: FontWeight.w600,
                        fontFamily: 'Mulish'),
                  ),
                ),
              ),

              Container(
                margin: const EdgeInsets.only(left: 8, right: 8, top: 4, bottom: 8),
                padding: const EdgeInsets.only(bottom: 16),
                decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(
                      width: 2,
                      color: Colors.pink.shade400,
                    )),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const AuditHead(
                        title: 'Manual Audit',
                        subtitle: 'Share a manually filled safety score.'),
                    Divider(
                      color: Colors.pink.shade400,
                    ),
                    const AuditHead(
                        title: 'Lighting',
                        subtitle: 'Brightness of light around you?'),
                    AuditIconRow(
                      onPressedCallback: (level) =>
                          updateAuditData('lighting', level),
                      mapData: auditData,
                      mapString: 'lighting',
                      iconLv1: Icons.wb_incandescent_outlined,
                      iconLv2: Icons.wb_incandescent_outlined,
                      iconLv3: Icons.wb_incandescent_rounded,
                      iconLv4: Icons.wb_incandescent_rounded,
                      labelLv1: 'None',
                      labelLv2: 'Little',
                      labelLv3: 'Enough',
                      labelLv4: 'Bright',
                    ),
                    Container(
                      padding: const EdgeInsets.all(16),
                      child: Divider(
                        color: Colors.pink.shade400,
                      ),
                    ),
                    const AuditHead(
                        title: 'WalkPath',
                        subtitle: 'Road or pavement quality?'),
                    AuditIconRow(
                      mapData: auditData,
                      mapString: 'walkpath',
                      onPressedCallback: (level) =>
                          updateAuditData('walkpath', level),
                      iconLv1: Icons.remove_road_rounded,
                      iconLv2: Icons.remove_road_rounded,
                      iconLv3: Icons.add_road_rounded,
                      iconLv4: Icons.add_road_rounded,
                      labelLv1: 'None',
                      labelLv2: 'Poor',
                      labelLv3: 'Fair',
                      labelLv4: 'Good',
                    ),
                    Container(
                      padding: const EdgeInsets.all(16),
                      child: Divider(
                        color: Colors.pink.shade400,
                      ),
                    ),
                    const AuditHead(
                        title: 'Openness',
                        subtitle: 'Spacious or congested area?'),
                    AuditIconRow(
                      mapData: auditData,
                      mapString: 'openness',
                      onPressedCallback: (level) =>
                          updateAuditData('openness', level),
                      iconLv1: Icons.width_normal_rounded,
                      iconLv2: Icons.width_normal_rounded,
                      iconLv3: Icons.width_wide_rounded,
                      iconLv4: Icons.width_wide_rounded,
                      labelLv1: 'Very Bad',
                      labelLv2: 'Bad',
                      labelLv3: 'Enough',
                      labelLv4: 'Spacious',
                    ),
                    Container(
                      padding: const EdgeInsets.all(16),
                      child: Divider(
                        color: Colors.pink.shade400,
                      ),
                    ),
                    const AuditHead(
                        title: 'Crowd', subtitle: 'People count around you?'),
                    AuditIconRow(
                      mapData: auditData,
                      mapString: 'crowd',
                      onPressedCallback: (level) =>
                          updateAuditData('crowd', level),
                      iconLv1: Icons.person,
                      iconLv2: Icons.person,
                      iconLv3: Icons.people,
                      iconLv4: Icons.people,
                      labelLv1: 'None',
                      labelLv2: 'Less',
                      labelLv3: 'Enough',
                      labelLv4: 'Many',
                    ),
                    Container(
                      padding: const EdgeInsets.all(16),
                      child: Divider(
                        color: Colors.pink.shade400,
                      ),
                    ),
                    const AuditHead(
                        title: 'Diversity',
                        subtitle: 'Presence of women and children around you?'),
                    AuditIconRow(
                      mapData: auditData,
                      mapString: 'diversity',
                      onPressedCallback: (level) =>
                          updateAuditData('diversity', level),
                      iconLv1: Icons.person,
                      iconLv2: Icons.person,
                      iconLv3: Icons.people,
                      iconLv4: Icons.people,
                      labelLv1: 'Minimal',
                      labelLv2: 'Somewhat',
                      labelLv3: 'Fair',
                      labelLv4: 'Enough',
                    ),
                    Container(
                      padding: const EdgeInsets.all(16),
                      child: Divider(
                        color: Colors.pink.shade400,
                      ),
                    ),
                    const AuditHead(
                        title: 'Security',
                        subtitle: 'Police or alternatives around you?'),
                    AuditIconRow(
                      mapData: auditData,
                      mapString: 'security',
                      onPressedCallback: (level) =>
                          updateAuditData('security', level),
                      iconLv1: Icons.policy_outlined,
                      iconLv2: Icons.policy_rounded,
                      iconLv3: Icons.local_police_outlined,
                      iconLv4: Icons.local_police_rounded,
                      labelLv1: 'None',
                      labelLv2: 'Bad',
                      labelLv3: 'Good',
                      labelLv4: 'Great',
                    ),
                    Container(
                      padding: const EdgeInsets.all(8),
                      child: Divider(
                        color: Colors.pink.shade400,
                      ),
                    ),
                    const AuditHead(
                        title: 'Transport',
                        subtitle: 'Distance to nearest local transport?'),
                    AuditIconRow(
                      mapData: auditData,
                      mapString: 'transport',
                      onPressedCallback: (level) =>
                          updateAuditData('transport', level),
                      iconLv1: Icons.bus_alert_outlined,
                      iconLv2: Icons.bus_alert_outlined,
                      iconLv3: Icons.train_outlined,
                      iconLv4: Icons.train_rounded,
                      labelLv1: 'Unavailable',
                      labelLv2: 'Distant',
                      labelLv3: 'Nearby',
                      labelLv4: 'Very close',
                    ),
                    Container(
                      padding: const EdgeInsets.all(8),
                      child: Divider(
                        color: Colors.pink.shade400,
                      ),
                    ),
                    const AuditHead(
                        title: 'Feeling', subtitle: 'How do you feel here?'),
                    AuditIconRow(
                      mapData: auditData,
                      mapString: 'feeling',
                      onPressedCallback: (level) =>
                          updateAuditData('feeling', level),
                      iconLv1: Icons.exposure_minus_1_rounded,
                      iconLv2: Icons.exposure_zero_rounded,
                      iconLv3: Icons.exposure_plus_1_rounded,
                      iconLv4: Icons.exposure_plus_2_rounded,
                      labelLv1: 'Scared',
                      labelLv2: 'Unsafe',
                      labelLv3: 'Safe',
                      labelLv4: 'Great',
                    ),
                    Container(
                      padding: const EdgeInsets.all(8),
                      child: Divider(
                        color: Colors.pink.shade400,
                      ),
                    ),
                    const SizedBox(
                      height: 8,
                    ),
                    (auditData.length == 8)
                        ? Center(
                            child: ElevatedButton(
                              style: ButtonStyle(
                                  backgroundColor: WidgetStatePropertyAll(
                                      Colors.pink.shade400)),
                              onPressed: () async {
                                debugPrint(auditData.toString());
                                // auditData.addAll({
                                //   "lat": position.latitude,
                                //   "lng": position.longitude
                                // });

                                _sendChatMessage(auditData);
                              },
                              child: const Text(
                                'Submit',
                                style: TextStyle(
                                  color: Colors.white,
                                ),
                              ),
                            ),
                          )
                        : Center(
                            child: ElevatedButton(
                              style: ButtonStyle(
                                  backgroundColor: WidgetStatePropertyAll(
                                      Colors.grey.shade600)),
                              onPressed: () {
                                Fluttertoast.showToast(
                                    msg:
                                        "Please fill all the details");
                              },
                              child: const Text(
                                'Submit',
                                style: TextStyle(
                                  color: Colors.white,
                                ),
                              ),
                            ),
                          ),
                  ],
                ),
              ),

              // Container(
              //   padding: EdgeInsets.all(8),
              //   child: Divider(),
              // ),
            ],
          ),
          _loading
              ? BackdropFilter(
                  filter: ImageFilter.blur(sigmaX: 20, sigmaY: 20),
                  child: Center(
                    child: CircularProgressIndicator(
                      color: Colors.pink.shade400,
                    ),
                  ),
                )
              : Container(),
        ],
      ),
    );
  }
}

class AuditHead extends StatelessWidget {
  final String title;
  final String subtitle;
  const AuditHead({super.key, required this.title, required this.subtitle});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            margin: const EdgeInsets.only(bottom: 4),
            child: Text(
              title,
              style: const TextStyle(
                  fontSize: 18,
                  fontFamily: 'Mulish',
                  fontWeight: FontWeight.w500),
            ),
          ),
          Text(
            subtitle,
            style: const TextStyle(
              fontSize: 14,
              fontFamily: 'Mulish',
            ),
          ),
        ],
      ),
    );
  }
}

class AuditIconRow extends StatefulWidget {
  final Map<String, dynamic> mapData;
  final String mapString;
  final IconData iconLv1;
  final IconData iconLv2;
  final IconData iconLv3;
  final IconData iconLv4;
  final String labelLv1;
  final String labelLv2;
  final String labelLv3;
  final String labelLv4;
  final Function(int level) onPressedCallback;
  const AuditIconRow(
      {super.key,
      required this.iconLv1,
      required this.iconLv2,
      required this.iconLv3,
      required this.iconLv4,
      required this.labelLv1,
      required this.labelLv2,
      required this.labelLv3,
      required this.labelLv4,
      required this.mapString,
      required this.mapData,
      required this.onPressedCallback});

  @override
  State<AuditIconRow> createState() => _AuditIconRowState();
}

class _AuditIconRowState extends State<AuditIconRow> {
  int _selectedLevel = 0; // Stores the currently selected level

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceAround,
        children: [
          Column(
            children: [
              ColorChangingIcon(
                icon: widget.iconLv1,
                onPressed: () {
                  setState(() {
                    _selectedLevel = 1;
                  });
                  widget.onPressedCallback(1);
                },
                isSelected: _selectedLevel == 1, // Pass isSelected flag
              ),
              Text(widget.labelLv1),
            ],
          ),
          Column(
            children: [
              ColorChangingIcon(
                icon: widget.iconLv2,
                onPressed: () {
                  setState(() {
                    _selectedLevel = 2;
                  });
                  widget.onPressedCallback(2);
                },
                isSelected: _selectedLevel == 2, // Pass isSelected flag
              ),
              Text(widget.labelLv2),
            ],
          ),
          Column(
            children: [
              ColorChangingIcon(
                icon: widget.iconLv3,
                onPressed: () {
                  setState(() {
                    _selectedLevel = 3;
                  });
                  widget.onPressedCallback(3);
                },
                isSelected: _selectedLevel == 3, // Pass isSelected flag
              ),
              Text(widget.labelLv3),
            ],
          ),
          Column(
            children: [
              ColorChangingIcon(
                icon: widget.iconLv4,
                onPressed: () {
                  setState(() {
                    _selectedLevel = 4;
                  });
                  widget.onPressedCallback(4);
                },
                isSelected: _selectedLevel == 4, // Pass isSelected flag
              ),
              Text(widget.labelLv4),
            ],
          ),
        ],
      ),
    );
  }
}

class ColorChangingIcon extends StatelessWidget {
  final IconData icon;
  final Color initialColor = Colors.grey.shade800;
  final Color pressedColor = Colors.pink.shade400;
  final VoidCallback onPressed;
  final bool isSelected;

  ColorChangingIcon({
    super.key,
    required this.icon,
    required this.onPressed,
    this.isSelected = false,
  });

  @override
  Widget build(BuildContext context) {
    return IconButton(
      icon: Icon(
        size: 28,
        icon,
        color: isSelected ? pressedColor : initialColor,
      ),
      onPressed: () {
        onPressed();
      },
    );
  }
}
