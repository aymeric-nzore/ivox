import 'package:flutter/material.dart';

class MyTextfield extends StatelessWidget {
  final String text;
  final TextEditingController controller;
  final Icon icon;
  final IconButton? sicon;
  final bool isObscure;
  const MyTextfield({
    super.key,
    required this.text,
    required this.controller,
    required this.icon,
    this.sicon,
    required this.isObscure,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(8.0),
      child: TextFormField(
        obscureText: isObscure,
        controller: controller,
        decoration: InputDecoration(
          border: OutlineInputBorder(borderRadius: BorderRadius.circular(6)),
          labelText: text,
          prefixIcon: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 12),
                child: icon,
              ),
              Container(width: 1, height: 24, color: Colors.grey.shade400),
              const SizedBox(width: 8),
            ],
          ),
          suffixIcon: sicon,
        ),
      ),
    );
  }
}
