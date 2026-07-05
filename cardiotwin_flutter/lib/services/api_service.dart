import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';
import '../theme.dart';

class ApiService {
  static final _client = http.Client();
  static String? _token;

  static Map<String, String> get _headers => {
    'Content-Type': 'application/json',
    if (_token != null) 'X-Auth-Token': _token!,
  };

  static Map<String, dynamic> _withToken(Map<String, dynamic> data) {
    if (_token != null) return {...data, '_token': _token!};
    return data;
  }

  static Future<void> loadSavedToken() async {
    final prefs = await SharedPreferences.getInstance();
    _token = prefs.getString('token');
  }

  static Future<Map<String, dynamic>> login(String username, String password) async {
    final res = await _client.post(
      Uri.parse('${AppConstants.baseUrl}/api/login'),
      headers: {'Content-Type': 'application/json'},
      body: jsonEncode({'username': username, 'password': password}),
    );
    final data = jsonDecode(res.body);
    if (data['success'] == true) {
      _token = data['token'];
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString('token', _token!);
    }
    return data;
  }

  static Future<void> logout() async {
    await _client.post(
      Uri.parse('${AppConstants.baseUrl}/api/logout'),
      headers: _headers,
      body: jsonEncode(_withToken({})),
    );
    _token = null;
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove('token');
  }

  static Future<Map<String, dynamic>> predict(Map<String, dynamic> data) async {
    final res = await _client.post(
      Uri.parse('${AppConstants.baseUrl}/api/predict'),
      headers: _headers,
      body: jsonEncode(_withToken(data)),
    );
    return jsonDecode(res.body);
  }

  static Future<Map<String, dynamic>> savePatient(Map<String, dynamic> data) async {
    final res = await _client.post(
      Uri.parse('${AppConstants.baseUrl}/api/save_patient'),
      headers: _headers,
      body: jsonEncode(_withToken(data)),
    );
    return jsonDecode(res.body);
  }

  static Future<List<dynamic>> getPatients({String search = ''}) async {
    final uri = Uri.parse('${AppConstants.baseUrl}/api/patients')
        .replace(queryParameters: {
          if (search.isNotEmpty) 'search': search,
          if (_token != null) '_token': _token!,
        });
    final res = await _client.get(uri, headers: _headers);
    return jsonDecode(res.body);
  }

  static Future<void> deletePatient(int id) async {
    final uri = Uri.parse('${AppConstants.baseUrl}/api/patients/$id')
        .replace(queryParameters: {if (_token != null) '_token': _token!});
    await _client.delete(uri, headers: _headers);
  }

  static Future<Map<String, dynamic>> getRecommendations(Map<String, dynamic> data) async {
    final res = await _client.post(
      Uri.parse('${AppConstants.baseUrl}/api/recommendations'),
      headers: _headers,
      body: jsonEncode(_withToken(data)),
    );
    return jsonDecode(res.body);
  }

  static Future<Map<String, dynamic>> getDashboard() async {
    final uri = Uri.parse('${AppConstants.baseUrl}/api/dashboard_data')
        .replace(queryParameters: {if (_token != null) '_token': _token!});
    final res = await _client.get(uri, headers: _headers);
    if (res.statusCode == 401) throw Exception('Unauthorized');
    return jsonDecode(res.body);
  }

  static Future<Map<String, dynamic>> sendChatMessage(String message, Map<String, dynamic> patientData) async {
    final res = await _client.post(
      Uri.parse('${AppConstants.baseUrl}/chatbot'),
      headers: _headers,
      body: jsonEncode(_withToken({'message': message, 'patient': patientData})),
    );
    return jsonDecode(res.body);
  }
}
