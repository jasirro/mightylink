import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:uuid/uuid.dart';
import '../../services/biometric_service.dart';
import '../../services/dashboard_service.dart';
import '../../theme/app_colors.dart';

class VaultSheet extends StatefulWidget {
  const VaultSheet({super.key});

  @override
  State<VaultSheet> createState() => _VaultSheetState();
}

class _VaultSheetState extends State<VaultSheet> {
  final TextEditingController _pinController = TextEditingController();
  final TextEditingController _titleController = TextEditingController();
  final TextEditingController _urlController = TextEditingController();
  final TextEditingController _secretNoteController = TextEditingController();

  bool _isAdding = false;
  String? _pinError;
  bool _canUseBiometrics = false;
  bool _isAuthenticatingBiometrics = false;

  @override
  void initState() {
    super.initState();
    _checkBiometrics();
  }

  Future<void> _checkBiometrics() async {
    final available = await BiometricService.isBiometricAvailable();
    if (mounted) {
      setState(() {
        _canUseBiometrics = available;
      });
    }
  }

  Future<void> _unlockWithBiometrics() async {
    setState(() {
      _isAuthenticatingBiometrics = true;
      _pinError = null;
    });

    final success = await BiometricService.authenticate();
    if (mounted) {
      setState(() {
        _isAuthenticatingBiometrics = false;
        if (success) {
          DashboardService.isVaultUnlocked = true;
          _pinError = null;
          _pinController.clear();
        } else {
          _pinError = 'Biometric verification unconfirmed. Please use PIN.';
        }
      });
    }
  }

  @override
  void dispose() {
    _pinController.dispose();
    _titleController.dispose();
    _urlController.dispose();
    _secretNoteController.dispose();
    super.dispose();
  }

  void _verifyPin() {
    final entered = _pinController.text.trim();
    if (DashboardService.checkPin(entered)) {
      setState(() {
        DashboardService.isVaultUnlocked = true;
        _pinError = null;
        _pinController.clear();
      });
    } else {
      setState(() {
        _pinError = 'Incorrect PIN. Default is 1234';
      });
    }
  }

  void _lockVault() {
    setState(() {
      DashboardService.isVaultUnlocked = false;
      _isAdding = false;
    });
  }

  void _saveVaultItem() {
    if (_titleController.text.trim().isEmpty || _urlController.text.trim().isEmpty) return;
    DashboardService.addVaultItem(
      VaultItem(
        id: const Uuid().v4(),
        title: _titleController.text.trim(),
        url: _urlController.text.trim(),
        secretNote: _secretNoteController.text.trim(),
        createdAt: DateTime.now(),
      ),
    );
    _titleController.clear();
    _urlController.clear();
    _secretNoteController.clear();
    setState(() {
      _isAdding = false;
    });
  }

