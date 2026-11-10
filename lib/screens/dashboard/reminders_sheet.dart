import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:uuid/uuid.dart';
import '../../services/dashboard_service.dart';
import '../../theme/app_colors.dart';

class RemindersSheet extends StatefulWidget {
  const RemindersSheet({super.key});

  @override
  State<RemindersSheet> createState() => _RemindersSheetState();
}

class _RemindersSheetState extends State<RemindersSheet> {
  int _selectedFilter = 0; // 0: All, 1: Pending, 2: Completed
  bool _isAdding = false;

  final TextEditingController _titleController = TextEditingController();
  final TextEditingController _urlController = TextEditingController();
  DateTime _selectedDate = DateTime.now().add(const Duration(hours: 6));
  String _selectedPriority = 'high';

  @override
  void dispose() {
    _titleController.dispose();
    _urlController.dispose();
    super.dispose();
  }

  void _saveNewReminder() {
    if (_titleController.text.trim().isEmpty) return;
    DashboardService.addReminder(
      ReminderItem(
        id: const Uuid().v4(),
        title: _titleController.text.trim(),
        url: _urlController.text.trim(),
        dueDate: _selectedDate,
        priority: _selectedPriority,
        isCompleted: false,
      ),
    );
    _titleController.clear();
    _urlController.clear();
    setState(() {
      _isAdding = false;
    });
  }

