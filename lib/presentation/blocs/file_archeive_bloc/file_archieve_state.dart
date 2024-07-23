import 'package:equatable/equatable.dart';

abstract class FileArchiveState extends Equatable {
  @override
  List<Object> get props => [];
}

class FileArchiveLoading extends FileArchiveState {}

class FileArchiveLoaded extends FileArchiveState {
  final List files;

  FileArchiveLoaded(this.files);

  @override
  List<Object> get props => [files];
}

class FileArchiveError extends FileArchiveState {
  final String error;

  FileArchiveError(this.error);

  @override
  List<Object> get props => [error];
}
