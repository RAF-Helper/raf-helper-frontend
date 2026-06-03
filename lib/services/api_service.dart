import 'dart:typed_data';
import 'package:dio/dio.dart';

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

  void setAuthToken(String token) {
    _dio.options.headers['Authorization'] = 'Bearer $token';
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

  Future<Map<String, dynamic>> createChat({String title = 'Новый чат'}) async {
    final response = await _dio.post('/chats/', data: {
      'title': title,
      'is_web_search_enabled': false,
    });
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

  // ---- Context files ----

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
}