  @override
  Widget build(BuildContext context) {
    final allReminders = DashboardService.getReminders();
    List<ReminderItem> displayList = List.from(allReminders);
    if (_selectedFilter == 1) {
      displayList = displayList.where((r) => !r.isCompleted).toList();
    } else if (_selectedFilter == 2) {
      displayList = displayList.where((r) => r.isCompleted).toList();
    }

    return Container(
      height: MediaQuery.of(context).size.height * 0.85,
      decoration: const BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.vertical(top: Radius.circular(32)),
      ),
      padding: EdgeInsets.fromLTRB(24, 16, 24, MediaQuery.of(context).viewInsets.bottom + 16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Drag Handle
          Center(
            child: Container(
              width: 44,
              height: 5,
              decoration: BoxDecoration(
                color: Colors.grey.shade300,
                borderRadius: BorderRadius.circular(10),
              ),
            ),
          ),
          const SizedBox(height: 16),

          // Header
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  color: AppColors.surfaceVioletTint,
                  borderRadius: BorderRadius.circular(14),
                ),
                child: const Icon(Icons.alarm_on_rounded, color: AppColors.primaryViolet, size: 26),
              ),
              const SizedBox(width: 14),
              const Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Smart Reminders & Todo',
                      style: TextStyle(
                        fontSize: 20,
                        fontWeight: FontWeight.w800,
                        color: AppColors.cardTitle,
                      ),
                    ),
                    Text(
                      'Turn links into actionable deadlines',
                      style: TextStyle(
                        fontSize: 13,
                        color: AppColors.cardSubtitle,
                      ),
                    ),
                  ],
                ),
              ),
              IconButton(
                onPressed: () => Navigator.pop(context),
                icon: const Icon(Icons.close_rounded, color: AppColors.iconMuted),
              ),
            ],
          ),
          const SizedBox(height: 16),

          // Action / Add Toggle Row
          Row(
            children: [
              // Filter Chips (Scrollable so it never overflows on compact screens)
              Expanded(
                child: SingleChildScrollView(
                  scrollDirection: Axis.horizontal,
                  physics: const BouncingScrollPhysics(),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      _buildFilterChip(0, 'All', allReminders.length),
                      const SizedBox(width: 6),
                      _buildFilterChip(1, 'Pending', allReminders.where((r) => !r.isCompleted).length),
                      const SizedBox(width: 6),
                      _buildFilterChip(2, 'Done', allReminders.where((r) => r.isCompleted).length),
                    ],
                  ),
                ),
              ),
              const SizedBox(width: 8),
              ElevatedButton.icon(
                onPressed: () {
                  setState(() => _isAdding = !_isAdding);
                },
                icon: Icon(_isAdding ? Icons.close : Icons.add_rounded, size: 16),
                label: Text(
                  _isAdding ? 'Cancel' : 'New Task',
                  style: const TextStyle(fontSize: 12.5, fontWeight: FontWeight.bold),
                ),
                style: ElevatedButton.styleFrom(
                  backgroundColor: _isAdding ? Colors.grey.shade200 : AppColors.primaryViolet,
                  foregroundColor: _isAdding ? AppColors.cardTitle : Colors.white,
                  elevation: 0,
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
                  minimumSize: Size.zero,
                  tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),

          // Add New Form (Expandable)
          if (_isAdding) ...[
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: AppColors.surfaceVioletTint,
                borderRadius: BorderRadius.circular(20),
                border: Border.all(color: AppColors.primaryViolet.withValues(alpha: 0.15)),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  TextField(
                    controller: _titleController,
                    decoration: const InputDecoration(
                      hintText: 'What needs to get done?',
                      border: InputBorder.none,
                      hintStyle: TextStyle(color: AppColors.iconMuted, fontSize: 15),
                      isDense: true,
                    ),
                    style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 16, color: AppColors.cardTitle),
                  ),
                  const Divider(height: 16, color: Color(0xFFDDD6FE)),
                  TextField(
                    controller: _urlController,
                    decoration: const InputDecoration(
                      hintText: 'Associated link / reference URL (optional)',
                      border: InputBorder.none,
                      hintStyle: TextStyle(color: AppColors.iconMuted, fontSize: 13),
                      prefixIcon: Icon(Icons.link_rounded, size: 18, color: AppColors.primaryViolet),
                      prefixIconConstraints: BoxConstraints(minWidth: 28),
                      isDense: true,
                    ),
                    style: const TextStyle(fontSize: 13, color: AppColors.primaryViolet),
                  ),
                  const SizedBox(height: 12),
                  // Priority Chips & Date Picker
                  Row(
                    children: [
                      const Text('Priority: ', style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: AppColors.cardSubtitle)),
                      _buildPriorityChoice('urgent', 'Urgent', Colors.red),
                      const SizedBox(width: 4),
                      _buildPriorityChoice('high', 'High', Colors.orange),
                      const SizedBox(width: 4),
                      _buildPriorityChoice('normal', 'Normal', AppColors.primaryViolet),
                      const Spacer(),
                      InkWell(
                        onTap: () async {
                          final picked = await showDatePicker(
                            context: context,
                            initialDate: _selectedDate,
                            firstDate: DateTime.now(),
                            lastDate: DateTime.now().add(const Duration(days: 365)),
                          );
                          if (picked != null) {
                            setState(() => _selectedDate = picked);
                          }
                        },
                        child: Container(
                          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                          decoration: BoxDecoration(
                            color: Colors.white,
                            borderRadius: BorderRadius.circular(10),
                            border: Border.all(color: const Color(0xFFDDD6FE)),
                          ),
                          child: Row(
                            children: [
                              const Icon(Icons.calendar_today_rounded, size: 14, color: AppColors.primaryViolet),
                              const SizedBox(width: 6),
                              Text(
                                DateFormat('MMM d').format(_selectedDate),
                                style: const TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: AppColors.cardTitle),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 14),
                  SizedBox(
                    width: double.infinity,
                    height: 44,
                    child: ElevatedButton(
                      onPressed: _saveNewReminder,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppColors.accentYellow,
                        foregroundColor: AppColors.yellowButtonText,
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                        elevation: 0,
                      ),
                      child: const Text('Save Reminder Task', style: TextStyle(fontWeight: FontWeight.w800, fontSize: 14)),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 16),
          ],

          // Reminders List
          Expanded(
            child: displayList.isEmpty
                ? Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(Icons.task_alt_rounded, size: 54, color: Colors.grey.shade300),
                        const SizedBox(height: 12),
                        const Text(
                          'No reminders in this view',
                          style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16, color: AppColors.cardTitle),
                        ),
                        const SizedBox(height: 4),
                        const Text(
                          'Tap + New Task to schedule your first link reminder',
                          style: TextStyle(color: AppColors.cardSubtitle, fontSize: 13),
                        ),
                      ],
                    ),
                  )
                : ListView.separated(
                    itemCount: displayList.length,
                    separatorBuilder: (_, _) => const SizedBox(height: 10),
                    itemBuilder: (context, index) {
                      final item = displayList[index];
                      final isOverdue = !item.isCompleted && item.dueDate.isBefore(DateTime.now());

                      return Container(
                        padding: const EdgeInsets.all(14),
                        decoration: BoxDecoration(
                          color: item.isCompleted ? const Color(0xFFF8FAFC) : Colors.white,
                          borderRadius: BorderRadius.circular(18),
                          border: Border.all(
                            color: item.isCompleted ? const Color(0xFFE2E8F0) : const Color(0xFFEDE9FE),
                          ),
                          boxShadow: item.isCompleted
                              ? null
                              : const [
                                  BoxShadow(
                                    color: Color(0x0C000000),
                                    blurRadius: 8,
                                    offset: Offset(0, 3),
                                  ),
                                ],
                        ),
                        child: Row(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Checkbox(
                              value: item.isCompleted,
                              activeColor: AppColors.fabGreen,
                              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(6)),
                              onChanged: (_) {
                                setState(() {
                                  DashboardService.toggleReminder(item.id);
                                });
                              },
                            ),
                            const SizedBox(width: 8),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    item.title,
                                    style: TextStyle(
                                      fontSize: 15,
                                      fontWeight: FontWeight.w700,
                                      color: item.isCompleted ? AppColors.iconMuted : AppColors.cardTitle,
                                      decoration: item.isCompleted ? TextDecoration.lineThrough : null,
                                    ),
                                  ),
                                  if (item.url.isNotEmpty) ...[
                                    const SizedBox(height: 2),
                                    Text(
                                      item.url,
                                      maxLines: 1,
                                      overflow: TextOverflow.ellipsis,
                                      style: TextStyle(
                                        fontSize: 12,
                                        color: item.isCompleted ? AppColors.iconMuted : AppColors.primaryViolet,
                                        decoration: item.isCompleted ? TextDecoration.lineThrough : null,
                                      ),
                                    ),
                                  ],
                                  const SizedBox(height: 8),
                                  Row(
                                    children: [
                                      Container(
                                        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                                        decoration: BoxDecoration(
                                          color: isOverdue ? const Color(0xFFFEE2E2) : AppColors.surfaceVioletTint,
                                          borderRadius: BorderRadius.circular(8),
                                        ),
                                        child: Row(
                                          children: [
                                            Icon(
                                              Icons.access_time_filled_rounded,
                                              size: 12,
                                              color: isOverdue ? Colors.red : AppColors.primaryViolet,
                                            ),
                                            const SizedBox(width: 4),
                                            Text(
                                              isOverdue ? 'Overdue • ' : 'Due ',
                                              style: TextStyle(
                                                fontSize: 11,
                                                fontWeight: FontWeight.w700,
                                                color: isOverdue ? Colors.red : AppColors.primaryViolet,
                                              ),
                                            ),
                                            Text(
                                              DateFormat('MMM d, h:mm a').format(item.dueDate),
                                              style: TextStyle(
                                                fontSize: 11,
                                                fontWeight: FontWeight.w600,
                                                color: isOverdue ? Colors.red : AppColors.cardTitle,
                                              ),
                                            ),
                                          ],
                                        ),
                                      ),
                                      const SizedBox(width: 6),
                                      _buildPriorityBadge(item.priority),
                                    ],
                                  ),
                                ],
                              ),
                            ),
                            IconButton(
                              icon: const Icon(Icons.delete_outline_rounded, size: 20, color: AppColors.iconMuted),
                              onPressed: () {
                                setState(() {
                                  DashboardService.deleteReminder(item.id);
                                });
                              },
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

  Widget _buildFilterChip(int index, String label, int count) {
    final isSelected = _selectedFilter == index;
    return InkWell(
      onTap: () => setState(() => _selectedFilter = index),
      borderRadius: BorderRadius.circular(14),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
        decoration: BoxDecoration(
          color: isSelected ? AppColors.surfaceVioletTint : Colors.transparent,
          borderRadius: BorderRadius.circular(14),
          border: Border.all(color: isSelected ? AppColors.primaryViolet : Colors.grey.shade300),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              label,
              style: TextStyle(
                fontSize: 12,
                fontWeight: isSelected ? FontWeight.w800 : FontWeight.w600,
                color: isSelected ? AppColors.primaryViolet : AppColors.cardSubtitle,
              ),
            ),
            const SizedBox(width: 6),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 1),
              decoration: BoxDecoration(
                color: isSelected ? AppColors.primaryViolet : Colors.grey.shade200,
                borderRadius: BorderRadius.circular(10),
              ),
              child: Text(
                '$count',
                style: TextStyle(
                  fontSize: 10,
                  fontWeight: FontWeight.w800,
                  color: isSelected ? Colors.white : AppColors.cardSubtitle,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildPriorityChoice(String value, String label, Color color) {
    final isSelected = _selectedPriority == value;
    return InkWell(
      onTap: () => setState(() => _selectedPriority = value),
      borderRadius: BorderRadius.circular(8),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
        decoration: BoxDecoration(
          color: isSelected ? color.withValues(alpha: 0.15) : Colors.white,
          borderRadius: BorderRadius.circular(8),
          border: Border.all(color: isSelected ? color : Colors.grey.shade300),
        ),
        child: Text(
          label,
          style: TextStyle(
            fontSize: 11,
            fontWeight: isSelected ? FontWeight.w800 : FontWeight.w600,
            color: isSelected ? color : AppColors.cardSubtitle,
          ),
        ),
      ),
    );
  }

  Widget _buildPriorityBadge(String priority) {
    Color color;
    String label;
    switch (priority) {
      case 'urgent':
        color = Colors.red;
        label = 'Urgent';
        break;
      case 'high':
        color = Colors.orange;
        label = 'High';
        break;
      default:
        color = AppColors.primaryViolet;
        label = 'Normal';
    }
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(6),
      ),
      child: Text(
        label,
        style: TextStyle(fontSize: 10, fontWeight: FontWeight.w800, color: color),
      ),
    );
  }
}
