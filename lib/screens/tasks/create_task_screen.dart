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
        const SnackBar(content: Text('Task assigned successfully.')),
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
    return Scaffold(
      backgroundColor: AppTheme.scaffoldBg,
      appBar: AppBar(
        title: Text('Assign New Task', style: AppTheme.heading(fontSize: 18)),
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
                      // 1. Project Selector
                      Text(
                        'Project *',
                        style: AppTheme.heading(
                          fontSize: 13,
                          fontWeight: FontWeight.w600,
                          color: AppTheme.deepSlate,
                        ),
                      ),
                      const SizedBox(height: 8),
                      DropdownButtonFormField<int>(
                        initialValue: _selectedProjectId,
                        isExpanded: true,
                        decoration: const InputDecoration(
                          contentPadding: EdgeInsets.symmetric(
                            horizontal: 14,
                            vertical: 12,
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
                                color: AppTheme.deepSlate,
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
                      const SizedBox(height: 16),

                      // 2. Task Title
                      Text(
                        'Task Title *',
                        style: AppTheme.heading(
                          fontSize: 13,
                          fontWeight: FontWeight.w600,
                          color: AppTheme.deepSlate,
                        ),
                      ),
                      const SizedBox(height: 8),
                      TextFormField(
                        controller: _titleController,
                        style: AppTheme.body(color: AppTheme.deepSlate),
                        decoration: const InputDecoration(
                          hintText:
                              'e.g. Implement checkout flow backend integration',
                        ),
                        validator: (v) {
                          if (v == null || v.trim().isEmpty) {
                            return 'Please enter a title.';
                          }
                          return null;
                        },
                      ),
                      const SizedBox(height: 16),

                      // 3. Description
                      Text(
                        'Description & Instructions',
                        style: AppTheme.heading(
                          fontSize: 13,
                          fontWeight: FontWeight.w600,
                          color: AppTheme.deepSlate,
                        ),
                      ),
                      const SizedBox(height: 8),
                      TextFormField(
                        controller: _descriptionController,
                        maxLines: 3,
                        style: AppTheme.body(color: AppTheme.deepSlate),
                        decoration: const InputDecoration(
                          hintText:
                              'Provide task context, requirements, deliverables...',
                        ),
                      ),
                      const SizedBox(height: 16),

                      // 4. Priority Selector
                      Text(
                        'Priority Level',
                        style: AppTheme.heading(
                          fontSize: 13,
                          fontWeight: FontWeight.w600,
                          color: AppTheme.deepSlate,
                        ),
                      ),
                      const SizedBox(height: 8),
                      _buildPrioritySelector(),
                      const SizedBox(height: 16),

                      // 5. Deadline & Estimated Hours
                      Row(
                        children: [
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  'Deadline',
                                  style: AppTheme.heading(
                                    fontSize: 13,
                                    fontWeight: FontWeight.w600,
                                    color: AppTheme.deepSlate,
                                  ),
                                ),
                                const SizedBox(height: 8),
                                InkWell(
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
                                  borderRadius: BorderRadius.circular(10),
                                  child: Container(
                                    padding: const EdgeInsets.symmetric(
                                      horizontal: 14,
                                      vertical: 14,
                                    ),
                                    decoration: BoxDecoration(
                                      color: AppTheme.scaffoldBg,
                                      borderRadius: BorderRadius.circular(10),
                                      border: Border.all(
                                        color: AppTheme.borderSubtle,
                                        width: 1.0,
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
                                          Icons.calendar_today_outlined,
                                          size: 16,
                                          color: AppTheme.mutedSlate,
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
                                  'Est. Hours',
                                  style: AppTheme.heading(
                                    fontSize: 13,
                                    fontWeight: FontWeight.w600,
                                    color: AppTheme.deepSlate,
                                  ),
                                ),
                                const SizedBox(height: 8),
                                TextFormField(
                                  controller: _estimatedHoursController,
                                  keyboardType:
                                      const TextInputType.numberWithOptions(
                                        decimal: true,
                                      ),
                                  style: AppTheme.mono(fontSize: 13),
                                  decoration: const InputDecoration(
                                    hintText: 'e.g. 8.5',
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
                        'Primary Owner *',
                        style: AppTheme.heading(
                          fontSize: 13,
                          fontWeight: FontWeight.w600,
                          color: AppTheme.deepSlate,
                        ),
                      ),
                      const SizedBox(height: 8),
                      DropdownButtonFormField<int>(
                        initialValue: _selectedOwnerId,
                        isExpanded: true,
                        decoration: const InputDecoration(
                          contentPadding: EdgeInsets.symmetric(
                            horizontal: 14,
                            vertical: 12,
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
                                color: AppTheme.deepSlate,
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

                      // 7. Contributors
                      Text(
                        'Contributors (Optional)',
                        style: AppTheme.heading(
                          fontSize: 13,
                          fontWeight: FontWeight.w600,
                          color: AppTheme.deepSlate,
                        ),
                      ),
                      const SizedBox(height: 8),
                      Wrap(
                        spacing: 8,
                        runSpacing: 8,
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

                              return InkWell(
                                onTap: () {
                                  setState(() {
                                    if (isSelected) {
                                      _selectedContributorIds.remove(id);
                                    } else {
                                      _selectedContributorIds.add(id);
                                    }
                                  });
                                },
                                borderRadius: BorderRadius.circular(6),
                                child: Container(
                                  padding: const EdgeInsets.symmetric(
                                    horizontal: 10,
                                    vertical: 6,
                                  ),
                                  decoration: BoxDecoration(
                                    color: isSelected
                                        ? AppTheme.navyBlue
                                        : const Color(0xFFF1F5F9),
                                    borderRadius: BorderRadius.circular(6),
                                    border: Border.all(
                                      color: isSelected
                                          ? AppTheme.navyBlue
                                          : AppTheme.borderSubtle,
                                    ),
                                  ),
                                  child: Text(
                                    name,
                                    style: AppTheme.body(
                                      fontSize: 11,
                                      fontWeight: FontWeight.w500,
                                      color: isSelected
                                          ? AppTheme.pureWhite
                                          : AppTheme.deepSlate,
                                    ),
                                  ),
                                ),
                              );
                            })
                            .toList(),
                      ),
                      const SizedBox(height: 28),

                      // 8. Submit Button
                      SizedBox(
                        width: double.infinity,
                        height: 52,
                        child: ElevatedButton(
                          onPressed: _isSubmitting ? null : _submitTask,
                          style: ElevatedButton.styleFrom(
                            backgroundColor: AppTheme.navyBlue,
                            foregroundColor: AppTheme.pureWhite,
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(10),
                            ),
                          ),
                          child: _isSubmitting
                              ? const SizedBox(
                                  width: 22,
                                  height: 22,
                                  child: CircularProgressIndicator(
                                    color: AppTheme.pureWhite,
                                    strokeWidth: 2.5,
                                  ),
                                )
                              : Text(
                                  'Create & Assign Task',
                                  style: AppTheme.heading(
                                    fontSize: 15,
                                    fontWeight: FontWeight.w600,
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

  Widget _buildPrioritySelector() {
    final priorities = ['low', 'medium', 'high', 'critical'];
    return Row(
      children: priorities.map((p) {
        final isSelected = _selectedPriority == p;
        Color selectedBg = AppTheme.navyBlue;
        Color selectedFg = AppTheme.pureWhite;

        if (p == 'critical') {
          selectedBg = AppTheme.dangerBg;
          selectedFg = AppTheme.dangerText;
        } else if (p == 'high') {
          selectedBg = AppTheme.warningBg;
          selectedFg = AppTheme.warningText;
        } else if (p == 'medium') {
          selectedBg = AppTheme.infoBg;
          selectedFg = AppTheme.infoText;
        }

        final label = p[0].toUpperCase() + p.substring(1);

        return Expanded(
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 3),
            child: InkWell(
              onTap: () {
                setState(() {
                  _selectedPriority = p;
                });
              },
              borderRadius: BorderRadius.circular(8),
              child: Container(
                padding: const EdgeInsets.symmetric(vertical: 10),
                decoration: BoxDecoration(
                  color: isSelected ? selectedBg : const Color(0xFFF1F5F9),
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(
                    color: isSelected
                        ? (p == 'critical'
                              ? const Color(0xFFFECACA)
                              : p == 'high'
                              ? const Color(0xFFFDE68A)
                              : p == 'medium'
                              ? const Color(0xFFBFDBFE)
                              : AppTheme.navyBlue)
                        : AppTheme.borderSubtle,
                  ),
                ),
                child: Center(
                  child: Text(
                    label,
                    style: AppTheme.heading(
                      fontSize: 11,
                      fontWeight: FontWeight.w600,
                      color: isSelected ? selectedFg : AppTheme.mutedSlate,
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
                'Failed to load form data',
                style: AppTheme.heading(
                  fontSize: 13,
                  fontWeight: FontWeight.w600,
                  color: AppTheme.dangerText,
                ),
              ),
              const SizedBox(height: 8),
              Text(
                _lookupError ?? 'Unknown error occurred.',
                style: AppTheme.body(color: AppTheme.deepSlate, fontSize: 13),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 14),
              ElevatedButton(
                onPressed: _loadLookups,
                child: const Text('Retry'),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
