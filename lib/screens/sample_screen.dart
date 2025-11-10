import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:flutter_haiau/models/sample_model.dart';
import 'sample_detail_screen.dart';
import 'package:cloud_functions/cloud_functions.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter_haiau/services/auth_service.dart';
import 'package:flutter_haiau/models/user_model.dart';
import 'dart:async';

final FirebaseFunctions functions = FirebaseFunctions.instance;

class SampleScreen extends StatefulWidget {
  const SampleScreen({super.key});

  @override
  State<SampleScreen> createState() => _SampleScreenState();
}

class _SampleScreenState extends State<SampleScreen> {
  final AuthService _auth = AuthService();
  final User? currentUser = FirebaseAuth.instance.currentUser;

  bool _isLoading = true;
  bool _isLoadingMore = false;
  bool _hasMoreData = true;
  List<DocumentSnapshot> _sampleDocs = [];
  DocumentSnapshot? _lastDocument;
  final int _pageSize = 10;

  final ScrollController _scrollController = ScrollController();
  Timer? _debounce;

  String searchQuery = '';
  String filterField = 'Tất cả';
  final List<String> filterOptions = [
    'Tất cả',
    'Mã mẫu',
    'Khách hàng',
    'Loại mẫu',
    'Trạng thái',
  ];
  @override
  void initState() {
    super.initState();
    _fetchInitialSamples();
    _scrollController.addListener(_onScroll);
  }

  @override
  void dispose() {
    _scrollController.removeListener(_onScroll);
    _scrollController.dispose();
    _debounce?.cancel();
    super.dispose();
  }

  void _onScroll() {
    if (!_hasMoreData || _isLoadingMore) return;
    if (_scrollController.position.pixels >=
        _scrollController.position.maxScrollExtent - 100) {
      _fetchMoreSamples();
    }
  }

  Future<void> _fetchInitialSamples() async {
    setState(() {
      _isLoading = true;
    });

    try {
      Query query = _buildBaseQuery();
      final querySnapshot = await query.limit(_pageSize).get();
      if (mounted) {
        setState(() {
          _sampleDocs = querySnapshot.docs;
          if (querySnapshot.docs.isNotEmpty) {
            _lastDocument = querySnapshot.docs.last;
          }
          _hasMoreData = querySnapshot.docs.length == _pageSize;
          _isLoading = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() => _isLoading = false);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Lỗi tải dữ liệu: ${e.toString()}')),
        );
      }
    }
  }

  Future<void> _fetchMoreSamples() async {
    setState(() {
      _isLoadingMore = true;
    });
    try {
      Query query = _buildBaseQuery();
      if (_lastDocument != null) {
        query = query.startAfterDocument(_lastDocument!);
      }

      final querySnapshot = await query.limit(_pageSize).get();

      if (mounted) {
        setState(() {
          if (querySnapshot.docs.isNotEmpty) {
            _lastDocument = querySnapshot.docs.last;
          }
          _sampleDocs.addAll(querySnapshot.docs);
          _hasMoreData = querySnapshot.docs.length == _pageSize;
          _isLoadingMore = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() => _isLoadingMore = false);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Lỗi tải thêm dữ liệu: ${e.toString()}')),
        );
      }
    }
  }

  Query _buildBaseQuery() {
    Query query = FirebaseFirestore.instance
        .collection('samples')
        .orderBy('createdAt', descending: true);

    if (searchQuery.isNotEmpty && filterField != 'Tất cả') {
      String fieldToQuery;
      switch (filterField) {
        case 'Mã mẫu':
          fieldToQuery = 'sampleCode';
          break;
        case 'Khách hàng':
          fieldToQuery = 'customerName';
          break;
        case 'Loại mẫu':
          fieldToQuery = 'sampleType';
          break;
        case 'Trạng thái':
          fieldToQuery = 'status';
          break;
        default:
          fieldToQuery = 'sampleCode';
      }

      query = FirebaseFirestore.instance
          .collection('samples')
          .orderBy(fieldToQuery)
          .where(fieldToQuery, isGreaterThanOrEqualTo: searchQuery)
          .where(fieldToQuery, isLessThanOrEqualTo: '$searchQuery\uf8ff');
    }

    return query;
  }

