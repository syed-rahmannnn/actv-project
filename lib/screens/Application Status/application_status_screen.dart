import 'package:flutter/material.dart';
import '../../services/application_status_service.dart';

// Stage model for dynamic UI rendering
class ApplicationStage {
  final String name;
  final String displayName;
  final String status; // 'pending', 'in_progress', 'approved', 'rejected'
  final String? reviewer;
  final DateTime? reviewDate;
  final String? message;
  final Color statusColor;
  final IconData icon;
  final bool isCompleted;
  final bool isActive;

  ApplicationStage({
    required this.name,
    required this.displayName,
    required this.status,
    this.reviewer,
    this.reviewDate,
    this.message,
    required this.statusColor,
    required this.icon,
    required this.isCompleted,
    required this.isActive,
  });

  String get statusDisplayText {
    switch (status) {
      case 'approved':
        return 'Approved';
      case 'in_progress':
        return 'In progress';
      case 'rejected':
        return 'Rejected';
      default:
        return 'Pending';
    }
  }
}

class ApplicationStatusScreen extends StatefulWidget {
  const ApplicationStatusScreen({super.key});

  @override
  State<ApplicationStatusScreen> createState() =>
      _ApplicationStatusScreenState();
}

class _ApplicationStatusScreenState extends State<ApplicationStatusScreen> {
  ApplicationData? applicationData;
  bool isLoading = true;
  String? errorMessage;
  List<ApplicationStage> stages = [];

  @override
  void initState() {
    super.initState();
    _fetchApplicationStatus();
  }

  Future<void> _fetchApplicationStatus() async {
    try {
      setState(() {
        isLoading = true;
        errorMessage = null;
      });

      final response = await ApplicationStatusService.fetchApplicationStatus();

      if (response.applications.isNotEmpty) {
        setState(() {
          applicationData =
              response.applications.first; // Get the latest application
          stages = _buildStagesFromData(applicationData!);
          isLoading = false;
        });
      } else {
        setState(() {
          errorMessage = 'No application found';
          isLoading = false;
        });
      }
    } catch (e) {
      setState(() {
        errorMessage = 'Failed to load application status: $e';
        isLoading = false;
      });
    }
  }

  // Dynamic stage mapping from backend data
  List<ApplicationStage> _buildStagesFromData(ApplicationData data) {
    return [
      // Block Admin Review Stage
      ApplicationStage(
        name: 'block_admin',
        displayName: 'Block Admin Review',
        status: _getStageStatus('block', data),
        reviewer: data.assignedBlockAdmin?.fullName ?? 'Block Admin',
        reviewDate: data.blockApprovedAt,
        message: _getStageMessage('block', data),
        statusColor: _getStageColor('block', data),
        icon: _getStageIcon('block', data),
        isCompleted: data.isBlockApproved,
        isActive: data.status == 'Pending-Block',
      ),

      // District Admin Review Stage
      ApplicationStage(
        name: 'district_admin',
        displayName: 'District Admin Review',
        status: _getStageStatus('district', data),
        reviewer: data.assignedDistrictAdmin?.fullName ?? 'District Admin',
        reviewDate: data.districtApprovedAt,
        message: _getStageMessage('district', data),
        statusColor: _getStageColor('district', data),
        icon: _getStageIcon('district', data),
        isCompleted: data.isDistrictApproved,
        isActive: data.status == 'Pending-District',
      ),

      // State Admin Review Stage
      ApplicationStage(
        name: 'state_admin',
        displayName: 'State Admin Review',
        status: _getStageStatus('state', data),
        reviewer: data.assignedStateAdmin?.fullName ?? 'State Admin',
        reviewDate: data.stateApprovedAt,
        message: _getStageMessage('state', data),
        statusColor: _getStageColor('state', data),
        icon: _getStageIcon('state', data),
        isCompleted: data.isStateApproved,
        isActive: data.status == 'Pending-State',
      ),

      // Payment Stage
      ApplicationStage(
        name: 'payment',
        displayName: 'Ready for Payment',
        status: data.status == 'Approved' ? 'approved' : 'pending',
        reviewer: 'ACTIV Super Admin',
        reviewDate: null,
        message: data.status == 'Approved'
            ? 'Your application has been approved. Please proceed to payment.'
            : '',
        statusColor: data.status == 'Approved' ? Colors.green : Colors.blue,
        icon: data.status == 'Approved' ? Icons.check : Icons.payment,
        isCompleted: data.status == 'Approved',
        isActive: false,
      ),
    ];
  }

