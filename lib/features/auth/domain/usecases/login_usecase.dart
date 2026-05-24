import '../entities/user.dart';
import '../repositories/auth_repository.dart';

class LoginUseCase {
  const LoginUseCase(this._repository);

  final AuthRepository _repository;

  Future<User> call({required String phone, required String password}) {
    return _repository.login(phone: phone, password: password);
  }
}
