import 'dart:typed_data';
import 'package:dio/dio.dart';

typedef TokenProvider = Future<String?> Function(bool forceRefresh);

class ApiService {
  final Dio _dio;

  static const _defaultBase = String.fromEnvironment(
    'API_BASE_URL',
    defaultValue: 'http://10.0.2.2:8000', // Android emulator → host loopback
  );

  ApiService({String baseUrl = _defaultBase}) : _dio = Dio() {
    _dio.options.baseUrl = baseUrl;
    _dio.options.connectTimeout = const Duration(seconds: 60);
    _dio.options.receiveTimeout = const Duration(seconds: 600);
    _dio.options.headers['Content-Type'] = 'application/json';
  }

  /// Устанавливает провайдер токена. Перед каждым запросом interceptor
  /// получает актуальный Firebase ID token. При 401 — force-refresh + retry.
  void setTokenProvider(TokenProvider provider) {
    _dio.interceptors.add(QueuedInterceptorsWrapper(
      onRequest: (options, handler) async {
        try {
          final token = await provider(false);
          if (token != null) {
            options.headers['Authorization'] = 'Bearer $token';
          }
        } catch (_) {}
        handler.next(options);
      },
      onError: (error, handler) async {
        if (error.response?.statusCode == 401) {
          try {
            final token = await provider(true);
            if (token != null) {
              error.requestOptions.headers['Authorization'] = 'Bearer $token';
              final response = await _dio.fetch(error.requestOptions);
              handler.resolve(response);
              return;
            }
          } catch (_) {}
        }
        handler.next(error);
      },
    ));
  }

  void clearAuthToken() {
    _dio.options.headers.remove('Authorization');
  }

  // ---- Auth ----

  Future<Map<String, dynamic>> syncUser() async {
    final response = await _dio.post('/auth/sync');
    return response.data;
  }

  Future<Map<String, dynamic>> getMe() async {
    final response = await _dio.get('/auth/me');
    return response.data;
  }

  // ---- Chats CRUD ----

  Future<Map<String, dynamic>> createChat({
    String title = 'Новый чат',
    bool isWebSearchEnabled = false,
  }) async {
    final response = await _dio.post('/chats/', data: {
      'title': title,
      'is_web_search_enabled': isWebSearchEnabled,
    });
    return response.data;
  }

  Future<Map<String, dynamic>> updateChat(int chatId, {
    String? title,
    bool? isWebSearchEnabled,
  }) async {
    final data = <String, dynamic>{};
    if (title != null) data['title'] = title;
    if (isWebSearchEnabled != null) data['is_web_search_enabled'] = isWebSearchEnabled;
    final response = await _dio.patch('/chats/$chatId', data: data);
    return response.data;
  }

  Future<List<dynamic>> getChats() async {
    final response = await _dio.get('/chats/');
    return response.data;
  }

  Future<Map<String, dynamic>> getChat(int chatId) async {
    final response = await _dio.get('/chats/$chatId');
    return response.data;
  }

  Future<void> deleteChat(int chatId) async {
    await _dio.delete('/chats/$chatId');
  }

  // ---- Messages ----

  Future<List<dynamic>> getChatMessages(int chatId) async {
    final response = await _dio.get('/chats/$chatId/messages');
    return response.data;
  }

  Future<Map<String, dynamic>> sendMessage({
    required int chatId,
    required String message,
    String? agent,
    String summarizationMode = 'default',
  }) async {
    final data = <String, dynamic>{
      'message': message,
      'summarization_mode': summarizationMode,
    };
    if (agent != null) {
      data['agent'] = agent;
    }
    final response = await _dio.post('/chats/$chatId/messages', data: data);
    return response.data;
  }

  // ---- Files ----

  Future<Map<String, dynamic>> uploadFile(String filePath, String fileName) async {
    final formData = FormData.fromMap({
      'file': await MultipartFile.fromFile(filePath, filename: fileName),
    });
    final response = await _dio.post('/files/', data: formData);
    return response.data;
  }

  Future<Map<String, dynamic>> uploadFileBytes(
      Uint8List bytes, String fileName, String mimeType) async {
    final formData = FormData.fromMap({
      'file': MultipartFile.fromBytes(
        bytes,
        filename: fileName,
        contentType: DioMediaType.parse(mimeType),
      ),
    });
    final response = await _dio.post('/files/', data: formData);
    return response.data;
  }

  Future<List<dynamic>> getFiles() async {
    final response = await _dio.get('/files/');
    return response.data;
  }

  Future<void> deleteFile(int fileId) async {
    await _dio.delete('/files/$fileId');
  }

  // ---- Chat context ----

  Future<List<dynamic>> getContextFiles(int chatId) async {
    final response = await _dio.get('/chats/$chatId/context');
    return response.data;
  }

  Future<void> addContextFile(int chatId, int fileId) async {
    await _dio.post('/chats/$chatId/context/$fileId');
  }

  Future<void> removeContextFile(int chatId, int fileId) async {
    await _dio.delete('/chats/$chatId/context/$fileId');
  }

  // ---- Exports ----

  /// Returns the full URL for an export file.
  /// The [filename] is the basename from export_path (e.g. "abstract_42.tex").
  String getExportFileUrl(String filename) {
    return '${_dio.options.baseUrl}/files/exports/$filename';
  }

  /// Downloads an export file to a local path.
  /// Uses the authenticated dio client so auth headers are included.
  Future<void> downloadFile(String url, String savePath) async {
    await _dio.download(url, savePath);
  }

  /// Fetches an export file as bytes.
  /// Useful for mobile platforms that require bytes for saving files.
  Future<Uint8List> getExportFileBytes(String url) async {
    final response = await _dio.get(
      url,
      options: Options(responseType: ResponseType.bytes),
    );
    return Uint8List.fromList(response.data);
  }
}
