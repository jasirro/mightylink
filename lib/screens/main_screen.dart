import 'dart:async';
import 'package:flutter/material.dart';
import 'package:receive_sharing_intent/receive_sharing_intent.dart';
import 'groups_screen.dart';
import 'dashboard_screen.dart';
import 'settings_screen.dart';
import 'add_link_screen.dart';
import '../services/db_service.dart';
import '../theme/app_colors.dart';
import '../widgets/linku_bottom_nav.dart';

class MainScreen extends StatefulWidget {
  final int initialIndex;

  const MainScreen({
    super.key,
    this.initialIndex = 0, // Default to Workspaces screen (Figma main hub)
  });

  @override
  State<MainScreen> createState() => _MainScreenState();
}

class _MainScreenState extends State<MainScreen> {
  late int _currentIndex;
  late StreamSubscription _intentDataStreamSubscription;

  final List<Widget> _screens = [
    const GroupsScreen(),    // Tab 0: Workspaces
    const DashboardScreen(), // Tab 1: Dashboard Hub
    const SettingsScreen(),  // Tab 2: Settings & Profile
  ];

  @override
  void initState() {
    super.initState();
    _currentIndex = widget.initialIndex;
    _initSharingIntent();
  }

  void _initSharingIntent() {
    _intentDataStreamSubscription = ReceiveSharingIntent.instance.getMediaStream().listen((List<SharedMediaFile> value) {
      if (value.isNotEmpty) {
        _showAddLinkSheet(value.first.path);
      }
    }, onError: (err) {
      debugPrint("getLinkStream error: $err");
    });

    ReceiveSharingIntent.instance.getInitialMedia().then((List<SharedMediaFile> value) {
      if (value.isNotEmpty) {
        _showAddLinkSheet(value.first.path);
      }
    });
  }

  @override
  void dispose() {
    _intentDataStreamSubscription.cancel();
    final user = DbService.activeUser;
    if (user.isNotEmpty) {
      DbService.closeUserBoxes(user).then((_) {
        if (DbService.activeUser == user) {
          DbService.activeUser = '';
        }
      });
    }
    super.dispose();
  }

  void _showAddLinkSheet(String url) {
    if (url.isEmpty) return;
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => AddLinkScreen(initialUrl: url),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.primaryViolet,
      extendBody: true,
      body: IndexedStack(
        index: _currentIndex,
        children: _screens,
      ),
      bottomNavigationBar: LinkuBottomNav(
        currentIndex: _currentIndex,
        onItemSelected: (index) {
          setState(() {
            _currentIndex = index;
          });
        },
      ),
    );
  }
}
