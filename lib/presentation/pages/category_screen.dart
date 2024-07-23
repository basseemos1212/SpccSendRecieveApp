import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:url_launcher/url_launcher.dart';

class CategoriesScreen extends StatelessWidget {
  final FirebaseAuth _auth = FirebaseAuth.instance;

  void _logout(BuildContext context) async {
    await _auth.signOut();
    Navigator.pushReplacementNamed(context, '/login');
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
            'قائمه المهام',
            style: GoogleFonts.cairo(
              textStyle: const TextStyle(
                color: Colors.white,
                fontSize: 24,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
          actions: [
            StreamBuilder<QuerySnapshot>(
              stream: FirebaseFirestore.instance
                  .collection('notifications')
                  .where('read', isEqualTo: false)
                  .snapshots(),
              builder: (context, snapshot) {
                if (!snapshot.hasData) {
                  return IconButton(
                    icon: const Stack(
                      children: [
                        Icon(Icons.notifications),
                      ],
                    ),
                    onPressed: () {
                      Navigator.pushNamed(context, '/notifications');
                    },
                  );
                }

                int unreadCount = snapshot.data!.docs.length;

                return IconButton(
                  icon: Stack(
                    children: [
                      const Icon(Icons.notifications),
                      if (unreadCount > 0)
                        Positioned(
                          right: 0,
                          child: Container(
                            padding: const EdgeInsets.all(1),
                            decoration: BoxDecoration(
                              color: Colors.red,
                              borderRadius: BorderRadius.circular(6),
                            ),
                            constraints: const BoxConstraints(
                              minWidth: 12,
                              minHeight: 12,
                            ),
                            child: Text(
                              '$unreadCount',
                              style: const TextStyle(
                                color: Colors.white,
                                fontSize: 8,
                              ),
                              textAlign: TextAlign.center,
                            ),
                          ),
                        ),
                    ],
                  ),
                  onPressed: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (context) => NotificationsScreen(),
                      ),
                    );
                  },
                );
              },
            ),
            IconButton(
              icon: const Icon(Icons.logout),
              onPressed: () => _logout(context),
            ),
          ],
        ),
        body: Padding(
          padding: const EdgeInsets.all(16.0),
          child: GridView.count(
            crossAxisCount: 3,
            crossAxisSpacing: 32,
            mainAxisSpacing: 32,
            childAspectRatio: 0.8,
            children: <Widget>[
              CategoryCard(
                title: 'رفع ملف إلى المدير',
                icon: Icons.upload_file,
                color: Colors.deepPurple,
                onTap: () {
                  Navigator.pushNamed(context, '/secretary-home');
                },
              ),
              CategoryCard(
                title: 'الدردشة',
                icon: Icons.chat,
                color: Colors.blue,
                onTap: () {
                  Navigator.pushNamed(context, '/chat');
                },
              ),
              CategoryCard(
                title: 'توكيل المهمة',
                icon: Icons.assignment,
                color: Colors.green,
                onTap: () {
                  Navigator.pushNamed(context, '/taskAssignment');
                },
              ),
              CategoryCard(
                title: 'أرشيف الملفات',
                icon: Icons.folder,
                color: Colors.orange,
                onTap: () {
                  Navigator.pushNamed(context, '/fileArchive');
                },
              ),
              CategoryCard(
                title: 'قائمة المهام',
                icon: Icons.task,
                color: Colors.teal,
                onTap: () {
                  Navigator.pushNamed(context, '/tasks');
                },
              ),
              CategoryCard(
                title: 'تسليم المهمة',
                icon: Icons.assignment_turned_in,
                color: Colors.red,
                onTap: () {
                  Navigator.pushNamed(context, '/taskSubmission');
                },
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class CategoryCard extends StatelessWidget {
  final String title;
  final IconData icon;
  final Color color;
  final VoidCallback onTap;

  const CategoryCard({
    required this.title,
    required this.icon,
    required this.color,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        decoration: BoxDecoration(
          color: color.withOpacity(0.2),
          borderRadius: BorderRadius.circular(16),
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(icon, size: 64, color: color),
            const SizedBox(height: 16),
            Text(
              title,
              textAlign: TextAlign.center,
              style: GoogleFonts.cairo(
                textStyle: const TextStyle(
                  color: Colors.white,
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class NotificationsScreen extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Directionality(
      textDirection: TextDirection.rtl,
      child: Scaffold(
        appBar: AppBar(
          title: Text(
            'الإشعارات',
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
        backgroundColor: Colors.black,
        body: StreamBuilder<QuerySnapshot>(
          stream: FirebaseFirestore.instance
              .collection('notifications')
              .orderBy('timestamp', descending: true)
              .snapshots(),
          builder: (context, snapshot) {
            if (!snapshot.hasData) {
              return const Center(child: CircularProgressIndicator());
            }

            var notifications = snapshot.data!.docs;

            return ListView.builder(
              itemCount: notifications.length,
              itemBuilder: (context, index) {
                var notification = notifications[index];
                return ListTile(
                  leading: CircleAvatar(
                    backgroundImage: AssetImage('assets/images/ceo.png'),
                  ),
                  title: Text(
                    notification['text'],
                    style: TextStyle(
                      color:
                          notification['read'] ? Colors.white54 : Colors.white,
                      fontWeight: notification['read']
                          ? FontWeight.normal
                          : FontWeight.bold,
                    ),
                  ),
                  onTap: () {
                    // Mark as read in the database
                    FirebaseFirestore.instance
                        .collection('notifications')
                        .doc(notification.id)
                        .update({'read': true});

                    // Open the file URL if available
                    if (notification['fileUrl'] != null &&
                        notification['fileUrl'].isNotEmpty) {
                      _launchURL(notification['fileUrl']);
                    }
                  },
                );
              },
            );
          },
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
