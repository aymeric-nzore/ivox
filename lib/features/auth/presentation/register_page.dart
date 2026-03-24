import 'package:flutter/material.dart';
import 'package:ivox/features/auth/presentation/login_page.dart';
import 'package:ivox/features/auth/services/api_auth_service.dart';
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
  final _apiAuthService = ApiAuthService();

  bool isObscure = true;
  bool isLoading = false;
  String? errorMessage;

  @override
  void dispose() {
    _usernameController.dispose();
    _emailController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  Future<void> register() async {
    if (_usernameController.text.trim().isEmpty ||
        _emailController.text.trim().isEmpty ||
        _passwordController.text.trim().isEmpty) {
      setState(() {
        errorMessage = 'Veuillez remplir tous les champs';
      });
      return;
    }

    setState(() {
      isLoading = true;
      errorMessage = null;
    });

    try {
      await _apiAuthService.register(
        username: _usernameController.text.trim(),
        email: _emailController.text.trim(),
        password: _passwordController.text.trim(),
      );
      if (!mounted) return;
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(
          builder: (context) => const MainPage(startTutorial: true),
        ),
      );
    } catch (e) {
      if (!mounted) return;
      setState(() {
        errorMessage = e.toString().replaceFirst('Exception: ', '');
        isLoading = false;
      });
    }
  }

  Future<void> signInWithGoogle() async {
    setState(() {
      isLoading = true;
      errorMessage = null;
    });

    try {
      await _apiAuthService.signInWithGoogle();
      if (!mounted) return;
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(
          builder: (context) => const MainPage(startTutorial: true),
        ),
      );
    } catch (e) {
      if (!mounted) return;
      setState(() {
        errorMessage = 'Erreur connexion Google: $e';
        isLoading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final screenWidth = MediaQuery.sizeOf(context).width;
    final isSmall = screenWidth < 360;
    final lottieHeight = isSmall ? 150.0 : 200.0;

    return Scaffold(
      resizeToAvoidBottomInset: true,
      appBar: AppBar(
        elevation: 0,
        leading: IconButton(
          onPressed: () => Navigator.pop(context),
          icon: const Icon(Icons.arrow_back_ios),
        ),
        title: Text(
          'Creer un compte',
          style: TextStyle(
            fontWeight: FontWeight.bold,
            fontSize: isSmall ? 22 : 28,
            letterSpacing: 2,
            color: Colors.amber[600],
          ),
        ),
        centerTitle: true,
      ),
      body: SafeArea(
        child: Stack(
          children: [
            IgnorePointer(
              ignoring: isLoading,
              child: SingleChildScrollView(
                padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 16.0),
                physics: const BouncingScrollPhysics(),
                child: Center(
                  child: ConstrainedBox(
                    constraints: const BoxConstraints(maxWidth: 520),
                    child: Column(
                      children: [
                        LottieBuilder.asset(
                          'assets/lotties/Stress Management.json',
                          height: lottieHeight,
                        ),
                        Form(
                          key: _key,
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.stretch,
                            children: [
                              MyTextfield(
                                text: 'Nom utilisateur',
                                controller: _usernameController,
                                icon: const Icon(Icons.person),
                                isObscure: false,
                              ),
                              MyTextfield(
                                text: 'E-mail',
                                controller: _emailController,
                                icon: const Icon(Icons.email),
                                isObscure: false,
                              ),
                              MyTextfield(
                                text: 'Mot de passe',
                                controller: _passwordController,
                                icon: const Icon(Icons.lock),
                                isObscure: isObscure,
                                sicon: IconButton(
                                  onPressed: () {
                                    setState(() {
                                      isObscure = !isObscure;
                                    });
                                  },
                                  icon: isObscure
                                      ? const Icon(Icons.visibility_off)
                                      : const Icon(Icons.visibility),
                                ),
                              ),
                              if (errorMessage != null)
                                Padding(
                                  padding: const EdgeInsets.only(top: 8.0),
                                  child: Text(
                                    errorMessage!,
                                    style: const TextStyle(
                                      color: Colors.red,
                                      fontSize: 14,
                                      fontWeight: FontWeight.w500,
                                    ),
                                  ),
                                ),
                              const SizedBox(height: 12),
                              MyButton(
                                text: isLoading ? 'Chargement...' : 'S inscrire',
                                onTap: isLoading ? () {} : register,
                              ),
                              const SizedBox(height: 12),
                              Row(
                                children: const [
                                  Expanded(
                                    child: Divider(thickness: 1, color: Colors.grey),
                                  ),
                                  Padding(
                                    padding: EdgeInsets.symmetric(horizontal: 8.0),
                                    child: Text(
                                      'Ou continuer avec',
                                      style: TextStyle(fontWeight: FontWeight.w600),
                                    ),
                                  ),
                                  Expanded(
                                    child: Divider(thickness: 1, color: Colors.grey),
                                  ),
                                ],
                              ),
                              const SizedBox(height: 12),
                              Row(
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                  Expanded(
                                    child: MyIconTile(
                                      name: 'google.png',
                                      onTap: isLoading ? () {} : signInWithGoogle,
                                      title: 'Google',
                                    ),
                                  ),
                                ],
                              ),
                              const SizedBox(height: 20),
                              GestureDetector(
                                onTap: () => Navigator.push(
                                  context,
                                  MaterialPageRoute(
                                    builder: (context) => const LoginPage(),
                                  ),
                                ),
                                child: Wrap(
                                  alignment: WrapAlignment.center,
                                  crossAxisAlignment: WrapCrossAlignment.center,
                                  children: const [
                                    Text(
                                      'Vous avez deja un compte ?',
                                      style: TextStyle(fontWeight: FontWeight.w600),
                                    ),
                                    SizedBox(width: 6),
                                    Text(
                                      'Connectez-vous',
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
              ),
            ),
            if (isLoading)
              Positioned.fill(
                child: ColoredBox(
                  color: Colors.black26,
                  child: const Center(
                    child: CircularProgressIndicator(),
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }
}
