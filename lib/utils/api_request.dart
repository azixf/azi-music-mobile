import 'dart:convert';
import 'dart:developer';

import 'package:azi_music_mobile/config/request_config.dart';
import 'package:dio/dio.dart';

class DioClient {
  static BaseOptions options = BaseOptions(
      baseUrl: RequestConfig.baseURL,
      connectTimeout: RequestConfig.connectTimeout,
      receiveTimeout: RequestConfig.receiveTimeout);

  static final Dio _dio = Dio(options);

  static Future<T> request<T>(String path,
      {String method = 'get', Map<String, dynamic> params = const {}}) async {
    try {
      Response response = await _dio.request(path,
          queryParameters: method == 'get' ? params : null,
          data: method == 'get' ? null : params,
          options: Options(method: method));
      if (response.data is Map) {
        return response.data;
      } else {
        return json.decode(response.data.toString());
      }
    } on DioError catch (e) {
      log('DioError: $e');
      return Future.error(_errorHandler(e));
    } catch (e) {
      log('request error: ${e.toString()}');
      return Future.error(e);
    }
  }

  static String _errorHandler(DioError error) {
    String msg = '';
    switch (error.type) {
      case DioErrorType.sendTimeout:
      case DioErrorType.connectTimeout:
        msg = '网络连接超时，请检查网络设置';
        break;
      case DioErrorType.receiveTimeout:
        msg = '服务器异常，请稍后重试';
        break;
      case DioErrorType.cancel:
        msg = '请求已取消';
        break;
      default:
        msg = '请求异常，请稍后再试';
        break;
    }
    return msg;
  }
}
