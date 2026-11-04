import 'package:flutter/material.dart';
import '../../core/theme.dart';
import '../../core/widgets/brutalist_pressable.dart';
import '../../models/project_model.dart';
import '../../services/project_service.dart';
import 'project_detail_screen.dart';

class ProjectsListScreen extends StatefulWidget {
  const ProjectsListScreen({super.key});

  @override
  State<ProjectsListScreen> createState() => _ProjectsListScreenState();
}

class _ProjectsListScreenState extends State<ProjectsListScreen> {
  final ProjectService _projectService = ProjectService();

  bool _isLoading = true;
  String? _errorMessage;
  List<ProjectModel> _projects = [];
  String _selectedFilter = 'All'; // All, Active, Completed, At Risk

  @override
  void initState() {
    super.initState();
    _loadProjects();
  }

  Future<void> _loadProjects() async {
    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    try {
      String? statusQuery;
      final upper = _selectedFilter.toUpperCase();
      if (upper == 'ACTIVE') statusQuery = 'active';
      if (upper == 'COMPLETED') statusQuery = 'completed';

      final res = await _projectService.getProjects(
        status: statusQuery,
        limit: 50,
      );

      var list = (res['projects'] as List<ProjectModel>?) ?? [];

      if (upper == 'AT RISK') {
        list = list.where((p) => p.isAtRisk).toList();
      }

      if (mounted) {
        setState(() {
          _projects = list;
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

  void _onFilterSelected(String filter) {
    if (_selectedFilter == filter) return;
    setState(() {
      _selectedFilter = filter;
    });
    _loadProjects();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.scaffoldBg,
      appBar: AppBar(
        title: Text(
          'Projects Directory',
          style: AppTheme.heading(fontSize: 18),
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            tooltip: 'Refresh',
            onPressed: _loadProjects,
          ),
        ],
      ),
      body: Column(
        children: [
          // Filter Pills Bar
          _buildFilterChips(),

          // Projects List or Loader/Error
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
                : _projects.isEmpty
                ? _buildEmptyView()
                : RefreshIndicator(
                    onRefresh: _loadProjects,
                    color: AppTheme.royalBlue,
                    child: ListView.separated(
                      padding: const EdgeInsets.all(16),
                      itemCount: _projects.length,
                      separatorBuilder: (_, _) => const SizedBox(height: 12),
                      itemBuilder: (ctx, index) {
                        return _buildProjectCard(_projects[index]);
                      },
                    ),
                  ),
          ),
        ],
      ),
    );
  }

  Widget _buildFilterChips() {
    final filters = ['All', 'Active', 'Completed', 'At Risk'];
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      decoration: const BoxDecoration(
        color: AppTheme.pureWhite,
        border: Border(
          bottom: BorderSide(color: AppTheme.borderSubtle, width: 1.0),
        ),
      ),
      child: SingleChildScrollView(
        scrollDirection: Axis.horizontal,
        child: Row(
          children: filters.map((f) {
            final isSelected = _selectedFilter.toUpperCase() == f.toUpperCase();
            final isAtRisk = f.toUpperCase() == 'AT RISK';

            return Padding(
              padding: const EdgeInsets.only(right: 8),
              child: InkWell(
                onTap: () => _onFilterSelected(f),
                borderRadius: BorderRadius.circular(20),
                child: Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 14,
                    vertical: 7,
                  ),
                  decoration: BoxDecoration(
                    color: isSelected
                        ? (isAtRisk ? AppTheme.dangerBg : AppTheme.navyBlue)
                        : const Color(0xFFF1F5F9),
                    borderRadius: BorderRadius.circular(20),
                    border: Border.all(
                      color: isSelected
                          ? (isAtRisk
                                ? const Color(0xFFFECACA)
                                : AppTheme.navyBlue)
                          : AppTheme.borderSubtle,
                    ),
                  ),
                  child: Text(
                    f,
                    style: AppTheme.heading(
                      fontSize: 12,
                      fontWeight: FontWeight.w600,
                      color: isSelected
                          ? (isAtRisk
                                ? AppTheme.dangerText
                                : AppTheme.pureWhite)
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

  Widget _buildProjectCard(ProjectModel project) {
    final completionClamped = (project.completionPercent / 100).clamp(0.0, 1.0);

    return BrutalistPressable(
      onTap: () {
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (_) => ProjectDetailScreen(projectId: project.id),
          ),
        );
      },
      backgroundColor: AppTheme.pureWhite,
      borderColor: project.isAtRisk
          ? const Color(0xFFFECACA)
          : AppTheme.borderSubtle,
      borderRadius: BorderRadius.circular(12),
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Top Row: Code Badge + Priority + Status Tag
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
                  project.projectCode,
                  style: AppTheme.mono(
                    fontSize: 11,
                    fontWeight: FontWeight.w700,
                    color: AppTheme.deepSlate,
                  ),
                ),
              ),
              Row(
                children: [
                  _buildPriorityTag(project.priority),
                  const SizedBox(width: 6),
                  _buildStatusBadge(project.status, project.isAtRisk),
                ],
              ),
            ],
          ),
          const SizedBox(height: 12),

          // Middle: Project Title + Client Subtitle
          Text(
            project.name,
            style: AppTheme.heading(
              fontSize: 16,
              fontWeight: FontWeight.w700,
              color: AppTheme.deepSlate,
            ),
          ),
          if (project.clientName != null) ...[
            const SizedBox(height: 4),
            Text(
              'Client: ${project.clientName}',
              style: AppTheme.body(fontSize: 12, color: AppTheme.mutedSlate),
            ),
          ],
          const SizedBox(height: 14),

          // Progress Bar with %
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'Progress',
                style: AppTheme.heading(
                  fontSize: 11,
                  fontWeight: FontWeight.w600,
                  color: AppTheme.mutedSlate,
                ),
              ),
              Text(
                '${project.completionPercent.toStringAsFixed(0)}%',
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
            child: TweenAnimationBuilder<double>(
              tween: Tween<double>(begin: 0.0, end: completionClamped),
              duration: const Duration(milliseconds: 400),
              builder: (context, value, _) {
                return LinearProgressIndicator(
                  value: value,
                  minHeight: 6,
                  backgroundColor: const Color(0xFFE2E8F0),
                  valueColor: AlwaysStoppedAnimation<Color>(
                    project.isAtRisk ? AppTheme.dangerText : AppTheme.royalBlue,
                  ),
                );
              },
            ),
          ),
          const SizedBox(height: 12),

          // Footer Stats
          Row(
            children: [
              Text(
                '${project.doneTasks}/${project.totalTasks} Tasks',
                style: AppTheme.body(
                  fontSize: 12,
                  fontWeight: FontWeight.w500,
                  color: AppTheme.mutedSlate,
                ),
              ),
              if (project.overdueTasks > 0) ...[
                const SizedBox(width: 8),
                Text('·', style: TextStyle(color: AppTheme.mutedSlate)),
                const SizedBox(width: 8),
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 6,
                    vertical: 2,
                  ),
                  decoration: BoxDecoration(
                    color: AppTheme.dangerBg,
                    borderRadius: BorderRadius.circular(4),
                  ),
                  child: Text(
                    '${project.overdueTasks} Overdue',
                    style: AppTheme.mono(
                      fontSize: 10,
                      fontWeight: FontWeight.w600,
                      color: AppTheme.dangerText,
                    ),
                  ),
                ),
              ],
              const Spacer(),
              const Icon(
                Icons.arrow_forward_ios_rounded,
                size: 13,
                color: AppTheme.lightSlate,
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildPriorityTag(String priority) {
    final p = priority.toLowerCase();
    Color bg = const Color(0xFFF1F5F9);
    Color fg = AppTheme.mutedSlate;

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
      padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 3),
      decoration: BoxDecoration(
        color: bg,
        borderRadius: BorderRadius.circular(6),
      ),
      child: Text(
        priority[0].toUpperCase() + priority.substring(1).toLowerCase(),
        style: AppTheme.heading(
          fontSize: 10,
          fontWeight: FontWeight.w600,
          color: fg,
        ),
      ),
    );
  }

  Widget _buildStatusBadge(String status, bool isAtRisk) {
    if (isAtRisk) {
      return Container(
        padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 3),
        decoration: BoxDecoration(
          color: AppTheme.dangerBg,
          borderRadius: BorderRadius.circular(6),
        ),
        child: Text(
          'At Risk',
          style: AppTheme.heading(
            fontSize: 10,
            fontWeight: FontWeight.w600,
            color: AppTheme.dangerText,
          ),
        ),
      );
    }

    final isCompleted = status.toLowerCase() == 'completed';
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 3),
      decoration: BoxDecoration(
        color: isCompleted ? AppTheme.successBg : AppTheme.infoBg,
        borderRadius: BorderRadius.circular(6),
      ),
      child: Text(
        status.isEmpty
            ? 'Active'
            : status[0].toUpperCase() + status.substring(1).toLowerCase(),
        style: AppTheme.heading(
          fontSize: 10,
          fontWeight: FontWeight.w600,
          color: isCompleted ? AppTheme.successText : AppTheme.infoText,
        ),
      ),
    );
  }

  Widget _buildEmptyView() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const Icon(
            Icons.folder_open_outlined,
            size: 48,
            color: AppTheme.mutedSlate,
          ),
          const SizedBox(height: 12),
          Text('No Projects Found', style: AppTheme.heading(fontSize: 16)),
          const SizedBox(height: 4),
          Text(
            'No projects matching current filter "$_selectedFilter"',
            style: AppTheme.body(fontSize: 13, color: AppTheme.mutedSlate),
          ),
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
                'Failed to load projects',
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
                onPressed: _loadProjects,
                child: const Text('Retry'),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
