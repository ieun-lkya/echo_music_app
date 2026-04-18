import 'dart:convert';
import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../config/api_constants.dart';

class MusicApi {
  static final Dio _dio = Dio(
    BaseOptions(
      baseUrl: ApiConstants.baseUrl,
      connectTimeout: const Duration(seconds: 30),
      receiveTimeout: const Duration(seconds: 30),
    ),
  );

  static Future<Options> _getAuthOptions() async {
    final prefs = await SharedPreferences.getInstance();
    final token = prefs.getString('echo_token') ?? '';
    return Options(headers: {'Authorization': 'Bearer $token'});
  }

  static Future<int?> _getUserId() async {
    final prefs = await SharedPreferences.getInstance();

    // 优先从本地存储读取（登录时保存的）
    final savedUserId = prefs.getInt('echo_user_id');
    if (savedUserId != null) {
      return savedUserId;
    }

    // 如果本地没有，尝试从 JWT Token 解析
    final token = prefs.getString('echo_token') ?? '';
    if (token.isEmpty) {
      debugPrint('Token 为空');
      return null;
    }

    try {
      final parts = token.split('.');
      if (parts.length == 3) {
        final payload = parts[1];
        final normalized = base64Url.normalize(payload);
        final decoded = utf8.decode(base64Url.decode(normalized));
        final data = jsonDecode(decoded);
        debugPrint('Token 解析结果: $data');
        final userId = data['userId'];
        if (userId != null) {
          final id = userId is int ? userId : int.parse(userId.toString());
          // 保存到本地，下次直接用
          await prefs.setInt('echo_user_id', id);
          return id;
        }
        debugPrint('Token 中未找到 id 字段');
      }
    } catch (e) {
      debugPrint('解析 Token 失败: $e');
    }
    return null;
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
        '/comment/list/$musicId',
        options: await _getAuthOptions(),
      );

