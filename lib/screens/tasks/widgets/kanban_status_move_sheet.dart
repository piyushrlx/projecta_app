import 'package:flutter/material.dart';
import '../../../core/theme.dart';
import '../../../models/task_model.dart';

class KanbanStatusMoveSheet extends StatefulWidget {
  final TaskModel task;
  final void Function(String targetStatus, String? note) onSelectStatus;

  const KanbanStatusMoveSheet({
    super.key,
    required this.task,
    required this.onSelectStatus,
  });

  @override
  State<KanbanStatusMoveSheet> createState() => _KanbanStatusMoveSheetState();
}

class _KanbanStatusMoveSheetState extends State<KanbanStatusMoveSheet> {
  String? _selectedTarget;
  String? _noteError;
  final TextEditingController _noteController = TextEditingController();
  final ScrollController _scrollController = ScrollController();

  @override
  void dispose() {
    _noteController.dispose();
    _scrollController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final task = widget.task;
    final statuses = [
      {
        'key': 'not_started',
        'label': 'Not Started',
        'icon': Icons.radio_button_unchecked,
        'color': AppTheme.mutedSlate,
      },
      {
        'key': 'in_progress',
        'label': 'In Progress',
        'icon': Icons.timelapse,
        'color': AppTheme.infoText,
      },
      {
        'key': 'blocked',
        'label': 'Blocked',
        'icon': Icons.error_outline,
        'color': AppTheme.dangerText,
      },
      {
        'key': 'pending_review',
        'label': 'Pending Review',
        'icon': Icons.hourglass_top,
        'color': AppTheme.warningText,
      },
      {
        'key': 'completed',
        'label': 'Completed',
        'icon': Icons.check_circle_outline,
        'color': AppTheme.successText,
      },
    ];

    return Padding(
      padding: EdgeInsets.only(
        bottom: MediaQuery.of(context).viewInsets.bottom,
      ),
      child: Container(
        decoration: const BoxDecoration(
          color: AppTheme.pureWhite,
          borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
        ),
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
        child: SingleChildScrollView(
          controller: _scrollController,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Center(
                child: Container(
                  width: 40,
                  height: 4,
                  decoration: BoxDecoration(
                    color: AppTheme.borderSubtle,
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
              ),
              const SizedBox(height: 12),
              Row(
                children: [
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 6,
                      vertical: 2,
                    ),
                    decoration: BoxDecoration(
                      color: AppTheme.scaffoldBg,
                      borderRadius: BorderRadius.circular(4),
                      border: Border.all(color: AppTheme.borderSubtle),
                    ),
                    child: Text(
                      task.taskCode,
                      style: AppTheme.mono(
                        fontSize: 11,
                        fontWeight: FontWeight.w700,
                        color: AppTheme.deepSlate,
                      ),
                    ),
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      task.title,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: AppTheme.heading(
                        fontSize: 14,
                        fontWeight: FontWeight.w700,
                        color: AppTheme.deepSlate,
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 4),
              Text(
                'Move card to target column',
                style: AppTheme.body(fontSize: 12, color: AppTheme.mutedSlate),
              ),
              const SizedBox(height: 14),
              ...statuses.map((s) {
                final key = s['key'] as String;
                final isCurrent = task.status == key;
                final isAllowed = task.isStatusAllowed(key);
                final isSelected = _selectedTarget == key;
                final color = s['color'] as Color;

                String? disableReason;
                if (!isAllowed && !isCurrent) {
                  if (key == 'completed') {
                    disableReason = 'Staff cannot mark as completed';
                  } else if (key == 'in_progress' && task.isLocked) {
                    disableReason =
                        'Blocked by ${task.openDependenciesCount} dependenc${task.openDependenciesCount == 1 ? 'y' : 'ies'}';
                  } else if (task.isCompleted) {
                    disableReason = 'Completed task is locked';
                  } else {
                    disableReason = 'Transition not allowed';
                  }
                }

                return Padding(
                  padding: const EdgeInsets.only(bottom: 8),
                  child: InkWell(
                    onTap: (!isAllowed || isCurrent)
                        ? null
                        : () {
                            if (key == 'completed' || key == 'pending_review') {
                              setState(() {
                                _selectedTarget = key;
                                _noteError = null;
                              });
                              WidgetsBinding.instance.addPostFrameCallback((_) {
                                if (_scrollController.hasClients) {
                                  _scrollController.animateTo(
                                    _scrollController.position.maxScrollExtent,
                                    duration: const Duration(milliseconds: 250),
                                    curve: Curves.easeOut,
                                  );
                                }
                              });
                            } else {
                              widget.onSelectStatus(key, null);
                            }
                          },
                    borderRadius: BorderRadius.circular(8),
                    child: Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 12,
                        vertical: 10,
                      ),
                      decoration: BoxDecoration(
                        color: isCurrent
                            ? const Color(0xFFF1F5F9)
                            : isSelected
                            ? AppTheme.royalBlue.withValues(alpha: 0.08)
                            : isAllowed
                            ? AppTheme.pureWhite
                            : const Color(0xFFFAFAFA),
                        borderRadius: BorderRadius.circular(8),
                        border: Border.all(
                          color: isSelected
                              ? AppTheme.royalBlue
                              : isCurrent
                              ? AppTheme.borderSubtle
                              : isAllowed
                              ? AppTheme.borderSubtle
                              : const Color(0xFFF1F5F9),
                          width: isSelected ? 1.5 : 1.0,
                        ),
                      ),
                      child: Row(
                        children: [
                          Icon(
                            s['icon'] as IconData,
                            size: 18,
                            color: isAllowed || isCurrent
                                ? color
                                : AppTheme.lightSlate,
                          ),
                          const SizedBox(width: 10),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Row(
                                  children: [
                                    Text(
                                      s['label'] as String,
                                      style: AppTheme.heading(
                                        fontSize: 13,
                                        fontWeight: FontWeight.w600,
                                        color: isAllowed || isCurrent
                                            ? AppTheme.deepSlate
                                            : AppTheme.lightSlate,
                                      ),
                                    ),
                                    if (isCurrent) ...[
                                      const SizedBox(width: 6),
                                      Container(
                                        padding: const EdgeInsets.symmetric(
                                          horizontal: 5,
                                          vertical: 1,
                                        ),
                                        decoration: BoxDecoration(
                                          color: AppTheme.borderSubtle,
                                          borderRadius: BorderRadius.circular(
                                            4,
                                          ),
                                        ),
                                        child: Text(
                                          'Current',
                                          style: AppTheme.mono(
                                            fontSize: 9,
                                            fontWeight: FontWeight.w600,
                                            color: AppTheme.mutedSlate,
                                          ),
                                        ),
                                      ),
                                    ],
                                  ],
                                ),
                                if (disableReason != null)
                                  Text(
                                    disableReason,
                                    style: AppTheme.body(
                                      fontSize: 11,
                                      color: AppTheme.lightSlate,
                                    ),
                                  ),
                              ],
                            ),
                          ),
                          if (isAllowed && !isCurrent)
                            Icon(
                              key == 'completed' || key == 'pending_review'
                                  ? Icons.edit_note
                                  : Icons.arrow_forward_ios,
                              size: 14,
                              color: AppTheme.mutedSlate,
                            ),
                        ],
                      ),
                    ),
                  ),
                );
              }),
              if (_selectedTarget != null) ...[
                const SizedBox(height: 10),
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: const Color(0xFFF8FAFC),
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(color: AppTheme.borderSubtle),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        _selectedTarget == 'completed'
                            ? 'Completion notes required:'
                            : 'Review notes required:',
                        style: AppTheme.heading(
                          fontSize: 12,
                          fontWeight: FontWeight.w600,
                          color: AppTheme.deepSlate,
                        ),
                      ),
                      const SizedBox(height: 6),
                      TextField(
                        controller: _noteController,
                        autofocus: true,
                        maxLines: 2,
                        onChanged: (_) {
                          if (_noteError != null) {
                            setState(() => _noteError = null);
                          }
                        },
                        decoration: InputDecoration(
                          hintText: 'What was delivered?',
                          errorText: _noteError,
                          border: const OutlineInputBorder(),
                          isDense: true,
                          contentPadding: const EdgeInsets.all(8),
                        ),
                      ),
                      const SizedBox(height: 10),
                      SizedBox(
                        width: double.infinity,
                        child: ElevatedButton(
                          onPressed: () {
                            final text = _noteController.text.trim();
                            if (text.isEmpty) {
                              setState(() {
                                _noteError = 'Notes are required before moving.';
                              });
                              return;
                            }
                            widget.onSelectStatus(
                              _selectedTarget!,
                              text,
                            );
                          },
                          style: ElevatedButton.styleFrom(
                            backgroundColor: AppTheme.royalBlue,
                            foregroundColor: Colors.white,
                            padding: const EdgeInsets.symmetric(vertical: 10),
                          ),
                          child: Text(
                            'Confirm Move to ${_selectedTarget == 'completed' ? 'Completed' : 'Pending Review'}',
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }
}
