import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import '../../../core/app_date_utils.dart';
import '../../../core/theme.dart';
import '../../../models/project_model.dart';
import '../../../services/project_service.dart';

class ProjectAttachmentsSection extends StatefulWidget {
  final int projectId;
  final List<AttachmentModel> attachments;
  final bool canUpload;
  final void Function(AttachmentModel attachment)? onDownload;
  final VoidCallback? onUploaded;
  final Future<AttachmentModel> Function()? onCustomUpload;

  const ProjectAttachmentsSection({
    super.key,
    this.projectId = 0,
    required this.attachments,
    this.canUpload = true,
    this.onDownload,
    this.onUploaded,
    this.onCustomUpload,
  });

  @override
  State<ProjectAttachmentsSection> createState() =>
      _ProjectAttachmentsSectionState();
}

class _ProjectAttachmentsSectionState extends State<ProjectAttachmentsSection> {
  final ProjectService _projectService = ProjectService();
  late List<AttachmentModel> _attachments;
  bool _isUploading = false;

  @override
  void initState() {
    super.initState();
    _attachments = List.from(widget.attachments);
  }

  @override
  void didUpdateWidget(covariant ProjectAttachmentsSection oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.attachments != oldWidget.attachments) {
      _attachments = List.from(widget.attachments);
    }
  }

  IconData _getFileIcon(String mimeType, String fileName) {
    final lowerMime = mimeType.toLowerCase();
    final lowerName = fileName.toLowerCase();

    if (lowerMime.contains('pdf') || lowerName.endsWith('.pdf')) {
      return Icons.picture_as_pdf_outlined;
    }
    if (lowerMime.startsWith('image/') ||
        lowerName.endsWith('.png') ||
        lowerName.endsWith('.jpg') ||
        lowerName.endsWith('.jpeg') ||
        lowerName.endsWith('.svg') ||
        lowerName.endsWith('.gif')) {
      return Icons.image_outlined;
    }
    if (lowerMime.contains('zip') ||
        lowerMime.contains('compressed') ||
        lowerName.endsWith('.zip') ||
        lowerName.endsWith('.rar') ||
        lowerName.endsWith('.tar') ||
        lowerName.endsWith('.gz')) {
      return Icons.folder_zip_outlined;
    }
    if (lowerMime.contains('sheet') ||
        lowerMime.contains('excel') ||
        lowerName.endsWith('.csv') ||
        lowerName.endsWith('.xls') ||
        lowerName.endsWith('.xlsx')) {
      return Icons.table_chart_outlined;
    }
    if (lowerMime.contains('json') ||
        lowerMime.contains('text/javascript') ||
        lowerName.endsWith('.dart') ||
        lowerName.endsWith('.php') ||
        lowerName.endsWith('.sql') ||
        lowerName.endsWith('.js') ||
        lowerName.endsWith('.ts')) {
      return Icons.code_outlined;
    }
    return Icons.insert_drive_file_outlined;
  }

  Color _getIconColor(String mimeType, String fileName) {
    final lowerMime = mimeType.toLowerCase();
    final lowerName = fileName.toLowerCase();

    if (lowerMime.contains('pdf') || lowerName.endsWith('.pdf')) {
      return const Color(0xFFDC2626);
    }
    if (lowerMime.startsWith('image/') ||
        lowerName.endsWith('.png') ||
        lowerName.endsWith('.jpg') ||
        lowerName.endsWith('.jpeg')) {
      return const Color(0xFF7C3AED);
    }
    if (lowerMime.contains('zip') || lowerName.endsWith('.zip')) {
      return const Color(0xFFD97706);
    }
    if (lowerMime.contains('sheet') || lowerName.endsWith('.csv')) {
      return const Color(0xFF059669);
    }
    return AppTheme.royalBlue;
  }

  Future<void> _pickAndUpload() async {
    if (_isUploading) return;

    if (widget.onCustomUpload != null) {
      setState(() => _isUploading = true);
      try {
        final newAtt = await widget.onCustomUpload!();
        if (mounted) {
          setState(() {
            _attachments.insert(0, newAtt);
            _isUploading = false;
          });
          widget.onUploaded?.call();
        }
      } catch (e) {
        if (mounted) {
          setState(() => _isUploading = false);
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('Upload failed: ${e.toString()}'),
              backgroundColor: AppTheme.dangerText,
            ),
          );
        }
      }
      return;
    }

    try {
      final result = await FilePicker.pickFiles(
        type: FileType.custom,
        allowedExtensions: [
          'pdf',
          'doc',
          'docx',
          'xls',
          'xlsx',
          'ppt',
          'pptx',
          'txt',
          'csv',
          'zip',
          'png',
          'jpg',
          'jpeg',
        ],
      );

      if (result.isEmpty) return;

      final pickedFile = result.first;
      final fileName = pickedFile.name;
      final filePath = pickedFile.path;
      final fileLength = await pickedFile.xFile.length();
      final fileBytes = await pickedFile.xFile.readAsBytes();

      if (!mounted) return;

      final confirm = await showModalBottomSheet<bool>(
        context: context,
        backgroundColor: AppTheme.pureWhite,
        shape: const RoundedRectangleBorder(
          borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
        ),
        builder: (ctx) => Padding(
          padding: const EdgeInsets.all(20),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Upload Project Attachment',
                style: AppTheme.heading(
                  fontSize: 16,
                  fontWeight: FontWeight.w700,
                ),
              ),
              const SizedBox(height: 12),
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: AppTheme.scaffoldBg,
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: AppTheme.borderSubtle),
                ),
                child: Row(
                  children: [
                    const Icon(
                      Icons.insert_drive_file_outlined,
                      color: AppTheme.royalBlue,
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            fileName,
                            style: AppTheme.body(fontWeight: FontWeight.w700),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                          Text(
                            fileLength > 0
                                ? '${(fileLength / 1024).toStringAsFixed(1)} KB'
                                : '',
                            style: AppTheme.mono(
                              fontSize: 11,
                              color: AppTheme.mutedSlate,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 20),
              Row(
                children: [
                  Expanded(
                    child: OutlinedButton(
                      onPressed: () => Navigator.pop(ctx, false),
                      style: OutlinedButton.styleFrom(
                        foregroundColor: AppTheme.deepSlate,
                        side: const BorderSide(color: AppTheme.borderSubtle),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(8),
                        ),
                      ),
                      child: const Text('Cancel'),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: ElevatedButton.icon(
                      onPressed: () => Navigator.pop(ctx, true),
                      icon: const Icon(Icons.cloud_upload_outlined, size: 18),
                      label: const Text('Upload'),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppTheme.navyBlue,
                        foregroundColor: AppTheme.pureWhite,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(8),
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      );

      if (confirm != true || !mounted) return;

      setState(() => _isUploading = true);

      final newAtt = await _projectService.uploadAttachment(
        entityType: 'project',
        entityId: widget.projectId,
        filePath: filePath,
        fileBytes: fileBytes,
        fileName: fileName,
      );

      if (mounted) {
        setState(() {
          _attachments.insert(0, newAtt);
          _isUploading = false;
        });
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              'Attached "$fileName" successfully.',
              style: AppTheme.body(
                color: AppTheme.pureWhite,
                fontWeight: FontWeight.w600,
              ),
            ),
            backgroundColor: AppTheme.navyBlue,
          ),
        );
        widget.onUploaded?.call();
      }
    } catch (e) {
      if (mounted) {
        setState(() => _isUploading = false);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              'Upload failed: ${e.toString().replaceAll('ApiException:', '').trim()}',
              style: AppTheme.body(color: AppTheme.pureWhite),
            ),
            backgroundColor: AppTheme.dangerText,
            duration: const Duration(seconds: 4),
          ),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: AppTheme.pureWhite,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppTheme.borderSubtle, width: 1),
        boxShadow: const [AppTheme.softShadow],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Section Header
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 16, 16, 12),
            child: Row(
              children: [
                Expanded(
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      const Icon(
                        Icons.attach_file,
                        size: 20,
                        color: AppTheme.navyBlue,
                      ),
                      const SizedBox(width: 8),
                      Flexible(
                        child: Text(
                          'Files & Attachments',
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: AppTheme.heading(
                            fontSize: 15,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                      ),
                      const SizedBox(width: 6),
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 8,
                          vertical: 2,
                        ),
                        decoration: BoxDecoration(
                          color: AppTheme.scaffoldBg,
                          borderRadius: BorderRadius.circular(10),
                          border: Border.all(color: AppTheme.borderSubtle),
                        ),
                        child: Text(
                          '${_attachments.length}',
                          style: AppTheme.mono(
                            fontSize: 12,
                            fontWeight: FontWeight.w700,
                            color: AppTheme.navyBlue,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
                if (widget.canUpload && widget.projectId > 0)
                  _isUploading
                      ? const Padding(
                          padding: EdgeInsets.symmetric(horizontal: 12),
                          child: SizedBox(
                            width: 18,
                            height: 18,
                            child: CircularProgressIndicator(
                              strokeWidth: 2,
                              color: AppTheme.royalBlue,
                            ),
                          ),
                        )
                      : TextButton.icon(
                          onPressed: _pickAndUpload,
                          icon: const Icon(Icons.add, size: 16),
                          label: const Text('Attach File'),
                          style: TextButton.styleFrom(
                            foregroundColor: AppTheme.royalBlue,
                            textStyle: AppTheme.body(
                              fontSize: 12,
                              fontWeight: FontWeight.w700,
                            ),
                            padding: const EdgeInsets.symmetric(
                              horizontal: 8,
                              vertical: 4,
                            ),
                          ),
                        ),
              ],
            ),
          ),
          const Divider(height: 1, color: AppTheme.borderSubtle),

          if (_attachments.isEmpty)
            Padding(
              padding: const EdgeInsets.all(24),
              child: Center(
                child: Column(
                  children: [
                    const Icon(
                      Icons.folder_open_outlined,
                      size: 36,
                      color: AppTheme.lightSlate,
                    ),
                    const SizedBox(height: 8),
                    Text(
                      'No files attached to this project.',
                      style: AppTheme.body(
                        fontSize: 13,
                        color: AppTheme.mutedSlate,
                      ),
                    ),
                  ],
                ),
              ),
            )
          else
            ListView.separated(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              itemCount: _attachments.length,
              separatorBuilder: (_, _) =>
                  const Divider(height: 1, color: AppTheme.borderSubtle),
              itemBuilder: (context, index) {
                final att = _attachments[index];
                final icon = _getFileIcon(att.mimeType, att.originalName);
                final iconColor = _getIconColor(att.mimeType, att.originalName);

                return Padding(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 16,
                    vertical: 12,
                  ),
                  child: Row(
                    children: [
                      Container(
                        width: 40,
                        height: 40,
                        decoration: BoxDecoration(
                          color: iconColor.withValues(alpha: 0.08),
                          borderRadius: BorderRadius.circular(8),
                          border: Border.all(
                            color: iconColor.withValues(alpha: 0.2),
                            width: 1,
                          ),
                        ),
                        child: Icon(icon, color: iconColor, size: 22),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              att.originalName,
                              style: AppTheme.body(
                                fontSize: 13,
                                fontWeight: FontWeight.w700,
                                color: AppTheme.deepSlate,
                              ),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            ),
                            const SizedBox(height: 2),
                            Text(
                              '${att.formattedSize}${att.uploaderName != null ? ' • ${att.uploaderName}' : ''}${att.createdAt != null ? ' • ${AppDateUtils.fmtDate(att.createdAt)}' : ''}',
                              style: AppTheme.mono(
                                fontSize: 11,
                                color: AppTheme.mutedSlate,
                              ),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(width: 8),
                      IconButton(
                        icon: const Icon(
                          Icons.download_rounded,
                          size: 20,
                          color: AppTheme.royalBlue,
                        ),
                        tooltip: 'Download file',
                        onPressed: () {
                          if (widget.onDownload != null) {
                            widget.onDownload!(att);
                          } else {
                            ScaffoldMessenger.of(context).showSnackBar(
                              SnackBar(
                                content: Text(
                                  'Downloading ${att.originalName}...',
                                ),
                                duration: const Duration(seconds: 2),
                              ),
                            );
                          }
                        },
                      ),
                    ],
                  ),
                );
              },
            ),
        ],
      ),
    );
  }
}
