import 'package:flutter/material.dart';
import 'package:uuid/uuid.dart';
import '../models/group.dart';
import '../models/saved_link.dart';
import 'package:metadata_fetch/metadata_fetch.dart';
import '../services/db_service.dart';

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

    return SafeArea(
      child: Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 600),
          child: Container(
            padding: EdgeInsets.only(
              bottom: MediaQuery.of(context).viewInsets.bottom,
              left: 24,
              right: 24,
              top: 24,
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text('Save Link', style: Theme.of(context).textTheme.titleLarge),
              IconButton(
                icon: const Icon(Icons.close),
                onPressed: () => Navigator.pop(context),
              ),
            ],
          ),
          const SizedBox(height: 16),
          TextField(
            controller: _urlController,
            decoration: const InputDecoration(
              labelText: 'URL',
              border: OutlineInputBorder(),
              prefixIcon: Icon(Icons.link),
            ),
            keyboardType: TextInputType.url,
          ),
          const SizedBox(height: 16),
          TextField(
            controller: _titleController,
            decoration: const InputDecoration(
              labelText: 'Title',
              border: OutlineInputBorder(),
              prefixIcon: Icon(Icons.title),
            ),
          ),
          const SizedBox(height: 16),
          TextField(
            controller: _noteController,
            decoration: const InputDecoration(
              labelText: 'Notes (optional)',
              border: OutlineInputBorder(),
              prefixIcon: Icon(Icons.notes),
            ),
            maxLines: 2,
          ),
          const SizedBox(height: 16),
          DropdownButtonFormField<String>(
            key: ValueKey(_selectedGroupId),
            initialValue: _selectedGroupId,
            decoration: const InputDecoration(
              labelText: 'Group',
              border: OutlineInputBorder(),
              prefixIcon: Icon(Icons.folder_outlined),
            ),
            items: [
              ...groups.map((g) => DropdownMenuItem(value: g.id, child: Text(g.name))),
              const DropdownMenuItem(
                value: '_add_new_group_',
                child: Row(
                  children: [
                    Icon(Icons.add, size: 18),
                    SizedBox(width: 8),
                    Text('Add New Group...', style: TextStyle(fontWeight: FontWeight.bold)),
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
            validator: (value) => (value == null || value == '_add_new_group_') ? 'Please select a group' : null,
          ),
          const SizedBox(height: 16),
          SwitchListTile(
            title: const Text('Mark as Favorite'),
            value: _isFavorite,
            onChanged: (val) {
              setState(() {
                _isFavorite = val;
              });
            },
            secondary: Icon(_isFavorite ? Icons.favorite : Icons.favorite_border),
            contentPadding: EdgeInsets.zero,
          ),
          const SizedBox(height: 24),
          FilledButton(
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
                
                if (context.mounted) {
                  Navigator.pop(context);
                }
              }
            },
            style: FilledButton.styleFrom(
              padding: const EdgeInsets.symmetric(vertical: 16),
            ),
            child: const Text('Save Link'),
          ),
          const SizedBox(height: 24),
        ],
      ),
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
        title: const Text('Create New Group'),
        content: TextField(
          controller: controller,
          decoration: const InputDecoration(
            hintText: 'Group Name',
            border: OutlineInputBorder(),
          ),
          autofocus: true,
        ),
        actions: [
          TextButton(
            onPressed: () {
              Navigator.pop(context);
              setState(() {
                _selectedGroupId = _previousSelectedGroupId;
              });
            },
            child: const Text('Cancel'),
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
                if (context.mounted) Navigator.pop(context);
                setState(() {
                  _selectedGroupId = group.id;
                  _previousSelectedGroupId = group.id;
                });
              }
            },
            child: const Text('Create'),
          ),
        ],
      ),
    );
  }
}
