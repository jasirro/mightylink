import 'dart:async';
import 'package:flutter/material.dart';
import 'package:receive_sharing_intent/receive_sharing_intent.dart';
import 'home_screen.dart';
import 'groups_screen.dart';
import 'settings_screen.dart';
import 'add_link_screen.dart';
import '../services/db_service.dart';
import '../widgets/linku_bottom_nav.dart';

class MainScreen extends StatefulWidget {
  final int initialIndex;

  const MainScreen({
    super.key,
    this.initialIndex = 2,
  });

  @override
  State<MainScreen> createState() => _MainScreenState();
}

class _MainScreenState extends State<MainScreen> {
  late int _currentIndex;
  late StreamSubscription _intentDataStreamSubscription;

  final List<Widget> _screens = [
    const HomeScreen(),
    const SettingsScreen(),
    const GroupsScreen(),
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
      useSafeArea: true,
      builder: (context) => AddLinkScreen(initialUrl: url),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: _screens[_currentIndex],
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
