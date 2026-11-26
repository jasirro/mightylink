import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';
import 'package:google_sign_in/google_sign_in.dart';
import 'package:hive_flutter/hive_flutter.dart';
import '../firebase_options.dart';
import 'db_service.dart';

class FirebaseAuthService {
  static const String googleServerClientId =
      '804361650910-tcap2sac0395159jhq1h280498tgr7f9.apps.googleusercontent.com';
  static FirebaseAuth? _auth;
  static String? initializationError;

  static User? get currentUser => _auth?.currentUser;

  static Future<void> init() async {
    try {
      await Firebase.initializeApp(
        options: DefaultFirebaseOptions.currentPlatform,
      );
      _auth = FirebaseAuth.instance;
      initializationError = null;
    } on FirebaseException catch (error) {
      initializationError = error.message ?? error.code;
      debugPrint('Firebase initialization failed: $initializationError');
    } on PlatformException catch (error) {
      initializationError =
          error.message?.contains('Failed to load FirebaseOptions') == true
          ? 'Firebase is not configured for this app. Add the Firebase project '
                'configuration for Android and rebuild.'
          : error.message ?? 'Firebase initialization failed (${error.code}).';
      debugPrint(
        'Firebase initialization failed (${error.code}): ${error.message}',
      );
    }
  }

  static FirebaseAuth get _firebaseAuth {
    final auth = _auth;
    if (auth == null) {
      throw StateError(
        initializationError ?? 'Firebase Authentication is not initialized.',
      );
    }
    return auth;
  }

  static Future<UserCredential> signInWithEmail({
    required String email,
    required String password,
  }) {
    return _firebaseAuth.signInWithEmailAndPassword(
      email: email.trim(),
      password: password,
    );
  }

  static Future<UserCredential> registerWithEmail({
    required String email,
    required String password,
    required String displayName,
  }) async {
    final credential = await _firebaseAuth.createUserWithEmailAndPassword(
      email: email.trim(),
      password: password,
    );
    await credential.user?.updateDisplayName(displayName.trim());
    await credential.user?.reload();
    return credential;
  }

  static Future<UserCredential> signInWithGoogle() async {
    if (googleServerClientId.isEmpty) {
      throw StateError(
        'Google sign-in needs the Web OAuth client ID. '
        'Configure GOOGLE_SERVER_CLIENT_ID and rebuild.',
      );
    }

    final googleSignIn = GoogleSignIn.instance;
    if (!googleSignIn.supportsAuthenticate()) {
      throw UnsupportedError(
        'Google sign-in is not supported on this platform.',
      );
    }

    final googleUser = await googleSignIn.authenticate(
      scopeHint: const ['email'],
    );
    final idToken = googleUser.authentication.idToken;
    if (idToken == null) {
      throw StateError('Google did not provide an ID token.');
    }

    final authorization = await googleUser.authorizationClient
        .authorizationForScopes(const ['email']);
    final credential = GoogleAuthProvider.credential(
      idToken: idToken,
      accessToken: authorization?.accessToken,
    );
    return _firebaseAuth.signInWithCredential(credential);
  }

  static Future<void> saveUserSession(User user) async {
    final userId = user.email ?? user.uid;
    DbService.activeUser = userId;
    final authBox = Hive.box('auth');
    await authBox.put('isLoggedIn', true);
    await authBox.put(
      'currentUser',
      user.displayName ?? user.email ?? user.uid,
    );
    await authBox.put('currentUserId', userId);
    await DbService.openUserBoxes(userId);
  }

  static Future<void> signOut() async {
    await _firebaseAuth.signOut();
    await GoogleSignIn.instance.signOut();
    final authBox = Hive.box('auth');
    await authBox.put('isLoggedIn', false);
    await authBox.put('currentUser', '');
    await authBox.put('currentUserId', '');
  }
}
