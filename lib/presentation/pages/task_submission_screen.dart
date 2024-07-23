import 'dart:io';
import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:file_picker/file_picker.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:path/path.dart' as p;
import 'package:url_launcher/url_launcher.dart';

class TaskSubmissionScreen extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Directionality(
      textDirection: TextDirection.rtl,
      child: Scaffold(
        appBar: AppBar(
          backgroundColor: Colors.black,
          title: const Text(
            'تسليم المهمة',
            style: TextStyle(color: Colors.white, fontSize: 24),
          ),
        ),
        backgroundColor: Colors.black,
        body: TaskSubmissionView(),
      ),
    );
  }
}

class TaskSubmissionView extends StatelessWidget {
  final String currentUserEmail = FirebaseAuth.instance.currentUser!.email!;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(16.0),
      child: StreamBuilder<QuerySnapshot>(
        stream: FirebaseFirestore.instance
            .collection('users')
            .doc(currentUserEmail)
            .collection('tasks')
            .snapshots(),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          } else if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
            return const Center(
              child: Text(
                'لا توجد مهام',
                style: TextStyle(color: Colors.white),
              ),
            );
          } else {
            var tasks = snapshot.data!.docs;
            return ListView.builder(
              itemCount: tasks.length,
              itemBuilder: (context, index) {
                var task = tasks[index];
                var deadline = DateTime.parse(task['deadline']);
                var isOverdue = deadline.isBefore(DateTime.now());
                return TaskSubmissionCard(
                  task: task,
                  isOverdue: isOverdue,
                );
              },
            );
          }
        },
      ),
    );
  }
}

class TaskSubmissionCard extends StatelessWidget {
  final DocumentSnapshot task;
  final bool isOverdue;

  const TaskSubmissionCard({
    required this.task,
    required this.isOverdue,
  });

  @override
  Widget build(BuildContext context) {
    String fileName = task['fileName'];
    String deadline = task['deadline'];
    String summary = task['summary'];
    String assignedBy = task['assignedBy'];
    String fileUrl = task['fileUrl'];

    return GestureDetector(
      onTap: () {
        showDialog(
          context: context,
          builder: (context) => TaskSubmissionDetailsDialog(
            fileName: fileName,
            deadline: deadline,
            summary: summary,
            assignedBy: assignedBy,
            fileUrl: fileUrl,
            isOverdue: isOverdue,
            taskId: task.id,
            userEmail: FirebaseAuth.instance.currentUser!.email!,
          ),
        );
      },
      child: Container(
        margin: const EdgeInsets.symmetric(vertical: 8.0),
        padding: const EdgeInsets.all(16.0),
        decoration: BoxDecoration(
          color: Colors.white.withOpacity(0.1),
          borderRadius: BorderRadius.circular(16),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  fileName,
                  style: const TextStyle(color: Colors.white, fontSize: 16),
                ),
                const SizedBox(height: 8),
                Text(
                  'الموعد النهائي: $deadline',
                  style: TextStyle(
                      color: isOverdue ? Colors.red : Colors.white70,
                      fontSize: 14),
                ),
              ],
            ),
            if (isOverdue)
              const Icon(Icons.error, color: Colors.red)
            else
              const Icon(Icons.check_circle, color: Colors.green),
          ],
        ),
      ),
    );
  }
}

class TaskSubmissionDetailsDialog extends StatefulWidget {
  final String fileName;
  final String deadline;
  final String summary;
  final String assignedBy;
  final String fileUrl;
  final bool isOverdue;
  final String taskId;
  final String userEmail;

  const TaskSubmissionDetailsDialog({
    required this.fileName,
    required this.deadline,
    required this.summary,
    required this.assignedBy,
    required this.fileUrl,
    required this.isOverdue,
    required this.taskId,
    required this.userEmail,
  });

  @override
  _TaskSubmissionDetailsDialogState createState() =>
      _TaskSubmissionDetailsDialogState();
}

