import 'package:dio/dio.dart';
import '../../../../core/error/exceptions.dart';
import '../../../../core/utils/app_logger.dart';
import '../models/attraction_model.dart';
import '../models/attraction_page_model.dart';

class AttractionRemoteDataSource {
  const AttractionRemoteDataSource(this._dio);

  final Dio _dio;

  Future<AttractionPageModel> getAttractions({
    required String lang,
    required int page,
    String? categoryIds,
    double? nlat,
    double? elong,
  }) async {
    try {
      final query = <String, dynamic>{
        'page': page,
        if (categoryIds != null && categoryIds.isNotEmpty)
          'categoryIds': categoryIds,
        'nlat': ?nlat,
        'elong': ?elong,
      };
      final response = await _dio.get<Map<String, dynamic>>(
        '/$lang/Attractions/All',
        queryParameters: query,
      );
      if (response.statusCode == 200 && response.data != null) {
        return AttractionPageModel.fromJson(response.data!, page);
      }
      if (response.statusCode == 204) {
        return AttractionPageModel(total: 0, page: page, data: const []);
      }
      throw ServerException(
        '取得遊憩景點列表失敗：statusCode=${response.statusCode}, page=$page',
      );
    } on DioException catch (e) {
      AppLogger.error(
        'Attraction API failed'
        ' | statusCode=${e.response?.statusCode}'
        ' | page=$page'
        ' | message=${e.message}',
        exception: e,
        stackTrace: e.stackTrace,
      );
      throw ServerException(e.message ?? '取得遊憩景點列表失敗');
    }
  }

  Future<List<AttractionCategoryModel>> getAttractionCategories({
    required String lang,
  }) async {
    try {
      final response = await _dio.get<dynamic>(
        '/$lang/Miscellaneous/Categories',
      );
      if (response.statusCode == 200 && response.data != null) {
        final data = response.data;
        final rawList = switch (data) {
          {'data': final List list} => list,
          {'categories': final List list} => list,
          final List list => list,
          _ => const [],
        };
        return rawList
            .whereType<Map<String, dynamic>>()
            .map(AttractionCategoryModel.fromJson)
            .where((e) => e.id != 0 && e.name.isNotEmpty)
            .toList();
      }
      return const [];
    } on DioException catch (e) {
      AppLogger.error(
        'AttractionRemoteDataSource, getAttractionCategories, e: ${e.message}',
      );
      throw ServerException(e.message ?? '取得遊憩景點分類失敗');
    }
  }
}
