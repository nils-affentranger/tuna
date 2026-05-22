import 'package:flutter/material.dart';
import 'package:tuna/icons/myna_outlined.dart';
import 'package:tuna/icons/myna_solid.dart';
import 'package:tuna/widgets/top_bar.dart';

class SettingsScreen extends StatelessWidget {
  const SettingsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SafeArea(
        child: Column(
          children: [
            TopBar(
              title: 'Settings',
              buttonRight: IconButton(
                icon: const Icon(MynaSolid.xHexagon),
                onPressed: () => Navigator.maybePop(context),
              ),
              buttonLeft: IconButton(
                icon: const Icon(MynaOutlined.infoHexagon),
                onPressed: () {},
              ),
            ),
          ],
        ),
      ),
    );
  }
}
