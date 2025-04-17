import 'package:flutter/material.dart';
import 'package:fluttertoast/fluttertoast.dart';
import 'package:url_launcher/url_launcher.dart';

class NavigateScreen extends StatefulWidget {
  const NavigateScreen({super.key});

  @override
  State<NavigateScreen> createState() => _NavigateScreenState();
}

class _NavigateScreenState extends State<NavigateScreen> {
  @override
  Widget build(BuildContext context) {
    return Container(
      color: Colors.grey.shade100,
      child: ListView(
        children: [
          NavigateScreenContainers(
            title: 'Police Stations',
            color: Colors.yellow.shade200,
            iconName: 'police',
            api:
                "https://www.google.com/maps/search/?api=1&query=Police Stations near me",
          ),
          NavigateScreenContainers(
            title: 'Hospitals',
            color: Colors.green.shade200,
            iconName: 'hospital',
            api:
                "https://www.google.com/maps/search/?api=1&query=Hospitals near me",
          ),
          NavigateScreenContainers(
            title: 'Pharmacies',
            color: Colors.purple.shade200,
            iconName: 'pharmacy',
            api:
                "https://www.google.com/maps/search/?api=1&query=Pharmacies near me",
          ),
          NavigateScreenContainers(
            title: 'Bus Stops',
            color: Colors.red.shade200,
            iconName: 'bus',
            api:
                "https://www.google.com/maps/search/?api=1&query=Bus Stops near me",
          ),
        ],
      ),
    );
  }
}

// ignore: must_be_immutable
class NavigateScreenContainers extends StatelessWidget {
  final String title;
  Color color;
  final String api;
  final String iconName;
  NavigateScreenContainers(
      {super.key,
      required this.title,
      required this.iconName,
      required this.color,
      required this.api});

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.all(12),
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(12),
        color: color,
      ),
      child: Row(
        children: [
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                title,
                style: TextStyle(
                    color: Colors.grey.shade900,
                    fontWeight: FontWeight.w600,
                    fontSize: 20),
              ),
              ElevatedButton(
                onPressed: () async {
                  try {
                    await launchUrl(Uri.parse(api));
                  } catch (e) {
                    print(e);
                    Fluttertoast.showToast(msg: "Something went wrong!");
                  }
                },
                style: ButtonStyle(
                  elevation: const WidgetStatePropertyAll(0),
                  shape: WidgetStatePropertyAll(
                    RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                ),
                child: const Text(
                  'View',
                  style: TextStyle(color: Colors.black),
                ),
              )
            ],
          ),
          const Spacer(),
          Padding(
            padding: const EdgeInsets.only(bottom: 8),
            child: Image.asset(
              "assets/images/$iconName.png",
              width: 100,
              height: 100,
            ),
          )
        ],
      ),
    );
  }
}
