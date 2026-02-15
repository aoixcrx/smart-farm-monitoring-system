import 'dart:io';
import 'package:excel/excel.dart'; // import excel
import 'package:path_provider/path_provider.dart';
import 'package:share_plus/share_plus.dart';
import 'package:intl/intl.dart'; // ต้องมีบรรทัดนี้สำหรับ DateFormat

class ExportService {
  // ฟังก์ชันสร้างและส่งออกไฟล์ Excel
  Future<void> exportSensorData() async {
    // 1. สร้าง Excel Object
    var excel = Excel.createExcel();

    // ลบ Sheet 1 เดิมที่ว่างเปล่า (ถ้ามี) แล้วสร้าง Sheet ใหม่
    String sheetName = 'SmartFarm_Data';
    Sheet sheet = excel[sheetName];

    // ตั้งค่า Sheet เริ่มต้น
    excel.setDefaultSheet(sheetName);

    // 2. สร้าง Header (หัวตาราง)
    // สำหรับ excel: ^4.0.0 ต้องแปลง String เป็น TextCellValue
    List<CellValue> headers = [
      TextCellValue('Date (วันที่)'),
      TextCellValue('Time (เวลา)'),
      TextCellValue('Temp Air (°C)'),
      TextCellValue('Humidity (%)'),
      TextCellValue('Light (Lux)'),
      TextCellValue('CWSI (Plot 1)'),
      TextCellValue('CWSI (Plot 2)'),
      TextCellValue('Temp Leaf (°C)'),
      TextCellValue('Water Level (cm)'),
    ];
    sheet.appendRow(headers);

    // 3. จำลองข้อมูล (Mock Data)
    DateTime now = DateTime.now();

    for (int i = 0; i < 10; i++) {
      DateTime time = now.subtract(Duration(hours: i));
      String dateStr = DateFormat('yyyy-MM-dd').format(time);
      String timeStr = DateFormat('HH:mm').format(time);

      // ข้อมูลสมมติ
      double temp = 28.0 + (i * 0.1);
      double hum = 75.0 - (i * 0.5);
      int lux = 5500 - (i * 100);
      double cwsi1 = 0.25 + (i * 0.01);

      // ใส่ข้อมูลลงแถว (ต้องแปลงเป็น CellValue)
      List<CellValue> rowData = [
        TextCellValue(dateStr),
        TextCellValue(timeStr),
        DoubleCellValue(double.parse(temp.toStringAsFixed(1))), // แปลงเป็น DoubleCellValue
        DoubleCellValue(double.parse(hum.toStringAsFixed(1))),
        IntCellValue(lux), // แปลงเป็น IntCellValue
        DoubleCellValue(double.parse(cwsi1.toStringAsFixed(2))),
        DoubleCellValue(0.18),
        DoubleCellValue(27.9),
        DoubleCellValue(15.1),
      ];

      sheet.appendRow(rowData);
    }

    // 4. บันทึกไฟล์ลงเครื่อง (Temporary)
    var fileBytes = excel.save();

    if (fileBytes != null) {
      // หา Path ชั่วคราวของเครื่อง
      final directory = await getTemporaryDirectory();
      String fileName = 'SmartFarm_Report_${DateFormat('yyyyMMdd_HHmm').format(now)}.xlsx';
      final path = '${directory.path}/$fileName';

      // สร้างไฟล์จริง
      File(path)
        ..createSync(recursive: true)
        ..writeAsBytesSync(fileBytes);

      // 5. เรียก Share Dialog
      // ใช้ Share.shareXFiles สำหรับเวอร์ชันใหม่
      await Share.shareXFiles(
        [XFile(path)],
        text: 'รายงานข้อมูล Smart Farm ประจำวันที่ ${DateFormat('dd/MM/yyyy').format(now)}',
      );
    }
  }
}