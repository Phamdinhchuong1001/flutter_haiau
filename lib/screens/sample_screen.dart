import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:flutter_haiau/models/sample_model.dart';
import 'sample_detail_screen.dart';

class SampleScreen extends StatefulWidget {
  const SampleScreen({super.key});

  @override
  State<SampleScreen> createState() => _SampleScreenState();
}

class _SampleScreenState extends State<SampleScreen> {
  String searchQuery = '';
  String filterField = 'Tất cả';

  final List<String> filterOptions = [
    'Tất cả',
    'Mã mẫu',
    'Khách hàng',
    'Loại mẫu',
    'Trạng thái',
  ];

  Color _getStatusColor(SampleStatus status) {
    switch (status) {
      case SampleStatus.analyzing:
        return Colors.orange.shade700;
      case SampleStatus.completed:
        return Colors.green.shade700;
      case SampleStatus.resultReturned:
        return const Color(0xFF005BFF);
      default:
        return Colors.grey.shade700;
    }
  }

  Widget _buildStatusTag(SampleStatus status) {
    final statusText = statusToString(status);
    final color = _getStatusColor(status);

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: color.withOpacity(0.15),
        borderRadius: BorderRadius.circular(6),
      ),
      child: Text(
        statusText,
        style: TextStyle(
          color: color,
          fontWeight: FontWeight.w600,
          fontSize: 12,
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final List<SampleModel> allSamples = SampleModel.mockSamples;

    final filteredSamples = allSamples.where((sample) {
      final query = searchQuery.toLowerCase().trim();

      if (query.isEmpty) return true;

      final sampleCode = sample.sampleCode.toLowerCase();
      final customerName = sample.customerName.toLowerCase();
      final sampleType = sample.sampleType.toLowerCase();
      final status = statusToString(sample.status).toLowerCase();

      switch (filterField) {
        case 'Mã mẫu':
          return sampleCode.contains(query);
        case 'Khách hàng':
          return customerName.contains(query);
        case 'Loại mẫu':
          return sampleType.contains(query);
        case 'Trạng thái':
          return status.contains(query);
        default:
          return sampleCode.contains(query) ||
              customerName.contains(query) ||
              sampleType.contains(query) ||
              status.contains(query);
      }
    }).toList();

    return Scaffold(
      appBar: AppBar(
        backgroundColor: const Color(0xFF005BFF),
        centerTitle: true,
        title: const Text('Quản lý Mẫu', style: TextStyle(color: Colors.white)),
        iconTheme: const IconThemeData(color: Colors.white),
        actions: [
          IconButton(
            icon: const Icon(Icons.add_box, color: Colors.white),
            onPressed: () {
              showDialog(
                context: context,
                builder: (context) => const AddSampleDialog(),
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
                          searchQuery = '';
                        });
                        FocusScope.of(context).unfocus();
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
                        hintText: 'Nhập từ khóa...',
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
                          searchQuery = value.toLowerCase();
                        });
                      },
                    ),
                  ),
                ),
              ],
            ),
          ),

          Expanded(
            child: filteredSamples.isEmpty
                ? const Center(child: Text('Không tìm thấy mẫu nào phù hợp.'))
                : ListView.builder(
                    itemCount: filteredSamples.length,
                    itemBuilder: (context, index) {
                      final sample = filteredSamples[index];

                      return Card(
                        elevation: 1.5,
                        margin: const EdgeInsets.symmetric(
                          horizontal: 12,
                          vertical: 6,
                        ),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(10),
                        ),
                        child: ListTile(
                          leading: CircleAvatar(
                            backgroundColor: Colors.blue.shade600,
                            child: const Icon(
                              Icons.science,
                              color: Colors.white,
                            ),
                          ),
                          title: Text(
                            'Mã mẫu: ${sample.sampleCode}',
                            style: const TextStyle(fontWeight: FontWeight.w600),
                          ),
                          subtitle: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              const SizedBox(height: 2),
                              Text('Khách hàng: ${sample.customerName}'),
                              Text('Loại: ${sample.sampleType}'),
                              Text('Ngày nhận: ${sample.receivedDate}'),
                            ],
                          ),
                          trailing: _buildStatusTag(sample.status),
                          onTap: () {
                            Navigator.push(
                              context,
                              MaterialPageRoute(
                                builder: (_) =>
                                    SampleDetailScreen(sample: sample),
                              ),
                            );
                          },
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

class AddSampleDialog extends StatefulWidget {
  const AddSampleDialog({super.key});

  @override
  State<AddSampleDialog> createState() => _AddSampleDialogState();
}

class _AddSampleDialogState extends State<AddSampleDialog> {
  final _formKey = GlobalKey<FormState>();
  final sampleCodeController = TextEditingController();
  final customerNameController = TextEditingController();
  final sampleTypeController = TextEditingController();
  final receivedDateController = TextEditingController();

  SampleStatus _selectedStatus = SampleStatus.analyzing;

  final List<SampleStatus> statusOptions = SampleStatus.values.toList();

  Future<void> addSample() async {
    if (_formKey.currentState!.validate()) {
      if (mounted) {
        Navigator.pop(context);
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Demo: Đã thêm mẫu mới (Không lưu vào DB)!'),
          ),
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
        'Thêm Mẫu mới',
        style: TextStyle(fontWeight: FontWeight.bold),
      ),
      content: Form(
        key: _formKey,
        child: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextFormField(
                controller: sampleCodeController,
                decoration: _inputDecoration('Mã mẫu'),
                validator: (value) => value == null || value.trim().isEmpty
                    ? 'Nhập mã mẫu'
                    : null,
              ),
              const SizedBox(height: 12),

              TextFormField(
                controller: customerNameController,
                decoration: _inputDecoration('Tên khách hàng'),
                validator: (value) => value == null || value.trim().isEmpty
                    ? 'Nhập tên khách hàng'
                    : null,
              ),
              const SizedBox(height: 12),

              TextFormField(
                controller: sampleTypeController,
                decoration: _inputDecoration('Loại mẫu (ví dụ: Nước, Đất...)'),
                validator: (value) => value == null || value.trim().isEmpty
                    ? 'Nhập loại mẫu'
                    : null,
              ),
              const SizedBox(height: 12),

              TextFormField(
                controller: receivedDateController,
                readOnly: true,
                decoration: _inputDecoration('Ngày nhận mẫu').copyWith(
                  suffixIcon: const Icon(
                    Icons.calendar_today,
                    size: 18,
                    color: Colors.black54,
                  ),
                ),
                validator: (value) => value == null || value.trim().isEmpty
                    ? 'Chọn ngày nhận'
                    : null,
                onTap: () async {
                  FocusScope.of(context).requestFocus(FocusNode());
                  DateTime? pickedDate = await showDatePicker(
                    context: context,
                    initialDate: DateTime.now(),
                    firstDate: DateTime(2000),
                    lastDate: DateTime(2100),
                  );
                  if (pickedDate != null) {
                    receivedDateController.text =
                        "${pickedDate.day}/${pickedDate.month}/${pickedDate.year}";
                  }
                },
              ),
              const SizedBox(height: 12),

              DropdownButtonFormField<SampleStatus>(
                decoration: _inputDecoration('').copyWith(
                  prefixIcon: const Icon(
                    Icons.info_outline,
                    color: Colors.blue,
                  ),
                ),
                value: _selectedStatus,
                items: statusOptions
                    .map(
                      (status) => DropdownMenuItem<SampleStatus>(
                        value: status,
                        child: Text(statusToString(status)),
                      ),
                    )
                    .toList(),
                onChanged: (value) => setState(() => _selectedStatus = value!),
                validator: (value) =>
                    value == null ? 'Vui lòng chọn trạng thái' : null,
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
          onPressed: addSample,
          style: ElevatedButton.styleFrom(
            backgroundColor: Colors.blue,
            foregroundColor: Colors.white,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(10),
            ),
          ),
          child: const Text('Thêm'),
        ),
      ],
    );
  }
}
