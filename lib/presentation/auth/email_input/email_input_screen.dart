import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:fmp_app/presentation/auth/auth_controller.dart';

// lib/presentation/auth/email_input/email_input_screen.dart

class EmailInputScreen extends StatefulWidget {
  const EmailInputScreen({super.key});

  @override
  State<EmailInputScreen> createState() => _EmailInputScreenState();
}

class _EmailInputScreenState extends State<EmailInputScreen>
    with SingleTickerProviderStateMixin {
  final _formKey   = GlobalKey<FormState>();
  final _emailCtrl = TextEditingController();
  late AnimationController _animCtrl;
  late Animation<double> _fadeAnim;
  late Animation<Offset> _slideAnim;

  @override
  void initState() {
    super.initState();
    _animCtrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 600),
    );
    _fadeAnim  = CurvedAnimation(parent: _animCtrl, curve: Curves.easeOut);
    _slideAnim = Tween<Offset>(
      begin: const Offset(0, 0.06),
      end: Offset.zero,
    ).animate(CurvedAnimation(parent: _animCtrl, curve: Curves.easeOut));
    _animCtrl.forward();
  }

  @override
  void dispose() {
    _emailCtrl.dispose();
    _animCtrl.dispose();
    super.dispose();
  }

  Future<void> _sendOtp(BuildContext context) async {
    final auth = context.read<AuthController>();
    if (!_formKey.currentState!.validate()) return;
    auth.setEmail(_emailCtrl.text.trim());
    await auth.sendOtp();
    if (!mounted) return;
    if (auth.stage == AuthStage.otpSent) {
      Navigator.pushNamed(context, '/otp');
    }
  }

  @override
  Widget build(BuildContext context) {
    final auth = context.watch<AuthController>();
    final isLoading = auth.stage == AuthStage.otpSending;

    return Scaffold(
      backgroundColor: const Color(0xFFF4F6FA),
      body: SafeArea(
        child: FadeTransition(
          opacity: _fadeAnim,
          child: SlideTransition(
            position: _slideAnim,
            child: SingleChildScrollView(
              padding: const EdgeInsets.symmetric(horizontal: 24),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const SizedBox(height: 48),

                  // ── Brand ──────────────────────────────────────────────────
                  _BrandMark(),
                  const SizedBox(height: 40),

                  // ── Headline ───────────────────────────────────────────────
                  const Text(
                    'Welcome back',
                    style: TextStyle(
                      fontSize: 30, fontWeight: FontWeight.w800,
                      color: Color(0xFF111827), letterSpacing: -0.5,
                    ),
                  ),
                  const SizedBox(height: 6),
                  const Text(
                    'Enter your email address to continue',
                    style: TextStyle(
                      fontSize: 15, color: Color(0xFF6B7280), height: 1.5,
                    ),
                  ),
                  const SizedBox(height: 36),

                  // ── Form ───────────────────────────────────────────────────
                  Form(
                    key: _formKey,
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text(
                          'Email Address',
                          style: TextStyle(
                            fontSize: 14, fontWeight: FontWeight.w500,
                            color: Color(0xFF374151),
                          ),
                        ),
                        const SizedBox(height: 6),
                        TextFormField(
                          controller: _emailCtrl,
                          keyboardType: TextInputType.emailAddress,
                          textInputAction: TextInputAction.done,
                          autocorrect: false,
                          onFieldSubmitted: (_) => _sendOtp(context),
                          style: const TextStyle(
                            fontSize: 16, fontWeight: FontWeight.w500,
                            color: Color(0xFF111827),
                          ),
                          decoration: InputDecoration(
                            hintText: 'you@example.com',
                            filled: true,
                            fillColor: Colors.white,
                            contentPadding: const EdgeInsets.symmetric(
                              horizontal: 16, vertical: 15,
                            ),
                            prefixIcon: const Padding(
                              padding: EdgeInsets.symmetric(horizontal: 14),
                              child: Icon(
                                Icons.mail_outline_rounded,
                                color: Color(0xFF6B7280),
                                size: 20,
                              ),
                            ),
                            border: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(12),
                              borderSide: const BorderSide(color: Color(0xFFE5E9F0), width: 1.5),
                            ),
                            enabledBorder: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(12),
                              borderSide: const BorderSide(color: Color(0xFFE5E9F0), width: 1.5),
                            ),
                            focusedBorder: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(12),
                              borderSide: const BorderSide(color: Color(0xFF1A56DB), width: 2),
                            ),
                            errorBorder: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(12),
                              borderSide: const BorderSide(color: Color(0xFFE02424), width: 1.5),
                            ),
                            focusedErrorBorder: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(12),
                              borderSide: const BorderSide(color: Color(0xFFE02424), width: 2),
                            ),
                          ),
                          validator: (v) {
                            final s = v?.trim() ?? '';
                            final emailRegex = RegExp(r'^[\w\.\+\-]+@[\w\-]+\.[a-zA-Z]{2,}$');
                            if (s.isEmpty) return 'Please enter your email address';
                            if (!emailRegex.hasMatch(s)) return 'Enter a valid email address';
                            return null;
                          },
                        ),
                        const SizedBox(height: 28),

                        // ── CTA Button ────────────────────────────────────────
                        SizedBox(
                          width: double.infinity,
                          height: 52,
                          child: ElevatedButton(
                            onPressed: isLoading ? null : () => _sendOtp(context),
                            style: ElevatedButton.styleFrom(
                              backgroundColor: const Color(0xFF1A56DB),
                              disabledBackgroundColor: const Color(0xFF1A56DB).withOpacity(0.6),
                              elevation: 0,
                              shadowColor: Colors.transparent,
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(12),
                              ),
                            ),
                            child: isLoading
                                ? const SizedBox(
                                    width: 20, height: 20,
                                    child: CircularProgressIndicator(
                                      strokeWidth: 2.5,
                                      valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                                    ),
                                  )
                                : const Row(
                                    mainAxisAlignment: MainAxisAlignment.center,
                                    children: [
                                      Text(
                                        'Send OTP',
                                        style: TextStyle(
                                          fontSize: 15, fontWeight: FontWeight.w600,
                                          color: Colors.white,
                                        ),
                                      ),
                                      SizedBox(width: 8),
                                      Icon(Icons.arrow_forward_rounded, size: 18, color: Colors.white),
                                    ],
                                  ),
                          ),
                        ),
                      ],
                    ),
                  ),

                  // ── Error message ──────────────────────────────────────────
                  if (auth.stage == AuthStage.error && auth.errorMessage != null) ...[
                    const SizedBox(height: 16),
                    _ErrorBanner(message: auth.errorMessage!),
                  ],

                  const SizedBox(height: 40),

                  // ── Footer note ────────────────────────────────────────────
                  Center(
                    child: Text(
                      'By continuing you agree to our Terms & Privacy Policy',
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        fontSize: 12, color: Colors.grey.shade500, height: 1.5,
                      ),
                    ),
                  ),
                  const SizedBox(height: 32),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}

