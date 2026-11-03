import 'package:flutter/material.dart';
import '../../core/theme.dart';
import '../../models/task_model.dart';
import '../../services/task_service.dart';
import 'task_detail_screen.dart';

class TasksScreen extends StatefulWidget {
  final int? projectId;
  final String? projectName;

  const TasksScreen({super.key, this.projectId, this.projectName});

  @override
  State<TasksScreen> createState() => _TasksScreenState();
}

class _TasksScreenState extends State<TasksScreen> {
  final TaskService _taskService = TaskService();

  bool _isLoading = true;
  String? _errorMessage;
  bool _isKanbanView = false;

  // List View State
  List<TaskModel> _tasks = [];
  String _selectedFilter =
      'ALL'; // ALL, MY PRIORITY, OVERDUE, IN PROGRESS, BLOCKED, PENDING REVIEW

  // Kanban View State
  Map<String, List<TaskModel>> _kanbanColumns = {
    'not_started': [],
    'in_progress': [],
    'blocked': [],
    'pending_review': [],
    'completed': [],
  };

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  Future<void> _loadData() async {
    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    try {
      if (_isKanbanView) {
        final cols = await _taskService.getKanban(projectId: widget.projectId);
        if (mounted) {
          setState(() {
            _kanbanColumns = cols;
            _isLoading = false;
          });
        }
      } else {
        String? status;
        bool? overdue;
        String? priority;

        if (_selectedFilter == 'OVERDUE') overdue = true;
        if (_selectedFilter == 'IN PROGRESS') status = 'in_progress';
        if (_selectedFilter == 'BLOCKED') status = 'blocked';
        if (_selectedFilter == 'PENDING REVIEW') status = 'pending_review';
        if (_selectedFilter == 'MY PRIORITY') priority = 'high';

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

  @override
  Widget build(BuildContext context) {
    final title = widget.projectName != null
        ? '${widget.projectName!.toUpperCase()} TASKS'
        : 'TASKS & KANBAN';

    return Scaffold(
      backgroundColor: AppTheme.pitchBlack,
      appBar: AppBar(
        title: Text(
          title,
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
          style: AppTheme.heading(fontSize: 16),
        ),
        actions: [
          // View Toggle Button (List vs Kanban)
          IconButton(
            icon: Icon(_isKanbanView ? Icons.view_list : Icons.view_kanban),
            tooltip: _isKanbanView ? 'Switch to List' : 'Switch to Kanban',
            onPressed: () {
              setState(() {
                _isKanbanView = !_isKanbanView;
              });
              _loadData();
            },
          ),
          IconButton(
            icon: const Icon(Icons.refresh),
            tooltip: 'Refresh',
            onPressed: _loadData,
          ),
        ],
      ),
      body: Column(
        children: [
          // If in list view, show 1-tap filter chips
          if (!_isKanbanView) _buildFilterBar(),

          // Main Body
          Expanded(
            child: _isLoading
                ? const Center(
                    child: CircularProgressIndicator(
                      color: AppTheme.violentRed,
                      strokeWidth: 3,
                    ),
                  )
                : _errorMessage != null
                ? _buildErrorView()
                : _isKanbanView
                ? _buildKanbanBoard()
                : _buildListView(),
          ),
        ],
      ),
    );
  }

  Widget _buildFilterBar() {
    final filters = [
      'ALL',
      'MY PRIORITY',
      'OVERDUE',
      'IN PROGRESS',
      'BLOCKED',
      'PENDING REVIEW',
    ];

    return Container(
      color: AppTheme.pitchBlack,
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      child: SingleChildScrollView(
        scrollDirection: Axis.horizontal,
        child: Row(
          children: filters.map((f) {
            final isSelected = _selectedFilter == f;
            final isAlert = f == 'OVERDUE' || f == 'BLOCKED';

            return Padding(
              padding: const EdgeInsets.only(right: 8),
              child: GestureDetector(
                onTap: () => _onFilterTap(f),
                child: Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 12,
                    vertical: 7,
                  ),
                  decoration: BoxDecoration(
                    color: isSelected
                        ? (isAlert ? AppTheme.violentRed : AppTheme.pureWhite)
                        : AppTheme.pitchBlack,
                    border: Border.all(
                      color: isAlert ? AppTheme.violentRed : AppTheme.pureWhite,
                      width: 2.0,
                    ),
                  ),
                  child: Text(
                    f,
                    style: AppTheme.mono(
                      fontSize: 11,
                      fontWeight: FontWeight.w800,
                      color: isSelected
                          ? (isAlert ? AppTheme.pureWhite : AppTheme.pitchBlack)
                          : AppTheme.pureWhite,
                    ),
                  ),
                ),
              ),
            );
          }).toList(),
        ),
      ),
    );
  }

  Widget _buildListView() {
    if (_tasks.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(
              Icons.check_circle_outline,
              size: 48,
              color: AppTheme.pureWhite,
            ),
            const SizedBox(height: 12),
            Text('NO TASKS FOUND', style: AppTheme.heading(fontSize: 16)),
            const SizedBox(height: 6),
            Text(
              'No tasks matching filter "$_selectedFilter"',
              style: AppTheme.body(
                fontSize: 13,
                color: const Color(0xFFAAAAAA),
              ),
            ),
          ],
        ),
      );
    }

    return RefreshIndicator(
      onRefresh: _loadData,
      color: AppTheme.violentRed,
      child: ListView.separated(
        padding: const EdgeInsets.all(16),
        itemCount: _tasks.length,
        separatorBuilder: (_, _) => const SizedBox(height: 12),
        itemBuilder: (ctx, idx) => _buildTaskCard(_tasks[idx]),
      ),
    );
  }

  Widget _buildKanbanBoard() {
    final columnKeys = [
      {'key': 'not_started', 'label': 'NOT STARTED'},
      {'key': 'in_progress', 'label': 'IN PROGRESS'},
      {'key': 'blocked', 'label': 'BLOCKED'},
      {'key': 'pending_review', 'label': 'REVIEW'},
      {'key': 'completed', 'label': 'DONE'},
    ];

    return DefaultTabController(
      length: columnKeys.length,
      child: Column(
        children: [
          Container(
            color: const Color(0xFF161616),
            child: TabBar(
              isScrollable: true,
              tabAlignment: TabAlignment.start,
              indicatorColor: AppTheme.violentRed,
              indicatorWeight: 3,
              labelColor: AppTheme.pureWhite,
              unselectedLabelColor: const Color(0xFF888888),
              labelStyle: AppTheme.mono(
                fontSize: 11,
                fontWeight: FontWeight.w800,
              ),
              tabs: columnKeys.map((c) {
                final list = _kanbanColumns[c['key']] ?? [];
                return Tab(text: '${c['label']} (${list.length})');
              }).toList(),
            ),
          ),
          Expanded(
            child: TabBarView(
              children: columnKeys.map((c) {
                final list = _kanbanColumns[c['key']] ?? [];
                if (list.isEmpty) {
                  return Center(
                    child: Text(
                      'No tasks in ${c['label']}',
                      style: AppTheme.body(color: const Color(0xFF888888)),
                    ),
                  );
                }
                return RefreshIndicator(
                  onRefresh: _loadData,
                  color: AppTheme.violentRed,
                  child: ListView.separated(
                    padding: const EdgeInsets.all(16),
                    itemCount: list.length,
                    separatorBuilder: (_, _) => const SizedBox(height: 12),
                    itemBuilder: (ctx, idx) => _buildTaskCard(list[idx]),
                  ),
                );
              }).toList(),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildTaskCard(TaskModel task) {
    return GestureDetector(
      onTap: () async {
        final changed = await Navigator.push<bool>(
          context,
          MaterialPageRoute(builder: (_) => TaskDetailScreen(taskId: task.id)),
        );
        if (changed == true) {
          _loadData();
        }
      },
      child: Container(
        decoration: AppTheme.neoCardDecoration(
          backgroundColor: AppTheme.pureWhite,
          borderColor: AppTheme.pitchBlack,
          shadowOffset: 4,
          shadowColor: AppTheme.pureWhite,
        ),
        padding: const EdgeInsets.all(14),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Top Row: Code + Project + Priority Badge
            Row(
              children: [
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 6,
                    vertical: 2,
                  ),
                  color: AppTheme.pitchBlack,
                  child: Text(
                    task.taskCode,
                    style: AppTheme.mono(
                      fontSize: 11,
                      fontWeight: FontWeight.w800,
                      color: AppTheme.pureWhite,
                    ),
                  ),
                ),
                if (task.projectName != null) ...[
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      task.projectName!.toUpperCase(),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: AppTheme.mono(
                        fontSize: 10,
                        color: const Color(0xFF666666),
                      ),
                    ),
                  ),
                ] else
                  const Spacer(),
                _buildPriorityBadge(task.priority),
              ],
            ),
            const SizedBox(height: 8),
            // Title
            Text(
              task.title,
              style: AppTheme.heading(fontSize: 15, color: AppTheme.pitchBlack),
            ),
            const SizedBox(height: 8),

            // Dependency Lock Banner if locked
            if (task.isLocked) ...[
              Container(
                margin: const EdgeInsets.only(bottom: 8),
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                color: const Color(0xFFFFEBEE),
                child: Row(
                  children: [
                    const Icon(
                      Icons.lock,
                      size: 14,
                      color: AppTheme.violentRed,
                    ),
                    const SizedBox(width: 6),
                    Expanded(
                      child: Text(
                        'BLOCKED BY ${task.openDependenciesCount} UNFINISHED DEPENDENCY',
                        style: AppTheme.mono(
                          fontSize: 10,
                          fontWeight: FontWeight.w800,
                          color: AppTheme.violentRed,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ],

            // Progress Bar if in progress
            if (task.status == 'in_progress' || task.progress > 0) ...[
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    'PROGRESS',
                    style: AppTheme.mono(
                      fontSize: 10,
                      color: const Color(0xFF666666),
                    ),
                  ),
                  Text(
                    '${task.progress}%',
                    style: AppTheme.mono(
                      fontSize: 10,
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 4),
              ClipRRect(
                borderRadius: BorderRadius.zero,
                child: LinearProgressIndicator(
                  value: (task.progress / 100).clamp(0.0, 1.0),
                  minHeight: 5,
                  backgroundColor: const Color(0xFFEEEEEE),
                  valueColor: AlwaysStoppedAnimation<Color>(
                    task.isLocked ? AppTheme.violentRed : AppTheme.pitchBlack,
                  ),
                ),
              ),
              const SizedBox(height: 8),
            ],

            // Bottom Meta Row: Status tag, Assignee count, Deadline
            Row(
              children: [
                _buildStatusPill(task.status),
                const SizedBox(width: 8),
                if (task.assignees.isNotEmpty) ...[
                  const Icon(
                    Icons.person_outline,
                    size: 13,
                    color: AppTheme.neutralGrey,
                  ),
                  const SizedBox(width: 3),
                  Text(
                    task.assignees.first.fullName.split(' ').first,
                    style: AppTheme.mono(
                      fontSize: 11,
                      color: const Color(0xFF555555),
                    ),
                  ),
                ],
                const Spacer(),
                Icon(
                  Icons.calendar_today_outlined,
                  size: 12,
                  color: task.isOverdue
                      ? AppTheme.violentRed
                      : AppTheme.neutralGrey,
                ),
                const SizedBox(width: 4),
                Text(
                  task.deadline ?? 'NO DATE',
                  style: AppTheme.mono(
                    fontSize: 11,
                    color: task.isOverdue
                        ? AppTheme.violentRed
                        : const Color(0xFF444444),
                    fontWeight: task.isOverdue
                        ? FontWeight.w800
                        : FontWeight.w600,
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildPriorityBadge(String priority) {
    Color bg = const Color(0xFFE0E0E0);
    Color fg = AppTheme.pitchBlack;

    if (priority == 'critical' || priority == 'high') {
      bg = AppTheme.violentRed;
      fg = AppTheme.pureWhite;
    } else if (priority == 'medium') {
      bg = const Color(0xFFFFF3E0);
      fg = const Color(0xFFE65100);
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

  Widget _buildStatusPill(String status) {
    Color bg = const Color(0xFFEEEEEE);
    Color fg = AppTheme.pitchBlack;

    if (status == 'completed') {
      bg = const Color(0xFFE8F5E9);
      fg = const Color(0xFF2E7D32);
    } else if (status == 'blocked') {
      bg = const Color(0xFFFFEBEE);
      fg = AppTheme.violentRed;
    } else if (status == 'in_progress') {
      bg = const Color(0xFFE3F2FD);
      fg = const Color(0xFF1565C0);
    } else if (status == 'pending_review') {
      bg = const Color(0xFFFFF8E1);
      fg = const Color(0xFFF57F17);
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
      decoration: BoxDecoration(
        color: bg,
        border: Border.all(color: AppTheme.pitchBlack, width: 1),
      ),
      child: Text(
        status.replaceAll('_', ' ').toUpperCase(),
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
                'FAILED TO LOAD TASKS',
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
                onPressed: _loadData,
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
