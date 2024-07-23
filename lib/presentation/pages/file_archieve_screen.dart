import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:url_launcher/url_launcher.dart';

class FileArchiveScreen extends StatefulWidget {
  @override
  _FileArchiveScreenState createState() => _FileArchiveScreenState();
}

class _FileArchiveScreenState extends State<FileArchiveScreen> {
  String searchQuery = '';

  @override
  Widget build(BuildContext context) {
    return Directionality(
      textDirection: TextDirection.rtl,
      child: Scaffold(
        appBar: AppBar(
          backgroundColor: Colors.black,
          title: const Text(
            'أرشيف الملفات',
            style: TextStyle(color: Colors.white, fontSize: 24),
          ),
        ),
        backgroundColor: Colors.black,
        body: Column(
          children: [
            Padding(
              padding: const EdgeInsets.all(16.0),
              child: TextField(
                onChanged: (value) {
                  setState(() {
                    searchQuery = value;
                  });
                },
                decoration: InputDecoration(
                  hintText: 'ابحث عن ملف',
                  hintStyle: const TextStyle(color: Colors.white54),
                  prefixIcon: const Icon(Icons.search, color: Colors.white54),
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
              child: FileArchiveView(searchQuery: searchQuery),
            ),
          ],
        ),
      ),
    );
  }
}

class FileArchiveView extends StatelessWidget {
  final String searchQuery;

  FileArchiveView({required this.searchQuery});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(16.0),
      child: StreamBuilder<QuerySnapshot>(
        stream: FirebaseFirestore.instance.collection('file_links').snapshots(),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          } else if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
            return const Center(
              child: Text(
                'لا توجد ملفات',
                style: TextStyle(color: Colors.white),
              ),
            );
          } else {
            var files = snapshot.data!.docs.where((file) {
              var fileName = file['fileName'].toLowerCase();
              var query = searchQuery.toLowerCase();
              return fileName.contains(query);
            }).toList();

            return GridView.builder(
              gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                crossAxisCount: 4,
                crossAxisSpacing: 16,
                mainAxisSpacing: 16,
                childAspectRatio: 1.5,
              ),
              itemCount: files.length,
              itemBuilder: (context, index) {
                var file = files[index];
                var fileType = _getFileType(file['fileName']);
                return FileCard(
                  fileName: file['fileName'],
                  fileUrl: file['link'],
                  fileType: fileType,
                  fileDocument: file, // Pass the entire document
                );
              },
            );
          }
        },
      ),
    );
  }

  String _getFileType(String fileName) {
    var extension = fileName.split('.').last.toLowerCase();
    if (['jpg', 'jpeg', 'png'].contains(extension)) {
      return 'image';
    } else if (extension == 'pdf') {
      return 'pdf';
    } else {
      return 'file';
    }
  }
}

class FileCard extends StatelessWidget {
  final String fileName;
  final String fileUrl;
  final String fileType;
  final DocumentSnapshot fileDocument; // Passing the entire document

  const FileCard({
    required this.fileName,
    required this.fileUrl,
    required this.fileType,
    required this.fileDocument,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: () {
        showDialog(
          context: context,
          builder: (context) => FileDetailsDialog(
            fileDocument: fileDocument,
          ),
        );
      },
      child: Container(
        decoration: BoxDecoration(
          color: Colors.white.withOpacity(0.1),
          borderRadius: BorderRadius.circular(16),
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              fileType == 'image'
                  ? Icons.image
                  : fileType == 'pdf'
                      ? Icons.picture_as_pdf
                      : Icons.insert_drive_file,
              size: 64,
              color: Colors.white,
            ),
            const SizedBox(height: 16),
            Text(
              fileName,
              textAlign: TextAlign.center,
              style: const TextStyle(color: Colors.white, fontSize: 16),
            ),
          ],
        ),
      ),
    );
  }
}

class FileDetailsDialog extends StatelessWidget {
  final DocumentSnapshot fileDocument;

  const FileDetailsDialog({
    required this.fileDocument,
  });

  @override
  Widget build(BuildContext context) {
    String fileName = fileDocument['fileName'];
    String fileUrl = fileDocument['link'];
    String transactionNumber = fileDocument['transactionNumber'] ?? 'غير متوفر';
    String incomingNumber = fileDocument['incomingNumber'] ?? 'غير متوفر';
    String transactionDate = fileDocument['transactionDate'] ?? 'غير متوفر';
    String outgoingNumber = fileDocument['outgoingNumber'] ?? 'غير متوفر';
    String uploadDate = fileDocument['uploadDate'] ?? 'غير متوفر';
    String departmentName = fileDocument['organizationName'] ?? 'غير متوفر';

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
              const Text(
                'تفاصيل الملف',
                style: const TextStyle(
                    color: Colors.white,
                    fontSize: 20,
                    fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 16),
              Text(
                'اسم الملف: $fileName',
                style: const TextStyle(color: Colors.white70, fontSize: 16),
              ),
              const SizedBox(height: 8),
              Text(
                'رقم المعاملة: $transactionNumber',
                style: const TextStyle(color: Colors.white70, fontSize: 16),
              ),
              const SizedBox(height: 8),
              Text(
                'رقم الوارد: $incomingNumber',
                style: const TextStyle(color: Colors.white70, fontSize: 16),
              ),
              const SizedBox(height: 8),
              Text(
                'تاريخ المعاملة: $transactionDate',
                style: const TextStyle(color: Colors.white70, fontSize: 16),
              ),
              const SizedBox(height: 8),
              Text(
                'رقم الصادر: $outgoingNumber',
                style: const TextStyle(color: Colors.white70, fontSize: 16),
              ),
              const SizedBox(height: 8),
              Text(
                'تاريخ التحميل: $uploadDate',
                style: const TextStyle(color: Colors.white70, fontSize: 16),
              ),
              const SizedBox(height: 8),
              Text(
                'اسم الجهة: $departmentName',
                style: const TextStyle(color: Colors.white70, fontSize: 16),
              ),
              const SizedBox(height: 16),
              Center(
                child: ElevatedButton.icon(
                  icon: const Icon(Icons.open_in_browser),
                  label: const Text('افتح الملف'),
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

  String _getFileType(String fileName) {
    var extension = fileName.split('.').last.toLowerCase();
    if (['jpg', 'jpeg', 'png'].contains(extension)) {
      return 'image';
    } else if (extension == 'pdf') {
      return 'pdf';
    } else {
      return 'file';
    }
  }

  void _launchURL(String url) async {
    if (await canLaunch(url)) {
      await launch(url);
    } else {
      throw 'Could not launch $url';
    }
  }
}
