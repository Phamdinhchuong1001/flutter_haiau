import 'package:flutter/material.dart';
import 'package:cloud_functions/cloud_functions.dart';
import 'package:flutter_haiau/models/device_model.dart';
import 'device_detail.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter_haiau/services/auth_service.dart';
import 'package:flutter_haiau/models/user_model.dart';

final FirebaseFunctions functions = FirebaseFunctions.instanceFor(
  region: 'asia-southeast1',
);

class DeviceScreen extends StatefulWidget {
  const DeviceScreen({super.key});

  @override
  State<DeviceScreen> createState() => _DeviceScreenState();
}

class _DeviceScreenState extends State<DeviceScreen> {
  final ScrollController scrollController = ScrollController();

  bool isLoading = true;
  bool isLoadingMore = false;
  bool hasMore = true;

  static const int pageSize = 10;

  List<DeviceModel> devices = [];
  dynamic lastCreatedAt;

  String searchQuery = '';
  String filterField = 'Tất cả';

  final List<String> filterOptions = [
    'Tất cả',
    'Tên thiết bị',
    'Model',
    'Hãng sản xuất',
    'Tình trạng',
  ];

  @override
  void initState() {
    super.initState();
    fetchDevices();
    scrollController.addListener(_onScroll);
  }

  @override
  void dispose() {
    scrollController.dispose();
    super.dispose();
  }

  void _onScroll() {
    if (!hasMore || isLoadingMore) return;
    if (scrollController.position.pixels >=
        scrollController.position.maxScrollExtent - 100) {
      fetchMoreDevices();
    }
  }

  Future<void> fetchDevices() async {
    setState(() => isLoading = true);

    try {
      final callable = functions.httpsCallable('getDevices');
      final result = await callable.call({
        'pageSize': pageSize,
        'lastCreatedAt': null,
      });

      final List<dynamic> data = result.data['devices'];

      devices = data.map((e) => DeviceModel.fromMap(e, e['id'])).toList();

      lastCreatedAt = result.data['lastCreatedAt'];
      hasMore = data.length == pageSize;
    } catch (e) {
      debugPrint("Error fetching devices: $e");
    }

    setState(() => isLoading = false);
  }

  Future<void> fetchMoreDevices() async {
    if (!hasMore) return;

    setState(() => isLoadingMore = true);

    try {
      final callable = functions.httpsCallable('getDevices');
      final result = await callable.call({
        'pageSize': pageSize,
        'lastCreatedAt': lastCreatedAt,
      });

      final List<dynamic> data = result.data['devices'];

      final newDevices = data
          .map((e) => DeviceModel.fromMap(e, e['id']))
          .toList();

      if (newDevices.isEmpty) {
        hasMore = false;
      } else {
        devices.addAll(newDevices);
        lastCreatedAt = result.data['lastCreatedAt'];
      }
    } catch (e) {
      debugPrint("Load more error: $e");
    }

    setState(() => isLoadingMore = false);
  }

  List<DeviceModel> get filteredDevices {
    if (searchQuery.isEmpty) return devices;

    final q = searchQuery.toLowerCase();

    return devices.where((d) {
      switch (filterField) {
        case 'Tên thiết bị':
          return d.name.toLowerCase().contains(q);
        case 'Model':
          return d.model.toLowerCase().contains(q);
        case 'Hãng sản xuất':
          return d.manufacturer.toLowerCase().contains(q);
        case 'Tình trạng':
          return statusToString(d.status).toLowerCase().contains(q);
        default:
          return d.name.toLowerCase().contains(q) ||
              d.model.toLowerCase().contains(q) ||
              d.manufacturer.toLowerCase().contains(q);
      }
    }).toList();
  }

  Color getStatusColor(DeviceStatus status) {
    switch (status) {
      case DeviceStatus.active:
        return Colors.green.shade700;
      case DeviceStatus.calibrating:
        return Colors.orange.shade700;
      case DeviceStatus.broken:
        return Colors.red.shade700;
      case DeviceStatus.outOfService:
        return Colors.grey.shade600;
      default:
        return Colors.grey.shade600;
    }
  }

