
import 'package:flutter/material.dart';
import 'package:rakshak/screens/home/audit_page.dart';
import 'package:rakshak/screens/sidenav/account_page.dart';
import 'package:rakshak/screens/sidenav/logout_page.dart';
import 'package:rakshak/screens/sidenav/settings_page.dart';
import 'package:rakshak/screens/sidenav/tour_page.dart';

class RouteGenerator {
  static Route<dynamic> generateRoute(RouteSettings settings) {
    // final args = settings.arguments; //To take in arguments while routing
    switch (settings.name) {

      case '/account':
        return MaterialPageRoute(builder: (_) => const AccountPage()); //For Account Page

      case '/settings':
        return MaterialPageRoute(builder: (_) => const SettingsPage()); //For Settings Page

      case '/tour':
        return MaterialPageRoute(builder: (_) => const TourPage()); //For Tour Page

      case '/logout':
        return MaterialPageRoute(builder: (_) => const LogOutPage()); //For Log-Out Page

      case '/audit':
        return MaterialPageRoute(builder: (_) => const AuditPage()); //For Log-Out Page
        
      default:
        return _errorRoute();
    }
  }
}

Route<dynamic> _errorRoute() {
  return MaterialPageRoute(
    builder: (_) {
      return Scaffold(
        appBar: AppBar(
          title: const Text('Error'),
        ),
        body: const Center(
          child: Text('ERROR'),
        ),
      );
    },
  );
}