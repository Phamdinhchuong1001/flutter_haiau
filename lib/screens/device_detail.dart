import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class DeviceDetailScreen extends StatefulWidget {
  final String deviceId;
  final Map<String, dynamic> deviceData;

  const DeviceDetailScreen({
    super.key,
    required this.deviceId,
    required this.deviceData,
  });

  @override
  State<DeviceDetailScreen> createState() => _DeviceDetailScreenState();
}

class _DeviceDetailScreenState extends State<DeviceDetailScreen> {
  final _formKey = GlobalKey<FormState>();

  late TextEditingController nameController;
  late TextEditingController modelController;
  late TextEditingController manufacturerController;
  late TextEditingController purchaseDateController;
  late TextEditingController calibrationCycleController;

  late String selectedStatus;

  final Color primaryColor = const Color(0xFF005BFF);

  final List<String> statusOptions = [
    'Đang hoạt động',
    'Hư hỏng',
    'Đang hiệu chuẩn',
    'Ngừng sử dụng',
  ];

  @override
  void initState() {
    super.initState();
    nameController = TextEditingController(text: widget.deviceData['name']);
    modelController = TextEditingController(text: widget.deviceData['model']);
    manufacturerController = TextEditingController(
      text: widget.deviceData['manufacturer'],
    );
    purchaseDateController = TextEditingController(
      text: widget.deviceData['purchaseDate'],
    );
    calibrationCycleController = TextEditingController(
      text: widget.deviceData['calibrationCycle'],
    );
    selectedStatus = statusOptions.contains(widget.deviceData['status'])
        ? widget.deviceData['status']
        : 'Đang hoạt động';
  }

  bool _hasChanged() {
    return nameController.text != widget.deviceData['name'] ||
        modelController.text != widget.deviceData['model'] ||
        manufacturerController.text != widget.deviceData['manufacturer'] ||
        purchaseDateController.text != widget.deviceData['purchaseDate'] ||
        calibrationCycleController.text !=
            widget.deviceData['calibrationCycle'] ||
        selectedStatus != widget.deviceData['status'];
  }

