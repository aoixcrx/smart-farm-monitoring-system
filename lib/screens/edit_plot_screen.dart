import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:go_router/go_router.dart';
import '../models/plot.dart';
import '../services/hybrid_database_service.dart';
import '../providers/theme_provider.dart';

class EditPlotScreen extends StatefulWidget {
  final Plot? plot; // If null, it's Add mode

  const EditPlotScreen({super.key, this.plot});

  @override
  State<EditPlotScreen> createState() => _EditPlotScreenState();
}

class _EditPlotScreenState extends State<EditPlotScreen> {
  final _formKey = GlobalKey<FormState>();
  late TextEditingController _nameController;
  late TextEditingController _plantTypeController;
  late TextEditingController _noteController;

  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    _nameController = TextEditingController(text: widget.plot?.name ?? '');
    _plantTypeController =
        TextEditingController(text: widget.plot?.plantType ?? '');
    _noteController = TextEditingController(text: widget.plot?.note ?? '');
  }

  @override
  void dispose() {
    _nameController.dispose();
    _plantTypeController.dispose();
    _noteController.dispose();
    super.dispose();
  }

  Future<void> _savePlot() async {
    if (_formKey.currentState!.validate()) {
      setState(() => _isLoading = true);

      final newPlot = Plot(
        id: widget.plot?.id, // Keep ID if editing
        name: _nameController.text,
        imagePath:
            widget.plot?.imagePath ?? 'assets/tree1.png', // Default or Keep
        plantType: _plantTypeController.text,
        datePlanted:
            widget.plot?.datePlanted ?? DateTime.now().toIso8601String(),
        leafTemp: widget.plot?.leafTemp ?? 0.0,
        waterLevel: widget.plot?.waterLevel ?? 0.0,
        note: _noteController.text,
      );

      try {
        print('[EditPlot] Saving plot: ${newPlot.name} (ID: ${newPlot.id})');

        if (widget.plot == null) {
          // Create new plot
          print('[EditPlot] Creating new plot...');
          await HybridDatabaseService().createPlot(newPlot);
          print('[EditPlot] New plot created successfully');
        } else {
          // Update existing plot
          print('[EditPlot] Updating existing plot...');
          await HybridDatabaseService().updatePlot(newPlot);
          print('[EditPlot] Plot updated successfully');

          // Verify the update by reading back the data
          print('[EditPlot] Verifying update by reading plot back...');
          final allPlots = await HybridDatabaseService().getAllPlots();
          final savedPlot = allPlots.firstWhere(
            (p) => p.id == newPlot.id,
            orElse: () => newPlot,
          );
          print(
              '[EditPlot] Verification: saved plot name="${savedPlot.name}" vs new plot name="${newPlot.name}"');
          if (savedPlot.name == newPlot.name) {
            print('[EditPlot] [OK] Verification successful - Update confirmed');
          } else {
            print(
                '[EditPlot] ⚠️ Verification failed - Name mismatch after save!');
          }
        }

        if (mounted) {
          // Show success message
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('บันทึกแปลงปลูกเสร็จแล้ว'),
              backgroundColor: Colors.green,
              duration: Duration(seconds: 2),
            ),
          );

          // Return success and pop
          print('[EditPlot] Popping with success true');
          Future.delayed(const Duration(milliseconds: 300), () {
            if (mounted) {
              context.pop(true); // Use GoRouter pop with return value
            }
          });
        }
      } catch (e) {
        print('[EditPlot] Error saving plot: $e');
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('ข้อผิดพลาด: $e'),
              backgroundColor: Colors.red,
              duration: const Duration(seconds: 3),
            ),
          );
        }
      } finally {
        if (mounted) setState(() => _isLoading = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final themeProvider = Provider.of<ThemeProvider>(context);
    final colors = themeProvider.colors;
    final isDark = themeProvider.isDarkMode;

    return Scaffold(
      backgroundColor: colors.background,
      appBar: AppBar(
        title: Text(widget.plot == null ? 'เพิ่มแปลงปลูก' : 'แก้ไขแปลงปลูก',
            style: TextStyle(color: colors.text)),
        backgroundColor: Colors.transparent,
        elevation: 0,
        iconTheme: IconThemeData(color: colors.text),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _buildTextField('ชื่อแปลง', _nameController, colors),
              const SizedBox(height: 16),
              _buildTextField('ชนิดพืช', _plantTypeController, colors),
              const SizedBox(height: 16),
              _buildTextField('หมายเหตุ', _noteController, colors, maxLines: 3),
              const SizedBox(height: 32),
              SizedBox(
                width: double.infinity,
                height: 50,
                child: ElevatedButton(
                  onPressed: _isLoading ? null : _savePlot,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: colors.primary,
                    shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12)),
                  ),
                  child: _isLoading
                      ? const CircularProgressIndicator(color: Colors.white)
                      : const Text('บันทึก',
                          style: TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.bold,
                              color: Colors.white)),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildTextField(
      String label, TextEditingController controller, AppColors colors,
      {int maxLines = 1}) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label,
            style: TextStyle(
                fontSize: 14, fontWeight: FontWeight.bold, color: colors.text)),
        const SizedBox(height: 8),
        TextFormField(
          controller: controller,
          maxLines: maxLines,
          style: TextStyle(color: colors.text),
          decoration: InputDecoration(
            filled: true,
            fillColor: colors.cardBg,
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: BorderSide.none,
            ),
            contentPadding:
                const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
          ),
          validator: (value) {
            if (value == null || value.isEmpty) {
              return 'กรุณากรอกข้อมูล';
            }
            return null;
          },
        ),
      ],
    );
  }
}
