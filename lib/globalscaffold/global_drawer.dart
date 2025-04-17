import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';

class GlobalDrawer extends StatefulWidget {
  final String name;
  final String email;
  const GlobalDrawer({super.key, required this.name, required this.email});

  @override
  State<GlobalDrawer> createState() => _GlobalDrawerState();
}

class _GlobalDrawerState extends State<GlobalDrawer> {
  @override
  void initState() {
    super.initState();
  }

  @override
  Widget build(BuildContext context) {
    return Drawer(
      width: MediaQuery.of(context).size.width * 0.85,
      child: Container(
        color: Colors.grey.shade50,
        child: Column(
          children: [
            DrawerHeader(name: widget.name, email: widget.email),
            const SizedBox(
              height: 10,
            ),
            ListTile(
              contentPadding:
                  const EdgeInsets.symmetric(horizontal: 18, vertical: 4),
              leading: const Icon(Icons.account_circle_outlined),
              title: const Text('Account'),
              trailing: const Icon(
                Icons.navigate_next_rounded,
              ),
              onTap: () {
                Navigator.of(context).pushNamed('/account');
              },
            ),
            ListTile(
              contentPadding:
                  const EdgeInsets.symmetric(horizontal: 18, vertical: 4),
              leading: const Icon(Icons.settings_outlined),
              title: const Text('Settings'),
              trailing: const Icon(Icons.navigate_next_rounded),
              onTap: () {
                Navigator.of(context).pushNamed('/settings');
              },
            ),
            ListTile(
              contentPadding:
                  const EdgeInsets.symmetric(horizontal: 18, vertical: 4),
              leading: const Icon(Icons.tour_outlined),
              title: const Text('Tour'),
              trailing: const Icon(Icons.navigate_next_rounded),
              onTap: () {
                Navigator.of(context).pushNamed('/tour');
              },
            ),
            ListTile(
              contentPadding:
                  const EdgeInsets.symmetric(horizontal: 18, vertical: 4),
              leading: const Icon(Icons.logout_outlined),
              title: const Text('Log Out'),
              trailing: const Icon(
                Icons.navigate_next_rounded,
              ),
              onTap: () {
                FirebaseAuth.instance.signOut();
              },
            ),
            const Spacer(),
            const DrawerFooter(),
          ],
        ),
      ),
    );
  }
}

class DrawerHeader extends StatelessWidget {
  final String name;
  final String email;
  DrawerHeader({super.key, required this.name, required this.email});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: MediaQuery.of(context).size.width,
      padding: const EdgeInsets.only(top: 16),
      height: 180,
      color: Colors.pink.shade400,
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          DrawerHeaderAvatar(),
          Text(
            name,
            style: TextStyle(
              fontFamily: 'Mulish',
              fontSize: 16,
              color: Colors.white,
            ),
          ),
          Text(
            email,
            style: TextStyle(
              fontFamily: 'Mulish',
              fontSize: 16,
              color: Colors.white,
            ),
          ),
        ],
      ),
    );
  }
}

class DrawerHeaderAvatar extends StatelessWidget {
  const DrawerHeaderAvatar({super.key});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(10),
      margin: const EdgeInsets.all(6),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(50),
        border: Border.all(width: 1, color: Colors.white),
      ),
      child: const Icon(
        Icons.person,
        size: 50,
        color: Colors.white,
      ),
    );
  }
}

class DrawerFooter extends StatelessWidget {
  const DrawerFooter({super.key});

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 100,
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [Colors.grey.shade50, Colors.grey.shade200],
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
        ),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Image.asset(
            'assets/images/nobgsafetylogo.png',
            width: 64,
            height: 64,
            isAntiAlias: true,
          ),
          const SizedBox(
            width: 12,
          ),
          const Text(
            'rakshak',
            style: TextStyle(
                fontFamily: 'Mulish',
                fontSize: 32,
                fontWeight: FontWeight.w700),
          )
        ],
      ),
    );
  }
}
