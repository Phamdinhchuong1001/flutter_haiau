import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'device_detail.dart';

class DeviceScreen extends StatefulWidget {
  const DeviceScreen({super.key});

  @override
  State<DeviceScreen> createState() => _DeviceScreenState();
}

class _DeviceScreenState extends State<DeviceScreen> {
  String searchQuery = '';
  String filterField = 'Tất cả';

  final List<String> filterOptions = [
    'Tất cả',
    'Tên thiết bị',
    'Model',
    'Hãng sản xuất',
    'Tình trạng',
    'Chu kỳ hiệu chuẩn',
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        backgroundColor: Colors.blue,
        centerTitle: true,
        title: const Text(
          'Quản lý thiết bị',
          style: TextStyle(color: Colors.white),
        ),
        iconTheme: const IconThemeData(color: Colors.white),
        actions: [
          IconButton(
            icon: const Icon(Icons.add, color: Colors.white),
            onPressed: () {
              showDialog(
                context: context,
                builder: (context) => const AddDeviceDialog(),
              );
            },
          ),
        ],
      ),

      // --- PHẦN THÂN ---
      body: Column(
        children: [
          // 🔍 Thanh tìm kiếm + Bộ lọc
          Padding(
            padding: const EdgeInsets.fromLTRB(12, 10, 12, 4),
            child: Row(
              children: [
                // 🔽 Dropdown chọn bộ lọc
                Container(
                  width: 120,
                  height: 40,
                  decoration: BoxDecoration(
                    color: Colors.grey.shade100, // nhẹ hơn 1 tông
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(color: Colors.grey.shade300), // viền nhạt
                  ),
                  child: DropdownButtonHideUnderline(
                    child: DropdownButton<String>(
                      value: filterField,
                      isExpanded: true,
                      icon: const Icon(Icons.arrow_drop_down, size: 20),
                      style: const TextStyle(fontSize: 14, color: Colors.black87),
                      items: filterOptions
                          .map((option) => DropdownMenuItem(
                                value: option,
                                child: Padding(
                                  padding: const EdgeInsets.symmetric(horizontal: 8),
                                  child: Text(option),
                                ),
                              ))
                          .toList(),
                      onChanged: (value) {
                        setState(() {
                          filterField = value!;
                          searchQuery = '';
                        });
                        FocusScope.of(context).unfocus();
                      },
                    ),
                  ),
                ),

                const SizedBox(width: 8), // khoảng cách giữa 2 ô

                // 🔍 Ô tìm kiếm
                Expanded(
                  child: SizedBox(
                    height: 40,
                    child: TextField(
                      decoration: InputDecoration(
                        hintText: 'Nhập từ khóa...',
                        hintStyle:
                            TextStyle(color: Colors.grey.shade600, fontSize: 14),
                        prefixIcon: const Icon(Icons.search, size: 20),
                        filled: true,
                        fillColor: Colors.grey.shade100, // đồng bộ màu nền
                        contentPadding:
                            const EdgeInsets.symmetric(vertical: 0, horizontal: 10),
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(8),
                          borderSide: BorderSide(color: Colors.grey.shade300), // viền nhạt
                        ),
                        enabledBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(8),
                          borderSide: BorderSide(color: Colors.grey.shade300),
                        ),
                        focusedBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(8),
                          borderSide: BorderSide(color: Colors.grey.shade400), // nhấn nhẹ khi focus
                        ),
                      ),
                      onChanged: (value) {
                        setState(() {
                          searchQuery = value.toLowerCase();
                        });
                      },
                    ),
                  ),
                ),
              ],
            ),
          ),



          // --- Danh sách thiết bị ---
          Expanded(
            child: StreamBuilder<QuerySnapshot>(
              stream: FirebaseFirestore.instance
                  .collection('devices')
                  .orderBy('createdAt', descending: true)
                  .snapshots(),
              builder: (context, snapshot) {
                if (snapshot.connectionState == ConnectionState.waiting) {
                  return const Center(child: CircularProgressIndicator());
                }
                if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
                  return const Center(child: Text('Chưa có thiết bị nào.'));
                }

                final devices = snapshot.data!.docs.where((doc) {
                  final data = doc.data() as Map<String, dynamic>;

                  final name = (data['name'] ?? '').toString().toLowerCase();
                  final model = (data['model'] ?? '').toString().toLowerCase();
                  final manufacturer =
                      (data['manufacturer'] ?? '').toString().toLowerCase();
                  final status =
                      (data['status'] ?? '').toString().toLowerCase();
                  final calibrationCycle =
                      (data['calibrationCycle'] ?? '').toString().toLowerCase();

                  if (searchQuery.isEmpty) return true;

                  switch (filterField) {
                    case 'Tên thiết bị':
                      return name.contains(searchQuery);
                    case 'Model':
                      return model.contains(searchQuery);
                    case 'Hãng sản xuất':
                      return manufacturer.contains(searchQuery);
                    case 'Tình trạng':
                      return status.contains(searchQuery);
                    case 'Chu kỳ hiệu chuẩn':
                      return calibrationCycle.contains(searchQuery);
                    default:
                      return name.contains(searchQuery) ||
                          model.contains(searchQuery) ||
                          manufacturer.contains(searchQuery) ||
                          status.contains(searchQuery) ||
                          calibrationCycle.contains(searchQuery);
                  }
                }).toList();

                if (devices.isEmpty) {
                  return const Center(child: Text('Không tìm thấy thiết bị nào.'));
                }

                return ListView.builder(
                  itemCount: devices.length,
                  itemBuilder: (context, index) {
                    final device = devices[index];
                    final data = device.data() as Map<String, dynamic>;

                    return Card(
                      elevation: 1.5,
                      margin: const EdgeInsets.symmetric(
                          horizontal: 12, vertical: 6),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(10),
                      ),
                      child: ListTile(
                        leading: CircleAvatar(
                          backgroundColor: Colors.blue.shade600,
                          child: const Icon(Icons.devices, color: Colors.white),
                        ),
                        title: Text(
                          data['name'] ?? 'Không có tên thiết bị',
                          style:
                              const TextStyle(fontWeight: FontWeight.w600),
                        ),
                        subtitle:
                            Text(data['status'] ?? 'Không rõ tình trạng'),
                        trailing:
                            const Icon(Icons.arrow_forward_ios, size: 16),
                        onTap: () {
                          Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (_) => DeviceDetailScreen(
                                deviceId: device.id,
                                deviceData: data,
                              ),
                            ),
                          );
                        },
                      ),
                    );
                  },
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}


