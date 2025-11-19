import 'dart:typed_data';

import 'package:flutter/material.dart';

import 'package:cloud_firestore/cloud_firestore.dart';

import 'package:printing/printing.dart';

import 'package:intl/intl.dart';



import '../../services/pdf/sample_report_pdf.dart';



class SampleReportScreen extends StatefulWidget {

  const SampleReportScreen({super.key});



  @override

  State<SampleReportScreen> createState() => _SampleReportScreenState();

}



class _SampleReportScreenState extends State<SampleReportScreen> {

  DateTime? from;

  DateTime? to;

  String status = "Tất cả";

  Color _getStatusColor(String status) {

    switch (status) {

      case "Đang phân tích":

        return Colors.orange;

      case "Đã trả kết quả":

        return Colors.green;

      case "Hoàn thành":

        return Colors.blue;

      default:

        return Colors.grey;

    }

  }



  final dateFormatter = DateFormat("dd/MM/yyyy");



  @override

  Widget build(BuildContext context) {

    return Scaffold(

      appBar: AppBar(

        backgroundColor: const Color(0xFF005BFF),

        elevation: 0,

        centerTitle: true, // căn giữa tiêu đề

        title: const Text(

          "Quản lý báo cáo mẫu",

          style: TextStyle(

            color: Colors.white,

            fontWeight: FontWeight.bold,

            fontSize: 20,

          ),

        ),

        leading: IconButton(

          icon: const Icon(Icons.arrow_back, color: Colors.white),

          onPressed: () => Navigator.pop(context),

        ),

       

      ),



      body: Column(

        children: [

          _buildFilterControls(),

          Expanded(child: _buildReportResults()),

        ],

      ),

    );

  }



  // ==============================================================

  //  FILTER UI

  // ==============================================================



  Widget _buildFilterControls() {

    return Padding(

      padding: const EdgeInsets.all(12),

      child: Row(

        children: [

          // TỪ NGÀY

          SizedBox(

            width: 160,

            child: _buildDateBox(

              label: from == null ? "Từ ngày" : dateFormatter.format(from!),

              onTap: () async {

                final d = await showDatePicker(

                  context: context,

                  firstDate: DateTime(2020),

                  lastDate: DateTime(2030),

                  initialDate: from ?? DateTime.now(),

                );

                if (d != null) setState(() => from = d);

              },

            ),

          ),



          const SizedBox(width: 10),



          // ĐẾN NGÀY

          SizedBox(

            width: 160,

            child: _buildDateBox(

              label: to == null ? "Đến ngày" : dateFormatter.format(to!),

              onTap: () async {

                final d = await showDatePicker(

                  context: context,

                  firstDate: DateTime(2020),

                  lastDate: DateTime(2030),

                  initialDate: to ?? DateTime.now(),

                );

                if (d != null) setState(() => to = d);

              },

            ),

          ),



          const Spacer(),



          // DROPDOWN TẤT CẢ

          Container(

            padding: const EdgeInsets.symmetric(horizontal: 16),

            decoration: BoxDecoration(

              color: const Color(0xFFF2F5FF),

              borderRadius: BorderRadius.circular(12),

              border: Border.all(color: Color(0xFFB7CEFF)),

            ),

            child: DropdownButtonHideUnderline(

              child: DropdownButton<String>(

                value: status,

                icon: const Icon(

                  Icons.keyboard_arrow_down_rounded,

                  color: Color(0xFF005BFF),

                ),

                items:

                    const [

                          "Tất cả",

                          "Đã trả kết quả",

                          "Đang phân tích",

                          "Hoàn thành",

                        ]

                        .map((e) => DropdownMenuItem(value: e, child: Text(e)))

                        .toList(),

                onChanged: (v) => setState(() => status = v!),

              ),

            ),

          ),

        ],

      ),

    );

  }



