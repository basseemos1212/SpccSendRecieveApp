import 'dart:async';
import 'package:bloc/bloc.dart';
import 'package:secret_contact/domain/usecases/upload_file_usecase.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:secret_contact/presentation/blocs/file_upload_bloc/file_upload_event.dart';
import 'package:secret_contact/presentation/blocs/file_upload_bloc/file_upload_state.dart';

class FileUploadBloc extends Bloc<FileUploadEvent, FileUploadState> {
  final UploadFileUseCase uploadFileUseCase;

  FileUploadBloc(this.uploadFileUseCase) : super(FileUploadInitial()) {
    on<FileSelected>(_onFileSelected);
  }

  Future<void> _onFileSelected(
      FileSelected event, Emitter<FileUploadState> emit) async {
    emit(FileUploadInProgress());

    try {
      String fileUrl =
          await uploadFileUseCase.uploadFile(event.file, event.fileName);

      await FirebaseFirestore.instance.collection('file_links').add({
        'fileName': event.fileName,
        'transactionNumber': event.transactionNumber,
        'incomingNumber': event.incomingNumber,
        'transactionDate': event.transactionDate,
        'outgoingNumber': event.outgoingNumber,
        'organizationName': event.organizationName,
        'uploadDate': event.incomingDate,
        'link': fileUrl,
      });

      emit(FileUploadSuccess(fileUrl));
    } catch (e) {
      emit(FileUploadFailure(e.toString()));
    }
  }
}
