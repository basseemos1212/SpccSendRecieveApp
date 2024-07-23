import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

class FileSelectionDialog extends StatelessWidget {
  final DocumentSnapshot user;

  FileSelectionDialog({required this.user});

  @override
  Widget build(BuildContext context) {
    return Dialog(
      child: Container(
        width: 600, // or another appropriate width for desktop
        height: 400, // or another appropriate height for desktop
        padding: EdgeInsets.all(20),
        child: Column(
          children: [
            Text(
              'اختر ملفًا لتوكيله لـ ${user['name']}',
              style: Theme.of(context).textTheme.headlineMedium,
            ),
            SizedBox(height: 20),
            Expanded(
              child: StreamBuilder<QuerySnapshot>(
                stream: FirebaseFirestore.instance
                    .collection('file_links')
                    .snapshots(),
                builder: (context, snapshot) {
                  if (!snapshot.hasData) {
                    return Center(child: CircularProgressIndicator());
                  }

                  var files = snapshot.data!.docs;
                  return ListView.builder(
                    itemCount: files.length,
                    itemBuilder: (context, index) {
                      var file = files[index];
                      return ListTile(
                        leading: Icon(Icons.insert_drive_file),
                        title: Text(file['fileName']),
                        onTap: () {
                          _showAdditionalInfoDialog(
                            context,
                            file['fileName'],
                            file['link'],
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
    );
  }

  void _showAdditionalInfoDialog(
      BuildContext context, String fileName, String fileLink) {
    final TextEditingController _deadlineController = TextEditingController();
    final TextEditingController _summaryController = TextEditingController();

    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: Text('إدخال تفاصيل إضافية'),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextField(
                controller: _deadlineController,
                decoration: InputDecoration(labelText: 'الموعد النهائي'),
                onTap: () async {
                  DateTime? pickedDate = await showDatePicker(
                    context: context,
                    initialDate: DateTime.now(),
                    firstDate: DateTime.now(),
                    lastDate: DateTime(2101),
                  );
                  if (pickedDate != null) {
                    _deadlineController.text =
                        "${pickedDate.toLocal()}".split(' ')[0];
                  }
                },
              ),
              TextField(
                controller: _summaryController,
                decoration: InputDecoration(labelText: 'ملخص المهمة'),
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () {
                Navigator.of(context).pop();
              },
              child: Text('إلغاء'),
            ),
            TextButton(
              onPressed: () {
                if (_deadlineController.text.isNotEmpty &&
                    _summaryController.text.isNotEmpty) {
                  _assignTaskToUser(
                    context,
                    fileName,
                    fileLink,
                    _deadlineController.text,
                    _summaryController.text,
                  );
                  Navigator.of(context).pop();
                }
              },
              child: Text('توكيل'),
            ),
          ],
        );
      },
    );
  }

  void _assignTaskToUser(
    BuildContext context,
    String fileName,
    String fileLink,
    String deadline,
    String summary,
  ) async {
    String currentUserEmail = FirebaseAuth.instance.currentUser!.email!;
    QuerySnapshot querySnapshot = await FirebaseFirestore.instance
        .collection('chats')
        .where('users', arrayContains: currentUserEmail)
        .get();

    DocumentSnapshot? chatDoc;
    for (var doc in querySnapshot.docs) {
      List<dynamic> users = doc['users'];
      if (users.contains(user['email'])) {
        chatDoc = doc;
        break;
      }
    }

    final messageData = {
      'sender': currentUserEmail,
      'message':
          'تم توكيل الملف $fileName \nو آخر ميعاد للتنفيذ هو $deadline \nوالملخص: $summary',
      'fileName': fileName,
      'fileUrl': fileLink,
      'timestamp': Timestamp.now(),
      'fileType': 'link',
      'deadline': deadline,
      'summary': summary,
      "status": "none"
    };

    if (chatDoc != null) {
      // محادثة موجودة، أضف الرسالة إلى المحادثة الحالية
      await FirebaseFirestore.instance
          .collection('chats')
          .doc(chatDoc.id)
          .update({
        'messages': FieldValue.arrayUnion([messageData]),
      });
    } else {
      // لا توجد محادثة، أنشئ محادثة جديدة
      await FirebaseFirestore.instance.collection('chats').add({
        'users': [user['email'], currentUserEmail],
        'messages': FieldValue.arrayUnion([messageData]),
      });
    }

    // إضافة المهمة إلى مجموعة المهام الخاصة بالمستخدم
    await FirebaseFirestore.instance
        .collection('users')
        .doc(user.id)
        .collection('tasks')
        .add({
      'fileName': fileName,
      'fileUrl': fileLink,
      'deadline': deadline,
      'summary': summary,
      'assignedBy': currentUserEmail,
      'timestamp': Timestamp.now(),
      "status": "none"
    });

    // إضافة الإشعار إلى مجموعة الإشعارات
    await FirebaseFirestore.instance.collection('notifications').add({
      'text':
          'تم توكيل ملف $fileName \nإلى ${user['name']} \nو آخر ميعاد للتنفيذ هو $deadline \nوالملخص: $summary',
      'fileUrl': fileLink,
      'read': false,
      'timestamp': Timestamp.now(),
      'userEmail': user['email'],
    });
  }
}
