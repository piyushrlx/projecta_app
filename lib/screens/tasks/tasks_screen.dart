import 'package:flutter/material.dart';
import '../../core/theme.dart';
import '../../core/widgets/brutalist_pressable.dart';
import '../../models/task_model.dart';
import '../../services/task_service.dart';
import 'task_detail_screen.dart';

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

  // List View State
  List<TaskModel> _tasks = [];
  late String _selectedFilter = widget.initialFilter ?? 'All';

  // Kanban View State
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

          // If in list view, show filter chips
          if (!_isKanbanView) _buildFilterBar(),

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
                ? _buildKanbanBoard()
                : _buildListView(),
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
              child: InkWell(
                onTap: () {
                  if (_isKanbanView) {
                    setState(() => _isKanbanView = false);
                    _loadData();
                  }
                },
                borderRadius: BorderRadius.circular(8),
                child: Container(
                  padding: const EdgeInsets.symmetric(vertical: 8),
                  decoration: BoxDecoration(
                    color: !_isKanbanView
                        ? AppTheme.pureWhite
                        : Colors.transparent,
                    borderRadius: BorderRadius.circular(8),
                    boxShadow: !_isKanbanView
                        ? const [AppTheme.softShadow]
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
                          fontWeight: FontWeight.w600,
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
              child: InkWell(
                onTap: () {
                  if (!_isKanbanView) {
                    setState(() => _isKanbanView = true);
                    _loadData();
                  }
                },
                borderRadius: BorderRadius.circular(8),
                child: Container(
                  padding: const EdgeInsets.symmetric(vertical: 8),
                  decoration: BoxDecoration(
                    color: _isKanbanView
                        ? AppTheme.pureWhite
                        : Colors.transparent,
                    borderRadius: BorderRadius.circular(8),
                    boxShadow: _isKanbanView
                        ? const [AppTheme.softShadow]
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
                          fontWeight: FontWeight.w600,
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

  Widget _buildFilterBar() {
    final filters = [
      'All',
      'My Priority',
      'Overdue',
      'In Progress',
      'Blocked',
      'Pending Review',
    ];

    return Container(
      color: AppTheme.pureWhite,
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      child: SingleChildScrollView(
        scrollDirection: Axis.horizontal,
        child: Row(
          children: filters.map((f) {
            final isSelected = _selectedFilter.toUpperCase() == f.toUpperCase();
            final isAlert =
                f.toUpperCase() == 'OVERDUE' || f.toUpperCase() == 'BLOCKED';

            return Padding(
              padding: const EdgeInsets.only(right: 8),
              child: InkWell(
                onTap: () => _onFilterTap(f),
                borderRadius: BorderRadius.circular(20),
                child: Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 12,
                    vertical: 6,
                  ),
                  decoration: BoxDecoration(
                    color: isSelected
                        ? (isAlert ? AppTheme.dangerBg : AppTheme.navyBlue)
                        : const Color(0xFFF1F5F9),
                    borderRadius: BorderRadius.circular(20),
                    border: Border.all(
                      color: isSelected
                          ? (isAlert
                                ? const Color(0xFFFECACA)
                                : AppTheme.navyBlue)
                          : AppTheme.borderSubtle,
                    ),
                  ),
                  child: Text(
                    f,
                    style: AppTheme.heading(
                      fontSize: 11,
                      fontWeight: FontWeight.w600,
                      color: isSelected
                          ? (isAlert ? AppTheme.dangerText : AppTheme.pureWhite)
                          : AppTheme.mutedSlate,
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
              color: AppTheme.mutedSlate,
            ),
            const SizedBox(height: 12),
            Text('No Tasks Found', style: AppTheme.heading(fontSize: 16)),
            const SizedBox(height: 4),
            Text(
              'No tasks matching filter "$_selectedFilter"',
              style: AppTheme.body(fontSize: 13, color: AppTheme.mutedSlate),
            ),
          ],
        ),
      );
    }

    return RefreshIndicator(
      onRefresh: _loadData,
      color: AppTheme.royalBlue,
      child: ListView.separated(
        padding: const EdgeInsets.all(16),
        itemCount: _tasks.length,
        separatorBuilder: (_, _) => const SizedBox(height: 10),
        itemBuilder: (ctx, idx) => _buildTaskCard(_tasks[idx]),
      ),
    );
  }

  // Smooth Horizontal Snap Columns via PageView (viewportFraction: 0.88)
  Widget _buildKanbanBoard() {
    final columnDefs = [
      {
        'key': 'not_started',
        'label': 'Not Started',
        'bg': const Color(0xFFF1F5F9),
        'fg': AppTheme.mutedSlate,
      },
      {
        'key': 'in_progress',
        'label': 'In Progress',
        'bg': AppTheme.infoBg,
        'fg': AppTheme.infoText,
      },
      {
        'key': 'blocked',
        'label': 'Blocked',
        'bg': AppTheme.dangerBg,
        'fg': AppTheme.dangerText,
      },
      {
        'key': 'pending_review',
        'label': 'Pending Review',
        'bg': AppTheme.warningBg,
        'fg': AppTheme.warningText,
      },
      {
        'key': 'completed',
        'label': 'Completed',
        'bg': AppTheme.successBg,
        'fg': AppTheme.successText,
      },
    ];

    return Column(
      children: [
        // Horizontal Column Indicators & Status Pills
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
          color: AppTheme.pureWhite,
          child: SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            child: Row(
              children: List.generate(columnDefs.length, (idx) {
                final def = columnDefs[idx];
                final list = _kanbanColumns[def['key']] ?? [];
                final isCurrent = _activeKanbanPage == idx;

                return Padding(
                  padding: const EdgeInsets.only(right: 8),
                  child: InkWell(
                    onTap: () {
                      _kanbanPageController.animateToPage(
                        idx,
                        duration: const Duration(milliseconds: 250),
                        curve: Curves.easeInOut,
                      );
                    },
                    borderRadius: BorderRadius.circular(6),
                    child: Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 10,
                        vertical: 5,
                      ),
                      decoration: BoxDecoration(
                        color: isCurrent
                            ? AppTheme.navyBlue
                            : const Color(0xFFF1F5F9),
                        borderRadius: BorderRadius.circular(6),
                      ),
                      child: Text(
                        '${def['label']} (${list.length})',
                        style: AppTheme.heading(
                          fontSize: 11,
                          fontWeight: FontWeight.w600,
                          color: isCurrent
                              ? AppTheme.pureWhite
                              : AppTheme.mutedSlate,
                        ),
                      ),
                    ),
                  ),
                );
              }),
            ),
          ),
        ),

        // Snapping PageView with viewportFraction 0.88
        Expanded(
          child: PageView.builder(
            controller: _kanbanPageController,
            itemCount: columnDefs.length,
            onPageChanged: (idx) {
              setState(() => _activeKanbanPage = idx);
            },
            itemBuilder: (context, colIndex) {
              final col = columnDefs[colIndex];
              final list = _kanbanColumns[col['key']] ?? [];

              return Padding(
                padding: const EdgeInsets.symmetric(
                  horizontal: 6.0,
                  vertical: 12.0,
                ),
                child: Container(
                  decoration: BoxDecoration(
                    color: const Color(0xFFF8FAFC),
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(
                      color: AppTheme.borderSubtle,
                      width: 1.0,
                    ),
                  ),
                  child: Column(
                    children: [
                      // Column Header
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 14,
                          vertical: 12,
                        ),
                        decoration: const BoxDecoration(
                          color: AppTheme.pureWhite,
                          borderRadius: BorderRadius.vertical(
                            top: Radius.circular(12),
                          ),
                          border: Border(
                            bottom: BorderSide(
                              color: AppTheme.borderSubtle,
                              width: 1.0,
                            ),
                          ),
                        ),
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Text(
                              col['label'] as String,
                              style: AppTheme.heading(
                                fontSize: 13,
                                fontWeight: FontWeight.w700,
                                color: AppTheme.deepSlate,
                              ),
                            ),
                            Container(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 8,
                                vertical: 2,
                              ),
                              decoration: BoxDecoration(
                                color: col['bg'] as Color,
                                borderRadius: BorderRadius.circular(6),
                              ),
                              child: Text(
                                '${list.length}',
                                style: AppTheme.mono(
                                  fontSize: 11,
                                  fontWeight: FontWeight.w700,
                                  color: col['fg'] as Color,
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),

                      // Column Tasks List
                      Expanded(
                        child: list.isEmpty
                            ? Center(
                                child: Text(
                                  'No tasks in ${col['label']}',
                                  style: AppTheme.body(
                                    fontSize: 12,
                                    color: AppTheme.mutedSlate,
                                  ),
                                ),
                              )
                            : RefreshIndicator(
                                onRefresh: _loadData,
                                color: AppTheme.royalBlue,
                                child: ListView.separated(
                                  padding: const EdgeInsets.all(12),
                                  itemCount: list.length,
                                  separatorBuilder: (_, _) =>
                                      const SizedBox(height: 10),
                                  itemBuilder: (ctx, idx) =>
                                      _buildTaskCard(list[idx]),
                                ),
                              ),
                      ),
                    ],
                  ),
                ),
              );
            },
          ),
        ),
      ],
    );
  }

  Widget _buildTaskCard(TaskModel task) {
    return BrutalistPressable(
      onTap: () async {
        final changed = await Navigator.push<bool>(
          context,
          MaterialPageRoute(builder: (_) => TaskDetailScreen(taskId: task.id)),
        );
        if (changed == true) {
          _loadData();
        }
      },
      backgroundColor: AppTheme.pureWhite,
      borderColor: task.isLocked
          ? const Color(0xFFFECACA)
          : AppTheme.borderSubtle,
      borderRadius: BorderRadius.circular(12),
      padding: const EdgeInsets.all(14),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Top Row: Code + Project + Priority Badge
          Row(
            children: [
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                decoration: BoxDecoration(
                  color: AppTheme.scaffoldBg,
                  borderRadius: BorderRadius.circular(4),
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
              if (task.projectName != null) ...[
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    task.projectName!,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: AppTheme.body(
                      fontSize: 11,
                      color: AppTheme.mutedSlate,
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
            style: AppTheme.heading(
              fontSize: 14,
              fontWeight: FontWeight.w600,
              color: AppTheme.deepSlate,
            ),
          ),
          const SizedBox(height: 8),

          // Dependency Lock Banner if locked
          if (task.isLocked) ...[
            Container(
              margin: const EdgeInsets.only(bottom: 8),
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
              decoration: BoxDecoration(
                color: AppTheme.dangerBg,
                borderRadius: BorderRadius.circular(6),
              ),
              child: Row(
                children: [
                  const Icon(
                    Icons.lock_outline,
                    size: 14,
                    color: AppTheme.dangerText,
                  ),
                  const SizedBox(width: 6),
                  Expanded(
                    child: Text(
                      'Blocked by ${task.openDependenciesCount} dependency',
                      style: AppTheme.heading(
                        fontSize: 10,
                        fontWeight: FontWeight.w600,
                        color: AppTheme.dangerText,
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
                  'Progress',
                  style: AppTheme.body(
                    fontSize: 10,
                    color: AppTheme.mutedSlate,
                  ),
                ),
                Text(
                  '${task.progress}%',
                  style: AppTheme.mono(
                    fontSize: 10,
                    fontWeight: FontWeight.w700,
                    color: AppTheme.deepSlate,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 4),
            ClipRRect(
              borderRadius: BorderRadius.circular(3),
              child: LinearProgressIndicator(
                value: (task.progress / 100).clamp(0.0, 1.0),
                minHeight: 5,
                backgroundColor: const Color(0xFFE2E8F0),
                valueColor: AlwaysStoppedAnimation<Color>(
                  task.isLocked ? AppTheme.dangerText : AppTheme.royalBlue,
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
                  color: AppTheme.mutedSlate,
                ),
                const SizedBox(width: 3),
                Text(
                  task.assignees.first.fullName.split(' ').first,
                  style: AppTheme.body(
                    fontSize: 11,
                    color: AppTheme.mutedSlate,
                  ),
                ),
              ],
              const Spacer(),
              Icon(
                Icons.calendar_today_outlined,
                size: 12,
                color: task.isOverdue
                    ? AppTheme.dangerText
                    : AppTheme.lightSlate,
              ),
              const SizedBox(width: 4),
              Text(
                task.deadline ?? 'No date',
                style: AppTheme.mono(
                  fontSize: 11,
                  color: task.isOverdue
                      ? AppTheme.dangerText
                      : AppTheme.mutedSlate,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ],
          ),
        ],
      ),
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
      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
      decoration: BoxDecoration(
        color: bg,
        borderRadius: BorderRadius.circular(4),
      ),
      child: Text(
        priority[0].toUpperCase() + priority.substring(1).toLowerCase(),
        style: AppTheme.heading(
          fontSize: 9,
          fontWeight: FontWeight.w600,
          color: fg,
        ),
      ),
    );
  }

  Widget _buildStatusPill(String status) {
    Color bg = const Color(0xFFF1F5F9);
    Color fg = AppTheme.mutedSlate;

    if (status == 'completed') {
      bg = AppTheme.successBg;
      fg = AppTheme.successText;
    } else if (status == 'blocked') {
      bg = AppTheme.dangerBg;
      fg = AppTheme.dangerText;
    } else if (status == 'in_progress') {
      bg = AppTheme.infoBg;
      fg = AppTheme.infoText;
    } else if (status == 'pending_review') {
      bg = AppTheme.warningBg;
      fg = AppTheme.warningText;
    }

    final formatted = status.replaceAll('_', ' ');
    final label = formatted.isEmpty
        ? 'Pending'
        : formatted[0].toUpperCase() + formatted.substring(1).toLowerCase();

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 2),
      decoration: BoxDecoration(
        color: bg,
        borderRadius: BorderRadius.circular(4),
      ),
      child: Text(
        label,
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
                'Failed to load tasks',
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
              ElevatedButton(onPressed: _loadData, child: const Text('Retry')),
            ],
          ),
        ),
      ),
    );
  }
}
