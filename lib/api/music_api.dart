import 'package:dio/dio.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../config/api_constants.dart';

class MusicApi {
  static final Dio _dio = Dio(
    BaseOptions(
      baseUrl: ApiConstants.baseUrl,
      connectTimeout: const Duration(seconds: 5),
    ),
  );

  static Future<Options> _getAuthOptions() async {
    final prefs = await SharedPreferences.getInstance();
    final token = prefs.getString('echo_token') ?? '';
    return Options(headers: {'token': token});
  }

  static Future<List<dynamic>> getMusicList() async {
    try {
      final options = await _getAuthOptions();
      final response = await _dio.get('/music/list', options: options);

      final resData = response.data;
      if (resData['code'] == '200' || resData['code'] == 200) {
        return resData['data'];
      } else {
        throw Exception(resData['msg'] ?? '获取音乐失败');
      }
    } catch (e) {
      throw Exception('网络请求异常: $e');
    }
  }

  static Future<void> toggleLike(String musicId) async {
    try {
      final options = await _getAuthOptions();
      final response = await _dio.post(
        '/music/like/$musicId',
        options: options,
      );

      final resData = response.data;
      if (resData['code'] != '200' && resData['code'] != 200) {
        throw Exception(resData['msg'] ?? '操作失败');
      }
    } catch (e) {
      throw Exception('网络请求异常: $e');
    }
  }

  static Future<List<dynamic>> aiRecommend(String prompt) async {
    try {
      final options = await _getAuthOptions();
      final response = await _dio.get(
        '/music/ai/recommend',
        queryParameters: {'scene': prompt},
        options: options,
      );

      final resData = response.data;
      if (resData['code'] == '200' || resData['code'] == 200) {
        return resData['data'];
      } else {
        throw Exception(resData['msg'] ?? 'AI 思考断片了...');
      }
    } catch (e) {
      throw Exception('AI 请求失败：$e');
    }
  }

  static Future<List<dynamic>> generateAiPlaylists() async {
    try {
      final options = await _getAuthOptions();
      final response = await _dio.get(
        '/music/ai/generatePlaylists',
        options: options,
      );

      final resData = response.data;
      if (resData['code'] == '200' || resData['code'] == 200) {
        return resData['data'];
      }
      return [];
    } catch (e) {
      print('AI 歌单接口暂未接入，自动隐藏该模块：$e');
      return [];
    }
  }
}
