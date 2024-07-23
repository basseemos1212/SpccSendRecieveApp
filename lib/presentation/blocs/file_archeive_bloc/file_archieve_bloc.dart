import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:secret_contact/presentation/blocs/file_archeive_bloc/file_archieve_event.dart';
import 'package:secret_contact/presentation/blocs/file_archeive_bloc/file_archieve_state.dart';

class FileArchiveBloc extends Bloc<FileArchiveEvent, FileArchiveState> {
  FileArchiveBloc() : super(FileArchiveLoading());

  Stream<FileArchiveState> mapEventToState(FileArchiveEvent event) async* {
    if (event is LoadFilesEvent) {
      yield* _mapLoadFilesToState();
    }
  }

  Stream<FileArchiveState> _mapLoadFilesToState() async* {
    try {
      var snapshot =
          await FirebaseFirestore.instance.collection('file_links').get();
      var files = snapshot.docs;
      yield FileArchiveLoaded(files);
    } catch (e) {
      yield FileArchiveError(e.toString());
    }
  }
}