  Widget _buildDateBox({required String label, required VoidCallback onTap}) {

    return GestureDetector(

      onTap: onTap,

      child: Container(

        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 14),

        decoration: BoxDecoration(

          color: const Color(0xFFF2F5FF),

          borderRadius: BorderRadius.circular(12),

          border: Border.all(color: Color(0xFFB7CEFF)),

        ),

        child: Row(

          mainAxisAlignment: MainAxisAlignment.spaceBetween,

          children: [

            Text(label, style: const TextStyle(fontSize: 15)),

            const Icon(

              Icons.calendar_today_outlined,

              size: 18,

              color: Color(0xFF005BFF),

            ),

          ],

        ),

      ),

    );

  }



  // ==============================================================

  //  REPORT LIST

  // ==============================================================



  Widget _buildReportResults() {

    Query query = FirebaseFirestore.instance.collection('samples');



    if (status != "Tất cả") {

      query = query.where('status', isEqualTo: status);

    }



    return StreamBuilder<QuerySnapshot>(

      stream: query.snapshots(),

      builder: (context, snapshot) {

        if (!snapshot.hasData) {

          return const Center(child: CircularProgressIndicator());

        }



        final docs = snapshot.data!.docs;



        // Lọc theo ngày

        final filtered = docs.where((d) {

          final dateText = d['receivedDate']?.toString();

          DateTime? date;



          try {

            date = dateFormatter.parse(dateText ?? "");

          } catch (e) {

            return false;

          }



          if (from != null && date.isBefore(from!)) return false;

          if (to != null && date.isAfter(to!)) return false;



          return true;

        }).toList();



        if (filtered.isEmpty) {

          return const Center(child: Text("Không có dữ liệu"));

        }



        return ListView.builder(

          itemCount: filtered.length,

          itemBuilder: (_, i) {

            final s = filtered[i];



            return Container(

              margin: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),

              padding: const EdgeInsets.all(14),

              decoration: BoxDecoration(

                color: Colors.white,

                borderRadius: BorderRadius.circular(12),

                border: Border.all(color: const Color(0xFFE0E6F5)),

              ),

              child: Row(

                crossAxisAlignment: CrossAxisAlignment.start,

                children: [

                  // ============================================

                  //       CỘT TRÁI: THÔNG TIN MẪU

                  // ============================================

                  Expanded(

                    child: Column(

                      crossAxisAlignment: CrossAxisAlignment.start,

                      children: [

                        Text(

                          s['sampleCode'],

                          style: const TextStyle(

                            fontSize: 17,

                            fontWeight: FontWeight.bold,

                          ),

                        ),

                        const SizedBox(height: 4),

                        Text("Khách hàng: ${s['customerName']}"),

                        const SizedBox(height: 6),

                        Text("Ngày nhận: ${s['receivedDate']}"),

                      ],

                    ),

                  ),



                  // ============================================

                  //      CỘT PHẢI: PDF + TRẠNG THÁI

                  // ============================================

                  Column(

                    crossAxisAlignment: CrossAxisAlignment.end,

                    children: [

                      // ==== NÚT PDF ====

                      IconButton(

                        icon: const Icon(

                          Icons.picture_as_pdf,

                          color: Color(0xFF005BFF),

                          size: 22,

                        ),

                        onPressed: () async {

                          final Uint8List pdfBytes =

                              await SampleReportPDF.generate([

                                s.data() as Map<String, dynamic>,

                              ]);

                          await Printing.layoutPdf(

                            onLayout: (_) async => pdfBytes,

                          );

                        },

                      ),



                      const SizedBox(height: 6),



                      // ==== TRẠNG THÁI ====

                      Container(

                        padding: const EdgeInsets.symmetric(

                          horizontal: 10,

                          vertical: 6,

                        ),

                        decoration: BoxDecoration(

                          color: _getStatusColor(s['status']).withOpacity(0.15),

                          borderRadius: BorderRadius.circular(8),

                        ),

                        child: Text(

                          s['status'],

                          style: TextStyle(

                            fontSize: 14,

                            fontWeight: FontWeight.w600,

                            color: _getStatusColor(s['status']),

                          ),

                        ),

                      ),

                    ],

                  ),

                ],

              ),

            );

          },

        );

      },

    );

  }



  // ==============================================================

  //  EXPORT PDF

  // ==============================================================



  Future<void> _exportPdf() async {

    Query query = FirebaseFirestore.instance.collection('samples');



    if (status != "Tất cả") {

      query = query.where('status', isEqualTo: status);

    }



    final snapshot = await query.get();



    final filtered = snapshot.docs.where((d) {

      final dateText = d['receivedDate']?.toString();

      DateTime? date;



      try {

        date = dateFormatter.parse(dateText ?? "");

      } catch (e) {

        return false;

      }



      if (from != null && date.isBefore(from!)) return false;

      if (to != null && date.isAfter(to!)) return false;



      return true;

    }).toList();



    final data = filtered.map((e) => e.data() as Map<String, dynamic>).toList();



    final Uint8List pdfBytes = await SampleReportPDF.generate(data);



    await Printing.layoutPdf(onLayout: (_) async => pdfBytes);

  }

}