  @override
  Widget build(BuildContext context) {
    final isUnlocked = DashboardService.isVaultUnlocked;
    final vaultItems = DashboardService.getVaultItems();

    return Container(
      height: MediaQuery.of(context).size.height * 0.85,
      decoration: const BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.vertical(top: Radius.circular(32)),
      ),
      padding: EdgeInsets.fromLTRB(24, 16, 24, MediaQuery.of(context).viewInsets.bottom + 16),
      child: isUnlocked ? _buildUnlockedView(vaultItems) : _buildLockedView(),
    );
  }

  Widget _buildLockedView() {
    return Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.center,
      children: [
        // Drag Handle
        Container(
          width: 44,
          height: 5,
          decoration: BoxDecoration(
            color: Colors.grey.shade300,
            borderRadius: BorderRadius.circular(10),
          ),
        ),
        const SizedBox(height: 24),

        // Shield Graphic
        Container(
          width: 80,
          height: 80,
          decoration: BoxDecoration(
            color: AppColors.surfaceVioletTint,
            shape: BoxShape.circle,
            border: Border.all(color: AppColors.primaryViolet.withValues(alpha: 0.2), width: 2),
          ),
          child: const Icon(Icons.shield_rounded, size: 44, color: AppColors.primaryViolet),
        ),
        const SizedBox(height: 16),
        const Text(
          'MightyLink Secure Vault',
          style: TextStyle(
            fontSize: 22,
            fontWeight: FontWeight.w800,
            color: AppColors.cardTitle,
          ),
        ),
        const SizedBox(height: 6),
        const Text(
          'AES-256 encrypted private link storage.\nEnter your 4-digit PIN to authenticate.',
          textAlign: TextAlign.center,
          style: TextStyle(fontSize: 13, color: AppColors.cardSubtitle),
        ),
        const SizedBox(height: 20),

        if (_canUseBiometrics) ...[
          SizedBox(
            width: 240,
            height: 48,
            child: OutlinedButton.icon(
              onPressed: _isAuthenticatingBiometrics ? null : _unlockWithBiometrics,
              icon: _isAuthenticatingBiometrics
                  ? const SizedBox(
                      width: 18,
                      height: 18,
                      child: CircularProgressIndicator(strokeWidth: 2, color: AppColors.primaryViolet),
                    )
                  : const Icon(Icons.fingerprint_rounded, size: 24, color: AppColors.primaryViolet),
              label: Text(
                _isAuthenticatingBiometrics ? 'Verifying...' : 'Unlock with Biometrics',
                style: const TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w700,
                  color: AppColors.primaryViolet,
                ),
              ),
              style: OutlinedButton.styleFrom(
                side: const BorderSide(color: AppColors.primaryViolet, width: 1.5),
                backgroundColor: AppColors.surfaceVioletTint,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
              ),
            ),
          ),
          const SizedBox(height: 16),
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Container(width: 40, height: 1, color: Colors.grey.shade300),
              const Padding(
                padding: EdgeInsets.symmetric(horizontal: 10),
                child: Text(
                  'OR ENTER PIN',
                  style: TextStyle(fontSize: 11, fontWeight: FontWeight.w700, color: AppColors.cardSubtitle),
                ),
              ),
              Container(width: 40, height: 1, color: Colors.grey.shade300),
            ],
          ),
          const SizedBox(height: 16),
        ],

        // PIN Input
        Container(
          width: 200,
          decoration: BoxDecoration(
            color: AppColors.surfaceVioletTint,
            borderRadius: BorderRadius.circular(16),
            border: Border.all(
              color: _pinError != null ? Colors.red : AppColors.primaryViolet.withValues(alpha: 0.3),
            ),
          ),
          child: TextField(
            controller: _pinController,
            obscureText: true,
            maxLength: 6,
            keyboardType: TextInputType.number,
            textAlign: TextAlign.center,
            style: const TextStyle(fontSize: 24, fontWeight: FontWeight.w800, letterSpacing: 8, color: AppColors.primaryViolet),
            decoration: const InputDecoration(
              counterText: '',
              hintText: '••••',
              border: InputBorder.none,
              contentPadding: EdgeInsets.symmetric(vertical: 12),
            ),
            onSubmitted: (_) => _verifyPin(),
          ),
        ),
        if (_pinError != null) ...[
          const SizedBox(height: 8),
          Text(
            _pinError!,
            style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w700, color: Colors.red),
          ),
        ],
        const SizedBox(height: 20),

        // Unlock Button
        SizedBox(
          width: 240,
          height: 50,
          child: ElevatedButton.icon(
            onPressed: _verifyPin,
            icon: const Icon(Icons.lock_open_rounded, color: AppColors.yellowButtonText),
            label: const Text(
              'Unlock Vault',
              style: TextStyle(fontSize: 15, fontWeight: FontWeight.w800, color: AppColors.yellowButtonText),
            ),
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.accentYellow,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
              elevation: 0,
            ),
          ),
        ),
        const SizedBox(height: 16),
        const Text(
          'Default security PIN: 1234',
          style: TextStyle(fontSize: 12, color: AppColors.iconMuted),
        ),
      ],
    );
  }

  Widget _buildUnlockedView(List<VaultItem> items) {
    return Column(
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
                color: const Color(0xFFF0FDF4),
                borderRadius: BorderRadius.circular(14),
              ),
              child: const Icon(Icons.lock_open_rounded, color: AppColors.fabGreen, size: 24),
            ),
            const SizedBox(width: 14),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'Secure Vault (Unlocked)',
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.w800,
                      color: AppColors.cardTitle,
                    ),
                  ),
                  Text(
                    '${items.length} private items encrypted',
                    style: const TextStyle(
                      fontSize: 12,
                      color: AppColors.cardSubtitle,
                    ),
                  ),
                ],
              ),
            ),
            TextButton.icon(
              onPressed: _lockVault,
              icon: const Icon(Icons.lock_rounded, size: 16, color: Colors.red),
              label: const Text('Lock', style: TextStyle(color: Colors.red, fontWeight: FontWeight.w800)),
              style: TextButton.styleFrom(
                backgroundColor: const Color(0xFFFEE2E2),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
              ),
            ),
          ],
        ),
        const SizedBox(height: 16),

        // Add Button
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            const Text(
              'Encrypted Bookmarks',
              style: TextStyle(fontSize: 15, fontWeight: FontWeight.w800, color: AppColors.cardTitle),
            ),
            ElevatedButton.icon(
              onPressed: () => setState(() => _isAdding = !_isAdding),
              icon: Icon(_isAdding ? Icons.close : Icons.add_rounded, size: 16),
              label: Text(_isAdding ? 'Cancel' : 'Add to Vault'),
              style: ElevatedButton.styleFrom(
                backgroundColor: _isAdding ? Colors.grey.shade200 : AppColors.primaryViolet,
                foregroundColor: _isAdding ? AppColors.cardTitle : Colors.white,
                elevation: 0,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
              ),
            ),
          ],
        ),
        const SizedBox(height: 12),

        // Add Item Form
        if (_isAdding) ...[
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
                  controller: _titleController,
                  decoration: const InputDecoration(
                    hintText: 'Private Title (e.g. Stripe Live Dashboard)',
                    border: InputBorder.none,
                    isDense: true,
                  ),
                  style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 15, color: AppColors.cardTitle),
                ),
                const Divider(height: 12, color: Color(0xFFDDD6FE)),
                TextField(
                  controller: _urlController,
                  decoration: const InputDecoration(
                    hintText: 'Private URL / Secret Bookmark',
                    border: InputBorder.none,
                    prefixIcon: Icon(Icons.link_rounded, size: 18, color: AppColors.primaryViolet),
                    prefixIconConstraints: BoxConstraints(minWidth: 26),
                    isDense: true,
                  ),
                  style: const TextStyle(fontSize: 13, color: AppColors.primaryViolet),
                ),
                const Divider(height: 12, color: Color(0xFFDDD6FE)),
                TextField(
                  controller: _secretNoteController,
                  decoration: const InputDecoration(
                    hintText: 'Secret Note / Credentials / Recovery Keys',
                    border: InputBorder.none,
                    prefixIcon: Icon(Icons.key_rounded, size: 18, color: Colors.orange),
                    prefixIconConstraints: BoxConstraints(minWidth: 26),
                    isDense: true,
                  ),
                  style: const TextStyle(fontSize: 13, color: AppColors.cardTitle),
                ),
                const SizedBox(height: 12),
                SizedBox(
                  width: double.infinity,
                  height: 42,
                  child: ElevatedButton(
                    onPressed: _saveVaultItem,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppColors.accentYellow,
                      foregroundColor: AppColors.yellowButtonText,
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                      elevation: 0,
                    ),
                    child: const Text('Encrypt & Save to Vault', style: TextStyle(fontWeight: FontWeight.w800, fontSize: 13)),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 12),
        ],

        // Items List
        Expanded(
          child: items.isEmpty
              ? Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(Icons.shield_outlined, size: 48, color: Colors.grey.shade300),
                      const SizedBox(height: 10),
                      const Text(
                        'No encrypted items in Vault',
                        style: TextStyle(fontWeight: FontWeight.w700, color: AppColors.cardTitle),
                      ),
                      const SizedBox(height: 4),
                      const Text(
                        'Tap "Add to Vault" to secure sensitive links.',
                        style: TextStyle(fontSize: 12, color: AppColors.cardSubtitle),
                      ),
                    ],
                  ),
                )
              : ListView.separated(
                  itemCount: items.length,
                  separatorBuilder: (_, _) => const SizedBox(height: 10),
                  itemBuilder: (context, index) {
                    final item = items[index];
                    return Container(
                      padding: const EdgeInsets.all(14),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(16),
                        border: Border.all(color: const Color(0xFFEDE9FE)),
                        boxShadow: const [
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
                          Container(
                            padding: const EdgeInsets.all(10),
                            decoration: BoxDecoration(
                              color: AppColors.surfaceVioletTint,
                              borderRadius: BorderRadius.circular(12),
                            ),
                            child: const Icon(Icons.shield_rounded, size: 20, color: AppColors.primaryViolet),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  item.title,
                                  style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w700, color: AppColors.cardTitle),
                                ),
                                const SizedBox(height: 2),
                                Text(
                                  item.url,
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                  style: const TextStyle(fontSize: 12, color: AppColors.primaryViolet),
                                ),
                                if (item.secretNote.isNotEmpty) ...[
                                  const SizedBox(height: 6),
                                  Container(
                                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                                    decoration: BoxDecoration(
                                      color: const Color(0xFFFFFBEB),
                                      borderRadius: BorderRadius.circular(8),
                                      border: Border.all(color: const Color(0xFFFEF3C7)),
                                    ),
                                    child: Row(
                                      children: [
                                        const Icon(Icons.key_rounded, size: 12, color: Colors.orange),
                                        const SizedBox(width: 6),
                                        Expanded(
                                          child: Text(
                                            item.secretNote,
                                            maxLines: 1,
                                            overflow: TextOverflow.ellipsis,
                                            style: const TextStyle(fontSize: 11, fontWeight: FontWeight.w600, color: Color(0xFF92400E)),
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                                ],
                              ],
                            ),
                          ),
                          IconButton(
                            icon: const Icon(Icons.copy_rounded, size: 18, color: AppColors.primaryViolet),
                            tooltip: 'Copy URL',
                            onPressed: () {
                              Clipboard.setData(ClipboardData(text: item.url));
                              ScaffoldMessenger.of(context).showSnackBar(
                                SnackBar(
                                  content: const Text('Encrypted URL copied to clipboard'),
                                  backgroundColor: AppColors.primaryViolet,
                                  behavior: SnackBarBehavior.floating,
                                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                                ),
                              );
                            },
                          ),
                          IconButton(
                            icon: const Icon(Icons.delete_outline_rounded, size: 18, color: AppColors.iconMuted),
                            onPressed: () {
                              setState(() {
                                DashboardService.deleteVaultItem(item.id);
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
    );
  }
}
