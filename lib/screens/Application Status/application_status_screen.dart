import 'package:flutter/material.dart';
import '../../services/application_status_service.dart';
import '../Member Bottom Navigation/dashboard_screen.dart';
import '../../services/auth_service.dart';
import '../Bussiness account/complete_membership_screen.dart';

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

      print('🔍 DEBUG: Fetched ${response.applications.length} application(s)');
      if (response.applications.isNotEmpty) {
        final app = response.applications.first;
        print('📊 DEBUG Application Data:');
        print('  - Status: ${app.status}');
        print('  - Block Approved: ${app.isBlockApproved}');
        print('  - District Approved: ${app.isDistrictApproved}');
        print('  - State Approved: ${app.isStateApproved}');
        print('  - Block Admin: ${app.assignedBlockAdmin?.fullName ?? "None"}');
        print(
          '  - District Admin: ${app.assignedDistrictAdmin?.fullName ?? "None"}',
        );
        print('  - State Admin: ${app.assignedStateAdmin?.fullName ?? "None"}');
      }

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
      print('❌ DEBUG Error fetching application: $e');
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
        statusColor: data.status == 'Approved'
            ? const Color(0xFF4CAF50)
            : const Color(0xFF90CAF9),
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
        return const Color(0xFF4CAF50); // New green for approved
      case 'in_progress':
        return const Color(0xFF2196F3); // New blue for in progress
      case 'rejected':
        return const Color(0xFFF44336); // New red for rejected
      default:
        return const Color(0xFF90CAF9); // New light blue for pending
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

  // Build simplified view for Aspirant applications
  Widget _buildAspirantStatusView() {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const SizedBox(height: 20),

          // Aspirant Application Submitted Card
          Container(
            width: double.infinity,
            margin: const EdgeInsets.symmetric(horizontal: 16),
            padding: const EdgeInsets.all(24),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(12),
              boxShadow: [
                BoxShadow(
                  color: Colors.grey.withValues(alpha: 0.1),
                  spreadRadius: 1,
                  blurRadius: 8,
                  offset: const Offset(0, 2),
                ),
              ],
            ),
            child: Column(
              children: [
                // Success Icon
                Container(
                  width: 80,
                  height: 80,
                  decoration: BoxDecoration(
                    color: const Color(0xFF4CAF50).withValues(alpha: 0.1),
                    shape: BoxShape.circle,
                  ),
                  child: const Icon(
                    Icons.check_circle,
                    size: 50,
                    color: Color(0xFF4CAF50),
                  ),
                ),
                const SizedBox(height: 20),

                // Title
                const Text(
                  'Application Submitted Successfully!',
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.w600,
                    color: Colors.black87,
                  ),
                ),
                const SizedBox(height: 12),

                // Subtitle
                Text(
                  'Your Aspirant membership application has been received.',
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    fontSize: 14,
                    color: Colors.grey[600],
                    height: 1.5,
                  ),
                ),
                const SizedBox(height: 24),

                // Status Badge
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 16,
                    vertical: 8,
                  ),
                  decoration: BoxDecoration(
                    color: const Color(0xFF2196F3).withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(20),
                    border: Border.all(
                      color: const Color(0xFF2196F3).withValues(alpha: 0.3),
                      width: 1,
                    ),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      const Icon(
                        Icons.schedule,
                        size: 18,
                        color: Color(0xFF2196F3),
                      ),
                      const SizedBox(width: 8),
                      const Text(
                        'Status: PENDING',
                        style: TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.w600,
                          color: Color(0xFF2196F3),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),

          const SizedBox(height: 24),

          // Information Card
          Container(
            width: double.infinity,
            margin: const EdgeInsets.symmetric(horizontal: 16),
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              color: const Color(0xFF64B5F6).withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(12),
              border: Border.all(
                color: const Color(0xFF64B5F6).withValues(alpha: 0.3),
                width: 1,
              ),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    const Icon(
                      Icons.info_outline,
                      color: Color(0xFF2196F3),
                      size: 24,
                    ),
                    const SizedBox(width: 12),
                    const Text(
                      'What happens next?',
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w600,
                        color: Colors.black87,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 16),
                _buildInfoPoint('1', 'Your application is under review'),
                const SizedBox(height: 12),
                _buildInfoPoint(
                  '2',
                  'You will receive a notification once reviewed',
                ),
                const SizedBox(height: 12),
                _buildInfoPoint('3', 'Check this page regularly for updates'),
              ],
            ),
          ),

          const SizedBox(height: 24),

          // Application Details Card
          Container(
            width: double.infinity,
            margin: const EdgeInsets.symmetric(horizontal: 16),
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(12),
              boxShadow: [
                BoxShadow(
                  color: Colors.grey.withValues(alpha: 0.1),
                  spreadRadius: 1,
                  blurRadius: 8,
                  offset: const Offset(0, 2),
                ),
              ],
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'Application Details',
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w600,
                    color: Colors.black87,
                  ),
                ),
                const SizedBox(height: 16),
                _buildDetailRow('Name', applicationData!.fullName),
                _buildDetailRow('Email', applicationData!.email),
                _buildDetailRow('Phone', applicationData!.phone),
                _buildDetailRow('State', applicationData!.state),
                _buildDetailRow('District', applicationData!.district),
                _buildDetailRow(
                  'Submitted',
                  _formatDate(applicationData!.createdAt),
                ),
              ],
            ),
          ),

          const SizedBox(height: 30),

          // Back to Dashboard Button
          Container(
            width: double.infinity,
            margin: const EdgeInsets.symmetric(horizontal: 16),
            child: ElevatedButton(
              onPressed: () async {
                final userData = await AuthService.getUserData();
                if (!mounted) return;
                if (userData != null) {
                  Navigator.pushAndRemoveUntil(
                    context,
                    MaterialPageRoute(
                      builder: (context) => DashboardScreen(userData: userData),
                    ),
                    (route) => false,
                  );
                } else {
                  Navigator.of(context).pop();
                }
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFF2196F3),
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(vertical: 16),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
                elevation: 2,
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

  Widget _buildInfoPoint(String number, String text) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Container(
          width: 24,
          height: 24,
          decoration: BoxDecoration(
            color: const Color(0xFF2196F3),
            shape: BoxShape.circle,
          ),
          child: Center(
            child: Text(
              number,
              style: const TextStyle(
                color: Colors.white,
                fontSize: 12,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: Padding(
            padding: const EdgeInsets.only(top: 2),
            child: Text(
              text,
              style: TextStyle(
                fontSize: 14,
                color: Colors.grey[700],
                height: 1.4,
              ),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildDetailRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 100,
            child: Text(
              '$label:',
              style: TextStyle(
                fontSize: 14,
                color: Colors.grey[600],
                fontWeight: FontWeight.w500,
              ),
            ),
          ),
          Expanded(
            child: Text(
              value,
              style: const TextStyle(
                fontSize: 14,
                color: Colors.black87,
                fontWeight: FontWeight.w500,
              ),
            ),
          ),
        ],
      ),
    );
  }

  String _formatDate(DateTime date) {
    final months = [
      'Jan',
      'Feb',
      'Mar',
      'Apr',
      'May',
      'Jun',
      'Jul',
      'Aug',
      'Sep',
      'Oct',
      'Nov',
      'Dec',
    ];
    return '${date.day} ${months[date.month - 1]} ${date.year}';
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
              Expanded(
                child: RefreshIndicator(
                  onRefresh: _fetchApplicationStatus,
                  color: const Color(0xFF2196F3),
                  backgroundColor: Colors.white,
                  child: _buildBody(),
                ),
              ),
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
                  color: Colors.grey.withValues(alpha: 0.1),
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

                  // Progress Bar - using new gradient colors based on backend status
                  Container(
                    width: double.infinity,
                    height: 10,
                    decoration: BoxDecoration(
                      color: const Color(0xFFE8EAF6), // Light indigo background
                      borderRadius: BorderRadius.circular(6),
                    ),
                    child: FractionallySizedBox(
                      alignment: Alignment.centerLeft,
                      widthFactor: _getDynamicProgressPercentage(),
                      child: Container(
                        decoration: BoxDecoration(
                          gradient: applicationData!.isRejected
                              ? const LinearGradient(
                                  colors: [
                                    Color(0xFFE53E3E),
                                    Color(0xFFC53030),
                                  ], // Red gradient for rejected
                                  begin: Alignment.centerLeft,
                                  end: Alignment.centerRight,
                                )
                              : const LinearGradient(
                                  colors: [
                                    Color(0xFF3182CE),
                                    Color(0xFF2B6CB0),
                                  ], // Blue gradient for progress
                                  begin: Alignment.centerLeft,
                                  end: Alignment.centerRight,
                                ),
                          borderRadius: BorderRadius.circular(6),
                          boxShadow: [
                            BoxShadow(
                              color: applicationData!.isRejected
                                  ? const Color(
                                      0xFFE53E3E,
                                    ).withValues(alpha: 0.3)
                                  : const Color(
                                      0xFF3182CE,
                                    ).withValues(alpha: 0.3),
                              spreadRadius: 0,
                              blurRadius: 4,
                              offset: const Offset(0, 2),
                            ),
                          ],
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

          // Payment Registration Button (when all stages approved)
          if (_isAllStagesApproved()) _buildPaymentRegistrationButton(),

          // Back to Dashboard Button
          Container(
            width: double.infinity,
            margin: const EdgeInsets.symmetric(horizontal: 16),
            child: ElevatedButton(
              onPressed: () async {
                // Get user data from AuthService
                final userData = await AuthService.getUserData();
                if (!mounted) return;
                if (userData != null) {
                  // Navigate to dashboard and clear the navigation stack
                  Navigator.pushAndRemoveUntil(
                    context,
                    MaterialPageRoute(
                      builder: (context) => DashboardScreen(userData: userData),
                    ),
                    (route) => false, // Remove all previous routes
                  );
                } else {
                  // Fallback: just pop if userData is not available
                  Navigator.of(context).pop();
                }
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

    // Get colors based on backend status
    Color stepColor;
    Color iconColor = Colors.white;

    if (stage.isCompleted) {
      stepColor = const Color(0xFF4CAF50); // Green for completed
    } else if (stage.isActive) {
      stepColor = const Color(0xFF2196F3); // Blue for active/in progress
    } else if (stage.status == 'rejected') {
      stepColor = const Color(0xFFF44336); // Red for rejected
      iconColor = Colors.white;
    } else {
      stepColor = const Color(0xFFE0E0E0); // Light grey for pending
      iconColor = const Color(0xFF9E9E9E);
    }

    return Expanded(
      child: Column(
        children: [
          Container(
            width: 32,
            height: 32,
            decoration: BoxDecoration(
              color: stepColor,
              shape: BoxShape.circle,
              boxShadow: stage.isCompleted || stage.isActive
                  ? [
                      BoxShadow(
                        color: stepColor.withValues(alpha: 0.3),
                        spreadRadius: 1,
                        blurRadius: 4,
                        offset: const Offset(0, 2),
                      ),
                    ]
                  : null,
            ),
            child: _getStepIcon(stage, iconColor),
          ),
          const SizedBox(height: 8),
          Text(
            shortName,
            textAlign: TextAlign.center,
            style: TextStyle(
              fontSize: 11,
              fontWeight: FontWeight.w500,
              color: stage.isCompleted || stage.isActive
                  ? const Color(0xFF1A1A1A)
                  : const Color(0xFF757575),
            ),
          ),
        ],
      ),
    );
  }

  Widget _getStepIcon(ApplicationStage stage, Color iconColor) {
    if (stage.status == 'rejected') {
      return Icon(Icons.close, color: iconColor, size: 18);
    } else if (stage.isCompleted) {
      return Icon(Icons.check, color: iconColor, size: 18);
    } else if (stage.isActive) {
      return Icon(Icons.hourglass_empty, color: iconColor, size: 18);
    } else {
      return Icon(Icons.circle, color: iconColor, size: 8);
    }
  }

  Widget _buildDynamicStatusCard(ApplicationStage stage) {
    // Get colors and styling based on backend status - using new design system
    Color statusColor;
    Color backgroundColor;
    String statusText;

    switch (stage.status) {
      case 'approved':
        statusColor = const Color(
          0xFF2E7D32,
        ); // Dark green text for better contrast
        backgroundColor = const Color(0xFFE8F5E8); // Light green background
        statusText = 'Approved';
        break;
      case 'in_progress':
        statusColor = const Color(0xFF1565C0); // Dark blue text
        backgroundColor = const Color(0xFFE3F2FD); // Light blue background
        statusText = 'In Progress';
        break;
      case 'pending':
        statusColor = const Color(0xFF5D4037); // Dark brown text
        backgroundColor = const Color(0xFFF3E5F5); // Light purple background
        statusText = 'Pending';
        break;
      case 'rejected':
        statusColor = Colors.white;
        backgroundColor = const Color(0xFFF44336); // Red background
        statusText = 'Rejected';
        break;
      default:
        statusColor = const Color(0xFF5D4037); // Dark brown text
        backgroundColor = const Color(0xFFF3E5F5); // Light purple background
        statusText = 'Pending';
    }

    return Container(
      width: double.infinity,
      margin: const EdgeInsets.only(bottom: 16, left: 16, right: 16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.08),
            spreadRadius: 0,
            blurRadius: 12,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Padding(
        padding: const EdgeInsets.all(20),
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
                          fontSize: 18,
                          fontWeight: FontWeight.w600,
                          color: Color(0xFF1A1A1A),
                          letterSpacing: -0.2,
                        ),
                      ),
                      const SizedBox(height: 6),
                      if (stage.reviewer != null &&
                          stage.reviewer!.isNotEmpty) ...[
                        Text(
                          stage.reviewer!,
                          style: const TextStyle(
                            fontSize: 14,
                            color: Color(0xFF6B7280),
                            fontWeight: FontWeight.w400,
                          ),
                        ),
                      ],
                      if (stage.reviewDate != null) ...[
                        const SizedBox(height: 4),
                        Text(
                          'Review Date: ${_formatDateTime(stage.reviewDate!)}',
                          style: const TextStyle(
                            fontSize: 13,
                            color: Color(0xFF9CA3AF),
                            fontWeight: FontWeight.w400,
                          ),
                        ),
                      ],
                    ],
                  ),
                ),
                const SizedBox(width: 16),
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 14,
                    vertical: 8,
                  ),
                  decoration: BoxDecoration(
                    color: backgroundColor,
                    borderRadius: BorderRadius.circular(20),
                    border: stage.status == 'rejected'
                        ? null
                        : Border.all(
                            color: statusColor.withValues(alpha: 0.2),
                            width: 1,
                          ),
                  ),
                  child: Text(
                    statusText,
                    style: TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.w600,
                      color: statusColor,
                      letterSpacing: 0.2,
                    ),
                  ),
                ),
              ],
            ),

            // Message Box (if exists) - using new design with dynamic colors
            if (stage.message != null && stage.message!.isNotEmpty) ...[
              const SizedBox(height: 16),
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: stage.status == 'approved'
                      ? const Color(0xFFE8F5E8) // Light green for approved
                      : stage.status == 'rejected'
                      ? const Color(0xFFFFEBEE) // Light red for rejected
                      : const Color(
                          0xFFFEF3C7,
                        ), // Yellow for in_progress/pending
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(
                    color: stage.status == 'approved'
                        ? const Color(0xFF4CAF50).withValues(
                            alpha: 0.3,
                          ) // Green border for approved
                        : stage.status == 'rejected'
                        ? const Color(0xFFE53E3E).withValues(
                            alpha: 0.3,
                          ) // Red border for rejected
                        : const Color(0xFFF59E0B).withValues(
                            alpha: 0.3,
                          ), // Yellow border for in_progress/pending
                    width: 1,
                  ),
                ),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Icon(
                      stage.status == 'rejected'
                          ? Icons.error_outline
                          : stage.status == 'approved'
                          ? Icons.check_circle_outline
                          : Icons.info_outline,
                      color: stage.status == 'approved'
                          ? const Color(0xFF4CAF50) // Green icon for approved
                          : stage.status == 'rejected'
                          ? const Color(0xFFE53E3E) // Red icon for rejected
                          : const Color(
                              0xFFF59E0B,
                            ), // Yellow icon for in_progress/pending
                      size: 18,
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Text(
                        stage.message!,
                        style: TextStyle(
                          fontSize: 14,
                          color: stage.status == 'approved'
                              ? const Color(
                                  0xFF2E7D32,
                                ) // Dark green text for approved
                              : stage.status == 'rejected'
                              ? const Color(
                                  0xFFD32F2F,
                                ) // Dark red text for rejected
                              : const Color(
                                  0xFFF59E0B,
                                ), // Yellow text for in_progress/pending
                          height: 1.5,
                          fontWeight: FontWeight.w400,
                        ),
                      ),
                    ),
                  ],
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
            color: Colors.grey.withValues(alpha: 0.15),
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

  // Helper method to check if all stages are approved
  bool _isAllStagesApproved() {
    if (applicationData == null) return false;
    return applicationData!.isBlockApproved &&
        applicationData!.isDistrictApproved &&
        applicationData!.isStateApproved &&
        !applicationData!.isRejected;
  }

  // Payment Registration Button Widget
  Widget _buildPaymentRegistrationButton() {
    return Container(
      width: double.infinity,
      margin: const EdgeInsets.symmetric(horizontal: 16),
      child: Column(
        children: [
          // Payment Registration Button
          ElevatedButton(
            onPressed: () {
              _handlePaymentRegistration();
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFF2196F3),
              foregroundColor: Colors.white,
              padding: const EdgeInsets.symmetric(vertical: 16),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
              elevation: 2,
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(Icons.payment, size: 20),
                const SizedBox(width: 8),
                Text(
                  'Register for Payment',
                  style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
                ),
              ],
            ),
          ),
          const SizedBox(height: 16),
        ],
      ),
    );
  }

  // Handle payment registration
  void _handlePaymentRegistration() {
    // Show confirmation dialog
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
          ),
          titlePadding: const EdgeInsets.fromLTRB(24, 24, 24, 16),
          title: Row(
            children: [
              Icon(Icons.payment, color: const Color(0xFF4CAF50)),
              const SizedBox(width: 8),
              Expanded(child: Text('Payment Registration')),
            ],
          ),
          contentPadding: const EdgeInsets.fromLTRB(24, 0, 24, 0),
          content: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'You are about to proceed with the payment registration process.',
                  style: TextStyle(fontSize: 16),
                ),
                const SizedBox(height: 12),
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: const Color(0xFFF3E5F5),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Next Steps:',
                        style: TextStyle(
                          fontWeight: FontWeight.w600,
                          color: const Color(0xFF7B1FA2),
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        '• Complete payment process\n• Receive membership confirmation\n• Access member benefits',
                        style: TextStyle(
                          fontSize: 14,
                          color: const Color(0xFF7B1FA2),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
          actions: [
            TextButton(
              onPressed: () {
                Navigator.of(context).pop();
              },
              child: Text('Cancel'),
            ),
            ElevatedButton(
              onPressed: () async {
                Navigator.of(context).pop();
                // Get user data from AuthService
                final userData = await AuthService.getUserData();
                if (userData != null) {
                  // Navigate to payment screen
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (context) =>
                          CompleteMembershipScreen(userData: userData),
                    ),
                  );
                }
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFF4CAF50),
                foregroundColor: Colors.white,
              ),
              child: Text('Proceed'),
            ),
          ],
        );
      },
    );
  }
}
