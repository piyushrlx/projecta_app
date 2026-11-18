import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../../core/api_client.dart';
import '../../core/theme.dart';
import '../../core/widgets/module_app_bar.dart';
import '../../core/widgets/offline_cache_banner.dart';
import '../../models/project_model.dart';
import '../../models/task_model.dart';
import '../../services/auth_service.dart';
import '../../services/directory_service.dart';
import '../../services/project_service.dart';
import '../../services/task_service.dart';
import 'create_task_screen.dart';
import '../calendar/calendar_screen.dart';
import 'task_detail_screen.dart';
import 'widgets/kanban_board_view.dart';
import 'widgets/kanban_status_move_sheet.dart';
import 'widgets/task_filter_bar.dart';
import 'widgets/task_list_view.dart';

class TasksScreen extends StatefulWidget {
  final int? projectId;
  final String? projectName;
  final TaskService? taskService;
  final ProjectService? projectService;
  final String? initialFilter;

  const TasksScreen({
    super.key,
    this.projectId,
    this.projectName,
    this.taskService,
    this.projectService,
    this.initialFilter,
  });

  @override
  State<TasksScreen> createState() => _TasksScreenState();
}

class _TasksScreenState extends State<TasksScreen> {
  late final TaskService _taskService = widget.taskService ?? TaskService();
  late final ProjectService _projectService =
      widget.projectService ?? ProjectService();

  bool _isLoading = true;
  String? _errorMessage;
  bool _isKanbanView = false;
  bool _isOfflineCached = false;
  bool _isNavigatingToCalendar = false;

  // Search State
  bool _showSearchBar = false;
  final TextEditingController _searchController = TextEditingController();
  final FocusNode _searchFocusNode = FocusNode();
  Timer? _searchDebounce;

  // List View State
  List<TaskModel> _tasks = [];
  late String _selectedFilter = widget.initialFilter ?? 'All';

  // Kanban View State
  String _selectedKanbanPriority = 'All';
  int? _selectedKanbanProjectId;
  String? _selectedKanbanProjectName;
  int? _selectedKanbanAssigneeId;
  String? _selectedKanbanAssigneeName;
  int? _kanbanServerTotal;
  int? _kanbanServerLimit;

  List<ProjectModel> _availableProjects = [];
  List<Map<String, dynamic>> _availableAssignees = [];

  Map<String, List<TaskModel>> _rawKanbanColumns = {
    'not_started': [],
    'in_progress': [],
    'blocked': [],
    'pending_review': [],
    'completed': [],
  };
  Map<String, List<TaskModel>> _kanbanColumns = {
    'not_started': [],
    'in_progress': [],
    'blocked': [],
    'pending_review': [],
    'completed': [],
  };

  int get _totalKanbanTasks =>
      _kanbanColumns.values.fold(0, (sum, list) => sum + list.length);

  late final PageController _kanbanPageController;
  int _activeKanbanPage = 0;

  @override
  void initState() {
    super.initState();
    _kanbanPageController = PageController(viewportFraction: 0.88);
    _selectedKanbanProjectId = widget.projectId;
    _selectedKanbanProjectName = widget.projectName;
    _loadData();
    if (widget.taskService == null || widget.projectService != null) {
      _loadFilterOptions();
    }
  }

  Future<void> _loadFilterOptions() async {
    final isAdmin = AuthService().currentUser?.isAdmin ?? false;
    try {
      final res = await _projectService.getProjects(status: 'all', limit: 100);
      final projects = (res['projects'] as List<ProjectModel>?) ?? [];
      List<Map<String, dynamic>> assignees = [];
      if (isAdmin) {
        assignees = await DirectoryService().getEmployees(
          status: 'active',
          limit: 100,
        );
      }
      if (mounted) {
        setState(() {
          _availableProjects = projects;
          _availableAssignees = assignees;
        });
      }
    } catch (_) {}
  }

  @override
  void dispose() {
    _searchDebounce?.cancel();
    _searchController.dispose();
    _searchFocusNode.dispose();
    _kanbanPageController.dispose();
    super.dispose();
  }

