import 'package:flutter/material.dart';
import '../../core/app_date_utils.dart';
import '../../core/theme.dart';
import '../../models/project_model.dart';
import '../../services/directory_service.dart';
import '../../services/project_service.dart';
import '../tasks/tasks_screen.dart';
import 'project_form_screen.dart';

class ProjectDetailScreen extends StatefulWidget {
  final int projectId;

  const ProjectDetailScreen({super.key, required this.projectId});

  @override
  State<ProjectDetailScreen> createState() => _ProjectDetailScreenState();
}

class _ProjectDetailScreenState extends State<ProjectDetailScreen> {
  final ProjectService _projectService = ProjectService();
  final DirectoryService _directoryService = DirectoryService();

  bool _isLoading = true;
  String? _errorMessage;
  ProjectDetailModel? _detail;

  @override
  void initState() {
    super.initState();
    _loadProjectDetail();
  }

  Future<void> _loadProjectDetail() async {
    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    try {
      final res = await _projectService.getProjectDetails(widget.projectId);
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

  // ---------------------------------------------------------------- Milestone Actions
  Future<void> _toggleMilestone(ProjectMilestoneModel m) async {
    if (_detail == null || !_detail!.project.canManage) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text(
            'Only project managers and admins can complete milestones.',
          ),
          backgroundColor: AppTheme.deepSlate,
        ),
      );
      return;
    }

    final oldStatus = m.status;
    final newStatus = oldStatus == 'completed' ? 'pending' : 'completed';

    // Optimistic UI Update
    setState(() {
      final index = _detail!.milestones.indexWhere((item) => item.id == m.id);
      if (index != -1) {
        _detail!.milestones[index] = m.copyWith(
          status: newStatus,
          completedAt: newStatus == 'completed'
              ? DateTime.now().toString().split(' ')[0]
              : null,
        );
      }
    });