      final resData = response.data;
      if (resData['code'] == '200' || resData['code'] == 200) {
        return resData['data'];
      }
      return [];
    } catch (e) {
      debugPrint('获取评论失败: $e');
      return [];
    }
  }

  static Future<void> addComment(int musicId, String content) async {
    try {
      final response = await _dio.post(
        '/comment/add',
        data: {'musicId': musicId, 'content': content},
        options: await _getAuthOptions(),
      );

      final resData = response.data;
      if (resData['code'] != '200' && resData['code'] != 200) {
        throw Exception(resData['msg'] ?? '发表失败');
      }
    } catch (e) {
      throw Exception('发表异常: $e');
    }
  }

  static Future<List<dynamic>> aiRecommend(String scene) async {
    try {
      final response = await _dio.post(
        '/music/recommend',
        data: {'text': scene},
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

  static Future<List<dynamic>> getPlaylists() async {
    try {
      final userId = await _getUserId();
      if (userId == null) return [];

      final response = await _dio.get(
        '/playlist/list',
        queryParameters: {'userId': userId},
        options: await _getAuthOptions(),
      );
      final resData = response.data;
      if (resData['code'] == '200' || resData['code'] == 200) {
        return resData['data'];
      }
      return [];
    } catch (e) {
      debugPrint('获取歌单失败: $e');
      return [];
    }
  }

  static Future<void> createPlaylist(String name) async {
    try {
      final userId = await _getUserId();
      if (userId == null) throw Exception('用户未登录');

      final response = await _dio.post(
        '/playlist/create',
        queryParameters: {'userId': userId, 'name': name},
        options: await _getAuthOptions(),
      );

      final resData = response.data;
      if (resData['code'] != '200' && resData['code'] != 200) {
        throw Exception(resData['msg'] ?? '创建失败');
      }
    } catch (e) {
      if (e is Exception) rethrow;
      throw Exception('创建歌单失败: $e');
    }
  }

  static Future<void> addMusicToPlaylist(int playlistId, int musicId) async {
    try {
      final response = await _dio.post(
        '/playlist/addMusic',
        queryParameters: {'playlistId': playlistId, 'musicId': musicId},
        options: await _getAuthOptions(),
      );
      final resData = response.data;
      if (resData['code'] != '200' && resData['code'] != 200) {
        throw Exception(resData['msg'] ?? '添加失败');
      }
    } catch (e) {
      throw Exception('添加失败: $e');
    }
  }

  static Future<List<dynamic>> getPlaylistDetail(int playlistId) async {
    try {
      final response = await _dio.get(
        '/playlist/musicList',
        queryParameters: {'playlistId': playlistId},
        options: await _getAuthOptions(),
      );
      final resData = response.data;
      if (resData['code'] == '200' || resData['code'] == 200) {
        return resData['data'];
      }
      return [];
    } catch (e) {
      debugPrint('获取歌单详情失败: $e');
      return [];
    }
  }

  static Future<void> deleteMusicFromPlaylist(
    int playlistId,
    int musicId,
  ) async {
    try {
      final response = await _dio.delete(
        '/playlist/delete',
        queryParameters: {'playlistId': playlistId, 'musicId': musicId},
        options: await _getAuthOptions(),
      );
      final resData = response.data;
      if (resData['code'] != '200' && resData['code'] != 200) {
        throw Exception(resData['msg'] ?? '删除失败');
      }
    } catch (e) {
      throw Exception('删除失败: $e');
    }
  }

  static Future<void> deletePlaylist(int playlistId) async {
    try {
      final response = await _dio.delete(
        '/playlist/delete',
        queryParameters: {'playlistId': playlistId},
        options: await _getAuthOptions(),
      );
      final resData = response.data;
      if (resData['code'] != '200' && resData['code'] != 200) {
        throw Exception(resData['msg'] ?? '删除失败');
      }
    } catch (e) {
      throw Exception('删除歌单失败: $e');
    }
  }

  static Future<void> likeMusic(int musicId) async {
    try {
      final userId = await _getUserId();
      if (userId == null) throw Exception('用户未登录');

      final response = await _dio.post(
        '/user/like',
        queryParameters: {'userId': userId, 'musicId': musicId},
        options: await _getAuthOptions(),
      );
      final resData = response.data;
      if (resData['code'] != '200' && resData['code'] != 200) {
        throw Exception(resData['msg'] ?? '点赞失败');
      }
    } catch (e) {
      throw Exception('点赞失败: $e');
    }
  }

  static Future<void> unlikeMusic(int musicId) async {
    try {
      final userId = await _getUserId();
      if (userId == null) throw Exception('用户未登录');

      final response = await _dio.post(
        '/user/unlike',
        queryParameters: {'userId': userId, 'musicId': musicId},
        options: await _getAuthOptions(),
      );
      final resData = response.data;
      if (resData['code'] != '200' && resData['code'] != 200) {
        throw Exception(resData['msg'] ?? '取消点赞失败');
      }
    } catch (e) {
      throw Exception('取消点赞失败: $e');
    }
  }

  static Future<List<dynamic>> getMyLikes() async {
    try {
      final userId = await _getUserId();
      if (userId == null) return [];

      final response = await _dio.get(
        '/user/likes',
        queryParameters: {'userId': userId},
        options: await _getAuthOptions(),
      );
      final resData = response.data;
      if (resData['code'] == '200' || resData['code'] == 200) {
        return resData['data'];
      }
      return [];
    } catch (e) {
      debugPrint('获取收藏列表失败: $e');
      return [];
    }
  }

  static Future<void> likeComment(int commentId) async {
    try {
      final response = await _dio.post(
        '/comment/like/$commentId',
        options: await _getAuthOptions(),
      );
      final resData = response.data;
      if (resData['code'] != '200' && resData['code'] != 200) {
        throw Exception(resData['msg'] ?? '点赞失败');
      }
    } catch (e) {
      throw Exception('点赞失败: $e');
    }
  }

  static Future<List<dynamic>> getTopMusic() async {
    try {
      final response = await _dio.get(
        '/music/top',
        options: await _getAuthOptions(),
      );
      final resData = response.data;
      if (resData['code'] == '200' || resData['code'] == 200) {
        return resData['data'];
      }
      return [];
    } catch (e) {
      debugPrint('获取热门音乐失败: $e');
      return [];
    }
  }

  static Future<List<dynamic>> getMusicByArtist(String artist) async {
    try {
      final response = await _dio.get(
        '/music/artist',
        queryParameters: {'name': artist},
        options: await _getAuthOptions(),
      );
      final resData = response.data;
      if (resData['code'] == '200' || resData['code'] == 200) {
        return resData['data'];
      }
      return [];
    } catch (e) {
      debugPrint('获取歌手歌曲失败: $e');
      return [];
    }
  }

  static Future<void> incrementPlayCount(int musicId) async {
    try {
      await _dio.post('/music/play/$musicId', options: await _getAuthOptions());
    } catch (e) {
      debugPrint('增加播放次数失败: $e');
    }
  }

  static Future<String?> getArtistBio(String artistName) async {
    try {
      final response = await _dio.get(
        '/music/artist/bio',
        queryParameters: {'artistName': artistName},
        options: await _getAuthOptions(),
      );
      final resData = response.data;
      if (resData['code'] == '200' || resData['code'] == 200) {
        return resData['data'];
      }
      return null;
    } catch (e) {
      debugPrint('获取歌手传记失败: $e');
      return null;
    }
  }

  static Future<Map<String, dynamic>?> updateUserProfile(
    Map<String, dynamic> user,
  ) async {
    try {
      final response = await _dio.post(
        '/user/update',
        data: user,
        options: await _getAuthOptions(),
      );
      final resData = response.data;
      if (resData['code'] == '200' || resData['code'] == 200) {
        return resData['data'];
      }
      return null;
    } catch (e) {
      debugPrint('更新用户信息失败: $e');
      return null;
    }
  }

  static Future<Map<String, dynamic>?> getUserProfile(
    int targetUserId,
    int currentUserId,
  ) async {
    try {
      final response = await _dio.get(
        '/user/profile/$targetUserId',
        queryParameters: {'currentUserId': currentUserId},
        options: await _getAuthOptions(),
      );
      final resData = response.data;
      if (resData['code'] == '200' || resData['code'] == 200) {
        return resData['data'];
      }
      return null;
    } catch (e) {
      debugPrint('获取用户信息失败: $e');
      return null;
    }
  }

  static Future<void> followUser(int followerId, int followingId) async {
    try {
      final response = await _dio.post(
        '/user/follow',
        queryParameters: {'followerId': followerId, 'followingId': followingId},
        options: await _getAuthOptions(),
      );
      final resData = response.data;
      if (resData['code'] != '200' && resData['code'] != 200) {
        throw Exception(resData['msg'] ?? '关注失败');
      }
    } catch (e) {
      throw Exception('关注失败: $e');
    }
  }

  static Future<void> unfollowUser(int followerId, int followingId) async {
    try {
      final response = await _dio.post(
        '/user/unfollow',
        queryParameters: {'followerId': followerId, 'followingId': followingId},
        options: await _getAuthOptions(),
      );
      final resData = response.data;
      if (resData['code'] != '200' && resData['code'] != 200) {
        throw Exception(resData['msg'] ?? '取消关注失败');
      }
    } catch (e) {
      throw Exception('取消关注失败: $e');
    }
  }

  static Future<List<dynamic>> getFriends(int userId) async {
    try {
      final response = await _dio.get(
        '/user/friends',
        queryParameters: {'userId': userId},
        options: await _getAuthOptions(),
      );
      final resData = response.data;
      if (resData['code'] == '200' || resData['code'] == 200) {
        return resData['data'];
      }
      return [];
    } catch (e) {
      debugPrint('获取好友列表失败: $e');
      return [];
    }
  }

  static Future<List<dynamic>> searchUsers(String keyword) async {
    try {
      final response = await _dio.get(
        '/user/search',
        queryParameters: {'keyword': keyword},
        options: await _getAuthOptions(),
      );
      final resData = response.data;
      if (resData['code'] == '200' || resData['code'] == 200) {
        return resData['data'];
      }
      return [];
    } catch (e) {
      debugPrint('搜索用户失败: $e');
      return [];
    }
  }

  static Future<void> sendMessage(Map<String, dynamic> msg) async {
    try {
      final response = await _dio.post(
        '/user/chat/send',
        data: msg,
        options: await _getAuthOptions(),
      );
      final resData = response.data;
      if (resData['code'] != '200' && resData['code'] != 200) {
        throw Exception(resData['msg'] ?? '发送失败');
      }
    } catch (e) {
      throw Exception('发送失败: $e');
    }
  }

  static Future<List<dynamic>> getChatHistory(int userId1, int userId2) async {
    try {
      final response = await _dio.get(
        '/user/chat/history',
        queryParameters: {'userId1': userId1, 'userId2': userId2},
        options: await _getAuthOptions(),
      );
      final resData = response.data;
      if (resData['code'] == '200' || resData['code'] == 200) {
        return resData['data'];
      }
      return [];
    } catch (e) {
      debugPrint('获取聊天记录失败: $e');
      return [];
    }
  }

  static Future<int> getUnreadCount(int userId) async {
    try {
      final response = await _dio.get(
        '/user/chat/unread',
        queryParameters: {'userId': userId},
        options: await _getAuthOptions(),
      );
      final resData = response.data;
      if (resData['code'] == '200' || resData['code'] == 200) {
        return resData['data'];
      }
      return 0;
    } catch (e) {
      debugPrint('获取未读消息数失败: $e');
      return 0;
    }
  }

  static Future<List<dynamic>> getRecentContacts(int userId) async {
    try {
      final response = await _dio.get(
        '/user/chat/contacts',
        queryParameters: {'userId': userId},
        options: await _getAuthOptions(),
      );
      final resData = response.data;
      if (resData['code'] == '200' || resData['code'] == 200) {
        return resData['data'];
      }
      return [];
    } catch (e) {
      debugPrint('获取最近联系人失败: $e');
      return [];
    }
  }

  static Future<void> markAsRead(int senderId, int receiverId) async {
    try {
      await _dio.post(
        '/user/chat/read',
        queryParameters: {'senderId': senderId, 'receiverId': receiverId},
        options: await _getAuthOptions(),
      );
    } catch (e) {
      debugPrint('标记已读失败: $e');
    }
  }
}
