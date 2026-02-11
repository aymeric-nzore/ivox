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
    final current_user = _auth.currentUser;
    final user_doc = _firestore.collection("users").doc(current_user?.uid);

    //recup les infos du doc firestore
    final snapshot = await user_doc.get();
    int current_xp = snapshot['xp'];
    int totalXp = snapshot['totalXp'];
    int current_lvl = snapshot['level'];

    //Gain d'xp
    current_xp += xpToAdd;
    totalXp += xpToAdd;
    //Evoluer en lvl
    if (current_xp >= xpRequired(current_lvl)) {
      current_xp -= xpRequired(current_lvl);
      current_lvl++;
    }
    //Update to firestore
    await user_doc.update({
      'xp': current_xp,
      'totalXp': totalXp,
      'level': current_lvl,
    });
  }
}
