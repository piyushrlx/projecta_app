import 'package:flutter/material.dart';
import '../../core/theme.dart';
import '../../models/task_model.dart';
import '../../services/task_service.dart';

class TaskDetailScreen extends StatefulWidget {
  final int taskId;

  const TaskDetailScreen({super.key, required this.taskId});

  @override
  State<TaskDetailScreen> createState() => _TaskDetailScreenState();
}

class _TaskDetailScreenState extends State<TaskDetailScreen> {
  final TaskService _taskService = TaskService();

  bool _isLoading = true;
  String? _errorMessage;
  TaskDetailModel? _detail;
  bool _hasChanges = false;
  bool _isActionInProgress = false;

  @override
  void initState() {
    super.initState();
    _loadTaskDetail();
  }

  Future<void> _loadTaskDetail() async {
    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    try {
      final res = await _taskService.getTaskDetails(widget.taskId);
      if (mounted) {
        setState(() {
          _detail = res;
          _isLoading = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _errorMessage = e.toString().replaceAll('ApiException', '').trim();
          _isLoading = false;
        });
      }
    }
  }

  Future<void> _handleStatusChange(String newStatus) async {
    final noteController = TextEditingController();
    String? note;

    if (newStatus == 'blocked' || newStatus == 'completed') {
      final confirmed = await showDialog<bool>(
        context: context,
        builder: (ctx) => AlertDialog(
          backgroundColor: AppTheme.pureWhite,
          shape: const RoundedRectangleBorder(
            borderRadius: BorderRadius.zero,
            side: BorderSide(color: AppTheme.pitchBlack, width: 2),
          ),
          title: Text(
            '${newStatus.toUpperCase()} NOTES REQUIRED',
            style: AppTheme.heading(fontSize: 15, color: AppTheme.pitchBlack),
          ),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Please provide reasoning or completion notes for this transition:',
                style: AppTheme.body(fontSize: 13),
              ),
              const SizedBox(height: 10),
              TextField(
                controller: noteController,
                maxLines: 3,
                style: AppTheme.body(color: AppTheme.pitchBlack),
                decoration: const InputDecoration(
                  hintText: 'Enter details here...',
                  border: OutlineInputBorder(borderRadius: BorderRadius.zero),
                ),
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(ctx, false),
              child: Text(
                'CANCEL',
                style: AppTheme.mono(color: AppTheme.pitchBlack),
              ),
            ),
            ElevatedButton(
              onPressed: () => Navigator.pop(ctx, true),
              style: ElevatedButton.styleFrom(
                backgroundColor: AppTheme.pitchBlack,
              ),
              child: const Text('CONFIRM'),
            ),
          ],
        ),
      );

