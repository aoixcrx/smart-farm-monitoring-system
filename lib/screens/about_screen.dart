import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/theme_provider.dart';

class AboutScreen extends StatelessWidget {
  const AboutScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final themeProvider = Provider.of<ThemeProvider>(context);
    final colors = themeProvider.colors;

    return Scaffold(
      backgroundColor: colors.background,
      appBar: AppBar(
        title: Text('เกี่ยวกับ', style: TextStyle(color: colors.text)),
        backgroundColor: Colors.transparent,
        elevation: 0,
        iconTheme: IconThemeData(color: colors.text),
      ),
      body: Padding(
        padding: const EdgeInsets.all(24.0),
        child: Column(
          children: [
            Image.asset('assets/tree1.png', height: 150),
            const SizedBox(height: 24),
            Text('Smart Farm Application', style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold, color: colors.text)),
            const SizedBox(height: 8),
            Text('Version 1.0.0', style: TextStyle(color: colors.textLight)),
            const SizedBox(height: 32),
            Text(
              'แอปพลิเคชันสำหรับบริหารจัดการฟาร์มไฮโดรโปนิกส์อัจฉริยะ ช่วยให้คุณติดตามดูแลพืชผลได้สะดวกและแม่นยำยิ่งขึ้น พร้อมระบบแจ้งเตือนและวิเคราะห์ข้อมูล',
              textAlign: TextAlign.center,
              style: TextStyle(fontSize: 14, color: colors.text, height: 1.5),
            ),
            const SizedBox(height: 48),
            Text('Developed by Andrographis Team', style: TextStyle(fontSize: 12, color: colors.textLight)),
          ],
        ),
      ),
    );
  }
}
