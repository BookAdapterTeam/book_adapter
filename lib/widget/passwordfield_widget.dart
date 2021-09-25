//Widget for password field

import "package:flutter/material.dart";
import 'package:passwordfield/passwordfield.dart';

class PasswordfieldWidget extends StatefulWidget {
  final int maxLines;
  final String label;
  final String text;
  final ValueChanged<String> onChanged;

  const PasswordfieldWidget({
    Key? key,
    required this.label,
    required this.text,
    required this.onChanged,
    this.maxLines = 1,
  }) : super(key: key);

  @override
  _PasswordfieldWidgetState createState() => _PasswordfieldWidgetState();
}

class _PasswordfieldWidgetState extends State<PasswordfieldWidget> {
  late final controller = TextEditingController(text: widget.text);

  @override
  void dispose() {
    controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(widget.label,
            style: TextStyle(fontWeight: FontWeight.bold, fontSize: 24)),
        const SizedBox(height: 8),
        PasswordField(
          
            color: Colors.blue,
            passwordConstraint: r'.*[@$#.*].*',
            inputDecoration: PasswordDecoration(),
            hintText: 'must have special characters',
            border: PasswordBorder(
              border: OutlineInputBorder(
                borderSide: BorderSide(
                  color: Colors.blue.shade100,
                ),
                borderRadius: BorderRadius.circular(12),
              ),
              focusedBorder: OutlineInputBorder(
                borderSide: BorderSide(
                  color: Colors.blue.shade100,
                ),
                borderRadius: BorderRadius.circular(12),
              ),
              focusedErrorBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide: BorderSide(width: 2, color: Colors.red.shade200),
              ),
            ),
            errorMessage: 'must contain special character either . * @ # \$',
          ),

        
      ],
    );
  }
}