  Future<void> updateDevice() async {
    if (!_formKey.currentState!.validate()) return;

    if (!_hasChanged()) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Vui lòng thay đổi thông tin trước khi cập nhật!'),
        ),
      );
      return;
    }

    await FirebaseFirestore.instance
        .collection('devices')
        .doc(widget.deviceId)
        .update({
          'name': nameController.text.trim(),
          'model': modelController.text.trim(),
          'manufacturer': manufacturerController.text.trim(),
          'purchaseDate': purchaseDateController.text.trim(),
          'calibrationCycle': calibrationCycleController.text.trim(),
          'status': selectedStatus,
        });

    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Cập nhật thiết bị thành công!')),
      );
      Navigator.pop(context);
    }
  }

  Future<void> confirmDeleteDevice() async {
    final bool? confirm = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text("Xác nhận xóa"),
        content: const Text("Bạn có chắc muốn xóa thiết bị này?"),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text("Hủy"),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
            onPressed: () => Navigator.pop(context, true),
            child: const Text(
              "Xác nhận",
              style: TextStyle(color: Colors.white),
            ),
          ),
        ],
      ),
    );

    if (confirm == true) {
      await FirebaseFirestore.instance
          .collection('devices')
          .doc(widget.deviceId)
          .delete();
      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(const SnackBar(content: Text('Đã xóa thiết bị!')));
        Navigator.pop(context);
      }
    }
  }

  Future<void> _selectPurchaseDate() async {
    FocusScope.of(context).requestFocus(FocusNode());
    DateTime? pickedDate = await showDatePicker(
      context: context,
      initialDate: DateTime.now(),
      firstDate: DateTime(2000),
      lastDate: DateTime(2100),
    );
    if (pickedDate != null) {
      setState(() {
        purchaseDateController.text =
            "${pickedDate.day}/${pickedDate.month}/${pickedDate.year}";
      });
    }
  }

  InputDecoration _inputDecoration(String label, IconData icon) {
    return InputDecoration(
      prefixIcon: Icon(icon, color: const Color(0xFF2196F3)),
      labelText: label,
      labelStyle: const TextStyle(
        fontWeight: FontWeight.bold,
        color: Colors.black87,
      ),
      filled: true,
      fillColor: Colors.grey[100],
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: BorderSide.none,
      ),
      contentPadding: const EdgeInsets.symmetric(vertical: 12),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        centerTitle: true,
        elevation: 0,
        backgroundColor: primaryColor,
        foregroundColor: Colors.white,
        title: const Text(
          "Thông tin thiết bị",
          style: TextStyle(fontWeight: FontWeight.bold),
        ),
      ),
      body: Form(
        key: _formKey,
        child: SingleChildScrollView(
          padding: const EdgeInsets.symmetric(horizontal: 16.0),
          child: Column(
            children: [
              const _DeviceIcon(),
              Text(
                nameController.text,
                style: Theme.of(context).textTheme.titleLarge!.copyWith(
                  color: Colors.black,
                  fontWeight: FontWeight.bold,
                  fontSize: 22,
                ),
              ),
              const Divider(height: 32),

              // 🔹 Tên thiết bị
              TextFormField(
                controller: nameController,
                decoration: _inputDecoration(
                  "Tên thiết bị",
                  Icons.devices_other,
                ),
                validator: (value) => value == null || value.trim().isEmpty
                    ? 'Nhập tên thiết bị'
                    : null,
              ),
              const SizedBox(height: 12),

              // 🔹 Model
              TextFormField(
                controller: modelController,
                decoration: _inputDecoration(
                  "Model / Số serial",
                  Icons.confirmation_number,
                ),
                validator: (value) => value == null || value.trim().isEmpty
                    ? 'Nhập model hoặc số serial'
                    : null,
              ),
              const SizedBox(height: 12),

              // 🔹 Hãng sản xuất
              TextFormField(
                controller: manufacturerController,
                decoration: _inputDecoration("Hãng sản xuất", Icons.factory),
                validator: (value) => value == null || value.trim().isEmpty
                    ? 'Nhập hãng sản xuất'
                    : null,
              ),
              const SizedBox(height: 12),

              // 🔹 Ngày mua
              TextFormField(
                controller: purchaseDateController,
                readOnly: true,
                decoration: _inputDecoration("Ngày mua", Icons.calendar_today),
                validator: (value) => value == null || value.trim().isEmpty
                    ? 'Chọn ngày mua'
                    : null,
                onTap: _selectPurchaseDate,
              ),
              const SizedBox(height: 12),

              // 🔹 Chu kỳ hiệu chuẩn
              TextFormField(
                controller: calibrationCycleController,
                keyboardType: TextInputType.number,
                decoration: _inputDecoration(
                  "Chu kỳ hiệu chuẩn (tháng)",
                  Icons.access_time,
                ),
                validator: (value) {
                  if (value == null || value.trim().isEmpty) {
                    return 'Nhập chu kỳ hiệu chuẩn';
                  }
                  final num? months = num.tryParse(value);
                  if (months == null || months <= 0) {
                    return 'Chu kỳ phải là số > 0';
                  }
                  return null;
                },
              ),
              const SizedBox(height: 12),

              // 🔹 Trạng thái
              DropdownButtonFormField<String>(
                value: selectedStatus,
                decoration: _inputDecoration("Trạng thái", Icons.info_outline),
                items: statusOptions.map((status) {
                  return DropdownMenuItem<String>(
                    value: status,
                    child: Text(status),
                  );
                }).toList(),
                onChanged: (value) {
                  setState(() {
                    selectedStatus = value!;
                  });
                },
              ),

              const SizedBox(height: 20),
              Row(
                children: [
                  Expanded(
                    child: ElevatedButton.icon(
                      style: ElevatedButton.styleFrom(
                        backgroundColor: primaryColor,
                        foregroundColor: Colors.white,
                        shape: const StadiumBorder(),
                        minimumSize: const Size(double.infinity, 48),
                      ),
                      icon: const Icon(Icons.save),
                      label: const Text(
                        "Cập nhật",
                        style: TextStyle(fontWeight: FontWeight.bold),
                      ),
                      onPressed: updateDevice,
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: ElevatedButton.icon(
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.red,
                        foregroundColor: Colors.white,
                        shape: const StadiumBorder(),
                        minimumSize: const Size(double.infinity, 48),
                      ),
                      icon: const Icon(Icons.delete),
                      label: const Text(
                        "Xóa",
                        style: TextStyle(fontWeight: FontWeight.bold),
                      ),
                      onPressed: confirmDeleteDevice,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 20),
            ],
          ),
        ),
      ),
    );
  }
}

class _DeviceIcon extends StatelessWidget {
  const _DeviceIcon();

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16.0),
      margin: const EdgeInsets.symmetric(vertical: 16.0),
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        border: Border.all(
          color: Theme.of(
            context,
          ).textTheme.bodyLarge!.color!.withOpacity(0.08),
        ),
      ),
      child: const CircleAvatar(
        radius: 50,
        backgroundColor: Color(0xFFE3F2FD),
        child: Icon(Icons.devices_other, size: 50, color: Color(0xFF2196F3)),
      ),
    );
  }
}
