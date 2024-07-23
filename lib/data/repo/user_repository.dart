import '../models/user_model.dart';
import '../providers/firebase_auth_provider.dart';

class UserRepository {
  final FirebaseAuthProvider _firebaseAuthProvider;

  UserRepository(this._firebaseAuthProvider);

  Future<UserModel?> signInWithEmailAndPassword(
      String email, String password) async {
    final user =
        await _firebaseAuthProvider.signInWithEmailAndPassword(email, password);
    return user != null ? UserModel.fromFirebaseUser(user) : null;
  }

  Future<void> signOut() async {
    await _firebaseAuthProvider.signOut();
  }
}
