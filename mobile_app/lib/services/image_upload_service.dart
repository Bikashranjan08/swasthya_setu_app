
import 'dart:io';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'package:image_picker/image_picker.dart';

class ImageUploadService {
  final String _cloudName = "dmz9u5htz";
  final String _uploadPreset = "flutter_uploads";

  /// Uploads the given image [file] to Cloudinary.
  /// Returns the secure URL of the uploaded image on success, or null on failure.
  Future<String?> uploadImage(XFile imageFile) async {
    final url = Uri.parse("https://api.cloudinary.com/v1_1/$_cloudName/image/upload");

    try {
      final request = http.MultipartRequest('POST', url)
        ..fields['upload_preset'] = _uploadPreset
        ..files.add(await http.MultipartFile.fromPath('file', imageFile.path));

      final response = await request.send();

      if (response.statusCode == 200) {
        final responseData = await response.stream.bytesToString();
        final data = json.decode(responseData);
        print("✅ Cloudinary Success: ${data['secure_url']}");
        return data['secure_url'];
      } else {
        final errorBody = await response.stream.bytesToString();
        print("❌ Cloudinary Error: $errorBody");
        return null;
      }
    } catch (e) {
      print("❌ Exception during upload: $e");
      return null;
    }
  }
}