    try {
      final res = await _projectService.toggleMilestone(m.id);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              res['message']?.toString() ??
                  (newStatus == 'completed'
                      ? 'Milestone completed!'
                      : 'Milestone reopened!'),
              style: AppTheme.body(
                color: AppTheme.pureWhite,
                fontWeight: FontWeight.w600,
              ),
            ),
            backgroundColor: newStatus == 'completed'
                ? AppTheme.navyBlue
                : AppTheme.deepSlate,
            duration: const Duration(seconds: 2),
          ),
        );
        _loadProjectDetail(); // sync fresh progress and activities
      }
    } catch (e) {
      // Rollback on error
      if (mounted) {
        setState(() {
          final index = _detail!.milestones.indexWhere(
            (item) => item.id == m.id,
          );
          if (index != -1) {
            _detail!.milestones[index] = m.copyWith(status: oldStatus);
          }
        });
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              'Failed to update milestone: ${e.toString().replaceAll('ApiException', '').trim()}',
            ),
            backgroundColor: AppTheme.dangerText,
          ),
        );
      }
    }
  }

  void _showMilestoneModal({ProjectMilestoneModel? existing}) {
    final titleCtrl = TextEditingController(text: existing?.title ?? '');
    final descCtrl = TextEditingController(text: existing?.description ?? '');
    final delivCtrl = TextEditingController(text: existing?.deliverables ?? '');
    DateTime? dueDate = existing?.dueDate != null
        ? DateTime.tryParse(existing!.dueDate!)
        : null;

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (ctx) => StatefulBuilder(
        builder: (context, setModalState) => Container(
          decoration: const BoxDecoration(
            color: AppTheme.pureWhite,
            borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
          ),
          padding: EdgeInsets.only(
            left: 20,
            right: 20,
            top: 20,
            bottom: MediaQuery.of(context).viewInsets.bottom + 20,
          ),
          child: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      existing != null ? 'Edit Milestone' : 'Add Milestone',
                      style: AppTheme.heading(
                        fontSize: 16,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                    IconButton(
                      icon: const Icon(Icons.close, size: 20),
                      onPressed: () => Navigator.pop(ctx),
                    ),
                  ],
                ),
                const SizedBox(height: 12),
                TextField(
                  controller: titleCtrl,
                  style: AppTheme.body(fontSize: 13, color: AppTheme.deepSlate),
                  decoration: const InputDecoration(
                    labelText: 'Milestone Title *',
                    hintText: 'e.g. Phase 1 Architecture Review',
                    border: OutlineInputBorder(),
                  ),
                ),
                const SizedBox(height: 12),
                TextField(
                  controller: delivCtrl,
                  style: AppTheme.body(fontSize: 13, color: AppTheme.deepSlate),
                  decoration: const InputDecoration(
                    labelText: 'Deliverables',
                    hintText: 'e.g. Design spec, prototype, schema dump',
                    border: OutlineInputBorder(),
                  ),
                ),
                const SizedBox(height: 12),
                InkWell(
                  onTap: () async {
                    final picked = await showDatePicker(
                      context: context,
                      initialDate: dueDate ?? DateTime.now(),
                      firstDate: DateTime(2020),
                      lastDate: DateTime(2035),
                    );
                    if (picked != null) {
                      setModalState(() => dueDate = picked);
                    }
                  },
                  child: Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 12,
                      vertical: 14,
                    ),
                    decoration: BoxDecoration(
                      border: Border.all(color: AppTheme.borderSubtle),
                      borderRadius: BorderRadius.circular(4),
                    ),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(
                          dueDate != null
                              ? 'Due: ${AppDateUtils.fmtDate('${dueDate!.year}-${dueDate!.month.toString().padLeft(2, '0')}-${dueDate!.day.toString().padLeft(2, '0')}')}'
                              : 'Select Due Date',
                          style: AppTheme.mono(
                            fontSize: 12,
                            color: dueDate != null
                                ? AppTheme.deepSlate
                                : AppTheme.mutedSlate,
                          ),
                        ),
                        const Icon(
                          Icons.calendar_today,
                          size: 16,
                          color: AppTheme.mutedSlate,
                        ),
                      ],
                    ),
                  ),
                ),
                const SizedBox(height: 12),
                TextField(
                  controller: descCtrl,
                  maxLines: 2,
                  style: AppTheme.body(fontSize: 13, color: AppTheme.deepSlate),
                  decoration: const InputDecoration(
                    labelText: 'Description (optional)',
                    border: OutlineInputBorder(),
                  ),
                ),
                const SizedBox(height: 20),
                SizedBox(
                  width: double.infinity,
                  height: 46,
                  child: ElevatedButton(
                    onPressed: () async {
                      if (titleCtrl.text.trim().isEmpty) return;
                      final messenger = ScaffoldMessenger.of(context);
                      Navigator.pop(ctx);
                      try {
                        final dateStr = dueDate != null
                            ? '${dueDate!.year}-${dueDate!.month.toString().padLeft(2, '0')}-${dueDate!.day.toString().padLeft(2, '0')}'
                            : null;
                        await _projectService.saveMilestone(
                          id: existing?.id,
                          projectId: widget.projectId,
                          title: titleCtrl.text.trim(),
                          description: descCtrl.text.trim().isEmpty
                              ? null
                              : descCtrl.text.trim(),
                          deliverables: delivCtrl.text.trim().isEmpty
                              ? null
                              : delivCtrl.text.trim(),
                          dueDate: dateStr,
                        );
                        _loadProjectDetail();
                      } catch (e) {
                        messenger.showSnackBar(
                          SnackBar(
                            content: Text('Failed to save milestone: $e'),
                            backgroundColor: AppTheme.dangerText,
                          ),
                        );
                      }
                    },
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppTheme.navyBlue,
                      foregroundColor: AppTheme.pureWhite,
                    ),
                    child: Text(
                      existing != null ? 'Update Milestone' : 'Save Milestone',
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

  void _confirmDeleteMilestone(ProjectMilestoneModel m) {
    if (m.taskCount > 0) {
      showDialog(
        context: context,
        builder: (_) => AlertDialog(
          title: const Text('Cannot Delete Milestone'),
          content: Text(
            'This milestone is linked to ${m.taskCount} task(s). Move or unlink those tasks before deleting it.',
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('OK'),
            ),
          ],
        ),
      );
      return;
    }

    showDialog(
      context: context,
      builder: (_) => AlertDialog(
        title: const Text('Delete Milestone?'),
        content: Text('Are you sure you want to delete "${m.title}"?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () async {
              Navigator.pop(context);
              try {
                await _projectService.deleteMilestone(m.id);
                _loadProjectDetail();
              } catch (e) {
                if (mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: Text('Delete failed: $e'),
                      backgroundColor: AppTheme.dangerText,
                    ),
                  );
                }
              }
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: AppTheme.dangerText,
            ),
            child: const Text('Delete'),
          ),
        ],
      ),
    );
  }

  // ---------------------------------------------------------------- Team Member Actions
  void _showAddMemberModal() async {
    List<Map<String, dynamic>> employees = [];
    try {
      employees = await _directoryService.getEmployees(limit: 100);
    } catch (_) {}

    // Exclude already added members
    final existingUserIds = _detail?.members.map((m) => m.userId).toSet() ?? {};
    final candidates = employees
        .where((e) => !existingUserIds.contains(e['id']))
        .toList();

    int? selectedUserId = candidates.isNotEmpty
        ? candidates.first['id'] as int?
        : null;
    String selectedRole = 'member';

    if (!mounted) return;

    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (ctx) => StatefulBuilder(
        builder: (context, setModalState) => Container(
          decoration: const BoxDecoration(
            color: AppTheme.pureWhite,
            borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
          ),
          padding: const EdgeInsets.all(20),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    'Add Team Member',
                    style: AppTheme.heading(
                      fontSize: 16,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                  IconButton(
                    icon: const Icon(Icons.close, size: 20),
                    onPressed: () => Navigator.pop(ctx),
                  ),
                ],
              ),
              const SizedBox(height: 12),
              if (candidates.isEmpty)
                const Padding(
                  padding: EdgeInsets.symmetric(vertical: 16),
                  child: Text(
                    'All available active employees are already in this project team.',
                  ),
                )
              else ...[
                DropdownButtonFormField<int>(
                  initialValue: selectedUserId,
                  items: candidates.map((c) {
                    return DropdownMenuItem<int>(
                      value: c['id'] as int?,
                      child: Text(c['full_name']?.toString() ?? ''),
                    );
                  }).toList(),
                  onChanged: (val) => setModalState(() => selectedUserId = val),
                  decoration: const InputDecoration(
                    labelText: 'Select Employee',
                    border: OutlineInputBorder(),
                  ),
                ),
                const SizedBox(height: 12),
                DropdownButtonFormField<String>(
                  initialValue: selectedRole,
                  items: const [
                    DropdownMenuItem(
                      value: 'member',
                      child: Text('Member (Can be assigned tasks)'),
                    ),
                    DropdownMenuItem(
                      value: 'viewer',
                      child: Text('Viewer (Read-only observation)'),
                    ),
                  ],
                  onChanged: (val) =>
                      setModalState(() => selectedRole = val ?? 'member'),
                  decoration: const InputDecoration(
                    labelText: 'Project Role',
                    border: OutlineInputBorder(),
                  ),
                ),
                const SizedBox(height: 20),
                SizedBox(
                  width: double.infinity,
                  height: 46,
                  child: ElevatedButton(
                    onPressed: () async {
                      if (selectedUserId == null) return;
                      final messenger = ScaffoldMessenger.of(context);
                      Navigator.pop(ctx);
                      try {
                        await _projectService.addProjectMember(
                          widget.projectId,
                          selectedUserId!,
                          selectedRole,
                        );
                        _loadProjectDetail();
                      } catch (e) {
                        messenger.showSnackBar(
                          SnackBar(
                            content: Text('Failed to add member: $e'),
                            backgroundColor: AppTheme.dangerText,
                          ),
                        );
                      }
                    },
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppTheme.navyBlue,
                      foregroundColor: AppTheme.pureWhite,
                    ),
                    child: const Text('Add Member'),
                  ),
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }

  void _confirmRemoveMember(ProjectMemberModel m) {
    if (m.userId == _detail?.project.managerId) {
      showDialog(
        context: context,
        builder: (_) => AlertDialog(
          title: const Text('Cannot Remove Manager'),
          content: const Text(
            'The project manager cannot be removed from the team. Change the manager first.',
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('OK'),
            ),
          ],
        ),
      );
      return;
    }

    if (m.openTasks > 0) {
      showDialog(
        context: context,
        builder: (_) => AlertDialog(
          title: const Text('Cannot Remove Member'),
          content: Text(
            '${m.fullName} has ${m.openTasks} open task(s) in this project. Reassign or close those tasks before removing them.',
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('OK'),
            ),
          ],
        ),
      );
      return;
    }

    showDialog(
      context: context,
      builder: (_) => AlertDialog(
        title: const Text('Remove Team Member?'),
        content: Text('Remove ${m.fullName} from this project?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () async {
              Navigator.pop(context);
              try {
                await _projectService.removeProjectMember(
                  widget.projectId,
                  m.userId,
                );
                _loadProjectDetail();
              } catch (e) {
                if (mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: Text('Removal failed: $e'),
                      backgroundColor: AppTheme.dangerText,
                    ),
                  );
                }
              }
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: AppTheme.dangerText,
            ),
            child: const Text('Remove'),
          ),
        ],
      ),
    );
  }

  // ---------------------------------------------------------------- Project Admin Actions
  void _showChangeStatusSheet() {
    final statuses = [
      'draft',
      'planned',
      'active',
      'on_hold',
      'completed',
      'cancelled',
    ];
    final currentStatus = _detail?.project.status ?? 'planned';

    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (ctx) => Container(
        decoration: const BoxDecoration(
          color: AppTheme.pureWhite,
          borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
        ),
        padding: const EdgeInsets.all(20),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  'Change Project Status',
                  style: AppTheme.heading(
                    fontSize: 16,
                    fontWeight: FontWeight.w700,
                  ),
                ),
                IconButton(
                  icon: const Icon(Icons.close, size: 20),
                  onPressed: () => Navigator.pop(ctx),
                ),
              ],
            ),
            const SizedBox(height: 12),
            ...statuses.map((st) {
              final isCurrent = st == currentStatus;
              return ListTile(
                title: Text(
                  st[0].toUpperCase() + st.substring(1).replaceAll('_', ' '),
                  style: AppTheme.body(
                    fontSize: 14,
                    fontWeight: isCurrent ? FontWeight.w700 : FontWeight.w500,
                    color: isCurrent ? AppTheme.navyBlue : AppTheme.deepSlate,
                  ),
                ),
                trailing: isCurrent
                    ? const Icon(Icons.check, color: AppTheme.navyBlue)
                    : null,
                onTap: () async {
                  Navigator.pop(ctx);
                  if (st == currentStatus) return;
                  try {
                    await _projectService.changeProjectStatus(
                      widget.projectId,
                      st,
                    );
                    _loadProjectDetail();
                  } catch (e) {
                    if (mounted) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(
                          content: Text('Status update failed: $e'),
                          backgroundColor: AppTheme.dangerText,
                        ),
                      );
                    }
                  }
                },
              );
            }),
          ],
        ),
      ),
    );
  }

  void _navigateToEditProject() async {
    final updated = await Navigator.push<bool>(
      context,
      MaterialPageRoute(
        builder: (_) =>
            ProjectFormScreen(project: _detail?.project, detail: _detail),
      ),
    );
    if (updated == true) {
      _loadProjectDetail();
    }
  }

  void _handleToggleArchive() {
    final p = _detail?.project;
    if (p == null) return;
    final isArchived = p.isArchived;

    showDialog(
      context: context,
      builder: (_) => AlertDialog(
        title: Text(isArchived ? 'Unarchive Project?' : 'Archive Project?'),
        content: Text(
          isArchived
              ? 'Restore "${p.name}" to the active projects directory?'
              : 'Archive "${p.name}"? It will be hidden from the active project list and marked as archived.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () async {
              Navigator.pop(context);
              try {
                final res = await _projectService.archiveProject(
                  p.id,
                  unarchive: isArchived,
                );
                if (mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: Text(
                        res['message']?.toString() ??
                            (isArchived
                                ? 'Project restored.'
                                : 'Project archived.'),
                      ),
                      backgroundColor: AppTheme.navyBlue,
                    ),
                  );
                  _loadProjectDetail();
                }
              } catch (e) {
                if (mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: Text('Action failed: $e'),
                      backgroundColor: AppTheme.dangerText,
                    ),
                  );
                }
              }
            },
            style: ElevatedButton.styleFrom(
              backgroundColor:
                  isArchived ? AppTheme.royalBlue : AppTheme.dangerText,
            ),
            child: Text(isArchived ? 'Unarchive' : 'Archive'),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final p = _detail?.project;
    final canManage = p?.canManage ?? false;

    return Scaffold(
      backgroundColor: AppTheme.scaffoldBg,
      appBar: AppBar(
        title: Text(
          p != null ? p.projectCode : 'Project Details',
          style: AppTheme.mono(fontSize: 16, fontWeight: FontWeight.w700),
        ),
        actions: [
          if (canManage)
            PopupMenuButton<String>(
              icon: const Icon(Icons.more_vert),
              tooltip: 'Project Options',
              onSelected: (val) {
                if (val == 'edit') _navigateToEditProject();
                if (val == 'status') _showChangeStatusSheet();
                if (val == 'archive') _handleToggleArchive();
                if (val == 'add_milestone') _showMilestoneModal();
                if (val == 'add_member') _showAddMemberModal();
              },
              itemBuilder: (_) => [
                const PopupMenuItem(
                  value: 'edit',
                  child: Row(
                    children: [
                      Icon(Icons.edit_outlined, size: 18),
                      SizedBox(width: 8),
                      Text('Edit Project'),
                    ],
                  ),
                ),
                const PopupMenuItem(
                  value: 'status',
                  child: Row(
                    children: [
                      Icon(Icons.swap_horiz, size: 18),
                      SizedBox(width: 8),
                      Text('Change Status'),
                    ],
                  ),
                ),
                PopupMenuItem(
                  value: 'archive',
                  child: Row(
                    children: [
                      Icon(
                        (p?.isArchived ?? false)
                            ? Icons.unarchive_outlined
                            : Icons.archive_outlined,
                        size: 18,
                        color: (p?.isArchived ?? false)
                            ? AppTheme.royalBlue
                            : AppTheme.dangerText,
                      ),
                      const SizedBox(width: 8),
                      Text(
                        (p?.isArchived ?? false)
                            ? 'Unarchive Project'
                            : 'Archive Project',
                        style: TextStyle(
                          color: (p?.isArchived ?? false)
                              ? AppTheme.royalBlue
                              : AppTheme.dangerText,
                        ),
                      ),
                    ],
                  ),
                ),
                const PopupMenuItem(
                  value: 'add_milestone',
                  child: Row(
                    children: [
                      Icon(Icons.flag_outlined, size: 18),
                      SizedBox(width: 8),
                      Text('Add Milestone'),
                    ],
                  ),
                ),
                const PopupMenuItem(
                  value: 'add_member',
                  child: Row(
                    children: [
                      Icon(Icons.person_add_outlined, size: 18),
                      SizedBox(width: 8),
                      Text('Add Team Member'),
                    ],
                  ),
                ),
              ],
            ),
          IconButton(
            icon: const Icon(Icons.refresh),
            tooltip: 'Refresh',
            onPressed: _loadProjectDetail,
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
    );
  }

  Widget _buildContent() {
    final detail = _detail!;
    final p = detail.project;

    return RefreshIndicator(
      onRefresh: _loadProjectDetail,
      color: AppTheme.royalBlue,
      child: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          // 0. Archived Banner (if applicable)
          if (p.isArchived) ...[
            Container(
              margin: const EdgeInsets.only(bottom: 16),
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
              decoration: BoxDecoration(
                color: const Color(0xFFFEF3C7),
                borderRadius: BorderRadius.circular(10),
                border: Border.all(color: const Color(0xFFF59E0B)),
              ),
              child: Row(
                children: [
                  const Icon(
                    Icons.archive_outlined,
                    color: Color(0xFFB45309),
                    size: 20,
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Archived Project',
                          style: AppTheme.mono(
                            fontSize: 12,
                            fontWeight: FontWeight.w700,
                            color: const Color(0xFFB45309),
                          ),
                        ),
                        Text(
                          'This project was archived on ${AppDateUtils.fmtDateTime(p.archivedAt)}. It is read-only in listings and dashboards.',
                          style: AppTheme.body(
                            fontSize: 12,
                            color: const Color(0xFF78350F),
                          ),
                        ),
                      ],
                    ),
                  ),
                  if (p.canManage)
                    TextButton(
                      onPressed: _handleToggleArchive,
                      child: const Text(
                        'Unarchive',
                        style: TextStyle(
                          color: Color(0xFFB45309),
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                    ),
                ],
              ),
            ),
          ],

          // 1. Header Summary Card
          _buildOverviewCard(p, detail),
          const SizedBox(height: 16),

          // 2. Task Breakdown Metrics
          _buildTaskCountsCard(detail.taskCounts),
          const SizedBox(height: 16),

          // 3. Button: View All Project Tasks
          SizedBox(
            height: 48,
            child: ElevatedButton.icon(
              onPressed: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (_) =>
                        TasksScreen(projectId: p.id, projectName: p.name),
                  ),
                );
              },
              icon: const Icon(Icons.task_alt, size: 18),
              label: Text(
                'View All Project Tasks (${detail.taskCounts.total})',
              ),
              style: ElevatedButton.styleFrom(
                backgroundColor: AppTheme.navyBlue,
                foregroundColor: AppTheme.pureWhite,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(10),
                ),
              ),
            ),
          ),
          const SizedBox(height: 24),

          // 4. Milestones Section (Interactive Stepper)
          _buildMilestonesSection(detail.milestones, p.canManage),
          const SizedBox(height: 24),

          // 5. Team Members Strip
          _buildTeamSection(detail.members, p.canManage),
          const SizedBox(height: 24),

          // 6. Scope & Deliverables
          if ((detail.scopeOfWork != null && detail.scopeOfWork!.isNotEmpty) ||
              (detail.deliverables != null &&
                  detail.deliverables!.isNotEmpty)) ...[
            _buildScopeSection(detail),
            const SizedBox(height: 24),
          ],

          // 7. Recent Activity Section
          if (detail.recentActivity.isNotEmpty) ...[
            _buildActivitySection(detail.recentActivity),
            const SizedBox(height: 24),
          ],
        ],
      ),
    );
  }

  Widget _buildOverviewCard(ProjectModel p, ProjectDetailModel detail) {
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
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                decoration: BoxDecoration(
                  color: AppTheme.scaffoldBg,
                  borderRadius: BorderRadius.circular(6),
                  border: Border.all(color: AppTheme.borderSubtle),
                ),
                child: Text(
                  p.projectCode,
                  style: AppTheme.mono(
                    fontSize: 12,
                    fontWeight: FontWeight.w700,
                    color: AppTheme.deepSlate,
                  ),
                ),
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                decoration: BoxDecoration(
                  color: p.isActive
                      ? AppTheme.infoBg
                      : p.isCompleted
                      ? AppTheme.successBg
                      : AppTheme.warningBg,
                  borderRadius: BorderRadius.circular(6),
                ),
                child: Text(
                  p.status.isEmpty
                      ? 'Active'
                      : p.status[0].toUpperCase() +
                            p.status.substring(1).toLowerCase(),
                  style: AppTheme.heading(
                    fontSize: 11,
                    fontWeight: FontWeight.w600,
                    color: p.isActive
                        ? AppTheme.infoText
                        : p.isCompleted
                        ? AppTheme.successText
                        : AppTheme.warningText,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Text(
            p.name,
            style: AppTheme.heading(fontSize: 18, color: AppTheme.deepSlate),
          ),
          if (p.clientName != null && p.clientName!.isNotEmpty) ...[
            const SizedBox(height: 4),
            Text(
              'Client: ${p.clientName}',
              style: AppTheme.body(fontSize: 13, color: AppTheme.mutedSlate),
            ),
          ],
          const SizedBox(height: 16),
          // Progress Bar
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'Project Completion',
                style: AppTheme.heading(
                  fontSize: 12,
                  fontWeight: FontWeight.w600,
                  color: AppTheme.mutedSlate,
                ),
              ),
              Text(
                '${p.completionPercent.toStringAsFixed(1)}%',
                style: AppTheme.mono(
                  fontSize: 12,
                  fontWeight: FontWeight.w700,
                  color: AppTheme.deepSlate,
                ),
              ),
            ],
          ),
          const SizedBox(height: 6),
          ClipRRect(
            borderRadius: BorderRadius.circular(4),
            child: LinearProgressIndicator(
              value: (p.completionPercent / 100).clamp(0.0, 1.0),
              minHeight: 8,
              backgroundColor: const Color(0xFFE2E8F0),
              valueColor: const AlwaysStoppedAnimation<Color>(
                AppTheme.royalBlue,
              ),
            ),
          ),
          const SizedBox(height: 16),
          const Divider(color: AppTheme.borderSubtle, thickness: 1.0),
          const SizedBox(height: 12),
          // Dates & Manager
          Row(
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Start Date',
                      style: AppTheme.body(
                        fontSize: 11,
                        color: AppTheme.mutedSlate,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      AppDateUtils.fmtDate(p.startDate),
                      style: AppTheme.mono(
                        fontSize: 12,
                        fontWeight: FontWeight.w600,
                        color: AppTheme.deepSlate,
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
                      'Deadline',
                      style: AppTheme.body(
                        fontSize: 11,
                        color: AppTheme.mutedSlate,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      p.deadline != null
                          ? '${AppDateUtils.fmtDate(p.deadline)}${p.deadlineDaysLabel != null ? ' (${p.deadlineDaysLabel})' : ''}'
                          : 'None',
                      style: AppTheme.mono(
                        fontSize: 12,
                        fontWeight: FontWeight.w600,
                        color: p.isOverdue
                            ? AppTheme.dangerText
                            : AppTheme.deepSlate,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Department',
                      style: AppTheme.body(
                        fontSize: 11,
                        color: AppTheme.mutedSlate,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      p.departmentName ?? 'General',
                      style: AppTheme.body(
                        fontSize: 12,
                        fontWeight: FontWeight.w500,
                        color: AppTheme.deepSlate,
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
                      'Manager',
                      style: AppTheme.body(
                        fontSize: 11,
                        color: AppTheme.mutedSlate,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      p.managerName ?? 'Unassigned',
                      style: AppTheme.body(
                        fontSize: 12,
                        fontWeight: FontWeight.w500,
                        color: AppTheme.deepSlate,
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

  Widget _buildTaskCountsCard(ProjectTaskCountsModel counts) {
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
          Text(
            'Tasks Breakdown',
            style: AppTheme.heading(fontSize: 13, fontWeight: FontWeight.w700),
          ),
          const SizedBox(height: 12),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceAround,
            children: [
              _buildMetricPill(
                'Total',
                counts.total.toString(),
                AppTheme.deepSlate,
              ),
              _buildMetricPill(
                'Active',
                counts.inProgress.toString(),
                AppTheme.royalBlue,
              ),
              _buildMetricPill(
                'Blocked',
                counts.blocked.toString(),
                AppTheme.dangerText,
              ),
              _buildMetricPill(
                'Done',
                counts.completed.toString(),
                AppTheme.successText,
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildMetricPill(String label, String value, Color color) {
    return Column(
      children: [
        Text(
          value,
          style: AppTheme.heading(
            fontSize: 22,
            fontWeight: FontWeight.w700,
            color: color,
          ),
        ),
        const SizedBox(height: 3),
        Text(
          label,
          style: AppTheme.body(
            fontSize: 11,
            color: AppTheme.mutedSlate,
            fontWeight: FontWeight.w500,
          ),
        ),
      ],
    );
  }

  Widget _buildMilestonesSection(
    List<ProjectMilestoneModel> milestones,
    bool canManage,
  ) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Row(
              children: [
                Text(
                  'Milestones',
                  style: AppTheme.heading(
                    fontSize: 15,
                    fontWeight: FontWeight.w700,
                  ),
                ),
                const SizedBox(width: 8),
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 8,
                    vertical: 2,
                  ),
                  decoration: BoxDecoration(
                    color: AppTheme.scaffoldBg,
                    borderRadius: BorderRadius.circular(6),
                    border: Border.all(color: AppTheme.borderSubtle),
                  ),
                  child: Text(
                    '${milestones.length}',
                    style: AppTheme.mono(
                      fontSize: 11,
                      fontWeight: FontWeight.w700,
                      color: AppTheme.deepSlate,
                    ),
                  ),
                ),
              ],
            ),
            if (canManage)
              TextButton.icon(
                onPressed: () => _showMilestoneModal(),
                icon: const Icon(
                  Icons.add,
                  size: 16,
                  color: AppTheme.royalBlue,
                ),
                label: Text(
                  '+ Add Milestone',
                  style: AppTheme.heading(
                    fontSize: 12,
                    color: AppTheme.royalBlue,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
          ],
        ),
        const SizedBox(height: 12),
        if (milestones.isEmpty)
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: AppTheme.pureWhite,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: AppTheme.borderSubtle),
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Expanded(
                  child: Text(
                    'No milestones defined for this project.',
                    style: AppTheme.body(
                      color: AppTheme.mutedSlate,
                      fontSize: 13,
                    ),
                  ),
                ),
                if (canManage)
                  ElevatedButton(
                    onPressed: () => _showMilestoneModal(),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppTheme.navyBlue,
                      foregroundColor: AppTheme.pureWhite,
                      padding: const EdgeInsets.symmetric(
                        horizontal: 12,
                        vertical: 8,
                      ),
                    ),
                    child: const Text('Add One'),
                  ),
              ],
            ),
          )
        else
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: AppTheme.pureWhite,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: AppTheme.borderSubtle, width: 1.0),
              boxShadow: const [AppTheme.softShadow],
            ),
            child: Column(
              children: List.generate(milestones.length, (idx) {
                final m = milestones[idx];
                final isDone = m.isCompleted;
                final isLast = idx == milestones.length - 1;

                return IntrinsicHeight(
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Column(
                        children: [
                          InkWell(
                            onTap: () => _toggleMilestone(m),
                            borderRadius: BorderRadius.circular(6),
                            child: Container(
                              width: 26,
                              height: 26,
                              decoration: BoxDecoration(
                                color: isDone
                                    ? AppTheme.successBg
                                    : AppTheme.scaffoldBg,
                                borderRadius: BorderRadius.circular(6),
                                border: Border.all(
                                  color: isDone
                                      ? AppTheme.successText
                                      : AppTheme.borderSubtle,
                                  width: 1.5,
                                ),
                              ),
                              child: Center(
                                child: isDone
                                    ? const Icon(
                                        Icons.check,
                                        size: 16,
                                        color: AppTheme.successText,
                                      )
                                    : null,
                              ),
                            ),
                          ),
                          if (!isLast)
                            Expanded(
                              child: Container(
                                width: 1.5,
                                color: AppTheme.borderSubtle,
                              ),
                            ),
                        ],
                      ),
                      const SizedBox(width: 14),
                      Expanded(
                        child: Padding(
                          padding: EdgeInsets.only(bottom: isLast ? 0 : 20.0),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Row(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Expanded(
                                    child: Column(
                                      crossAxisAlignment:
                                          CrossAxisAlignment.start,
                                      children: [
                                        Text(
                                          m.title,
                                          style:
                                              AppTheme.heading(
                                                fontSize: 14,
                                                fontWeight: FontWeight.w600,
                                                color: isDone
                                                    ? AppTheme.mutedSlate
                                                    : AppTheme.deepSlate,
                                              ).copyWith(
                                                decoration: isDone
                                                    ? TextDecoration.lineThrough
                                                    : null,
                                              ),
                                        ),
                                        if (m.description != null &&
                                            m.description!.isNotEmpty) ...[
                                          const SizedBox(height: 2),
                                          Text(
                                            m.description!,
                                            style: AppTheme.body(
                                              fontSize: 12,
                                              color: AppTheme.mutedSlate,
                                            ),
                                          ),
                                        ],
                                      ],
                                    ),
                                  ),
                                  Row(
                                    children: [
                                      Container(
                                        padding: const EdgeInsets.symmetric(
                                          horizontal: 7,
                                          vertical: 2,
                                        ),
                                        decoration: BoxDecoration(
                                          color: isDone
                                              ? AppTheme.successBg
                                              : const Color(0xFFF1F5F9),
                                          borderRadius: BorderRadius.circular(
                                            4,
                                          ),
                                        ),
                                        child: Text(
                                          m.status.isEmpty
                                              ? 'Pending'
                                              : m.status[0].toUpperCase() +
                                                    m.status
                                                        .substring(1)
                                                        .toLowerCase(),
                                          style: AppTheme.heading(
                                            fontSize: 10,
                                            fontWeight: FontWeight.w600,
                                            color: isDone
                                                ? AppTheme.successText
                                                : AppTheme.mutedSlate,
                                          ),
                                        ),
                                      ),
                                      if (canManage) ...[
                                        const SizedBox(width: 4),
                                        PopupMenuButton<String>(
                                          padding: EdgeInsets.zero,
                                          iconSize: 18,
                                          icon: const Icon(
                                            Icons.more_vert,
                                            size: 18,
                                            color: AppTheme.mutedSlate,
                                          ),
                                          onSelected: (val) {
                                            if (val == 'edit') {
                                              _showMilestoneModal(existing: m);
                                            }
                                            if (val == 'delete') {
                                              _confirmDeleteMilestone(m);
                                            }
                                          },
                                          itemBuilder: (_) => [
                                            const PopupMenuItem(
                                              value: 'edit',
                                              child: Text('Edit Milestone'),
                                            ),
                                            const PopupMenuItem(
                                              value: 'delete',
                                              child: Text(
                                                'Delete Milestone',
                                                style: TextStyle(
                                                  color: AppTheme.dangerText,
                                                ),
                                              ),
                                            ),
                                          ],
                                        ),
                                      ],
                                    ],
                                  ),
                                ],
                              ),
                              const SizedBox(height: 6),
                              Row(
                                children: [
                                  if (m.dueDate != null) ...[
                                    Text(
                                      'Due: ${AppDateUtils.fmtDate(m.dueDate)}',
                                      style: AppTheme.mono(
                                        fontSize: 11,
                                        color: m.isOverdue
                                            ? AppTheme.dangerText
                                            : AppTheme.mutedSlate,
                                        fontWeight: m.isOverdue
                                            ? FontWeight.w700
                                            : FontWeight.w500,
                                      ),
                                    ),
                                    if (m.isOverdue) ...[
                                      const SizedBox(width: 6),
                                      Container(
                                        padding: const EdgeInsets.symmetric(
                                          horizontal: 5,
                                          vertical: 1,
                                        ),
                                        decoration: BoxDecoration(
                                          color: AppTheme.dangerBg,
                                          borderRadius: BorderRadius.circular(
                                            3,
                                          ),
                                        ),
                                        child: Text(
                                          'OVERDUE',
                                          style: AppTheme.mono(
                                            fontSize: 9,
                                            fontWeight: FontWeight.w700,
                                            color: AppTheme.dangerText,
                                          ),
                                        ),
                                      ),
                                    ],
                                  ],
                                  if (m.taskCount > 0) ...[
                                    const SizedBox(width: 8),
                                    Text(
                                      '·',
                                      style: TextStyle(
                                        color: AppTheme.mutedSlate,
                                      ),
                                    ),
                                    const SizedBox(width: 8),
                                    Text(
                                      '${m.taskCount} task${m.taskCount == 1 ? '' : 's'}',
                                      style: AppTheme.body(
                                        fontSize: 11,
                                        color: AppTheme.mutedSlate,
                                      ),
                                    ),
                                  ],
                                ],
                              ),
                              if (m.deliverables != null &&
                                  m.deliverables!.isNotEmpty) ...[
                                const SizedBox(height: 6),
                                Container(
                                  padding: const EdgeInsets.symmetric(
                                    horizontal: 10,
                                    vertical: 6,
                                  ),
                                  decoration: BoxDecoration(
                                    color: AppTheme.scaffoldBg,
                                    borderRadius: BorderRadius.circular(6),
                                    border: Border.all(
                                      color: AppTheme.borderSubtle,
                                    ),
                                  ),
                                  child: Text(
                                    'Deliverables: ${m.deliverables}',
                                    style: AppTheme.body(
                                      fontSize: 12,
                                      color: AppTheme.deepSlate,
                                    ),
                                  ),
                                ),
                              ],
                            ],
                          ),
                        ),
                      ),
                    ],
                  ),
                );
              }),
            ),
          ),
      ],
    );
  }

  Widget _buildTeamSection(List<ProjectMemberModel> members, bool canManage) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Row(
              children: [
                Text(
                  'Team Members',
                  style: AppTheme.heading(
                    fontSize: 15,
                    fontWeight: FontWeight.w700,
                  ),
                ),
                const SizedBox(width: 8),
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 8,
                    vertical: 2,
                  ),
                  decoration: BoxDecoration(
                    color: AppTheme.scaffoldBg,
                    borderRadius: BorderRadius.circular(6),
                    border: Border.all(color: AppTheme.borderSubtle),
                  ),
                  child: Text(
                    '${members.length}',
                    style: AppTheme.mono(
                      fontSize: 11,
                      fontWeight: FontWeight.w700,
                      color: AppTheme.deepSlate,
                    ),
                  ),
                ),
              ],
            ),
            if (canManage)
              TextButton.icon(
                onPressed: _showAddMemberModal,
                icon: const Icon(
                  Icons.person_add_alt,
                  size: 16,
                  color: AppTheme.royalBlue,
                ),
                label: Text(
                  '+ Add Member',
                  style: AppTheme.heading(
                    fontSize: 12,
                    color: AppTheme.royalBlue,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
          ],
        ),
        const SizedBox(height: 12),
        if (members.isEmpty)
          Text(
            'No team members assigned.',
            style: AppTheme.body(color: AppTheme.mutedSlate, fontSize: 13),
          )
        else
          SizedBox(
            height: 110,
            child: ListView.separated(
              scrollDirection: Axis.horizontal,
              itemCount: members.length,
              separatorBuilder: (_, _) => const SizedBox(width: 10),
              itemBuilder: (ctx, idx) {
                final mem = members[idx];
                final isViewer = mem.memberRole.toLowerCase().contains(
                  'viewer',
                );

                return InkWell(
                  onTap: canManage ? () => _confirmRemoveMember(mem) : null,
                  borderRadius: BorderRadius.circular(12),
                  child: Container(
                    width: 150,
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: AppTheme.pureWhite,
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(
                        color: AppTheme.borderSubtle,
                        width: 1.0,
                      ),
                      boxShadow: const [AppTheme.softShadow],
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Expanded(
                              child: Text(
                                mem.fullName,
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                                style: AppTheme.heading(
                                  fontSize: 13,
                                  fontWeight: FontWeight.w600,
                                  color: AppTheme.deepSlate,
                                ),
                              ),
                            ),
                            if (canManage)
                              const Icon(
                                Icons.close,
                                size: 14,
                                color: AppTheme.mutedSlate,
                              ),
                          ],
                        ),
                        const SizedBox(height: 4),
                        Row(
                          children: [
                            Container(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 6,
                                vertical: 1.5,
                              ),
                              decoration: BoxDecoration(
                                color: isViewer
                                    ? const Color(0xFFF1F5F9)
                                    : AppTheme.infoBg,
                                borderRadius: BorderRadius.circular(4),
                              ),
                              child: Text(
                                isViewer ? 'Viewer' : 'Member',
                                style: AppTheme.heading(
                                  fontSize: 9,
                                  fontWeight: FontWeight.w600,
                                  color: isViewer
                                      ? AppTheme.mutedSlate
                                      : AppTheme.infoText,
                                ),
                              ),
                            ),
                            if (mem.openTasks > 0) ...[
                              const SizedBox(width: 6),
                              Container(
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 5,
                                  vertical: 1.5,
                                ),
                                decoration: BoxDecoration(
                                  color: const Color(0xFFFEF3C7),
                                  borderRadius: BorderRadius.circular(4),
                                ),
                                child: Text(
                                  '${mem.openTasks} open',
                                  style: AppTheme.mono(
                                    fontSize: 8.5,
                                    fontWeight: FontWeight.w700,
                                    color: const Color(0xFFB45309),
                                  ),
                                ),
                              ),
                            ],
                          ],
                        ),
                        const SizedBox(height: 4),
                        Text(
                          mem.designation ?? 'Team Member',
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: AppTheme.body(
                            fontSize: 11,
                            color: AppTheme.mutedSlate,
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

  Widget _buildScopeSection(ProjectDetailModel detail) {
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
          Text(
            'Scope & Deliverables',
            style: AppTheme.heading(
              fontSize: 13,
              fontWeight: FontWeight.w700,
              color: AppTheme.deepSlate,
            ),
          ),
          if (detail.scopeOfWork != null && detail.scopeOfWork!.isNotEmpty) ...[
            const SizedBox(height: 8),
            Text(
              detail.scopeOfWork!,
              style: AppTheme.body(fontSize: 13, color: AppTheme.deepSlate),
            ),
          ],
          if (detail.deliverables != null &&
              detail.deliverables!.isNotEmpty) ...[
            const SizedBox(height: 12),
            Text(
              'Deliverables',
              style: AppTheme.heading(
                fontSize: 12,
                color: AppTheme.royalBlue,
                fontWeight: FontWeight.w600,
              ),
            ),
            const SizedBox(height: 4),
            Text(
              detail.deliverables!,
              style: AppTheme.body(fontSize: 13, color: AppTheme.deepSlate),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildActivitySection(List<ProjectActivityModel> activities) {
    return Container(
      decoration: BoxDecoration(
        color: AppTheme.pureWhite,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppTheme.borderSubtle),
      ),
      child: Theme(
        data: Theme.of(context).copyWith(
          dividerColor: Colors.transparent,
          splashColor: Colors.transparent,
          highlightColor: Colors.transparent,
        ),
        child: ExpansionTile(
          initiallyExpanded: false,
          tilePadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 4),
          leading: Container(
            padding: const EdgeInsets.all(7),
            decoration: BoxDecoration(
              color: AppTheme.infoBg,
              borderRadius: BorderRadius.circular(8),
            ),
            child: const Icon(
              Icons.history_rounded,
              color: AppTheme.royalBlue,
              size: 18,
            ),
          ),
          title: Row(
            children: [
              Text(
                'Recent Activity',
                style: AppTheme.heading(
                  fontSize: 14,
                  fontWeight: FontWeight.w700,
                  color: AppTheme.deepSlate,
                ),
              ),
              const SizedBox(width: 8),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 2),
                decoration: BoxDecoration(
                  color: const Color(0xFFF1F5F9),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Text(
                  '${activities.length}',
                  style: AppTheme.mono(
                    fontSize: 11,
                    fontWeight: FontWeight.w700,
                    color: AppTheme.mutedSlate,
                  ),
                ),
              ),
            ],
          ),
          subtitle: Text(
            'Tap to view audit trail & changes',
            style: AppTheme.body(fontSize: 11, color: AppTheme.mutedSlate),
          ),
          iconColor: AppTheme.deepSlate,
          collapsedIconColor: AppTheme.mutedSlate,
          childrenPadding: const EdgeInsets.fromLTRB(14, 0, 14, 12),
          children: [
            const Divider(height: 1, color: AppTheme.borderSubtle),
            const SizedBox(height: 12),
            ...activities.take(10).map((act) {
              return Container(
                margin: const EdgeInsets.only(bottom: 8),
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: const Color(0xFFF8FAFC),
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: AppTheme.borderSubtle),
                ),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Icon(
                      Icons.bolt_rounded,
                      color: AppTheme.royalBlue,
                      size: 16,
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            act.description,
                            style: AppTheme.body(
                              fontSize: 12,
                              color: AppTheme.deepSlate,
                            ),
                          ),
                          const SizedBox(height: 2),
                          Text(
                            '${AppDateUtils.fmtDateTime(act.createdAt)} (${AppDateUtils.timeAgo(act.createdAt)})',
                            style: AppTheme.mono(
                              fontSize: 10,
                              color: AppTheme.mutedSlate,
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
                'Failed to load project',
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
                onPressed: _loadProjectDetail,
                child: const Text('Retry'),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
