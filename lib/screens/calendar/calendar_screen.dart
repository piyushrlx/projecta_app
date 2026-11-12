import 'package:flutter/material.dart';
import '../../core/theme.dart';
import '../../core/widgets/brutalist_pressable.dart';
import '../../models/user_model.dart';
import '../../services/dashboard_service.dart';
import '../tasks/task_detail_screen.dart';

class CalendarScreen extends StatefulWidget {
  final UserModel? currentUser;
  final DashboardService? dashboardService;

  const CalendarScreen({
    super.key,
    this.currentUser,
    this.dashboardService,
  });

  @override
  State<CalendarScreen> createState() => _CalendarScreenState();
}

class _CalendarScreenState extends State<CalendarScreen> {
  late final DashboardService _dashboardService =
      widget.dashboardService ?? DashboardService();

  DateTime _selectedDate = DateTime.now();
  DateTime _visibleAnchor = DateTime.now();
  String _view = 'month'; // 'month' or 'week'

  bool _isLoading = true;
  String? _errorMessage;

  List<dynamic> _tasks = [];
  List<dynamic> _milestones = [];
  Map<String, String> _holidays = {};
  List<dynamic> _upcoming = [];
  String _heading = '';

  @override
  void initState() {
    super.initState();
    _fetchCalendarData();
  }

  String _formatDateYMD(DateTime dt) {
    return '${dt.year.toString().padLeft(4, '0')}-${dt.month.toString().padLeft(2, '0')}-${dt.day.toString().padLeft(2, '0')}';
  }

  Future<void> _fetchCalendarData() async {
    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    try {
      final data = await _dashboardService.getCalendarData(
        date: _visibleAnchor,
        view: _view,
      );

      final rawTasks = data['tasks'] as List<dynamic>? ?? [];
      final rawMilestones = data['milestones'] as List<dynamic>? ?? [];
      final rawHolidays = data['holidays'] as List<dynamic>? ?? [];
      final rawUpcoming = data['upcoming'] as List<dynamic>? ?? [];

      final holidayMap = <String, String>{};
      for (final h in rawHolidays) {
        if (h is Map<String, dynamic> && h['holiday_date'] != null) {
          holidayMap[h['holiday_date'].toString()] = (h['name'] ?? 'Holiday').toString();
        }
      }

      if (mounted) {
        setState(() {
          _tasks = rawTasks;
          _milestones = rawMilestones;
          _holidays = holidayMap;
          _upcoming = rawUpcoming;
          _heading = (data['heading'] ?? '').toString();
          _isLoading = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _errorMessage = e.toString().replaceAll('ApiException:', '').trim();
          _isLoading = false;
        });
      }
    }
  }

  void _changePeriod(int offset) {
    setState(() {
      if (_view == 'month') {
        _visibleAnchor = DateTime(
          _visibleAnchor.year,
          _visibleAnchor.month + offset,
          1,
        );
      } else {
        _visibleAnchor = _visibleAnchor.add(Duration(days: offset * 7));
      }
      _selectedDate = _visibleAnchor;
    });
    _fetchCalendarData();
  }

  void _jumpToToday() {
    final now = DateTime.now();
    setState(() {
      _visibleAnchor = now;
      _selectedDate = now;
    });
    _fetchCalendarData();
  }

  List<dynamic> _getTasksForDate(DateTime date) {
    final dateStr = _formatDateYMD(date);
    return _tasks.where((t) => t['deadline'] == dateStr).toList();
  }

  List<dynamic> _getMilestonesForDate(DateTime date) {
    final dateStr = _formatDateYMD(date);
    return _milestones.where((m) => m['due_date'] == dateStr).toList();
  }

