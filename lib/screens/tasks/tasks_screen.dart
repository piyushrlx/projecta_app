import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../../core/api_client.dart';
import '../../core/theme.dart';
import '../../core/widgets/offline_cache_banner.dart';
import '../../models/task_model.dart';
import '../../services/task_service.dart';
import 'task_detail_screen.dart';
import 'widgets/kanban_board_view.dart';
import 'widgets/kanban_status_move_sheet.dart';
import 'widgets/task_filter_bar.dart';
import 'widgets/task_list_view.dart';

class TasksScreen extends StatefulWidget {
  final int? projectId;
  final String? projectName;
  final TaskService? taskService;
  final String? initialFilter;

  const TasksScreen({
    super.key,
    this.projectId,
    this.projectName,
    this.taskService,
    this.initialFilter,
  });

  @override
  State<TasksScreen> createState() => _TasksScreenState();
}

class _TasksScreenState extends State<TasksScreen> {
  late final TaskService _taskService = widget.taskService ?? TaskService();

  bool _isLoading = true;
  String? _errorMessage;
  bool _isKanbanView = false;
  bool _isOfflineCached = false;

  // List View State
  List<TaskModel> _tasks = [];
  late String _selectedFilter = widget.initialFilter ?? 'All';

  // Kanban View State
  String _selectedKanbanPriority = 'All';
  Map<String, List<TaskModel>> _kanbanColumns = {
    'not_started': [],
    'in_progress': [],
    'blocked': [],
    'pending_review': [],
    'completed': [],
  };

  late final PageController _kanbanPageController;
  int _activeKanbanPage = 0;

  @override
  void initState() {
    super.initState();
    _kanbanPageController = PageController(viewportFraction: 0.88);
    _loadData();
  }

  @override
  void dispose() {
    _kanbanPageController.dispose();
    super.dispose();
  }

  Future<void> _loadData() async {
    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    try {
      if (_isKanbanView) {
        final priority = _selectedKanbanPriority == 'All'
            ? null
            : _selectedKanbanPriority.toLowerCase();
        final res = await _taskService.getKanban(
          projectId: widget.projectId,
          priority: priority,
        );
        if (mounted) {
          final rawCols = res['columns'];
          final parsedCols = <String, List<TaskModel>>{
            'not_started': [],
            'in_progress': [],
            'blocked': [],
            'pending_review': [],
            'completed': [],
          };
          if (rawCols is Map) {
            rawCols.forEach((k, v) {
              if (v is List) {
                parsedCols[k.toString()] = v.whereType<TaskModel>().toList();
              }
            });
          }
          setState(() {
            _kanbanColumns = parsedCols;
            _isOfflineCached = res['is_cached'] == true;
            _isLoading = false;
          });
        }
      } else {
        String? status;
        bool? overdue;
        String? priority;

        final upper = _selectedFilter.toUpperCase();
        if (upper == 'OVERDUE') overdue = true;
        if (upper == 'IN PROGRESS') status = 'in_progress';
        if (upper == 'BLOCKED') status = 'blocked';
        if (upper == 'PENDING REVIEW') status = 'pending_review';
        if (upper == 'MY PRIORITY') priority = 'high';

        final res = await _taskService.getTasks(
          projectId: widget.projectId,
          status: status,
          overdue: overdue,
          priority: priority,
          limit: 100,
        );

        if (mounted) {
          setState(() {
            _tasks = (res['tasks'] as List<TaskModel>?) ?? [];
            _isOfflineCached = res['is_cached'] == true;
            _isLoading = false;
          });
        }
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

  void _onFilterTap(String f) {
    if (_selectedFilter == f) return;
    setState(() {
      _selectedFilter = f;
    });
    _loadData();
  }

  void _onKanbanPriorityTap(String p) {
    if (_selectedKanbanPriority == p) return;
    setState(() {
      _selectedKanbanPriority = p;
    });
    _loadData();
  }

  Future<void> _navigateToDetail(TaskModel task) async {
    final changed = await Navigator.push<bool>(
      context,
      MaterialPageRoute(builder: (_) => TaskDetailScreen(taskId: task.id)),
    );
    if (changed == true) {
      _loadData();
    }
  }

  void _showStatusMoveSheet(TaskModel task) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (ctx) => KanbanStatusMoveSheet(
        task: task,
        onSelectStatus: (targetStatus, note) {
          Navigator.pop(ctx);
          _handleTaskMove(task, targetStatus, note: note);
        },
      ),
    );
  }

  Future<void> _handleTaskMove(
    TaskModel task,
    String targetStatus, {
    String? note,
  }) async {
    if (task.status == targetStatus) return;

    if (_isOfflineCached) {
      HapticFeedback.heavyImpact();
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Cannot move cards while viewing offline cached data.'),
          backgroundColor: Color(0xFFB45309),
          behavior: SnackBarBehavior.floating,
        ),
      );
      return;
    }

