import 'package:flutter/material.dart';
import '../../../core/theme.dart';

class DashboardFilterSheet extends StatefulWidget {
  final Map<String, dynamic> filterOptions;
  final int? selectedProjectId;
  final int? selectedDepartmentId;
  final int? selectedUserId;
  final Function(int? projectId, int? departmentId, int? userId) onApply;

  const DashboardFilterSheet({
    super.key,
    required this.filterOptions,
    this.selectedProjectId,
    this.selectedDepartmentId,
    this.selectedUserId,
    required this.onApply,
  });

  @override
  State<DashboardFilterSheet> createState() => _DashboardFilterSheetState();
}

class _DashboardFilterSheetState extends State<DashboardFilterSheet> {
  int? _projectId;
  int? _departmentId;
  int? _userId;

  @override
  void initState() {
    super.initState();
    _projectId = widget.selectedProjectId;
    _departmentId = widget.selectedDepartmentId;
    _userId = widget.selectedUserId;
  }

  @override
  Widget build(BuildContext context) {
    final projects =
        (widget.filterOptions['projects'] as List<dynamic>?) ?? [];
    final departments =
        (widget.filterOptions['departments'] as List<dynamic>?) ?? [];
    final employees =
        (widget.filterOptions['employees'] as List<dynamic>?) ?? [];

    return Container(
      padding: EdgeInsets.only(
        left: 20,
        right: 20,
        top: 20,
        bottom: MediaQuery.of(context).viewInsets.bottom + 24,
      ),
      decoration: const BoxDecoration(
        color: AppTheme.pureWhite,
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      child: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Grab handle
            Center(
              child: Container(
                width: 40,
                height: 4,
                margin: const EdgeInsets.only(bottom: 16),
                decoration: BoxDecoration(
                  color: AppTheme.borderSubtle,
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
            ),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  'Filter Dashboard',
                  style: AppTheme.heading(
                    fontSize: 18,
                    fontWeight: FontWeight.w700,
                    color: AppTheme.deepSlate,
                  ),
                ),
                TextButton(
                  onPressed: () {
                    setState(() {
                      _projectId = null;
                      _departmentId = null;
                      _userId = null;
                    });
                  },
                  child: Text(
                    'Reset',
                    style: AppTheme.heading(
                      fontSize: 13,
                      fontWeight: FontWeight.w600,
                      color: AppTheme.royalBlue,
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),

            // Project Selector
            _buildDropdown(
              label: 'Project',
              hint: 'All projects',
              value: _projectId,
              items: projects.map((p) {
                final item = p as Map<String, dynamic>;
                return DropdownMenuItem<int>(
                  value: (item['id'] as num).toInt(),
                  child: Text(
                    item['name']?.toString() ?? '',
                    overflow: TextOverflow.ellipsis,
                  ),
                );
              }).toList(),
              onChanged: (val) => setState(() => _projectId = val),
            ),
            const SizedBox(height: 16),

            // Department Selector
            _buildDropdown(
              label: 'Department',
              hint: 'All departments',
              value: _departmentId,
              items: departments.map((d) {
                final item = d as Map<String, dynamic>;
                return DropdownMenuItem<int>(
                  value: (item['id'] as num).toInt(),
                  child: Text(
                    item['name']?.toString() ?? '',
                    overflow: TextOverflow.ellipsis,
                  ),
                );
              }).toList(),
              onChanged: (val) => setState(() => _departmentId = val),
            ),
            const SizedBox(height: 16),

            // Employee Selector
            _buildDropdown(
              label: 'Employee',
              hint: 'All employees',
              value: _userId,
              items: employees.map((e) {
                final item = e as Map<String, dynamic>;
                return DropdownMenuItem<int>(
                  value: (item['id'] as num).toInt(),
                  child: Text(
                    item['full_name']?.toString() ?? '',
                    overflow: TextOverflow.ellipsis,
                  ),
                );
              }).toList(),
              onChanged: (val) => setState(() => _userId = val),
            ),
            const SizedBox(height: 24),

            // Action Buttons
            Row(
              children: [
                Expanded(
                  child: OutlinedButton(
                    onPressed: () => Navigator.pop(context),
                    style: OutlinedButton.styleFrom(
                      foregroundColor: AppTheme.mutedSlate,
                      side: const BorderSide(color: AppTheme.borderSubtle),
                      padding: const EdgeInsets.symmetric(vertical: 14),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(10),
                      ),
                    ),
                    child: const Text('Cancel'),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: ElevatedButton(
                    onPressed: () {
                      widget.onApply(_projectId, _departmentId, _userId);
                      Navigator.pop(context);
                    },
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppTheme.royalBlue,
                      foregroundColor: AppTheme.pureWhite,
                      padding: const EdgeInsets.symmetric(vertical: 14),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(10),
                      ),
                      elevation: 0,
                    ),
                    child: const Text('Apply Filter'),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildDropdown({
    required String label,
    required String hint,
    required int? value,
    required List<DropdownMenuItem<int>> items,
    required ValueChanged<int?> onChanged,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: AppTheme.heading(
            fontSize: 12,
            fontWeight: FontWeight.w600,
            color: AppTheme.mutedSlate,
          ),
        ),
        const SizedBox(height: 6),
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 12),
          decoration: BoxDecoration(
            color: AppTheme.scaffoldBg,
            borderRadius: BorderRadius.circular(10),
            border: Border.all(color: AppTheme.borderSubtle),
          ),
          child: DropdownButtonHideUnderline(
            child: DropdownButton<int>(
              isExpanded: true,
              value: value,
              hint: Text(
                hint,
                style: AppTheme.body(fontSize: 13, color: AppTheme.lightSlate),
              ),
              items: [
                DropdownMenuItem<int>(
                  value: null,
                  child: Text(
                    hint,
                    style: AppTheme.body(
                      fontSize: 13,
                      color: AppTheme.mutedSlate,
                    ),
                  ),
                ),
                ...items,
              ],
              onChanged: onChanged,
            ),
          ),
        ),
      ],
    );
  }
}