  Widget buildStatusTag(DeviceStatus status) {
    final color = getStatusColor(status);

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
      decoration: BoxDecoration(
        color: color.withOpacity(0.15),
        borderRadius: BorderRadius.circular(6),
      ),
      child: Text(
        statusToString(status),
        style: TextStyle(
          color: color,
          fontSize: 12,
          fontWeight: FontWeight.w600,
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        backgroundColor: const Color(0xFF005BFF),
        centerTitle: true,
        title: const Text(
          'Quản lý Thiết bị',
          style: TextStyle(
            color: Colors.white,
            fontWeight: FontWeight.normal,
            fontSize: 22,
          ),
        ),
        iconTheme: const IconThemeData(color: Colors.white),
        actions: [
          StreamBuilder<UserModel?>(
            stream: AuthService().streamUser(
              FirebaseAuth.instance.currentUser?.uid,
            ),
            builder: (context, snapshot) {
              final role = snapshot.data?.role ?? "nhanvien";
              final isAdmin = role == "admin";

              if (!isAdmin) return const SizedBox.shrink();

              return IconButton(
                icon: const Icon(Icons.add_box, color: Colors.white),
                onPressed: () async {
                  final created = await showDialog(
                    context: context,
                    builder: (context) => const AddDeviceDialog(),
                    barrierDismissible: false,
                  );
                  if (created == true) fetchDevices();
                },
              );
            },
          ),
        ],
      ),

      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(12, 10, 12, 4),
            child: Row(
              children: [
                Container(
                  width: 120,
                  height: 40,
                  decoration: BoxDecoration(
                    color: Colors.grey.shade100,
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(color: Colors.grey.shade300),
                  ),
                  child: DropdownButtonHideUnderline(
                    child: DropdownButton<String>(
                      value: filterField,
                      isExpanded: true,
                      icon: const Icon(Icons.arrow_drop_down, size: 20),
                      style: const TextStyle(
                        fontSize: 14,
                        color: Colors.black87,
                      ),
                      items: filterOptions
                          .map(
                            (option) => DropdownMenuItem(
                              value: option,
                              child: Padding(
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 8,
                                ),
                                child: Text(option),
                              ),
                            ),
                          )
                          .toList(),
                      onChanged: (value) {
                        setState(() {
                          filterField = value!;
                        });
                      },
                    ),
                  ),
                ),

                const SizedBox(width: 8),

                Expanded(
                  child: SizedBox(
                    height: 40,
                    child: TextField(
                      decoration: InputDecoration(
                        hintText: 'Tìm kiếm...',
                        hintStyle: TextStyle(
                          color: Colors.grey.shade600,
                          fontSize: 14,
                        ),
                        prefixIcon: const Icon(Icons.search, size: 20),
                        filled: true,
                        fillColor: Colors.grey.shade100,
                        contentPadding: const EdgeInsets.symmetric(
                          vertical: 0,
                          horizontal: 10,
                        ),
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(8),
                          borderSide: BorderSide(color: Colors.grey.shade300),
                        ),
                        enabledBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(8),
                          borderSide: BorderSide(color: Colors.grey.shade300),
                        ),
                        focusedBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(8),
                          borderSide: BorderSide(color: Colors.grey.shade400),
                        ),
                      ),
                      onChanged: (value) {
                        setState(() {
                          searchQuery = value.trim();
                        });
                      },
                    ),
                  ),
                ),
              ],
            ),
          ),

          Expanded(
            child: isLoading
                ? const Center(child: CircularProgressIndicator())
                : ListView.builder(
                    controller: scrollController,
                    itemCount: filteredDevices.length + (isLoadingMore ? 1 : 0),
                    itemBuilder: (context, index) {
                      if (index == filteredDevices.length) {
                        return const Padding(
                          padding: EdgeInsets.all(16),
                          child: Center(child: CircularProgressIndicator()),
                        );
                      }

                      final device = filteredDevices[index];

                      return Card(
                        elevation: 1.5,
                        margin: const EdgeInsets.symmetric(
                          horizontal: 12,
                          vertical: 6,
                        ),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(10),
                        ),
                        child: InkWell(
                          borderRadius: BorderRadius.circular(10),
                          onTap: () async {
                            final updated = await Navigator.push(
                              context,
                              MaterialPageRoute(
                                builder: (_) =>
                                    DeviceDetailScreen(device: device),
                              ),
                            );
                            if (updated == true) fetchDevices();
                          },
                          child: Padding(
                            padding: const EdgeInsets.symmetric(
                              vertical: 10,
                              horizontal: 12,
                            ),
                            child: Row(
                              children: [
                                CircleAvatar(
                                  radius: 22,
                                  backgroundColor: getStatusColor(
                                    device.status,
                                  ),
                                  child: const Icon(
                                    Icons.devices,
                                    color: Colors.white,
                                    size: 22,
                                  ),
                                ),

                                const SizedBox(width: 12),

                                Expanded(
                                  child: Column(
                                    crossAxisAlignment:
                                        CrossAxisAlignment.start,
                                    children: [
                                      Text(
                                        device.name,
                                        style: const TextStyle(
                                          fontWeight: FontWeight.bold,
                                          fontSize: 16,
                                        ),
                                      ),
                                      const SizedBox(height: 3),
                                      Text(
                                        "Hãng: ${device.manufacturer}",
                                        style: TextStyle(
                                          color: Colors.grey.shade700,
                                          fontSize: 14,
                                        ),
                                      ),
                                      Text(
                                        "Model: ${device.model}",
                                        style: TextStyle(
                                          color: Colors.grey.shade700,
                                          fontSize: 14,
                                        ),
                                      ),
                                    ],
                                  ),
                                ),

                                buildStatusTag(device.status),
                              ],
                            ),
                          ),
                        ),
                      );
                    },
                  ),
          ),
        ],
      ),
    );
  }
}

