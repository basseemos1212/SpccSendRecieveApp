import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:secret_contact/presentation/widgets/file_selection_dialog.dart';

class TaskAssignmentScreen extends StatelessWidget {
  final String currentUserEmail = FirebaseAuth.instance.currentUser!.email!;

  @override
  Widget build(BuildContext context) {
    return Directionality(
      textDirection: TextDirection.rtl,
      child: Scaffold(
        appBar: AppBar(
          title: Text(
            'توكيل المهمة',
            style: GoogleFonts.cairo(
              textStyle: const TextStyle(
                color: Colors.white,
                fontSize: 24,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
          backgroundColor: Colors.black,
        ),
        body: StreamBuilder<QuerySnapshot>(
          stream: FirebaseFirestore.instance.collection('users').snapshots(),
          builder: (context, snapshot) {
            if (snapshot.connectionState == ConnectionState.waiting) {
              return const Center(child: CircularProgressIndicator());
            }
            if (!snapshot.hasData) {
              return const Center(
                  child: Text('لا يوجد مستخدمون',
                      style: TextStyle(color: Colors.white)));
            }

            List<DocumentSnapshot> users = snapshot.data!.docs;
            return ListView.builder(
              itemCount: users.length,
              itemBuilder: (context, index) {
                var user = users[index];
                if (user['email'] == currentUserEmail) {
                  return Container(); // Do not display the current user
                }
                return ListTile(
                  title: Text(user['name'],
                      style: const TextStyle(color: Colors.white)),
                  subtitle: Text(user['email'],
                      style: const TextStyle(color: Colors.white54)),
                  onTap: () => _openFileSelectionDialog(context, user),
                );
              },
            );
          },
        ),
        backgroundColor: Colors.black,
      ),
    );
  }

  void _openFileSelectionDialog(BuildContext context, DocumentSnapshot user) {
    showDialog(
      context: context,
      builder: (context) {
        return FileSelectionDialog(user: user);
      },
    );
  }
}
