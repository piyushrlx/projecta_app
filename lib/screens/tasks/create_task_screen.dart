import 'package:flutter/material.dart';
import '../../core/theme.dart';
import '../../services/task_service.dart';

class CreateTaskScreen extends StatefulWidget {
  final int? initialProjectId;

  const CreateTaskScreen({super.key, this.initialProjectId});

  @override
  State<CreateTaskScreen> createState() => _CreateTaskScreenState();
}

class _CreateTaskScreenState extends State<CreateTaskScreen> {
  final TaskService _taskService = TaskService();

  final _formKey = GlobalKey<FormState>();
  final _titleController = TextEditingController();
  final _descriptionController = TextEditingController();
  final _estimatedHoursController = TextEditingController();

  bool _isLoadingLookups = true;
  bool _isSubmitting = false;
  String? _lookupError;

  List<Map<String, dynamic>> _projects = [];
  List<Map<String, dynamic>> _employees = [];

  int? _selectedProjectId;
  String _selectedPriority = 'medium'; // low, medium, high, critical
  DateTime? _selectedDeadline;
  int? _selectedOwnerId;
  final Set<int> _selectedContributorIds = {};

  @override
  void initState() {
    super.initState();
    _selectedProjectId = widget.initialProjectId;
    _selectedDeadline = DateTime.now().add(const Duration(days: 7));
    _loadLookups();
  }

