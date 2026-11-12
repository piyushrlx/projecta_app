import 'package:flutter/material.dart';
import '../../core/theme.dart';
import '../../services/directory_service.dart';
import 'departments_screen.dart';

class DepartmentsSheet extends StatefulWidget {
  final DirectoryService? directoryService;

  const DepartmentsSheet({super.key, this.directoryService});

  static Future<void> show(
    BuildContext context, {
    DirectoryService? directoryService,
  }) {
    return showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => DepartmentsSheet(directoryService: directoryService),
    );
  }

  @override
  State<DepartmentsSheet> createState() => _DepartmentsSheetState();
}

class _DepartmentsSheetState extends State<DepartmentsSheet> {
  late final DirectoryService _directoryService =
      widget.directoryService ?? DirectoryService();

  List<Map<String, dynamic>> _departments = [];
  List<Map<String, dynamic>> _managers = [];
  bool _isLoading = true;
  String? _errorMessage;

  @override
  void initState() {
    super.initState();
    _loadDepartments();
  }

  Future<void> _loadDepartments() async {
    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    try {
      final depts = await _directoryService.getDepartments(status: 'all');
      final emps = await _directoryService.getEmployees();
      if (mounted) {
        setState(() {
          _departments = depts;
          _managers = emps.where((e) {
            final r = (e['role'] ?? '').toString();
            return r == 'admin' || r == 'super_admin';
          }).toList();
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

  Future<void> _openDepartmentDialog({Map<String, dynamic>? dept}) async {
    final isEdit = dept != null;
    final nameController = TextEditingController(
      text: dept?['name']?.toString() ?? '',
    );
    final descController = TextEditingController(
      text: dept?['description']?.toString() ?? '',
    );
    int? selectedManagerId = dept?['manager_id'] as int?;
    String status = (dept?['status'] ?? 'active').toString();

    final saved = await showDialog<bool>(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setDialogState) => AlertDialog(
          backgroundColor: AppTheme.pureWhite,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
          ),
          title: Text(
            isEdit ? 'Edit Department' : 'Add Department',
            style: AppTheme.heading(fontSize: 16, color: AppTheme.deepSlate),
          ),
          content: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Name *',
                  style: AppTheme.body(
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                const SizedBox(height: 6),
                TextField(
                  controller: nameController,
                  style: AppTheme.body(fontSize: 13),
                  decoration: InputDecoration(
                    hintText: 'e.g. Engineering',
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(8),
                    ),
                    contentPadding: const EdgeInsets.symmetric(
                      horizontal: 12,
                      vertical: 10,
                    ),
                  ),
                ),
                const SizedBox(height: 12),
                Text(
                  'Description',
                  style: AppTheme.body(
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                const SizedBox(height: 6),
                TextField(
                  controller: descController,
                  maxLines: 2,
                  style: AppTheme.body(fontSize: 13),
                  decoration: InputDecoration(
                    hintText: 'Brief description...',
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(8),
                    ),
                    contentPadding: const EdgeInsets.symmetric(
                      horizontal: 12,
                      vertical: 10,
                    ),
                  ),
                ),
                const SizedBox(height: 12),
                Text(
                  'Department Head',
                  style: AppTheme.body(
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                const SizedBox(height: 6),
                DropdownButtonFormField<int?>(
                  initialValue: selectedManagerId,
                  isExpanded: true,
                  decoration: InputDecoration(
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(8),
                    ),
                    contentPadding: const EdgeInsets.symmetric(
                      horizontal: 12,
                      vertical: 8,
                    ),
                  ),
                  items: [
                    const DropdownMenuItem<int?>(
                      value: null,
                      child: Text('No Head Assigned'),
                    ),
                    ..._managers.map(
                      (m) => DropdownMenuItem<int?>(
                        value: m['id'] as int,
                        child: Text(
                          m['full_name']?.toString() ?? '',
                          style: AppTheme.body(fontSize: 13),
                        ),
                      ),
                    ),
                  ],
                  onChanged: (val) =>
                      setDialogState(() => selectedManagerId = val),
                ),
              ],
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(ctx, false),
              child: Text(
                'Cancel',
                style: AppTheme.body(color: AppTheme.mutedSlate),
              ),
            ),
            ElevatedButton(
              onPressed: () async {
                if (nameController.text.trim().isEmpty) return;
                Navigator.pop(ctx, true);
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: AppTheme.navyBlue,
              ),
              child: const Text('Save'),
            ),
          ],
        ),
      ),
    );

    if (saved != true || !mounted) return;

    final scaffoldMessenger = ScaffoldMessenger.of(context);
    try {
      final payload = <String, dynamic>{
        if (isEdit) 'id': dept['id'],
        'name': nameController.text.trim(),
        'description': descController.text.trim(),
        'manager_id': ?selectedManagerId,
        'status': status,
      };
      final res = await _directoryService.saveDepartment(payload);
      scaffoldMessenger.showSnackBar(
        SnackBar(
          content: Text(res['message']?.toString() ?? 'Department saved.'),
          backgroundColor: AppTheme.successText,
        ),
      );
      _loadDepartments();
    } catch (e) {
      scaffoldMessenger.showSnackBar(
        SnackBar(
          content: Text(e.toString().replaceAll('ApiException:', '').trim()),
          backgroundColor: AppTheme.dangerText,
        ),
      );
    }
  }

  Future<void> _deleteDepartment(Map<String, dynamic> dept) async {
    final id = dept['id'] as int;
    final name = dept['name']?.toString() ?? '';
    final empCount =
        (dept['total_employee_count'] ?? dept['employee_count'] ?? 0) as int;
    final projCount =
        (dept['total_projects_count'] ?? dept['active_projects_count'] ?? 0)
            as int;
    final inUse = empCount > 0 || projCount > 0;

    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: AppTheme.pureWhite,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: Text(
          inUse ? 'Deactivate Department' : 'Delete Department',
          style: AppTheme.heading(fontSize: 16, color: AppTheme.deepSlate),
        ),
        content: Text(
          inUse
              ? 'Department "$name" is referenced by $empCount employee(s) and $projCount project(s). It will be marked inactive instead of permanently deleted.'
              : 'Permanently delete department "$name"? This cannot be undone.',
          style: AppTheme.body(fontSize: 13, color: AppTheme.mutedSlate),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: Text(
              'Cancel',
              style: AppTheme.body(color: AppTheme.mutedSlate),
            ),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(ctx, true),
            style: ElevatedButton.styleFrom(
              backgroundColor: inUse
                  ? AppTheme.warningText
                  : AppTheme.dangerText,
            ),
            child: Text(inUse ? 'Deactivate' : 'Delete'),
          ),
        ],
      ),
    );

    if (confirmed != true || !mounted) return;

    final scaffoldMessenger = ScaffoldMessenger.of(context);
    try {
      final res = await _directoryService.deleteDepartment(id);
      scaffoldMessenger.showSnackBar(
        SnackBar(
          content: Text(res['message']?.toString() ?? 'Department updated.'),
          backgroundColor: inUse ? AppTheme.warningText : AppTheme.dangerText,
        ),
      );
      _loadDepartments();
    } catch (e) {
      scaffoldMessenger.showSnackBar(
        SnackBar(
          content: Text(e.toString().replaceAll('ApiException:', '').trim()),
          backgroundColor: AppTheme.dangerText,
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      height: MediaQuery.of(context).size.height * 0.78,
      decoration: const BoxDecoration(
        color: AppTheme.pureWhite,
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      child: Column(
        children: [
          // Drag handle
          Container(
            margin: const EdgeInsets.only(top: 10, bottom: 8),
            width: 36,
            height: 4,
            decoration: BoxDecoration(
              color: const Color(0xFFCBD5E1),
              borderRadius: BorderRadius.circular(2),
            ),
          ),
          // Header Row
          Padding(
            padding: const EdgeInsets.fromLTRB(18, 4, 18, 12),
            child: Row(
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Department Management',
                        style: AppTheme.heading(
                          fontSize: 17,
                          fontWeight: FontWeight.w700,
                          color: AppTheme.deepSlate,
                        ),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        '${_departments.length} registered department(s)',
                        style: AppTheme.body(
                          fontSize: 12,
                          color: AppTheme.mutedSlate,
                        ),
                      ),
                    ],
                  ),
                ),
                IconButton(
                  icon: const Icon(
                    Icons.open_in_new,
                    size: 18,
                    color: AppTheme.royalBlue,
                  ),
                  tooltip: 'Open Full Page',
                  onPressed: () {
                    Navigator.pop(context);
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (_) => DepartmentsScreen(
                          directoryService: _directoryService,
                        ),
                      ),
                    );
                  },
                ),
                ElevatedButton.icon(
                  onPressed: () => _openDepartmentDialog(),
                  icon: const Icon(Icons.add, size: 16),
                  label: const Text('Add'),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppTheme.navyBlue,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(8),
                    ),
                    padding: const EdgeInsets.symmetric(
                      horizontal: 12,
                      vertical: 8,
                    ),
                  ),
                ),
              ],
            ),
          ),
          const Divider(height: 1, color: AppTheme.borderSubtle),
          // List
          Expanded(
            child: _isLoading
                ? const Center(
                    child: CircularProgressIndicator(color: AppTheme.navyBlue),
                  )
                : _errorMessage != null
                ? Center(
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Text(
                          _errorMessage!,
                          style: AppTheme.body(color: AppTheme.mutedSlate),
                        ),
                        const SizedBox(height: 12),
                        ElevatedButton(
                          onPressed: _loadDepartments,
                          child: const Text('Retry'),
                        ),
                      ],
                    ),
                  )
                : _departments.isEmpty
                ? Center(
                    child: Text(
                      'No departments found.',
                      style: AppTheme.body(color: AppTheme.mutedSlate),
                    ),
                  )
                : ListView.separated(
                    padding: const EdgeInsets.all(16),
                    itemCount: _departments.length,
                    separatorBuilder: (_, _) => const SizedBox(height: 10),
                    itemBuilder: (_, i) {
                      final d = _departments[i];
                      final name = d['name']?.toString() ?? '';
                      final desc = d['description']?.toString() ?? '';
                      final mgr = d['manager_name']?.toString();
                      final empCount = (d['employee_count'] ?? 0) as int;
                      final projCount =
                          (d['active_projects_count'] ?? 0) as int;
                      final isActive = (d['status'] ?? 'active') == 'active';

                      return Container(
                        padding: const EdgeInsets.all(12),
                        decoration: BoxDecoration(
                          color: AppTheme.pureWhite,
                          borderRadius: BorderRadius.circular(10),
                          border: Border.all(color: AppTheme.borderSubtle),
                          boxShadow: const [AppTheme.softShadow],
                        ),
                        child: Row(
                          children: [
                            Container(
                              width: 38,
                              height: 38,
                              decoration: BoxDecoration(
                                color: const Color(0xFFF1F5F9),
                                borderRadius: BorderRadius.circular(8),
                              ),
                              child: const Center(
                                child: Icon(
                                  Icons.domain_outlined,
                                  size: 20,
                                  color: AppTheme.royalBlue,
                                ),
                              ),
                            ),
                            const SizedBox(width: 12),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Row(
                                    children: [
                                      Flexible(
                                        child: Text(
                                          name,
                                          maxLines: 1,
                                          overflow: TextOverflow.ellipsis,
                                          style: AppTheme.heading(
                                            fontSize: 14,
                                            fontWeight: FontWeight.w700,
                                            color: AppTheme.deepSlate,
                                          ),
                                        ),
                                      ),
                                      const SizedBox(width: 6),
                                      if (!isActive)
                                        Container(
                                          padding: const EdgeInsets.symmetric(
                                            horizontal: 5,
                                            vertical: 1,
                                          ),
                                          decoration: BoxDecoration(
                                            color: AppTheme.dangerBg,
                                            borderRadius: BorderRadius.circular(
                                              4,
                                            ),
                                          ),
                                          child: Text(
                                            'INACTIVE',
                                            style: AppTheme.mono(
                                              fontSize: 8,
                                              fontWeight: FontWeight.w700,
                                              color: AppTheme.dangerText,
                                            ),
                                          ),
                                        ),
                                    ],
                                  ),
                                  if (desc.isNotEmpty) ...[
                                    const SizedBox(height: 2),
                                    Text(
                                      desc,
                                      style: AppTheme.body(
                                        fontSize: 11,
                                        color: AppTheme.mutedSlate,
                                      ),
                                      maxLines: 1,
                                      overflow: TextOverflow.ellipsis,
                                    ),
                                  ],
                                  const SizedBox(height: 4),
                                  Text(
                                    'Head: ${mgr ?? 'Unassigned'}  •  $empCount staff  •  $projCount projects',
                                    style: AppTheme.body(
                                      fontSize: 10,
                                      color: AppTheme.lightSlate,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                            IconButton(
                              icon: const Icon(
                                Icons.edit_outlined,
                                size: 18,
                                color: AppTheme.royalBlue,
                              ),
                              onPressed: () => _openDepartmentDialog(dept: d),
                            ),
                            IconButton(
                              icon: Icon(
                                isActive ? Icons.delete_outline : Icons.block,
                                size: 18,
                                color: isActive
                                    ? AppTheme.dangerText
                                    : AppTheme.mutedSlate,
                              ),
                              onPressed: () => _deleteDepartment(d),
                            ),
                          ],
                        ),
                      );
                    },
                  ),
          ),
        ],
      ),
    );
  }
}
