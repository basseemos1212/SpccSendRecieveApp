import 'dart:io';
import 'package:secret_contact/data/repo/file_repository.dart';

class UploadFileUseCase {
  final FileRepository fileRepository;

  UploadFileUseCase(this.fileRepository);

  Future<String> uploadFile(File file, String fileName) async {
    return await fileRepository.uploadFile(file, fileName);
  }
}
