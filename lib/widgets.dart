import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

Widget textForm({title, hint, required controller, isDigits=false, required BuildContext context, icon}) {
  return TextField(
    controller: controller,
    maxLines: 1,
    keyboardType: isDigits ? TextInputType.number : null,
    inputFormatters: isDigits? <TextInputFormatter>[FilteringTextInputFormatter.digitsOnly]: null,
    decoration: InputDecoration(
      labelText: title,
      hintText: hint,
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(100),
      ),
      prefixIcon: Icon(icon),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(16),
        borderSide: BorderSide(color: Theme.of(context).colorScheme.primaryContainer, width: 4),
      ),
    ),
    style: TextStyle(color: Theme.of(context).colorScheme.primary, fontSize: 15),
  );
}
