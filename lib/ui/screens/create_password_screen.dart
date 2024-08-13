import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:password/ui/screens/homepage.dart';
import 'package:shared_preferences/shared_preferences.dart';

class CreatePasswordScreen extends StatefulWidget {
  const CreatePasswordScreen({super.key});

  @override
  State<CreatePasswordScreen> createState() => _CreatePasswordScreenState();
}

class _CreatePasswordScreenState extends State<CreatePasswordScreen>
    with SingleTickerProviderStateMixin {
  int passwordLength = 0;
  String password = '';
  List<ValueNotifier<bool>> buttonStates =
      List.generate(12, (_) => ValueNotifier(false));
  late AnimationController _controller;
  late Animation<double> _scaleAnimation;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      duration: const Duration(milliseconds: 200),
      vsync: this,
    );
    _scaleAnimation = Tween<double>(begin: 1.0, end: 1.2).animate(
      CurvedAnimation(parent: _controller, curve: Curves.easeInOut),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text(
          "Create a Password",
          style: TextStyle(color: Colors.white),
        ),
        centerTitle: true,
        backgroundColor: Colors.deepPurpleAccent,
        elevation: 0,
      ),
      body: Padding(
        padding: const EdgeInsets.symmetric(vertical: 60),
        child: Column(
          children: [
            SvgPicture.asset(
              "assets/icons/lock.svg",
              height: 100,
              color: Colors.deepPurpleAccent,
            ),
            const SizedBox(height: 40),
            _buildPasswordIndicator(),
            const SizedBox(height: 40),
            _buildNumberPad(),
          ],
        ),
      ),
    );
  }

  Widget _buildPasswordIndicator() {
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: List.generate(
        4,
        (index) {
          return Padding(
            padding: const EdgeInsets.symmetric(horizontal: 10),
            child: AnimatedBuilder(
              animation: _controller,
              builder: (context, child) {
                return Transform.scale(
                  scale: passwordLength > index ? _scaleAnimation.value : 1.0,
                  child: Container(
                    height: 24,
                    width: 24,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      color: index < passwordLength
                          ? Colors.deepPurpleAccent
                          : Colors.white,
                      border: Border.all(
                        color: index < passwordLength
                            ? Colors.deepPurpleAccent
                            : Colors.black12,
                        width: 2,
                      ),
                    ),
                  ),
                );
              },
            ),
          );
        },
      ),
    );
  }

  Widget _buildNumberPad() {
    return Expanded(
      child: GridView.builder(
        physics: const NeverScrollableScrollPhysics(),
        padding: const EdgeInsets.symmetric(horizontal: 70),
        itemCount: 12,
        gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
          crossAxisCount: 3,
          mainAxisSpacing: 20,
          crossAxisSpacing: 20,
        ),
        itemBuilder: (context, index) {
          if (index == 9) {
            return const SizedBox();
          }
          if (index == 10) {
            return _buildDigitButton(index: 0, stateIndex: index);
          }
          if (index == 11) {
            return _buildBackspaceButton(stateIndex: index);
          }
          return _buildDigitButton(index: index + 1, stateIndex: index);
        },
      ),
    );
  }

  Widget _buildDigitButton({required int index, required int stateIndex}) {
    return InkWell(
      onTapDown: (_) {
        buttonStates[stateIndex].value = true;
        _controller.forward();
      },
      onTapCancel: () {
        buttonStates[stateIndex].value = false;
        _controller.reverse();
      },
      onTapUp: (_) {
        buttonStates[stateIndex].value = false;
        _controller.reverse();
        _onDigitPressed(index, stateIndex);
      },
      borderRadius: BorderRadius.circular(16),
      splashColor: Colors.deepPurpleAccent.withOpacity(0.3),
      child: ValueListenableBuilder<bool>(
        valueListenable: buttonStates[stateIndex],
        builder: (context, isPressed, child) {
          return Container(
            alignment: Alignment.center,
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(16),
              color: Colors.white,
              border: Border.all(color: Colors.deepPurpleAccent),
              boxShadow: [
                if (isPressed)
                  BoxShadow(
                    color: Colors.deepPurpleAccent.withOpacity(0.4),
                    blurRadius: 10,
                    offset: const Offset(0, 4),
                  ),
              ],
            ),
            child: Text(
              '$index',
              style: TextStyle(
                fontSize: 28,
                fontWeight: FontWeight.bold,
                color: isPressed ? Colors.deepPurpleAccent : Colors.black54,
              ),
            ),
          );
        },
      ),
    );
  }

  Widget _buildBackspaceButton({required int stateIndex}) {
    return InkWell(
      onTap: _onBackspacePressed,
      splashColor: Colors.deepPurpleAccent.withOpacity(0.3),
      borderRadius: BorderRadius.circular(16),
      child: const Icon(
        Icons.backspace_outlined,
        size: 28,
        color: Colors.black54,
      ),
    );
  }

  void _onDigitPressed(int digit, int stateIndex) async {
    if (passwordLength < 4) {
      setState(() {
        password += digit.toString();
        passwordLength++;
      });
      if (passwordLength == 4) {
        final prefs = await SharedPreferences.getInstance();
        await prefs.setString("password", password);
        await prefs.setBool("isPasswordEnabled", true);

        Navigator.of(context).pushAndRemoveUntil(
          CupertinoPageRoute(builder: (context) => const Homepage()),
          (route) => false,
        );
      }
    }
  }

  void _onBackspacePressed() {
    if (passwordLength > 0) {
      setState(() {
        password = password.substring(0, passwordLength - 1);
        passwordLength--;
      });
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