  void _onSearchChanged() {
    _sampleDocs = [];
    _lastDocument = null;
    _hasMoreData = true;
    _fetchInitialSamples();
  }

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
    return StreamBuilder<UserModel?>(
      stream: _auth.streamUser(currentUser?.uid),
      builder: (context, snapshot) {
        final userRole = snapshot.data?.role ?? 'nhanvien';
        final bool isAdmin = (userRole == 'admin');

        return Scaffold(
          appBar: AppBar(
            backgroundColor: const Color(0xFF005BFF),
            centerTitle: true,
            title: const Text(
              'Quản lý Mẫu',
              style: TextStyle(color: Colors.white),
            ),
            iconTheme: const IconThemeData(color: Colors.white),
            actions: [
              if (isAdmin)
                IconButton(
                  icon: const Icon(Icons.add_box, color: Colors.white),
                  onPressed: () async {
                    final result = await showDialog(
                      context: context,
                      builder: (context) => const AddSampleDialog(),
                      barrierDismissible: false,
                    );
                    if (result == true) {
                      _onSearchChanged();
                    }
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
                            _onSearchChanged();
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
                              borderSide: BorderSide(
                                color: Colors.grey.shade300,
                              ),
                            ),
                            enabledBorder: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(8),
                              borderSide: BorderSide(
                                color: Colors.grey.shade300,
                              ),
                            ),
                            focusedBorder: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(8),
                              borderSide: BorderSide(
                                color: Colors.grey.shade400,
                              ),
                            ),
                          ),
                          onChanged: (value) {
                            setState(() {
                              searchQuery = value;
                            });
                            if (_debounce?.isActive ?? false)
                              _debounce!.cancel();
                            _debounce = Timer(
                              const Duration(milliseconds: 500),
                              _onSearchChanged,
                            );
                          },
                          onSubmitted: (value) => {
                            _debounce?.cancel(),
                            _onSearchChanged(),
                          },
                        ),
                      ),
                    ),
                  ],
                ),
              ),

              Expanded(
                child: _isLoading
                    ? const Center(child: CircularProgressIndicator())
                    : _sampleDocs.isEmpty
                    ? const Center(child: Text('Không tìm thấy mẫu nào.'))
                    : ListView.builder(
                        controller: _scrollController,
                        itemCount: _sampleDocs.length + 1,
                        itemBuilder: (context, index) {
                          if (index == _sampleDocs.length) {
                            if (_isLoadingMore) {
                              return const Center(
                                child: Padding(
                                  padding: EdgeInsets.all(16.0),
                                  child: CircularProgressIndicator(),
                                ),
                              );
                            }
                            if (!_hasMoreData) {
                              return const Center(
                                child: Padding(padding: EdgeInsets.all(16.0)),
                              );
                            }
                            return const SizedBox.shrink();
                          }

                          final doc = _sampleDocs[index];
                          final sample = SampleModel.fromMap(
                            doc.data() as Map<String, dynamic>,
                            doc.id,
                          );

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
                                backgroundColor: _getStatusColor(sample.status),
                                child: const Icon(
                                  Icons.science,
                                  color: Colors.white,
                                ),
                              ),
                              title: Text(
                                'Mã mẫu: ${sample.sampleCode}',
                                style: const TextStyle(
                                  fontWeight: FontWeight.w600,
                                ),
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
                              onTap: () async {
                                final result = await Navigator.push(
                                  context,
                                  MaterialPageRoute(
                                    builder: (_) =>
                                        SampleDetailScreen(sample: sample),
                                  ),
                                );
                                if (result == true) {
                                  _onSearchChanged();
                                }
                              },
                            ),
                          );
                        },
                      ),
              ),
            ],
          ),
        );
      },
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

  final customerNameController = TextEditingController();
  final sampleTypeController = TextEditingController();
  final receivedDateController = TextEditingController();

  SampleStatus _selectedStatus = SampleStatus.analyzing;
  final List<SampleStatus> statusOptions = SampleStatus.values.toList();

  String? _autoGeneratedSampleCode;
  int? _nextSequence;
  bool _isGeneratingCode = true;
  String _errorMessage = '';
  bool _isSubmitting = false;

  @override
  void initState() {
    super.initState();
    _fetchNewSampleCode();
  }

  Future<void> _fetchNewSampleCode() async {
    setState(() {
      _isGeneratingCode = true;
      _errorMessage = '';
    });
    try {
      final HttpsCallable callable = functions.httpsCallable(
        'getNewSampleCode',
      );
      final result = await callable.call();

      if (mounted) {
        setState(() {
          _autoGeneratedSampleCode = result.data['sampleCode'];
          _nextSequence = result.data['nextSequence'];
          _isGeneratingCode = false;
        });
      }
    } on FirebaseFunctionsException catch (e) {
      if (mounted) {
        setState(() {
          _errorMessage = 'Lỗi tạo mã: ${e.message}';
          _isGeneratingCode = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _errorMessage = 'Lỗi kết nối khi tạo mã.';
          _isGeneratingCode = false;
        });
      }
    }
  }

  Future<void> addSample() async {
    if (_formKey.currentState!.validate() && _autoGeneratedSampleCode != null) {
      setState(() {
        _isSubmitting = true;
      });
      final data = {
        'sampleCode': _autoGeneratedSampleCode!,
        'customerName': customerNameController.text.trim(),
        'sampleType': sampleTypeController.text.trim(),
        'receivedDate': receivedDateController.text.trim(),
        'status': statusToString(_selectedStatus),
        'nextSequence': _nextSequence,
      };

      try {
        final HttpsCallable callable = functions.httpsCallable('addSample');
        await callable.call(data);

        if (mounted) {
          Navigator.pop(context, true);
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('Đã thêm mẫu mới: ${_autoGeneratedSampleCode!}'),
              backgroundColor: Colors.green,
            ),
          );
        }
      } on FirebaseFunctionsException catch (e) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(
                'Lỗi thêm mẫu: ${e.message ?? 'Lỗi không xác định'}',
              ),
              backgroundColor: Colors.red,
            ),
          );
        }
      } catch (e) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Lỗi kết nối hoặc server.'),
              backgroundColor: Colors.red,
            ),
          );
        }
      } finally {
        if (mounted) {
          setState(() {
            _isSubmitting = false;
          });
        }
      }
    } else if (_autoGeneratedSampleCode == null && _errorMessage.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Vui lòng đợi mã mẫu được tạo.')),
      );
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
              if (_isGeneratingCode)
                Container(
                  padding: const EdgeInsets.symmetric(vertical: 16),
                  child: const Center(child: CircularProgressIndicator()),
                )
              else if (_errorMessage.isNotEmpty)
                Container(
                  padding: const EdgeInsets.all(8),
                  color: Colors.red.withOpacity(0.1),
                  child: Text(
                    _errorMessage,
                    style: const TextStyle(color: Colors.red),
                  ),
                )
              else
                TextFormField(
                  controller: TextEditingController(
                    text: _autoGeneratedSampleCode,
                  ),
                  readOnly: true,
                  decoration: _inputDecoration('Mã mẫu').copyWith(
                    fillColor: Colors.lightBlue.shade50,
                    suffixIcon: const Icon(
                      Icons.lock,
                      size: 18,
                      color: Colors.blueGrey,
                    ),
                  ),
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
                decoration: _inputDecoration('Loại mẫu'),
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
          onPressed:
              _isGeneratingCode || _errorMessage.isNotEmpty || _isSubmitting
              ? null
              : addSample,
          style: ElevatedButton.styleFrom(
            backgroundColor: Colors.blue,
            foregroundColor: Colors.white,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(10),
            ),
          ),
          child: _isSubmitting
              ? const SizedBox(
                  height: 20,
                  width: 20,
                  child: CircularProgressIndicator(
                    strokeWidth: 2,
                    color: Colors.white,
                  ),
                )
              : const Text('Thêm'),
        ),
      ],
    );
  }
}
