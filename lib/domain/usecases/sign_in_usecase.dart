import 'package:secret_contact/data/repo/user_repository.dart';

import '../../data/models/user_model.dart';

class SignInUseCase {
  final UserRepository repository;

  SignInUseCase(this.repository);

  Future<UserModel?> execute(String email, String password) async {
    return await repository.signInWithEmailAndPassword(email, password);
  }
}
