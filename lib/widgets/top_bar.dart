import 'package:flutter/material.dart';

class TopBar extends StatelessWidget {
  const TopBar({
    super.key,
    this.title = 'Tuna',
    this.buttonLeft,
    this.buttonRight,
  });

  final String title;
  final IconButton? buttonLeft;
  final IconButton? buttonRight;

  @override
  Widget build(BuildContext context) {
    return Container(
      height: kToolbarHeight,
      width: double.infinity,
      padding: const EdgeInsets.symmetric(horizontal: 10),
      child: Stack(
        alignment: Alignment.center,
        children: [
          Text(
            title,
            style: const TextStyle(
              fontSize: 32,
            ),
          ),

          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              buttonLeft ?? const SizedBox(width: 40),
              buttonRight ?? const SizedBox(width: 40),
            ],
          ),
        ],
      ),
    );
  }
}