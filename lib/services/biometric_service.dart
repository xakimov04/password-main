import 'package:local_auth/local_auth.dart';

class BiometricService {
  Future<bool> checkBiometrics() async {
    final localAuthentication = LocalAuthentication();
    return await localAuthentication.canCheckBiometrics;
  }
}
