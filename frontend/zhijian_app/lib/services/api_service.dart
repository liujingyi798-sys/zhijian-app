import 'dart:convert';
import 'dart:typed_data';
import 'package:http/http.dart' as http;
import '../config/api_config.dart';
import '../models/index.dart';

/// API service for communicating with 智健 backend.
/// Supports JWT auth via token injection.
class ApiService {
  final String baseUrl;
  final http.Client _client = http.Client();
  String? _authToken;

  ApiService({this.baseUrl = ApiConfig.baseUrl});

  /// Set the JWT token for authenticated requests.
  set authToken(String? token) => _authToken = token;

  Map<String, String> get _headers => {
    if (_authToken != null) 'Authorization': 'Bearer $_authToken',
  };

  // ── User / Auth ──────────────────────────────────────────

  Future<Map<String, dynamic>> getMe(String token) async {
    final res = await http.get(
      Uri.parse('$baseUrl/api/auth/me'),
      headers: {'Authorization': 'Bearer $token'},
    );
    if (res.statusCode == 200) {
      final data = jsonDecode(res.body);
      return data['user'] ?? {};
    }
    throw Exception('Failed to get user data');
  }

  // ── Health ──────────────────────────────────────────────

  Future<bool> healthCheck() async {
    try {
      final res = await _client.get(Uri.parse('$baseUrl${ApiConfig.health}'));
      return res.statusCode == 200;
    } catch (_) {
      return false;
    }
  }

  // ── Personalities ───────────────────────────────────────

  Future<List<PersonalityMeta>> getPersonalities() async {
    final res = await _client.get(Uri.parse('$baseUrl${ApiConfig.personalities}'));
    if (res.statusCode == 200) {
      final data = jsonDecode(res.body);
      return (data['personalities'] as List)
          .map((p) => PersonalityMeta.fromJson(p))
          .toList();
    }
    throw Exception('Failed to load personalities');
  }

  // ── Photo Upload (bytes — web & native compatible) ──────

  Future<Map<String, dynamic>> uploadPhotoBytes({
    required Uint8List photoBytes,
    required String fileName,
    String photoType = 'front',
    String personality = 'gym_bro',
    double? weightKg,
    double? bodyFatPct,
  }) async {
    final uri = Uri.parse('$baseUrl${ApiConfig.photoUpload}');
    final request = http.MultipartRequest('POST', uri);

    // Add auth header
    if (_authToken != null) {
      request.headers['Authorization'] = 'Bearer $_authToken';
    }

    request.fields['photo_type'] = photoType;
    request.fields['personality'] = personality;
    if (weightKg != null) request.fields['weight_kg'] = weightKg.toString();
    if (bodyFatPct != null) request.fields['body_fat_pct'] = bodyFatPct.toString();

    request.files.add(http.MultipartFile.fromBytes(
      'photo',
      photoBytes,
      filename: fileName,
    ));

    final streamed = await request.send();
    final response = await http.Response.fromStream(streamed);

    if (response.statusCode == 200) {
      return jsonDecode(response.body);
    }
    throw Exception('Upload failed: ${response.statusCode} ${response.body}');
  }

  // ── Reports ─────────────────────────────────────────────

  Future<List<Map<String, dynamic>>> getReportHistory(
    String userId, {
    String? startDate,
    String? endDate,
    int limit = 30,
  }) async {
    String url = '$baseUrl${ApiConfig.reportHistory(userId)}&limit=$limit';
    if (startDate != null) url += '&start_date=$startDate';
    if (endDate != null) url += '&end_date=$endDate';
    final res = await _client.get(Uri.parse(url));
    if (res.statusCode == 200) return List<Map<String, dynamic>>.from(jsonDecode(res.body));
    throw Exception('Failed to load reports');
  }

  // ── Training Plans ──────────────────────────────────────

  Future<Map<String, dynamic>> getTodayPlan(String userId) async {
    final res = await _client.get(Uri.parse('$baseUrl${ApiConfig.todayPlan(userId)}'));
    if (res.statusCode == 200) return jsonDecode(res.body);
    throw Exception('Failed to load plan');
  }

  // ── Calendar ────────────────────────────────────────────

  Future<Map<String, dynamic>> getMonthCalendar(String userId, int year, int month) async {
    final res = await _client.get(
      Uri.parse('$baseUrl${ApiConfig.monthCalendar(userId, year, month)}'),
    );
    if (res.statusCode == 200) return jsonDecode(res.body);
    throw Exception('Failed to load calendar');
  }

  void dispose() => _client.close();
}
