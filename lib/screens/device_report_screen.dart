import 'package:flutter/material.dart';

import 'package:cloud_firestore/cloud_firestore.dart';

import 'package:printing/printing.dart';

import '../../services/pdf/device_report_pdf.dart';



class DeviceReportScreen extends StatefulWidget {

  const DeviceReportScreen({super.key});



  @override

  State<DeviceReportScreen> createState() => _DeviceReportScreenState();

}



class _DeviceReportScreenState extends State<DeviceReportScreen> {

  String status = "Tất cả";



  @override

  Widget build(BuildContext context) {

    return Scaffold(

      appBar: AppBar(

        backgroundColor: const Color(0xFF005BFF),

        centerTitle: true,

        title: const Text(

          "Quản lý báo cáo thiết bị",

          style: TextStyle(

            color: Colors.white,

            fontSize: 18,

            fontWeight: FontWeight.w600,

          ),

        ),

      ),



      body: Column(

        children: [

          _buildTopBar(), // ⬅️ Thanh lọc mới giống UI bạn gửi

          Expanded(child: _buildList()),

        ],

      ),

    );

  }



  Widget _buildTopBar() {

    return Container(

      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),

      color: const Color(0xFFF7F6FF),

      child: Row(

        mainAxisAlignment: MainAxisAlignment.end,

        children: [

          // Nút xuất PDF

          ElevatedButton.icon(

            onPressed: _exportPDF,

            style: ElevatedButton.styleFrom(

              backgroundColor: const Color(0xFF005BFF),

              foregroundColor: Colors.white,

              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),

              shape: RoundedRectangleBorder(

                borderRadius: BorderRadius.circular(10),

              ),

            ),

            icon: const Icon(Icons.picture_as_pdf),

            label: const Text("PDF"),

          ),



          const SizedBox(width: 12),



          // Dropdown lọc trạng thái

          Container(

            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),

            decoration: BoxDecoration(

              color: Colors.white,

              borderRadius: BorderRadius.circular(10),

              border: Border.all(color: Colors.grey.shade300),

            ),

            child: DropdownButtonHideUnderline(

              child: DropdownButton<String>(

                value: status,

                items:

                    [

                          "Tất cả",

                          "Đang hoạt động",

                          "Hư hỏng",

                          "Đang hiệu chuẩn",

                          "Ngừng sử dụng",

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



  // ------------------------ LIST ------------------------

  Widget _buildList() {

    Query query = FirebaseFirestore.instance.collection('devices');



    if (status != "Tất cả") {

      query = query.where('status', isEqualTo: status);

    }



    return StreamBuilder(

      stream: query.snapshots(),

      builder: (context, snapshot) {

        if (!snapshot.hasData) {

          return const Center(child: CircularProgressIndicator());

        }



        final docs = snapshot.data!.docs;



        return ListView(

          children: docs.map((d) {

            return Container(

              margin: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),

              padding: const EdgeInsets.all(14),

              decoration: BoxDecoration(

                color: Colors.white,

                borderRadius: BorderRadius.circular(12),

                border: Border.all(color: Colors.grey.shade300),

                boxShadow: [

                  BoxShadow(

                    color: Colors.black.withOpacity(0.05),

                    blurRadius: 6,

                    offset: const Offset(0, 3),

                  ),

                ],

              ),



              child: Column(

                crossAxisAlignment: CrossAxisAlignment.start,

                children: [

                  Text(

                    d['name'],

                    style: const TextStyle(

                      fontSize: 16,

                      fontWeight: FontWeight.bold,

                    ),

                  ),

                  const SizedBox(height: 4),

                  Text("Model: ${d['model']}"),

                  const SizedBox(height: 8),

                  Row(

                    mainAxisAlignment: MainAxisAlignment.end,

                    children: [

                      Container(

                        padding: const EdgeInsets.symmetric(

                          horizontal: 10,

                          vertical: 4,

                        ),

                        decoration: BoxDecoration(

                          color: Colors.blue.shade50,

                          borderRadius: BorderRadius.circular(8),

                        ),

                        child: Text(

                          d['status'],

                          style: const TextStyle(

                            color: Colors.blue,

                            fontWeight: FontWeight.w600,

                          ),

                        ),

                      ),

                    ],

                  ),

                ],

              ),

            );

          }).toList(),

        );

      },

    );

  }



  // ------------------------ EXPORT PDF ------------------------

  Future<void> _exportPDF() async {

    Query query = FirebaseFirestore.instance.collection('devices');



    if (status != "Tất cả") {

      query = query.where('status', isEqualTo: status);

    }



    final snap = await query.get();



    final deviceList = snap.docs

        .map(

          (d) => {

            "name": d['name'],

            "model": d['model'],

            "status": d['status'],

          },

        )

        .toList();



    final pdf = await DeviceReportPDF.generate(

      status: status,

      devices: deviceList,

    );



    await Printing.layoutPdf(onLayout: (format) => pdf);

  }

}