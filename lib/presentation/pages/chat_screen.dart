import 'dart:io';
import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:file_picker/file_picker.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:path/path.dart' as path;
import '../widgets/chat_bubble.dart';

class ChatScreen extends StatefulWidget {
  @override
  _ChatScreenState createState() => _ChatScreenState();
}

class _ChatScreenState extends State<ChatScreen> {
  String? selectedChatUserEmail;
  String? selectedChatUserName;
  String currentUserEmail = FirebaseAuth.instance.currentUser!.email!;

  void _startNewChat() {
    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: const Text('اختر مستخدمًا لبدء الدردشة'),
          content: SizedBox(
            width: double.maxFinite,
            child: StreamBuilder<QuerySnapshot>(
              stream:
                  FirebaseFirestore.instance.collection('users').snapshots(),
              builder: (context, snapshot) {
                if (!snapshot.hasData) {
                  return const Center(child: CircularProgressIndicator());
                }
                var users = snapshot.data!.docs;
                return ListView.builder(
                  itemCount: users.length,
                  itemBuilder: (context, index) {
                    var user = users[index];
                    if (user['email'] == currentUserEmail) {
                      return Container(); // لا تعرض المستخدم الحالي في القائمة
                    }
                    return ListTile(
                      title: Text(user['name']),
                      subtitle: Text(user['email']),
                      onTap: () {
                        Navigator.of(context).pop();
                        setState(() {
                          selectedChatUserEmail = user['email'];
                          selectedChatUserName = user['name'];
                        });
                      },
                    );
                  },
                );
              },
            ),
          ),
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return Directionality(
      textDirection: TextDirection.rtl,
      child: Scaffold(
        backgroundColor: Colors.black,
        appBar: AppBar(
          backgroundColor: Colors.black,
          title: Text(
            'الرسائل',
            style: GoogleFonts.cairo(
              textStyle: const TextStyle(
                color: Colors.white,
                fontSize: 24,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
          actions: [
            IconButton(
              icon: const Icon(Icons.add),
              onPressed: _startNewChat,
            ),
          ],
        ),
        body: Row(
          children: [
            Expanded(
              flex: 1,
              child: Container(
                color: Colors.black54,
                child: Column(
                  children: [
                    Padding(
                      padding: const EdgeInsets.all(16.0),
                      child: TextField(
                        decoration: InputDecoration(
                          hintText: 'بحث',
                          hintStyle: const TextStyle(color: Colors.white54),
                          prefixIcon:
                              const Icon(Icons.search, color: Colors.white54),
                          filled: true,
                          fillColor: Colors.white.withOpacity(0.1),
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(8.0),
                            borderSide: BorderSide.none,
                          ),
                        ),
                        style: const TextStyle(color: Colors.white),
                      ),
                    ),
                    Expanded(
                      child: StreamBuilder<QuerySnapshot>(
                        stream: FirebaseFirestore.instance
                            .collection('chats')
                            .snapshots(),
                        builder: (context, snapshot) {
                          if (!snapshot.hasData) {
                            return const Center(
                                child: CircularProgressIndicator());
                          }
                          var chats = snapshot.data!.docs;
                          var userChats = chats
                              .where((chat) =>
                                  chat['users'].contains(currentUserEmail))
                              .toList();
                          return ListView.builder(
                            itemCount: userChats.length,
                            itemBuilder: (context, index) {
                              var chat = userChats[index];
                              var chatUsers = chat['users'] as List;
                              var otherUserEmail = chatUsers.firstWhere(
                                  (email) => email != currentUserEmail);
                              return FutureBuilder<DocumentSnapshot>(
                                future: FirebaseFirestore.instance
                                    .collection('users')
                                    .doc(otherUserEmail)
                                    .get(),
                                builder: (context, userSnapshot) {
                                  if (!userSnapshot.hasData) {
                                    return Container();
                                  }
                                  var user = userSnapshot.data!;
                                  return ListTile(
                                    title: Text(
                                      user['name'],
                                      style: GoogleFonts.cairo(
                                        textStyle: const TextStyle(
                                            color: Colors.white),
                                      ),
                                    ),
                                    subtitle: Text(
                                      user['email'],
                                      style: const TextStyle(
                                          color: Colors.white54),
                                    ),
                                    onTap: () {
                                      setState(() {
                                        selectedChatUserEmail = user['email'];
                                        selectedChatUserName = user['name'];
                                      });
                                    },
                                  );
                                },
                              );
                            },
                          );
                        },
                      ),
                    ),
                  ],
                ),
              ),
            ),
            Expanded(
              flex: 2,
              child: selectedChatUserEmail != null
                  ? ChatDetail(
                      chatWithUserEmail: selectedChatUserEmail!,
                      chatWithUserName: selectedChatUserName!,
                      currentUserEmail: currentUserEmail,
                    )
                  : const Center(
                      child: Text(
                        'اختر محادثة لبدء الدردشة',
                        style: TextStyle(color: Colors.white54),
                      ),
                    ),
            ),
          ],
        ),
      ),
    );
  }
}

class ChatDetail extends StatefulWidget {
  final String chatWithUserEmail;
  final String chatWithUserName;
  final String currentUserEmail;

  ChatDetail({
    required this.chatWithUserEmail,
    required this.chatWithUserName,
    required this.currentUserEmail,
  });

  @override
  _ChatDetailState createState() => _ChatDetailState();
}

class _ChatDetailState extends State<ChatDetail> {
  final TextEditingController _messageController = TextEditingController();
  final ScrollController _scrollController = ScrollController();

  Future<void> _pickImage() async {
    final result = await FilePicker.platform.pickFiles(type: FileType.image);
    if (result != null && result.files.single.path != null) {
      await _sendMessage(
          file: File(result.files.single.path!), fileType: 'image');
    }
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Expanded(
          child: StreamBuilder<QuerySnapshot>(
            stream: FirebaseFirestore.instance
                .collection('chats')
                .where('users', arrayContains: widget.currentUserEmail)
                .snapshots(),
            builder: (context, snapshot) {
              if (!snapshot.hasData) {
                return const Center(child: CircularProgressIndicator());
              }
              var chats = snapshot.data!.docs
                  .where((chat) =>
                      chat['users'].contains(widget.chatWithUserEmail))
                  .toList();
              if (chats.isEmpty) {
                return const Center(child: Text('لا توجد رسائل بعد.'));
              }
              var chat = chats.first;
              var messages = chat['messages'];
              WidgetsBinding.instance.addPostFrameCallback((_) {
                _scrollController
                    .jumpTo(_scrollController.position.maxScrollExtent);
              });
              return ListView.builder(
                controller: _scrollController,
                itemCount: messages.length,
                itemBuilder: (context, index) {
                  var message = messages[index];
                  return ChatBubble(
                    message: message['message'],
                    isMe: message['sender'] == widget.currentUserEmail,
                    time: message['timestamp'].toDate(),
                    fileType: message['fileType'],
                    fileUrl: message['fileUrl'],
                  );
                },
              );
            },
          ),
        ),
        Padding(
          padding: const EdgeInsets.all(16.0),
          child: Row(
            children: [
              IconButton(
                icon: const Icon(Icons.photo, color: Colors.blue),
                onPressed: _pickImage,
              ),
              Expanded(
                child: TextField(
                  controller: _messageController,
                  decoration: InputDecoration(
                    hintText: 'اكتب رسالة...',
                    hintStyle: const TextStyle(color: Colors.white54),
                    filled: true,
                    fillColor: Colors.white.withOpacity(0.1),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(8.0),
                      borderSide: BorderSide.none,
                    ),
                  ),
                  style: const TextStyle(color: Colors.white),
                ),
              ),
              const SizedBox(width: 8),
              IconButton(
                icon: const Icon(Icons.send, color: Colors.blue),
                onPressed: () async {
                  if (_messageController.text.isNotEmpty) {
                    await _sendMessage();
                    _messageController.clear();
                  }
                },
              ),
            ],
          ),
        ),
      ],
    );
  }

  Future<void> _sendMessage({File? file, String? fileType}) async {
    var message = _messageController.text;
    var chatId = await _getOrCreateChatId();
    var messageData = {
      'sender': widget.currentUserEmail,
      'message': message,
      'timestamp': Timestamp.now(),
      'fileType': fileType ?? 'text',
    };
    if (file != null) {
      var fileUrl = await _uploadFile(file);
      messageData['fileUrl'] = fileUrl;
    }
    await FirebaseFirestore.instance.collection('chats').doc(chatId).update({
      'messages': FieldValue.arrayUnion([messageData])
    });
    _messageController.clear();
  }

  Future<String> _uploadFile(File file) async {
    String fileName = path.basename(file.path);
    Reference storageReference =
        FirebaseStorage.instance.ref().child('uploads/$fileName');
    UploadTask uploadTask = storageReference.putFile(file);
    TaskSnapshot snapshot = await uploadTask;
    return await snapshot.ref.getDownloadURL();
  }

  Future<String> _getOrCreateChatId() async {
    var chatQuery = await FirebaseFirestore.instance
        .collection('chats')
        .where('users', arrayContains: widget.currentUserEmail)
        .get();
    var chats = chatQuery.docs
        .where((chat) => chat['users'].contains(widget.chatWithUserEmail))
        .toList();
    if (chats.isNotEmpty) {
      return chats.first.id;
    } else {
      var newChat = await FirebaseFirestore.instance.collection('chats').add({
        'users': [widget.currentUserEmail, widget.chatWithUserEmail],
        'messages': []
      });
      return newChat.id;
    }
  }
}
