import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:pdf/pdf.dart';
import 'package:printing/printing.dart';

class ApplicationSubmittedPage extends StatelessWidget {
  final String applicationId;
  final DateTime submittedDate;
  final String status;

  const ApplicationSubmittedPage({
    super.key,
    required this.applicationId,
    required this.submittedDate,
    required this.status,
  });

  /// 🔹 Generate PDF for Application Copy
  Future<void> _generatePdf(BuildContext context) async {
    final pdf = pw.Document();

    pdf.addPage(
      pw.Page(
        build: (pw.Context context) {
          return pw.Padding(
            padding: const pw.EdgeInsets.all(24),
            child: pw.Column(
              crossAxisAlignment: pw.CrossAxisAlignment.start,
              children: [
                pw.Text("Application Copy",
                    style: pw.TextStyle(
                        fontSize: 22, fontWeight: pw.FontWeight.bold)),
                pw.SizedBox(height: 20),
                pw.Text("Application ID: $applicationId",
                    style: const pw.TextStyle(fontSize: 16)),
                pw.Text("Submitted: ${DateFormat.yMMMd().format(submittedDate)}",
                    style: const pw.TextStyle(fontSize: 16)),
                pw.Text("Status: $status",
                    style: const pw.TextStyle(fontSize: 16)),
                pw.SizedBox(height: 20),
                pw.Text(
                  "Thank you for submitting your application. You will receive updates regarding further review and approval.",
                  style: const pw.TextStyle(fontSize: 14),
                ),
              ],
            ),
          );
        },
      ),
    );

    await Printing.layoutPdf(
      onLayout: (PdfPageFormat format) async => pdf.save(),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFEFF6FF), // light blue bg
      body: SafeArea(
        child: Center(
          child: SingleChildScrollView(
            child: Container(
              margin: const EdgeInsets.all(20),
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(16),
                boxShadow: [
                  BoxShadow(
                    // ignore: deprecated_member_use
                    color: Colors.black.withOpacity(0.05),
                    blurRadius: 10,
                    offset: const Offset(0, 4),
                  ),
                ],
              ),
              child: Column(
                children: [
                  const Icon(Icons.check_circle,
                      color: Colors.green, size: 60),
                  const SizedBox(height: 12),
                  const Text(
                    "Application Submitted!",
                    style: TextStyle(
                      fontSize: 22,
                      fontWeight: FontWeight.bold,
                      color: Colors.black87,
                    ),
                  ),
                  const SizedBox(height: 8),
                  const Text(
                    "Your membership application has been successfully submitted and is now under review.",
                    textAlign: TextAlign.center,
                    style: TextStyle(fontSize: 14, color: Colors.black54),
                  ),
                  const SizedBox(height: 20),

                  // 🔹 Application Info
                  _buildInfoRow("Application ID", applicationId),
                  _buildInfoRow(
                      "Submitted", DateFormat.yMMMd().format(submittedDate)),
                  _buildInfoRow("Status", status, statusColor: Colors.orange),

                  const SizedBox(height: 20),

                  // 🔹 Progress Steps
                  _buildStep(1, "Application Received",
                      "Your application has been received and assigned for review", true),
                  _buildStep(2, "Block Admin Review",
                      "Pending review by block administrator", false),
                  _buildStep(3, "Final Approval",
                      "Final approval and membership activation", false),

                  const SizedBox(height: 20),

                  // 🔹 Notice
                  Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: Colors.yellow.shade100,
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Row(
                      children: [
                        const Icon(Icons.warning, color: Colors.black87),
                        const SizedBox(width: 8),
                        Expanded(
                          child: Text(
                            "Please keep your application ID safe. You may need it for future reference and status inquiries.",
                            style: const TextStyle(
                                fontSize: 13, color: Colors.black87),
                          ),
                        ),
                      ],
                    ),
                  ),

                  const SizedBox(height: 20),

                  // 🔹 Buttons
                  ElevatedButton(
                    onPressed: () {
                      // You can navigate to Application Status Page
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(
                            content: Text("Navigating to Application Status...")),
                      );
                    },
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.blue,
                      minimumSize: const Size(double.infinity, 48),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(8),
                      ),
                    ),
                    child: const Text("View Application Status"),
                  ),

                  const SizedBox(height: 12),

                  OutlinedButton(
                    onPressed: () => _generatePdf(context),
                    style: OutlinedButton.styleFrom(
                      minimumSize: const Size(double.infinity, 48),
                      side: const BorderSide(color: Colors.grey),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(8),
                      ),
                    ),
                    child: const Text("Download Application Copy"),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  /// 🔹 Info row widget
  Widget _buildInfoRow(String label, String value, {Color? statusColor}) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        children: [
          Expanded(
            child: Text(
              "$label:",
              style: const TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w500,
                  color: Colors.black54),
            ),
          ),
          Text(
            value,
            style: TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.w600,
              color: statusColor ?? Colors.black87,
            ),
          ),
        ],
      ),
    );
  }

  /// 🔹 Step widget
  Widget _buildStep(int number, String title, String subtitle, bool completed) {
    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: completed ? Colors.blue.shade50 : Colors.grey.shade100,
        borderRadius: BorderRadius.circular(8),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          CircleAvatar(
            radius: 14,
            backgroundColor: completed ? Colors.blue : Colors.grey,
            child: Text(
              number.toString(),
              style: const TextStyle(color: Colors.white, fontSize: 13),
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(title,
                    style: TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.bold,
                        color:
                            completed ? Colors.blue.shade800 : Colors.black87)),
                const SizedBox(height: 4),
                Text(subtitle,
                    style: const TextStyle(fontSize: 12, color: Colors.black54)),
              ],
            ),
          )
        ],
      ),
    );
  }
}
