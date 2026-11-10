import 'package:flutter/material.dart';
import '../../core/app_date_utils.dart';
import '../../core/theme.dart';
import '../../core/widgets/brutalist_pressable.dart';
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
            _selectedProjectId =
                p0 is num
                    ? p0.toInt()
                    : (p0 is String ? int.tryParse(p0) : null);
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
      final assignable = <Map<String, dynamic>>[];

      // Manager is always eligible for task assignment
      if (detail.project.managerId != null) {
        assignable.add({
          'id': detail.project.managerId!,
          'full_name': detail.project.managerName ?? 'Project Manager',
          'designation': 'Project Manager',
          'role': 'manager',
        });
      }

      // Add project members who have memberRole == 'member'
      for (final mem in detail.members) {
        final uid = mem.userId;
        if (!assignable.any((a) => a['id'] == uid)) {
          if (mem.memberRole.toLowerCase() == 'member') {
            assignable.add({
              'id': uid,
              'full_name': mem.fullName,
              'designation': mem.designation ?? 'Member',
              'role': mem.memberRole,
            });
          }
        }
      }

      if (mounted) {
        setState(() {
          _projectMembers = assignable;
          if (_selectedOwnerId == null ||
              !assignable.any((a) => a['id'] == _selectedOwnerId)) {
            _selectedOwnerId =
                assignable.isNotEmpty
                    ? assignable.first['id'] as int?
                    : null;
          }
          _selectedContributorIds.removeWhere(
            (id) => !assignable.any((a) => a['id'] == id),
          );
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

  Future<void> _pickDate({required bool isStartDate}) async {
    final now = DateTime.now();
    final initial = isStartDate
        ? (_startDate ?? now)
        : (_selectedDeadline ?? (_startDate ?? now).add(const Duration(days: 7)));

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
          if (_selectedDeadline != null && _selectedDeadline!.isBefore(_startDate!)) {
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
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please select a project.')),
      );
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
      final deadlineStr =
          _selectedDeadline != null ? _fmtDateIso(_selectedDeadline!) : null;

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
        title: Text(titleText, style: AppTheme.heading(fontSize: 18)),
      ),
      body: _isLoadingLookups
          ? const Center(
              child: CircularProgressIndicator(
                color: AppTheme.royalBlue,
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
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(
                      color: AppTheme.borderSubtle,
                      width: 1.0,
                    ),
                    boxShadow: const [AppTheme.softShadow],
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

                      // 6. Assignees: Primary Owner & Contributors
                      Text(
                        'Primary Owner (Required)',
                        style: AppTheme.heading(
                          fontSize: 13,
                          color: AppTheme.deepSlate,
                        ),
                      ),
                      const SizedBox(height: 8),
                      _isLoadingMembers
                          ? const LinearProgressIndicator(
                              color: AppTheme.royalBlue,
                              backgroundColor: AppTheme.scaffoldBg,
                            )
                          : _buildOwnerDropdown(),

                      const SizedBox(height: 20),

                      Text(
                        'Contributors (Optional)',
                        style: AppTheme.heading(
                          fontSize: 13,
                          color: AppTheme.deepSlate,
                        ),
                      ),
                      const SizedBox(height: 8),
                      _isLoadingMembers
                          ? const SizedBox.shrink()
                          : _buildContributorsSelector(),

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
                          hintText: 'Specific technical steps, checklist or notes...',
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

                      // 9. Submit Button
                      SizedBox(
                        width: double.infinity,
                        height: 50,
                        child: BrutalistPressable(
                          onTap: _isSubmitting ? null : _submitTask,
                          child: Container(
                            decoration: BoxDecoration(
                              color: _isSubmitting
                                  ? AppTheme.mutedSlate
                                  : AppTheme.royalBlue,
                              borderRadius: BorderRadius.circular(12),
                              boxShadow: const [AppTheme.softShadow],
                            ),
                            alignment: Alignment.center,
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
                                      color: AppTheme.pureWhite,
                                    ),
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
          const Icon(Icons.folder_outlined, color: AppTheme.royalBlue, size: 20),
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
        final id = p['id'] as int;
        final name = p['name']?.toString() ?? 'Project #$id';
        return DropdownMenuItem<int>(
          value: id,
          child: Text(
            name,
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
                child: Text(
                  p.toUpperCase(),
                  style: AppTheme.heading(
                    fontSize: 11,
                    color: isSelected ? AppTheme.pureWhite : AppTheme.deepSlate,
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
    final display = date != null ? AppDateUtils.fmtDate(_fmtDateIso(date)) : label;
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
                  color: date != null ? AppTheme.deepSlate : AppTheme.mutedSlate,
                ),
                overflow: TextOverflow.ellipsis,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildOwnerDropdown() {
    if (_projectMembers.isEmpty) {
      return Container(
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: AppTheme.scaffoldBg,
          borderRadius: BorderRadius.circular(10),
          border: Border.all(color: AppTheme.borderSubtle),
        ),
        child: Text(
          'No members found for this project.',
          style: AppTheme.body(fontSize: 13, color: AppTheme.mutedSlate),
        ),
      );
    }

    return DropdownButtonFormField<int>(
      initialValue: _selectedOwnerId,
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
      items: _projectMembers.map((m) {
        final id = m['id'] as int;
        final name = m['full_name']?.toString() ?? 'User #$id';
        final desig = m['designation']?.toString() ?? '';
        return DropdownMenuItem<int>(
          value: id,
          child: Text(
            '$name ($desig)',
            style: AppTheme.body(fontSize: 13, color: AppTheme.deepSlate),
            overflow: TextOverflow.ellipsis,
          ),
        );
      }).toList(),
      onChanged: (val) {
        if (val != null) {
          setState(() {
            _selectedOwnerId = val;
            _selectedContributorIds.remove(val);
          });
        }
      },
    );
  }

  Widget _buildContributorsSelector() {
    final eligibleContributors = _projectMembers
        .where((m) => m['id'] != _selectedOwnerId)
        .toList();

    if (eligibleContributors.isEmpty) {
      return Text(
        'No additional contributors available in this project.',
        style: AppTheme.body(fontSize: 12, color: AppTheme.mutedSlate),
      );
    }

    return Wrap(
      spacing: 8,
      runSpacing: 8,
      children: eligibleContributors.map((m) {
        final id = m['id'] as int;
        final name = m['full_name']?.toString() ?? 'User #$id';
        final isChecked = _selectedContributorIds.contains(id);

        return FilterChip(
          label: Text(
            name,
            style: AppTheme.body(
              fontSize: 12,
              color: isChecked ? AppTheme.royalBlue : AppTheme.deepSlate,
              fontWeight: isChecked ? FontWeight.w700 : FontWeight.w500,
            ),
          ),
          selected: isChecked,
          selectedColor: AppTheme.infoBg,
          checkmarkColor: AppTheme.royalBlue,
          backgroundColor: AppTheme.scaffoldBg,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(8),
            side: BorderSide(
              color: isChecked ? AppTheme.royalBlue : AppTheme.borderSubtle,
            ),
          ),
          onSelected: (selected) {
            setState(() {
              if (selected) {
                _selectedContributorIds.add(id);
              } else {
                _selectedContributorIds.remove(id);
              }
            });
          },
        );
      }).toList(),
    );
  }

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
            Text('Failed to Load Lookups', style: AppTheme.heading(fontSize: 16)),
            const SizedBox(height: 8),
            Text(
              _lookupError ?? 'An unexpected error occurred.',
              textAlign: TextAlign.center,
              style: AppTheme.body(
                fontSize: 13,
                color: AppTheme.deepSlate,
              ),
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