    if (!task.isStatusAllowed(targetStatus)) {
      HapticFeedback.heavyImpact();
      String reason =
          'Moving to ${_formatStatus(targetStatus)} is not allowed.';
      if (task.isLocked && targetStatus == 'in_progress') {
        reason =
            'Blocked: Waiting on ${task.openDependenciesCount} open dependencies.';
      } else if (targetStatus == 'completed') {
        reason =
            'Staff cannot mark as completed. Move to Pending Review instead.';
      }
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(reason),
          backgroundColor: AppTheme.dangerText,
          behavior: SnackBarBehavior.floating,
        ),
      );
      return;
    }

    if ((targetStatus == 'completed' || targetStatus == 'pending_review') &&
        (note == null || note.trim().isEmpty)) {
      _showCompletionNotesDialog(task, targetStatus);
      return;
    }

    await _executeOptimisticMove(task, targetStatus, note: note);
  }

  Future<void> _executeOptimisticMove(
    TaskModel task,
    String targetStatus, {
    String? note,
  }) async {
    HapticFeedback.mediumImpact();

    final previousColumns = <String, List<TaskModel>>{};
    _kanbanColumns.forEach((k, v) => previousColumns[k] = List<TaskModel>.from(v));

    final fromStatus = task.status;
    final updatedTask = task.copyWith(
      status: targetStatus,
      progress: targetStatus == 'completed' ? 100 : task.progress,
      allowedStatuses: task.nextAllowedStatusesFor(targetStatus),
    );

    setState(() {
      _kanbanColumns[fromStatus]?.removeWhere((t) => t.id == task.id);
      _kanbanColumns[targetStatus]?.insert(0, updatedTask);
    });

    try {
      await _taskService.updateStatus(
        task.id,
        status: targetStatus,
        progress: targetStatus == 'completed' ? 100 : null,
        note: note,
      );
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Moved to ${_formatStatus(targetStatus)}'),
            duration: const Duration(seconds: 2),
            behavior: SnackBarBehavior.floating,
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _kanbanColumns = previousColumns;
        });

        if (e is ApiException &&
            e.details is Map &&
            e.details['needs_note'] == true) {
          _showCompletionNotesDialog(task, targetStatus);
          return;
        }

        final errorMsg = e.toString().replaceAll('ApiException', '').trim();
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              errorMsg.isNotEmpty ? errorMsg : 'Failed to move task',
            ),
            backgroundColor: AppTheme.dangerText,
            behavior: SnackBarBehavior.floating,
          ),
        );
      }
    }
  }

  Future<void> _showCompletionNotesDialog(
    TaskModel task,
    String targetStatus,
  ) async {
    final noteController = TextEditingController();
    final isComplete = targetStatus == 'completed';

    final confirmed = await showModalBottomSheet<bool>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (ctx) {
        return Padding(
          padding: EdgeInsets.only(
            bottom: MediaQuery.of(ctx).viewInsets.bottom,
          ),
          child: Container(
            decoration: const BoxDecoration(
              color: AppTheme.pureWhite,
              borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
            ),
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Center(
                  child: Container(
                    width: 40,
                    height: 4,
                    decoration: BoxDecoration(
                      color: AppTheme.borderSubtle,
                      borderRadius: BorderRadius.circular(2),
                    ),
                  ),
                ),
                const SizedBox(height: 14),
                Text(
                  isComplete ? 'Completion Notes' : 'Review Delivery Notes',
                  style: AppTheme.heading(
                    fontSize: 15,
                    fontWeight: FontWeight.w700,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  isComplete
                      ? 'Please summarize what was completed before closing.'
                      : 'Provide a brief summary for your manager to review.',
                  style: AppTheme.body(
                    fontSize: 12,
                    color: AppTheme.mutedSlate,
                  ),
                ),
                const SizedBox(height: 12),
                TextField(
                  controller: noteController,
                  maxLines: 3,
                  autofocus: true,
                  style: AppTheme.body(fontSize: 13),
                  decoration: InputDecoration(
                    hintText: 'Enter completion notes...',
                    hintStyle: AppTheme.body(
                      fontSize: 13,
                      color: AppTheme.lightSlate,
                    ),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(8),
                      borderSide: const BorderSide(
                        color: AppTheme.borderSubtle,
                      ),
                    ),
                    focusedBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(8),
                      borderSide: const BorderSide(
                        color: AppTheme.navyBlue,
                        width: 1.5,
                      ),
                    ),
                    contentPadding: const EdgeInsets.all(12),
                  ),
                ),
                const SizedBox(height: 16),
                Row(
                  mainAxisAlignment: MainAxisAlignment.end,
                  children: [
                    TextButton(
                      onPressed: () => Navigator.pop(ctx, false),
                      child: Text(
                        'Cancel',
                        style: AppTheme.heading(
                          fontSize: 13,
                          color: AppTheme.mutedSlate,
                        ),
                      ),
                    ),
                    const SizedBox(width: 8),
                    ElevatedButton(
                      onPressed: () {
                        if (noteController.text.trim().isEmpty) {
                          ScaffoldMessenger.of(ctx).showSnackBar(
                            const SnackBar(
                              content: Text('Notes cannot be empty.'),
                              backgroundColor: AppTheme.dangerText,
                            ),
                          );
                          return;
                        }
                        Navigator.pop(ctx, true);
                      },
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppTheme.navyBlue,
                        foregroundColor: AppTheme.pureWhite,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(8),
                        ),
                        padding: const EdgeInsets.symmetric(
                          horizontal: 16,
                          vertical: 10,
                        ),
                      ),
                      child: const Text('Submit & Move'),
                    ),
                  ],
                ),
              ],
            ),
          ),
        );
      },
    );

    if (confirmed == true && noteController.text.trim().isNotEmpty) {
      await _executeOptimisticMove(
        task,
        targetStatus,
        note: noteController.text.trim(),
      );
    }
  }

  String _formatStatus(String status) {
    final s = status.replaceAll('_', ' ');
    return s.isEmpty ? '' : s[0].toUpperCase() + s.substring(1).toLowerCase();
  }

  @override
  Widget build(BuildContext context) {
    final title = widget.projectName != null
        ? '${widget.projectName} Tasks'
        : 'Tasks & Kanban';

    return Scaffold(
      backgroundColor: AppTheme.scaffoldBg,
      appBar: AppBar(
        title: Text(
          title,
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
          style: AppTheme.heading(fontSize: 18),
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            tooltip: 'Refresh',
            onPressed: _loadData,
          ),
        ],
      ),
      body: Column(
        children: [
          // Top Segmented Switcher
          _buildViewToggle(),

          // Ambient Offline Banner
          if (_isOfflineCached)
            OfflineCacheBanner(onRetry: _loadData),

          // Filter bar depends on view mode
          if (!_isKanbanView)
            TaskListFilterBar(
              selectedFilter: _selectedFilter,
              onFilterChanged: _onFilterTap,
            )
          else
            TaskKanbanFilterBar(
              selectedPriority: _selectedKanbanPriority,
              onPriorityChanged: _onKanbanPriorityTap,
            ),

          // Main Body
          Expanded(
            child: _isLoading
                ? const Center(
                    child: CircularProgressIndicator(
                      color: AppTheme.royalBlue,
                      strokeWidth: 2.5,
                    ),
                  )
                : _errorMessage != null
                    ? _buildErrorView()
                    : _isKanbanView
                        ? KanbanBoardView(
                            kanbanColumns: _kanbanColumns,
                            pageController: _kanbanPageController,
                            activePage: _activeKanbanPage,
                            onPageChanged: (idx) {
                              setState(() => _activeKanbanPage = idx);
                            },
                            onTaskTap: _navigateToDetail,
                            onStatusPillTap: _showStatusMoveSheet,
                            onTaskMove: _handleTaskMove,
                            onRefresh: _loadData,
                          )
                        : TaskListView(
                            tasks: _tasks,
                            selectedFilter: _selectedFilter,
                            onRefresh: _loadData,
                            onTaskTap: _navigateToDetail,
                          ),
          ),
        ],
      ),
    );
  }

  Widget _buildViewToggle() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
      decoration: const BoxDecoration(
        color: AppTheme.pureWhite,
        border: Border(
          bottom: BorderSide(color: AppTheme.borderSubtle, width: 1.0),
        ),
      ),
      child: Container(
        padding: const EdgeInsets.all(4),
        decoration: BoxDecoration(
          color: const Color(0xFFF1F5F9),
          borderRadius: BorderRadius.circular(10),
        ),
        child: Row(
          children: [
            Expanded(
              child: GestureDetector(
                onTap: () {
                  if (!_isKanbanView) return;
                  setState(() => _isKanbanView = false);
                  _loadData();
                },
                child: AnimatedContainer(
                  duration: const Duration(milliseconds: 150),
                  padding: const EdgeInsets.symmetric(vertical: 8),
                  decoration: BoxDecoration(
                    color: !_isKanbanView
                        ? AppTheme.pureWhite
                        : Colors.transparent,
                    borderRadius: BorderRadius.circular(8),
                    boxShadow: !_isKanbanView
                        ? [
                            BoxShadow(
                              color: Colors.black.withValues(alpha: 0.05),
                              blurRadius: 4,
                              offset: const Offset(0, 1),
                            )
                          ]
                        : null,
                  ),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(
                        Icons.format_list_bulleted,
                        size: 16,
                        color: !_isKanbanView
                            ? AppTheme.navyBlue
                            : AppTheme.mutedSlate,
                      ),
                      const SizedBox(width: 6),
                      Text(
                        'List View',
                        style: AppTheme.heading(
                          fontSize: 13,
                          fontWeight: !_isKanbanView
                              ? FontWeight.w700
                              : FontWeight.w600,
                          color: !_isKanbanView
                              ? AppTheme.navyBlue
                              : AppTheme.mutedSlate,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
            const SizedBox(width: 4),
            Expanded(
              child: GestureDetector(
                onTap: () {
                  if (_isKanbanView) return;
                  setState(() => _isKanbanView = true);
                  _loadData();
                },
                child: AnimatedContainer(
                  duration: const Duration(milliseconds: 150),
                  padding: const EdgeInsets.symmetric(vertical: 8),
                  decoration: BoxDecoration(
                    color: _isKanbanView
                        ? AppTheme.pureWhite
                        : Colors.transparent,
                    borderRadius: BorderRadius.circular(8),
                    boxShadow: _isKanbanView
                        ? [
                            BoxShadow(
                              color: Colors.black.withValues(alpha: 0.05),
                              blurRadius: 4,
                              offset: const Offset(0, 1),
                            )
                          ]
                        : null,
                  ),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(
                        Icons.view_column_outlined,
                        size: 16,
                        color: _isKanbanView
                            ? AppTheme.navyBlue
                            : AppTheme.mutedSlate,
                      ),
                      const SizedBox(width: 6),
                      Text(
                        'Kanban Board',
                        style: AppTheme.heading(
                          fontSize: 13,
                          fontWeight: _isKanbanView
                              ? FontWeight.w700
                              : FontWeight.w600,
                          color: _isKanbanView
                              ? AppTheme.navyBlue
                              : AppTheme.mutedSlate,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildErrorView() {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24.0),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(
              Icons.error_outline,
              size: 48,
              color: AppTheme.dangerText,
            ),
            const SizedBox(height: 12),
            Text('Error Loading Tasks', style: AppTheme.heading(fontSize: 16)),
            const SizedBox(height: 6),
            Text(
              _errorMessage ?? 'An unexpected error occurred.',
              textAlign: TextAlign.center,
              style: AppTheme.body(fontSize: 13, color: AppTheme.mutedSlate),
            ),
            const SizedBox(height: 16),
            ElevatedButton(
              onPressed: _loadData,
              style: ElevatedButton.styleFrom(
                backgroundColor: AppTheme.navyBlue,
                foregroundColor: AppTheme.pureWhite,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(8),
                ),
              ),
              child: const Text('Try Again'),
            ),
          ],
        ),
      ),
    );
  }
}
