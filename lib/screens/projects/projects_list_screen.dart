import 'package:flutter/material.dart';
import '../../core/theme.dart';
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
  String _selectedFilter = 'ALL'; // ALL, ACTIVE, COMPLETED, AT RISK

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
      if (_selectedFilter == 'ACTIVE') statusQuery = 'active';
      if (_selectedFilter == 'COMPLETED') statusQuery = 'completed';

      final res = await _projectService.getProjects(
        status: statusQuery,
        limit: 50,
      );

      var list = (res['projects'] as List<ProjectModel>?) ?? [];

      if (_selectedFilter == 'AT RISK') {
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
      backgroundColor: AppTheme.pitchBlack,
      appBar: AppBar(
        title: Text(
          'PROJECTS DIRECTORY',
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
          // Filter Chips Bar
          _buildFilterChips(),
          // Projects List or Loader/Error
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
                : _projects.isEmpty
                ? _buildEmptyView()
                : RefreshIndicator(
                    onRefresh: _loadProjects,
                    color: AppTheme.violentRed,
                    child: ListView.separated(
                      padding: const EdgeInsets.all(16),
                      itemCount: _projects.length,
                      separatorBuilder: (_, _) => const SizedBox(height: 14),
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
    final filters = ['ALL', 'ACTIVE', 'COMPLETED', 'AT RISK'];
    return Container(
      color: AppTheme.pitchBlack,
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
      child: SingleChildScrollView(
        scrollDirection: Axis.horizontal,
        child: Row(
          children: filters.map((f) {
            final isSelected = _selectedFilter == f;
            return Padding(
              padding: const EdgeInsets.only(right: 8),
              child: GestureDetector(
                onTap: () => _onFilterSelected(f),
                child: Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 14,
                    vertical: 8,
                  ),
                  decoration: BoxDecoration(
                    color: isSelected
                        ? AppTheme.violentRed
                        : AppTheme.pitchBlack,
                    border: Border.all(
                      color: isSelected
                          ? AppTheme.violentRed
                          : AppTheme.pureWhite,
                      width: 2.0,
                    ),
                  ),
                  child: Text(
                    f,
                    style: AppTheme.mono(
                      fontSize: 12,
                      fontWeight: FontWeight.w800,
                      color: AppTheme.pureWhite,
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
    return GestureDetector(
      onTap: () {
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (_) => ProjectDetailScreen(projectId: project.id),
          ),
        );
      },
      child: Container(
        decoration: AppTheme.neoCardDecoration(
          backgroundColor: AppTheme.pureWhite,
          borderColor: AppTheme.pitchBlack,
          shadowOffset: 4.0,
          shadowColor: AppTheme.pureWhite,
        ),
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Top Row: Code Badge + Priority + Status Tag
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 8,
                    vertical: 3,
                  ),
                  color: AppTheme.pitchBlack,
                  child: Text(
                    project.projectCode,
                    style: AppTheme.mono(
                      fontSize: 12,
                      fontWeight: FontWeight.w800,
                      color: AppTheme.pureWhite,
                    ),
                  ),
                ),
                Row(
                  children: [
                    if (project.overdueTasks > 0)
                      Container(
                        margin: const EdgeInsets.only(right: 6),
                        padding: const EdgeInsets.symmetric(
                          horizontal: 6,
                          vertical: 2,
                        ),
                        color: AppTheme.violentRed,
                        child: Text(
                          '${project.overdueTasks} OVERDUE',
                          style: AppTheme.mono(
                            fontSize: 10,
                            fontWeight: FontWeight.w800,
                            color: AppTheme.pureWhite,
                          ),
                        ),
                      ),
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 8,
                        vertical: 2,
                      ),
                      decoration: BoxDecoration(
                        border: Border.all(
                          color: AppTheme.pitchBlack,
                          width: 1.5,
                        ),
                        color: project.isActive
                            ? const Color(0xFFE8F5E9)
                            : project.isCompleted
                            ? const Color(0xFFE3F2FD)
                            : const Color(0xFFFFF3E0),
                      ),
                      child: Text(
                        project.status.toUpperCase(),
                        style: AppTheme.mono(
                          fontSize: 10,
                          fontWeight: FontWeight.w800,
                          color: AppTheme.pitchBlack,
                        ),
                      ),
                    ),
                  ],
                ),
              ],
            ),
            const SizedBox(height: 10),
            // Project Name
            Text(
              project.name,
              style: AppTheme.heading(fontSize: 17, color: AppTheme.pitchBlack),
            ),
            if (project.clientName != null &&
                project.clientName!.isNotEmpty) ...[
              const SizedBox(height: 3),
              Text(
                'CLIENT: ${project.clientName!.toUpperCase()}',
                style: AppTheme.mono(
                  fontSize: 11,
                  color: const Color(0xFF666666),
                ),
              ),
            ],
            const SizedBox(height: 12),
            // Progress Bar with TweenAnimationBuilder
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  'COMPLETION',
                  style: AppTheme.mono(
                    fontSize: 11,
                    fontWeight: FontWeight.w700,
                  ),
                ),
                Text(
                  '${project.completionPercent.toStringAsFixed(1)}%',
                  style: AppTheme.mono(
                    fontSize: 12,
                    fontWeight: FontWeight.w900,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 6),
            TweenAnimationBuilder<double>(
              tween: Tween<double>(
                begin: 0.0,
                end: (project.completionPercent / 100).clamp(0.0, 1.0),
              ),
              duration: const Duration(milliseconds: 400),
              curve: Curves.easeOutCubic,
              builder: (ctx, value, _) {
                return ClipRRect(
                  borderRadius: BorderRadius.zero,
                  child: LinearProgressIndicator(
                    value: value,
                    minHeight: 8,
                    backgroundColor: const Color(0xFFE0E0E0),
                    valueColor: const AlwaysStoppedAnimation<Color>(
                      AppTheme.pitchBlack,
                    ),
                  ),
                );
              },
            ),
            const SizedBox(height: 12),
            // Bottom Meta Row: Tasks count, Member count, Deadline
            Row(
              children: [
                Icon(
                  Icons.check_circle_outline,
                  size: 14,
                  color: AppTheme.neutralGrey,
                ),
                const SizedBox(width: 4),
                Text(
                  '${project.doneTasks}/${project.totalTasks} TASKS',
                  style: AppTheme.mono(
                    fontSize: 11,
                    color: const Color(0xFF444444),
                  ),
                ),
                const Spacer(),
                Icon(
                  Icons.people_outline,
                  size: 14,
                  color: AppTheme.neutralGrey,
                ),
                const SizedBox(width: 4),
                Text(
                  '${project.memberCount} MEMBERS',
                  style: AppTheme.mono(
                    fontSize: 11,
                    color: const Color(0xFF444444),
                  ),
                ),
                const Spacer(),
                Icon(
                  Icons.calendar_today_outlined,
                  size: 13,
                  color: AppTheme.neutralGrey,
                ),
                const SizedBox(width: 4),
                Text(
                  project.deadline ?? 'NO DATE',
                  style: AppTheme.mono(
                    fontSize: 11,
                    color: project.overdueTasks > 0
                        ? AppTheme.violentRed
                        : const Color(0xFF444444),
                    fontWeight: project.overdueTasks > 0
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

  Widget _buildEmptyView() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const Icon(Icons.folder_open, size: 48, color: AppTheme.pureWhite),
          const SizedBox(height: 12),
          Text('NO PROJECTS FOUND', style: AppTheme.heading(fontSize: 16)),
          const SizedBox(height: 6),
          Text(
            'No projects matching filter "$_selectedFilter"',
            style: AppTheme.body(fontSize: 13, color: const Color(0xFFAAAAAA)),
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
            color: const Color(0xFF1E1414),
            border: Border.all(color: AppTheme.violentRed, width: 2),
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                'FAILED TO LOAD PROJECTS',
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
                onPressed: _loadProjects,
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
