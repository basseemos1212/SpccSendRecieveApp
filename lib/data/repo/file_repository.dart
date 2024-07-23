import 'dart:io';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_storage/firebase_storage.dart';

class FileRepository {
  final FirebaseStorage storage;
  final FirebaseFirestore firestore;

  FileRepository(this.storage, this.firestore);

  Future<String> uploadFile(File file, String fileName) async {
    try {
      // Create a reference to the location you want to upload to in Firebase Storage
      final ref = storage.ref().child('uploads/$fileName');

      // Start the file upload
      final uploadTask = ref.putFile(file);

      // Wait for the upload to complete
      final snapshot = await uploadTask.whenComplete(() => {});

      // Get the download URL of the uploaded file
      final downloadUrl = await snapshot.ref.getDownloadURL();

      return downloadUrl;
    } catch (e) {
      throw Exception('Error uploading file: $e');
    }
  }

  Future<void> saveLink(String fileName, String link) async {
    try {
      await firestore.collection('file_links').doc(fileName).set({
        'fileName': fileName,
        'link': link,
      });
    } catch (e) {
      throw Exception('Error saving file link: $e');
    }
  }
}
