import 'package:dio/dio.dart';
import '../config/api_constants.dart';

class UserApi {
  static final Dio _dio = Dio(BaseOptions(
    baseUrl: ApiConstants.baseUrl,
    connectTimeout: const Duration(seconds: 5),
  ));

  static Future<Map<String, dynamic>> login(String username, String password) async {
    try {
      final response = await _dio.post(
        '/user/login',
        data: {
          'username': username,
          'password': password,
        },
      );

      final resData = response.data;
      if (resData['code'] == '200' || resData['code'] == 200) {
        return resData['data'];
      } else {
        throw Exception(resData['msg'] ?? '登录失败，请检查账号密码');
      }
    } on DioException catch (e) {
      if (e.type == DioExceptionType.connectionTimeout) {
        throw Exception('连接服务器超时，请检查手机是否连着电脑热点，以及防火墙是否关闭！');
      }
      throw Exception('网络请求异常: ${e.message}');
    }
  }

  static Future<void> register(String username, String password) async {
    try {
      final response = await _dio.post(
        '/user/register',
        data: {'username': username, 'password': password},
      );
      final resData = response.data;
      if (resData['code'] != '200' && resData['code'] != 200) {
        throw Exception(resData['msg'] ?? '注册失败，可能账号已存在');
      }
    } catch (e) {
      throw Exception('网络请求异常: $e');
    }
  }
}