class _TaskSubmissionDetailsDialogState
    extends State<TaskSubmissionDetailsDialog> {
  File? _selectedFile;

  Future<void> _pickFile() async {
    final result = await FilePicker.platform.pickFiles();
    if (result != null && result.files.single.path != null) {
      setState(() {
        _selectedFile = File(result.files.single.path!);
      });
    }
  }

  Future<void> _uploadFile() async {
    if (_selectedFile == null) return;
    try {
      String fullFileName = _selectedFile!.path.split('/').last;
      String fileName = p.basename(fullFileName);
      UploadTask uploadTask = FirebaseStorage.instance
          .ref('task_submissions/$fileName')
          .putFile(_selectedFile!);
      TaskSnapshot snapshot = await uploadTask;
      String downloadUrl = await snapshot.ref.getDownloadURL();

      // Send notification to the task assigner
      await FirebaseFirestore.instance.collection('notifications').add({
        'text': 'تم تسليم ملف $fileName\nمن قبل ${widget.userEmail}',
        'fileUrl': downloadUrl,
        'read': false,
        'timestamp': Timestamp.now(),
        'userEmail': widget.assignedBy,
      });

      // Send chat message to the task assigner
      final querySnapshot = await FirebaseFirestore.instance
          .collection('chats')
          .where('users', arrayContains: widget.userEmail)
          .get();

      DocumentSnapshot? chatDoc;
      for (var doc in querySnapshot.docs) {
        List<dynamic> users = doc['users'];
        if (users.contains(widget.assignedBy)) {
          chatDoc = doc;
          break;
        }
      }

      final messageData = {
        'sender': widget.userEmail,
        'message': 'تم تسليم الملف $fileName ',
        'fileName': fileName,
        'fileUrl': downloadUrl,
        'timestamp': Timestamp.now(),
        'fileType': 'link',
      };

      if (chatDoc != null) {
        // Add the message to the existing chat
        await FirebaseFirestore.instance
            .collection('chats')
            .doc(chatDoc.id)
            .update({
          'messages': FieldValue.arrayUnion([messageData]),
        });
      } else {
        // Create a new chat and add the message
        await FirebaseFirestore.instance.collection('chats').add({
          'users': [widget.assignedBy, widget.userEmail],
          'messages': FieldValue.arrayUnion([messageData]),
        });
      }

      // Update task status to 'completed'
      await FirebaseFirestore.instance
          .collection('users')
          .doc(widget.userEmail)
          .collection('tasks')
          .doc(widget.taskId)
          .update({'status': 'completed'});

      Navigator.of(context).pop();
    } catch (e) {
      print('Failed to upload file: $e');
    }
  }

  @override
  Widget build(BuildContext context) {
    return Directionality(
      textDirection: TextDirection.rtl,
      child: Dialog(
        backgroundColor: Colors.grey[900],
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'تفاصيل المهمة',
                style: TextStyle(
                    color: Colors.white,
                    fontSize: 20,
                    fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 16),
              Text(
                'اسم الملف: ${widget.fileName}',
                style: TextStyle(color: Colors.white70, fontSize: 16),
              ),
              const SizedBox(height: 8),
              Text(
                'الموعد النهائي: ${widget.deadline}',
                style: TextStyle(
                    color: widget.isOverdue ? Colors.red : Colors.white70,
                    fontSize: 16),
              ),
              const SizedBox(height: 8),
              Text(
                'ملخص المهمة: ${widget.summary}',
                style: TextStyle(color: Colors.white70, fontSize: 16),
              ),
              const SizedBox(height: 8),
              Text(
                'وُكلت بواسطة: ${widget.assignedBy}',
                style: TextStyle(color: Colors.white70, fontSize: 16),
              ),
              const SizedBox(height: 16),
              Center(
                child: ElevatedButton.icon(
                  icon: Icon(Icons.open_in_browser),
                  label: Text('افتح الملف'),
                  onPressed: () {
                    _launchURL(widget.fileUrl);
                  },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.blue,
                    foregroundColor: Colors.white,
                  ),
                ),
              ),
              const SizedBox(height: 16),
              Center(
                child: ElevatedButton.icon(
                  icon: Icon(Icons.upload_file),
                  label: Text('تسليم الملف'),
                  onPressed: _pickFile,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.green,
                    foregroundColor: Colors.white,
                  ),
                ),
              ),
              const SizedBox(height: 16),
              if (_selectedFile != null)
                Center(
                  child: ElevatedButton.icon(
                    icon: Icon(Icons.cloud_upload),
                    label: Text('رفع الملف'),
                    onPressed: _uploadFile,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.orange,
                      foregroundColor: Colors.white,
                    ),
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }

  void _launchURL(String url) async {
    if (await canLaunch(url)) {
      await launch(url);
    } else {
      throw 'Could not launch $url';
    }
  }
}
