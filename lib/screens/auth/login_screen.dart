import 'package:flutter/material.dart';
// import 'package:rakshak/globalScaffold/global_scaffold.dart';
import 'package:rakshak/globalscaffold/global_scaffold.dart';
import 'package:rakshak/screens/auth/register_screen.dart';
import 'package:rakshak/screens/services/google_auth.dart';
import 'package:rakshak/widgets/sign_in_button.dart';

class LoginScreen extends StatelessWidget {
  const LoginScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SafeArea(
        child: Container(
          clipBehavior: Clip.hardEdge,
          decoration: BoxDecoration(
            border: Border.all(
            color: Colors.pink.shade400,
            width: 10.0,            
            ),
          ),
          child: Center(
            child: Padding(
              padding: const EdgeInsets.all(60.0),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Image.asset(
                    'assets/images/logo.png',
                    width: 250,
                    height: 190,
                  ),
                  // const SizedBox(height: 10),
                  SignInButton(
                    buttontext: ("Sign In with Google"),
                    iconImage: const AssetImage('assets/images/googlelogo.png'),
                    onPressed: () {
                      // TODO: Implement Google Sign-In and remove Navigator.push in favor of StreamBuilder in SplashScreen
                      print("Google Sign-In button pressed");
                      GoogleAuth.signIn();
                      
                      // Navigator.push(
                      //     context,
                      //     MaterialPageRoute(
                      //         builder: (context) => const GlobalScaffold()));

                    },
                  ),
                  const SizedBox(height: 10),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      const TextButton(
                        onPressed: null,
                        child: Text('Not Registered?'),
                      ),
                      TextButton(
                        child: const Text("Register"),
                        onPressed: () => Navigator.push(
                            context,
                            MaterialPageRoute(
                                builder: (context) => const RegisterScreen())),
                      )
                    ],
                  ),
                ],
              ),
            ),
          ),
      ),
    ),
    );    
  }
}
