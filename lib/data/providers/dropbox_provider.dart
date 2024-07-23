import 'dart:io';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:dio/dio.dart';

class DropboxProvider {
  final Dio dio = Dio();

  Future<String> getAccessToken() async {
    try {
      DocumentSnapshot documentSnapshot = await FirebaseFirestore.instance
          .collection('DataBaseCode')
          .doc('DB')
          .get();
      return documentSnapshot['code'];
    } catch (e) {
      print('Error getting access token: $e');
      throw Exception('Failed to get access token');
    }
  }

  Future<String> uploadFile(File file, String fileName) async {
    try {
      final accessToken = await getAccessToken();
      final uploadUrl = 'https://content.dropboxapi.com/2/files/upload';

      final headers = {
        'Authorization': 'Bearer $accessToken',
        'Dropbox-API-Arg':
            '{"path": "/$fileName","mode": "add","autorename": true,"mute": false,"strict_conflict": false}',
        'Content-Type': 'application/octet-stream',
      };

      print('Uploading file to Dropbox...');
      print('URL: $uploadUrl');
      print('Headers: $headers');

      final uploadResponse = await dio.post(
        uploadUrl,
        data: await file.readAsBytes(), // Read file as bytes
        options: Options(
          headers: headers,
          responseType: ResponseType.json,
          validateStatus: (status) {
            return status! < 500; // Let any status code below 500 pass through
          },
        ),
      );

      print('Response status code: ${uploadResponse.statusCode}');
      print('Response data: ${uploadResponse.data}');

      if (uploadResponse.statusCode == 200) {
        return await createSharedLink(fileName, accessToken);
      } else {
        print('Error response: ${uploadResponse.data}');
        throw Exception(
            'Failed to upload file: ${uploadResponse.statusCode} ${uploadResponse.statusMessage}');
      }
    } catch (e) {
      print('Upload file error: $e');
      throw Exception('Failed to upload file: $e');
    }
  }

  Future<String> createSharedLink(String fileName, String accessToken) async {
    try {
      const createLinkUrl =
          'https://api.dropboxapi.com/2/sharing/create_shared_link_with_settings';

      final headers = {
        'Authorization': 'Bearer $accessToken',
        'Content-Type': 'application/json',
      };

      final data = {
        "path": "/$fileName",
        "settings": {"requested_visibility": "public"}
      };

      final createLinkResponse = await dio.post(
        createLinkUrl,
        data: data,
        options: Options(
          headers: headers,
          responseType: ResponseType.json,
          validateStatus: (status) {
            return status! < 500; // Let any status code below 500 pass through
          },
        ),
      );

      print(
          'Create link response status code: ${createLinkResponse.statusCode}');
      print('Create link response data: ${createLinkResponse.data}');

      if (createLinkResponse.statusCode == 200) {
        String sharedLink = createLinkResponse.data['url'];
        // Modify the shared link to get the direct link
        String directLink = sharedLink
            .replaceFirst("www.dropbox.com", "dl.dropboxusercontent.com")
            .replaceFirst("?dl=0", "");
        await FirebaseFirestore.instance
            .collection("Files")
            .add({'fileName': fileName, 'link': directLink});
        return directLink;
      } else {
        print('Error response: ${createLinkResponse.data}');
        throw Exception(
            'Failed to create shared link: ${createLinkResponse.statusCode} ${createLinkResponse.statusMessage}');
      }
    } catch (e) {
      print('Create shared link error: $e');
      throw Exception('Failed to create shared link: $e');
    }
  }

  Future<void> saveLinkToFirestore(String fileName, String link) async {
    try {
      await FirebaseFirestore.instance.collection('files').add({
        'name': fileName,
        'link': link,
      });
    } catch (e) {
      print('Error saving link to Firestore: $e');
      throw Exception('Failed to save link to Firestore');
    }
  }
}
