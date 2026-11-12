import 'package:flutter/material.dart';
import '../../core/theme.dart';
import '../../models/task_model.dart';
import '../../services/task_service.dart';
import 'task_form_screen.dart';

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
  int? _localProgress;
  bool _isSavingProgress = false;

  @override
  void initState() {
    super.initState();
    _loadTaskDetail();
  }

  Future<void> _loadTaskDetail({bool silent = false}) async {
    if (!silent && _detail == null) {
      setState(() {
        _isLoading = true;
        _errorMessage = null;
      });
    }

    try {
      final res = await _taskService.getTaskDetails(widget.taskId);
      if (mounted) {
        setState(() {
          _detail = res;
          _localProgress = res.task.progress;
          _isLoading = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          if (_detail == null) {
            _errorMessage = e.toString().replaceAll('ApiException', '').trim();
          }
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
          surfaceTintColor: Colors.transparent,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
            side: const BorderSide(color: AppTheme.borderSubtle, width: 1.0),
          ),
          title: Text(
            '${newStatus[0].toUpperCase()}${newStatus.substring(1)} Notes Required',
            style: AppTheme.heading(fontSize: 16, color: AppTheme.deepSlate),
          ),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Please provide reasoning or completion notes for this transition:',
                style: AppTheme.body(fontSize: 13, color: AppTheme.mutedSlate),
              ),
              const SizedBox(height: 12),
              TextField(
                controller: noteController,
                maxLines: 3,
                style: AppTheme.body(color: AppTheme.deepSlate),
                decoration: const InputDecoration(
                  hintText: 'Enter details here...',
                ),
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(ctx, false),
              child: Text(
                'Cancel',
                style: AppTheme.heading(
                  fontSize: 14,
                  color: AppTheme.mutedSlate,
                ),
              ),
            ),
            ElevatedButton(
              onPressed: () => Navigator.pop(ctx, true),
              style: ElevatedButton.styleFrom(
                backgroundColor: AppTheme.navyBlue,
              ),
              child: const Text('Confirm'),
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
          content: Text('Status updated to ${newStatus.replaceAll('_', ' ')}'),
        ),
      );
      await _loadTaskDetail(silent: true);
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(e.toString().replaceAll('ApiException', '').trim()),
          backgroundColor: AppTheme.dangerText,
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

  Future<void> _handleProgressCommit(int progress) async {
    if (_detail == null) return;
    final oldProgress = _detail!.task.progress;
    if (progress == oldProgress) return;

    setState(() {
      _isSavingProgress = true;
      _localProgress = progress;
      _detail = _detail!.copyWith(
        task: _detail!.task.copyWith(progress: progress),
      );
    });

    try {
      await _taskService.updateProgress(widget.taskId, progress);
      _hasChanges = true;
      await _loadTaskDetail(silent: true);
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _localProgress = oldProgress;
        if (_detail != null) {
          _detail = _detail!.copyWith(
            task: _detail!.task.copyWith(progress: oldProgress),
          );
        }
      });
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(e.toString().replaceAll('ApiException', '').trim()),
          backgroundColor: AppTheme.dangerText,
        ),
      );
    } finally {
      if (mounted) {
        setState(() {
          _isSavingProgress = false;
        });
      }
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
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
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
                'Request Deadline Extension',
                style: AppTheme.heading(
                  fontSize: 17,
                  fontWeight: FontWeight.w700,
                  color: AppTheme.deepSlate,
                ),
              ),
              const SizedBox(height: 14),
              Text(
                'Requested New Deadline',
                style: AppTheme.heading(
                  fontSize: 12,
                  fontWeight: FontWeight.w600,
                  color: AppTheme.deepSlate,
                ),
              ),
              const SizedBox(height: 8),
              InkWell(
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
                borderRadius: BorderRadius.circular(10),
                child: Container(
                  padding: const EdgeInsets.all(14),
                  decoration: BoxDecoration(
                    color: AppTheme.scaffoldBg,
                    borderRadius: BorderRadius.circular(10),
                    border: Border.all(color: AppTheme.borderSubtle),
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
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                      const Icon(
                        Icons.calendar_month_outlined,
                        color: AppTheme.mutedSlate,
                        size: 20,
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 16),
              Text(
                'Reason for Extension (Required)',
                style: AppTheme.heading(
                  fontSize: 12,
                  fontWeight: FontWeight.w600,
                  color: AppTheme.deepSlate,
                ),
              ),
              const SizedBox(height: 8),
              TextField(
                controller: reasonController,
                maxLines: 3,
                style: AppTheme.body(color: AppTheme.deepSlate),
                decoration: const InputDecoration(
                  hintText: 'Explain why extension is needed...',
                ),
              ),
              const SizedBox(height: 20),
              SizedBox(
                width: double.infinity,
                height: 48,
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
                    backgroundColor: AppTheme.navyBlue,
                    foregroundColor: AppTheme.pureWhite,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(10),
                    ),
                  ),
                  child: const Text('Submit Extension Request'),
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
          ),
        );
        await _loadTaskDetail();
      } catch (e) {
        if (!mounted) return;
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(e.toString().replaceAll('ApiException', '').trim()),
            backgroundColor: AppTheme.dangerText,
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
          surfaceTintColor: Colors.transparent,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
            side: const BorderSide(color: AppTheme.borderSubtle, width: 1.0),
          ),
          title: Text(
            'Rejection Reason Required',
            style: AppTheme.heading(fontSize: 16, color: AppTheme.deepSlate),
          ),
          content: TextField(
            controller: noteController,
            maxLines: 2,
            style: AppTheme.body(color: AppTheme.deepSlate),
            decoration: const InputDecoration(
              hintText: 'Enter rejection reason...',
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(ctx, false),
              child: Text(
                'Cancel',
                style: AppTheme.heading(
                  fontSize: 14,
                  color: AppTheme.mutedSlate,
                ),
              ),
            ),
            ElevatedButton(
              onPressed: () => Navigator.pop(ctx, true),
              style: ElevatedButton.styleFrom(
                backgroundColor: AppTheme.dangerText,
              ),
              child: const Text('Confirm Reject'),
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
        SnackBar(content: Text('Extension request ${decision}d.')),
      );
      await _loadTaskDetail();
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(e.toString().replaceAll('ApiException', '').trim()),
          backgroundColor: AppTheme.dangerText,
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return PopScope(
      canPop: true,
      onPopInvokedWithResult: (didPop, _) {},
      child: Scaffold(
        backgroundColor: AppTheme.scaffoldBg,
        appBar: AppBar(
          leading: IconButton(
            icon: const Icon(Icons.arrow_back, color: AppTheme.deepSlate),
            onPressed: () => Navigator.pop(context, _hasChanges),
          ),
          title: Text(
            _detail != null ? _detail!.task.taskCode : 'Task Details',
            style: AppTheme.mono(fontSize: 16, fontWeight: FontWeight.w700),
          ),
          actions: [
            if (_detail != null && _detail!.canManage)
              IconButton(
                icon: const Icon(Icons.edit_outlined, color: AppTheme.royalBlue),
                tooltip: 'Edit Task',
                onPressed: () async {
                  final updated = await Navigator.push<bool>(
                    context,
                    MaterialPageRoute(
                      builder: (_) => TaskFormScreen(detail: _detail),
                    ),
                  );
                  if (updated == true && mounted) {
                    _loadTaskDetail();
                  }
                },
              ),
            IconButton(
              icon: const Icon(Icons.refresh, color: AppTheme.deepSlate),
              tooltip: 'Refresh',
              onPressed: _loadTaskDetail,
            ),
          ],
        ),
        body: _isLoading
            ? const Center(
                child: CircularProgressIndicator(
                  color: AppTheme.royalBlue,
                  strokeWidth: 2.5,
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
      color: AppTheme.royalBlue,
      child: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          // 1. Dependency Lock Alert
          if (task.isLocked) ...[
            Container(
              padding: const EdgeInsets.all(14),
              decoration: BoxDecoration(
                color: AppTheme.dangerBg,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(
                  color: AppTheme.dangerText.withValues(alpha: 0.3),
                ),
              ),
              child: Row(
                children: [
                  const Icon(
                    Icons.lock_outline,
                    color: AppTheme.dangerText,
                    size: 22,
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Locked: Complete Predecessor Tasks First',
                          style: AppTheme.heading(
                            fontSize: 12,
                            fontWeight: FontWeight.w700,
                            color: AppTheme.dangerText,
                          ),
                        ),
                        const SizedBox(height: 3),
                        Text(
                          'This task has ${task.openDependenciesCount} unfinished predecessor dependency. You cannot mark it complete until preceding tasks are resolved.',
                          style: AppTheme.body(
                            fontSize: 12,
                            color: AppTheme.deepSlate,
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

          // 3. Status State-Machine Bar
          _buildStatusTransitionSection(detail),
          const SizedBox(height: 16),

          // 4. Progress Slider
          if (detail.canWork && !task.isCompleted) ...[
            _buildProgressSlider(task),
            const SizedBox(height: 16),
          ],

          // 5. Pending Extension Requests
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
          if (detail.subtasks.isNotEmpty || detail.canManage) ...[
            _buildSubtasksSection(detail),
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
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: AppTheme.pureWhite,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppTheme.borderSubtle, width: 1.0),
        boxShadow: const [AppTheme.softShadow],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                decoration: BoxDecoration(
                  color: AppTheme.scaffoldBg,
                  borderRadius: BorderRadius.circular(6),
                  border: Border.all(color: AppTheme.borderSubtle),
                ),
                child: Text(
                  task.taskCode,
                  style: AppTheme.mono(
                    fontSize: 11,
                    fontWeight: FontWeight.w700,
                    color: AppTheme.deepSlate,
                  ),
                ),
              ),
              _buildPriorityBadge(task.priority),
            ],
          ),
          const SizedBox(height: 12),
          Text(
            task.title,
            style: AppTheme.heading(fontSize: 18, color: AppTheme.deepSlate),
          ),
          if (task.projectName != null) ...[
            const SizedBox(height: 4),
            Text(
              'Project: ${task.projectName}',
              style: AppTheme.body(fontSize: 12, color: AppTheme.mutedSlate),
            ),
          ],
          if (detail.description != null && detail.description!.isNotEmpty) ...[
            const SizedBox(height: 12),
            Text(
              detail.description!,
              style: AppTheme.body(fontSize: 13, color: AppTheme.deepSlate),
            ),
          ],
          if (detail.instructions != null &&
              detail.instructions!.isNotEmpty) ...[
            const SizedBox(height: 12),
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: AppTheme.scaffoldBg,
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: AppTheme.borderSubtle),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Instructions',
                    style: AppTheme.heading(
                      fontSize: 11,
                      fontWeight: FontWeight.w600,
                      color: AppTheme.mutedSlate,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    detail.instructions!,
                    style: AppTheme.body(fontSize: 12),
                  ),
                ],
              ),
            ),
          ],
          const SizedBox(height: 16),
          const Divider(color: AppTheme.borderSubtle, thickness: 1.0),
          const SizedBox(height: 12),
          Row(
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Deadline',
                      style: AppTheme.body(
                        fontSize: 11,
                        color: AppTheme.mutedSlate,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      task.deadline ?? 'None',
                      style: AppTheme.mono(
                        fontSize: 12,
                        fontWeight: FontWeight.w600,
                        color: task.isOverdue
                            ? AppTheme.dangerText
                            : AppTheme.deepSlate,
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
                      'Estimated',
                      style: AppTheme.body(
                        fontSize: 11,
                        color: AppTheme.mutedSlate,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      task.estimatedHours != null
                          ? '${task.estimatedHours} hrs'
                          : 'None',
                      style: AppTheme.mono(
                        fontSize: 12,
                        fontWeight: FontWeight.w600,
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
                      'Actual Spent',
                      style: AppTheme.body(
                        fontSize: 11,
                        color: AppTheme.mutedSlate,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      '${(task.actualMinutes / 60).toStringAsFixed(1)} hrs',
                      style: AppTheme.mono(
                        fontSize: 12,
                        fontWeight: FontWeight.w600,
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
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppTheme.pureWhite,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppTheme.borderSubtle, width: 1.0),
        boxShadow: const [AppTheme.softShadow],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'Update Status',
                style: AppTheme.heading(
                  fontSize: 13,
                  fontWeight: FontWeight.w700,
                  color: AppTheme.deepSlate,
                ),
              ),
              Text(
                'Current: ${detail.task.status.replaceAll('_', ' ')}',
                style: AppTheme.body(
                  fontSize: 11,
                  color: AppTheme.mutedSlate,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: allowed.map((status) {
              final isCurrent = detail.task.status == status;
              final isBlocked = status == 'blocked';
              final label = status.replaceAll('_', ' ');

              return InkWell(
                onTap: isCurrent || _isActionInProgress
                    ? null
                    : () => _handleStatusChange(status),
                borderRadius: BorderRadius.circular(8),
                child: Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 12,
                    vertical: 8,
                  ),
                  decoration: BoxDecoration(
                    color: isCurrent
                        ? AppTheme.navyBlue
                        : isBlocked
                        ? AppTheme.dangerBg
                        : const Color(0xFFF1F5F9),
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(
                      color: isCurrent
                          ? AppTheme.navyBlue
                          : isBlocked
                          ? const Color(0xFFFECACA)
                          : AppTheme.borderSubtle,
                    ),
                  ),
                  child: Text(
                    label[0].toUpperCase() + label.substring(1),
                    style: AppTheme.heading(
                      fontSize: 12,
                      fontWeight: FontWeight.w600,
                      color: isCurrent
                          ? AppTheme.pureWhite
                          : isBlocked
                          ? AppTheme.dangerText
                          : AppTheme.deepSlate,
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
    final currentProgress = (_localProgress ?? task.progress).clamp(0, 100);

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppTheme.pureWhite,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppTheme.borderSubtle, width: 1.0),
        boxShadow: const [AppTheme.softShadow],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'Task Progress',
                style: AppTheme.heading(
                  fontSize: 13,
                  fontWeight: FontWeight.w700,
                  color: AppTheme.deepSlate,
                ),
              ),
              Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  if (_isSavingProgress) ...[
                    const SizedBox(
                      width: 12,
                      height: 12,
                      child: CircularProgressIndicator(
                        strokeWidth: 2,
                        color: AppTheme.royalBlue,
                      ),
                    ),
                    const SizedBox(width: 6),
                  ],
                  Text(
                    '$currentProgress%',
                    style: AppTheme.mono(
                      fontSize: 14,
                      fontWeight: FontWeight.w700,
                      color: AppTheme.deepSlate,
                    ),
                  ),
                ],
              ),
            ],
          ),
          Slider(
            value: currentProgress.toDouble(),
            min: 0,
            max: 100,
            divisions: 20,
            activeColor: task.isLocked
                ? AppTheme.dangerText
                : AppTheme.royalBlue,
            inactiveColor: const Color(0xFFE2E8F0),
            onChanged: task.isLocked
                ? null
                : (val) {
                    setState(() {
                      _localProgress = val.round();
                    });
                  },
            onChangeEnd: task.isLocked
                ? null
                : (val) {
                    _handleProgressCommit(val.round());
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
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppTheme.pureWhite,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppTheme.borderSubtle, width: 1.0),
        boxShadow: const [AppTheme.softShadow],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'Deadline Extension',
                style: AppTheme.heading(
                  fontSize: 13,
                  fontWeight: FontWeight.w700,
                  color: AppTheme.deepSlate,
                ),
              ),
              if (detail.canWork && !detail.task.isCompleted)
                InkWell(
                  onTap: _showExtensionDialog,
                  borderRadius: BorderRadius.circular(6),
                  child: Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 10,
                      vertical: 5,
                    ),
                    decoration: BoxDecoration(
                      color: AppTheme.infoBg,
                      borderRadius: BorderRadius.circular(6),
                    ),
                    child: Text(
                      'Request Extension',
                      style: AppTheme.heading(
                        fontSize: 11,
                        fontWeight: FontWeight.w600,
                        color: AppTheme.infoText,
                      ),
                    ),
                  ),
                ),
            ],
          ),
          if (pendingRequests.isNotEmpty) ...[
            const SizedBox(height: 12),
            ...pendingRequests.map((req) {
              return Container(
                margin: const EdgeInsets.only(bottom: 8),
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: AppTheme.warningBg,
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: const Color(0xFFFDE68A)),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Pending Extension Request',
                      style: AppTheme.heading(
                        fontSize: 11,
                        fontWeight: FontWeight.w600,
                        color: AppTheme.warningText,
                      ),
                    ),
                    const SizedBox(height: 3),
                    Text(
                      'Requested Date: ${req.requestedDeadline} by ${req.requesterName}',
                      style: AppTheme.body(
                        fontSize: 12,
                        color: AppTheme.deepSlate,
                      ),
                    ),
                    Text(
                      'Reason: ${req.reason}',
                      style: AppTheme.body(
                        fontSize: 12,
                        color: AppTheme.mutedSlate,
                      ),
                    ),
                    if (detail.canManage) ...[
                      const SizedBox(height: 10),
                      Row(
                        children: [
                          ElevatedButton(
                            onPressed: () =>
                                _handleDecideExtension(req.id, 'approve'),
                            style: ElevatedButton.styleFrom(
                              backgroundColor: AppTheme.navyBlue,
                              padding: const EdgeInsets.symmetric(
                                horizontal: 14,
                                vertical: 6,
                              ),
                            ),
                            child: const Text('Approve'),
                          ),
                          const SizedBox(width: 8),
                          OutlinedButton(
                            onPressed: () =>
                                _handleDecideExtension(req.id, 'reject'),
                            style: OutlinedButton.styleFrom(
                              foregroundColor: AppTheme.dangerText,
                              side: const BorderSide(
                                color: AppTheme.dangerText,
                              ),
                              padding: const EdgeInsets.symmetric(
                                horizontal: 14,
                                vertical: 6,
                              ),
                            ),
                            child: const Text('Reject'),
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
              style: AppTheme.body(fontSize: 12, color: AppTheme.mutedSlate),
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
          'Assignees (${assignees.length})',
          style: AppTheme.heading(fontSize: 14, fontWeight: FontWeight.w700),
        ),
        const SizedBox(height: 10),
        Wrap(
          spacing: 8,
          runSpacing: 8,
          children: assignees.map((a) {
            return Container(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
              decoration: BoxDecoration(
                color: AppTheme.pureWhite,
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: AppTheme.borderSubtle),
                boxShadow: const [AppTheme.softShadow],
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    a.fullName,
                    style: AppTheme.heading(
                      fontSize: 12,
                      fontWeight: FontWeight.w600,
                      color: AppTheme.deepSlate,
                    ),
                  ),
                  const SizedBox(width: 6),
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 5,
                      vertical: 2,
                    ),
                    decoration: BoxDecoration(
                      color: a.isOwner
                          ? AppTheme.infoBg
                          : const Color(0xFFF1F5F9),
                      borderRadius: BorderRadius.circular(4),
                    ),
                    child: Text(
                      a.responsibility,
                      style: AppTheme.heading(
                        fontSize: 9,
                        fontWeight: FontWeight.w600,
                        color: a.isOwner
                            ? AppTheme.infoText
                            : AppTheme.mutedSlate,
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
        Text(
          'Dependencies',
          style: AppTheme.heading(fontSize: 14, fontWeight: FontWeight.w700),
        ),
        const SizedBox(height: 10),
        if (detail.dependsOn.isNotEmpty) ...[
          Text(
            'Predecessors (this task depends on):',
            style: AppTheme.body(fontSize: 11, color: AppTheme.mutedSlate),
          ),
          const SizedBox(height: 6),
          ...detail.dependsOn.map((d) {
            return Container(
              margin: const EdgeInsets.only(bottom: 6),
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(
                color: d.isFinished ? AppTheme.successBg : AppTheme.dangerBg,
                borderRadius: BorderRadius.circular(8),
              ),
              child: Row(
                children: [
                  Icon(
                    d.isFinished
                        ? Icons.check_circle_outline
                        : Icons.lock_outline,
                    size: 16,
                    color: d.isFinished
                        ? AppTheme.successText
                        : AppTheme.dangerText,
                  ),
                  const SizedBox(width: 8),
                  Text(
                    '${d.taskCode}: ${d.title}',
                    style: AppTheme.body(
                      fontSize: 12,
                      fontWeight: FontWeight.w500,
                      color: d.isFinished
                          ? AppTheme.successText
                          : AppTheme.dangerText,
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

  Widget _buildSubtasksSection(TaskDetailModel detail) {
    final subtasks = detail.subtasks;
    final task = detail.task;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              'Subtasks (${subtasks.length})',
              style: AppTheme.heading(fontSize: 14, fontWeight: FontWeight.w700),
            ),
            if (detail.canManage)
              TextButton.icon(
                onPressed: () async {
                  final added = await Navigator.push<bool>(
                    context,
                    MaterialPageRoute(
                      builder: (_) => TaskFormScreen(
                        initialProjectId: task.projectId,
                        parentTaskId: task.id,
                        parentTaskTitle: task.title,
                      ),
                    ),
                  );
                  if (added == true && mounted) {
                    _loadTaskDetail();
                  }
                },
                icon: const Icon(Icons.add, size: 16, color: AppTheme.royalBlue),
                label: const Text(
                  'Add Subtask',
                  style: TextStyle(
                    color: AppTheme.royalBlue,
                    fontWeight: FontWeight.w700,
                    fontSize: 12,
                  ),
                ),
                style: TextButton.styleFrom(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                  minimumSize: Size.zero,
                  tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                ),
              ),
          ],
        ),
        const SizedBox(height: 10),
        if (subtasks.isEmpty)
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: AppTheme.pureWhite,
              borderRadius: BorderRadius.circular(8),
              border: Border.all(color: AppTheme.borderSubtle),
            ),
            child: Text(
              'No subtasks yet. Click "Add Subtask" to break down this work.',
              style: AppTheme.body(fontSize: 12, color: AppTheme.mutedSlate),
            ),
          )
        else
          ...subtasks.map((s) {
            return InkWell(
              onTap: () async {
                await Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (_) => TaskDetailScreen(taskId: s.id),
                  ),
                );
                if (mounted) {
                  _loadTaskDetail();
                }
              },
              borderRadius: BorderRadius.circular(8),
              child: Container(
                margin: const EdgeInsets.only(bottom: 6),
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: AppTheme.pureWhite,
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: AppTheme.borderSubtle),
                ),
                child: Row(
                  children: [
                    Icon(
                      s.isCompleted
                          ? Icons.check_circle
                          : Icons.radio_button_unchecked,
                      color: s.isCompleted
                          ? AppTheme.royalBlue
                          : AppTheme.lightSlate,
                      size: 18,
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        '${s.taskCode} · ${s.title}',
                        style: AppTheme.body(
                          fontSize: 13,
                          color: AppTheme.deepSlate,
                        ),
                      ),
                    ),
                    const Icon(
                      Icons.chevron_right,
                      size: 16,
                      color: AppTheme.mutedSlate,
                    ),
                  ],
                ),
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
        Text(
          'Status Audit Trail',
          style: AppTheme.heading(fontSize: 14, fontWeight: FontWeight.w700),
        ),
        const SizedBox(height: 10),
        ...history.take(6).map((h) {
          return Container(
            margin: const EdgeInsets.only(bottom: 6),
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
              color: AppTheme.pureWhite,
              borderRadius: BorderRadius.circular(8),
              border: Border.all(color: AppTheme.borderSubtle),
            ),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Icon(Icons.history, size: 16, color: AppTheme.mutedSlate),
                const SizedBox(width: 8),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        '${h.oldStatus} → ${h.newStatus} by ${h.changedByName}',
                        style: AppTheme.body(
                          fontSize: 12,
                          fontWeight: FontWeight.w500,
                          color: AppTheme.deepSlate,
                        ),
                      ),
                      if (h.note != null && h.note!.isNotEmpty)
                        Text(
                          h.note!,
                          style: AppTheme.body(
                            fontSize: 11,
                            color: AppTheme.mutedSlate,
                          ),
                        ),
                    ],
                  ),
                ),
                Text(
                  h.createdAt,
                  style: AppTheme.mono(
                    fontSize: 10,
                    color: AppTheme.lightSlate,
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
    Color bg = const Color(0xFFF1F5F9);
    Color fg = AppTheme.mutedSlate;

    final p = priority.toLowerCase();
    if (p == 'critical' || p == 'urgent') {
      bg = AppTheme.dangerBg;
      fg = AppTheme.dangerText;
    } else if (p == 'high') {
      bg = AppTheme.warningBg;
      fg = AppTheme.warningText;
    } else if (p == 'medium') {
      bg = AppTheme.infoBg;
      fg = AppTheme.infoText;
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 3),
      decoration: BoxDecoration(
        color: bg,
        borderRadius: BorderRadius.circular(4),
      ),
      child: Text(
        priority[0].toUpperCase() + priority.substring(1).toLowerCase(),
        style: AppTheme.heading(
          fontSize: 10,
          fontWeight: FontWeight.w600,
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
            color: AppTheme.dangerBg,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(
              color: AppTheme.dangerText.withValues(alpha: 0.3),
            ),
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                'Failed to load task',
                style: AppTheme.heading(
                  fontSize: 13,
                  fontWeight: FontWeight.w600,
                  color: AppTheme.dangerText,
                ),
              ),
              const SizedBox(height: 8),
              Text(
                _errorMessage ?? 'Unknown error occurred.',
                style: AppTheme.body(color: AppTheme.deepSlate, fontSize: 13),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 14),
              ElevatedButton(
                onPressed: _loadTaskDetail,
                child: const Text('Retry'),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
