import 'package:mercato_frontend/core/constants/api_endpoints.dart';
import 'package:mercato_frontend/core/network/dio_client.dart';
import 'package:mercato_frontend/core/network/paginated_result.dart';
import 'package:mercato_frontend/features/admin/domain/admin_models.dart';

class AdminRepository {
  final DioClient _dioClient;

  AdminRepository(this._dioClient);

  Future<PaginatedResult<AdminUserModel>> listUsers({
    String? role,
    String? search,
    int page = 1,
    int limit = 20,
  }) async {
    final response = await _dioClient.dio.get(
      ApiEndpoints.adminUsers,
      queryParameters: {
        if (role != null) 'role': role,
        if (search != null && search.trim().isNotEmpty) 'search': search.trim(),
        'page': page,
        'limit': limit,
      },
    );
    return PaginatedResult.fromJson(response.data, AdminUserModel.fromJson);
  }

  Future<void> setUserBanned(
    int userId, {
    required bool banned,
    String? reason,
  }) async {
    await _dioClient.dio.patch(
      ApiEndpoints.adminUserBan(userId),
      data: {
        'banned': banned,
        if (reason != null && reason.trim().isNotEmpty) 'reason': reason.trim(),
      },
    );
  }

  Future<void> deleteUser(int userId) async {
    await _dioClient.dio.delete('${ApiEndpoints.adminUsersDelete}/$userId');
  }

  Future<List<AdminRecruiterEntry>> listRecruiters({String? status}) async {
    final response = await _dioClient.dio.get(
      ApiEndpoints.adminRecruiters,
      queryParameters: {if (status != null) 'status': status},
    );
    final List list = response.data['data'] ?? [];
    return list.map((json) => AdminRecruiterEntry.fromJson(json)).toList();
  }

  Future<void> verifyRecruiter(int profileId, {required bool approve}) async {
    await _dioClient.dio.patch(
      ApiEndpoints.adminRecruiterVerify(profileId),
      data: {'status': approve ? 'VERIFIED' : 'REJECTED'},
    );
  }

  Future<List<AdminReportEntry>> listReports({String? status}) async {
    final response = await _dioClient.dio.get(
      ApiEndpoints.adminReports,
      queryParameters: {if (status != null) 'status': status},
    );
    final List list = response.data['data'] ?? [];
    return list.map((json) => AdminReportEntry.fromJson(json)).toList();
  }

  Future<void> reviewReport(int reportId, {required bool dismiss}) async {
    await _dioClient.dio.patch(
      ApiEndpoints.adminReportReview(reportId),
      data: {'status': dismiss ? 'DISMISSED' : 'REVIEWED'},
    );
  }
}
