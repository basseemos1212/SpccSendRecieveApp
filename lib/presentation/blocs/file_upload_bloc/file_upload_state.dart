import 'package:equatable/equatable.dart';

abstract class FileUploadState extends Equatable {
  const FileUploadState();

  @override
  List<Object> get props => [];
}

class FileUploadInitial extends FileUploadState {}

class FileUploadInProgress extends FileUploadState {}

class FileUploadSuccess extends FileUploadState {
  final String fileUrl;

  const FileUploadSuccess(this.fileUrl);

  @override
  List<Object> get props => [fileUrl];
}

class FileUploadFailure extends FileUploadState {
  final String error;

  const FileUploadFailure(this.error);

  @override
  List<Object> get props => [error];
}