// =========================
//  ADD DEVICE DIALOG
// =========================

class AddDeviceDialog extends StatefulWidget {
  const AddDeviceDialog({super.key});

  @override
  State<AddDeviceDialog> createState() => _AddDeviceDialogState();
}

class _AddDeviceDialogState extends State<AddDeviceDialog> {
  final _formKey = GlobalKey<FormState>();

  final nameController = TextEditingController();
  final modelController = TextEditingController();
  final manufacturerController = TextEditingController();
  final purchaseDateController = TextEditingController();
  final calibrationController = TextEditingController();

  bool _isSubmitting = false;
  bool _isGeneratingCode = true;

  String? _autoDeviceCode;
  String _errorMessage = "";

  DeviceStatus _selectedStatus = DeviceStatus.active;
  int? _nextSequence;

  @override
  void initState() {
    super.initState();
    _fetchNewCode();
  }

  Future<void> _fetchNewCode() async {
    try {
      final callable = functions.httpsCallable('getNewDeviceCode');
      final result = await callable.call();

      setState(() {
        _autoDeviceCode = result.data['deviceCode'];
        _nextSequence = result.data['nextSequence'];
        _isGeneratingCode = false;
      });
    } catch (e) {
      setState(() {
        _errorMessage = "Lỗi tạo mã thiết bị: $e";
        _isGeneratingCode = false;
      });
    }
  }

  Future<void> _saveDevice() async {
    if (!_formKey.currentState!.validate()) return;

    if (_autoDeviceCode == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Không thể tạo mã thiết bị")),
      );
      return;
    }

    setState(() => _isSubmitting = true);

    final data = {
      "deviceCode": _autoDeviceCode!,
      "name": nameController.text.trim(),
      "model": modelController.text.trim(),
      "manufacturer": manufacturerController.text.trim(),
      "purchaseDate": purchaseDateController.text.trim(),
      "calibrationCycle": calibrationController.text.trim(),
      "status": statusToString(_selectedStatus),
      "nextSequence": _nextSequence,
    };

