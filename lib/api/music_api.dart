import 'package:dio/dio.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../config/api_constants.dart';

class MusicApi {
  static final Dio _dio = Dio(BaseOptions(
    baseUrl: ApiConstants.baseUrl,
    connectTimeout: const Duration(seconds: 5),
  ));

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
}
