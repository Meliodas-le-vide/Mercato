import 'package:dio/dio.dart';
import 'package:mercato_frontend/core/constants/api_endpoints.dart';
import 'package:mercato_frontend/core/network/dio_client.dart';
import 'package:mercato_frontend/features/recruiter/domain/recruiter_profile_model.dart';

class RecruiterProfileRepository {
  final DioClient _dioClient;

  RecruiterProfileRepository(this._dioClient);

  /// Récupère le profil recruteur connecté.
  Future<RecruiterProfileModel> getMe() async {
    final response = await _dioClient.dio.get(ApiEndpoints.recruiterMe);
    return RecruiterProfileModel.fromJson(response.data['data']);
  }

  /// Met à jour (ou crée, si premier remplissage) le profil recruteur.
  Future<RecruiterProfileModel> updateMe(RecruiterProfileModel profile) async {
    final response = await _dioClient.dio.put(
      ApiEndpoints.recruiterMe,
      data: profile.toUpdateJson(),
    );
    return RecruiterProfileModel.fromJson(response.data['data']);
  }

  Future<String> uploadKycDocument(String filePath) async {
    final fileName = filePath.split('/').removeLast();
    final formData = FormData.fromMap({
      'document': await MultipartFile.fromFile(filePath, filename: fileName),
    });

    final response = await _dioClient.dio.post(
      ApiEndpoints.recruiterUploadKyc,
      data: formData,
    );
    return response.data['url'] as String;
  }
}