  Map<String, List<TaskModel>> _filterKanbanByQuery(
    Map<String, List<TaskModel>> source,
    String query,
  ) {
    final clean = query.trim().toLowerCase();
    final filtered = <String, List<TaskModel>>{};
    source.forEach((col, items) {
      if (clean.isEmpty) {
        filtered[col] = List<TaskModel>.from(items);
      } else {
        filtered[col] = items.where((t) {
          return t.title.toLowerCase().contains(clean) ||
              t.taskCode.toLowerCase().contains(clean) ||
              (t.projectName?.toLowerCase().contains(clean) ?? false);
        }).toList();
      }
    });
    return filtered;
  }

  void _onSearchChanged(String query) {
    setState(() {});
    if (_isKanbanView) {
      setState(() {
        _kanbanColumns = _filterKanbanByQuery(_rawKanbanColumns, query);
      });
      return;
    }
    _searchDebounce?.cancel();
    _searchDebounce = Timer(const Duration(milliseconds: 350), () {
      _loadData();
    });
  }

  void _toggleSearchBar() {
    if (_showSearchBar) {
      final hadText = _searchController.text.trim().isNotEmpty;
      _searchDebounce?.cancel();
      _searchController.clear();
      setState(() {
        _showSearchBar = false;
        if (_isKanbanView && hadText) {
          _kanbanColumns = _filterKanbanByQuery(_rawKanbanColumns, '');
        }
      });
      if (!_isKanbanView && hadText) {
        _loadData();
      }
    } else {
      setState(() => _showSearchBar = true);
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (mounted) _searchFocusNode.requestFocus();
      });
    }
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
          projectId: _selectedKanbanProjectId,
          priority: priority,
          userId: _selectedKanbanAssigneeId,
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
            _rawKanbanColumns = parsedCols;
            _kanbanColumns = _filterKanbanByQuery(
              parsedCols,
              _searchController.text,
            );
            _kanbanServerTotal = res['total'] as int?;
            _kanbanServerLimit = res['limit'] as int?;
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

        final searchQuery = _searchController.text.trim();
        final res = await _taskService.getTasks(
          projectId: widget.projectId,
          status: status,
          overdue: overdue,
          priority: priority,
          search: searchQuery.isNotEmpty ? searchQuery : null,
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

  void _resetKanbanFilters() {
    setState(() {
      _selectedKanbanPriority = 'All';
      _selectedKanbanProjectId = widget.projectId;
      _selectedKanbanProjectName = widget.projectName;
      _selectedKanbanAssigneeId = null;
      _selectedKanbanAssigneeName = null;
    });
    _loadData();
  }

  void _showProjectFilterDialog() {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (ctx) {
        return Container(
          decoration: const BoxDecoration(
            color: AppTheme.pureWhite,
            borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
          ),
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
          constraints: BoxConstraints(
            maxHeight: MediaQuery.of(context).size.height * 0.7,
          ),
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
                'Filter by Project',
                style: AppTheme.heading(
                  fontSize: 16,
                  fontWeight: FontWeight.w700,
                ),
              ),
              const SizedBox(height: 4),
              Text(
                'Select a project to view its Kanban board',
                style: AppTheme.body(fontSize: 12, color: AppTheme.mutedSlate),
              ),
              const SizedBox(height: 12),
              Expanded(
                child: ListView(
                  shrinkWrap: true,
                  children: [
                    ListTile(
                      leading: const Icon(
                        Icons.all_inclusive,
                        size: 20,
                        color: AppTheme.royalBlue,
                      ),
                      title: Text(
                        'All Projects',
                        style: AppTheme.heading(
                          fontSize: 13,
                          fontWeight: _selectedKanbanProjectId == null
                              ? FontWeight.w700
                              : FontWeight.w500,
                          color: _selectedKanbanProjectId == null
                              ? AppTheme.royalBlue
                              : AppTheme.deepSlate,
                        ),
                      ),
                      trailing: _selectedKanbanProjectId == null
                          ? const Icon(
                              Icons.check,
                              color: AppTheme.royalBlue,
                              size: 18,
                            )
                          : null,
                      onTap: () {
                        Navigator.pop(ctx);
                        setState(() {
                          _selectedKanbanProjectId = null;
                          _selectedKanbanProjectName = null;
                        });
                        _loadData();
                      },
                    ),
                    const Divider(height: 1),
                    ..._availableProjects.map((p) {
                      final pId = p.id;
                      final pName = p.name;
                      final pCode = p.projectCode;
                      final isSelected = _selectedKanbanProjectId == pId;

                      return ListTile(
                        leading: const Icon(
                          Icons.folder_outlined,
                          size: 20,
                          color: AppTheme.mutedSlate,
                        ),
                        title: Text(
                          pCode.isNotEmpty ? '$pName ($pCode)' : pName,
                          style: AppTheme.heading(
                            fontSize: 13,
                            fontWeight: isSelected
                                ? FontWeight.w700
                                : FontWeight.w500,
                            color: isSelected
                                ? AppTheme.royalBlue
                                : AppTheme.deepSlate,
                          ),
                        ),
                        trailing: isSelected
                            ? const Icon(
                                Icons.check,
                                color: AppTheme.royalBlue,
                                size: 18,
                              )
                            : null,
                        onTap: () {
                          Navigator.pop(ctx);
                          setState(() {
                            _selectedKanbanProjectId = pId;
                            _selectedKanbanProjectName = pName;
                          });
                          _loadData();
                        },
                      );
                    }),
                  ],
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  void _showAssigneeFilterDialog() {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (ctx) {
        return Container(
          decoration: const BoxDecoration(
            color: AppTheme.pureWhite,
            borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
          ),
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
          constraints: BoxConstraints(
            maxHeight: MediaQuery.of(context).size.height * 0.7,
          ),
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
                'Filter by Assignee',
                style: AppTheme.heading(
                  fontSize: 16,
                  fontWeight: FontWeight.w700,
                ),
              ),
              const SizedBox(height: 4),
              Text(
                'View tasks assigned to a specific team member',
                style: AppTheme.body(fontSize: 12, color: AppTheme.mutedSlate),
              ),
              const SizedBox(height: 12),
              Expanded(
                child: ListView(
                  shrinkWrap: true,
                  children: [
                    ListTile(
                      leading: const Icon(
                        Icons.people_outline,
                        size: 20,
                        color: AppTheme.royalBlue,
                      ),
                      title: Text(
                        'Anyone (All Members)',
                        style: AppTheme.heading(
                          fontSize: 13,
                          fontWeight: _selectedKanbanAssigneeId == null
                              ? FontWeight.w700
                              : FontWeight.w500,
                          color: _selectedKanbanAssigneeId == null
                              ? AppTheme.royalBlue
                              : AppTheme.deepSlate,
                        ),
                      ),
                      trailing: _selectedKanbanAssigneeId == null
                          ? const Icon(
                              Icons.check,
                              color: AppTheme.royalBlue,
                              size: 18,
                            )
                          : null,
                      onTap: () {
                        Navigator.pop(ctx);
                        setState(() {
                          _selectedKanbanAssigneeId = null;
                          _selectedKanbanAssigneeName = null;
                        });
                        _loadData();
                      },
                    ),
                    const Divider(height: 1),
                    ..._availableAssignees.map((u) {
                      final uId = int.tryParse(u['id']?.toString() ?? '');
                      final uName =
                          u['full_name']?.toString() ??
                          u['name']?.toString() ??
                          'User';
                      final uRole =
                          u['designation']?.toString() ??
                          u['role']?.toString() ??
                          '';
                      final isSelected = _selectedKanbanAssigneeId == uId;

                      return ListTile(
                        leading: CircleAvatar(
                          radius: 14,
                          backgroundColor: AppTheme.royalBlue.withValues(
                            alpha: 0.1,
                          ),
                          child: Text(
                            uName.isNotEmpty ? uName[0].toUpperCase() : 'U',
                            style: AppTheme.mono(
                              fontSize: 11,
                              fontWeight: FontWeight.w700,
                              color: AppTheme.royalBlue,
                            ),
                          ),
                        ),
                        title: Text(
                          uRole.isNotEmpty ? '$uName ($uRole)' : uName,
                          style: AppTheme.heading(
                            fontSize: 13,
                            fontWeight: isSelected
                                ? FontWeight.w700
                                : FontWeight.w500,
                            color: isSelected
                                ? AppTheme.royalBlue
                                : AppTheme.deepSlate,
                          ),
                        ),
                        trailing: isSelected
                            ? const Icon(
                                Icons.check,
                                color: AppTheme.royalBlue,
                                size: 18,
                              )
                            : null,
                        onTap: () {
                          Navigator.pop(ctx);
                          setState(() {
                            _selectedKanbanAssigneeId = uId;
                            _selectedKanbanAssigneeName = uName;
                          });
                          _loadData();
                        },
                      );
                    }),
                  ],
                ),
              ),
            ],
          ),
        );
      },
    );
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
    _kanbanColumns.forEach(
      (k, v) => previousColumns[k] = List<TaskModel>.from(v),
    );
    final previousRawColumns = <String, List<TaskModel>>{};
    _rawKanbanColumns.forEach(
      (k, v) => previousRawColumns[k] = List<TaskModel>.from(v),
    );

    final fromStatus = task.status;
    final updatedTask = task.copyWith(
      status: targetStatus,
      progress: targetStatus == 'completed' ? 100 : task.progress,
      allowedStatuses: task.nextAllowedStatusesFor(targetStatus),
    );

    setState(() {
      _rawKanbanColumns[fromStatus]?.removeWhere((t) => t.id == task.id);
      _rawKanbanColumns[targetStatus]?.insert(0, updatedTask);
      _kanbanColumns = _filterKanbanByQuery(
        _rawKanbanColumns,
        _searchController.text,
      );
    });

    try {
      final res = await _taskService.updateStatus(
        task.id,
        status: targetStatus,
        progress: targetStatus == 'completed' ? 100 : null,
        note: note,
      );
      if (mounted) {
        if (res['task'] is Map && (res['task']['allowed_statuses'] is List)) {
          final serverAllowed = (res['task']['allowed_statuses'] as List)
              .cast<String>();
          final finalTask = updatedTask.copyWith(
            allowedStatuses: serverAllowed,
          );
          setState(() {
            _rawKanbanColumns[targetStatus]?.removeWhere(
              (t) => t.id == task.id,
            );
            _rawKanbanColumns[targetStatus]?.insert(0, finalTask);
            _kanbanColumns = _filterKanbanByQuery(
              _rawKanbanColumns,
              _searchController.text,
            );
          });
        }
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
          _rawKanbanColumns = previousRawColumns;
          _kanbanColumns = _filterKanbanByQuery(
            _rawKanbanColumns,
            _searchController.text,
          );
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
    String? localError;

    final confirmed = await showModalBottomSheet<bool>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (ctx) {
        return StatefulBuilder(
          builder: (modalCtx, setModalState) {
            return Padding(
              padding: EdgeInsets.only(
                bottom: MediaQuery.of(modalCtx).viewInsets.bottom,
              ),
              child: Container(
                decoration: const BoxDecoration(
                  color: AppTheme.pureWhite,
                  borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
                ),
                padding: const EdgeInsets.symmetric(
                  horizontal: 20,
                  vertical: 16,
                ),
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
                      onChanged: (_) {
                        if (localError != null) {
                          setModalState(() => localError = null);
                        }
                      },
                      style: AppTheme.body(fontSize: 13),
                      decoration: InputDecoration(
                        hintText: 'Enter completion notes...',
                        errorText: localError,
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
                          onPressed: () => Navigator.pop(modalCtx, false),
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
                              setModalState(() {
                                localError = 'Notes cannot be empty.';
                              });
                              return;
                            }
                            Navigator.pop(modalCtx, true);
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
    final subtitle = _isKanbanView
        ? '$_totalKanbanTasks task${_totalKanbanTasks == 1 ? '' : 's'} · Kanban'
        : '${_tasks.length} task${_tasks.length == 1 ? '' : 's'} · $_selectedFilter';
    final isAdmin = AuthService().currentUser?.isAdmin ?? false;

    return Scaffold(
      backgroundColor: AppTheme.scaffoldBg,
      appBar: ModuleAppBar(
        title: title,
        subtitle: subtitle,
        actions: [
          IconButton(
            icon: const Icon(
              Icons.calendar_month_outlined,
              color: AppTheme.deepSlate,
            ),
            tooltip: 'Calendar & Deadlines',
            onPressed: () async {
              if (_isNavigatingToCalendar) return;
              _isNavigatingToCalendar = true;

              final changed = await Navigator.push<bool>(
                context,
                MaterialPageRoute(
                  builder: (_) =>
                      CalendarScreen(currentUser: AuthService().currentUser),
                ),
              );

              _isNavigatingToCalendar = false;

              if (mounted && changed == true) {
                _loadData();
              }
            },
          ),
          IconButton(
            icon: Icon(
              _showSearchBar ? Icons.search_off : Icons.search,
              color: AppTheme.deepSlate,
            ),
            tooltip: _showSearchBar ? 'Close Search' : 'Search Tasks',
            onPressed: _toggleSearchBar,
          ),
          IconButton(
            icon: const Icon(Icons.refresh, color: AppTheme.deepSlate),
            tooltip: 'Refresh',
            onPressed: _loadData,
          ),
        ],
      ),
      floatingActionButton: isAdmin
          ? FloatingActionButton(
              heroTag: 'tasks_screen_fab',
              onPressed: () async {
                final created = await Navigator.push<bool>(
                  context,
                  MaterialPageRoute(
                    builder: (_) =>
                        CreateTaskScreen(initialProjectId: widget.projectId),
                  ),
                );
                if (created == true && mounted) {
                  _loadData();
                }
              },
              backgroundColor: AppTheme.electricIndigo,
              shape: const CircleBorder(),
              tooltip: 'New Task',
              child: const Icon(Icons.add, color: AppTheme.pureWhite),
            )
          : null,
      body: Column(
        children: [
          // Top Segmented Switcher
          _buildViewToggle(),

          // Optional Inline Search Bar
          if (_showSearchBar) _buildSearchBar(),

          // Ambient Offline Banner
          if (_isOfflineCached) OfflineCacheBanner(onRetry: _loadData),

          // Filter bar depends on view mode
          if (!_isKanbanView)
            TaskListFilterBar(
              selectedFilter: _selectedFilter,
              onFilterChanged: _onFilterTap,
            )
          else ...[
            TaskKanbanFilterBar(
              selectedPriority: _selectedKanbanPriority,
              onPriorityChanged: _onKanbanPriorityTap,
              selectedProjectName: _selectedKanbanProjectName,
              onProjectFilterTap: widget.projectId == null
                  ? _showProjectFilterDialog
                  : null,
              selectedAssigneeName: _selectedKanbanAssigneeName,
              onAssigneeFilterTap: isAdmin ? _showAssigneeFilterDialog : null,
              onClearFilters: _resetKanbanFilters,
            ),
            if (_kanbanServerTotal != null &&
                _kanbanServerLimit != null &&
                _kanbanServerTotal! > _kanbanServerLimit!)
              Container(
                width: double.infinity,
                color: const Color(0xFFEFF6FF),
                padding: const EdgeInsets.symmetric(
                  horizontal: 16,
                  vertical: 6,
                ),
                child: Row(
                  children: [
                    const Icon(
                      Icons.info_outline,
                      size: 14,
                      color: AppTheme.royalBlue,
                    ),
                    const SizedBox(width: 6),
                    Expanded(
                      child: Text(
                        'Showing first $_kanbanServerLimit of $_kanbanServerTotal tasks. Narrow filters to see more.',
                        style: AppTheme.body(
                          fontSize: 11,
                          color: AppTheme.royalBlue,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
          ],

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

  Widget _buildSearchBar() {
    return Container(
      color: AppTheme.scaffoldBg,
      padding: const EdgeInsets.fromLTRB(16, 10, 16, 6),
      child: TextField(
        controller: _searchController,
        focusNode: _searchFocusNode,
        onChanged: _onSearchChanged,
        style: AppTheme.body(fontSize: 13, color: AppTheme.pureWhite),
        decoration: InputDecoration(
          hintText: 'Search by task title, code, or project...',
          hintStyle: AppTheme.body(
            fontSize: 13,
            color: AppTheme.textSecondaryNavy,
          ),
          prefixIcon: Icon(
            Icons.search,
            size: 20,
            color: AppTheme.textSecondaryNavy,
          ),
          suffixIcon: _searchController.text.isNotEmpty
              ? IconButton(
                  icon: Icon(
                    Icons.clear,
                    size: 18,
                    color: AppTheme.textSecondaryNavy,
                  ),
                  onPressed: () {
                    _searchController.clear();
                    _onSearchChanged('');
                  },
                )
              : null,
          filled: true,
          fillColor: AppTheme.dockSurface,
          contentPadding: const EdgeInsets.symmetric(
            horizontal: 14,
            vertical: 10,
          ),
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
            borderSide: const BorderSide(color: Color(0xFF1E284A)),
          ),
          enabledBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
            borderSide: const BorderSide(color: Color(0xFF1E284A)),
          ),
          focusedBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
            borderSide: BorderSide(color: AppTheme.electricIndigo, width: 1.5),
          ),
        ),
      ),
    );
  }

  Widget _buildViewToggle() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
      decoration: const BoxDecoration(
        color: AppTheme.scaffoldBg,
        border: Border(
          bottom: BorderSide(color: Color(0xFF1E284A), width: 1.0),
        ),
      ),
      child: Container(
        padding: const EdgeInsets.all(4),
        decoration: BoxDecoration(
          color: AppTheme.dockSurface,
          borderRadius: BorderRadius.circular(12),
        ),
        child: Row(
          children: [
            // Tab 1: List View
            Expanded(
              child: Semantics(
                button: true,
                selected: !_isKanbanView,
                label: 'Switch to List view',
                child: Material(
                  color: Colors.transparent,
                  child: InkWell(
                    borderRadius: BorderRadius.circular(10),
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
                            ? AppTheme.electricIndigo
                            : Colors.transparent,
                        borderRadius: BorderRadius.circular(10),
                      ),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(
                            Icons.format_list_bulleted,
                            size: 16,
                            color: !_isKanbanView
                                ? AppTheme.pureWhite
                                : AppTheme.textSecondaryNavy,
                          ),
                          const SizedBox(width: 6),
                          Flexible(
                            child: Text(
                              'List View',
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              style: AppTheme.heading(
                                fontSize: 13,
                                fontWeight: !_isKanbanView
                                    ? FontWeight.w700
                                    : FontWeight.w600,
                                color: !_isKanbanView
                                    ? AppTheme.pureWhite
                                    : AppTheme.textSecondaryNavy,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              ),
            ),
            const SizedBox(width: 4),

            // Tab 2: Kanban Board
            Expanded(
              child: Semantics(
                button: true,
                selected: _isKanbanView,
                label: 'Switch to Kanban board',
                child: Material(
                  color: Colors.transparent,
                  child: InkWell(
                    borderRadius: BorderRadius.circular(10),
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
                            ? AppTheme.electricIndigo
                            : Colors.transparent,
                        borderRadius: BorderRadius.circular(10),
                      ),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(
                            Icons.view_column_outlined,
                            size: 16,
                            color: _isKanbanView
                                ? AppTheme.pureWhite
                                : AppTheme.textSecondaryNavy,
                          ),
                          const SizedBox(width: 6),
                          Flexible(
                            child: Text(
                              'Kanban Board',
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              style: AppTheme.heading(
                                fontSize: 13,
                                fontWeight: _isKanbanView
                                    ? FontWeight.w700
                                    : FontWeight.w600,
                                color: _isKanbanView
                                    ? AppTheme.pureWhite
                                    : AppTheme.textSecondaryNavy,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
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
