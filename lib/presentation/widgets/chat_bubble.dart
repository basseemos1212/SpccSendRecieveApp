import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:timeago/timeago.dart' as timeago;
import 'package:timeago/timeago.dart' as timeago_ar; // استيراد اللغة العربية

class ChatBubble extends StatelessWidget {
  final String message;
  final bool isMe;
  final DateTime time;
  final String? fileType;
  final String? fileUrl;
  final String? fileName;

  const ChatBubble({
    required this.message,
    required this.isMe,
    required this.time,
    this.fileType,
    this.fileUrl,
    this.fileName,
  });

  @override
  Widget build(BuildContext context) {
    // إعداد الوقت باللغة العربية
    timeago.setLocaleMessages('ar', timeago_ar.ArMessages());

    return Directionality(
      textDirection: TextDirection.rtl,
      child: Align(
        alignment: isMe ? Alignment.centerRight : Alignment.centerLeft,
        child: GestureDetector(
          onTap: fileUrl != null ? () => _launchURL(fileUrl!) : null,
          child: Container(
            margin: const EdgeInsets.symmetric(vertical: 4.0),
            padding:
                const EdgeInsets.symmetric(horizontal: 16.0, vertical: 10.0),
            decoration: BoxDecoration(
              color: isMe ? Colors.blue : Colors.white.withOpacity(0.1),
              borderRadius: BorderRadius.circular(12.0),
            ),
            child: Column(
              crossAxisAlignment:
                  isMe ? CrossAxisAlignment.end : CrossAxisAlignment.start,
              children: [
                if (fileType == 'link' && fileUrl != null)
                  Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      const Icon(Icons.insert_drive_file, color: Colors.white),
                      const SizedBox(width: 8),
                      Text(
                        message,
                        style: const TextStyle(color: Colors.white),
                      ),
                    ],
                  ),
                if (fileType == 'image' && fileUrl != null)
                  Image.network(
                    fileUrl!,
                    height: 200,
                    width: 200,
                  ),
                if (fileType == 'text' || fileType == null)
                  Text(
                    message,
                    style: const TextStyle(color: Colors.white),
                  ),
                const SizedBox(height: 4),
                Text(
                  timeago.format(time, locale: 'ar'), // استخدام اللغة العربية
                  style: const TextStyle(color: Colors.white54, fontSize: 12),
                ),
              ],
            ),
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
