import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:ivox/features/auth/presentation/login_page.dart';
import 'package:ivox/features/auth/services/auth_service.dart';
import 'package:ivox/features/notifications/notification_service.dart';
import 'package:ivox/main_page.dart';
import 'package:ivox/shared/utils/my_button.dart';
import 'package:ivox/shared/utils/my_icon_tile.dart';
import 'package:ivox/shared/utils/my_textfield.dart';
import 'package:lottie/lottie.dart';

class RegisterPage extends StatefulWidget {
  const RegisterPage({super.key});

  @override
  State<RegisterPage> createState() => _RegisterPageState();
}

class _RegisterPageState extends State<RegisterPage> {
  final _key = GlobalKey<FormState>();
  final _usernameController = TextEditingController();
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  bool isObscure = true;
  final _authService = AuthService();
  String? errorMessage;
  bool isLoading = false;

  @override
  void dispose() {
    // TODO: implement dispose
    super.dispose();
    _usernameController.dispose();
    _emailController.dispose();
    _passwordController.dispose();
  }

  void register() async {
    if (_usernameController.text.trim().isEmpty ||
        _emailController.text.trim().isEmpty ||
        _passwordController.text.trim().isEmpty) {
      setState(() {
        errorMessage = "Veuillez remplir tous les champs";
      });
      return;
    }

    setState(() {
      isLoading = true;
      errorMessage = null;
    });

    try {
      await _authService.signUpWithEmailAndPassword(
        _emailController.text.trim(),
        _passwordController.text.trim(),
        _usernameController.text.trim(),
      );
      await NotificationService().saveUserFcmToken();
      if (mounted) {
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(builder: (context) => MainPage()),
        );
      }
    } on FirebaseAuthException catch (e) {
      String message;
      switch (e.code) {
        case 'weak-password':
          message = 'Le mot de passe est trop faible';
          break;
        case 'email-already-in-use':
          message = 'Cet e-mail est déjà utilisé';
          break;
        case 'invalid-email':
          message = 'L\'adresse e-mail est invalide';
          break;
        default:
          message = 'Erreur: ${e.message}';
      }
      setState(() {
        errorMessage = message;
        isLoading = false;
      });
    } catch (e) {
      setState(() {
        errorMessage = 'Une erreur est survenue: $e';
        isLoading = false;
      });
    }
  }

  void signInWithGoogle() async {
    setState(() {
      isLoading = true;
      errorMessage = null;
    });

    try {
      await _authService.signInWithGoogle();
      await NotificationService().saveUserFcmToken();
      if (mounted) {
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(builder: (context) => MainPage()),
        );
      }
    } catch (e) {
      setState(() {
        errorMessage = 'Erreur connexion Google: $e';
        isLoading = false;
      });
    }
  }

  void signInWithFacebook() async {
    setState(() {
      isLoading = true;
      errorMessage = null;
    });

    try {
      await _authService.signInWithFacebook();
      await NotificationService().saveUserFcmToken();
      if (mounted) {
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(builder: (context) => MainPage()),
        );
      }
    } catch (e) {
      setState(() {
        errorMessage = 'Erreur connexion Facebook: $e';
        isLoading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      resizeToAvoidBottomInset: true,
      appBar: AppBar(
        elevation: 0,
        leading: IconButton(
          onPressed: () {
            Navigator.pop(context);
          },
          icon: Icon(Icons.arrow_back_ios),
        ),
        title: Text(
          "Créer un compte",
          style: TextStyle(
            fontWeight: FontWeight.bold,
            fontSize: 28,
            letterSpacing: 2,
            color: Colors.amber[600],
          ),
        ),
        centerTitle: true,
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 16.0),
          physics: BouncingScrollPhysics(),
          child: Column(
            children: [
              LottieBuilder.asset(
                "assets/lotties/Stress Management.json",
                height: 200,
              ),
              Form(
                key: _key,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    MyTextfield(
                      text: "Nom d'utilisateur",
                      controller: _usernameController,
                      icon: Icon(Icons.person),
                      isObscure: false,
                    ),
                    MyTextfield(
                      text: "E-mail",
                      controller: _emailController,
                      icon: Icon(Icons.email),
                      isObscure: false,
                    ),
                    MyTextfield(
                      text: "Mot de passe",
                      controller: _passwordController,
                      icon: Icon(Icons.lock),
                      isObscure: isObscure,
                      sicon: IconButton(
                        onPressed: () {
                          setState(() {
                            isObscure = !isObscure;
                          });
                        },
                        icon: isObscure
                            ? Icon(Icons.visibility_off)
                            : Icon(Icons.visibility),
                      ),
                    ),
                    if (errorMessage != null)
                      Padding(
                        padding: const EdgeInsets.only(top: 8.0),
                        child: Text(
                          errorMessage!,
                          style: TextStyle(
                            color: Colors.red,
                            fontSize: 14,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                      ),
                    SizedBox(height: 12),
                    MyButton(
                      text: isLoading ? "Chargement..." : "S'inscrire",
                      onTap: isLoading ? () {} : register,
                    ),
                    const SizedBox(height: 12),
                    Row(
                      children: [
                        Expanded(
                          child: Divider(thickness: 1, color: Colors.grey),
                        ),
                        Padding(
                          padding: const EdgeInsets.symmetric(horizontal: 8.0),
                          child: Text(
                            "Or continue with",
                            style: TextStyle(fontWeight: FontWeight.w600),
                          ),
                        ),
                        Expanded(
                          child: Divider(thickness: 1, color: Colors.grey),
                        ),
                      ],
                    ),
                    SizedBox(height: 12),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Expanded(
                          child: MyIconTile(
                            name: "google.png",
                            onTap: isLoading ? () {} : signInWithGoogle,
                            title: 'Google',
                          ),
                        ),
                        SizedBox(width: 25),
                        Expanded(
                          child: MyIconTile(
                            name: "facebook.png",
                            onTap: isLoading ? () {} : signInWithFacebook,
                            title: 'facebook',
                          ),
                        ),
                      ],
                    ),
                    SizedBox(height: 20),
                    GestureDetector(
                      onTap: () => Navigator.push(
                        context,
                        MaterialPageRoute(builder: (context) => LoginPage()),
                      ),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Text(
                            "Vous avez déja un compte ?",
                            style: TextStyle(fontWeight: FontWeight.w600),
                          ),
                          SizedBox(width: 6),
                          Text(
                            "Connecter-vous",
                            style: TextStyle(
                              color: Colors.blue,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
