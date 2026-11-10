import 'package:flutter/material.dart';
import '../../../core/app_date_utils.dart';
import '../../../core/theme.dart';
import '../../../models/project_model.dart';
import '../../../services/project_service.dart';

class ProjectCommentsSection extends StatefulWidget {
  final int projectId;
  final List<CommentModel>? initialComments;
  final bool autoFetch;
  final Future<CommentModel> Function(String body)? onAddComment;

  const ProjectCommentsSection({
    super.key,
    required this.projectId,
    this.initialComments,
    this.autoFetch = true,
    this.onAddComment,
  });

  @override
  State<ProjectCommentsSection> createState() => _ProjectCommentsSectionState();
}

class _ProjectCommentsSectionState extends State<ProjectCommentsSection> {
  final TextEditingController _commentController = TextEditingController();
  final FocusNode _focusNode = FocusNode();
  final ProjectService _projectService = ProjectService();

  late List<CommentModel> _comments;
  bool _isLoadingComments = false;
  bool _isSending = false;
  String? _errorMessage;

  @override
  void initState() {
    super.initState();
    _comments = List.from(widget.initialComments ?? []);
    if (widget.initialComments == null &&
        widget.autoFetch &&
        widget.projectId > 0) {
      _loadComments();
    }
  }

  Future<void> _loadComments() async {
    setState(() => _isLoadingComments = true);
    try {
      final fetched = await _projectService.getComments(
        'project',
        widget.projectId,
      );
      if (mounted) {
        setState(() {
          _comments = fetched;
          _isLoadingComments = false;
        });
      }
    } catch (_) {
      if (mounted) {
        setState(() => _isLoadingComments = false);
      }
    }
  }

