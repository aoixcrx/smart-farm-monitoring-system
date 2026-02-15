import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/theme_provider.dart';
import '../services/local_database_service.dart';
import '../models/user.dart';
import '../models/device_status.dart';
import '../models/sensor_log.dart';

class AdminPanelScreen extends StatefulWidget {
  const AdminPanelScreen({super.key});

  @override
  State<AdminPanelScreen> createState() => _AdminPanelScreenState();
}

class _AdminPanelScreenState extends State<AdminPanelScreen> with SingleTickerProviderStateMixin {
  late TabController _tabController;
  final LocalDatabaseService _db = LocalDatabaseService.instance;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 3, vsync: this);
  }

  @override
  Widget build(BuildContext context) {
    final theme = context.watch<ThemeProvider>();
    final colors = theme.colors;

    return Scaffold(
      backgroundColor: colors.background,
      appBar: AppBar(
        title: Text('Admin Panel', style: TextStyle(color: colors.text)),
        backgroundColor: colors.cardBg,
        iconTheme: IconThemeData(color: colors.text),
        bottom: TabBar(
          controller: _tabController,
          labelColor: colors.primary,
          unselectedLabelColor: colors.textLight,
          indicatorColor: colors.primary,
          tabs: const [
            Tab(text: 'Users', icon: Icon(Icons.people)),
            Tab(text: 'Devices', icon: Icon(Icons.devices)),
            Tab(text: 'Logs', icon: Icon(Icons.history)),
          ],
        ),
      ),
      body: TabBarView(
        controller: _tabController,
        children: [
          _UsersTab(db: _db, colors: colors),
          _DevicesTab(db: _db, colors: colors),
          _LogsTab(db: _db, colors: colors),
        ],
      ),
    );
  }
}

// ================== USERS TAB ==================
class _UsersTab extends StatefulWidget {
  final LocalDatabaseService db;
  final AppColors colors;

  const _UsersTab({required this.db, required this.colors});

  @override
  State<_UsersTab> createState() => _UsersTabState();
}

class _UsersTabState extends State<_UsersTab> {
  List<User> _users = [];

  @override
  void initState() {
    super.initState();
    _refresh();
  }

  Future<void> _refresh() async {
    final data = await widget.db.readAllUsers();
    setState(() => _users = data);
  }

  void _showForm({User? user}) {
    final usernameController = TextEditingController(text: user?.username ?? '');
    final nameController = TextEditingController(text: user?.fullName ?? '');
    final typeController = TextEditingController(text: user?.userType ?? 'เกตษรกร');
    
    showDialog(
      context: context,
      builder: (_) => AlertDialog(
        backgroundColor: widget.colors.cardBg,
        title: Text(user == null ? 'เพิ่มผู้ใช้' : 'แก้ไขผู้ใช้', style: TextStyle(color: widget.colors.text)),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(controller: usernameController, decoration: InputDecoration(labelText: 'Username'), style: TextStyle(color: widget.colors.text)),
            TextField(controller: nameController, decoration: InputDecoration(labelText: 'ชื่อ-นามสกุล'), style: TextStyle(color: widget.colors.text)),
            TextField(controller: typeController, decoration: InputDecoration(labelText: 'ประเภท (Admin/เกษตรกร)'), style: TextStyle(color: widget.colors.text)),
          ],
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context), child: const Text('ยกเลิก')),
          ElevatedButton(
            onPressed: () async {
              final newUser = User(
                id: user?.id,
                username: usernameController.text,
                password: user?.password ?? '1234', // Default password
                userType: typeController.text,
                fullName: nameController.text,
                createdAt: user?.createdAt ?? DateTime.now().toIso8601String(),
              );
              
              if (user == null) {
                await widget.db.createUser(newUser);
              } else {
                await widget.db.updateUser(newUser);
              }
              if (mounted) Navigator.pop(context);
              _refresh();
            },
            child: const Text('บันทึก'),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.transparent,
      floatingActionButton: FloatingActionButton(
        onPressed: () => _showForm(),
        backgroundColor: widget.colors.primary,
        child: const Icon(Icons.add, color: Colors.white),
      ),
      body: ListView.builder(
        itemCount: _users.length,
        itemBuilder: (context, index) {
          final u = _users[index];
          return Card(
            color: widget.colors.cardBg,
            margin: const EdgeInsets.all(8),
            child: ListTile(
              title: Text(u.username, style: TextStyle(fontWeight: FontWeight.bold, color: widget.colors.text)),
              subtitle: Text('${u.fullName} (${u.userType})', style: TextStyle(color: widget.colors.textLight)),
              trailing: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  IconButton(icon: Icon(Icons.edit, color: widget.colors.accent), onPressed: () => _showForm(user: u)),
                  IconButton(icon: Icon(Icons.delete, color: widget.colors.error), onPressed: () async {
                    await widget.db.deleteUser(u.id!);
                    _refresh();
                  }),
                ],
              ),
            ),
          );
        },
      ),
    );
  }
}

// ================== DEVICES TAB ==================
class _DevicesTab extends StatefulWidget {
  final LocalDatabaseService db;
  final AppColors colors;

  const _DevicesTab({required this.db, required this.colors});

  @override
  State<_DevicesTab> createState() => _DevicesTabState();
}

class _DevicesTabState extends State<_DevicesTab> {
  List<DeviceStatus> _devices = [];

