import 'package:devotion/features/auth/presentation/screen/login_screen.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:devotion/core/common/styles/login_Signup_widgets/form_divider.dart';
import 'package:devotion/core/common/styles/login_Signup_widgets/social_button.dart';
import 'package:devotion/core/common/styles/text_strings.dart';
import 'package:devotion/core/constants/sizes.dart';
import 'package:devotion/features/auth/controller/sign_up_controller.dart';

class SignUpScreen extends ConsumerStatefulWidget {
  const SignUpScreen({super.key});

  @override
  ConsumerState<SignUpScreen> createState() => _SignUpScreenState();
}

class _SignUpScreenState extends ConsumerState<SignUpScreen> {
  // ✅ Password visibility state lives in the StatefulWidget, not build()
  bool _obscurePassword = true;
  bool _obscureConfirmPassword = true;

  @override
  Widget build(BuildContext context) {
    final signUpController = ref.watch(signUpControllerProvider.notifier);
    final signUpState = ref.watch(signUpControllerProvider);

    return Scaffold(
      // ✅ Replaced blank AppBar with a styled one
      appBar: AppBar(
        title: const Text('Create Account'),
        centerTitle: true,
      ),
      body: SingleChildScrollView(
        child: Padding(
          padding: const EdgeInsets.all(TSizes.defaultSpace),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // ✅ Removed conflicting TextAlign.center — column is start-aligned
              Text(
                TTexts.signUpTitle,
                style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                      fontWeight: FontWeight.bold,
                      color: Theme.of(context).colorScheme.primary,
                    ),
              ),
              const SizedBox(height: TSizes.spaceBtwSections),

              Form(
                key: signUpController.signupformKey,
                child: Column(
                  children: [
                    // Name row
                    Row(
                      children: [
                        Flexible(
                          child: _buildTextField(
                            controller: signUpController.firstName,
                            label: TTexts.firstName,
                            icon: Icons.person_2_rounded,
                            validator: (value) => value!.isEmpty
                                ? 'Please enter your first name'
                                : null,
                          ),
                        ),
                        const SizedBox(width: TSizes.spaceBtwinputFields),
                        Flexible(
                          child: _buildTextField(
                            controller: signUpController.lastName,
                            label: TTexts.lastName,
                            icon: Icons.person_2_rounded,
                            validator: (value) => value!.isEmpty
                                ? 'Please enter your last name'
                                : null,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: TSizes.spaceBtwinputFields),

                    // Email
                    _buildTextField(
                      controller: signUpController.email,
                      label: TTexts.email,
                      icon: Icons.email_rounded,
                      keyboardType: TextInputType.emailAddress,
                      validator: (value) {
                        if (value!.isEmpty) return 'Please enter your email';
                        if (!value.contains('@')) return 'Enter a valid email';
                        return null;
                      },
                    ),
                    const SizedBox(height: TSizes.spaceBtwinputFields),

                    // Phone
                    _buildTextField(
                      controller: signUpController.phoneNumber,
                      label: TTexts.phoneNumber,
                      icon: Icons.call,
                      keyboardType: TextInputType.phone,
                      validator: (value) => value!.isEmpty
                          ? 'Please enter your phone number'
                          : null,
                    ),
                    const SizedBox(height: TSizes.spaceBtwinputFields),

                    // ✅ Password — uses signUpController.password (was disconnected local controller before)
                    _buildPasswordField(
                      controller: signUpController.password,
                      label: TTexts.password,
                      obscureText: _obscurePassword,
                      onToggle: () =>
                          setState(() => _obscurePassword = !_obscurePassword),
                      validator: (value) {
                        if (value!.isEmpty) return 'Please enter your password';
                        if (value.length < 8) {
                          return 'Password must be at least 8 characters';
                        }
                        return null;
                      },
                    ),
                    const SizedBox(height: TSizes.spaceBtwinputFields),

                    // ✅ Confirm Password — new field
                    _buildPasswordField(
                      controller: signUpController.confirmPassword,
                      label: 'Confirm Password',
                      obscureText: _obscureConfirmPassword,
                      onToggle: () => setState(() =>
                          _obscureConfirmPassword = !_obscureConfirmPassword),
                      validator: (value) {
                        if (value!.isEmpty) {
                          return 'Please confirm your password';
                        }
                        if (value != signUpController.password.text) {
                          return 'Passwords do not match';
                        }
                        return null;
                      },
                    ),
                    const SizedBox(height: TSizes.spaceBtwSections),

                    // Submit button
                    SizedBox(
                      width: double.infinity,
                      child: ElevatedButton(
                        onPressed: signUpState.isLoading
                            ? null
                            : () async {
                                if (signUpController
                                    .signupformKey.currentState!
                                    .validate()) {
                                  try {
                                    await signUpController.signUp(context);
                                    // ✅ Only one snackbar + navigation here (controller no longer does it)
                                    if (context.mounted) {
                                      ScaffoldMessenger.of(context)
                                          .showSnackBar(
                                        const SnackBar(
                                          content: Text(
                                              'Account created successfully! Please log in.'),
                                          backgroundColor: Colors.green,
                                        ),
                                      );
                                      Navigator.pushReplacement(
                                        context,
                                        MaterialPageRoute(
                                            builder: (context) =>
                                                const LoginScreen()),
                                      );
                                    }
                                  } catch (e) {
                                    // Error snackbar is already shown via controller state,
                                    // but we catch here to prevent unhandled exception
                                    if (context.mounted) {
                                      ScaffoldMessenger.of(context)
                                          .showSnackBar(
                                        SnackBar(
                                          content: Text(
                                              signUpState.error ?? e.toString()),
                                          backgroundColor: Colors.red,
                                        ),
                                      );
                                    }
                                  }
                                }
                              },
                        child: signUpState.isLoading
                            ? const SizedBox(
                                height: 20,
                                width: 20,
                                child: CircularProgressIndicator(
                                    strokeWidth: 2, color: Colors.white),
                              )
                            : const Text(TTexts.createAccount),
                      ),
                    ),
                  ],
                ),
              ),

              const SizedBox(height: TSizes.spaceBtwSections),
              const TFormDivider(dividerText: TTexts.orSignupWith),
              const TSocialButton(),
              const SizedBox(height: TSizes.spaceBtwItems),

              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Text('Already have an account?'),
                  TextButton(
                    onPressed: () => Navigator.push(
                      context,
                      MaterialPageRoute(
                          builder: (context) => const LoginScreen()),
                    ),
                    child: const Text(
                      'Log In',
                      style: TextStyle(fontWeight: FontWeight.bold),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildTextField({
    required TextEditingController controller,
    required String label,
    required IconData icon,
    String? Function(String?)? validator,
    TextInputType? keyboardType,
  }) {
    return TextFormField(
      controller: controller,
      validator: validator,
      keyboardType: keyboardType,
      decoration: InputDecoration(
        labelText: label,
        prefixIcon: Icon(icon),
      ),
    );
  }

  // ✅ Separate password builder with functional visibility toggle
  Widget _buildPasswordField({
    required TextEditingController controller,
    required String label,
    required bool obscureText,
    required VoidCallback onToggle,
    String? Function(String?)? validator,
  }) {
    return TextFormField(
      controller: controller,
      validator: validator,
      obscureText: obscureText,
      decoration: InputDecoration(
        labelText: label,
        prefixIcon: const Icon(Icons.lock_rounded),
        suffixIcon: IconButton(
          icon: Icon(
            obscureText ? Icons.visibility_off : Icons.visibility,
          ),
          onPressed: onToggle,
        ),
      ),
    );
  }
}