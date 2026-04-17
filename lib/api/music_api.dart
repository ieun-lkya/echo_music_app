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
      final resData = response.data;
      if (resData['code'] == '200' || resData['code'] == 200) {
        return resData['data'];
      } else {
        throw Exception(resData['msg'] ?? '获取音乐失败');
      }
    } catch (e) {
      throw Exception('获取列表失败：$e');
    }
  }

  static Future<List<dynamic>> searchMusic(String keyword) async {
    try {
      final response = await _dio.get(
        '/music/search',
        queryParameters: {'keyword': keyword},
        options: await _getAuthOptions(),
      );
      final resData = response.data;
      if (resData['code'] == '200' || resData['code'] == 200) {
        return resData['data'];
      } else {
        throw Exception(resData['msg'] ?? '搜索失败');
      }
    } catch (e) {
      throw Exception('搜索失败：$e');
    }
  }

  static Future<List<dynamic>> getComments(int musicId) async {
    try {
      final response = await _dio.get(
        '/music/comment/list/$musicId',
        options: await _getAuthOptions(),
      );
      final resData = response.data;
      if (resData['code'] == '200' || resData['code'] == 200) {
        return resData['data'];
      }
      return [];
    } catch (e) {
      return [];
    }
  }

  static Future<void> addComment(int musicId, String content) async {
    try {
      final response = await _dio.post(
        '/music/comment/add',
        data: {'musicId': musicId, 'content': content},
        options: await _getAuthOptions(),
      );
      final resData = response.data;
      if (resData['code'] != '200' && resData['code'] != 200) {
        throw Exception(resData['msg'] ?? '发表失败');
      }
    } catch (e) {
      throw Exception('发表失败：$e');
    }
  }

  static Future<List<dynamic>> aiRecommend(String scene) async {
    try {
      final response = await _dio.get(
        '/music/ai/recommend',
        queryParameters: {'scene': scene},
        options: await _getAuthOptions(),
      );
      final resData = response.data;
      if (resData['code'] == '200' || resData['code'] == 200) {
        return resData['data'];
      } else {
        throw Exception(resData['msg'] ?? 'AI 推荐失败');
      }
    } catch (e) {
      throw Exception('AI 推荐失败：$e');
    }
  }
}
