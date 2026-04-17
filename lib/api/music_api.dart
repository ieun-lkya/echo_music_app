import 'package:dio/dio.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../config/api_constants.dart';

class MusicApi {
  static final Dio _dio = Dio(
    BaseOptions(
      baseUrl: ApiConstants.baseUrl,
      connectTimeout: const Duration(seconds: 15),
    ),
  );

  static Future<Options> _getAuthOptions() async {
    final prefs = await SharedPreferences.getInstance();
    final token = prefs.getString('echo_token') ?? '';
    return Options(headers: {'token': token});
  }

  static Future<List<dynamic>> getMusicList() async {
    try {
      final response = await _dio.get(
        '/music/list',
        options: await _getAuthOptions(),
      );
      return response.data;
    } catch (e) {
      throw Exception('获取列表失败：$e');
    }
  }

  static Future<List<dynamic>> aiRecommend(String scene) async {
    try {
      final response = await _dio.get(
        '/music/ai/recommend',
        queryParameters: {'scene': scene},
        options: await _getAuthOptions(),
      );
      return response.data;
    } catch (e) {
      throw Exception('AI 推荐失败：$e');
    }
  }
}
