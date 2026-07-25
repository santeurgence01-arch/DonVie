import 'package:flutter/material.dart';

/// Champ de texte thémé : validation affichée seulement après perte de
/// focus (blur) ou tentative de soumission explicite du formulaire
/// (Form.validate() force toujours l'affichage, quel que soit l'état
/// "touched").
class AppTextField extends StatefulWidget {
  const AppTextField({
    super.key,
    required this.label,
    this.controller,
    this.prefixIcon,
    this.suffixIcon,
    this.isPassword = false,
    this.keyboardType,
    this.validator,
    this.maxLength,
    this.showCounter = false,
    this.onChanged,
    this.enabled = true,
    this.semanticsLabel,
    this.maxLines = 1,
  });

  final String label;
  final TextEditingController? controller;
  final IconData? prefixIcon;
  final Widget? suffixIcon;
  final bool isPassword;
  final TextInputType? keyboardType;
  final String? Function(String?)? validator;
  final int? maxLength;
  final bool showCounter;
  final void Function(String)? onChanged;
  final bool enabled;
  final String? semanticsLabel;
  final int maxLines;

  @override
  State<AppTextField> createState() => _AppTextFieldState();
}

class _AppTextFieldState extends State<AppTextField> {
  final FocusNode _focusNode = FocusNode();
  bool _touched = false;
  bool _obscure = true;

  @override
  void initState() {
    super.initState();
    _focusNode.addListener(_handleFocusChange);
  }

  void _handleFocusChange() {
    if (!_focusNode.hasFocus && !_touched) {
      setState(() => _touched = true);
    }
  }

  @override
  void dispose() {
    _focusNode.removeListener(_handleFocusChange);
    _focusNode.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Semantics(
      label: widget.semanticsLabel ?? widget.label,
      child: TextFormField(
        controller: widget.controller,
        focusNode: _focusNode,
        obscureText: widget.isPassword && _obscure,
        keyboardType: widget.keyboardType,
        maxLength: widget.maxLength,
        maxLines: widget.isPassword ? 1 : widget.maxLines,
        enabled: widget.enabled,
        autovalidateMode: _touched
            ? AutovalidateMode.onUserInteraction
            : AutovalidateMode.disabled,
        validator: widget.validator,
        onChanged: widget.onChanged,
        buildCounter: widget.showCounter
            ? null
            : (
                context, {
                required currentLength,
                required isFocused,
                maxLength,
              }) => null,
        decoration: InputDecoration(
          labelText: widget.label,
          prefixIcon: widget.prefixIcon != null
              ? Icon(widget.prefixIcon)
              : null,
          suffixIcon: widget.isPassword
              ? IconButton(
                  icon: Icon(
                    _obscure
                        ? Icons.visibility_outlined
                        : Icons.visibility_off_outlined,
                  ),
                  onPressed: () => setState(() => _obscure = !_obscure),
                )
              : widget.suffixIcon,
        ),
      ),
    );
  }
}
