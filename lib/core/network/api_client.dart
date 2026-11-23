import 'package:dio/dio.dart';
import 'package:flutter/foundation.dart' show kDebugMode;

import '../constants/app_constants.dart';
import '../errors/exceptions.dart';
import '../storage/local_storage.dart';
import 'data_refresh.dart';

/// Client HTTP partagé. Ajoute le jeton d'accès et convertit les erreurs Dio
/// en exceptions de la couche data.
///
/// Format d'erreur du backend :
/// `{"status": 400, "message": "Bad Request", "error": "Données invalides", "details": {"nom": "must not be blank"}}`
class ApiClient {
  ApiClient(this._storage)
    : _dio = Dio(
        BaseOptions(
          baseUrl: AppConstants.apiBaseUrl,
          connectTimeout: const Duration(seconds: 20),
          receiveTimeout: const Duration(seconds: 30),
          contentType: Headers.jsonContentType,
        ),
      ) {
    _dio.interceptors.add(
      InterceptorsWrapper(
        onRequest: (options, handler) {
          final token = _storage.getString(LocalStorage.keyToken);
          if (token != null) options.headers['Authorization'] = 'Bearer $token';
          handler.next(options);
        },
      ),
    );
  }

  final Dio _dio;
  final LocalStorage _storage;

  /// Appelé quand le serveur refuse le jeton (écran « Session expirée »).
  void Function()? onUnauthorized;

  Future<dynamic> get(String path, {Map<String, dynamic>? query}) =>
      _send(() => _dio.get(path, queryParameters: query));

  Future<dynamic> post(String path, {Object? data}) => _write(path, () => _dio.post(path, data: data));

  Future<dynamic> put(String path, {Object? data}) => _write(path, () => _dio.put(path, data: data));

  Future<dynamic> patch(String path, {Object? data}) => _write(path, () => _dio.patch(path, data: data));

  Future<dynamic> delete(String path) => _write(path, () => _dio.delete(path));

  /// Envoi `multipart/form-data` : champs texte + un fichier facultatif lu sur le téléphone.
  Future<dynamic> postMultipart(
    String path, {
    required Map<String, String> fields,
    String? fileField,
    String? filePath,
    String? fileName,
  }) async {
    final form = FormData.fromMap({
      ...fields,
      if (fileField != null && filePath != null)
        fileField: await MultipartFile.fromFile(filePath, filename: fileName ?? filePath.split(RegExp(r'[\\/]')).last),
    });
    return _write(path, () => _dio.post(path, data: form));
  }

  /// Téléchargement d'un fichier (reçu PDF…) : contenu brut.
  Future<List<int>> getBytes(String path) async {
    final data = await _send(() => _dio.get<List<int>>(path, options: Options(responseType: ResponseType.bytes)));
    return data as List<int>;
  }

  /// Écriture : une fois réussie, les écrans affichés se rechargent ([DataRefresh]).
  /// Exceptions : l'authentification et le marquage des notifications comme lues
  /// (ce dernier est lui-même déclenché par un rechargement).
  Future<dynamic> _write(String path, Future<Response<dynamic>> Function() request) async {
    final data = await _send(request);
    if (!path.startsWith('/auth/') && !path.endsWith('/lues')) DataRefresh.instance.request();
    return data;
  }

  Future<dynamic> _send(Future<Response<dynamic>> Function() request) async {
    try {
      return (await request()).data;
    } on DioException catch (e) {
      switch (e.type) {
        case DioExceptionType.connectionError:
        case DioExceptionType.connectionTimeout:
          // En mode debug, l'adresse du serveur aide à repérer une mauvaise configuration
          // (API_BASE_URL, PC injoignable sur le Wi-Fi…).
          throw NetworkException(
            'Impossible de joindre le serveur SchoolConnect. Vérifiez votre connexion Internet.'
            '${kDebugMode ? '\n(Serveur : ${AppConstants.apiBaseUrl})' : ''}',
          );
        case DioExceptionType.receiveTimeout:
        case DioExceptionType.sendTimeout:
          throw const NetworkException('Le serveur met trop de temps à répondre. Réessayez dans un instant.');
        default:
          final status = e.response?.statusCode;
          final message = _message(e.response?.data);
          if (status == 401) {
            // Sans jeton (connexion, inscription) : identifiants refusés.
            // Avec jeton : la session a expiré.
            if (e.requestOptions.headers['Authorization'] == null) {
              throw AuthException(message ?? 'Identifiants invalides.');
            }
            onUnauthorized?.call();
            throw const UnauthorizedException();
          }
          if (status == 403) {
            throw ServerException(message ?? 'Vous n’avez pas accès à cette information.');
          }
          if (status == 404) throw ServerException(message ?? 'Information introuvable sur le serveur.');
          throw ServerException(message);
      }
    }
  }

  /// « Données invalides : nom (must not be blank) ».
  static String? _message(Object? data) {
    if (data is! Map) return null;
    final error = data['error'] as String? ?? data['message'] as String?;
    final details = data['details'];
    if (details is Map && details.isNotEmpty) {
      final list = details.entries.map((d) => '${d.key} (${d.value})').join(', ');
      return error == null ? list : '$error : $list';
    }
    return error;
  }
}
