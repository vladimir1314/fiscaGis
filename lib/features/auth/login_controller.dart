import 'package:fiscagis/core/config/app_config.dart';
import 'package:fiscagis/core/services/http_provider.dart';
import 'package:fiscagis/features/auth/models/login_request.dart';

class LoginController {
  final HttpProvider _httpProvider = HttpProvider();

  Future<bool> login(String username, String password) async {
    try {
      final request = LoginRequest(
        usuario: username,
        clave: password,
        idSistema: AppConfig.idSistema,
      );

      // El endpoint debe comenzar sin barra inicial si baseUrl no termina en barra,
      // pero HttpProvider maneja la concatenación.
      // Asumiendo 'movil/security/singin' como solicitaste.
      final response = await _httpProvider.post(
        'movil/security/singin',
        body: request.toJson(),
      );

      // Validar respuesta exitosa. Ajusta según la estructura real de tu API.
      // Si no lanza excepción, asumimos éxito por ahora.
      if (response != null) {
        return true;
      }
      return false;
    } catch (e) {
      rethrow;
    }
  }
}