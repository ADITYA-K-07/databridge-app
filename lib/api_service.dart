import 'dart:io';
import 'package:http/http.dart' as http;
import 'dart:convert';

class ApiService {
  // Change this if your backend URL changes
  static const String baseUrl = 'http://127.0.0.1:8000';

  // ── Health check ──────────────────────────
  static Future<bool> checkHealth() async {
    try {
      final res = await http.get(Uri.parse('$baseUrl/health'));
      return res.statusCode == 200;
    } catch (_) {
      return false;
    }
  }

  // ── Send image → get extracted text back ──
  static Future<Map<String, dynamic>> extractFromImage(File imageFile) async {
    try {
      final request = http.MultipartRequest(
        'POST',
        Uri.parse('$baseUrl/extract/image'),
      );

      request.files.add(
        await http.MultipartFile.fromPath('file', imageFile.path),
      );

      final response = await request.send();
      final body = await response.stream.bytesToString();
      return jsonDecode(body);
    } catch (e) {
      return {'success': false, 'error': e.toString(), 'extracted_text': ''};
    }
  }

  // ── Send NL question → get SQL back ───────
  static Future<Map<String, dynamic>> nlToSql(String question) async {
    try {
      final res = await http.post(
        Uri.parse('$baseUrl/query/nl'),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({'question': question}),
      );
      return jsonDecode(res.body);
    } catch (e) {
      return {'success': false, 'error': e.toString()};
    }
  }
}