import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';
import 'package:local_auth/local_auth.dart';

/// Biometric service supporting Fingerprint, Face ID, and device credentials
/// with seamless PIN fallback for the MightyLink Secure Vault.
class BiometricService {
  static final LocalAuthentication _auth = LocalAuthentication();

  /// Checks if biometric or device credential authentication is supported on this device.
  static Future<bool> isBiometricAvailable() async {
    try {
      final bool canCheck = await _auth.canCheckBiometrics;
      final bool isSupported = await _auth.isDeviceSupported();
      return canCheck || isSupported;
    } on PlatformException catch (e) {
      debugPrint('Biometric availability check error: $e');
      return false;
    } catch (e) {
      debugPrint('Biometric error: $e');
      return false;
    }
  }

  /// Retrieves list of enrolled biometric types (fingerprint, face, etc.)
  static Future<List<BiometricType>> getAvailableBiometrics() async {
    try {
      return await _auth.getAvailableBiometrics();
    } on PlatformException catch (e) {
      debugPrint('Get biometrics error: $e');
      return [];
    } catch (_) {
      return [];
    }
  }

  /// Triggers the system biometric authentication dialog
  static Future<bool> authenticate({
    String reason = 'Scan fingerprint or Face ID to unlock MightyLink Secure Vault',
  }) async {
    try {
      final bool didAuthenticate = await _auth.authenticate(
        localizedReason: reason,
        options: const AuthenticationOptions(
          stickyAuth: true,
          biometricOnly: false,
        ),
      );
      return didAuthenticate;
    } on PlatformException catch (e) {
      debugPrint('Biometric authentication exception: $e');
      return false;
    } catch (e) {
      debugPrint('Biometric general exception: $e');
      return false;
    }
  }
}
