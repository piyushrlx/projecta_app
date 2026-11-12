import 'dart:typed_data';
import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import '../../core/api_client.dart';
import '../../core/company_settings.dart';
import '../../core/theme.dart';
import '../../core/widgets/module_app_bar.dart';
import '../../models/user_model.dart';
import '../../services/dashboard_service.dart';

class SettingsScreen extends StatefulWidget {
  final UserModel? currentUser;
  final DashboardService? dashboardService;

  const SettingsScreen({super.key, this.currentUser, this.dashboardService});

  @override
  State<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends State<SettingsScreen> {
  late final DashboardService _service =
      widget.dashboardService ?? DashboardService();

  int _selectedTab =
      0; // 0: General, 1: Working time, 2: Rules & permissions, 3: Holidays
  bool _isLoading = true;
  bool _isSaving = false;
  String? _errorMessage;

  List<dynamic> _holidays = [];

  // Controllers
  final _companyNameController = TextEditingController();
  final _timezoneController = TextEditingController();
  final _currencyController = TextEditingController();
  final _startController = TextEditingController();
  final _endController = TextEditingController();
  final _deadlineController = TextEditingController();
  final _graceController = TextEditingController();

  // Rules booleans
  bool _staffCanSetProgress = true;
  bool _staffCanUpload = true;
  bool _requireCompletionNotes = true;

  // Company logo state (web-parity)
  String? _currentLogoUrl;
  String? _selectedLogoName;
  String? _selectedLogoPath;
  List<int>? _selectedLogoBytes;
  bool _removeLogo = false;

  @override
  void initState() {
    super.initState();
    _fetchSettings();
  }

  @override
  void dispose() {
    _companyNameController.dispose();
    _timezoneController.dispose();
    _currencyController.dispose();
    _startController.dispose();
    _endController.dispose();
    _deadlineController.dispose();
    _graceController.dispose();
    super.dispose();
  }

  Future<void> _fetchSettings() async {
    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    try {
      final res = await _service.getFullSettings();
      final s = (res['settings'] as Map<String, dynamic>?) ?? {};
      final h = (res['holidays'] as List<dynamic>?) ?? [];

      if (mounted) {
        setState(() {
          _holidays = h;

          _companyNameController.text =
              (s['company_name'] ?? 'Rank First Technologies').toString();
          _timezoneController.text = (s['timezone'] ?? 'Asia/Kolkata')
              .toString();
          _currencyController.text = (s['currency'] ?? 'INR').toString();
          _startController.text = (s['work_start_time'] ?? '09:30').toString();
          _endController.text = (s['work_end_time'] ?? '18:30').toString();
          _deadlineController.text = (s['report_deadline_time'] ?? '19:00')
              .toString();
          _graceController.text = (s['report_grace_minutes'] ?? '60')
              .toString();

          _currentLogoUrl = s['logo_url']?.toString();
          if (_currentLogoUrl != null && _currentLogoUrl!.isNotEmpty) {
            CompanySettings.instance.update(
              companyName: _companyNameController.text,
              logoUrl: _currentLogoUrl,
            );
          }

          _staffCanSetProgress =
              s['staff_can_set_progress'] == '1' ||
              s['staff_can_set_progress'] == true;
          _staffCanUpload =
              s['staff_can_upload'] == '1' || s['staff_can_upload'] == true;
          _requireCompletionNotes =
              s['require_completion_notes'] == '1' ||
              s['require_completion_notes'] == true;

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

  Future<void> _handlePickLogo() async {
    try {
      final result = await FilePicker.pickFiles(
        type: FileType.custom,
        allowedExtensions: ['jpg', 'jpeg', 'png', 'webp'],
      );

      if (result.isEmpty) return;

      final file = result.first;
      final fileLength = await file.xFile.length();
      if (fileLength > 2 * 1024 * 1024) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Company logo must not exceed 2 MB.'),
              backgroundColor: AppTheme.dangerText,
            ),
          );
        }
        return;
      }

      final fileBytes = await file.xFile.readAsBytes();
      if (!mounted) return;

      setState(() {
        _selectedLogoName = file.name;
        _selectedLogoPath = file.path;
        _selectedLogoBytes = fileBytes;
        _removeLogo = false;
      });
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Failed to pick logo: $e'),
            backgroundColor: AppTheme.dangerText,
          ),
        );
      }
    }
  }

  Future<void> _handleSave() async {
    setState(() => _isSaving = true);
    final scaffold = ScaffoldMessenger.of(context);

    final payload = <String, dynamic>{
      'company_name': _companyNameController.text.trim(),
      'timezone': _timezoneController.text.trim(),
      'currency': _currencyController.text.trim(),
      'work_start_time': _startController.text.trim(),
      'work_end_time': _endController.text.trim(),
      'report_deadline_time': _deadlineController.text.trim(),
      'report_grace_minutes': _graceController.text.trim(),
      'staff_can_set_progress': _staffCanSetProgress ? '1' : '0',
      'staff_can_upload': _staffCanUpload ? '1' : '0',
      'require_completion_notes': _requireCompletionNotes ? '1' : '0',
    };

    try {
      final res = await _service.saveSettings(
        payload,
        logoBytes: _selectedLogoBytes,
        logoFileName: _selectedLogoName,
        logoPath: _selectedLogoPath,
        removeLogo: _removeLogo,
      );

      // Extract updated logo_url if returned
      String? updatedLogoUrl = _currentLogoUrl;
      if (res['settings'] is Map<String, dynamic>) {
        final s = res['settings'] as Map<String, dynamic>;
        if (s.containsKey('logo_url')) {
          updatedLogoUrl = s['logo_url']?.toString();
        }
      }

      await CompanySettings.instance.update(
        companyName: _companyNameController.text.trim(),
        logoUrl: _removeLogo ? null : (updatedLogoUrl ?? _currentLogoUrl),
        logoBytes: _removeLogo
            ? null
            : (_selectedLogoBytes != null
                  ? Uint8List.fromList(_selectedLogoBytes!)
                  : null),
      );

      if (mounted) {
        setState(() {
          if (_removeLogo) {
            _currentLogoUrl = null;
          } else if (updatedLogoUrl != null) {
            _currentLogoUrl = updatedLogoUrl;
          }
          _selectedLogoName = null;
          _selectedLogoPath = null;
          _selectedLogoBytes = null;
          _removeLogo = false;
          _isSaving = false;
        });
        scaffold.showSnackBar(
          const SnackBar(
            content: Text('Settings saved successfully.'),
            backgroundColor: AppTheme.successText,
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        setState(() => _isSaving = false);
        scaffold.showSnackBar(
          SnackBar(
            content: Text(e.toString().replaceAll('ApiException:', '').trim()),
            backgroundColor: AppTheme.dangerText,
          ),
        );
      }
    }
  }

  Future<void> _handleDeleteHoliday(int id, String name) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Delete Holiday'),
        content: Text('Are you sure you want to delete "$name"?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: const Text('Cancel'),
          ),
          FilledButton(
            style: FilledButton.styleFrom(backgroundColor: AppTheme.dangerText),
            onPressed: () => Navigator.pop(ctx, true),
            child: const Text('Delete'),
          ),
        ],
      ),
    );

    if (confirmed == true) {
      try {
        await _service.deleteHoliday(id);
        if (mounted) {
          setState(() {
            _holidays.removeWhere((h) => h['id'] == id);
          });
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Holiday deleted.'),
              backgroundColor: AppTheme.successText,
            ),
          );
        }
      } catch (e) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('Failed to delete holiday: $e'),
              backgroundColor: AppTheme.dangerText,
            ),
          );
        }
      }
    }
  }

  Future<void> _showAddHolidayDialog() async {
    final dateCtrl = TextEditingController();
    final nameCtrl = TextEditingController();

    await showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Add Company Holiday'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(
              controller: dateCtrl,
              decoration: const InputDecoration(
                labelText: 'Holiday Date (YYYY-MM-DD)',
                hintText: 'e.g. 2026-12-25',
              ),
            ),
            const SizedBox(height: 12),
            TextField(
              controller: nameCtrl,
              decoration: const InputDecoration(
                labelText: 'Holiday Name',
                hintText: 'e.g. Christmas Day',
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('Cancel'),
          ),
          FilledButton(
            onPressed: () async {
              final d = dateCtrl.text.trim();
              final n = nameCtrl.text.trim();
              if (d.isEmpty || n.isEmpty) return;
              Navigator.pop(ctx);
              try {
                final newId = await _service.addHoliday(d, n);
                if (mounted) {
                  setState(() {
                    _holidays.insert(0, {
                      'id': newId,
                      'holiday_date': d,
                      'name': n,
                    });
                  });
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                      content: Text('Holiday added successfully.'),
                      backgroundColor: AppTheme.successText,
                    ),
                  );
                }
              } catch (e) {
                if (mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: Text('Error adding holiday: $e'),
                      backgroundColor: AppTheme.dangerText,
                    ),
                  );
                }
              }
            },
            child: const Text('Add Holiday'),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final tabs = [
      'General',
      'Working time',
      'Rules & permissions',
      'Holidays (${_holidays.length})',
    ];

    return Scaffold(
      backgroundColor: AppTheme.scaffoldBg,
      appBar: ModuleAppBar(
        title: 'Settings',
        subtitle: 'Workspace & company preferences',
        actions: [
          if (_selectedTab != 3)
            TextButton(
              onPressed: _isSaving ? null : _handleSave,
              child: _isSaving
                  ? const SizedBox(
                      height: 16,
                      width: 16,
                      child: CircularProgressIndicator(strokeWidth: 2),
                    )
                  : Text(
                      'Save',
                      style: AppTheme.body(
                        fontSize: 14,
                        fontWeight: FontWeight.w700,
                        color: AppTheme.royalBlue,
                      ),
                    ),
            ),
          IconButton(
            icon: const Icon(Icons.refresh, color: AppTheme.deepSlate),
            tooltip: 'Refresh',
            onPressed: _fetchSettings,
          ),
        ],
      ),
      body: _isLoading
          ? const Center(
              child: CircularProgressIndicator(color: AppTheme.royalBlue),
            )
          : _errorMessage != null
          ? Center(
              child: Text(
                _errorMessage!,
                style: AppTheme.body(fontSize: 14, color: AppTheme.dangerText),
              ),
            )
          : Column(
              children: [
                // Sub Tabs
                Container(
                  color: AppTheme.pureWhite,
                  padding: const EdgeInsets.symmetric(vertical: 8.0),
                  child: SingleChildScrollView(
                    scrollDirection: Axis.horizontal,
                    padding: const EdgeInsets.symmetric(horizontal: 16.0),
                    child: Row(
                      children: List.generate(tabs.length, (idx) {
                        final isSelected = _selectedTab == idx;
                        return Padding(
                          padding: const EdgeInsets.only(right: 8.0),
                          child: ChoiceChip(
                            label: Text(tabs[idx]),
                            selected: isSelected,
                            selectedColor: AppTheme.royalBlue,
                            backgroundColor: const Color(0xFFF1F5F9),
                            labelStyle: AppTheme.body(
                              fontSize: 12,
                              fontWeight: isSelected
                                  ? FontWeight.w700
                                  : FontWeight.w600,
                              color: isSelected
                                  ? AppTheme.pureWhite
                                  : AppTheme.deepSlate,
                            ),
                            onSelected: (val) {
                              if (val) setState(() => _selectedTab = idx);
                            },
                          ),
                        );
                      }),
                    ),
                  ),
                ),
                const Divider(height: 1, color: AppTheme.borderSubtle),

                // Active Tab Content
                Expanded(
                  child: ListView(
                    padding: const EdgeInsets.all(16.0),
                    children: [
                      if (_selectedTab == 0) _buildGeneralTab(),
                      if (_selectedTab == 1) _buildWorkingTab(),
                      if (_selectedTab == 2) _buildRulesTab(),
                      if (_selectedTab == 3) _buildHolidaysTab(),
                    ],
                  ),
                ),
              ],
            ),
    );
  }

  Widget _buildGeneralTab() {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: AppTheme.pureWhite,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppTheme.borderSubtle),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Company & Display',
            style: AppTheme.heading(
              fontSize: 16,
              fontWeight: FontWeight.w700,
              color: AppTheme.deepSlate,
            ),
          ),
          const SizedBox(height: 16),
          _buildField('Company name', _companyNameController),
          const SizedBox(height: 16),
          _buildCompanyLogoSection(),
          const SizedBox(height: 16),
          _buildField('Company timezone', _timezoneController),
          const SizedBox(height: 12),
          _buildField('Currency code', _currencyController),
        ],
      ),
    );
  }

  Widget _buildCompanyLogoSection() {
    final hasExistingLogo =
        _currentLogoUrl != null &&
        _currentLogoUrl!.trim().isNotEmpty &&
        !_removeLogo;
    final hasNewLogo =
        _selectedLogoBytes != null && _selectedLogoBytes!.isNotEmpty;

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: const Color(0xFFF8FAFC),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppTheme.borderSubtle),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Icon(
                Icons.business_outlined,
                size: 18,
                color: AppTheme.royalBlue,
              ),
              const SizedBox(width: 8),
              Text(
                'Company logo',
                style: AppTheme.heading(
                  fontSize: 14,
                  fontWeight: FontWeight.w700,
                  color: AppTheme.deepSlate,
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),

          // Logo Preview Container with sleek dark background (#0F172A)
          Container(
            width: double.infinity,
            height: 76,
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
            decoration: BoxDecoration(
              color: const Color(0xFF0F172A),
              borderRadius: BorderRadius.circular(10),
              border: Border.all(color: const Color(0xFF1E293B)),
            ),
            child: Center(
              child: hasNewLogo
                  ? Image.memory(
                      Uint8List.fromList(_selectedLogoBytes!),
                      fit: BoxFit.contain,
                    )
                  : hasExistingLogo
                  ? Image.network(
                      ApiClient().resolveMediaUrl(_currentLogoUrl!) ??
                          _currentLogoUrl!,
                      fit: BoxFit.contain,
                      errorBuilder: (context, error, stackTrace) =>
                          _buildLogoPlaceholder(),
                    )
                  : _buildLogoPlaceholder(),
            ),
          ),
          const SizedBox(height: 12),

          // Remove logo checkbox (when a logo exists or is chosen)
          if (hasExistingLogo || hasNewLogo) ...[
            InkWell(
              onTap: () {
                setState(() {
                  _removeLogo = !_removeLogo;
                  if (_removeLogo) {
                    _selectedLogoName = null;
                    _selectedLogoPath = null;
                    _selectedLogoBytes = null;
                  }
                });
              },
              borderRadius: BorderRadius.circular(6),
              child: Padding(
                padding: const EdgeInsets.symmetric(vertical: 4),
                child: Row(
                  children: [
                    SizedBox(
                      width: 20,
                      height: 20,
                      child: Checkbox(
                        value: _removeLogo,
                        activeColor: AppTheme.dangerText,
                        materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
                        onChanged: (val) {
                          setState(() {
                            _removeLogo = val ?? false;
                            if (_removeLogo) {
                              _selectedLogoName = null;
                              _selectedLogoPath = null;
                              _selectedLogoBytes = null;
                            }
                          });
                        },
                      ),
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        'Remove company logo',
                        style: AppTheme.body(
                          fontSize: 13,
                          fontWeight: FontWeight.w600,
                          color: _removeLogo
                              ? AppTheme.dangerText
                              : AppTheme.deepSlate,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 10),
          ],

          // Upload button & selected file row
          Row(
            children: [
              OutlinedButton.icon(
                onPressed: _handlePickLogo,
                icon: const Icon(Icons.upload_file, size: 16),
                label: const Text('Choose File'),
                style: OutlinedButton.styleFrom(
                  foregroundColor: AppTheme.deepSlate,
                  side: const BorderSide(color: AppTheme.borderSubtle),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(8),
                  ),
                  padding: const EdgeInsets.symmetric(
                    horizontal: 14,
                    vertical: 10,
                  ),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Text(
                  _selectedLogoName ??
                      (hasExistingLogo
                          ? 'Current logo active'
                          : 'No file chosen'),
                  style: AppTheme.body(
                    fontSize: 12,
                    color: _selectedLogoName != null
                        ? AppTheme.royalBlue
                        : AppTheme.mutedSlate,
                    fontWeight: _selectedLogoName != null
                        ? FontWeight.w600
                        : FontWeight.w400,
                  ),
                  overflow: TextOverflow.ellipsis,
                ),
              ),
            ],
          ),
          const SizedBox(height: 10),

          // Guideline text matching website
          Text(
            'Replaces the Projeqta logo in the sidebar for your workspace. Shown on a dark background, so a white or light logo works best. JPG, PNG or WebP, max 2 MB.',
            style: AppTheme.body(
              fontSize: 11,
              color: AppTheme.mutedSlate,
              height: 1.4,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildLogoPlaceholder() {
    return FittedBox(
      fit: BoxFit.scaleDown,
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          const Icon(Icons.image_outlined, size: 18, color: Color(0xFF64748B)),
          const SizedBox(width: 8),
          Text(
            'No company logo (default Projeqta)',
            style: AppTheme.mono(fontSize: 12, color: const Color(0xFF94A3B8)),
          ),
        ],
      ),
    );
  }

  Widget _buildWorkingTab() {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: AppTheme.pureWhite,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppTheme.borderSubtle),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Working Time & Reports',
            style: AppTheme.heading(
              fontSize: 16,
              fontWeight: FontWeight.w700,
              color: AppTheme.deepSlate,
            ),
          ),
          const SizedBox(height: 16),
          _buildField('Work start time (HH:MM)', _startController),
          const SizedBox(height: 12),
          _buildField('Work end time (HH:MM)', _endController),
          const SizedBox(height: 12),
          _buildField('Daily report deadline', _deadlineController),
          const SizedBox(height: 12),
          _buildField('Report grace minutes', _graceController),
        ],
      ),
    );
  }

  Widget _buildRulesTab() {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: AppTheme.pureWhite,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppTheme.borderSubtle),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Rules & Permissions',
            style: AppTheme.heading(
              fontSize: 16,
              fontWeight: FontWeight.w700,
              color: AppTheme.deepSlate,
            ),
          ),
          const SizedBox(height: 16),
          SwitchListTile(
            title: Text(
              'Staff can set progress',
              style: AppTheme.body(
                fontSize: 13,
                fontWeight: FontWeight.w600,
                color: AppTheme.deepSlate,
              ),
            ),
            subtitle: Text(
              'Allow staff members to update task completion percentages.',
              style: AppTheme.body(fontSize: 11, color: AppTheme.mutedSlate),
            ),
            value: _staffCanSetProgress,
            activeThumbColor: AppTheme.royalBlue,
            onChanged: (val) => setState(() => _staffCanSetProgress = val),
          ),
          const Divider(height: 1),
          SwitchListTile(
            title: Text(
              'Staff can upload attachments',
              style: AppTheme.body(
                fontSize: 13,
                fontWeight: FontWeight.w600,
                color: AppTheme.deepSlate,
              ),
            ),
            subtitle: Text(
              'Allow team members to upload project and task files.',
              style: AppTheme.body(fontSize: 11, color: AppTheme.mutedSlate),
            ),
            value: _staffCanUpload,
            activeThumbColor: AppTheme.royalBlue,
            onChanged: (val) => setState(() => _staffCanUpload = val),
          ),
          const Divider(height: 1),
          SwitchListTile(
            title: Text(
              'Require completion notes',
              style: AppTheme.body(
                fontSize: 13,
                fontWeight: FontWeight.w600,
                color: AppTheme.deepSlate,
              ),
            ),
            subtitle: Text(
              'Require descriptive remarks before moving a task to complete.',
              style: AppTheme.body(fontSize: 11, color: AppTheme.mutedSlate),
            ),
            value: _requireCompletionNotes,
            activeThumbColor: AppTheme.royalBlue,
            onChanged: (val) => setState(() => _requireCompletionNotes = val),
          ),
        ],
      ),
    );
  }

  Widget _buildHolidaysTab() {
    return Column(
      children: [
        Wrap(
          alignment: WrapAlignment.spaceBetween,
          crossAxisAlignment: WrapCrossAlignment.center,
          spacing: 8,
          runSpacing: 8,
          children: [
            Text(
              'Company Holidays',
              style: AppTheme.heading(
                fontSize: 16,
                fontWeight: FontWeight.w700,
                color: AppTheme.deepSlate,
              ),
            ),
            FilledButton.icon(
              onPressed: _showAddHolidayDialog,
              icon: const Icon(Icons.add, size: 16),
              label: const Text('Add Holiday'),
              style: FilledButton.styleFrom(
                backgroundColor: AppTheme.royalBlue,
              ),
            ),
          ],
        ),
        const SizedBox(height: 12),
        if (_holidays.isEmpty)
          Container(
            padding: const EdgeInsets.all(32),
            decoration: BoxDecoration(
              color: AppTheme.pureWhite,
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: AppTheme.borderSubtle),
            ),
            child: Center(
              child: Text(
                'No company holidays configured.',
                style: AppTheme.body(fontSize: 13, color: AppTheme.mutedSlate),
              ),
            ),
          )
        else
          ..._holidays.map(
            (h) => Container(
              margin: const EdgeInsets.only(bottom: 8),
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: AppTheme.pureWhite,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: AppTheme.borderSubtle),
              ),
              child: Row(
                children: [
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 8,
                      vertical: 4,
                    ),
                    decoration: BoxDecoration(
                      color: const Color(0xFFCCFBF1),
                      borderRadius: BorderRadius.circular(6),
                    ),
                    child: Text(
                      h['holiday_date']?.toString() ?? '',
                      style: AppTheme.mono(
                        fontSize: 11,
                        fontWeight: FontWeight.w700,
                        color: const Color(0xFF0F766E),
                      ),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Text(
                      h['name']?.toString() ?? '',
                      style: AppTheme.body(
                        fontSize: 13,
                        fontWeight: FontWeight.w700,
                        color: AppTheme.deepSlate,
                      ),
                    ),
                  ),
                  IconButton(
                    icon: const Icon(
                      Icons.delete_outline,
                      size: 18,
                      color: AppTheme.dangerText,
                    ),
                    onPressed: () {
                      final id = h['id'];
                      if (id != null) {
                        _handleDeleteHoliday(
                          id is int ? id : int.parse(id.toString()),
                          h['name']?.toString() ?? 'Holiday',
                        );
                      }
                    },
                  ),
                ],
              ),
            ),
          ),
      ],
    );
  }

  Widget _buildField(String label, TextEditingController ctrl) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: AppTheme.body(
            fontSize: 12,
            fontWeight: FontWeight.w600,
            color: AppTheme.deepSlate,
          ),
        ),
        const SizedBox(height: 6),
        TextField(
          controller: ctrl,
          decoration: InputDecoration(hintText: label),
        ),
      ],
    );
  }
}
