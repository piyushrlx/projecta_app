import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../../core/app_date_utils.dart';
import '../../core/theme.dart';
import '../../core/widgets/module_app_bar.dart';
import '../../core/widgets/offline_cache_banner.dart';
import '../../models/project_model.dart';
import '../../services/directory_service.dart';
import '../../services/project_service.dart';
import '../tasks/tasks_screen.dart';
import 'project_form_screen.dart';
import 'widgets/project_activity_timeline.dart';
import 'widgets/project_attachments_section.dart';
import 'widgets/project_comments_section.dart';
import 'widgets/project_milestones_section.dart';
import 'widgets/project_overview_card.dart';
import 'widgets/project_scope_section.dart';
import 'widgets/project_task_metric_grid.dart';
import 'widgets/project_team_section.dart';

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

  bool _checkOfflineMutationGuard() {
    if (_detail?.isFromCache == true) {
      HapticFeedback.heavyImpact();
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text(
            'Cannot modify project data while viewing offline cached data.',
          ),
          backgroundColor: Color(0xFFB45309),
        ),
      );
      return true;
    }
    return false;
  }

  // ---------------------------------------------------------------- Milestone Actions
  Future<void> _toggleMilestone(ProjectMilestoneModel m) async {
    if (_checkOfflineMutationGuard()) return;

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
    if (_checkOfflineMutationGuard()) return;

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
    if (_checkOfflineMutationGuard()) return;

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
    if (_checkOfflineMutationGuard()) return;

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
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (ctx) => StatefulBuilder(
        builder: (context, setModalState) => Container(
          decoration: const BoxDecoration(
            color: AppTheme.pureWhite,
            borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
          ),
          padding: EdgeInsets.fromLTRB(
            20,
            20,
            20,
            MediaQuery.of(ctx).viewInsets.bottom + 20,
          ),
          child: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Expanded(
                      child: Text(
                        'Add Team Member',
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: AppTheme.heading(
                          fontSize: 16,
                          fontWeight: FontWeight.w700,
                        ),
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
                    isExpanded: true,
                    items: candidates.map((c) {
                      return DropdownMenuItem<int>(
                        value: c['id'] as int?,
                        child: Text(
                          c['full_name']?.toString() ?? '',
                          overflow: TextOverflow.ellipsis,
                        ),
                      );
                    }).toList(),
                    onChanged: (val) =>
                        setModalState(() => selectedUserId = val),
                    decoration: const InputDecoration(
                      labelText: 'Select Employee',
                      border: OutlineInputBorder(),
                    ),
                  ),
                  const SizedBox(height: 12),
                  DropdownButtonFormField<String>(
                    initialValue: selectedRole,
                    isExpanded: true,
                    items: const [
                      DropdownMenuItem(
                        value: 'member',
                        child: Text(
                          'Member (Can be assigned tasks)',
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                      DropdownMenuItem(
                        value: 'viewer',
                        child: Text(
                          'Viewer (Read-only observation)',
                          overflow: TextOverflow.ellipsis,
                        ),
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
      ),
    );
  }

  void _confirmRemoveMember(ProjectMemberModel m) {
    if (_checkOfflineMutationGuard()) return;

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
    if (_checkOfflineMutationGuard()) return;

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
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (ctx) => Container(
        decoration: const BoxDecoration(
          color: AppTheme.pureWhite,
          borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
        ),
        padding: const EdgeInsets.all(20),
        child: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Expanded(
                    child: Text(
                      'Change Project Status',
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: AppTheme.heading(
                        fontSize: 16,
                        fontWeight: FontWeight.w700,
                      ),
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
    if (_checkOfflineMutationGuard()) return;

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
              backgroundColor: isArchived
                  ? AppTheme.royalBlue
                  : AppTheme.dangerText,
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
      appBar: ModuleAppBar(
        title: p != null ? p.projectCode : 'Project Details',
        titleStyle: AppTheme.mono(
          fontSize: 17,
          fontWeight: FontWeight.w700,
          color: AppTheme.deepSlate,
        ),
        subtitle: p?.name,
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

          // Ambient Offline Banner
          if (detail.isFromCache)
            Padding(
              padding: const EdgeInsets.only(bottom: 16),
              child: OfflineCacheBanner(onRetry: _loadProjectDetail),
            ),

          // 1. Header Summary Card
          ProjectOverviewCard(project: p, detail: detail),
          const SizedBox(height: 16),

          // 2. Task Breakdown Metrics
          ProjectTaskMetricGrid(counts: detail.taskCounts),
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
          ProjectMilestonesSection(
            milestones: detail.milestones,
            canManage: p.canManage,
            onToggle: _toggleMilestone,
            onAdd: _showMilestoneModal,
            onEdit: (m) => _showMilestoneModal(existing: m),
            onDelete: _confirmDeleteMilestone,
          ),
          const SizedBox(height: 24),

          // 5. Team Members Strip
          ProjectTeamSection(
            members: detail.members,
            canManage: p.canManage,
            onAdd: _showAddMemberModal,
            onRemove: _confirmRemoveMember,
          ),
          const SizedBox(height: 24),

          // 6. Scope & Deliverables
          if ((detail.scopeOfWork != null && detail.scopeOfWork!.isNotEmpty) ||
              (detail.deliverables != null &&
                  detail.deliverables!.isNotEmpty)) ...[
            ProjectScopeSection(detail: detail),
            const SizedBox(height: 24),
          ],

          // 7. Recent Activity Section
          if (detail.recentActivity.isNotEmpty) ...[
            ProjectActivityTimeline(activities: detail.recentActivity),
            const SizedBox(height: 24),
          ],

          // 8. Files & Attachments Section
          ProjectAttachmentsSection(
            projectId: p.id,
            attachments: detail.attachments,
            onUploaded: _loadProjectDetail,
          ),
          const SizedBox(height: 24),

          // 9. Discussion & Comments Section
          ProjectCommentsSection(projectId: p.id),
          const SizedBox(height: 24),
        ],
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
