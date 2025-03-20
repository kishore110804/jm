import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../utils/theme_config.dart';

class NameStep extends StatefulWidget {
  final Function(String) onNext;

  const NameStep({super.key, required this.onNext});

  @override
  State<NameStep> createState() => _NameStepState();
}

class _NameStepState extends State<NameStep> {
  final TextEditingController _nameController = TextEditingController();
  final _formKey = GlobalKey<FormState>();

  @override
  void dispose() {
    _nameController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(24.0),
      child: Form(
        key: _formKey,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const SizedBox(height: 20),
            Text(
              'What\'s your name?',
              style: GoogleFonts.poppins(
                fontSize: 24,
                fontWeight: FontWeight.bold,
                color: ThemeConfig.textIvory,
              ),
            ),
            const SizedBox(height: 10),
            Text(
              'This will be visible to your friends and in public forums.',
              style: GoogleFonts.poppins(
                fontSize: 16,
                color: ThemeConfig.textIvory.withOpacity(0.7),
              ),
            ),
            const SizedBox(height: 40),
            TextFormField(
              controller: _nameController,
              style: GoogleFonts.poppins(color: ThemeConfig.textIvory),
              decoration: InputDecoration(
                labelText: 'Your Name',
                labelStyle: GoogleFonts.poppins(color: ThemeConfig.textIvory),
                enabledBorder: OutlineInputBorder(
                  borderSide: const BorderSide(color: ThemeConfig.textIvory),
                  borderRadius: BorderRadius.circular(10),
                ),
                focusedBorder: OutlineInputBorder(
                  borderSide: const BorderSide(color: ThemeConfig.primaryGreen),
                  borderRadius: BorderRadius.circular(10),
                ),
                errorBorder: OutlineInputBorder(
                  borderSide: const BorderSide(color: Colors.red),
                  borderRadius: BorderRadius.circular(10),
                ),
                focusedErrorBorder: OutlineInputBorder(
                  borderSide: const BorderSide(color: Colors.red),
                  borderRadius: BorderRadius.circular(10),
                ),
              ),
              validator: (value) {
                if (value == null || value.isEmpty) {
                  return 'Please enter your name';
                }
                return null;
              },
            ),
            const Spacer(),
            Align(
              alignment: Alignment.centerRight,
              child: FloatingActionButton(
                backgroundColor: ThemeConfig.primaryGreen,
                onPressed: () {
                  if (_formKey.currentState!.validate()) {
                    widget.onNext(_nameController.text);
                  }
                },
                child: const Icon(Icons.arrow_forward, color: Colors.black),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
