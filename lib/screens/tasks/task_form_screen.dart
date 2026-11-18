import 'package:flutter/material.dart';
import '../../core/app_date_utils.dart';
import '../../core/theme.dart';
import '../../core/widgets/brutalist_pressable.dart';
import '../../core/widgets/user_avatar.dart';
import '../../models/project_model.dart';
import '../../models/task_model.dart';
import '../../services/project_service.dart';
import '../../services/task_service.dart';

class TaskFormScreen extends StatefulWidget {
  final int? initialProjectId;
  final int? parentTaskId;
  final String? parentTaskTitle;
  final TaskModel? task;
  final TaskDetailModel? detail;

  const TaskFormScreen({
    super.key,
    this.initialProjectId,
    this.parentTaskId,
    this.parentTaskTitle,
    this.task,
    this.detail,
  });

  @override
  State<TaskFormScreen> createState() => _TaskFormScreenState();
}

class _TaskFormScreenState extends State<TaskFormScreen> {
  final TaskService _taskService = TaskService();
  final ProjectService _projectService = ProjectService();

  final _formKey = GlobalKey<FormState>();
  late final TextEditingController _titleController;
  late final TextEditingController _descriptionController;
  late final TextEditingController _instructionsController;
  late final TextEditingController _estimatedHoursController;

  bool _isLoadingLookups = true;
  bool _isLoadingMembers = false;
  bool _isSubmitting = false;
  String? _lookupError;

  List<Map<String, dynamic>> _projects = [];
  List<Map<String, dynamic>> _projectMembers = [];

  int? _selectedProjectId;
  String _selectedPriority = 'medium'; // low, medium, high, critical
  DateTime? _startDate;
  DateTime? _selectedDeadline;
  int? _selectedOwnerId;
  final Set<int> _selectedContributorIds = {};

  // Assignees search / filter
  String _memberSearchQuery = '';
  final TextEditingController _memberSearchController = TextEditingController();

  // ── Milestone ──────────────────────────────────────────────────────────────
  List<ProjectMilestoneModel> _milestones = [];
  int? _selectedMilestoneId;
  bool _milestoneExpanded = false;

  // ── Parent Task ────────────────────────────────────────────────────────────
  List<Map<String, dynamic>> _projectTasks = [];
  int? _selectedParentTaskId;
  bool _isLoadingTasks = false;
  bool _parentTaskExpanded = false;

  // ── Dependencies ───────────────────────────────────────────────────────────
  final Set<int> _selectedDependencyIds = {};
  bool _dependenciesExpanded = false;

  List<Map<String, dynamic>> get _filteredMembers {
    if (_memberSearchQuery.trim().isEmpty) return _projectMembers;
    final q = _memberSearchQuery.trim().toLowerCase();
    return _projectMembers.where((m) {
      final name = (m['full_name'] ?? '').toString().toLowerCase();
      final dept = (m['department'] ?? '').toString().toLowerCase();
      final desig = (m['designation'] ?? '').toString().toLowerCase();
      return name.contains(q) || dept.contains(q) || desig.contains(q);
    }).toList();
  }

  bool get isEdit => widget.task != null || widget.detail != null;
  bool get isSubtask =>
      widget.parentTaskId != null ||
      (isEdit &&
          (widget.detail?.task.parentTaskId != null ||
              widget.task?.parentTaskId != null));
  int? get currentTaskId => widget.detail?.task.id ?? widget.task?.id;
  int? get effectiveProjectId =>
      widget.detail?.task.projectId ??
      widget.task?.projectId ??
      widget.initialProjectId;

  String _fmtDateIso(DateTime d) =>
      '${d.year}-${d.month.toString().padLeft(2, '0')}-${d.day.toString().padLeft(2, '0')}';

  @override
  void initState() {
    super.initState();

    final existingTitle = widget.detail?.task.title ?? widget.task?.title ?? '';
    final existingDesc = widget.detail?.description ?? '';
    final existingInst = widget.detail?.instructions ?? '';
    final existingEst =
        widget.detail?.task.estimatedHours ?? widget.task?.estimatedHours;

    _titleController = TextEditingController(text: existingTitle);
    _descriptionController = TextEditingController(text: existingDesc);
    _instructionsController = TextEditingController(text: existingInst);
    _estimatedHoursController = TextEditingController(
      text: existingEst != null ? existingEst.toString() : '',
    );

    if (isEdit) {
      final t = widget.detail?.task ?? widget.task!;
      _selectedProjectId = t.projectId;
      _selectedPriority = t.priority.toLowerCase();
      if (t.startDate != null) {
        _startDate = DateTime.tryParse(t.startDate!);
      }
      if (t.deadline != null) {
        _selectedDeadline = DateTime.tryParse(t.deadline!);
      }

      // Populate assignees from detail or task
      final assigneesList = widget.detail?.assignees ?? t.assignees;
      for (final a in assigneesList) {
        if (a.isOwner && _selectedOwnerId == null) {
          _selectedOwnerId = a.userId;
        } else {
          _selectedContributorIds.add(a.userId);
        }
      }

      // Pre-fill milestone, parent task, dependencies
      _selectedMilestoneId = widget.detail?.task.milestoneId ?? widget.task?.milestoneId;
      _selectedParentTaskId = widget.detail?.task.parentTaskId ?? widget.task?.parentTaskId;
      for (final dep in widget.detail?.dependsOn ?? []) {
        _selectedDependencyIds.add(dep.id);
      }
    } else {
      _selectedProjectId = widget.initialProjectId;
      _selectedDeadline = DateTime.now().add(const Duration(days: 7));
    }

    _loadLookups();
  }

  @override
  void dispose() {
    _titleController.dispose();
    _descriptionController.dispose();
    _instructionsController.dispose();
    _estimatedHoursController.dispose();
    _memberSearchController.dispose();
    super.dispose();
  }