  @override
  void didUpdateWidget(covariant ProjectCommentsSection oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.initialComments != oldWidget.initialComments &&
        widget.initialComments != null) {
      _comments = List.from(widget.initialComments!);
    }
  }

  @override
  void dispose() {
    _commentController.dispose();
    _focusNode.dispose();
    super.dispose();
  }

  Future<void> _submitComment() async {
    final text = _commentController.text.trim();
    if (text.isEmpty || _isSending) return;

    setState(() {
      _isSending = true;
      _errorMessage = null;
    });

    try {
      final CommentModel newComment;
      if (widget.onAddComment != null) {
        newComment = await widget.onAddComment!(text);
      } else {
        newComment = await _projectService.addComment(
          entityType: 'project',
          entityId: widget.projectId,
          body: text,
        );
      }

      if (mounted) {
        setState(() {
          _comments.add(newComment);
          _commentController.clear();
          _isSending = false;
        });
        _focusNode.unfocus();
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _isSending = false;
          _errorMessage = e.toString().replaceAll('ApiException:', '').trim();
        });
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              _errorMessage ?? 'Failed to post comment.',
              style: AppTheme.body(color: AppTheme.pureWhite),
            ),
            backgroundColor: AppTheme.dangerText,
            duration: const Duration(seconds: 3),
          ),
        );
      }
    }
  }

  String _getInitials(String name) {
    final parts = name.trim().split(RegExp(r'\s+'));
    if (parts.isEmpty || parts[0].isEmpty) return '?';
    if (parts.length == 1) return parts[0][0].toUpperCase();
    return (parts[0][0] + parts[1][0]).toUpperCase();
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
                const Icon(
                  Icons.chat_bubble_outline,
                  size: 20,
                  color: AppTheme.navyBlue,
                ),
                const SizedBox(width: 8),
                Text(
                  'Discussion & Comments',
                  style: AppTheme.heading(
                    fontSize: 15,
                    fontWeight: FontWeight.w700,
                  ),
                ),
                const Spacer(),
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
                    '${_comments.length}',
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
          const Divider(height: 1, color: AppTheme.borderSubtle),

          // Comments List
          if (_isLoadingComments)
            const Padding(
              padding: EdgeInsets.all(24),
              child: Center(
                child: SizedBox(
                  width: 24,
                  height: 24,
                  child: CircularProgressIndicator(
                    strokeWidth: 2,
                    color: AppTheme.royalBlue,
                  ),
                ),
              ),
            )
          else if (_comments.isEmpty)
            Padding(
              padding: const EdgeInsets.all(24),
              child: Center(
                child: Column(
                  children: [
                    const Icon(
                      Icons.forum_outlined,
                      size: 36,
                      color: AppTheme.lightSlate,
                    ),
                    const SizedBox(height: 8),
                    Text(
                      'No comments yet. Start the conversation.',
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
              itemCount: _comments.length,
              separatorBuilder: (_, _) =>
                  const Divider(height: 1, color: AppTheme.borderSubtle),
              itemBuilder: (context, index) {
                final comment = _comments[index];
                return _buildCommentTile(comment);
              },
            ),

          const Divider(height: 1, color: AppTheme.borderSubtle),

          // Comment Composer Bar
          Padding(
            padding: const EdgeInsets.all(12),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                Expanded(
                  child: TextField(
                    controller: _commentController,
                    focusNode: _focusNode,
                    minLines: 1,
                    maxLines: 4,
                    textCapitalization: TextCapitalization.sentences,
                    style: AppTheme.body(fontSize: 14),
                    decoration: InputDecoration(
                      hintText: 'Write a comment or update...',
                      hintStyle: AppTheme.body(
                        fontSize: 13,
                        color: AppTheme.lightSlate,
                      ),
                      filled: true,
                      fillColor: AppTheme.scaffoldBg,
                      contentPadding: const EdgeInsets.symmetric(
                        horizontal: 14,
                        vertical: 10,
                      ),
                      isDense: true,
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(8),
                        borderSide: const BorderSide(
                          color: AppTheme.borderSubtle,
                        ),
                      ),
                      enabledBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(8),
                        borderSide: const BorderSide(
                          color: AppTheme.borderSubtle,
                        ),
                      ),
                      focusedBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(8),
                        borderSide: const BorderSide(
                          color: AppTheme.royalBlue,
                          width: 1.5,
                        ),
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: 8),
                SizedBox(
                  height: 40,
                  width: 44,
                  child: ElevatedButton(
                    onPressed: _isSending ? null : _submitComment,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppTheme.navyBlue,
                      foregroundColor: AppTheme.pureWhite,
                      padding: EdgeInsets.zero,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(8),
                      ),
                      elevation: 0,
                    ),
                    child: _isSending
                        ? const SizedBox(
                            width: 18,
                            height: 18,
                            child: CircularProgressIndicator(
                              strokeWidth: 2,
                              color: AppTheme.pureWhite,
                            ),
                          )
                        : const Icon(Icons.send_rounded, size: 18),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildCommentTile(CommentModel comment) {
    final initials = _getInitials(comment.userName);
    final isMy = comment.isMyComment;

    return Container(
      color: isMy ? const Color(0xFFF8FAFC) : AppTheme.pureWhite,
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // User Avatar / Initials
          Container(
            width: 34,
            height: 34,
            decoration: BoxDecoration(
              color: isMy ? AppTheme.navyBlue : const Color(0xFFE2E8F0),
              borderRadius: BorderRadius.circular(8),
            ),
            alignment: Alignment.center,
            child: Text(
              initials,
              style: AppTheme.mono(
                fontSize: 12,
                fontWeight: FontWeight.w700,
                color: isMy ? AppTheme.pureWhite : AppTheme.deepSlate,
              ),
            ),
          ),
          const SizedBox(width: 12),
          // Comment Content
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Flexible(
                      child: Text(
                        comment.userName,
                        style: AppTheme.body(
                          fontSize: 13,
                          fontWeight: FontWeight.w700,
                          color: AppTheme.deepSlate,
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                    if (comment.userRole != null &&
                        comment.userRole!.isNotEmpty) ...[
                      const SizedBox(width: 6),
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 6,
                          vertical: 1,
                        ),
                        decoration: BoxDecoration(
                          color: AppTheme.scaffoldBg,
                          borderRadius: BorderRadius.circular(4),
                          border: Border.all(color: AppTheme.borderSubtle),
                        ),
                        child: Text(
                          comment.userRole!.toUpperCase(),
                          style: AppTheme.mono(
                            fontSize: 9,
                            fontWeight: FontWeight.w700,
                            color: AppTheme.mutedSlate,
                          ),
                        ),
                      ),
                    ],
                    const Spacer(),
                    Text(
                      AppDateUtils.timeAgo(comment.createdAt),
                      style: AppTheme.mono(
                        fontSize: 11,
                        color: AppTheme.lightSlate,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 6),
                Text(
                  comment.body,
                  style: AppTheme.body(fontSize: 13, color: AppTheme.deepSlate),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