  Future<void> _loadLookups() async {
    setState(() {
      _isLoadingLookups = true;
      _lookupError = null;
    });

    try {
      final projectsFuture = _taskService.getActiveProjects();
      final employeesFuture = _taskService.getActiveEmployees();

      final results = await Future.wait([projectsFuture, employeesFuture]);

      if (mounted) {
        setState(() {
          _projects = results[0];
          _employees = results[1];

          if (_selectedProjectId == null && _projects.isNotEmpty) {
            _selectedProjectId = (_projects.first['id'] as num?)?.toInt();
          }
          if (_employees.isNotEmpty) {
            _selectedOwnerId = (_employees.first['id'] as num?)?.toInt();
          }

          _isLoadingLookups = false;
        });
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

  Future<void> _submitTask() async {
    if (!_formKey.currentState!.validate()) return;
    if (_selectedProjectId == null) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text('Please select a project.')));
      return;
    }

    setState(() {
      _isSubmitting = true;
    });

    try {
      final deadlineStr = _selectedDeadline != null
          ? '${_selectedDeadline!.year}-${_selectedDeadline!.month.toString().padLeft(2, '0')}-${_selectedDeadline!.day.toString().padLeft(2, '0')}'
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
        'project_id': _selectedProjectId,
        'title': _titleController.text.trim(),
        'description': _descriptionController.text.trim(),
        'priority': _selectedPriority,
        'deadline': deadlineStr,
        'estimated_hours': _estimatedHoursController.text.trim().isNotEmpty
            ? double.tryParse(_estimatedHoursController.text.trim())
            : null,
        'assignees': assignees,
        'responsibility': resp,
      };

      await _taskService.createTask(payload);

      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Task assigned successfully.'),
          backgroundColor: AppTheme.pitchBlack,
        ),
      );
      Navigator.pop(context, true);
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
          _isSubmitting = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.pitchBlack,
      appBar: AppBar(
        title: Text('ASSIGN NEW TASK', style: AppTheme.heading(fontSize: 16)),
      ),
      body: _isLoadingLookups
          ? const Center(
              child: CircularProgressIndicator(
                color: AppTheme.violentRed,
                strokeWidth: 3,
              ),
            )
          : _lookupError != null
          ? _buildErrorView()
          : SingleChildScrollView(
              padding: const EdgeInsets.all(16),
              child: Form(
                key: _formKey,
                child: Container(
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
                      // 1. Project Selector
                      Text(
                        'PROJECT *',
                        style: AppTheme.mono(
                          fontSize: 11,
                          fontWeight: FontWeight.w800,
                        ),
                      ),
                      const SizedBox(height: 6),
                      DropdownButtonFormField<int>(
                        initialValue: _selectedProjectId,
                        isExpanded: true,
                        decoration: const InputDecoration(
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.zero,
                          ),
                          contentPadding: EdgeInsets.symmetric(
                            horizontal: 12,
                            vertical: 10,
                          ),
                        ),
                        items: _projects.map((p) {
                          final id = (p['id'] as num).toInt();
                          final name = p['name']?.toString() ?? '';
                          final code = p['project_code']?.toString() ?? '';
                          return DropdownMenuItem<int>(
                            value: id,
                            child: Text(
                              '$code · $name',
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              style: AppTheme.body(
                                fontSize: 13,
                                color: AppTheme.pitchBlack,
                              ),
                            ),
                          );
                        }).toList(),
                        onChanged: (val) {
                          setState(() {
                            _selectedProjectId = val;
                          });
                        },
                      ),
                      const SizedBox(height: 14),

                      // 2. Task Title
                      Text(
                        'TASK TITLE *',
                        style: AppTheme.mono(
                          fontSize: 11,
                          fontWeight: FontWeight.w800,
                        ),
                      ),
                      const SizedBox(height: 6),
                      TextFormField(
                        controller: _titleController,
                        style: AppTheme.body(color: AppTheme.pitchBlack),
                        decoration: const InputDecoration(
                          hintText:
                              'e.g. Implement checkout flow backend integration',
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.zero,
                          ),
                        ),
                        validator: (v) {
                          if (v == null || v.trim().isEmpty) {
                            return 'Please enter a title.';
                          }
                          return null;
                        },
                      ),
                      const SizedBox(height: 14),

                      // 3. Description
                      Text(
                        'DESCRIPTION & INSTRUCTIONS',
                        style: AppTheme.mono(
                          fontSize: 11,
                          fontWeight: FontWeight.w800,
                        ),
                      ),
                      const SizedBox(height: 6),
                      TextFormField(
                        controller: _descriptionController,
                        maxLines: 3,
                        style: AppTheme.body(color: AppTheme.pitchBlack),
                        decoration: const InputDecoration(
                          hintText:
                              'Provide task context, requirements, deliverables...',
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.zero,
                          ),
                        ),
                      ),
                      const SizedBox(height: 14),

                      // 4. Priority Selector
                      Text(
                        'PRIORITY LEVEL',
                        style: AppTheme.mono(
                          fontSize: 11,
                          fontWeight: FontWeight.w800,
                        ),
                      ),
                      const SizedBox(height: 6),
                      _buildPrioritySelector(),
                      const SizedBox(height: 14),

                      // 5. Deadline & Estimated Hours
                      Row(
                        children: [
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  'DEADLINE',
                                  style: AppTheme.mono(
                                    fontSize: 11,
                                    fontWeight: FontWeight.w800,
                                  ),
                                ),
                                const SizedBox(height: 6),
                                GestureDetector(
                                  onTap: () async {
                                    final picked = await showDatePicker(
                                      context: context,
                                      initialDate:
                                          _selectedDeadline ?? DateTime.now(),
                                      firstDate: DateTime.now().subtract(
                                        const Duration(days: 7),
                                      ),
                                      lastDate: DateTime.now().add(
                                        const Duration(days: 365),
                                      ),
                                    );
                                    if (picked != null) {
                                      setState(() {
                                        _selectedDeadline = picked;
                                      });
                                    }
                                  },
                                  child: Container(
                                    padding: const EdgeInsets.symmetric(
                                      horizontal: 10,
                                      vertical: 12,
                                    ),
                                    decoration: BoxDecoration(
                                      border: Border.all(
                                        color: const Color(0xFFCCCCCC),
                                      ),
                                    ),
                                    child: Row(
                                      mainAxisAlignment:
                                          MainAxisAlignment.spaceBetween,
                                      children: [
                                        Text(
                                          _selectedDeadline != null
                                              ? '${_selectedDeadline!.year}-${_selectedDeadline!.month.toString().padLeft(2, '0')}-${_selectedDeadline!.day.toString().padLeft(2, '0')}'
                                              : 'Select Date',
                                          style: AppTheme.mono(fontSize: 12),
                                        ),
                                        const Icon(
                                          Icons.calendar_today,
                                          size: 16,
                                        ),
                                      ],
                                    ),
                                  ),
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
                                  'EST. HOURS',
                                  style: AppTheme.mono(
                                    fontSize: 11,
                                    fontWeight: FontWeight.w800,
                                  ),
                                ),
                                const SizedBox(height: 6),
                                TextFormField(
                                  controller: _estimatedHoursController,
                                  keyboardType:
                                      const TextInputType.numberWithOptions(
                                        decimal: true,
                                      ),
                                  style: AppTheme.mono(fontSize: 12),
                                  decoration: const InputDecoration(
                                    hintText: 'e.g. 8.5',
                                    border: OutlineInputBorder(
                                      borderRadius: BorderRadius.zero,
                                    ),
                                    contentPadding: EdgeInsets.symmetric(
                                      horizontal: 10,
                                      vertical: 12,
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 16),

                      // 6. Lead Owner Assignee
                      Text(
                        'PRIMARY OWNER *',
                        style: AppTheme.mono(
                          fontSize: 11,
                          fontWeight: FontWeight.w800,
                        ),
                      ),
                      const SizedBox(height: 6),
                      DropdownButtonFormField<int>(
                        initialValue: _selectedOwnerId,
                        isExpanded: true,
                        decoration: const InputDecoration(
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.zero,
                          ),
                          contentPadding: EdgeInsets.symmetric(
                            horizontal: 12,
                            vertical: 10,
                          ),
                        ),
                        items: _employees.map((e) {
                          final id = (e['id'] as num).toInt();
                          final name = e['full_name']?.toString() ?? '';
                          final des = e['designation']?.toString() ?? 'Staff';
                          return DropdownMenuItem<int>(
                            value: id,
                            child: Text(
                              '$name ($des)',
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              style: AppTheme.body(
                                fontSize: 13,
                                color: AppTheme.pitchBlack,
                              ),
                            ),
                          );
                        }).toList(),
                        onChanged: (val) {
                          setState(() {
                            _selectedOwnerId = val;
                          });
                        },
                      ),
                      const SizedBox(height: 16),

                      // 7. Contributors (Optional Multi-Select)
                      Text(
                        'CONTRIBUTORS (OPTIONAL)',
                        style: AppTheme.mono(
                          fontSize: 11,
                          fontWeight: FontWeight.w800,
                        ),
                      ),
                      const SizedBox(height: 6),
                      Wrap(
                        spacing: 6,
                        runSpacing: 6,
                        children: _employees
                            .where(
                              (e) =>
                                  (e['id'] as num).toInt() != _selectedOwnerId,
                            )
                            .map((e) {
                              final id = (e['id'] as num).toInt();
                              final name = e['full_name']?.toString() ?? '';
                              final isSelected = _selectedContributorIds
                                  .contains(id);

                              return GestureDetector(
                                onTap: () {
                                  setState(() {
                                    if (isSelected) {
                                      _selectedContributorIds.remove(id);
                                    } else {
                                      _selectedContributorIds.add(id);
                                    }
                                  });
                                },
                                child: Container(
                                  padding: const EdgeInsets.symmetric(
                                    horizontal: 8,
                                    vertical: 4,
                                  ),
                                  decoration: BoxDecoration(
                                    color: isSelected
                                        ? AppTheme.pitchBlack
                                        : const Color(0xFFF0F0F0),
                                    border: Border.all(
                                      color: AppTheme.pitchBlack,
                                      width: 1,
                                    ),
                                  ),
                                  child: Text(
                                    name,
                                    style: AppTheme.mono(
                                      fontSize: 10,
                                      color: isSelected
                                          ? AppTheme.pureWhite
                                          : AppTheme.pitchBlack,
                                    ),
                                  ),
                                ),
                              );
                            })
                            .toList(),
                      ),
                      const SizedBox(height: 24),

                      // 8. Submit Button
                      SizedBox(
                        width: double.infinity,
                        child: ElevatedButton(
                          onPressed: _isSubmitting ? null : _submitTask,
                          style: ElevatedButton.styleFrom(
                            backgroundColor: AppTheme.violentRed,
                            padding: const EdgeInsets.symmetric(vertical: 14),
                          ),
                          child: _isSubmitting
                              ? const SizedBox(
                                  width: 20,
                                  height: 20,
                                  child: CircularProgressIndicator(
                                    color: AppTheme.pureWhite,
                                    strokeWidth: 2,
                                  ),
                                )
                              : const Text(
                                  'CREATE & ASSIGN TASK',
                                  style: TextStyle(fontWeight: FontWeight.w900),
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

  Widget _buildPrioritySelector() {
    final priorities = ['low', 'medium', 'high', 'critical'];
    return Row(
      children: priorities.map((p) {
        final isSelected = _selectedPriority == p;
        return Expanded(
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 2),
            child: GestureDetector(
              onTap: () {
                setState(() {
                  _selectedPriority = p;
                });
              },
              child: Container(
                padding: const EdgeInsets.symmetric(vertical: 8),
                decoration: BoxDecoration(
                  color: isSelected
                      ? AppTheme.pitchBlack
                      : const Color(0xFFF0F0F0),
                  border: Border.all(
                    color: isSelected
                        ? AppTheme.pitchBlack
                        : const Color(0xFFCCCCCC),
                    width: 1.5,
                  ),
                ),
                child: Center(
                  child: Text(
                    p.toUpperCase(),
                    style: AppTheme.mono(
                      fontSize: 10,
                      fontWeight: FontWeight.w800,
                      color: isSelected
                          ? AppTheme.pureWhite
                          : AppTheme.pitchBlack,
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
                'FAILED TO LOAD FORM DATA',
                style: AppTheme.mono(
                  fontSize: 12,
                  fontWeight: FontWeight.w800,
                  color: AppTheme.violentRed,
                ),
              ),
              const SizedBox(height: 8),
              Text(
                _lookupError ?? 'Unknown error occurred.',
                style: AppTheme.body(color: AppTheme.pureWhite, fontSize: 13),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 14),
              ElevatedButton(
                onPressed: _loadLookups,
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