  Future<void> _loadLookups() async {
    setState(() {
      _isLoadingLookups = true;
      _lookupError = null;
    });

    try {
      final projects = await _taskService.getActiveProjects();

      if (mounted) {
        setState(() {
          _projects = projects;
          if (_selectedProjectId == null && _projects.isNotEmpty) {
            final p0 = _projects.first['id'];
            _selectedProjectId = p0 is num
                ? p0.toInt()
                : (p0 is String ? int.tryParse(p0) : null);
          } else if (_selectedProjectId != null &&
              !_projects.any((p) {
                final pid = p['id'] is num
                    ? (p['id'] as num).toInt()
                    : int.tryParse(p['id'].toString());
                return pid == _selectedProjectId;
              })) {
            if (_projects.isNotEmpty) {
              final p0 = _projects.first['id'];
              _selectedProjectId = p0 is num
                  ? p0.toInt()
                  : (p0 is String ? int.tryParse(p0) : null);
            }
          }
          _isLoadingLookups = false;
        });

        final pid = effectiveProjectId ?? _selectedProjectId;
        if (pid != null) {
          await _loadProjectMembers(pid);
        }
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _lookupError = e.toString().replaceAll('ApiException', '').trim();
          _isLoadingLookups = false;
        });
      }
    }
  }

  Future<void> _loadProjectMembers(int projectId) async {
    setState(() {
      _isLoadingMembers = true;
    });

    try {
      final detail = await _projectService.getProjectDetails(projectId);

      // Capture milestones for this project
      if (mounted) {
        setState(() {
          _milestones = detail.milestones;
          // Reset milestone selection if previous value not in new list
          if (_selectedMilestoneId != null &&
              !detail.milestones.any((m) => m.id == _selectedMilestoneId)) {
            _selectedMilestoneId = null;
          }
        });
      }

      // Load project tasks (for parent task picker + dependencies)
      await _loadProjectTasks(projectId);

      final assignable = <Map<String, dynamic>>[];

      // Manager is always eligible for task assignment
      if (detail.project.managerId != null) {
        assignable.add({
          'id': detail.project.managerId!,
          'full_name': detail.project.managerName ?? 'Project Manager',
          'designation': 'Project Manager',
          'role': 'manager',
          'photo_url': null,
          'department': 'Manager',
        });
      }

      // Add all project members (both members and viewers)
      for (final mem in detail.members) {
        final uid = mem.userId;
        if (!assignable.any((a) => a['id'] == uid)) {
          final isViewer = mem.memberRole.toLowerCase() == 'viewer';
          final badge = mem.designation != null && mem.designation!.isNotEmpty
              ? mem.designation!
              : (isViewer ? 'Team Member' : 'Member');
          assignable.add({
            'id': uid,
            'full_name': mem.fullName,
            'designation': badge,
            'role': mem.memberRole,
            'photo_url': mem.profilePhotoUrl,
            'department': badge,
          });
        }
      }

      // Also include other active organization staff members
      try {
        final allEmps = await _taskService.getActiveEmployees();
        for (final emp in allEmps) {
          final eid = emp['id'] is num
              ? (emp['id'] as num).toInt()
              : int.tryParse(emp['id'].toString());
          if (eid != null && !assignable.any((a) => a['id'] == eid)) {
            assignable.add({
              'id': eid,
              'full_name': emp['full_name']?.toString() ?? 'User #$eid',
              'designation': emp['designation']?.toString() ?? 'Staff',
              'role': 'employee',
              'photo_url': emp['profile_photo_url']?.toString(),
              'department': emp['department_name']?.toString() ??
                  emp['designation']?.toString() ??
                  'Staff',
            });
          }
        }
      } catch (_) {}

      if (mounted) {
        setState(() {
          _projectMembers = assignable;
          if (_selectedOwnerId == null ||
              !assignable.any((a) {
                final aid = a['id'] is num
                    ? (a['id'] as num).toInt()
                    : int.tryParse(a['id'].toString());
                return aid == _selectedOwnerId;
              })) {
            _selectedOwnerId = assignable.isNotEmpty
                ? (assignable.first['id'] is num
                    ? (assignable.first['id'] as num).toInt()
                    : int.tryParse(assignable.first['id'].toString()))
                : null;
          }
          _selectedContributorIds.removeWhere(
            (id) => !assignable.any((a) {
              final aid = a['id'] is num
                  ? (a['id'] as num).toInt()
                  : int.tryParse(a['id'].toString());
              return aid == id;
            }),
          );
          _memberSearchQuery = '';
          _memberSearchController.clear();
          _isLoadingMembers = false;
        });
      }
    } catch (_) {
      if (mounted) {
        setState(() {
          _isLoadingMembers = false;
        });
      }
    }
  }

  Future<void> _loadProjectTasks(int projectId) async {
    if (mounted) setState(() => _isLoadingTasks = true);
    try {
      final result = await _taskService.getTasks(projectId: projectId, limit: 500);
      final allTasks = (result['tasks'] as List<TaskModel>?) ?? [];
      final selfId = currentTaskId;
      final excludeIds = <int>{};
      if (selfId != null) {
        excludeIds.add(selfId);
        for (final sub in widget.detail?.subtasks ?? []) {
          excludeIds.add(sub.id);
        }
      }
      final taskMaps = allTasks
          .where((t) => !excludeIds.contains(t.id))
          .map((t) => <String, dynamic>{
                'id': t.id,
                'task_code': t.taskCode,
                'title': t.title,
                'status': t.status,
              })
          .toList();
      if (mounted) {
        setState(() {
          _projectTasks = taskMaps;
          if (_selectedParentTaskId != null &&
              !taskMaps.any((t) => t['id'] == _selectedParentTaskId)) {
            _selectedParentTaskId = null;
          }
          _selectedDependencyIds.removeWhere(
            (id) => !taskMaps.any((t) => t['id'] == id),
          );
          _isLoadingTasks = false;
        });
      }
    } catch (_) {
      if (mounted) setState(() => _isLoadingTasks = false);
    }
  }

  Future<void> _pickDate({required bool isStartDate}) async {
    final now = DateTime.now();
    final initial = isStartDate
        ? (_startDate ?? now)
        : (_selectedDeadline ??
              (_startDate ?? now).add(const Duration(days: 7)));

    final picked = await showDatePicker(
      context: context,
      initialDate: initial,
      firstDate: DateTime(2020),
      lastDate: DateTime(2035),
      builder: (context, child) {
        return Theme(
          data: Theme.of(context).copyWith(
            colorScheme: const ColorScheme.light(
              primary: AppTheme.royalBlue,
              onPrimary: AppTheme.pureWhite,
              onSurface: AppTheme.deepSlate,
            ),
          ),
          child: child!,
        );
      },
    );

    if (picked != null && mounted) {
      setState(() {
        if (isStartDate) {
          _startDate = picked;
          if (_selectedDeadline != null &&
              _selectedDeadline!.isBefore(_startDate!)) {
            _selectedDeadline = _startDate;
          }
        } else {
          _selectedDeadline = picked;
        }
      });
    }
  }

  Future<void> _submitTask() async {
    if (!_formKey.currentState!.validate()) return;
    final pid = effectiveProjectId ?? _selectedProjectId;
    if (pid == null) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text('Please select a project.')));
      return;
    }

    if (_startDate != null &&
        _selectedDeadline != null &&
        _selectedDeadline!.isBefore(_startDate!)) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Deadline must be on or after the start date.'),
          backgroundColor: AppTheme.dangerText,
        ),
      );
      return;
    }

    setState(() {
      _isSubmitting = true;
    });

    try {
      final startStr = _startDate != null ? _fmtDateIso(_startDate!) : null;
      final deadlineStr = _selectedDeadline != null
          ? _fmtDateIso(_selectedDeadline!)
          : null;

      final assignees = <int>[];
      final resp = <String, String>{};

      if (_selectedOwnerId != null) {
        assignees.add(_selectedOwnerId!);
        resp[_selectedOwnerId!.toString()] = 'owner';
      }

      for (final cid in _selectedContributorIds) {
        if (!assignees.contains(cid)) {
          assignees.add(cid);
          resp[cid.toString()] = 'contributor';
        }
      }

      final payload = <String, dynamic>{
        'project_id': pid,
        'title': _titleController.text.trim(),
        'description': _descriptionController.text.trim(),
        'instructions': _instructionsController.text.trim(),
        'priority': _selectedPriority,
        'start_date': startStr,
        'deadline': deadlineStr,
        'estimated_hours': _estimatedHoursController.text.trim().isNotEmpty
            ? double.tryParse(_estimatedHoursController.text.trim())
            : null,
        'assignees': assignees,
        'responsibility': resp,
      };

      if (isSubtask && widget.parentTaskId != null) {
        payload['parent_task_id'] = widget.parentTaskId;
      }

      // Milestone
      if (_selectedMilestoneId != null && _selectedMilestoneId! > 0) {
        payload['milestone_id'] = _selectedMilestoneId;
      }

      // Parent task from UI picker (only when not already a fixed subtask)
      if (!(isSubtask && widget.parentTaskId != null) &&
          _selectedParentTaskId != null &&
          _selectedParentTaskId! > 0) {
        payload['parent_task_id'] = _selectedParentTaskId;
      }

      // Dependencies
      if (_selectedDependencyIds.isNotEmpty) {
        payload['dependencies'] = _selectedDependencyIds.toList();
      }

      if (isEdit) {
        await _taskService.updateTask(currentTaskId!, payload);
      } else {
        await _taskService.createTask(payload);
      }

      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            isEdit
                ? 'Task updated successfully.'
                : (isSubtask
                      ? 'Subtask created successfully.'
                      : 'Task assigned successfully.'),
          ),
          backgroundColor: AppTheme.successText,
        ),
      );
      Navigator.pop(context, true);
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
          _isSubmitting = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final titleText = isEdit
        ? 'Edit Task'
        : (isSubtask ? 'Add Subtask' : 'Assign New Task');

    return Scaffold(
      backgroundColor: AppTheme.scaffoldBg,
      appBar: AppBar(
        title: Text(
          titleText,
          style: AppTheme.heading(fontSize: 18, color: AppTheme.deepSlate),
        ),
        backgroundColor: AppTheme.pureWhite,
        iconTheme: const IconThemeData(color: AppTheme.deepSlate),
        elevation: 0,
        scrolledUnderElevation: 0,
        shape: const Border(
          bottom: BorderSide(color: AppTheme.borderSubtle, width: 1.0),
        ),
      ),
      body: _isLoadingLookups
          ? Center(
              child: CircularProgressIndicator(
                color: AppTheme.electricIndigo,
                strokeWidth: 2.5,
              ),
            )
          : _lookupError != null
          ? _buildErrorView()
          : SingleChildScrollView(
              padding: const EdgeInsets.all(16),
              child: Form(
                key: _formKey,
                child: Container(
                  padding: const EdgeInsets.all(20),
                  decoration: BoxDecoration(
                    color: AppTheme.pureWhite,
                    borderRadius: BorderRadius.circular(24),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withValues(alpha: 0.16),
                        blurRadius: 18,
                        offset: const Offset(0, 4),
                      ),
                    ],
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Subtask Header Indicator
                      if (isSubtask) ...[
                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 14,
                            vertical: 10,
                          ),
                          decoration: BoxDecoration(
                            color: AppTheme.infoBg,
                            borderRadius: BorderRadius.circular(10),
                            border: Border.all(
                              color: AppTheme.royalBlue.withValues(alpha: 0.3),
                            ),
                          ),
                          child: Row(
                            children: [
                              const Icon(
                                Icons.subdirectory_arrow_right,
                                color: AppTheme.royalBlue,
                                size: 20,
                              ),
                              const SizedBox(width: 8),
                              Expanded(
                                child: Text(
                                  widget.parentTaskTitle != null
                                      ? 'Subtask of: ${widget.parentTaskTitle}'
                                      : 'Parent Task #${widget.parentTaskId ?? widget.detail?.task.parentTaskId}',
                                  style: AppTheme.body(
                                    fontSize: 13,
                                    color: AppTheme.royalBlue,
                                    fontWeight: FontWeight.w700,
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(height: 16),
                      ],

                      // 1. Project Selector / Locked Badge
                      Text(
                        'Project *',
                        style: AppTheme.heading(
                          fontSize: 13,
                          color: AppTheme.deepSlate,
                        ),
                      ),
                      const SizedBox(height: 8),
                      if (isEdit || isSubtask)
                        _buildLockedProjectCard()
                      else
                        _buildProjectDropdown(),

                      const SizedBox(height: 20),

                      // 2. Task Title
                      Text(
                        'Task Title *',
                        style: AppTheme.heading(
                          fontSize: 13,
                          color: AppTheme.deepSlate,
                        ),
                      ),
                      const SizedBox(height: 8),
                      TextFormField(
                        controller: _titleController,
                        style: AppTheme.body(
                          fontSize: 14,
                          color: AppTheme.deepSlate,
                        ),
                        decoration: InputDecoration(
                          hintText: 'e.g. Implement OAuth Flow',
                          hintStyle: AppTheme.body(
                            fontSize: 14,
                            color: AppTheme.mutedSlate,
                          ),
                          filled: true,
                          fillColor: AppTheme.scaffoldBg,
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(10),
                            borderSide: const BorderSide(
                              color: AppTheme.borderSubtle,
                            ),
                          ),
                          enabledBorder: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(10),
                            borderSide: const BorderSide(
                              color: AppTheme.borderSubtle,
                            ),
                          ),
                          focusedBorder: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(10),
                            borderSide: const BorderSide(
                              color: AppTheme.royalBlue,
                              width: 1.5,
                            ),
                          ),
                        ),
                        validator: (val) {
                          if (val == null || val.trim().isEmpty) {
                            return 'Please enter a task title.';
                          }
                          if (val.trim().length > 200) {
                            return 'Title cannot exceed 200 characters.';
                          }
                          return null;
                        },
                      ),

                      const SizedBox(height: 20),

                      // 3. Priority Selector Chips
                      Text(
                        'Priority',
                        style: AppTheme.heading(
                          fontSize: 13,
                          color: AppTheme.deepSlate,
                        ),
                      ),
                      const SizedBox(height: 8),
                      _buildPriorityChips(),

                      const SizedBox(height: 20),

                      // 4. Dates: Start Date & Deadline
                      Row(
                        children: [
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  'Start Date',
                                  style: AppTheme.heading(
                                    fontSize: 13,
                                    color: AppTheme.deepSlate,
                                  ),
                                ),
                                const SizedBox(height: 8),
                                _buildDateButton(
                                  date: _startDate,
                                  label: 'Select Date',
                                  onTap: () => _pickDate(isStartDate: true),
                                ),
                              ],
                            ),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  'Deadline',
                                  style: AppTheme.heading(
                                    fontSize: 13,
                                    color: AppTheme.deepSlate,
                                  ),
                                ),
                                const SizedBox(height: 8),
                                _buildDateButton(
                                  date: _selectedDeadline,
                                  label: 'Select Deadline',
                                  onTap: () => _pickDate(isStartDate: false),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),

                      const SizedBox(height: 20),

                      // 5. Estimated Hours
                      Text(
                        'Estimated Hours',
                        style: AppTheme.heading(
                          fontSize: 13,
                          color: AppTheme.deepSlate,
                        ),
                      ),
                      const SizedBox(height: 8),
                      TextFormField(
                        controller: _estimatedHoursController,
                        keyboardType: const TextInputType.numberWithOptions(
                          decimal: true,
                        ),
                        style: AppTheme.body(
                          fontSize: 14,
                          color: AppTheme.deepSlate,
                        ),
                        decoration: InputDecoration(
                          hintText: 'e.g. 4.5',
                          hintStyle: AppTheme.body(
                            fontSize: 14,
                            color: AppTheme.mutedSlate,
                          ),
                          filled: true,
                          fillColor: AppTheme.scaffoldBg,
                          suffixText: 'hours',
                          suffixStyle: AppTheme.body(
                            fontSize: 12,
                            color: AppTheme.mutedSlate,
                          ),
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(10),
                            borderSide: const BorderSide(
                              color: AppTheme.borderSubtle,
                            ),
                          ),
                          enabledBorder: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(10),
                            borderSide: const BorderSide(
                              color: AppTheme.borderSubtle,
                            ),
                          ),
                          focusedBorder: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(10),
                            borderSide: const BorderSide(
                              color: AppTheme.royalBlue,
                              width: 1.5,
                            ),
                          ),
                        ),
                        validator: (val) {
                          if (val != null && val.trim().isNotEmpty) {
                            final parsed = double.tryParse(val.trim());
                            if (parsed == null || parsed < 0) {
                              return 'Enter a valid positive number.';
                            }
                          }
                          return null;
                        },
                      ),

                      const SizedBox(height: 20),

                      // 6. Assignees: Unified section with photos
                      _isLoadingMembers
                          ? const LinearProgressIndicator(
                              color: AppTheme.royalBlue,
                              backgroundColor: AppTheme.scaffoldBg,
                            )
                          : _buildAssigneesSection(),

                      const SizedBox(height: 20),

                      // 7. Description
                      Text(
                        'Description',
                        style: AppTheme.heading(
                          fontSize: 13,
                          color: AppTheme.deepSlate,
                        ),
                      ),
                      const SizedBox(height: 8),
                      TextFormField(
                        controller: _descriptionController,
                        maxLines: 4,
                        style: AppTheme.body(
                          fontSize: 14,
                          color: AppTheme.deepSlate,
                        ),
                        decoration: InputDecoration(
                          hintText: 'Detailed requirements or task scope...',
                          hintStyle: AppTheme.body(
                            fontSize: 14,
                            color: AppTheme.mutedSlate,
                          ),
                          filled: true,
                          fillColor: AppTheme.scaffoldBg,
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(10),
                            borderSide: const BorderSide(
                              color: AppTheme.borderSubtle,
                            ),
                          ),
                          enabledBorder: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(10),
                            borderSide: const BorderSide(
                              color: AppTheme.borderSubtle,
                            ),
                          ),
                          focusedBorder: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(10),
                            borderSide: const BorderSide(
                              color: AppTheme.royalBlue,
                              width: 1.5,
                            ),
                          ),
                        ),
                      ),

                      const SizedBox(height: 20),

                      // 8. Instructions
                      Text(
                        'Special Instructions / Acceptance Criteria',
                        style: AppTheme.heading(
                          fontSize: 13,
                          color: AppTheme.deepSlate,
                        ),
                      ),
                      const SizedBox(height: 8),
                      TextFormField(
                        controller: _instructionsController,
                        maxLines: 3,
                        style: AppTheme.body(
                          fontSize: 14,
                          color: AppTheme.deepSlate,
                        ),
                        decoration: InputDecoration(
                          hintText:
                              'Specific technical steps, checklist or notes...',
                          hintStyle: AppTheme.body(
                            fontSize: 14,
                            color: AppTheme.mutedSlate,
                          ),
                          filled: true,
                          fillColor: AppTheme.scaffoldBg,
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(10),
                            borderSide: const BorderSide(
                              color: AppTheme.borderSubtle,
                            ),
                          ),
                          enabledBorder: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(10),
                            borderSide: const BorderSide(
                              color: AppTheme.borderSubtle,
                            ),
                          ),
                          focusedBorder: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(10),
                            borderSide: const BorderSide(
                              color: AppTheme.royalBlue,
                              width: 1.5,
                            ),
                          ),
                        ),
                      ),

                      const SizedBox(height: 28),

                      // 9. Milestone / Parent Task / Dependencies (collapsible)
                      _buildMilestoneSection(),
                      const SizedBox(height: 10),
                      _buildParentTaskSection(),
                      const SizedBox(height: 10),
                      _buildDependenciesSection(),

                      const SizedBox(height: 28),

                      // 10. Submit Button
                      SizedBox(
                        width: double.infinity,
                        height: 52,
                        child: ElevatedButton(
                          onPressed: _isSubmitting ? null : _submitTask,
                          style: ElevatedButton.styleFrom(
                            backgroundColor: AppTheme.deepInk,
                            foregroundColor: AppTheme.pureWhite,
                            disabledBackgroundColor: AppTheme.mutedSlate,
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(999),
                            ),
                            elevation: 0,
                          ),
                          child: _isSubmitting
                              ? const SizedBox(
                                  width: 22,
                                  height: 22,
                                  child: CircularProgressIndicator(
                                    color: AppTheme.pureWhite,
                                    strokeWidth: 2,
                                  ),
                                )
                              : Text(
                                  isEdit
                                      ? 'Save Changes'
                                      : (isSubtask
                                            ? 'Create Subtask'
                                            : 'Assign Task'),
                                  style: AppTheme.heading(
                                    fontSize: 15,
                                    fontWeight: FontWeight.w700,
                                    color: AppTheme.pureWhite,
                                  ),
                                ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
    );
  }

  Widget _buildLockedProjectCard() {
    final pid = effectiveProjectId ?? _selectedProjectId;
    String pName = 'Project #$pid';
    if (_projects.isNotEmpty) {
      final match = _projects.firstWhere(
        (p) => p['id'] == pid,
        orElse: () => {},
      );
      if (match.isNotEmpty && match['name'] != null) {
        pName = match['name'].toString();
      }
    } else if (widget.detail != null) {
      pName = widget.detail!.task.projectName ?? pName;
    }

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
      decoration: BoxDecoration(
        color: AppTheme.scaffoldBg,
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: AppTheme.borderSubtle),
      ),
      child: Row(
        children: [
          const Icon(
            Icons.folder_outlined,
            color: AppTheme.royalBlue,
            size: 20,
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Text(
              pName,
              style: AppTheme.body(
                fontSize: 14,
                color: AppTheme.deepSlate,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
          const Icon(Icons.lock_outline, color: AppTheme.mutedSlate, size: 16),
        ],
      ),
    );
  }

  Widget _buildProjectDropdown() {
    return DropdownButtonFormField<int>(
      initialValue: _selectedProjectId,
      isExpanded: true,
      decoration: InputDecoration(
        filled: true,
        fillColor: AppTheme.scaffoldBg,
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(10),
          borderSide: const BorderSide(color: AppTheme.borderSubtle),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(10),
          borderSide: const BorderSide(color: AppTheme.borderSubtle),
        ),
      ),
      items: _projects.map((p) {
        final id = p['id'] is num
            ? (p['id'] as num).toInt()
            : int.tryParse(p['id'].toString()) ?? 0;
        final name = p['name']?.toString() ?? 'Project #$id';
        final code = p['project_code']?.toString();
        final label = code != null && code.isNotEmpty ? '$name ($code)' : name;
        return DropdownMenuItem<int>(
          value: id,
          child: Text(
            label,
            style: AppTheme.body(fontSize: 14, color: AppTheme.deepSlate),
            overflow: TextOverflow.ellipsis,
          ),
        );
      }).toList(),
      onChanged: (val) {
        if (val != null && val != _selectedProjectId) {
          setState(() {
            _selectedProjectId = val;
            _selectedOwnerId = null;
            _selectedContributorIds.clear();
            // Reset project-dependent fields
            _milestones = [];
            _selectedMilestoneId = null;
            _milestoneExpanded = false;
            _projectTasks = [];
            _selectedParentTaskId = null;
            _parentTaskExpanded = false;
            _selectedDependencyIds.clear();
            _dependenciesExpanded = false;
          });
          _loadProjectMembers(val);
        }
      },
    );
  }

  Widget _buildPriorityChips() {
    final priorities = ['low', 'medium', 'high', 'critical'];
    return Row(
      children: priorities.map((p) {
        final isSelected = _selectedPriority == p;
        Color activeColor;
        switch (p) {
          case 'critical':
            activeColor = AppTheme.dangerText;
            break;
          case 'high':
            activeColor = AppTheme.warningText;
            break;
          case 'medium':
            activeColor = AppTheme.royalBlue;
            break;
          default:
            activeColor = AppTheme.deepSlate;
        }

        return Expanded(
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 3),
            child: BrutalistPressable(
              onTap: () {
                setState(() {
                  _selectedPriority = p;
                });
              },
              child: Container(
                padding: const EdgeInsets.symmetric(vertical: 8),
                decoration: BoxDecoration(
                  color: isSelected ? activeColor : AppTheme.scaffoldBg,
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(
                    color: isSelected ? activeColor : AppTheme.borderSubtle,
                    width: 1.2,
                  ),
                ),
                alignment: Alignment.center,
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 4),
                  child: FittedBox(
                    fit: BoxFit.scaleDown,
                    child: Text(
                      p.toUpperCase(),
                      maxLines: 1,
                      style: AppTheme.heading(
                        fontSize: 11,
                        color: isSelected
                            ? AppTheme.pureWhite
                            : AppTheme.deepSlate,
                      ),
                    ),
                  ),
                ),
              ),
            ),
          ),
        );
      }).toList(),
    );
  }

  Widget _buildDateButton({
    required DateTime? date,
    required String label,
    required VoidCallback onTap,
  }) {
    final display = date != null
        ? AppDateUtils.fmtDate(_fmtDateIso(date))
        : label;
    return BrutalistPressable(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
        decoration: BoxDecoration(
          color: AppTheme.scaffoldBg,
          borderRadius: BorderRadius.circular(10),
          border: Border.all(color: AppTheme.borderSubtle),
        ),
        child: Row(
          children: [
            const Icon(
              Icons.calendar_today_outlined,
              size: 16,
              color: AppTheme.royalBlue,
            ),
            const SizedBox(width: 8),
            Expanded(
              child: Text(
                display,
                style: AppTheme.body(
                  fontSize: 13,
                  color: date != null
                      ? AppTheme.deepSlate
                      : AppTheme.mutedSlate,
                ),
                overflow: TextOverflow.ellipsis,
              ),
            ),
          ],
        ),
      ),
    );
  }

  // ─── Unified Assignees Section ────────────────────────────────────────────

  void _toggleMemberSelection(int id) {
    setState(() {
      final isOwner = _selectedOwnerId == id;
      final isContributor = _selectedContributorIds.contains(id);

      if (isOwner) {
        // De-select current owner
        _selectedOwnerId = null;
      } else if (isContributor) {
        // De-select contributor
        _selectedContributorIds.remove(id);
      } else {
        // Select new person: first selected becomes owner, rest become contributors
        if (_selectedOwnerId == null) {
          _selectedOwnerId = id;
        } else {
          _selectedContributorIds.add(id);
        }
      }
    });
  }

  void _setRoleOwner(int id) {
    setState(() {
      // Demote previous owner to contributor (if different)
      if (_selectedOwnerId != null && _selectedOwnerId != id) {
        _selectedContributorIds.add(_selectedOwnerId!);
      }
      _selectedOwnerId = id;
      _selectedContributorIds.remove(id);
    });
  }

  void _setRoleContributor(int id) {
    setState(() {
      if (_selectedOwnerId == id) {
        _selectedOwnerId = null;
        _selectedContributorIds.add(id);
      }
    });
  }

  int _parseId(dynamic raw) {
    if (raw is num) return raw.toInt();
    return int.tryParse(raw.toString()) ?? 0;
  }

  Widget _buildAssigneesSection() {
    final selectedCount =
        (_selectedOwnerId != null ? 1 : 0) + _selectedContributorIds.length;
    final filtered = _filteredMembers;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // ── Header row: label + count badge ──
        Row(
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            Text(
              'Assignees',
              style: AppTheme.heading(fontSize: 13, color: AppTheme.deepSlate),
            ),
            const SizedBox(width: 10),
            Flexible(
              child: Text(
                selectedCount == 0
                    ? '0 selected · owner = responsible, contributor = shared'
                    : '$selectedCount selected · owner = responsible, contributor = shared',
                style: AppTheme.body(
                  fontSize: 10,
                  color: AppTheme.mutedSlate,
                ),
                overflow: TextOverflow.ellipsis,
              ),
            ),
          ],
        ),
        const SizedBox(height: 8),

        // ── Search / filter field ──
        TextField(
          controller: _memberSearchController,
          onChanged: (val) => setState(() => _memberSearchQuery = val),
          style: AppTheme.body(fontSize: 13, color: AppTheme.deepSlate),
          decoration: InputDecoration(
            hintText: 'Filter by name, department or designation...',
            hintStyle: AppTheme.body(fontSize: 13, color: AppTheme.mutedSlate),
            prefixIcon: const Icon(
              Icons.search,
              size: 18,
              color: AppTheme.mutedSlate,
            ),
            filled: true,
            fillColor: AppTheme.scaffoldBg,
            contentPadding: const EdgeInsets.symmetric(
              horizontal: 12,
              vertical: 10,
            ),
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(10),
              borderSide: const BorderSide(color: AppTheme.borderSubtle),
            ),
            enabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(10),
              borderSide: const BorderSide(color: AppTheme.borderSubtle),
            ),
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(10),
              borderSide: const BorderSide(
                color: AppTheme.royalBlue,
                width: 1.5,
              ),
            ),
          ),
        ),
        const SizedBox(height: 8),

        // ── Members list ──
        Container(
          decoration: BoxDecoration(
            color: AppTheme.pureWhite,
            border: Border.all(color: AppTheme.borderSubtle),
            borderRadius: BorderRadius.circular(12),
          ),
          child: filtered.isEmpty
              ? Padding(
                  padding: const EdgeInsets.all(14),
                  child: Text(
                    _projectMembers.isEmpty
                        ? 'No members found for this project.'
                        : 'No members match your search.',
                    style: AppTheme.body(
                      fontSize: 13,
                      color: AppTheme.mutedSlate,
                    ),
                  ),
                )
              : ConstrainedBox(
                  constraints: const BoxConstraints(maxHeight: 340),
                  child: ListView.separated(
                    shrinkWrap: true,
                    itemCount: filtered.length,
                    separatorBuilder: (context, index) => const Divider(
                      height: 1,
                      thickness: 1,
                      color: AppTheme.borderSubtle,
                    ),
                    itemBuilder: (context, i) =>
                        _buildMemberTile(filtered[i]),
                  ),
                ),
        ),
        const SizedBox(height: 6),
        Text(
          'Project members are listed first. Assigned users are added to the project automatically.',
          style: AppTheme.body(fontSize: 11, color: AppTheme.mutedSlate),
        ),
      ],
    );
  }

  Widget _buildMemberTile(Map<String, dynamic> m) {
    final id = _parseId(m['id']);
    final name = m['full_name']?.toString() ?? 'User #$id';
    final dept = (m['department'] ?? m['designation'] ?? '').toString();
    final photoUrl = m['photo_url']?.toString();
    final isOwner = _selectedOwnerId == id;
    final isContributor = _selectedContributorIds.contains(id);
    final isSelected = isOwner || isContributor;

    return Material(
      color: isSelected
          ? AppTheme.infoBg.withValues(alpha: 0.5)
          : AppTheme.pureWhite,
      child: InkWell(
        onTap: () => _toggleMemberSelection(id),
        borderRadius: BorderRadius.circular(0),
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 10),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              // Checkbox
              SizedBox(
                width: 24,
                height: 24,
                child: Checkbox(
                  value: isSelected,
                  activeColor: AppTheme.royalBlue,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(4),
                  ),
                  onChanged: (_) => _toggleMemberSelection(id),
                ),
              ),
              const SizedBox(width: 10),

              // Avatar with photo or initials fallback
              UserAvatar(
                name: name,
                photoUrl: photoUrl,
                size: 36,
                backgroundColor: const Color(0xFFE0E7FF),
                textColor: AppTheme.royalBlue,
              ),
              const SizedBox(width: 10),

              // Name + department
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      name,
                      style: AppTheme.body(
                        fontSize: 13,
                        color: AppTheme.deepSlate,
                        fontWeight: FontWeight.w600,
                      ),
                      overflow: TextOverflow.ellipsis,
                    ),
                    if (dept.isNotEmpty)
                      Text(
                        dept,
                        style: AppTheme.body(
                          fontSize: 11,
                          color: AppTheme.mutedSlate,
                        ),
                        overflow: TextOverflow.ellipsis,
                      ),
                  ],
                ),
              ),

              // Role toggle (only when selected)
              if (isSelected) ...[
                const SizedBox(width: 6),
                _buildRoleToggle(id, isOwner: isOwner),
              ],
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildRoleToggle(int id, {required bool isOwner}) {
    return Container(
      decoration: BoxDecoration(
        color: AppTheme.scaffoldBg,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: AppTheme.borderSubtle),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          _roleBtn(label: 'Owner', isActive: isOwner, onTap: () => _setRoleOwner(id)),
          Container(width: 1, height: 24, color: AppTheme.borderSubtle),
          _roleBtn(label: 'Contrib.', isActive: !isOwner, onTap: () => _setRoleContributor(id)),
        ],
      ),
    );
  }

  Widget _roleBtn({
    required String label,
    required bool isActive,
    required VoidCallback onTap,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 150),
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 5),
        decoration: BoxDecoration(
          color: isActive ? AppTheme.royalBlue : Colors.transparent,
          borderRadius: BorderRadius.circular(7),
        ),
        child: Text(
          label,
          style: AppTheme.body(
            fontSize: 10,
            color: isActive ? AppTheme.pureWhite : AppTheme.mutedSlate,
            fontWeight: isActive ? FontWeight.w700 : FontWeight.w500,
          ),
        ),
      ),
    );
  }

  // ─── Collapsible Card wrapper ─────────────────────────────────────────────

  Widget _buildCollapsibleCard({
    required IconData icon,
    required String title,
    required String subtitle,
    required bool expanded,
    required VoidCallback onToggle,
    required Widget body,
    bool disabled = false,
  }) {
    return Container(
      decoration: BoxDecoration(
        color: AppTheme.pureWhite,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppTheme.borderSubtle),
      ),
      child: Column(
        children: [
          InkWell(
            onTap: disabled ? null : onToggle,
            borderRadius: BorderRadius.circular(12),
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
              child: Row(
                children: [
                  Icon(
                    icon,
                    size: 18,
                    color: disabled ? AppTheme.mutedSlate : AppTheme.royalBlue,
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          title,
                          style: AppTheme.heading(
                            fontSize: 13,
                            color: AppTheme.deepSlate,
                          ),
                        ),
                        Text(
                          subtitle,
                          style: AppTheme.body(
                            fontSize: 11,
                            color: AppTheme.mutedSlate,
                          ),
                          overflow: TextOverflow.ellipsis,
                        ),
                      ],
                    ),
                  ),
                  if (!disabled)
                    Icon(
                      expanded ? Icons.expand_less : Icons.expand_more,
                      color: AppTheme.mutedSlate,
                      size: 20,
                    ),
                ],
              ),
            ),
          ),
          if (expanded && !disabled) ...[
            Divider(height: 1, thickness: 1, color: AppTheme.borderSubtle),
            Padding(
              padding: const EdgeInsets.all(14),
              child: body,
            ),
          ],
        ],
      ),
    );
  }

  // ─── Milestone Section ────────────────────────────────────────────────────

  Widget _buildMilestoneSection() {
    final projectSelected = (_selectedProjectId ?? effectiveProjectId) != null;

    String subtitle;
    if (!projectSelected) {
      subtitle = 'Select a project first';
    } else if (_milestones.isEmpty) {
      subtitle = _isLoadingTasks ? 'Loading milestones…' : 'No milestones in this project';
    } else if (_selectedMilestoneId != null) {
      final m = _milestones.firstWhere(
        (m) => m.id == _selectedMilestoneId,
        orElse: () => _milestones.first,
      );
      subtitle = m.title;
    } else {
      subtitle = '— None —';
    }

    return _buildCollapsibleCard(
      icon: Icons.flag_outlined,
      title: 'Milestone',
      subtitle: subtitle,
      expanded: _milestoneExpanded,
      disabled: !projectSelected || _milestones.isEmpty,
      onToggle: () => setState(() => _milestoneExpanded = !_milestoneExpanded),
      body: DropdownButtonFormField<int?>(
        initialValue: _selectedMilestoneId,
        isExpanded: true,
        decoration: InputDecoration(
          filled: true,
          fillColor: AppTheme.scaffoldBg,
          contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(10),
            borderSide: const BorderSide(color: AppTheme.borderSubtle),
          ),
          enabledBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(10),
            borderSide: const BorderSide(color: AppTheme.borderSubtle),
          ),
          focusedBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(10),
            borderSide: const BorderSide(color: AppTheme.royalBlue, width: 1.5),
          ),
        ),
        items: [
          DropdownMenuItem<int?>(
            value: null,
            child: Text(
              '— None —',
              style: AppTheme.body(fontSize: 13, color: AppTheme.mutedSlate),
            ),
          ),
          ..._milestones.map((m) {
            final label = m.dueDate != null && m.dueDate!.isNotEmpty
                ? '${m.title}  ·  Due ${AppDateUtils.fmtDate(m.dueDate!)}'
                : m.title;
            return DropdownMenuItem<int?>(
              value: m.id,
              child: Text(
                label,
                style: AppTheme.body(fontSize: 13, color: AppTheme.deepSlate),
                overflow: TextOverflow.ellipsis,
              ),
            );
          }),
        ],
        onChanged: (val) => setState(() => _selectedMilestoneId = val),
      ),
    );
  }

  // ─── Parent Task Section ──────────────────────────────────────────────────

  Widget _buildParentTaskSection() {
    if (isSubtask && widget.parentTaskId != null) {
      return _buildCollapsibleCard(
        icon: Icons.account_tree_outlined,
        title: 'Parent task (makes this a subtask)',
        subtitle: widget.parentTaskTitle != null
            ? widget.parentTaskTitle!
            : 'Task #${widget.parentTaskId}',
        expanded: false,
        disabled: true,
        onToggle: () {},
        body: const SizedBox.shrink(),
      );
    }

    final projectSelected = (_selectedProjectId ?? effectiveProjectId) != null;

    String subtitle;
    if (!projectSelected) {
      subtitle = 'Select a project first';
    } else if (_isLoadingTasks) {
      subtitle = 'Loading tasks…';
    } else if (_projectTasks.isEmpty) {
      subtitle = 'No other tasks in this project';
    } else if (_selectedParentTaskId != null) {
      final t = _projectTasks.firstWhere(
        (t) => t['id'] == _selectedParentTaskId,
        orElse: () => <String, dynamic>{},
      );
      subtitle = t.isNotEmpty ? '${t['task_code']} · ${t['title']}' : '— None —';
    } else {
      subtitle = '— None —';
    }

    return _buildCollapsibleCard(
      icon: Icons.account_tree_outlined,
      title: 'Parent task (makes this a subtask)',
      subtitle: subtitle,
      expanded: _parentTaskExpanded,
      disabled: !projectSelected || (_projectTasks.isEmpty && !_isLoadingTasks),
      onToggle: () => setState(() => _parentTaskExpanded = !_parentTaskExpanded),
      body: _isLoadingTasks
          ? const LinearProgressIndicator(
              color: AppTheme.royalBlue,
              backgroundColor: AppTheme.scaffoldBg,
            )
          : DropdownButtonFormField<int?>(
              initialValue: _selectedParentTaskId,
              isExpanded: true,
              decoration: InputDecoration(
                filled: true,
                fillColor: AppTheme.scaffoldBg,
                contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(10),
                  borderSide: const BorderSide(color: AppTheme.borderSubtle),
                ),
                enabledBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(10),
                  borderSide: const BorderSide(color: AppTheme.borderSubtle),
                ),
                focusedBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(10),
                  borderSide: const BorderSide(color: AppTheme.royalBlue, width: 1.5),
                ),
              ),
              items: [
                DropdownMenuItem<int?>(
                  value: null,
                  child: Text(
                    '— None —',
                    style: AppTheme.body(fontSize: 13, color: AppTheme.mutedSlate),
                  ),
                ),
                ..._projectTasks.map((t) {
                  final id = t['id'] as int;
                  final label = '${t['task_code']} · ${t['title']}';
                  return DropdownMenuItem<int?>(
                    value: id,
                    child: Text(
                      label,
                      style: AppTheme.body(fontSize: 13, color: AppTheme.deepSlate),
                      overflow: TextOverflow.ellipsis,
                    ),
                  );
                }),
              ],
              onChanged: (val) => setState(() => _selectedParentTaskId = val),
            ),
    );
  }

  // ─── Dependencies Section ─────────────────────────────────────────────────

  Widget _buildDependenciesSection() {
    final projectSelected = (_selectedProjectId ?? effectiveProjectId) != null;
    final count = _selectedDependencyIds.length;

    String subtitle;
    if (!projectSelected) {
      subtitle = 'Select a project first';
    } else if (_isLoadingTasks) {
      subtitle = 'Loading tasks…';
    } else if (_projectTasks.isEmpty) {
      subtitle = 'No tasks available';
    } else {
      subtitle = count == 0
          ? 'Tap to select blocking tasks'
          : '$count task${count == 1 ? '' : 's'} selected';
    }

    return _buildCollapsibleCard(
      icon: Icons.link_outlined,
      title: 'Dependencies',
      subtitle: subtitle,
      expanded: _dependenciesExpanded,
      disabled: !projectSelected || (_projectTasks.isEmpty && !_isLoadingTasks),
      onToggle: () => setState(() => _dependenciesExpanded = !_dependenciesExpanded),
      body: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'This task cannot start until these tasks are completed:',
            style: AppTheme.body(fontSize: 11, color: AppTheme.mutedSlate),
          ),
          const SizedBox(height: 8),
          if (_isLoadingTasks)
            const LinearProgressIndicator(
              color: AppTheme.royalBlue,
              backgroundColor: AppTheme.scaffoldBg,
            )
          else
            ConstrainedBox(
              constraints: const BoxConstraints(maxHeight: 240),
              child: ListView.builder(
                shrinkWrap: true,
                itemCount: _projectTasks.length,
                itemBuilder: (context, i) {
                  final t = _projectTasks[i];
                  final id = t['id'] as int;
                  final isChecked = _selectedDependencyIds.contains(id);
                  final status = t['status']?.toString() ?? 'not_started';
                  return InkWell(
                    onTap: () {
                      setState(() {
                        if (isChecked) {
                          _selectedDependencyIds.remove(id);
                        } else {
                          _selectedDependencyIds.add(id);
                        }
                      });
                    },
                    borderRadius: BorderRadius.circular(8),
                    child: Padding(
                      padding: const EdgeInsets.symmetric(vertical: 4),
                      child: Row(
                        children: [
                          SizedBox(
                            width: 24,
                            height: 24,
                            child: Checkbox(
                              value: isChecked,
                              activeColor: AppTheme.royalBlue,
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(4),
                              ),
                              onChanged: (_) {
                                setState(() {
                                  if (isChecked) {
                                    _selectedDependencyIds.remove(id);
                                  } else {
                                    _selectedDependencyIds.add(id);
                                  }
                                });
                              },
                            ),
                          ),
                          const SizedBox(width: 8),
                          Expanded(
                            child: Text(
                              '${t['task_code']} · ${t['title']}',
                              style: AppTheme.body(fontSize: 12, color: AppTheme.deepSlate),
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                          const SizedBox(width: 6),
                          _buildStatusPill(status),
                        ],
                      ),
                    ),
                  );
                },
              ),
            ),
          const SizedBox(height: 6),
          Text(
            'Only tasks of the same project are listed.',
            style: AppTheme.body(fontSize: 10, color: AppTheme.mutedSlate),
          ),
        ],
      ),
    );
  }

  // ─── Status Pill ──────────────────────────────────────────────────────────

  Widget _buildStatusPill(String status) {
    final label = status.replaceAll('_', ' ');
    Color color;
    switch (status) {
      case 'completed':
        color = AppTheme.successText;
        break;
      case 'in_progress':
        color = AppTheme.royalBlue;
        break;
      case 'blocked':
        color = AppTheme.dangerText;
        break;
      case 'pending_review':
        color = AppTheme.warningText;
        break;
      default:
        color = AppTheme.mutedSlate;
    }
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(4),
      ),
      child: Text(
        label,
        style: AppTheme.body(
          fontSize: 10,
          color: color,
          fontWeight: FontWeight.w600,
        ),
      ),
    );
  }

  // ─── Error View ───────────────────────────────────────────────────────────
  Widget _buildErrorView() {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(
              Icons.error_outline,
              size: 48,
              color: AppTheme.dangerText,
            ),
            const SizedBox(height: 16),
            Text(
              'Failed to Load Lookups',
              style: AppTheme.heading(fontSize: 16),
            ),
            const SizedBox(height: 8),
            Text(
              _lookupError ?? 'An unexpected error occurred.',
              textAlign: TextAlign.center,
              style: AppTheme.body(fontSize: 13, color: AppTheme.deepSlate),
            ),
            const SizedBox(height: 20),
            ElevatedButton(
              onPressed: _loadLookups,
              style: ElevatedButton.styleFrom(
                backgroundColor: AppTheme.royalBlue,
                foregroundColor: AppTheme.pureWhite,
              ),
              child: const Text('Retry'),
            ),
          ],
        ),
      ),
    );
  }
}