  @override
  Widget build(BuildContext context) {
    final todayStr = _formatDateYMD(DateTime.now());
    final selectedStr = _formatDateYMD(_selectedDate);

    final selectedTasks = _getTasksForDate(_selectedDate);
    final selectedMilestones = _getMilestonesForDate(_selectedDate);
    final selectedHoliday = _holidays[selectedStr];

    return Scaffold(
      backgroundColor: AppTheme.scaffoldBg,
      appBar: PreferredSize(
        preferredSize: const Size.fromHeight(64),
        child: Container(
          decoration: const BoxDecoration(
            color: AppTheme.pureWhite,
            border: Border(
              bottom: BorderSide(color: AppTheme.borderSubtle, width: 1.0),
            ),
          ),
          child: SafeArea(
            bottom: false,
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16.0),
              child: Row(
                children: [
                  IconButton(
                    icon: const Icon(Icons.arrow_back, color: AppTheme.deepSlate),
                    onPressed: () => Navigator.pop(context),
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      'Calendar & Deadlines',
                      style: AppTheme.heading(
                        fontSize: 18,
                        fontWeight: FontWeight.w700,
                        color: AppTheme.deepSlate,
                      ),
                    ),
                  ),
                  TextButton.icon(
                    onPressed: _jumpToToday,
                    icon: const Icon(Icons.today, size: 16, color: AppTheme.royalBlue),
                    label: Text(
                      'Today',
                      style: AppTheme.body(
                        fontSize: 12,
                        fontWeight: FontWeight.w700,
                        color: AppTheme.royalBlue,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
      body: _isLoading
          ? const Center(
              child: CircularProgressIndicator(color: AppTheme.royalBlue),
            )
          : _errorMessage != null
              ? Center(
                  child: Padding(
                    padding: const EdgeInsets.all(24.0),
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        const Icon(Icons.error_outline, size: 48, color: AppTheme.dangerText),
                        const SizedBox(height: 12),
                        Text(
                          _errorMessage!,
                          textAlign: TextAlign.center,
                          style: AppTheme.body(fontSize: 14, color: AppTheme.deepSlate),
                        ),
                        const SizedBox(height: 16),
                        OutlinedButton(
                          onPressed: _fetchCalendarData,
                          child: const Text('Try Again'),
                        ),
                      ],
                    ),
                  ),
                )
              : RefreshIndicator(
                  color: AppTheme.royalBlue,
                  onRefresh: _fetchCalendarData,
                  child: SingleChildScrollView(
                    padding: const EdgeInsets.all(16.0),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        // View switcher & Navigation Row
                        _buildPeriodNavigator(),
                        const SizedBox(height: 16),

                        // Calendar Grid Card
                        _buildCalendarCard(todayStr, selectedStr),
                        const SizedBox(height: 16),

                        // Selected Date Event Details
                        _buildDayDetailCard(selectedTasks, selectedMilestones, selectedHoliday),
                        const SizedBox(height: 16),

                        // 14-Day Upcoming Feed
                        _buildUpcomingDeadlinesCard(todayStr),
                        const SizedBox(height: 24),
                      ],
                    ),
                  ),
                ),
    );
  }

  Widget _buildPeriodNavigator() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      decoration: BoxDecoration(
        color: AppTheme.pureWhite,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppTheme.borderSubtle),
      ),
      child: Wrap(
        alignment: WrapAlignment.spaceBetween,
        crossAxisAlignment: WrapCrossAlignment.center,
        spacing: 8,
        runSpacing: 8,
        children: [
          Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              IconButton(
                icon: const Icon(Icons.chevron_left, color: AppTheme.deepSlate),
                onPressed: () => _changePeriod(-1),
                visualDensity: VisualDensity.compact,
              ),
              IconButton(
                icon: const Icon(Icons.chevron_right, color: AppTheme.deepSlate),
                onPressed: () => _changePeriod(1),
                visualDensity: VisualDensity.compact,
              ),
              const SizedBox(width: 4),
              Text(
                _heading.isNotEmpty
                    ? _heading
                    : '${_visibleAnchor.month}/${_visibleAnchor.year}',
                style: AppTheme.heading(
                  fontSize: 15,
                  fontWeight: FontWeight.w700,
                  color: AppTheme.deepSlate,
                ),
              ),
            ],
          ),
          SegmentedButton<String>(
            segments: const [
              ButtonSegment(value: 'month', label: Text('Month')),
              ButtonSegment(value: 'week', label: Text('Week')),
            ],
            selected: {_view},
            onSelectionChanged: (set) {
              if (set.isNotEmpty) {
                setState(() => _view = set.first);
                _fetchCalendarData();
              }
            },
            style: ButtonStyle(
              visualDensity: VisualDensity.compact,
              tapTargetSize: MaterialTapTargetSize.shrinkWrap,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildCalendarCard(String todayStr, String selectedStr) {
    final daysOfWeek = ['M', 'T', 'W', 'T', 'F', 'S', 'S'];

    final firstDayOfMonth = DateTime(_visibleAnchor.year, _visibleAnchor.month, 1);
    final daysInMonth = DateTime(_visibleAnchor.year, _visibleAnchor.month + 1, 0).day;
    final startingWeekday = firstDayOfMonth.weekday; // 1 = Monday, 7 = Sunday

    final totalSlots = _view == 'month'
        ? ((daysInMonth + startingWeekday - 1) <= 35 ? 35 : 42)
        : 7;

    final startOfWeek = _visibleAnchor.subtract(Duration(days: _visibleAnchor.weekday - 1));

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppTheme.pureWhite,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppTheme.borderSubtle),
        boxShadow: const [AppTheme.softShadow],
      ),
      child: Column(
        children: [
          // Day Header
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceAround,
            children: daysOfWeek
                .map(
                  (d) => SizedBox(
                    width: 38,
                    child: Center(
                      child: Text(
                        d,
                        style: AppTheme.mono(
                          fontSize: 12,
                          fontWeight: FontWeight.w700,
                          color: AppTheme.mutedSlate,
                        ),
                      ),
                    ),
                  ),
                )
                .toList(),
          ),
          const SizedBox(height: 8),
          const Divider(height: 1, color: AppTheme.borderSubtle),
          const SizedBox(height: 8),

          // Day Grid
          GridView.builder(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            itemCount: totalSlots,
            gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
              crossAxisCount: 7,
              crossAxisSpacing: 4,
              mainAxisSpacing: 6,
              childAspectRatio: 0.95,
            ),
            itemBuilder: (context, index) {
              DateTime dayDate;
              bool isCurrentMonth = true;

              if (_view == 'month') {
                final dayNumber = index - startingWeekday + 2;
                if (dayNumber < 1) {
                  final prevMonthLastDay = DateTime(_visibleAnchor.year, _visibleAnchor.month, 0).day;
                  dayDate = DateTime(_visibleAnchor.year, _visibleAnchor.month - 1, prevMonthLastDay + dayNumber);
                  isCurrentMonth = false;
                } else if (dayNumber > daysInMonth) {
                  dayDate = DateTime(_visibleAnchor.year, _visibleAnchor.month + 1, dayNumber - daysInMonth);
                  isCurrentMonth = false;
                } else {
                  dayDate = DateTime(_visibleAnchor.year, _visibleAnchor.month, dayNumber);
                }
              } else {
                dayDate = startOfWeek.add(Duration(days: index));
              }

              final dayYMD = _formatDateYMD(dayDate);
              final isToday = dayYMD == todayStr;
              final isSelected = dayYMD == selectedStr;

              final tasksOnDay = _getTasksForDate(dayDate);
              final milestonesOnDay = _getMilestonesForDate(dayDate);
              final isHoliday = _holidays.containsKey(dayYMD);

              return GestureDetector(
                onTap: () {
                  setState(() => _selectedDate = dayDate);
                },
                child: Container(
                  decoration: BoxDecoration(
                    color: isSelected
                        ? AppTheme.royalBlue
                        : isToday
                            ? const Color(0xFFEFF6FF)
                            : Colors.transparent,
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(
                      color: isToday && !isSelected
                          ? AppTheme.royalBlue
                          : Colors.transparent,
                      width: 1.2,
                    ),
                  ),
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Text(
                        '${dayDate.day}',
                        style: AppTheme.body(
                          fontSize: 12,
                          fontWeight: (isSelected || isToday) ? FontWeight.w800 : FontWeight.w600,
                          color: isSelected
                              ? AppTheme.pureWhite
                              : isCurrentMonth
                                  ? AppTheme.deepSlate
                                  : AppTheme.borderSubtle,
                        ),
                      ),
                      const SizedBox(height: 2),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          if (tasksOnDay.isNotEmpty)
                            Container(
                              width: 5,
                              height: 5,
                              margin: const EdgeInsets.symmetric(horizontal: 1),
                              decoration: BoxDecoration(
                                shape: BoxShape.circle,
                                color: isSelected
                                    ? AppTheme.pureWhite
                                    : (dayYMD.compareTo(todayStr) < 0
                                        ? AppTheme.dangerText
                                        : AppTheme.warningText),
                              ),
                            ),
                          if (milestonesOnDay.isNotEmpty)
                            Container(
                              width: 5,
                              height: 5,
                              margin: const EdgeInsets.symmetric(horizontal: 1),
                              decoration: BoxDecoration(
                                shape: BoxShape.circle,
                                color: isSelected
                                    ? AppTheme.pureWhite
                                    : const Color(0xFF7C3AED),
                              ),
                            ),
                          if (isHoliday)
                            Container(
                              width: 5,
                              height: 5,
                              margin: const EdgeInsets.symmetric(horizontal: 1),
                              decoration: BoxDecoration(
                                shape: BoxShape.circle,
                                color: isSelected
                                    ? AppTheme.pureWhite
                                    : const Color(0xFF0D9488),
                              ),
                            ),
                        ],
                      ),
                    ],
                  ),
                ),
              );
            },
          ),
          const SizedBox(height: 12),
          // Legend
          Wrap(
            spacing: 12,
            runSpacing: 6,
            children: [
              _buildLegendDot(AppTheme.warningText, 'Due Soon'),
              _buildLegendDot(AppTheme.dangerText, 'Overdue'),
              _buildLegendDot(const Color(0xFF7C3AED), 'Milestone'),
              _buildLegendDot(const Color(0xFF0D9488), 'Holiday'),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildLegendDot(Color color, String label) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(
          width: 8,
          height: 8,
          decoration: BoxDecoration(color: color, shape: BoxShape.circle),
        ),
        const SizedBox(width: 4),
        Text(label, style: AppTheme.body(fontSize: 10, color: AppTheme.mutedSlate)),
      ],
    );
  }

  Widget _buildDayDetailCard(
    List<dynamic> tasks,
    List<dynamic> milestones,
    String? holiday,
  ) {
    final hasEvents = tasks.isNotEmpty || milestones.isNotEmpty || holiday != null;

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppTheme.pureWhite,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppTheme.borderSubtle),
        boxShadow: const [AppTheme.softShadow],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Icon(Icons.event_note, color: AppTheme.royalBlue, size: 20),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  'Events on ${_selectedDate.day} ${_heading.split(' ').first} ${_selectedDate.year}',
                  style: AppTheme.heading(
                    fontSize: 15,
                    fontWeight: FontWeight.w700,
                    color: AppTheme.deepSlate,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),

          if (holiday != null) ...[
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
              decoration: BoxDecoration(
                color: const Color(0xFFCCFBF1),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Row(
                children: [
                  const Icon(Icons.celebration, color: Color(0xFF0F766E), size: 18),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      'Holiday: $holiday',
                      style: AppTheme.body(
                        fontSize: 13,
                        fontWeight: FontWeight.w700,
                        color: const Color(0xFF0F766E),
                      ),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 10),
          ],

          if (milestones.isNotEmpty) ...[
            Text(
              'Milestones',
              style: AppTheme.body(fontSize: 12, fontWeight: FontWeight.w700, color: const Color(0xFF6D28D9)),
            ),
            const SizedBox(height: 6),
            ...milestones.map((m) => Container(
                  margin: const EdgeInsets.only(bottom: 6),
                  padding: const EdgeInsets.all(10),
                  decoration: BoxDecoration(
                    color: const Color(0xFFF5F3FF),
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(color: const Color(0xFFDDD6FE)),
                  ),
                  child: Row(
                    children: [
                      const Icon(Icons.flag_outlined, color: Color(0xFF7C3AED), size: 18),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              m['title']?.toString() ?? '',
                              style: AppTheme.body(fontSize: 13, fontWeight: FontWeight.w700, color: AppTheme.deepSlate),
                            ),
                            Text(
                              m['project_name']?.toString() ?? '',
                              style: AppTheme.body(fontSize: 11, color: AppTheme.mutedSlate),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                )),
            const SizedBox(height: 10),
          ],

          if (tasks.isNotEmpty) ...[
            Text(
              'Tasks Due',
              style: AppTheme.body(fontSize: 12, fontWeight: FontWeight.w700, color: AppTheme.deepSlate),
            ),
            const SizedBox(height: 6),
            ...tasks.map((t) => BrutalistPressable(
                  onTap: () {
                    final id = t['id'];
                    if (id != null) {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (_) => TaskDetailScreen(taskId: id is int ? id : int.parse(id.toString())),
                        ),
                      );
                    }
                  },
                  child: Container(
                    margin: const EdgeInsets.only(bottom: 6),
                    padding: const EdgeInsets.all(10),
                    decoration: BoxDecoration(
                      color: const Color(0xFFF8FAFC),
                      borderRadius: BorderRadius.circular(8),
                      border: Border.all(color: AppTheme.borderSubtle),
                    ),
                    child: Row(
                      children: [
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                          decoration: BoxDecoration(
                            color: AppTheme.pureWhite,
                            borderRadius: BorderRadius.circular(4),
                            border: Border.all(color: AppTheme.borderSubtle),
                          ),
                          child: Text(
                            t['task_code']?.toString() ?? '',
                            style: AppTheme.mono(fontSize: 11, fontWeight: FontWeight.w700, color: AppTheme.royalBlue),
                          ),
                        ),
                        const SizedBox(width: 8),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                t['title']?.toString() ?? '',
                                style: AppTheme.body(fontSize: 13, fontWeight: FontWeight.w600, color: AppTheme.deepSlate),
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                              ),
                              Text(
                                t['project_name']?.toString() ?? '',
                                style: AppTheme.body(fontSize: 11, color: AppTheme.mutedSlate),
                              ),
                            ],
                          ),
                        ),
                        const Icon(Icons.chevron_right, size: 16, color: AppTheme.mutedSlate),
                      ],
                    ),
                  ),
                )),
          ],

          if (!hasEvents)
            Padding(
              padding: const EdgeInsets.symmetric(vertical: 12),
              child: Center(
                child: Text(
                  'No deadlines or events scheduled for this day.',
                  style: AppTheme.body(fontSize: 13, color: AppTheme.mutedSlate),
                ),
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildUpcomingDeadlinesCard(String todayStr) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppTheme.pureWhite,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppTheme.borderSubtle),
        boxShadow: const [AppTheme.softShadow],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Icon(Icons.alarm, color: AppTheme.warningText, size: 20),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  'Upcoming Deadlines (Next 14 Days)',
                  style: AppTheme.heading(
                    fontSize: 15,
                    fontWeight: FontWeight.w700,
                    color: AppTheme.deepSlate,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          if (_upcoming.isEmpty)
            Padding(
              padding: const EdgeInsets.symmetric(vertical: 12),
              child: Center(
                child: Text(
                  'No upcoming deadlines within the next 14 days.',
                  style: AppTheme.body(fontSize: 13, color: AppTheme.mutedSlate),
                ),
              ),
            )
          else
            ListView.separated(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              itemCount: _upcoming.length > 5 ? 5 : _upcoming.length,
              separatorBuilder: (_, _) => const Divider(height: 1, color: AppTheme.borderSubtle),
              itemBuilder: (context, idx) {
                final item = _upcoming[idx];
                final deadline = item['deadline']?.toString() ?? '';
                final isOverdue = deadline.isNotEmpty && deadline.compareTo(todayStr) < 0;

                return InkWell(
                  onTap: () {
                    final id = item['id'];
                    if (id != null) {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (_) => TaskDetailScreen(taskId: id is int ? id : int.parse(id.toString())),
                        ),
                      );
                    }
                  },
                  child: Padding(
                    padding: const EdgeInsets.symmetric(vertical: 8.0),
                    child: Row(
                      children: [
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                item['title']?.toString() ?? '',
                                style: AppTheme.body(fontSize: 13, fontWeight: FontWeight.w700, color: AppTheme.deepSlate),
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                              ),
                              const SizedBox(height: 2),
                              Text(
                                '${item['task_code']} · ${item['project_name']}',
                                style: AppTheme.body(fontSize: 11, color: AppTheme.mutedSlate),
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(width: 8),
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                          decoration: BoxDecoration(
                            color: isOverdue ? const Color(0xFFFEE2E2) : const Color(0xFFFEF3C7),
                            borderRadius: BorderRadius.circular(6),
                          ),
                          child: Text(
                            deadline,
                            style: AppTheme.mono(
                              fontSize: 10,
                              fontWeight: FontWeight.w700,
                              color: isOverdue ? AppTheme.dangerText : const Color(0xFFB45309),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                );
              },
            ),
        ],
      ),
    );
  }
}
