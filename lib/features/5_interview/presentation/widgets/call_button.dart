import 'package:ai_voice_interview_app/core/constants/theme.dart';
import 'package:flutter/material.dart';

enum CallButtonType { answer, hangup, mute }

class CallButton extends StatelessWidget {
  final CallButtonType type;
  final VoidCallback onPressed;
  final bool isActive;
  final bool isLoading;

  const CallButton({
    super.key,
    required this.type,
    required this.onPressed,
    this.isActive = true,
    this.isLoading = false,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: isActive && !isLoading ? onPressed : null,
      child: Container(
        width: 64,
        height: 64,
        decoration: BoxDecoration(
          color: _getButtonColor(),
          shape: BoxShape.circle,
          boxShadow: [
            BoxShadow(
              color: _getButtonColor().withValues(alpha: 0.3),
              blurRadius: 10,
              spreadRadius: 2,
            ),
          ],
        ),
        child: isLoading
            ? const CircularProgressIndicator(
                valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
              )
            : Icon(_getButtonIcon(), color: Colors.white, size: 28),
      ),
    );
  }

  Color _getButtonColor() {
    if (!isActive) {
      return Colors.grey;
    }

    switch (type) {
      case CallButtonType.answer:
        return AppTheme.successColor;
      case CallButtonType.hangup:
        return AppTheme.errorColor;
      case CallButtonType.mute:
        return isActive ? AppTheme.primaryColor : Colors.grey;
    }
  }

  IconData _getButtonIcon() {
    switch (type) {
      case CallButtonType.answer:
        return Icons.mic;
      case CallButtonType.hangup:
        return Icons.call_end;
      case CallButtonType.mute:
        return Icons.mic_off;
    }
  }
}
