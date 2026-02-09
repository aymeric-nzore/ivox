import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_facebook_auth/flutter_facebook_auth.dart';
import 'package:google_sign_in/google_sign_in.dart';
import 'package:ivox/core/services/supabase_service.dart';

class AuthService {
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final SupabaseService _supabaseService = SupabaseService();

  User? getUser() {
    return _auth.currentUser;
  }

  Stream<DocumentSnapshot<Map<String, dynamic>>> userDocStream() {
    final user = getUser();
    if (user == null) {
      return const Stream.empty();
    }
    return _firestore.collection("users").doc(user.uid).snapshots();
  }

  //Email
  //Inscription
  Future<UserCredential> signUpWithEmailAndPassword(
    String email,
    String password,
    String username,
  ) async {
    UserCredential userCredential = await _auth.createUserWithEmailAndPassword(
      email: email,
      password: password,
    );
    //Envoyez à firestore
    await _firestore.collection("users").doc(userCredential.user!.uid).set({
      'uid': userCredential.user!.uid,
      'username': username,
      'email': email,
      'timestamp': Timestamp.now(),
    });
    return userCredential;
  }

  //CONNEXION
  Future<UserCredential> signInWithEmailAndPassword(
    String email,
    String password,
  ) async {
    UserCredential userCredential = await _auth.signInWithEmailAndPassword(
      email: email,
      password: password,
    );
    return userCredential;
  }

  //Google
  Future<UserCredential> signInWithGoogle() async {
    // Get the GoogleSignIn instance (singleton in v7.x)
    final GoogleSignIn googleSignIn = GoogleSignIn.instance;
    
    // Trigger the authentication flow (replaces signIn() in v7.x)
    final GoogleSignInAccount googleUser = await googleSignIn.authenticate();

    // Obtenir les détails d'authentification (idToken only in v7.x)
    final GoogleSignInAuthentication googleAuth = googleUser.authentication;

    // Get access token from authorization client for Firebase
    final GoogleSignInClientAuthorization? authorization =
        
        await googleUser.authorizationClient.authorizationForScopes([
      'email',
      'profile',
    ]);

    // Créer les credentials
    final credential = GoogleAuthProvider.credential(
      accessToken: authorization?.accessToken,
      idToken: googleAuth.idToken,
    );

    // Se connecter avec Firebase
    UserCredential userCredential = await _auth.signInWithCredential(
      credential,
    );

    // Enregistrer/mettre à jour l'utilisateur dans Firestore
    final userDoc = await _firestore
        .collection("users")
        .doc(userCredential.user!.uid)
        .get();

    if (!userDoc.exists) {
      await _firestore.collection("users").doc(userCredential.user!.uid).set({
        'uid': userCredential.user!.uid,
        'username': googleUser.displayName ?? 'User',
        'email': googleUser.email,
        'photoUrl': googleUser.photoUrl,
        'timestamp': Timestamp.now(),
      });
    }

    return userCredential;
  }

  //Facebook
  Future<UserCredential> signInWithFacebook() async {
    // Déclencher le flux d'authentification
    final LoginResult loginResult = await FacebookAuth.instance.login();

    if (loginResult.status != LoginStatus.success) {
      throw Exception("Connexion Facebook échouée");
    }

    // Obtenir le token d'accès
    final OAuthCredential facebookAuthCredential =
        FacebookAuthProvider.credential(loginResult.accessToken!.tokenString);

    // Se connecter avec Firebase
    UserCredential userCredential = await _auth.signInWithCredential(
      facebookAuthCredential,
    );

    // Obtenir les infos du profil Facebook
    final userData = await FacebookAuth.instance.getUserData();

    // Enregistrer/mettre à jour l'utilisateur dans Firestore
    final userDoc = await _firestore
        .collection("users")
        .doc(userCredential.user!.uid)
        .get();

    if (!userDoc.exists) {
      await _firestore.collection("users").doc(userCredential.user!.uid).set({
        'uid': userCredential.user!.uid,
        'username': userData['name'] ?? 'User',
        'email': userData['email'] ?? userCredential.user!.email,
        'photoUrl': userData['picture']?['data']?['url'],
        'timestamp': Timestamp.now(),
      });
    }

    return userCredential;
  }

  Future<void> updateUsername(String username) async {
    final user = getUser();
    if (user == null) throw Exception("Utilisateur non connecté");
    await _firestore.collection("users").doc(user.uid).update({
      'username': username,
      'updatedAt': Timestamp.now(),
    });
  }

  Future<void> updatePhotoUrl(String photoUrl) async {
    final user = getUser();
    if (user == null) throw Exception("Utilisateur non connecté");
    await _firestore.collection("users").doc(user.uid).update({
      'photoUrl': photoUrl,
      'updatedAt': Timestamp.now(),
    });
  }

  Future<String> uploadProfileImage({
    required Uint8List bytes,
    required String fileName,
  }) async {
    final user = getUser();
    if (user == null) throw Exception("Utilisateur non connecté");

    return await _supabaseService.uploadProfileImage(
      bytes: bytes,
      userId: user.uid,
      fileName: fileName,
    );
  }

  //DECONNEXION
  Future<void> logout() async {
    await _auth.signOut();
  }
}
