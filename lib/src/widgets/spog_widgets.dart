import 'package:flutter/material.dart';

import '../theme.dart';

class SpogTextField extends StatefulWidget {
  const SpogTextField({
    super.key,
    required this.controller,
    required this.hintText,
    this.obscureText = false,
    this.keyboardType,
  });

  final TextEditingController controller;
  final String hintText;
  final bool obscureText;
  final TextInputType? keyboardType;

  @override
  State<SpogTextField> createState() => _SpogTextFieldState();
}

class _SpogTextFieldState extends State<SpogTextField> {
  final _focusNode = FocusNode();
  bool _isFocused = false;

  @override
  void initState() {
    super.initState();
    _focusNode.addListener(_onFocusChanged);
  }

  @override
  void dispose() {
    _focusNode.removeListener(_onFocusChanged);
    _focusNode.dispose();
    super.dispose();
  }

  void _onFocusChanged() {
    if (mounted) {
      setState(() => _isFocused = _focusNode.hasFocus);
    }
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedContainer(
      duration: const Duration(milliseconds: 180),
      height: 45,
      padding: const EdgeInsets.symmetric(horizontal: 12),
      decoration: BoxDecoration(
        color: const Color(0xFFF1EEF7),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: _isFocused ? AdminColors.secondary : const Color(0xFFE2E8F0),
        ),
      ),
      child: Center(
        child: TextField(
          controller: widget.controller,
          focusNode: _focusNode,
          obscureText: widget.obscureText,
          keyboardType: widget.keyboardType,
          style: const TextStyle(
            fontFamily: 'Manrope',
            fontWeight: FontWeight.w700,
            fontSize: 14,
            color: AdminColors.black,
          ),
          decoration: InputDecoration(
            isDense: true,
            border: InputBorder.none,
            hintText: widget.hintText,
            hintStyle: const TextStyle(
              fontFamily: 'Manrope',
              fontSize: 13,
              color: Color(0xFF94A3B8),
            ),
          ),
        ),
      ),
    );
  }
}

class SpogButton extends StatefulWidget {
  const SpogButton({
    super.key,
    required this.text,
    this.onTap,
    this.isLoading = false,
    this.backgroundColor = AdminColors.primary,
    this.textColor = AdminColors.secondary,
    this.height = 45,
    this.fontSize = 13,
    this.uppercase = true,
  });

  final String text;
  final VoidCallback? onTap;
  final bool isLoading;
  final Color backgroundColor;
  final Color textColor;
  final double height;
  final double fontSize;
  final bool uppercase;

  @override
  State<SpogButton> createState() => _SpogButtonState();
}

class _SpogButtonState extends State<SpogButton> {
  bool _pressed = false;

  @override
  Widget build(BuildContext context) {
    final enabled = widget.onTap != null && !widget.isLoading;
    final borderColor = HSLColor.fromColor(widget.backgroundColor)
        .withLightness(
          (HSLColor.fromColor(widget.backgroundColor).lightness - 0.20).clamp(
            0.0,
            1.0,
          ),
        )
        .toColor();
    final shadowColor = HSLColor.fromColor(borderColor)
        .withLightness(
          (HSLColor.fromColor(borderColor).lightness - 0.08).clamp(0.0, 1.0),
        )
        .toColor();

    return SizedBox(
      height: widget.height,
      width: double.infinity,
      child: GestureDetector(
        onTapDown: enabled ? (_) => setState(() => _pressed = true) : null,
        onTapUp: enabled
            ? (_) {
                setState(() => _pressed = false);
                widget.onTap?.call();
              }
            : null,
        onTapCancel: enabled ? () => setState(() => _pressed = false) : null,
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 90),
          transform: Matrix4.translationValues(
            _pressed ? 2 : 0,
            _pressed ? 2 : 0,
            0,
          ),
          decoration: BoxDecoration(
            color: enabled ? widget.backgroundColor : const Color(0xFFE9E3F7),
            borderRadius: BorderRadius.circular(12),
            boxShadow: _pressed
                ? const []
                : [
                    BoxShadow(
                      color: shadowColor,
                      offset: const Offset(2, 2),
                      blurRadius: 0,
                    ),
                  ],
          ),
          child: Center(
            child: widget.isLoading
                ? const SizedBox(
                    width: 16,
                    height: 16,
                    child: CircularProgressIndicator(strokeWidth: 2),
                  )
                : Text(
                    widget.uppercase ? widget.text.toUpperCase() : widget.text,
                    style: TextStyle(
                      fontFamily: 'Manrope',
                      fontWeight: FontWeight.w800,
                      fontSize: widget.fontSize,
                      color: widget.textColor,
                    ),
                  ),
          ),
        ),
      ),
    );
  }
}
