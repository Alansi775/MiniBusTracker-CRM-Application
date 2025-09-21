// lib/widgets/elegant_hover_button.dart (الكود المُعدَّل والنهائي)

import 'package:flutter/material.dart';
import 'custom_shimmer.dart'; 

// 🚨 تعريف الألوان الجديدة هنا (الأسود والذهبي)
const Color primaryColor = Colors.black87; // أسود داكن (افتراضي)
const Color successColor = Color(0xFF28A745); // أخضر هادئ
const Color accentColor = Color(0xFFFFC107); // ذهبي

class ElegantHoverButton extends StatefulWidget {
  final VoidCallback onPressed;
  final String? text; 
  final double? width; 
  final double height; 
  final Widget? child; 
  // 🚨 تغيير اللون الافتراضي ليستخدم الأسود الداكن
  final Color backgroundColor; 

  const ElegantHoverButton({
    super.key,
    required this.onPressed,
    this.text,
    this.width, 
    this.height = 50.0, 
    this.child, 
    this.backgroundColor = primaryColor, // 💡 اللون الافتراضي أصبح Colors.black87
  }) : assert(text != null || child != null, 'Either text or child must be provided.');

  @override
  State<ElegantHoverButton> createState() => _ElegantHoverButtonState();
}

class _ElegantHoverButtonState extends State<ElegantHoverButton> {
  bool _isHovering = false;

  @override
  Widget build(BuildContext context) {
    final buttonContent = widget.child ?? Text(
      widget.text!,
      style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
    );

    final wrappedContent = _isHovering && widget.child == null
        ? CustomShimmer(
            child: buttonContent,
          )
        : buttonContent;

    return MouseRegion(
      onEnter: (event) => setState(() => _isHovering = true), 
      onExit: (event) => setState(() => _isHovering = false),  
      child: Container(
        width: widget.width, 
        height: widget.height, 
        child: ElevatedButton(
          onPressed: widget.onPressed,
          style: ElevatedButton.styleFrom(
            backgroundColor: widget.backgroundColor,
            foregroundColor: Colors.white, 
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12.0),
            ),
            // 🚨 الحافة الذهبية تُطبق فقط عندما يكون اللون هو primaryColor (الأسود)
            side: BorderSide(
              color: widget.backgroundColor == primaryColor ? accentColor : Colors.transparent, 
              width: 1.5,
            ), 
            padding: EdgeInsets.zero, 
            minimumSize: const Size(double.infinity, 0), 
            elevation: _isHovering ? 8 : 4, 
          ),
          child: Padding( 
            padding: const EdgeInsets.symmetric(horizontal: 10), 
            child: wrappedContent, 
          ),
        ),
      ),
    );
  }
}