// ====================== DIALOG THÊM THIẾT BỊ ======================
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
  final calibrationCycleController = TextEditingController();
  final purchaseDateController = TextEditingController();
  String? selectedStatus;

  final List<String> statusOptions = [
    'Đang hoạt động',
    'Hư hỏng',
    'Đang hiệu chuẩn',
    'Ngừng sử dụng',
  ];

  Future<void> addDevice() async {
    if (_formKey.currentState!.validate()) {
      await FirebaseFirestore.instance.collection('devices').add({
        'name': nameController.text.trim(),
        'model': modelController.text.trim(),
        'manufacturer': manufacturerController.text.trim(),
        'status': selectedStatus ?? 'Không rõ',
        'calibrationCycle': calibrationCycleController.text.trim(),
        'purchaseDate': purchaseDateController.text.trim(),
        'createdAt': Timestamp.now(),
      });

      if (mounted) {
        Navigator.pop(context);
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Thêm thiết bị thành công!')),
        );
      }
    }
  }

  InputDecoration _inputDecoration(String label) {
    return InputDecoration(
      labelText: label,
      filled: true,
      fillColor: Colors.grey.shade100,
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(10),
        borderSide: BorderSide.none,
      ),
      contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
    );
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      title: const Text(
        'Thêm thiết bị mới',
        style: TextStyle(fontWeight: FontWeight.bold),
      ),
      content: Form(
        key: _formKey,
        child: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              // 🔹 Tên thiết bị
              TextFormField(
                controller: nameController,
                decoration: _inputDecoration('Tên thiết bị'),
                validator: (value) =>
                    value == null || value.trim().isEmpty ? 'Nhập tên thiết bị' : null,
              ),
              const SizedBox(height: 12),

              // 🔹 Model / Serial
              TextFormField(
                controller: modelController,
                decoration: _inputDecoration('Model / Số serial'),
                validator: (value) =>
                    value == null || value.trim().isEmpty ? 'Nhập model hoặc số serial' : null,
              ),
              const SizedBox(height: 12),

              // 🔹 Hãng sản xuất
              TextFormField(
                controller: manufacturerController,
                decoration: _inputDecoration('Hãng sản xuất'),
                validator: (value) =>
                    value == null || value.trim().isEmpty ? 'Nhập hãng sản xuất' : null,
              ),
              const SizedBox(height: 12),

              // 🔹 Tình trạng
              DropdownButtonFormField<String>(
                decoration: _inputDecoration('Tình trạng'),
                value: selectedStatus,
                items: statusOptions
                    .map((status) => DropdownMenuItem(
                          value: status,
                          child: Text(status),
                        ))
                    .toList(),
                onChanged: (value) => setState(() => selectedStatus = value),
                validator: (value) => value == null ? 'Vui lòng chọn tình trạng' : null,
              ),
              const SizedBox(height: 12),

              // 🔹 Chu kỳ hiệu chuẩn
              TextFormField(
                controller: calibrationCycleController,
                decoration: _inputDecoration('Chu kỳ hiệu chuẩn (tháng)'),
                keyboardType: TextInputType.number,
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

              // 🔹 Ngày mua
              TextFormField(
                controller: purchaseDateController,
                readOnly: true,
                decoration: _inputDecoration('Ngày mua').copyWith(
                  suffixIcon: const Icon(
                    Icons.calendar_today,
                    size: 18,
                    color: Colors.black54,
                  ),
                ),
                validator: (value) =>
                    value == null || value.trim().isEmpty ? 'Chọn ngày mua' : null,
                onTap: () async {
                  FocusScope.of(context).requestFocus(FocusNode());
                  DateTime? pickedDate = await showDatePicker(
                    context: context,
                    initialDate: DateTime.now(),
                    firstDate: DateTime(2000),
                    lastDate: DateTime(2100),
                  );
                  if (pickedDate != null) {
                    purchaseDateController.text =
                        "${pickedDate.day}/${pickedDate.month}/${pickedDate.year}";
                  }
                },
              ),
            ],
          ),
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: const Text('Hủy'),
        ),
        ElevatedButton(
          onPressed: addDevice,
          style: ElevatedButton.styleFrom(
            backgroundColor: Colors.blue,
            foregroundColor: Colors.white,
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
          ),
          child: const Text('Thêm'),
        ),
      ],
    );
  }
}
