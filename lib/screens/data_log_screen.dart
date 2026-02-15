import 'dart:math';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/theme_provider.dart';

class DataLogScreen extends StatelessWidget {
  const DataLogScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final themeProvider = Provider.of<ThemeProvider>(context);
    final colors = themeProvider.colors;

    // Mock Data for Table
    final data = List.generate(10, (index) {
      return {
        'time': '10:0$index',
        'temp': (25 + Random().nextDouble() * 5).toStringAsFixed(1),
        'humidity': (60 + Random().nextDouble() * 20).toStringAsFixed(1),
        'cwsi': (0.1 + Random().nextDouble() * 0.3).toStringAsFixed(2),
      };
    });
    
    // Summary
    final avgTemp = data.map((e) => double.parse(e['temp']!)).reduce((a,b)=>a+b) / data.length;

    return Scaffold(
      backgroundColor: colors.background,
      appBar: AppBar(
        title: Text('บันทึกข้อมูล', style: TextStyle(color: colors.text)),
        backgroundColor: Colors.transparent,
        elevation: 0,
        iconTheme: IconThemeData(color: colors.text),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildSummaryCard(avgTemp.toStringAsFixed(1), colors),
            const SizedBox(height: 24),
            Text('ตารางข้อมูล', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: colors.text)),
            const SizedBox(height: 12),
            Container(
              width: double.infinity,
              decoration: BoxDecoration(
                color: colors.cardBg,
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: colors.border),
              ),
              child: SingleChildScrollView(
                scrollDirection: Axis.horizontal,
                child: DataTable(
                  columns: const [
                    DataColumn(label: Text('เวลา')),
                    DataColumn(label: Text('อุณหภูมิ (°C)')),
                    DataColumn(label: Text('ความชื้น (%)')),
                    DataColumn(label: Text('CWSI')),
                  ],
                  rows: data.map((d) {
                    return DataRow(cells: [
                      DataCell(Text(d['time']!, style: TextStyle(color: colors.text))),
                      DataCell(Text(d['temp']!, style: TextStyle(color: colors.text))),
                      DataCell(Text(d['humidity']!, style: TextStyle(color: colors.text))),
                      DataCell(Text(d['cwsi']!, style: TextStyle(color: colors.text))),
                    ]);
                  }).toList(),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSummaryCard(String temp, AppColors colors) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(color: colors.primary.withOpacity(0.1), borderRadius: BorderRadius.circular(20)),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('สรุปข้อมูลวันนี้', style: TextStyle(fontWeight: FontWeight.bold, color: colors.primary)),
          const SizedBox(height: 10),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text('อุณหภูมิเฉลี่ย: $temp °C', style: TextStyle(fontSize: 16, color: colors.text)),
              Icon(Icons.query_stats, color: colors.primary),
            ],
          ),
          Text('จำนวนบันทึก: 10 รายการ', style: TextStyle(fontSize: 14, color: colors.textLight)),
        ],
      ),
    );
  }
}
