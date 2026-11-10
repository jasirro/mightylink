import 'package:flutter/material.dart';
import 'package:uuid/uuid.dart';
import '../models/group.dart';
import '../models/saved_link.dart';
import 'package:metadata_fetch/metadata_fetch.dart';
import '../services/db_service.dart';
import '../services/google_drive_sync_service.dart';
import '../theme/app_colors.dart';

class AddLinkScreen extends StatefulWidget {
  final String? initialUrl;
  final SavedLink? existingLink;
  const AddLinkScreen({super.key, this.initialUrl, this.existingLink});

  @override
  State<AddLinkScreen> createState() => _AddLinkScreenState();
}

class _AddLinkScreenState extends State<AddLinkScreen> {
  late TextEditingController _titleController;
  late TextEditingController _urlController;
  late TextEditingController _noteController;
  String? _selectedGroupId;
  String? _previousSelectedGroupId;
  bool _isFavorite = false;
  bool _isLoadingMetadata = false;

  @override
  void initState() {
    super.initState();
    final link = widget.existingLink;
    _titleController = TextEditingController(text: link?.title ?? '');
    _urlController = TextEditingController(text: link?.url ?? widget.initialUrl ?? '');
    _noteController = TextEditingController(text: link?.note ?? '');
    if (link != null) {
      _selectedGroupId = link.groupId;
      _previousSelectedGroupId = link.groupId;
      _isFavorite = link.isFavorite;
    }
    if (widget.initialUrl != null && widget.initialUrl!.isNotEmpty) {
      _fetchMetadata(widget.initialUrl!);
    }
  }

  Future<void> _fetchMetadata(String url) async {
    setState(() => _isLoadingMetadata = true);
    try {
      final data = await MetadataFetch.extract(url);
      if (data != null && mounted) {
        if (_titleController.text.isEmpty && data.title != null) {
          setState(() {
            _titleController.text = data.title!;
          });
        }
        if (_noteController.text.isEmpty && data.description != null) {
          setState(() {
            _noteController.text = data.description!;
          });
        }
      }
    } catch (e) {
      debugPrint('Error fetching metadata: $e');
    } finally {
      if (mounted) setState(() => _isLoadingMetadata = false);
    }
  }