// ── Brand mark ────────────────────────────────────────────────────────────────
class _BrandMark extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Container(
          width: 48, height: 48,
          decoration: BoxDecoration(
            gradient: const LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: [Color(0xFF1A56DB), Color(0xFF0C3997)],
            ),
            borderRadius: BorderRadius.circular(14),
            boxShadow: [
              BoxShadow(
                color: const Color(0xFF1A56DB).withOpacity(0.3),
                blurRadius: 16,
                offset: const Offset(0, 6),
              ),
            ],
          ),
          child: const Icon(Icons.local_shipping_rounded, color: Colors.white, size: 24),
        ),
        const SizedBox(width: 12),
        const Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('FleetOS', style: TextStyle(fontSize: 18, fontWeight: FontWeight.w800, color: Color(0xFF111827), letterSpacing: -0.3)),
            Text('Logistics Platform', style: TextStyle(fontSize: 12, color: Color(0xFF6B7280), fontWeight: FontWeight.w400)),
          ],
        ),
      ],
    );
  }
}

// ── Error Banner ──────────────────────────────────────────────────────────────
class _ErrorBanner extends StatelessWidget {
  final String message;
  const _ErrorBanner({required this.message});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
      decoration: BoxDecoration(
        color: const Color(0xFFFDE8E8),
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: const Color(0xFFF8B4B4), width: 1),
      ),
      child: Row(
        children: [
          const Icon(Icons.error_outline_rounded, size: 18, color: Color(0xFFE02424)),
          const SizedBox(width: 10),
          Expanded(
            child: Text(
              message,
              style: const TextStyle(fontSize: 13, color: Color(0xFFE02424), height: 1.4),
            ),
          ),
        ],
      ),
    );
  }
}