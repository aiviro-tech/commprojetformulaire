import 'package:dio/dio.dart';

import 'package:flutter/foundation.dart'; // pour debugPrint



class ApiService {

  // Ton IP locale + port du serveur Laravel

  static const String baseUrl = 'http://192.168.56.1:8000/api';



  // Instance Dio

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

  );



  // Ajouter le token (après login ou register)

  static void setToken(String token) {

    dio.options.headers['Authorization'] = 'Bearer $token';

  }



  // Inscription

  static Future<Map<String, dynamic>> register({

    required String firstName,

    required String lastName,

    required String email,

    required String password,

  }) async {

    try {

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



      if (response.statusCode == 201) {

        final data = response.data;

        final token = data['token'];

        setToken(token); // On stocke le token pour les futures requêtes

        debugPrint('Inscription réussie : $data');

        return data;

      } else {

        throw Exception('Erreur inscription : ${response.data['message']}');

      }

    } on DioException catch (e) {

      final errorMessage = e.response?.data['message'] ?? 'Erreur réseau';

      throw Exception(errorMessage);

    }

  }



  // Connexion (login)

  static Future<Map<String, dynamic>> login({

    required String email,

    required String password,

  }) async {

    try {

      final response = await dio.post(

        '/login',

        data: {

          'email': email,

          'password': password,

        },

      );



      if (response.statusCode == 200) {

        final data = response.data;

        final token = data['token'];

        setToken(token);

        debugPrint('Connexion réussie : $data');

        return data;

      } else {

        throw Exception('Erreur connexion');

      }

    } on DioException catch (e) {

      final errorMessage = e.response?.data['message'] ?? 'Erreur réseau';

      throw Exception(errorMessage);

    }

  }

}