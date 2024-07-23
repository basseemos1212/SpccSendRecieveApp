import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:url_launcher/url_launcher.dart';

class TasksScreen extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Directionality(
      textDirection: TextDirection.rtl,
      child: Scaffold(
        appBar: AppBar(
          backgroundColor: Colors.black,
          title: const Text(
            'قائمة المهام',
            style: TextStyle(color: Colors.white, fontSize: 24),
          ),
        ),
        backgroundColor: Colors.black,
        body: TasksView(),
      ),
    );
  }
}

class TasksView extends StatelessWidget {
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
                return TaskCard(
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

class TaskCard extends StatelessWidget {
  final DocumentSnapshot task;
  final bool isOverdue;

  const TaskCard({
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
    String status = task['status'] ?? "none";

    return GestureDetector(
      onTap: () {
        showDialog(
          context: context,
          builder: (context) => TaskDetailsDialog(
            fileName: fileName,
            deadline: deadline,
            summary: summary,
            assignedBy: assignedBy,
            fileUrl: fileUrl,
            isOverdue: isOverdue,
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
            Icon(
                status == "completed"
                    ? Icons.check
                    : isOverdue
                        ? Icons.error
                        : Icons.lock_clock,
                color: isOverdue ? Colors.red : Colors.green)
          ],
        ),
      ),
    );
  }
}

class TaskDetailsDialog extends StatelessWidget {
  final String fileName;
  final String deadline;
  final String summary;
  final String assignedBy;
  final String fileUrl;
  final bool isOverdue;

  const TaskDetailsDialog({
    required this.fileName,
    required this.deadline,
    required this.summary,
    required this.assignedBy,
    required this.fileUrl,
    required this.isOverdue,
  });

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
                'اسم الملف: $fileName',
                style: TextStyle(color: Colors.white70, fontSize: 16),
              ),
              const SizedBox(height: 8),
              Text(
                'الموعد النهائي: $deadline',
                style: TextStyle(
                    color: isOverdue ? Colors.red : Colors.white70,
                    fontSize: 16),
              ),
              const SizedBox(height: 8),
              Text(
                'ملخص المهمة: $summary',
                style: TextStyle(color: Colors.white70, fontSize: 16),
              ),
              const SizedBox(height: 8),
              Text(
                'وُكلت بواسطة: $assignedBy',
                style: TextStyle(color: Colors.white70, fontSize: 16),
              ),
              const SizedBox(height: 16),
              Center(
                child: ElevatedButton.icon(
                  icon: Icon(Icons.open_in_browser),
                  label: Text('افتح الملف'),
                  onPressed: () {
                    _launchURL(fileUrl);
                  },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.blue,
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
