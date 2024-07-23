import 'dart:io';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:path/path.dart' as path;
import '../../data/providers/dropbox_provider.dart';

abstract class ChatEvent {}

class SendMessageEvent extends ChatEvent {
  final String? message;
  final File? file;
  final String? fileType;

  SendMessageEvent({this.message, this.file, this.fileType});
}

abstract class ChatState {}

class ChatInitial extends ChatState {}

class ChatLoading extends ChatState {}

class ChatSuccess extends ChatState {}

class ChatFailure extends ChatState {
  final String error;

  ChatFailure(this.error);
}

class ChatBloc extends Bloc<ChatEvent, ChatState> {
  final DropboxProvider dropboxProvider;

  ChatBloc(this.dropboxProvider) : super(ChatInitial()) {
    on<SendMessageEvent>(_onSendMessage);
  }

  Future<void> _onSendMessage(
      SendMessageEvent event, Emitter<ChatState> emit) async {
    emit(ChatLoading());
    try {
      var currentUserEmail = FirebaseAuth.instance.currentUser!.email!;
      if (event.message == null && event.file == null) {
        throw Exception("Message or file must be provided.");
      }

      var chatId =
          await _getOrCreateChatId(currentUserEmail, event.message ?? '');

      var messageData = {
        'sender': currentUserEmail,
        'message': event.message ?? '',
        'timestamp': Timestamp.now(),
        'fileType': event.fileType ?? 'text',
      };

      if (event.file != null) {
        var fileUrl = await dropboxProvider.uploadFile(
            event.file!, path.basename(event.file!.path));
        messageData['fileUrl'] = fileUrl;
      }

      await FirebaseFirestore.instance.collection('chats').doc(chatId).update({
        'messages': FieldValue.arrayUnion([messageData])
      });

      emit(ChatSuccess());
    } catch (e) {
      emit(ChatFailure(e.toString()));
    }
  }

  Future<String> _getOrCreateChatId(
      String currentUserEmail, String chatWithUserEmail) async {
    if (currentUserEmail.isEmpty || chatWithUserEmail.isEmpty) {
      throw Exception("User emails must not be empty.");
    }

    var chatQuery = await FirebaseFirestore.instance
        .collection('chats')
        .where('users', arrayContains: currentUserEmail)
        .get();
    var chats = chatQuery.docs
        .where((chat) => chat['users'].contains(chatWithUserEmail))
        .toList();
    if (chats.isNotEmpty) {
      return chats.first.id;
    } else {
      var newChat = await FirebaseFirestore.instance.collection('chats').add({
        'users': [currentUserEmail, chatWithUserEmail],
        'messages': []
      });
      return newChat.id;
    }
  }
}
