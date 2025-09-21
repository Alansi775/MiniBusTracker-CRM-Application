// lib/widgets/custom_shimmer.dart

import 'package:flutter/material.dart';
import 'package:shimmer/shimmer.dart';

//  الألوان الأساسية للبراند (تم تحديثها)
const Color primaryColor = Colors.black87; // الأسود الداكن (بديل الكحلي)
const Color accentColor = Color(0xFFFFC107); // الذهبي

//  إعدادات Shimmer (الأسود والأبيض) 
// اللون الأساسي للشيمر: أبيض مائل للذهبي (لون مشرق جداً يمثل بداية التوهج)
const Color shimmerBaseColor = Color(0xFFE0E0E0); // رمادي فاتح جداً (بديل F0F0F0)
// لون التوهج: الأسود الداكن (لإعطاء إحساس بالظل المتحرك على الخلفية الفاتحة)
const Color shimmerHighlightColor = primaryColor; 

class CustomShimmer extends StatelessWidget {
  final Widget child;
  const CustomShimmer({super.key, required this.child});

  @override
  Widget build(BuildContext context) {
    return Shimmer.fromColors(
      baseColor: shimmerBaseColor,
      highlightColor: shimmerHighlightColor,
      // المدة تبقى 4 ثوانٍ لتأثير بطيء ومهدئ
      period: const Duration(milliseconds: 8000), 
      child: child,
    );
  }

  // دالة مساعدة لتأثير التحميل الأولي (تم تحديث الألوان للتماشي مع النمط الفاتح)
  static Widget buildLoadingListTile() {
    return ListTile(
      leading: Container(width: 40, height: 40, decoration: BoxDecoration(color: Colors.grey.shade400, borderRadius: BorderRadius.circular(20))),
      title: Container(height: 10, width: double.infinity, color: Colors.grey.shade400),
      subtitle: Container(height: 10, width: 150, color: Colors.grey.shade400, margin: const EdgeInsets.only(top: 4)),
    );
  }
}
