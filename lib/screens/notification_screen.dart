import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/theme_provider.dart';

class NotificationScreen extends StatelessWidget {
  const NotificationScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final themeProvider = Provider.of<ThemeProvider>(context);
    final colors = themeProvider.colors;

    // Dummy Notification Data
    final notifications = [
      {'title': 'อากาศร้อนจัด', 'body': 'อุณหภูมิในโรงเรือนสูงเกิน 35°C', 'time': '10:30 น.'},
      {'title': 'น้ำในแปลงต่ำ', 'body': 'ระดับน้ำในแปลง 1 ต่ำกว่ากำหนด', 'time': '09:15 น.'},
      {'title': 'ระบบรดน้ำอัตโนมัติ', 'body': 'ทำงานเสร็จสิ้น', 'time': '08:00 น.'},
    ];

    return Scaffold(
      backgroundColor: colors.background,
      appBar: AppBar(
        title: Text('การแจ้งเตือน', style: TextStyle(color: colors.text)),
        backgroundColor: Colors.transparent,
        elevation: 0,
        iconTheme: IconThemeData(color: colors.text),
      ),
      body: ListView.separated(
        padding: const EdgeInsets.all(16),
        itemCount: notifications.length,
        separatorBuilder: (context, index) => const Divider(),
        itemBuilder: (context, index) {
          final notif = notifications[index];
          return ListTile(
            leading: CircleAvatar(
              backgroundColor: colors.primary.withOpacity(0.1),
              child: Icon(Icons.notifications, color: colors.primary),
            ),
            title: Text(notif['title']!, style: TextStyle(fontWeight: FontWeight.bold, color: colors.text)),
            subtitle: Text(notif['body']!, style: TextStyle(color: colors.textLight)),
            trailing: Text(notif['time']!, style: TextStyle(fontSize: 12, color: colors.textLight)),
            onTap: () {
               // Show Details
               showDialog(
                 context: context,
                 builder: (context) => AlertDialog(
                   title: Text(notif['title']!),
                   content: Text(notif['body']!),
                   actions: [TextButton(onPressed: () => Navigator.pop(context), child: const Text('ตกลง'))],
                 ),
               );
            },
          );
        },
      ),
    );
  }
}
