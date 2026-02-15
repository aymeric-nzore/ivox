import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

class XpService {
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  int xpRequired(int level) {
    return 100 + level * 25;
  }

  //Ajoutez de l'xp
  Future<void> addXp(int xpToAdd) async {
    final currentUser = _auth.currentUser;
    final userDoc = _firestore.collection("users").doc(currentUser?.uid);

    //recup les infos du doc firestore
    final snapshot = await userDoc.get();
    int currentXp = snapshot['xp'];
    int totalXp = snapshot['totalXp'];
    int currentLvl = snapshot['level'];

    //Gain d'xp
    currentXp += xpToAdd;
    totalXp += xpToAdd;
    //Evoluer en lvl
    if (currentXp >= xpRequired(currentLvl)) {
      currentXp -= xpRequired(currentLvl);
      currentLvl++;
    }
    //Update to firestore
    await userDoc.update({
      'xp': currentXp,
      'totalXp': totalXp,
      'level': currentLvl,
    });
  }
}
