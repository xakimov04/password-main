import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:local_auth/local_auth.dart';
import 'package:password/services/biometric_service.dart';
import 'package:password/ui/screens/homepage.dart';
import 'package:shared_preferences/shared_preferences.dart';

class PasswordScreen extends StatefulWidget {
  const PasswordScreen({super.key});

  @override
  State<PasswordScreen> createState() => _PasswordScreenState();
}

class _PasswordScreenState extends State<PasswordScreen>
    with SingleTickerProviderStateMixin {
  int password = 0;
  String passKey = '';
  bool isEnabled = false;
  List<ValueNotifier<bool>> buttonStates =
      List.generate(12, (_) => ValueNotifier(false));

  late AnimationController _controller;
  late Animation<double> _animation;

  @override
  void initState() {
    super.initState();
    checkBiometrics();

    // Initialize animation controller
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 200),
    );

    // Define animation
    _animation = Tween<double>(begin: 1.0, end: 1.2).animate(
      CurvedAnimation(parent: _controller, curve: Curves.easeInOut),
    );
  }

  void checkBiometrics() async {
    isEnabled = await BiometricService().checkBiometrics();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text(
          "Enter Password",
          style: TextStyle(color: Colors.black87),
        ),
        backgroundColor: Colors.white,
        elevation: 1,
        iconTheme: const IconThemeData(color: Colors.black87),
      ),
      body: Padding(
        padding: const EdgeInsets.only(top: 140.0),
        child: Column(
          children: [
            SvgPicture.asset("assets/icons/lock.svg"),
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: List.generate(4, (index) {
                return Padding(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 15,
                    vertical: 30,
                  ),
                  child: AnimatedBuilder(
                    animation: _controller,
                    builder: (context, child) {
                      return Transform.scale(
                        scale: password > index ? _animation.value : 1.0,
                        child: Container(
                          height: 24,
                          width: 24,
                          decoration: BoxDecoration(
                            borderRadius: BorderRadius.circular(6),
                            color: password > index
                                ? Colors.green
                                : Colors.transparent,
                            border: password > index
                                ? null
                                : Border.all(color: Colors.black12),
                          ),
                        ),
                      );
                    },
                  ),
                );
              }),
            ),
            Expanded(
              child: GridView.builder(
                padding: const EdgeInsets.symmetric(horizontal: 60),
                itemCount: 12,
                gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                  crossAxisCount: 3,
                  mainAxisSpacing: 30,
                  crossAxisSpacing: 30,
                ),
                itemBuilder: (context, index) {
                  if (index == 9) {
                    return _buildBiometricButton();
                  }

                  if (index == 10) {
                    return _buildDigitButton(index: 0, stateIndex: index);
                  }

                  if (index == 11) {
                    return _buildBackspaceButton();
                  }

                  return _buildDigitButton(index: index + 1, stateIndex: index);
                },
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildBiometricButton() {
    return InkWell(
      onTap: () {
        isEnabled
            ? LocalAuthentication()
                .authenticate(
                localizedReason: "Authenticate to open the app",
                options: const AuthenticationOptions(
                  biometricOnly: true,
                  stickyAuth: true,
                  useErrorDialogs: true,
                ),
              )
                .then(
                (value) {
                  if (value) {
                    Navigator.of(context).pushReplacement(
                      CupertinoPageRoute(
                        builder: (context) => const Homepage(),
                      ),
                    );
                  }
                },
              )
            : null;
      },
      borderRadius: BorderRadius.circular(50),
      child: Padding(
        padding: const EdgeInsets.all(15.0),
        child: SvgPicture.asset("assets/icons/finger.svg"),
      ),
    );
  }

  Widget _buildBackspaceButton() {
    return InkWell(
      onTap: () {
        if (password > 0) {
          setState(() {
            password--;
            passKey = passKey.substring(0, password);
            _controller.reverse();
          });
        }
      },
      splashColor: const Color(0xffDDF6E1),
      borderRadius: BorderRadius.circular(50),
      child: const Icon(
        Icons.backspace_outlined,
        color: Color(0xff727782),
      ),
    );
  }

  Widget _buildDigitButton({required int index, required int stateIndex}) {
    return InkWell(
      onTapDown: (details) {
        buttonStates[stateIndex].value = true;
      },
      onTapCancel: () {
        buttonStates[stateIndex].value = false;
      },
      onTapUp: (details) async {
        buttonStates[stateIndex].value = false;
        if (password < 4) {
          setState(() {
            password++;
            passKey += index.toString();
            _controller.forward(from: 0);

            if (password == 4) {
              _validatePassword();
            }
          });
        }
      },
      borderRadius: BorderRadius.circular(16),
      splashColor: const Color(0xffDDF6E1),
      child: ValueListenableBuilder<bool>(
        valueListenable: buttonStates[stateIndex],
        builder: (context, value, child) {
          return Container(
            alignment: Alignment.center,
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(16),
              border: Border.all(
                color: const Color(0xfff2f2f2),
              ),
            ),
            child: Text(
              '$index',
              style: TextStyle(
                fontSize: 28,
                fontWeight: FontWeight.bold,
                color: value ? Colors.green : const Color(0xff727782),
              ),
            ),
          );
        },
      ),
    );
  }

  void _validatePassword() async {
    final shared = await SharedPreferences.getInstance();
    final prefPass = shared.getString("password");
    if (prefPass == passKey) {
      Navigator.of(context).pushAndRemoveUntil(
        CupertinoPageRoute(
          builder: (context) => const Homepage(),
        ),
        (route) => false,
      );
    } else {
      // Handle incorrect password (optional)
      passKey = '';
      password = 0;
      setState(() {});
    }
  }

  @override
  void dispose() {
    for (var notifier in buttonStates) {
      notifier.dispose();
    }
    _controller.dispose();
    super.dispose();
  }
}
