import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../utils/theme_config.dart';

class AgeStep extends StatefulWidget {
  final Function(String?) onNext;

  const AgeStep({super.key, required this.onNext});

  @override
  State<AgeStep> createState() => _AgeStepState();
}

class _AgeStepState extends State<AgeStep> {
  final TextEditingController _ageController = TextEditingController();
  final _formKey = GlobalKey<FormState>();

  @override
  void dispose() {
    _ageController.dispose();
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
              'What\'s your age?',
              style: GoogleFonts.poppins(
                fontSize: 24,
                fontWeight: FontWeight.bold,
                color: ThemeConfig.textIvory,
              ),
            ),
            const SizedBox(height: 10),
            Text(
              'This is optional and will be kept private.',
              style: GoogleFonts.poppins(
                fontSize: 16,
                color: ThemeConfig.textIvory.withOpacity(0.7),
              ),
            ),
            const SizedBox(height: 40),
            TextFormField(
              controller: _ageController,
              style: GoogleFonts.poppins(color: ThemeConfig.textIvory),
              keyboardType: TextInputType.number,
              decoration: InputDecoration(
                labelText: 'Your Age',
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
                if (value != null && value.isNotEmpty) {
                  if (int.tryParse(value) == null) {
                    return 'Please enter a valid number';
                  }
                  if (int.parse(value) < 13 || int.parse(value) > 120) {
                    return 'Please enter an age between 13 and 120';
                  }
                }
                return null;
              },
            ),
            const SizedBox(height: 20),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                TextButton(
                  onPressed: () {
                    widget.onNext(null); // Skip this step
                  },
                  child: Text(
                    'Skip',
                    style: GoogleFonts.poppins(
                      color: ThemeConfig.textIvory.withOpacity(0.7),
                      fontSize: 16,
                    ),
                  ),
                ),
                FloatingActionButton(
                  backgroundColor: ThemeConfig.primaryGreen,
                  onPressed: () {
                    if (_formKey.currentState!.validate()) {
                      widget.onNext(
                        _ageController.text.isEmpty
                            ? null
                            : _ageController.text,
                      );
                    }
                  },
                  child: const Icon(Icons.arrow_forward, color: Colors.black),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
