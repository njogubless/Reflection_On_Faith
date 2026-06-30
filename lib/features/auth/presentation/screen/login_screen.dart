import 'package:devotion/core/common/navigation/main_layout.dart';
import 'package:devotion/core/common/styles/login_Signup_widgets/form_divider.dart';
import 'package:devotion/core/common/styles/image_strings.dart';
import 'package:devotion/core/common/styles/spacing_styles.dart';
import 'package:devotion/core/common/styles/text_strings.dart';
import 'package:devotion/core/constants/sizes.dart';
import 'package:devotion/features/auth/controller/auth_controller.dart';
import 'package:devotion/features/auth/controller/auth_preferences.dart';
import 'package:devotion/features/auth/presentation/screen/sign_up.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:icons_plus/icons_plus.dart';

class LoginScreen extends ConsumerStatefulWidget {
  const LoginScreen({super.key});

  @override
  ConsumerState<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends ConsumerState<LoginScreen> {
  final emailController = TextEditingController();
  final passwordController = TextEditingController();
  final formKey = GlobalKey<FormState>();
  bool rememberMe = false;
  bool _obscurePassword = true; // ✅ Added password visibility state

  @override
  void initState() {
    super.initState();
    _loadSavedCredentials();
  }

  @override
  void dispose() {
    emailController.dispose();
    passwordController.dispose();
    super.dispose();
  }

  Future<void> _loadSavedCredentials() async {
    final savedCredentials = await AuthPreferences.getSavedCredentials();
    setState(() {
      rememberMe = savedCredentials['rememberMe'];
      if (rememberMe) {
        emailController.text = savedCredentials['email'];
        passwordController.text = savedCredentials['password'];
      }
    });
  }

  void _showForgotPasswordDialog() {
    final resetEmailController =
        TextEditingController(); // ✅ Separate controller for dialog
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Reset Password'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Text('Enter your email to receive a password reset link'),
            const SizedBox(height: TSizes.spaceBtwinputFields),
            TextFormField(
              controller: resetEmailController,
              keyboardType: TextInputType.emailAddress,
              decoration: const InputDecoration(
                labelText: TTexts.email,
                prefixIcon: Icon(Iconsax.direct_right_bold),
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () {
              ref
                  .read(authControllerProvider.notifier)
                  .resetPassword(context, resetEmailController.text.trim());
              Navigator.pop(context);
            },
            child: const Text('Reset Password'),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    ref.watch(authControllerProvider);

    return Scaffold(
      body: SingleChildScrollView(
        child: Padding(
          padding: TSpacingStyle.paddingWithAppBarHeight,
          child: Column(
            children: [
              // Header
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    TTexts.logInTitle,
                    style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                          fontWeight: FontWeight.bold,
                          color: Colors.blueAccent,
                        ),
                  ),
                  const SizedBox(height: TSizes.sm),
                  Text(
                    TTexts.logInSubTitle,
                    style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                          fontStyle: FontStyle.italic,
                          color: Colors.grey,
                        ),
                  ),
                ],
              ),

              // Form
              Form(
                key: formKey,
                child: Padding(
                  padding: const EdgeInsets.symmetric(
                      vertical: TSizes.spaceBtwSections),
                  child: Column(
                    children: [
                      // Email
                      TextFormField(
                        controller: emailController,
                        keyboardType: TextInputType.emailAddress,
                        validator: (value) {
                          if (value == null || value.isEmpty) {
                            return 'Please enter a valid email';
                          }
                          if (!value.contains('@')) {
                            return 'Please enter a valid email';
                          }
                          return null;
                        },
                        decoration: const InputDecoration(
                          prefixIcon: Icon(Iconsax.direct_right_bold),
                          labelText: TTexts.email,
                        ),
                      ),
                      const SizedBox(height: TSizes.spaceBtwinputFields),

                      // ✅ Password with functional visibility toggle
                      TextFormField(
                        controller: passwordController,
                        obscureText: _obscurePassword,
                        validator: (value) {
                          if (value == null || value.isEmpty) {
                            return 'Please enter your password';
                          }
                          if (value.length < 8) {
                            return 'Password must be at least 8 characters';
                          }
                          return null;
                        },
                        decoration: InputDecoration(
                          prefixIcon: const Icon(Iconsax.password_check_bold),
                          labelText: TTexts.password,
                          suffixIcon: IconButton(
                            icon: Icon(
                              _obscurePassword
                                  ? Iconsax.eye_slash_bold
                                  : Iconsax.eye_bold,
                            ),
                            onPressed: () => setState(
                                () => _obscurePassword = !_obscurePassword),
                          ),
                        ),
                      ),
                      const SizedBox(height: TSizes.spaceBtwinputFields / 2),

                      // Remember me + Forgot password
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Row(
                            children: [
                              Checkbox(
                                value: rememberMe,
                                onChanged: (value) {
                                  setState(() {
                                    rememberMe = value ?? false;
                                  });
                                },
                              ),
                              const Text(TTexts.rememberMe),
                            ],
                          ),
                          TextButton(
                            onPressed: _showForgotPasswordDialog,
                            child: const Text(TTexts.forgetPassword),
                          ),
                        ],
                      ),

                      // Login button
                      SizedBox(
                        width: double.infinity,
                        child: ElevatedButton(
                          onPressed: () async {
                            final ctx = context;
                            final messenger = ScaffoldMessenger.of(ctx);
                            final email = emailController.text.trim();
                            final password = passwordController.text.trim();

                            if (formKey.currentState!.validate()) {
                              await AuthPreferences.saveLoginCredentials(
                                  email, password, rememberMe);

                              // ✅ signInWithEmailAndPassword now returns bool
                              // ✅ Navigation happens here only, not also inside the controller
                              final success = await ref
                                  .read(authControllerProvider.notifier)
                                  .signInWithEmailAndPassword(
                                      messenger, email, password);

                              if (success && ctx.mounted) {
                                Navigator.pushAndRemoveUntil(
                                  ctx,
                                  MaterialPageRoute(
                                      builder: (context) => const MainLayout()),
                                  (route) => false,
                                );
                              }
                            }
                          },
                          child: const Text(TTexts.logInTitle),
                        ),
                      ),
                      const SizedBox(height: TSizes.spaceBtwItems),

                      // Sign up link
                      Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          const Text("Don't have an account?"),
                          TextButton(
                            onPressed: () {
                              Navigator.push(
                                context,
                                MaterialPageRoute(
                                  builder: (context) => const SignUpScreen(),
                                ),
                              );
                            },
                            child: const Text(
                              TTexts.createAccount,
                              style: TextStyle(fontWeight: FontWeight.bold),
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ),

              // ✅ Added form divider before social login (was missing, inconsistent with SignUpScreen)
              const TFormDivider(dividerText: TTexts.orSignInWith),
              const SizedBox(height: TSizes.spaceBtwSections),

              // ✅ Removed dangling SizedBox — just the Google button now
              Container(
                decoration: BoxDecoration(
                  border: Border.all(color: Colors.greenAccent),
                  borderRadius: BorderRadius.circular(100),
                ),
                child: IconButton(
                  onPressed: () async {
                    final success = await ref
                        .read(authControllerProvider.notifier)
                        .signInWithGoogle(context);

                    if (success && context.mounted) {
                      Navigator.pushAndRemoveUntil(
                        context,
                        MaterialPageRoute(
                            builder: (context) => const MainLayout()),
                        (route) => false,
                      );
                    }
                  },
                  icon: const Image(
                    width: TSizes.iconMd,
                    height: TSizes.iconMd,
                    image: AssetImage(TImages.google),
                  ),
                ),
              ),
              const SizedBox(height: TSizes.spaceBtwSections),
            ],
          ),
        ),
      ),
    );
  }
}
