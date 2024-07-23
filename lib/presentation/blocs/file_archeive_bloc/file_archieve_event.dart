import 'package:equatable/equatable.dart';

abstract class FileArchiveEvent extends Equatable {
  @override
  List<Object> get props => [];
}

class LoadFilesEvent extends FileArchiveEvent {}