  String _getStageStatus(String stageType, ApplicationData data) {
    if (data.isRejected) return 'rejected';

    switch (stageType) {
      case 'block':
        if (data.isBlockApproved) return 'approved';
        if (data.status == 'Pending-Block') return 'in_progress';
        return 'pending';
      case 'district':
        if (data.isDistrictApproved) return 'approved';
        if (data.status == 'Pending-District') return 'in_progress';
        return 'pending';
      case 'state':
        if (data.isStateApproved) return 'approved';
        if (data.status == 'Pending-State') return 'in_progress';
        return 'pending';
      default:
        return 'pending';
    }
  }

  Color _getStageColor(String stageType, ApplicationData data) {
    final status = _getStageStatus(stageType, data);
    switch (status) {
      case 'approved':
        return Colors.green;
      case 'in_progress':
        return Colors.orange;
      case 'rejected':
        return Colors.red;
      default:
        return Colors.blue;
    }
  }

  IconData _getStageIcon(String stageType, ApplicationData data) {
    final status = _getStageStatus(stageType, data);
    switch (status) {
      case 'approved':
        return Icons.check;
      case 'in_progress':
        return Icons.hourglass_empty;
      case 'rejected':
        return Icons.close;
      default:
        return Icons.circle;
    }
  }

  String _getStageMessage(String stageType, ApplicationData data) {
    final status = _getStageStatus(stageType, data);

    switch (status) {
      case 'approved':
        switch (stageType) {
          case 'block':
            return 'All documents verified. Profile looks good.';
          case 'district':
            return 'District level verification completed.';
          case 'state':
            return 'State level verification completed.';
          default:
            return 'Stage completed successfully.';
        }
      case 'in_progress':
        return 'Your application is currently being reviewed. You will be notified once this stage is complete.';
      case 'rejected':
        return data.rejectionReason ?? 'Application rejected at this stage.';
      default:
        return '';
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Container(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [
              Color(0xFFC5E2FF), // Light blue from color picker
              Color(0xFFE6E8FF), // Light purple/blue from color picker
            ],
          ),
        ),
        child: SafeArea(
          child: Column(
            children: [
              // Custom Header
              Padding(
                padding: const EdgeInsets.fromLTRB(20, 24, 20, 8),
                child: Column(
                  children: [
                    const Text(
                      'Application Status',
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        fontSize: 24,
                        fontWeight: FontWeight.w700,
                        color: Colors.black87,
                        letterSpacing: 0.5,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      'Track your membership approval progress',
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w400,
                        color: const Color.fromARGB(255, 15, 15, 15),
                        height: 1.3,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 16),
              Expanded(child: _buildBody()),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildBody() {
    if (isLoading) {
      return const Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            CircularProgressIndicator(),
            SizedBox(height: 16),
            Text(
              'Loading application status...',
              style: TextStyle(fontSize: 16, color: Colors.grey),
            ),
          ],
        ),
      );
    }

    if (errorMessage != null) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.error_outline, size: 64, color: Colors.red[400]),
            const SizedBox(height: 16),
            Text(
              'Error Loading Status',
              style: TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.w600,
                color: Colors.red[700],
              ),
            ),
            const SizedBox(height: 8),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 32),
              child: Text(
                errorMessage!,
                textAlign: TextAlign.center,
                style: const TextStyle(fontSize: 14, color: Colors.grey),
              ),
            ),
            const SizedBox(height: 24),
            ElevatedButton(
              onPressed: _fetchApplicationStatus,
              child: const Text('Retry'),
            ),
          ],
        ),
      );
    }

    if (applicationData == null) {
      return const Center(
        child: Text(
          'No application data found',
          style: TextStyle(fontSize: 16, color: Colors.grey),
        ),
      );
    }

    return SingleChildScrollView(
      padding: const EdgeInsets.all(16.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Overall Progress Section - sits directly on gradient background
          Container(
            width: double.infinity,
            margin: const EdgeInsets.symmetric(horizontal: 16),
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              color: Colors.white, // White background
              borderRadius: BorderRadius.circular(12),
              boxShadow: [
                BoxShadow(
                  color: Colors.grey.withOpacity(0.1),
                  spreadRadius: 1,
                  blurRadius: 8,
                  offset: const Offset(0, 2),
                ),
              ],
            ),
            child: Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Colors.white, // White background for inner container
                borderRadius: BorderRadius.circular(8),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.center,
                children: [
                  const Text(
                    'Overall Progress',
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.w600,
                      color: Colors.black, // Changed from blue to black
                    ),
                  ),
                  const SizedBox(height: 12),
                  Text(
                    _getDynamicProgressText(),
                    style: const TextStyle(
                      fontSize: 14,
                      color: Colors.black, // Changed from grey to black
                    ),
                  ),
                  const SizedBox(height: 16),

                  // Progress Bar
                  Container(
                    width: double.infinity,
                    height: 8,
                    decoration: BoxDecoration(
                      color: Colors.grey[200],
                      borderRadius: BorderRadius.circular(4),
                    ),
                    child: FractionallySizedBox(
                      alignment: Alignment.centerLeft,
                      widthFactor: _getDynamicProgressPercentage(),
                      child: Container(
                        decoration: BoxDecoration(
                          color: applicationData!.isRejected
                              ? Colors.red[600]
                              : const Color(0xFF2196F3),
                          borderRadius: BorderRadius.circular(4),
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(height: 16),

                  // Dynamic Status Steps
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: stages
                        .map((stage) => _buildDynamicStatusStep(stage))
                        .toList(),
                  ),
                ],
              ),
            ),
          ),

          const SizedBox(height: 20),

          // Dynamic Status Cards
          ...stages.map((stage) => _buildDynamicStatusCard(stage)),

          const SizedBox(height: 20),

          // Waiting for Approval Section
          if (!applicationData!.isRejected &&
              applicationData!.status != 'Approved')
            _buildWaitingSection(),

          // Rejection Section
          if (applicationData!.isRejected) _buildRejectionSection(),

          const SizedBox(height: 30),

          // Back to Dashboard Button
          Container(
            width: double.infinity,
            margin: const EdgeInsets.symmetric(horizontal: 16),
            child: ElevatedButton(
              onPressed: () {
                Navigator.of(context).pop(); // Navigate back to dashboard
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.white,
                foregroundColor: const Color(0xFF2196F3),
                padding: const EdgeInsets.symmetric(vertical: 16),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                  side: const BorderSide(color: Color(0xFF2196F3), width: 1),
                ),
                elevation: 0,
              ),
              child: const Text(
                'Back to Dashboard',
                style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
              ),
            ),
          ),

          const SizedBox(height: 20),
        ],
      ),
    );
  }

  // Dynamic helper methods
  double _getDynamicProgressPercentage() {
    if (applicationData == null || applicationData!.isRejected) return 0.0;

    // Ensure stages list is not empty to avoid division by zero
    if (stages.isEmpty) return 0.0;

    int completedStages = stages.where((stage) => stage.isCompleted).length;
    double percentage = completedStages / stages.length;

    // Ensure the percentage is between 0.0 and 1.0 to prevent assertion errors
    return percentage.clamp(0.0, 1.0);
  }

  String _getDynamicProgressText() {
    if (applicationData == null) {
      return 'Loading...';
    }

    if (applicationData!.isRejected) {
      return 'Application rejected';
    }

    // Handle empty stages list
    if (stages.isEmpty) {
      return 'No stages available';
    }

    int completedStages = stages.where((stage) => stage.isCompleted).length;
    return '$completedStages of ${stages.length} stages completed';
  }

  Widget _buildDynamicStatusStep(ApplicationStage stage) {
    // Format display name for status steps (shorter version)
    String shortName = stage.displayName
        .replaceAll('Admin Review', 'Admin')
        .replaceAll('Ready for Payment', 'Ready for\nPayment');

    return Expanded(
      child: Column(
        children: [
          Container(
            width: 20, // Reduced from 40 to 32
            height: 20, // Reduced from 40 to 32
            decoration: BoxDecoration(
              color: stage.isCompleted
                  ? const Color(0xFF2196F3) // Blue for completed
                  : (stage.isActive
                        ? const Color(0xFF2196F3)
                        : Colors.grey[300]),
              shape: BoxShape.circle,
            ),
            child: stage.isCompleted
                ? const Icon(
                    Icons.check,
                    color: Colors.white,
                    size: 16, // Reduced from 20 to 16
                  )
                : stage.isActive
                ? const Icon(
                    Icons.hourglass_empty,
                    color: Colors.white,
                    size: 16, // Reduced from 20 to 16
                  )
                : Container(),
          ),
          const SizedBox(height: 8),
          Text(
            shortName,
            textAlign: TextAlign.center,
            style: TextStyle(
              fontSize: 11,
              fontWeight: FontWeight.w500,
              color: stage.isCompleted
                  ? Colors.black87
                  : (stage.isActive ? Colors.black87 : Colors.grey[600]),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildDynamicStatusCard(ApplicationStage stage) {
    Color statusColor;
    Color backgroundColor;
    String statusText;

    switch (stage.status) {
      case 'approved':
        statusColor = const Color(0xFF219653); // Green text
        backgroundColor = const Color(0xFFD1F5DD); // Light green background
        statusText = 'Approved';
        break;
      case 'in_progress':
        statusColor = const Color(0xFFFFB300); // Orange text
        backgroundColor = const Color(0xFFFFF8D9); // Light yellow background
        statusText = 'In progress';
        break;
      case 'pending':
        statusColor = const Color(0xFF1976D2); // Blue text
        backgroundColor = const Color(0xFFE3F2FD); // Light blue background
        statusText = 'Pending';
        break;
      case 'rejected':
        statusColor = Colors.white;
        backgroundColor = const Color(0xFFF44336); // Red
        statusText = 'Rejected';
        break;
      default:
        statusColor = const Color(0xFF1976D2); // Blue text
        backgroundColor = const Color(0xFFE3F2FD); // Light blue background
        statusText = 'Pending';
    }

    return Container(
      width: double.infinity,
      margin: const EdgeInsets.only(bottom: 16, left: 16, right: 16),
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white, // White background
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: Colors.grey.withOpacity(0.1),
            spreadRadius: 1,
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: Colors.white, // White background for inner container
          borderRadius: BorderRadius.circular(8),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Card Header with Status Chip
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        stage.displayName,
                        style: const TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.w600,
                          color: Colors.black, // Changed from blue to black
                        ),
                      ),
                      const SizedBox(height: 4),
                      if (stage.reviewer != null &&
                          stage.reviewer!.isNotEmpty) ...[
                        Text(
                          stage.reviewer!,
                          style: const TextStyle(
                            fontSize: 14,
                            color: Color(
                              0xFF4A5568,
                            ), // Dark grey text to match waiting section
                            fontWeight: FontWeight.w400,
                          ),
                        ),
                      ],
                      if (stage.reviewDate != null) ...[
                        const SizedBox(height: 4),
                        Text(
                          'Review date: ${_formatDateTime(stage.reviewDate!)}',
                          style: const TextStyle(
                            fontSize: 12,
                            color: Color(
                              0xFF4A5568,
                            ), // Dark grey text to match waiting section
                          ),
                        ),
                      ],
                    ],
                  ),
                ),
                const SizedBox(width: 12),
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 12,
                    vertical: 6,
                  ),
                  decoration: BoxDecoration(
                    color: backgroundColor,
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: Text(
                    statusText,
                    style: TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.w600,
                      color: statusColor,
                    ),
                  ),
                ),
              ],
            ),

            // Message Box (if exists)
            if (stage.message != null && stage.message!.isNotEmpty) ...[
              const SizedBox(height: 12),
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: Color(
                    0xFFFEF3C7,
                  ), // Exact background color from palette #FEF3C7
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(
                    color: Color(0xFFF59E0B),
                    width: 1,
                  ), // Exact border color from palette #F59E0B
                ),
                child: Text(
                  stage.message!,
                  style: const TextStyle(
                    fontSize: 14,
                    color: Color(
                      0xFFF59E0B,
                    ), // Exact text color from palette #F59E0B
                    height: 1.4,
                  ),
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }

  // Helper methods

  String _formatDateTime(DateTime date) {
    return '${date.day}/${date.month}/${date.year}';
  }

  Widget _buildWaitingSection() {
    return Container(
      width: double.infinity,
      margin: const EdgeInsets.symmetric(horizontal: 16),
      padding: const EdgeInsets.all(16), // Outer padding
      decoration: BoxDecoration(
        color: Colors.white, // White outer background
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.grey.withOpacity(0.15),
            spreadRadius: 2,
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Container(
        width: double.infinity,
        padding: const EdgeInsets.all(20), // Inner padding
        decoration: BoxDecoration(
          color: const Color(0xFFE3F2FD), // Light blue inner background #E3F2FD
          borderRadius: BorderRadius.circular(16),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Waiting for Approval',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold, // Bold font weight
                color: Color(0xFF1565C0), // Dark blue color #1565C0
              ),
            ),
            const SizedBox(height: 12), // Spacing
            const Text(
              'Your application is currently under review. Once all approval stages are complete, you\'ll be redirected to the payment section to complete your membership.',
              style: TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.normal, // Regular weight
                color: Color(0xFF4B647A), // Grey-blue color #4B647A
                height: 1.5, // Line height
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildRejectionSection() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.red[50],
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.red[200]!),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(Icons.error_outline, color: Colors.red[600], size: 20),
              const SizedBox(width: 8),
              Text(
                'Application Rejected',
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w600,
                  color: Colors.red[800],
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Text(
            applicationData!.rejectionReason ??
                'Your application has been rejected. Please contact support for more information.',
            style: TextStyle(fontSize: 14, color: Colors.red[700], height: 1.4),
          ),
        ],
      ),
    );
  }
}