  @override
  void initState() {
    super.initState();
    _refresh();
  }

  Future<void> _refresh() async {
    final data = await widget.db.readAllDevices();
    setState(() => _devices = data);
  }

  void _showForm({DeviceStatus? device}) {
    final nameController = TextEditingController(text: device?.deviceName ?? '');
    bool isActive = device?.isActive ?? false;

    showDialog(
      context: context,
      builder: (_) => StatefulBuilder(
        builder: (context, setState) => AlertDialog(
          backgroundColor: widget.colors.cardBg,
          title: Text(device == null ? 'เพิ่มอุปกรณ์' : 'แก้ไขอุปกรณ์', style: TextStyle(color: widget.colors.text)),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextField(controller: nameController, decoration: InputDecoration(labelText: 'ชื่ออุปกรณ์'), style: TextStyle(color: widget.colors.text)),
              SwitchListTile(
                title: Text('สถานะเปิดใช้งาน', style: TextStyle(color: widget.colors.text)),
                value: isActive,
                onChanged: (v) => setState(() => isActive = v),
              ),
            ],
          ),
          actions: [
            TextButton(onPressed: () => Navigator.pop(context), child: const Text('ยกเลิก')),
            ElevatedButton(
              onPressed: () async {
                final newDevice = DeviceStatus(
                  deviceId: device?.deviceId,
                  deviceName: nameController.text,
                  isActive: isActive,
                  updatedAt: DateTime.now().toIso8601String(),
                );

                if (device == null) {
                  await widget.db.createDevice(newDevice);
                } else {
                  await widget.db.updateDevice(newDevice);
                }
                if (mounted) Navigator.pop(context);
                _refresh();
              },
              child: const Text('บันทึก'),
            ),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.transparent,
      floatingActionButton: FloatingActionButton(
        onPressed: () => _showForm(),
        backgroundColor: widget.colors.primary,
        child: const Icon(Icons.add, color: Colors.white),
      ),
      body: ListView.builder(
        itemCount: _devices.length,
        itemBuilder: (context, index) {
          final d = _devices[index];
          return Card(
            color: widget.colors.cardBg,
            margin: const EdgeInsets.all(8),
            child: ListTile(
              leading: Icon(Icons.power_settings_new, color: d.isActive ? Colors.green : Colors.red),
              title: Text(d.deviceName, style: TextStyle(fontWeight: FontWeight.bold, color: widget.colors.text)),
              subtitle: Text(d.isActive ? 'Active' : 'Inactive', style: TextStyle(color: widget.colors.textLight)),
              trailing: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Switch(value: d.isActive, onChanged: (v) async {
                     final updated = DeviceStatus(deviceId: d.deviceId, deviceName: d.deviceName, isActive: v, updatedAt: DateTime.now().toIso8601String());
                     await widget.db.updateDevice(updated);
                     _refresh();
                  }),
                  IconButton(icon: Icon(Icons.delete, color: widget.colors.error), onPressed: () async {
                    await widget.db.deleteDevice(d.deviceId!);
                    _refresh();
                  }),
                ],
              ),
              onTap: () => _showForm(device: d),
            ),
          );
        },
      ),
    );
  }
}

// ================== LOGS TAB ==================
class _LogsTab extends StatefulWidget {
  final LocalDatabaseService db;
  final AppColors colors;

  const _LogsTab({required this.db, required this.colors});

  @override
  State<_LogsTab> createState() => _LogsTabState();
}

class _LogsTabState extends State<_LogsTab> {
  List<SensorLog> _logs = [];

  @override
  void initState() {
    super.initState();
    _refresh();
  }

  Future<void> _refresh() async {
    final data = await widget.db.readAllSensorLogs();
    setState(() => _logs = data);
  }
  
  // Only for testing adding dummy log
  Future<void> _addDummyLog() async {
    final log = SensorLog(
      plotId: 1, // Assume plot 1 exists
      airTemp: 30.5, 
      airHumidity: 60.2,
      leafTemp: 28.1,
      lightLux: 4500,
      cwsiIndex: 0.3, 
      recordedAt: DateTime.now().toIso8601String()
    );
    await widget.db.createSensorLog(log);
    _refresh();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.transparent,
      floatingActionButton: FloatingActionButton(
        mini: true,
        onPressed: _addDummyLog,
        backgroundColor: widget.colors.secondary,
        child: const Icon(Icons.add_chart, color: Colors.white),
      ),
      body: ListView.builder(
        itemCount: _logs.length,
        itemBuilder: (context, index) {
          final l = _logs[index];
          return Card(
             color: widget.colors.cardBg,
            margin: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
            child: ListTile(
              dense: true,
              title: Text('Log #${l.logId} - Plot ${l.plotId}', style: TextStyle(fontWeight: FontWeight.bold, color: widget.colors.text)),
              subtitle: Text(
                'Temp: ${l.airTemp}°C, Hum: ${l.airHumidity}%\nTime: ${l.recordedAt}',
                style: TextStyle(color: widget.colors.textLight),
              ),
              trailing: IconButton(
                icon: Icon(Icons.delete, size: 20, color: widget.colors.error),
                onPressed: () async {
                  await widget.db.deleteSensorLog(l.logId!);
                  _refresh();
                },
              ),
            ),
          );
        },
      ),
    );
  }
}