    try {
      final callable = functions.httpsCallable("addDevice");
      await callable.call(data);

      if (mounted) {
        Navigator.pop(context, true);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text("Đã thêm thiết bị $_autoDeviceCode"),
            backgroundColor: Colors.green,
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text("Lỗi thêm thiết bị: $e"),
            backgroundColor: Colors.red,
          ),
        );
      }
    } finally {
      setState(() => _isSubmitting = false);
    }
  }

  InputDecoration _input(String label) {
    return InputDecoration(
      labelText: label,
      filled: true,
      fillColor: Colors.grey.shade100,
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(10),
        borderSide: BorderSide.none,
      ),
      contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
    );
  }

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<UserModel?>(
      stream: AuthService().streamUser(FirebaseAuth.instance.currentUser?.uid),
      builder: (context, snapshot) {
        final role = snapshot.data?.role ?? "nhanvien";

        // ❌ Nếu không phải admin => khóa dialog
        if (role != "admin") {
          return const AlertDialog(
            title: Text("Không có quyền"),
            content: Text("Bạn không được phép thêm thiết bị."),
          );
        }

        // ⬇ NẾU LÀ ADMIN => hiện dialog bình thường
        return AlertDialog(
          title: const Text(
            "Thêm thiết bị mới",
            style: TextStyle(fontWeight: FontWeight.bold),
          ),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
          content: _isGeneratingCode
              ? const SizedBox(
                  height: 80,
                  child: Center(child: CircularProgressIndicator()),
                )
              : _errorMessage.isNotEmpty
              ? Text(_errorMessage, style: const TextStyle(color: Colors.red))
              : Form(
                  key: _formKey,
                  child: SingleChildScrollView(
                    child: Column(
                      children: [
                        TextFormField(
                          readOnly: true,
                          initialValue: _autoDeviceCode,
                          decoration: _input(
                            "Mã thiết bị",
                          ).copyWith(fillColor: Colors.blue.shade50),
                        ),
                        const SizedBox(height: 12),

                        TextFormField(
                          controller: nameController,
                          decoration: _input("Tên thiết bị"),
                          validator: (v) {
                            if (v == null || v.trim().isEmpty)
                              return "Nhập tên thiết bị";
                            if (v.trim().length < 3)
                              return "Tên thiết bị phải từ 3 ký tự";
                            return null;
                          },
                        ),
                        const SizedBox(height: 12),

                        TextFormField(
                          controller: modelController,
                          decoration: _input("Model / Serial"),
                          validator: (v) => v!.isEmpty ? "Nhập model" : null,
                        ),
                        const SizedBox(height: 12),

                        TextFormField(
                          controller: manufacturerController,
                          decoration: _input("Hãng sản xuất"),
                          validator: (v) =>
                              v!.isEmpty ? "Nhập hãng sản xuất" : null,
                        ),
                        const SizedBox(height: 12),

                        TextFormField(
                          controller: purchaseDateController,
                          readOnly: true,
                          decoration: _input("Ngày mua").copyWith(
                            suffixIcon: Icon(
                              Icons.calendar_today,
                              color: Colors
                                  .grey
                                  .shade600, // icon nhạt giống các ô khác
                              size: 20,
                            ),
                          ),
                          validator: (v) => v!.isEmpty ? "Chọn ngày mua" : null,
                          onTap: () async {
                            final d = await showDatePicker(
                              context: context,
                              initialDate: DateTime.now(),
                              firstDate: DateTime(2000),
                              lastDate: DateTime(2100),
                            );
                            if (d != null) {
                              purchaseDateController.text =
                                  "${d.day}/${d.month}/${d.year}";
                            }
                          },
                        ),
                        const SizedBox(height: 12),

                        TextFormField(
                          controller: calibrationController,
                          decoration: _input("Chu kỳ hiệu chuẩn (tháng)"),
                          validator: (v) {
                            if (v == null || v.trim().isEmpty)
                              return "Nhập chu kỳ hiệu chuẩn";
                            if (int.tryParse(v) == null)
                              return "Chu kỳ phải là số";
                            if (int.parse(v) <= 0)
                              return "Chu kỳ phải lớn hơn 0";
                            return null;
                          },
                        ),
                        SizedBox(height: 12),

                        DropdownButtonFormField<DeviceStatus>(
                          value: _selectedStatus,
                          items: DeviceStatus.values
                              .map(
                                (s) => DropdownMenuItem(
                                  value: s,
                                  child: Text(statusToString(s)),
                                ),
                              )
                              .toList(),
                          onChanged: (v) =>
                              setState(() => _selectedStatus = v!),
                          decoration: _input("Trạng thái"),
                        ),
                      ],
                    ),
                  ),
                ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text("Hủy"),
            ),
            ElevatedButton(
              onPressed: _isSubmitting || _isGeneratingCode
                  ? null
                  : _saveDevice,
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.blue,
                foregroundColor: Colors.white,
              ),
              child: _isSubmitting
                  ? const SizedBox(
                      width: 20,
                      height: 20,
                      child: CircularProgressIndicator(
                        color: Colors.white,
                        strokeWidth: 2,
                      ),
                    )
                  : const Text("Thêm"),
            ),
          ],
        );
      },
    );
  }
}
