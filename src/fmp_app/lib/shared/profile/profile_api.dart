// lib/shared/profile/profile_api.dart

import 'package:fmp_app/core/network/api_client.dart';
import 'package:fmp_app/shared/profile/profile_data.dart';

class ProfileApi {
  final _dio = ApiClient().dio;  // uses ApiClient which auto-attaches JWT

  /// GET /profile?phone={phone}
  Future<ProfileData> getProfile(String phone) async {
    final encoded = Uri.encodeComponent(phone);
    final res = await _dio.get('/profile?phone=$encoded');
    return ProfileData.fromJson(Map<String, dynamic>.from(res.data as Map));
  }
}