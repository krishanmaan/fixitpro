import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:fixitpro/constants/app_constants.dart';

class CustomTextField extends StatelessWidget {
  final String label;
  final String? hint;
  final TextEditingController controller;
  final bool obscureText;
  final TextInputType keyboardType;
  final IconData? prefixIcon;
  final Widget? suffixIcon;
  final String? Function(String?)? validator;
  final bool isEnabled;
  final int? maxLines;
  final int? maxLength;
  final List<TextInputFormatter>? inputFormatters;
  final Function(String)? onChanged;
  final FocusNode? focusNode;
  final TextInputAction? textInputAction;
  final Function(String)? onFieldSubmitted;

  const CustomTextField({
    super.key,
    required this.label,
    this.hint,
    required this.controller,
    this.obscureText = false,
    this.keyboardType = TextInputType.text,
    this.prefixIcon,
    this.suffixIcon,
    this.validator,
    this.isEnabled = true,
    this.maxLines = 1,
    this.maxLength,
    this.inputFormatters,
    this.onChanged,
    this.focusNode,
    this.textInputAction,
    this.onFieldSubmitted,
  });

  @override
  Widget build(BuildContext context) {
    return TextFormField(
      controller: controller,
      obscureText: obscureText,
      keyboardType: keyboardType,
      enabled: isEnabled,
      maxLines: maxLines,
      maxLength: maxLength,
      inputFormatters: inputFormatters,
      onChanged: onChanged,
      focusNode: focusNode,
      textInputAction: textInputAction,
      onFieldSubmitted: onFieldSubmitted,
      style: AppConstants.bodyStyle,
      decoration: AppConstants.inputDecoration(
        label: label,
        hint: hint,
        prefixIcon: prefixIcon != null ? Icon(prefixIcon) : null,
        suffixIcon: suffixIcon,
      ),
      validator: validator,
    );
  }
}

class PasswordTextField extends StatefulWidget {
  final String label;
  final String? hint;
  final TextEditingController controller;
  final String? Function(String?)? validator;
  final FocusNode? focusNode;
  final TextInputAction? textInputAction;
  final Function(String)? onFieldSubmitted;

  const PasswordTextField({
    super.key,
    required this.label,
    this.hint,
    required this.controller,
    this.validator,
    this.focusNode,
    this.textInputAction,
    this.onFieldSubmitted,
  });

  @override
  State<PasswordTextField> createState() => _PasswordTextFieldState();
}

class _PasswordTextFieldState extends State<PasswordTextField> {
  bool _obscureText = true;

  @override
  Widget build(BuildContext context) {
    return CustomTextField(
      label: widget.label,
      hint: widget.hint,
      controller: widget.controller,
      obscureText: _obscureText,
      keyboardType: TextInputType.visiblePassword,
      prefixIcon: Icons.lock_outline,
      suffixIcon: IconButton(
        icon: Icon(
          _obscureText
              ? Icons.visibility_outlined
              : Icons.visibility_off_outlined,
          color: AppConstants.lightTextColor,
        ),
        onPressed: () {
          setState(() {
            _obscureText = !_obscureText;
          });
        },
      ),
      validator: widget.validator,
      focusNode: widget.focusNode,
      textInputAction: widget.textInputAction,
      onFieldSubmitted: widget.onFieldSubmitted,
    );
  }
}

class CustomDropdownField<T> extends StatelessWidget {
  final String label;
  final T value;
  final List<DropdownMenuItem<T>> items;
  final Function(T?) onChanged;
  final String? Function(T?)? validator;
  final IconData? prefixIcon;

  const CustomDropdownField({
    super.key,
    required this.label,
    required this.value,
    required this.items,
    required this.onChanged,
    this.validator,
    this.prefixIcon,
  });

  @override
  Widget build(BuildContext context) {
    return DropdownButtonFormField<T>(
      value: value,
      items: items,
      onChanged: onChanged,
      validator: validator,
      decoration: AppConstants.inputDecoration(
        label: label,
        prefixIcon: prefixIcon != null ? Icon(prefixIcon) : null,
      ),
      icon: const Icon(Icons.arrow_drop_down),
      style: AppConstants.bodyStyle,
      isExpanded: true,
      dropdownColor: AppConstants.whiteColor,
      borderRadius: BorderRadius.circular(AppConstants.buttonBorderRadius),
    );
  }
}

class SearchTextField extends StatelessWidget {
  final TextEditingController controller;
  final String hint;
  final Function(String)? onChanged;
  final VoidCallback? onClear;
  final VoidCallback? onSubmitted;
  final bool autofocus;

  const SearchTextField({
    super.key,
    required this.controller,
    this.hint = 'Search...',
    this.onChanged,
    this.onClear,
    this.onSubmitted,
    this.autofocus = false,
  });

  @override
  Widget build(BuildContext context) {
    // Get screen dimensions for responsive sizing
    final isSmallScreen = AppConstants.isSmallScreen(context);

    // Adjust icon and text sizes based on screen size
    final double iconSize = isSmallScreen ? 20.0 : 24.0;
    final double fontSize = AppConstants.getResponsiveFontSize(
      context,
      isSmallScreen ? 14 : 16,
    );
    final double verticalPadding = isSmallScreen ? 12.0 : 14.0;
    final double horizontalPadding = isSmallScreen ? 12.0 : 16.0;
    final double borderRadius = isSmallScreen ? 12.0 : 16.0;

    return Container(
      decoration: BoxDecoration(
        boxShadow: [
          BoxShadow(
            color: Colors.black.withAlpha(13),
            blurRadius: 10,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: TextField(
        controller: controller,
        onChanged: onChanged,
        autofocus: autofocus,
        textInputAction: TextInputAction.search,
        onSubmitted: (_) => onSubmitted?.call(),
        style: TextStyle(
          fontSize: fontSize,
          color: AppConstants.textColor,
          fontFamily: 'Poppins',
        ),
        decoration: InputDecoration(
          hintText: hint,
          hintStyle: TextStyle(
            fontSize: fontSize,
            color: AppConstants.lightTextColor,
            fontFamily: 'Poppins',
          ),
          prefixIcon: Padding(
            padding: EdgeInsets.only(
              left: horizontalPadding,
              right: horizontalPadding / 2,
            ),
            child: Icon(
              Icons.search,
              size: iconSize,
              color: AppConstants.primaryColor.withAlpha(128),
            ),
          ),
          suffixIcon:
              controller.text.isNotEmpty
                  ? GestureDetector(
                    onTap: () {
                      onClear?.call();
                    },
                    child: Padding(
                      padding: EdgeInsets.only(
                        left: horizontalPadding / 2,
                        right: horizontalPadding,
                      ),
                      child: Icon(
                        Icons.clear,
                        size: iconSize - 2,
                        color: Colors.grey.shade500,
                      ),
                    ),
                  )
                  : null,
          filled: true,
          fillColor: Colors.white,
          contentPadding: EdgeInsets.symmetric(
            vertical: verticalPadding,
            horizontal: horizontalPadding,
          ),
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(borderRadius),
            borderSide: BorderSide.none,
          ),
          enabledBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(borderRadius),
            borderSide: BorderSide.none,
          ),
          focusedBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(borderRadius),
            borderSide: BorderSide(
              color: AppConstants.primaryColor.withAlpha(178),
              width: 1.0,
            ),
          ),
        ),
      ),
    );
  }
}
