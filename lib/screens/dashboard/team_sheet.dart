import 'package:flutter/material.dart';
import '../../services/dashboard_service.dart';
import '../../theme/app_colors.dart';

class TeamSheet extends StatefulWidget {
  const TeamSheet({super.key});

  @override
  State<TeamSheet> createState() => _TeamSheetState();
}

class _TeamSheetState extends State<TeamSheet> {
  final TextEditingController _nameController = TextEditingController();
  final TextEditingController _emailController = TextEditingController();
  String _selectedRole = 'Editor';
  bool _isInviting = false;

  @override
  void dispose() {
    _nameController.dispose();
    _emailController.dispose();
    super.dispose();
  }

  void _sendInvite() {
    if (_emailController.text.trim().isEmpty) return;
    final name = _nameController.text.trim().isEmpty
        ? _emailController.text.trim().split('@').first
        : _nameController.text.trim();

    DashboardService.inviteTeamMember(name, _emailController.text.trim(), _selectedRole);
    _nameController.clear();
    _emailController.clear();
    setState(() => _isInviting = false);

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: const Row(
          children: [
            Icon(Icons.mark_email_read_rounded, color: Colors.white, size: 20),
            SizedBox(width: 8),
            Text('Team invitation sent successfully!'),
          ],
        ),
        backgroundColor: AppColors.primaryViolet,
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final members = DashboardService.getTeamMembers();

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
                child: const Icon(Icons.groups_rounded, color: AppColors.primaryViolet, size: 26),
              ),
              const SizedBox(width: 14),
              const Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Team Workspace',
                      style: TextStyle(
                        fontSize: 20,
                        fontWeight: FontWeight.w800,
                        color: AppColors.cardTitle,
                      ),
                    ),
                    Text(
                      'Multi-seat collaboration & live permissions',
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

          // Workspace Card
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              gradient: const LinearGradient(
                colors: [Color(0xFF5619F6), Color(0xFF6F3CF8)],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
              borderRadius: BorderRadius.circular(20),
              boxShadow: const [
                BoxShadow(
                  color: Color(0x285619F6),
                  blurRadius: 16,
                  offset: Offset(0, 6),
                ),
              ],
            ),
            child: Row(
              children: [
                Container(
                  width: 44,
                  height: 44,
                  decoration: BoxDecoration(
                    color: Colors.white.withValues(alpha: 0.2),
                    shape: BoxShape.circle,
                  ),
                  child: const Center(
                    child: Text('⚡', style: TextStyle(fontSize: 20)),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        DashboardService.teamWorkspaceName,
                        style: const TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.w800,
                          color: Colors.white,
                        ),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        '${members.length} Active Collaborators',
                        style: const TextStyle(
                          fontSize: 12,
                          color: AppColors.textOnPurpleMuted,
                        ),
                      ),
                    ],
                  ),
                ),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                  decoration: BoxDecoration(
                    color: AppColors.accentYellow,
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: const Text(
                    'PRO TEAM',
                    style: TextStyle(
                      fontSize: 11,
                      fontWeight: FontWeight.w900,
                      color: AppColors.yellowButtonText,
                    ),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 18),

          // Action Row
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Expanded(
                child: Text(
                  'Members & Roles (${members.length})',
                  style: const TextStyle(fontSize: 15, fontWeight: FontWeight.w800, color: AppColors.cardTitle),
                  overflow: TextOverflow.ellipsis,
                ),
              ),
              const SizedBox(width: 8),
              ElevatedButton.icon(
                onPressed: () => setState(() => _isInviting = !_isInviting),
                icon: Icon(_isInviting ? Icons.close : Icons.person_add_rounded, size: 16),
                label: Text(_isInviting ? 'Cancel' : 'Invite Member'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: _isInviting ? Colors.grey.shade200 : AppColors.primaryViolet,
                  foregroundColor: _isInviting ? AppColors.cardTitle : Colors.white,
                  elevation: 0,
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),

          // Invite Form
          if (_isInviting) ...[
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: AppColors.surfaceVioletTint,
                borderRadius: BorderRadius.circular(18),
                border: Border.all(color: AppColors.primaryViolet.withValues(alpha: 0.2)),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  TextField(
                    controller: _nameController,
                    decoration: const InputDecoration(
                      hintText: 'Member Full Name (e.g. Elena Rostova)',
                      border: InputBorder.none,
                      isDense: true,
                    ),
                    style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 14, color: AppColors.cardTitle),
                  ),
                  const Divider(height: 12, color: Color(0xFFDDD6FE)),
                  TextField(
                    controller: _emailController,
                    keyboardType: TextInputType.emailAddress,
                    decoration: const InputDecoration(
                      hintText: 'Work email address (name@company.com)',
                      border: InputBorder.none,
                      prefixIcon: Icon(Icons.email_outlined, size: 18, color: AppColors.primaryViolet),
                      prefixIconConstraints: BoxConstraints(minWidth: 26),
                      isDense: true,
                    ),
                    style: const TextStyle(fontSize: 13, color: AppColors.primaryViolet),
                  ),
                  const Divider(height: 12, color: Color(0xFFDDD6FE)),
                  Row(
                    children: [
                      const Text('Role: ', style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: AppColors.cardSubtitle)),
                      const SizedBox(width: 8),
                      DropdownButton<String>(
                        value: _selectedRole,
                        underline: const SizedBox(),
                        style: const TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: AppColors.primaryViolet),
                        items: ['Admin', 'Editor', 'Viewer']
                            .map((e) => DropdownMenuItem(value: e, child: Text(e)))
                            .toList(),
                        onChanged: (val) {
                          if (val != null) setState(() => _selectedRole = val);
                        },
                      ),
                      const Spacer(),
                      ElevatedButton(
                        onPressed: _sendInvite,
                        style: ElevatedButton.styleFrom(
                          backgroundColor: AppColors.accentYellow,
                          foregroundColor: AppColors.yellowButtonText,
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                          elevation: 0,
                          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                        ),
                        child: const Text('Send Invite', style: TextStyle(fontWeight: FontWeight.w800, fontSize: 12)),
                      ),
                    ],
                  ),
                ],
              ),
            ),
            const SizedBox(height: 12),
          ],

          // Member List
          Expanded(
            child: ListView.separated(
              itemCount: members.length,
              separatorBuilder: (_, _) => const SizedBox(height: 10),
              itemBuilder: (context, index) {
                final member = members[index];
                final isOwner = member.role == 'Owner';

                return Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(color: const Color(0xFFEDE9FE)),
                    boxShadow: const [
                      BoxShadow(
                        color: Color(0x08000000),
                        blurRadius: 6,
                        offset: Offset(0, 2),
                      ),
                    ],
                  ),
                  child: Row(
                    children: [
                      CircleAvatar(
                        radius: 20,
                        backgroundColor: _getAvatarColor(member.name),
                        child: Text(
                          member.name.isNotEmpty ? member.name[0].toUpperCase() : '?',
                          style: const TextStyle(color: Colors.white, fontWeight: FontWeight.w800, fontSize: 15),
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              member.name,
                              style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w700, color: AppColors.cardTitle),
                            ),
                            Text(
                              member.email,
                              style: const TextStyle(fontSize: 12, color: AppColors.cardSubtitle),
                            ),
                          ],
                        ),
                      ),
                      _buildRoleBadge(member.role),
                      if (!isOwner) ...[
                        const SizedBox(width: 6),
                        IconButton(
                          icon: const Icon(Icons.remove_circle_outline_rounded, size: 18, color: AppColors.iconMuted),
                          onPressed: () {
                            setState(() {
                              DashboardService.removeTeamMember(member.id);
                            });
                          },
                        ),
                      ],
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

  Color _getAvatarColor(String name) {
    final colors = [
      AppColors.primaryViolet,
      const Color(0xFF0284C7),
      const Color(0xFF15CA91),
      const Color(0xFFF59E0B),
      const Color(0xFFEC4899),
    ];
    return colors[name.hashCode.abs() % colors.length];
  }

  Widget _buildRoleBadge(String role) {
    Color bg;
    Color text;
    switch (role) {
      case 'Owner':
        bg = const Color(0xFFFEF3C7);
        text = const Color(0xFFB45309);
        break;
      case 'Admin':
        bg = AppColors.surfaceVioletTint;
        text = AppColors.primaryViolet;
        break;
      case 'Editor':
        bg = const Color(0xFFDCFCE7);
        text = const Color(0xFF15803D);
        break;
      default:
        bg = const Color(0xFFF1F5F9);
        text = const Color(0xFF475569);
    }
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
        color: bg,
        borderRadius: BorderRadius.circular(10),
      ),
      child: Text(
        role,
        style: TextStyle(fontSize: 11, fontWeight: FontWeight.w800, color: text),
      ),
    );
  }
}
