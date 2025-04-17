import 'package:flutter/material.dart';
import 'package:rakshak/screens/auth/login_screen.dart';
import 'package:rakshak/screens/services/google_auth.dart';
import 'package:rakshak/widgets/sign_in_button.dart';

class RegisterScreen extends StatefulWidget {
  const RegisterScreen({super.key});

  @override
  State<RegisterScreen> createState() => _RegisterScreenState();
}

class _RegisterScreenState extends State<RegisterScreen> {

  final TextEditingController _fnameController = TextEditingController();
  final TextEditingController _lnameController = TextEditingController();
  final TextEditingController _phnoController = TextEditingController();

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      child: Scaffold(      
          body: Container(
            clipBehavior: Clip.hardEdge,
            decoration: BoxDecoration(
              border: Border.all(
              color: Colors.pink.shade400,
              width: 10.0,            
              ),
            ),
            child: Center(
              child: SingleChildScrollView(
                child: Padding(
                  padding: const EdgeInsets.symmetric(vertical: 20, horizontal: 40),
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.start,
                    children: [
                      Image.asset(
                        'assets/images/logo.png',
                        width: 250,
                        height: 190,
                      ),
                      // const SizedBox(height: 10),
                      TextFormField(
                        controller: _fnameController,
                        decoration: const InputDecoration(
                          border: OutlineInputBorder(),
                          labelText: 'First Name',
                          
                        ),
                      ),
                      SizedBox(height: 10),
                      TextFormField(
                        controller: _lnameController,
                        decoration: InputDecoration(
                          border: OutlineInputBorder(),
                          labelText: 'Last Name',
                        ),
                      ),
                      SizedBox(height: 10),
                      TextFormField(
                        controller: _phnoController,
                        decoration: InputDecoration(
                          border: OutlineInputBorder(),
                          labelText: 'Phone No.',
                        ),
                      ),
                      SizedBox(height: 10),
                      SignInButton(
                        buttontext: ("Sign Up with Google"),
                        iconImage: const AssetImage('assets/images/googlelogo.png'),
                        onPressed: () async {
                          // TODO: Implement Google Sign-In and remove Navigator.push in favor of StreamBuilder in SplashScreen
                          
                          final e = await GoogleAuth.signUp(
                            fname: _fnameController.text,
                            lname: _lnameController.text,
                            phno: _phnoController.text,
                          );
                      
                          if(!context.mounted) return;

                          if(e != null){
                            ScaffoldMessenger.of(context).showSnackBar(
                              SnackBar(content: Text(e)),
                            );
                          }
                      
                          // if(e == null){
                          //   print("Google Sign-Up button pressed");
                          //   Navigator.push(
                          //       context,
                          //       MaterialPageRoute(
                          //           builder: (context) => const GlobalScaffold()));
                          // } else {
                          //   ScaffoldMessenger.of(context).showSnackBar(
                          //     SnackBar(content: Text(e)),
                          //   );
                          // }
                      
                        },
                      ),
                      const SizedBox(height: 10),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        
                        children: [
                          const TextButton(
                            onPressed: null,
                            child: Text('Already Registered?'),
                          ),
                          TextButton(
                            child: const Text("Login"),
                            onPressed: () {
                              Navigator.push(
                                context,
                                MaterialPageRoute(
                                    builder: (context) => const LoginScreen()));
                            }
                          )
                        ],
                      ),
                    ],
                  ),
                ),
              ),
            ),
        ),
      ),
    );
        
  }
}