      if (confirmed != true) return;
      note = noteController.text.trim();
    }

    setState(() {
      _isActionInProgress = true;
    });

    try {
      await _taskService.updateStatus(
        widget.taskId,
        status: newStatus,
        note: note,
      );
      _hasChanges = true;
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            'Status updated to ${newStatus.replaceAll('_', ' ').toUpperCase()}',
          ),
          backgroundColor: AppTheme.pitchBlack,
        ),
      );
      await _loadTaskDetail();
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(e.toString().replaceAll('ApiException', '').trim()),
          backgroundColor: AppTheme.violentRed,
        ),
      );
    } finally {
      if (mounted) {
        setState(() {
          _isActionInProgress = false;
        });
      }
    }
  }

  Future<void> _handleProgressUpdate(double val) async {
    final progress = val.round();
    try {
      await _taskService.updateProgress(widget.taskId, progress);
      _hasChanges = true;
      await _loadTaskDetail();
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(e.toString().replaceAll('ApiException', '').trim()),
          backgroundColor: AppTheme.violentRed,
        ),
      );
    }
  }

  Future<void> _showExtensionDialog() async {
    final reasonController = TextEditingController();
    DateTime? selectedDate = DateTime.now().add(const Duration(days: 3));

    final submitted = await showModalBottomSheet<bool>(
      context: context,
      isScrollControlled: true,
      backgroundColor: AppTheme.pureWhite,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.zero,
        side: BorderSide(color: AppTheme.pitchBlack, width: 2),
      ),
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setModalState) => Padding(
          padding: EdgeInsets.only(
            left: 20,
            right: 20,
            top: 20,
            bottom: MediaQuery.of(ctx).viewInsets.bottom + 20,
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'REQUEST DEADLINE EXTENSION',
                style: AppTheme.heading(
                  fontSize: 16,
                  color: AppTheme.pitchBlack,
                ),
              ),
              const SizedBox(height: 12),
              Text(
                'REQUESTED NEW DEADLINE',
                style: AppTheme.mono(fontSize: 11, fontWeight: FontWeight.w800),
              ),
              const SizedBox(height: 6),
              GestureDetector(
                onTap: () async {
                  final picked = await showDatePicker(
                    context: ctx,
                    initialDate: selectedDate ?? DateTime.now(),
                    firstDate: DateTime.now(),
                    lastDate: DateTime.now().add(const Duration(days: 365)),
                  );
                  if (picked != null) {
                    setModalState(() {
                      selectedDate = picked;
                    });
                  }
                },
                child: Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    border: Border.all(color: AppTheme.pitchBlack, width: 2),
                  ),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        selectedDate != null
                            ? '${selectedDate!.year}-${selectedDate!.month.toString().padLeft(2, '0')}-${selectedDate!.day.toString().padLeft(2, '0')}'
                            : 'Select Date',
                        style: AppTheme.mono(
                          fontSize: 13,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                      const Icon(
                        Icons.calendar_month,
                        color: AppTheme.pitchBlack,
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 14),
              Text(
                'REASON FOR EXTENSION (REQUIRED)',
                style: AppTheme.mono(fontSize: 11, fontWeight: FontWeight.w800),
              ),
              const SizedBox(height: 6),
              TextField(
                controller: reasonController,
                maxLines: 3,
                style: AppTheme.body(color: AppTheme.pitchBlack),
                decoration: const InputDecoration(
                  hintText: 'Explain why extension is needed...',
                  border: OutlineInputBorder(borderRadius: BorderRadius.zero),
                ),
              ),
              const SizedBox(height: 16),
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: () {
                    if (reasonController.text.trim().isEmpty) {
                      ScaffoldMessenger.of(ctx).showSnackBar(
                        const SnackBar(content: Text('Please enter a reason.')),
                      );
                      return;
                    }
                    Navigator.pop(ctx, true);
                  },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppTheme.violentRed,
                  ),
                  child: const Text('SUBMIT EXTENSION REQUEST'),
                ),
              ),
            ],
          ),
        ),
      ),
    );

    if (submitted == true && selectedDate != null) {
      final dateStr =
          '${selectedDate!.year}-${selectedDate!.month.toString().padLeft(2, '0')}-${selectedDate!.day.toString().padLeft(2, '0')}';
      try {
        await _taskService.requestExtension(
          widget.taskId,
          requestedDeadline: dateStr,
          reason: reasonController.text.trim(),
        );
        _hasChanges = true;
        if (!mounted) return;
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Extension request submitted to manager.'),
            backgroundColor: AppTheme.pitchBlack,
          ),
        );
        await _loadTaskDetail();
      } catch (e) {
        if (!mounted) return;
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(e.toString().replaceAll('ApiException', '').trim()),
            backgroundColor: AppTheme.violentRed,
          ),
        );
      }
    }
  }

  Future<void> _handleDecideExtension(int requestId, String decision) async {
    final noteController = TextEditingController();
    if (decision == 'reject') {
      final confirmed = await showDialog<bool>(
        context: context,
        builder: (ctx) => AlertDialog(
          backgroundColor: AppTheme.pureWhite,
          shape: const RoundedRectangleBorder(
            borderRadius: BorderRadius.zero,
            side: BorderSide(color: AppTheme.pitchBlack, width: 2),
          ),
          title: Text(
            'REJECTION REASON REQUIRED',
            style: AppTheme.heading(fontSize: 15, color: AppTheme.pitchBlack),
          ),
          content: TextField(
            controller: noteController,
            maxLines: 2,
            style: AppTheme.body(color: AppTheme.pitchBlack),
            decoration: const InputDecoration(
              hintText: 'Enter rejection reason...',
              border: OutlineInputBorder(borderRadius: BorderRadius.zero),
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(ctx, false),
              child: Text(
                'CANCEL',
                style: AppTheme.mono(color: AppTheme.pitchBlack),
              ),
            ),
            ElevatedButton(
              onPressed: () => Navigator.pop(ctx, true),
              style: ElevatedButton.styleFrom(
                backgroundColor: AppTheme.violentRed,
              ),
              child: const Text('CONFIRM REJECT'),
            ),
          ],
        ),
      );
      if (confirmed != true) return;
    }

    try {
      await _taskService.decideExtension(
        widget.taskId,
        requestId: requestId,
        decision: decision,
        note: noteController.text.trim(),
      );
      _hasChanges = true;
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Extension request ${decision}d.'),
          backgroundColor: AppTheme.pitchBlack,
        ),
      );
      await _loadTaskDetail();
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(e.toString().replaceAll('ApiException', '').trim()),
          backgroundColor: AppTheme.violentRed,
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return PopScope(
      canPop: true,
      onPopInvokedWithResult: (didPop, _) {
        if (didPop && _hasChanges) {
          // Handled via returning result in Navigator
        }
      },
      child: Scaffold(
        backgroundColor: AppTheme.pitchBlack,
        appBar: AppBar(
          leading: IconButton(
            icon: const Icon(Icons.arrow_back),
            onPressed: () => Navigator.pop(context, _hasChanges),
          ),
          title: Text(
            _detail != null ? _detail!.task.taskCode : 'TASK DETAILS',
            style: AppTheme.mono(fontSize: 16, fontWeight: FontWeight.w800),
          ),
          actions: [
            IconButton(
              icon: const Icon(Icons.refresh),
              tooltip: 'Refresh',
              onPressed: _loadTaskDetail,
            ),
          ],
        ),
        body: _isLoading
            ? const Center(
                child: CircularProgressIndicator(
                  color: AppTheme.violentRed,
                  strokeWidth: 3,
                ),
              )
            : _errorMessage != null
            ? _buildErrorView()
            : _detail == null
            ? const SizedBox.shrink()
            : _buildContent(),
      ),
    );
  }

  Widget _buildContent() {
    final detail = _detail!;
    final task = detail.task;

    return RefreshIndicator(
      onRefresh: _loadTaskDetail,
      color: AppTheme.violentRed,
      child: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          // 1. Dependency Lock Banner (if blocked by predecessor tasks)
          if (task.isLocked) ...[
            Container(
              padding: const EdgeInsets.all(14),
              decoration: BoxDecoration(
                color: const Color(0xFFFFF0F0),
                border: Border.all(color: AppTheme.violentRed, width: 2.0),
              ),
              child: Row(
                children: [
                  const Icon(Icons.lock, color: AppTheme.violentRed, size: 24),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'BLOCKED BY PREDECESSORS',
                          style: AppTheme.mono(
                            fontSize: 12,
                            fontWeight: FontWeight.w900,
                            color: AppTheme.violentRed,
                          ),
                        ),
                        const SizedBox(height: 2),
                        Text(
                          'This task has ${task.openDependenciesCount} unfinished dependency. You cannot mark it complete until preceding tasks are resolved.',
                          style: AppTheme.body(
                            fontSize: 12,
                            color: AppTheme.pitchBlack,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 16),
          ],

          // 2. Overview Card
          _buildOverviewCard(task, detail),
          const SizedBox(height: 16),

          // 3. Status State-Machine Bar (Allowed Transitions)
          _buildStatusTransitionSection(detail),
          const SizedBox(height: 16),

          // 4. Progress Slider (if staff can work)
          if (detail.canWork && !task.isCompleted) ...[
            _buildProgressSlider(task),
            const SizedBox(height: 16),
          ],

          // 5. Pending Extension Requests (Staff request or Admin decision)
          _buildExtensionSection(detail),
          const SizedBox(height: 16),

          // 6. Assignees Section
          _buildAssigneesSection(detail.assignees),
          const SizedBox(height: 16),

          // 7. Dependencies Section
          if (detail.dependsOn.isNotEmpty ||
              detail.dependentTasks.isNotEmpty) ...[
            _buildDependenciesSection(detail),
            const SizedBox(height: 16),
          ],

          // 8. Subtasks Section
          if (detail.subtasks.isNotEmpty) ...[
            _buildSubtasksSection(detail.subtasks),
            const SizedBox(height: 16),
          ],

          // 9. Status History Section
          if (detail.statusHistory.isNotEmpty) ...[
            _buildHistorySection(detail.statusHistory),
            const SizedBox(height: 16),
          ],
        ],
      ),
    );
  }

  Widget _buildOverviewCard(TaskModel task, TaskDetailModel detail) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: AppTheme.neoCardDecoration(
        backgroundColor: AppTheme.pureWhite,
        borderColor: AppTheme.pitchBlack,
        shadowOffset: 4,
        shadowColor: AppTheme.pureWhite,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                color: AppTheme.pitchBlack,
                child: Text(
                  task.taskCode,
                  style: AppTheme.mono(
                    fontSize: 12,
                    fontWeight: FontWeight.w800,
                    color: AppTheme.pureWhite,
                  ),
                ),
              ),
              _buildPriorityBadge(task.priority),
            ],
          ),
          const SizedBox(height: 10),
          Text(
            task.title,
            style: AppTheme.heading(fontSize: 18, color: AppTheme.pitchBlack),
          ),
          if (task.projectName != null) ...[
            const SizedBox(height: 4),
            Text(
              'PROJECT: ${task.projectName!.toUpperCase()}',
              style: AppTheme.mono(
                fontSize: 11,
                color: const Color(0xFF666666),
              ),
            ),
          ],
          if (detail.description != null && detail.description!.isNotEmpty) ...[
            const SizedBox(height: 10),
            Text(
              detail.description!,
              style: AppTheme.body(
                fontSize: 13,
                color: const Color(0xFF333333),
              ),
            ),
          ],
          if (detail.instructions != null &&
              detail.instructions!.isNotEmpty) ...[
            const SizedBox(height: 10),
            Container(
              padding: const EdgeInsets.all(10),
              color: const Color(0xFFF9F9F9),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'INSTRUCTIONS',
                    style: AppTheme.mono(
                      fontSize: 10,
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    detail.instructions!,
                    style: AppTheme.body(fontSize: 12),
                  ),
                ],
              ),
            ),
          ],
          const SizedBox(height: 14),
          const Divider(color: AppTheme.pitchBlack, thickness: 1.5),
          const SizedBox(height: 8),
          Row(
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'DEADLINE',
                      style: AppTheme.mono(
                        fontSize: 10,
                        color: const Color(0xFF777777),
                      ),
                    ),
                    Text(
                      task.deadline ?? 'None',
                      style: AppTheme.mono(
                        fontSize: 12,
                        fontWeight: FontWeight.w800,
                        color: task.isOverdue
                            ? AppTheme.violentRed
                            : AppTheme.pitchBlack,
                      ),
                    ),
                  ],
                ),
              ),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'ESTIMATED',
                      style: AppTheme.mono(
                        fontSize: 10,
                        color: const Color(0xFF777777),
                      ),
                    ),
                    Text(
                      task.estimatedHours != null
                          ? '${task.estimatedHours} hrs'
                          : 'None',
                      style: AppTheme.mono(
                        fontSize: 12,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ],
                ),
              ),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'ACTUAL SPENT',
                      style: AppTheme.mono(
                        fontSize: 10,
                        color: const Color(0xFF777777),
                      ),
                    ),
                    Text(
                      '${(task.actualMinutes / 60).toStringAsFixed(1)} hrs',
                      style: AppTheme.mono(
                        fontSize: 12,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildStatusTransitionSection(TaskDetailModel detail) {
    final allowed = detail.allowedStatuses;
    if (allowed.isEmpty) return const SizedBox.shrink();

    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: const Color(0xFF161616),
        border: Border.all(color: AppTheme.pureWhite, width: 2),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'UPDATE STATUS',
                style: AppTheme.mono(
                  fontSize: 11,
                  fontWeight: FontWeight.w800,
                  color: AppTheme.pureWhite,
                ),
              ),
              Text(
                'CURRENT: ${detail.task.status.replaceAll('_', ' ').toUpperCase()}',
                style: AppTheme.mono(
                  fontSize: 10,
                  color: AppTheme.violentRed,
                  fontWeight: FontWeight.w800,
                ),
              ),
            ],
          ),
          const SizedBox(height: 10),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: allowed.map((status) {
              final isCurrent = detail.task.status == status;
              return GestureDetector(
                onTap: isCurrent || _isActionInProgress
                    ? null
                    : () => _handleStatusChange(status),
                child: Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 12,
                    vertical: 8,
                  ),
                  decoration: BoxDecoration(
                    color: isCurrent
                        ? AppTheme.pureWhite
                        : status == 'blocked'
                        ? const Color(0xFF4A1010)
                        : AppTheme.pitchBlack,
                    border: Border.all(
                      color: isCurrent
                          ? AppTheme.pureWhite
                          : status == 'blocked'
                          ? AppTheme.violentRed
                          : AppTheme.pureWhite,
                      width: 1.5,
                    ),
                  ),
                  child: Text(
                    status.replaceAll('_', ' ').toUpperCase(),
                    style: AppTheme.mono(
                      fontSize: 11,
                      fontWeight: FontWeight.w800,
                      color: isCurrent
                          ? AppTheme.pitchBlack
                          : AppTheme.pureWhite,
                    ),
                  ),
                ),
              );
            }).toList(),
          ),
        ],
      ),
    );
  }

  Widget _buildProgressSlider(TaskModel task) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: const Color(0xFF141414),
        border: Border.all(color: AppTheme.pureWhite, width: 1.5),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'TASK PROGRESS SLIDER',
                style: AppTheme.mono(
                  fontSize: 11,
                  fontWeight: FontWeight.w800,
                  color: AppTheme.pureWhite,
                ),
              ),
              Text(
                '${task.progress}%',
                style: AppTheme.mono(
                  fontSize: 14,
                  fontWeight: FontWeight.w900,
                  color: AppTheme.pureWhite,
                ),
              ),
            ],
          ),
          Slider(
            value: task.progress.toDouble(),
            min: 0,
            max: 100,
            divisions: 20,
            activeColor: task.isLocked
                ? AppTheme.violentRed
                : AppTheme.pureWhite,
            inactiveColor: const Color(0xFF333333),
            onChanged: (val) {
              _handleProgressUpdate(val);
            },
          ),
        ],
      ),
    );
  }

  Widget _buildExtensionSection(TaskDetailModel detail) {
    final pendingRequests = detail.extensionRequests
        .where((e) => e.isPending)
        .toList();

    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: const Color(0xFF141414),
        border: Border.all(color: AppTheme.pureWhite, width: 1.5),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'DEADLINE EXTENSION',
                style: AppTheme.mono(
                  fontSize: 11,
                  fontWeight: FontWeight.w800,
                  color: AppTheme.pureWhite,
                ),
              ),
              if (detail.canWork && !detail.task.isCompleted)
                GestureDetector(
                  onTap: _showExtensionDialog,
                  child: Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 8,
                      vertical: 4,
                    ),
                    color: AppTheme.violentRed,
                    child: Text(
                      'REQUEST EXTENSION',
                      style: AppTheme.mono(
                        fontSize: 10,
                        fontWeight: FontWeight.w800,
                        color: AppTheme.pureWhite,
                      ),
                    ),
                  ),
                ),
            ],
          ),
          if (pendingRequests.isNotEmpty) ...[
            const SizedBox(height: 10),
            ...pendingRequests.map((req) {
              return Container(
                margin: const EdgeInsets.only(bottom: 8),
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  color: const Color(0xFF221414),
                  border: Border.all(color: AppTheme.violentRed, width: 1.5),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'PENDING EXTENSION REQUEST',
                      style: AppTheme.mono(
                        fontSize: 10,
                        fontWeight: FontWeight.w800,
                        color: AppTheme.violentRed,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      'Requested Date: ${req.requestedDeadline} by ${req.requesterName}',
                      style: AppTheme.body(
                        fontSize: 12,
                        color: AppTheme.pureWhite,
                      ),
                    ),
                    Text(
                      'Reason: ${req.reason}',
                      style: AppTheme.body(
                        fontSize: 12,
                        color: const Color(0xFFAAAAAA),
                      ),
                    ),
                    if (detail.canManage) ...[
                      const SizedBox(height: 8),
                      Row(
                        children: [
                          ElevatedButton(
                            onPressed: () =>
                                _handleDecideExtension(req.id, 'approve'),
                            style: ElevatedButton.styleFrom(
                              backgroundColor: const Color(0xFF2E7D32),
                              padding: const EdgeInsets.symmetric(
                                horizontal: 14,
                                vertical: 6,
                              ),
                            ),
                            child: const Text('APPROVE'),
                          ),
                          const SizedBox(width: 8),
                          ElevatedButton(
                            onPressed: () =>
                                _handleDecideExtension(req.id, 'reject'),
                            style: ElevatedButton.styleFrom(
                              backgroundColor: AppTheme.violentRed,
                              padding: const EdgeInsets.symmetric(
                                horizontal: 14,
                                vertical: 6,
                              ),
                            ),
                            child: const Text('REJECT'),
                          ),
                        ],
                      ),
                    ],
                  ],
                ),
              );
            }),
          ] else if (!detail.canWork || detail.task.isCompleted) ...[
            const SizedBox(height: 6),
            Text(
              'No pending extension requests.',
              style: AppTheme.body(
                fontSize: 12,
                color: const Color(0xFF777777),
              ),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildAssigneesSection(List<TaskAssigneeModel> assignees) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'ASSIGNEES (${assignees.length})',
          style: AppTheme.heading(fontSize: 14),
        ),
        const SizedBox(height: 8),
        Wrap(
          spacing: 8,
          runSpacing: 8,
          children: assignees.map((a) {
            return Container(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
              decoration: BoxDecoration(
                color: AppTheme.pureWhite,
                border: Border.all(color: AppTheme.pitchBlack, width: 1.5),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    a.fullName,
                    style: AppTheme.mono(
                      fontSize: 11,
                      fontWeight: FontWeight.w800,
                      color: AppTheme.pitchBlack,
                    ),
                  ),
                  const SizedBox(width: 6),
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 4,
                      vertical: 1,
                    ),
                    color: a.isOwner
                        ? AppTheme.pitchBlack
                        : const Color(0xFFEEEEEE),
                    child: Text(
                      a.responsibility.toUpperCase(),
                      style: AppTheme.mono(
                        fontSize: 9,
                        color: a.isOwner
                            ? AppTheme.pureWhite
                            : AppTheme.pitchBlack,
                      ),
                    ),
                  ),
                ],
              ),
            );
          }).toList(),
        ),
      ],
    );
  }

  Widget _buildDependenciesSection(TaskDetailModel detail) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text('DEPENDENCY NETWORK', style: AppTheme.heading(fontSize: 14)),
        const SizedBox(height: 8),
        if (detail.dependsOn.isNotEmpty) ...[
          Text(
            'PREDECESSORS (THIS TASK DEPENDS ON):',
            style: AppTheme.mono(fontSize: 10, color: const Color(0xFF999999)),
          ),
          const SizedBox(height: 4),
          ...detail.dependsOn.map((d) {
            return Container(
              margin: const EdgeInsets.only(bottom: 6),
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: d.isFinished
                    ? const Color(0xFF0F1E12)
                    : const Color(0xFF1E1414),
                border: Border.all(
                  color: d.isFinished
                      ? const Color(0xFF4CAF50)
                      : AppTheme.violentRed,
                ),
              ),
              child: Row(
                children: [
                  Icon(
                    d.isFinished ? Icons.check : Icons.lock,
                    size: 14,
                    color: d.isFinished
                        ? const Color(0xFF4CAF50)
                        : AppTheme.violentRed,
                  ),
                  const SizedBox(width: 8),
                  Text(
                    '${d.taskCode}: ${d.title}',
                    style: AppTheme.mono(
                      fontSize: 11,
                      color: AppTheme.pureWhite,
                    ),
                  ),
                ],
              ),
            );
          }),
        ],
      ],
    );
  }

  Widget _buildSubtasksSection(List<SubtaskModel> subtasks) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'SUBTASKS (${subtasks.length})',
          style: AppTheme.heading(fontSize: 14),
        ),
        const SizedBox(height: 8),
        ...subtasks.map((s) {
          return Container(
            margin: const EdgeInsets.only(bottom: 6),
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
              border: Border.all(color: const Color(0xFF333333)),
            ),
            child: Row(
              children: [
                Icon(
                  s.isCompleted
                      ? Icons.check_box
                      : Icons.check_box_outline_blank,
                  color: AppTheme.pureWhite,
                  size: 18,
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    '${s.taskCode} · ${s.title}',
                    style: AppTheme.body(
                      fontSize: 12,
                      color: AppTheme.pureWhite,
                    ),
                  ),
                ),
              ],
            ),
          );
        }),
      ],
    );
  }

  Widget _buildHistorySection(List<TaskStatusHistoryModel> history) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text('STATUS AUDIT TRAIL', style: AppTheme.heading(fontSize: 14)),
        const SizedBox(height: 8),
        ...history.take(6).map((h) {
          return Container(
            margin: const EdgeInsets.only(bottom: 6),
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              border: Border.all(color: const Color(0xFF222222)),
            ),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Icon(Icons.history, size: 14, color: Color(0xFF777777)),
                const SizedBox(width: 8),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Status -> ${h.newStatus.toUpperCase()}${h.note != null && h.note!.isNotEmpty ? ' (${h.note})' : ''}',
                        style: AppTheme.mono(
                          fontSize: 11,
                          color: AppTheme.pureWhite,
                        ),
                      ),
                      Text(
                        '${h.changedByName ?? 'System'} · ${h.createdAt}',
                        style: AppTheme.body(
                          fontSize: 10,
                          color: const Color(0xFF777777),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          );
        }),
      ],
    );
  }

  Widget _buildPriorityBadge(String priority) {
    Color bg = const Color(0xFFE0E0E0);
    Color fg = AppTheme.pitchBlack;

    if (priority == 'critical' || priority == 'high') {
      bg = AppTheme.violentRed;
      fg = AppTheme.pureWhite;
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
      decoration: BoxDecoration(
        color: bg,
        border: Border.all(color: AppTheme.pitchBlack, width: 1),
      ),
      child: Text(
        priority.toUpperCase(),
        style: AppTheme.mono(
          fontSize: 9,
          fontWeight: FontWeight.w800,
          color: fg,
        ),
      ),
    );
  }

  Widget _buildErrorView() {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: const Color(0xFF1E1414),
            border: Border.all(color: AppTheme.violentRed, width: 2),
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                'FAILED TO LOAD TASK',
                style: AppTheme.mono(
                  fontSize: 12,
                  fontWeight: FontWeight.w800,
                  color: AppTheme.violentRed,
                ),
              ),
              const SizedBox(height: 8),
              Text(
                _errorMessage ?? 'Unknown error occurred.',
                style: AppTheme.body(color: AppTheme.pureWhite, fontSize: 13),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 14),
              ElevatedButton(
                onPressed: _loadTaskDetail,
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppTheme.violentRed,
                ),
                child: const Text('RETRY'),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
