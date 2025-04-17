import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:curved_navigation_bar/curved_navigation_bar.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:rakshak/globalScaffold/global_app_bar.dart';
import 'package:rakshak/globalScaffold/global_drawer.dart';
import 'package:rakshak/screens/bot/bot_screen.dart';
import 'package:rakshak/screens/chat/chat_screen.dart';
import 'package:rakshak/screens/chat/comm_tab.dart';
import 'package:rakshak/screens/feed/create_post.dart';
import 'package:rakshak/screens/home/home_screen.dart';
import 'package:rakshak/screens/navigate/navigate_screen.dart';
import 'package:rakshak/screens/feed/feed_screen.dart';

class GlobalScaffold extends StatefulWidget {
  const GlobalScaffold({super.key});

  @override
  State<GlobalScaffold> createState() => _GlobalScaffoldState();
}

class _GlobalScaffoldState extends State<GlobalScaffold> {
  int _initialIndex = 0;
  String name = "";
  String email = "";
  bool isLoading = true;

  final List<Widget> _screens = [
    const HomeScreen(),
    const NavigateScreen(),
    const FeedScreen(),
    const CommuncationTabs(),
  ];
  void navigateBottomBar(int index) {
    setState(() {
      _initialIndex = index;
    });
  }

  Future<void> initializeHeader() async {
    String uid = await FirebaseAuth.instance.currentUser!.uid;
    DocumentSnapshot doc =
        await FirebaseFirestore.instance.collection("userData").doc(uid).get();

    final map = doc.data() as Map;
    setState(() {
      name = map["fname"] + " " + map["lname"];
      email = map["email"];
      isLoading = false;
    });
  }

  @override
  void initState() {
    super.initState();
    initializeHeader();
  }

  @override
  Widget build(BuildContext context) {
    return (isLoading == false)
        ? Scaffold(
            drawer: GlobalDrawer(
              name: name,
              email: email,
            ),
            appBar: (_initialIndex == 0)
                ? const GlobalAppBar(
                    title: 'Home',
                    action: SizedBox(),
                    subTitle: 'Activate our services',
                  )
                : (_initialIndex == 1)
                    ? const GlobalAppBar(
                        title: 'Navigate',
                        action: SizedBox(),
                        subTitle: 'Find places near you',
                      )
                    : (_initialIndex == 2)
                        ? GlobalAppBar(
                            title: 'Feed',
                            action: Container(
                              decoration: BoxDecoration(
                                  color: Colors.pink,
                                  borderRadius: BorderRadius.circular(10)),
                              child: IconButton(
                                  onPressed: () {
                                    Navigator.push(
                                        context,
                                        MaterialPageRoute(
                                            builder: (context) =>
                                                const CreatePost()));
                                  },
                                  icon: Icon(Icons.add)),
                            ),
                            subTitle: 'Share your experiences',
                          )
                        : const GlobalAppBar(
                            action: SizedBox(),
                            title: 'Communications',
                            subTitle: 'Talk to fellow users',
                          ),
            body: _screens[_initialIndex],
            floatingActionButton: FloatingActionButton(
              backgroundColor: Colors.pink,
              child: Image(
                image: AssetImage("assets/images/bot.jpeg"),
                height: MediaQuery.of(context).size.height * 0.09,
                // width: MediaQuery.of(context).size.width*0.05,
              ),
              onPressed: () {
                Navigator.push(context,
                    MaterialPageRoute(builder: (context) => BotScreen()));
              },
            ),
            bottomNavigationBar: Container(
              color: Colors.grey.shade100,
              padding: const EdgeInsets.only(top: 8),
              child: CurvedNavigationBar(
                items: const <Widget>[
                  Icon(
                    Icons.home_rounded,
                    color: Colors.white,
                  ),
                  Icon(
                    Icons.navigation_rounded,
                    color: Colors.white,
                  ),
                  Icon(
                    Icons.feed_rounded,
                    color: Colors.white,
                  ),
                  Icon(
                    Icons.chat_bubble_rounded,
                    color: Colors.white,
                  ),
                ],
                onTap: navigateBottomBar,
                height: 50,
                color: Colors.pink.shade400,
                backgroundColor: Colors.grey.shade100,
              ),
            ),
          )
        : Container(
            color: Colors.white,
            child: Center(
              child: CircularProgressIndicator(
                color: Colors.pink.shade400,
              ),
            ),
          );
  }
}
