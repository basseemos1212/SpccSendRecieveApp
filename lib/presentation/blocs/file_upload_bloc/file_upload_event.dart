import 'dart:io';
import 'package:equatable/equatable.dart';

abstract class FileUploadEvent extends Equatable {
  const FileUploadEvent();

  @override
  List<Object> get props => [];
}

class FileSelected extends FileUploadEvent {
  final File file;
  final String fileName;
  final String transactionNumber;
  final String incomingNumber;
  final String transactionDate;
  final String outgoingNumber;
  final String organizationName;
  final String incomingDate;

  const FileSelected(
    this.file,
    this.fileName,
    this.transactionNumber,
    this.incomingNumber,
    this.transactionDate,
    this.outgoingNumber,
    this.organizationName,
    this.incomingDate,
  );

  @override
  List<Object> get props => [
        file,
        fileName,
        transactionNumber,
        incomingNumber,
        transactionDate,
        outgoingNumber,
        organizationName,
        incomingDate,
      ];
}