  @override
  void dispose() {
    _titleController.dispose();
    _urlController.dispose();
    _noteController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final groupsBox = DbService.groupsBox;
    final groups = groupsBox.values.toList();

    if (groups.isNotEmpty && _selectedGroupId == null) {
      _selectedGroupId = groups.first.id;
      _previousSelectedGroupId = groups.first.id;
    }

    return Container(
      decoration: const BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
      ),
      child: SafeArea(
        child: SingleChildScrollView(
          padding: EdgeInsets.only(
            bottom: MediaQuery.of(context).viewInsets.bottom + 20,
            left: 24,
            right: 24,
            top: 16,
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Center(
                child: Container(
                  width: 44,
                  height: 4,
                  decoration: BoxDecoration(
                    color: Colors.grey.shade300,
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
              ),
              const SizedBox(height: 18),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    widget.existingLink != null ? 'Edit Link' : 'Save New Link',
                    style: const TextStyle(
                      fontSize: 22,
                      fontWeight: FontWeight.w800,
                      color: AppColors.cardTitle,
                      letterSpacing: -0.5,
                    ),
                  ),
                  IconButton(
                    icon: const Icon(Icons.close_rounded, color: AppColors.iconMuted),
                    onPressed: () => Navigator.pop(context),
                  ),
                ],
              ),
              const SizedBox(height: 18),
              TextField(
                controller: _urlController,
                keyboardType: TextInputType.url,
                style: const TextStyle(color: AppColors.cardTitle, fontWeight: FontWeight.w500),
                decoration: InputDecoration(
                  labelText: 'URL Link',
                  hintText: 'https://...',
                  filled: true,
                  fillColor: AppColors.surfaceVioletTint,
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(16),
                    borderSide: BorderSide.none,
                  ),
                  prefixIcon: const Icon(Icons.link_rounded, color: AppColors.primaryViolet),
                  suffixIcon: _isLoadingMetadata
                      ? const SizedBox(
                          width: 20,
                          height: 20,
                          child: Padding(
                            padding: EdgeInsets.all(12.0),
                            child: CircularProgressIndicator(strokeWidth: 2),
                          ),
                        )
                      : IconButton(
                          icon: const Icon(Icons.autorenew_rounded, color: AppColors.primaryViolet),
                          tooltip: 'Fetch Title & Details',
                          onPressed: () {
                            if (_urlController.text.isNotEmpty) {
                              _fetchMetadata(_urlController.text.trim());
                            }
                          },
                        ),
                ),
                onSubmitted: (url) {
                  if (url.isNotEmpty) _fetchMetadata(url.trim());
                },
              ),
              const SizedBox(height: 14),
              TextField(
                controller: _titleController,
                style: const TextStyle(color: AppColors.cardTitle, fontWeight: FontWeight.w600),
                decoration: InputDecoration(
                  labelText: 'Title',
                  hintText: 'e.g. Flutter Documentation',
                  filled: true,
                  fillColor: AppColors.surfaceVioletTint,
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(16),
                    borderSide: BorderSide.none,
                  ),
                  prefixIcon: const Icon(Icons.title_rounded, color: AppColors.primaryViolet),
                ),
              ),
              const SizedBox(height: 14),
              DropdownButtonFormField<String>(
                key: ValueKey(_selectedGroupId),
                initialValue: _selectedGroupId,
                style: const TextStyle(color: AppColors.cardTitle, fontWeight: FontWeight.w600),
                decoration: InputDecoration(
                  labelText: 'Workspace',
                  filled: true,
                  fillColor: AppColors.surfaceVioletTint,
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(16),
                    borderSide: BorderSide.none,
                  ),
                  prefixIcon: const Icon(Icons.folder_rounded, color: AppColors.primaryViolet),
                ),
                items: [
                  ...groups.map((g) => DropdownMenuItem(value: g.id, child: Text(g.name))),
                  const DropdownMenuItem(
                    value: '_add_new_group_',
                    child: Row(
                      children: [
                        Icon(Icons.add_circle_outline, size: 18, color: AppColors.primaryViolet),
                        SizedBox(width: 8),
                        Text('Create New Workspace...', style: TextStyle(fontWeight: FontWeight.bold, color: AppColors.primaryViolet)),
                      ],
                    ),
                  ),
                ],
                onChanged: (val) {
                  if (val == '_add_new_group_') {
                    _showAddGroupDialog(context);
                  } else {
                    setState(() {
                      _selectedGroupId = val;
                      _previousSelectedGroupId = val;
                    });
                  }
                },
              ),
              const SizedBox(height: 14),
              TextField(
                controller: _noteController,
                style: const TextStyle(color: AppColors.cardTitle),
                decoration: InputDecoration(
                  labelText: 'Notes (optional)',
                  hintText: 'Add context or tags...',
                  filled: true,
                  fillColor: AppColors.surfaceVioletTint,
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(16),
                    borderSide: BorderSide.none,
                  ),
                  prefixIcon: const Icon(Icons.notes_rounded, color: AppColors.primaryViolet),
                ),
                maxLines: 2,
              ),
              const SizedBox(height: 10),
              SwitchListTile(
                title: const Text(
                  'Mark as Favorite',
                  style: TextStyle(fontWeight: FontWeight.w600, color: AppColors.cardTitle),
                ),
                value: _isFavorite,
                activeThumbColor: AppColors.primaryViolet,
                onChanged: (val) {
                  setState(() {
                    _isFavorite = val;
                  });
                },
                secondary: Icon(
                  _isFavorite ? Icons.favorite_rounded : Icons.favorite_border_rounded,
                  color: _isFavorite ? Colors.red : AppColors.iconMuted,
                ),
                contentPadding: EdgeInsets.zero,
              ),
              const SizedBox(height: 20),
              // Golden Yellow CTA Button matching Figma
              SizedBox(
                height: 52,
                child: FilledButton(
                  onPressed: () async {
                    if (_titleController.text.isNotEmpty && _urlController.text.isNotEmpty && _selectedGroupId != null) {
                      if (widget.existingLink != null) {
                        final link = widget.existingLink!;
                        link.title = _titleController.text.trim();
                        link.url = _urlController.text.trim();
                        link.note = _noteController.text.trim();
                        link.groupId = _selectedGroupId!;
                        link.isFavorite = _isFavorite;
                        await link.save();
                      } else {
                        final link = SavedLink(
                          id: const Uuid().v4(),
                          title: _titleController.text.trim(),
                          url: _urlController.text.trim(),
                          note: _noteController.text.trim(),
                          groupId: _selectedGroupId!,
                          isFavorite: _isFavorite,
                          createdAt: DateTime.now(),
                        );
                        await DbService.linksBox.put(link.id, link);
                      }
                      
                      GoogleDriveSyncService.scheduleDebouncedSync();

                      if (context.mounted) {
                        Navigator.pop(context);
                      }
                    }
                  },
                  style: FilledButton.styleFrom(
                    backgroundColor: AppColors.accentYellow,
                    foregroundColor: AppColors.yellowButtonText,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(16),
                    ),
                  ),
                  child: Text(
                    widget.existingLink != null ? 'Update Link' : 'Save Link',
                    style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w800),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  void _showAddGroupDialog(BuildContext context) {
    final controller = TextEditingController();
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: Colors.white,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
        title: const Text(
          'Create New Workspace',
          style: TextStyle(fontWeight: FontWeight.w800, color: AppColors.cardTitle),
        ),
        content: TextField(
          controller: controller,
          decoration: InputDecoration(
            hintText: 'Workspace Name',
            filled: true,
            fillColor: AppColors.surfaceVioletTint,
            border: OutlineInputBorder(borderRadius: BorderRadius.circular(14), borderSide: BorderSide.none),
          ),
          autofocus: true,
        ),
        actionsPadding: const EdgeInsets.fromLTRB(20, 0, 20, 20),
        actions: [
          TextButton(
            onPressed: () {
              Navigator.pop(context);
              setState(() {
                _selectedGroupId = _previousSelectedGroupId;
              });
            },
            child: const Text('Cancel', style: TextStyle(color: AppColors.cardSubtitle)),
          ),
          FilledButton(
            onPressed: () async {
              if (controller.text.trim().isNotEmpty) {
                final group = Group(
                  id: const Uuid().v4(),
                  name: controller.text.trim(),
                  createdAt: DateTime.now(),
                );
                await DbService.groupsBox.put(group.id, group);
                GoogleDriveSyncService.scheduleDebouncedSync();
                if (context.mounted) Navigator.pop(context);
                setState(() {
                  _selectedGroupId = group.id;
                  _previousSelectedGroupId = group.id;
                });
              }
            },
            style: FilledButton.styleFrom(
              backgroundColor: AppColors.accentYellow,
              foregroundColor: AppColors.yellowButtonText,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
            ),
            child: const Text('Create'),
          ),
        ],
      ),
    );
  }
}
