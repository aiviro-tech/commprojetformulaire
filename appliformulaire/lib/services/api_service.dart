
import 'package:dio/dio.dart';
import 'package:flutter/foundation.dart';

class ApiService {
  static const String baseUrl = 'http://192.168.56.1:8000/api';

  static final Dio dio = Dio(
    BaseOptions(
      baseUrl: baseUrl,
      connectTimeout: const Duration(seconds: 30),
      receiveTimeout: const Duration(seconds: 30),
      headers: {
        'Accept': 'application/json',
        'Content-Type': 'application/json',
      },
    ),
  )..interceptors.add(LogInterceptor(
      requestBody: true,
      responseBody: true,
      logPrint: (obj) => debugPrint(obj.toString()),
    ));

  // Stocker le token
  static void setToken(String token) {
    dio.options.headers['Authorization'] = 'Bearer $token';
    debugPrint('Token configuré: $token');
  }

  // Inscription
  static Future<Map<String, dynamic>> register({
    required String firstName,
    required String lastName,
    required String email,
    required String password,
  }) async {
    try {
      debugPrint('Envoi inscription: $email');
      
      final response = await dio.post(
        '/register',
        data: {
          'first_name': firstName,
          'last_name': lastName,
          'email': email,
          'password': password,
          'password_confirmation': password,
        },
      );

      debugPrint('Réponse inscription: ${response.statusCode}');
      
      if (response.statusCode == 201) {
        final data = response.data;
        if (data['token'] != null) {
          setToken(data['token']);
        }
        return data;
      } else {
        throw Exception(response.data['message'] ?? 'Erreur inscription');
      }
    } on DioException catch (e) {
      debugPrint('Erreur Dio: ${e.type}');
      debugPrint('Message: ${e.message}');
      debugPrint('Response: ${e.response?.data}');
      
      if (e.response != null) {
        final errorData = e.response!.data;
        if (errorData is Map && errorData['message'] != null) {
          throw Exception(errorData['message']);
        } else if (errorData is Map && errorData['errors'] != null) {
          final errors = errorData['errors'] as Map;
          final firstError = errors.values.first;
          throw Exception(firstError is List ? firstError.first : firstError);
        }
      }
      
      // Erreurs réseau
      if (e.type == DioExceptionType.connectionTimeout) {
        throw Exception('Délai de connexion dépassé. Vérifiez votre serveur Laravel.');
      } else if (e.type == DioExceptionType.receiveTimeout) {
        throw Exception('Délai de réception dépassé.');
      } else if (e.type == DioExceptionType.connectionError) {
        throw Exception('Impossible de se connecter au serveur. Vérifiez l\'URL et que Laravel tourne.');
      }
      
      throw Exception('Erreur réseau: ${e.message}');
    } catch (e) {
      debugPrint('Erreur inattendue: $e');
      throw Exception('Erreur inattendue: $e');
    }
  }

  // Vérification email après inscription
  static Future<Map<String, dynamic>> verifyEmail({
    required String email,
    required String code,
  }) async {
    try {
      debugPrint('Vérification code pour: $email');
      
      final response = await dio.post(
        '/verify-email',
        data: {
          'email': email,
          'code': code,
        },
      );

      debugPrint('Code vérifié: ${response.statusCode}');
      return response.data;
    } on DioException catch (e) {
      debugPrint('Erreur vérification code: ${e.response?.data}');
      
      if (e.response != null && e.response!.data['message'] != null) {
        throw Exception(e.response!.data['message']);
      }
      throw Exception('Erreur de vérification');
    }
  }

  // Connexion
  static Future<Map<String, dynamic>> login({
    required String email,
    required String password,
  }) async {
    try {
      debugPrint('Connexion: $email');
      
      final response = await dio.post(
        '/login',
        data: {
          'email': email,
          'password': password,
        },
      );

      debugPrint('Connexion réussie: ${response.statusCode}');
      
      if (response.statusCode == 200) {
        final data = response.data;
        if (data['token'] != null) {
          setToken(data['token']);
        }
        return data;
      } else {
        throw Exception(response.data['message'] ?? 'Erreur connexion');
      }
    } on DioException catch (e) {
      debugPrint('Erreur connexion: ${e.response?.data}');
      
      if (e.response != null && e.response!.data['message'] != null) {
        throw Exception(e.response!.data['message']);
      }
      
      if (e.type == DioExceptionType.connectionError) {
        throw Exception('Impossible de se connecter au serveur');
      }
      
      throw Exception('Erreur de connexion');
    }
  }

  // Mot de passe oublié - Demande du code OTP
  static Future<Map<String, dynamic>> forgotPassword({
    required String email,
  }) async {
    try {
      debugPrint(' Demande réinitialisation: $email');
      
      final response = await dio.post(
        '/forgot-password',
        data: {'email': email},
      );

      debugPrint('Code OTP envoyé');
      return response.data;
    } on DioException catch (e) {
      debugPrint('Erreur mot de passe oublié: ${e.response?.data}');
      
      if (e.response != null && e.response!.data['message'] != null) {
        throw Exception(e.response!.data['message']);
      }
      throw Exception('Erreur lors de l\'envoi du code');
    }
  }

  // Réinitialisation du mot de passe
  static Future<Map<String, dynamic>> resetPassword({
    required String email,
    required String otpCode,
    required String password,
  }) async {
    try {
      debugPrint('Réinitialisation mot de passe: $email');
      
      final response = await dio.post(
        '/reset-password',
        data: {
          'email': email,
          'otp_code': otpCode,
          'password': password,
          'password_confirmation': password,
        },
      );

      debugPrint('Mot de passe réinitialisé');
      return response.data;
    } on DioException catch (e) {
      debugPrint(' Erreur réinitialisation: ${e.response?.data}');
      
      if (e.response != null && e.response!.data['message'] != null) {
        throw Exception(e.response!.data['message']);
      }
      throw Exception('Erreur lors de la réinitialisation');
    }
  }

  // Déconnexion
  static Future<void> logout() async {
    try {
      await dio.post('/logout');
      dio.options.headers.remove('Authorization');
      debugPrint('Déconnexion réussie');
    } on DioException catch (e) {
      debugPrint('Erreur déconnexion: ${e.message}');
      // On supprime quand même le token localement
      dio.options.headers.remove('Authorization');
    }
  }

  // Renvoyer le code de vérification d'inscription
  static Future<Map<String, dynamic>> resendVerificationCode({
    required String email,
  }) async {
    try {
      debugPrint('Renvoi code vérification: $email');
      
      final response = await dio.post(
        '/resend-verification-code',
        data: {'email': email},
      );

      debugPrint('Code de vérification renvoyé');
      return response.data;
    } on DioException catch (e) {
      debugPrint('Erreur renvoi code: ${e.response?.data}');
      
      if (e.response != null && e.response!.data['message'] != null) {
        throw Exception(e.response!.data['message']);
      }
      throw Exception('Erreur lors du renvoi du code');
    }
  }

  // Renvoyer le code de réinitialisation
  static Future<Map<String, dynamic>> resendResetCode({
    required String email,
  }) async {
    try {
      debugPrint(' Renvoi code réinitialisation: $email');
      
      final response = await dio.post(
        '/resend-reset-code',
        data: {'email': email},
      );

      debugPrint(' Code de réinitialisation renvoyé');
      return response.data;
    } on DioException catch (e) {
      debugPrint(' Erreur renvoi code: ${e.response?.data}');
      
      if (e.response != null && e.response!.data['message'] != null) {
        throw Exception(e.response!.data['message']);
      }
      throw Exception('Erreur lors du renvoi du code');
    }
  }
}
