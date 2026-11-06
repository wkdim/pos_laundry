import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart';
import 'package:provider/provider.dart';
import '../../core/constants/app_colors.dart';
import '../../core/database/database_helper.dart';
import '../../core/utils/theme_provider.dart';
import '../dashboard/dashboard_screen.dart';

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  _LoginScreenState createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  final _user = TextEditingController();
  final _pass = TextEditingController();
  bool _obscure = true, _loading = false;

  void _login() async {
    if (_user.text.isEmpty || _pass.text.isEmpty) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('Enter username and password')));
      return;
    }
    setState(() => _loading = true);
    try {
      final admin = await DatabaseHelper.instance.login(_user.text, _pass.text);
      if (!mounted) return;
      setState(() => _loading = false);
      if (admin != null) {
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(builder: (_) => DashboardScreen(admin: admin)),
        );
      } else {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('Invalid credentials')));
      }
    } catch (e) {
      if (!mounted) return;
      setState(() => _loading = false);
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('Error: $e')));
    }
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Provider.of<ThemeProvider>(context).isDarkMode;

    // prefer explicit platform detection but fall back to width for safety
    final bool isMobilePlatform =
        defaultTargetPlatform == TargetPlatform.android ||
        defaultTargetPlatform == TargetPlatform.iOS ||
        MediaQuery.of(context).size.width < 600;

    final iconSize = isMobilePlatform ? 48.0 : 60.0;
    final titleSize = isMobilePlatform ? 22.0 : 28.0;

    return Scaffold(
      body: isMobilePlatform
          ? SafeArea(
              child: Container(
                color: AppColors2.bg,
                width: double.infinity,
                child: Center(
                  child: SingleChildScrollView(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 16,
                      vertical: 28,
                    ),
                    child: Container(
                      constraints: const BoxConstraints(maxWidth: 520),
                      padding: const EdgeInsets.symmetric(
                        horizontal: 20,
                        vertical: 24,
                      ),
                      decoration: BoxDecoration(
                        color: AppColors2.surface,
                        border: Border.all(color: AppColors2.border),
                        borderRadius: BorderRadius.circular(16),
                      ),
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Container(
                            padding: const EdgeInsets.all(14),
                            decoration: BoxDecoration(
                              color: AppColors2.blue.withValues(alpha: 0.08),
                              shape: BoxShape.circle,
                            ),
                            child: const Icon(
                              Icons.local_laundry_service,
                              size: 44,
                              color: AppColors2.blue,
                            ),
                          ),
                          const SizedBox(height: 12),
                          Text(
                            'Laundry POS Pro',
                            style: const TextStyle(
                              fontSize: 20,
                              fontWeight: FontWeight.w800,
                              color: AppColors2.textPrimary,
                            ),
                          ),
                          const SizedBox(height: 6),
                          const Text(
                            'Sign in to continue',
                            style: TextStyle(color: AppColors2.textMuted),
                          ),
                          const SizedBox(height: 20),

                          // Username
                          TextField(
                            controller: _user,
                            style: const TextStyle(
                              color: AppColors2.textPrimary,
                            ),
                            decoration: InputDecoration(
                              hintText: 'Username',
                              hintStyle: const TextStyle(
                                color: AppColors2.textMuted,
                              ),
                              filled: true,
                              fillColor: AppColors2.surfaceHigh,
                              prefixIcon: const Icon(
                                Icons.person,
                                color: AppColors2.textMuted,
                              ),
                              border: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(12),
                                borderSide: BorderSide(
                                  color: AppColors2.border,
                                ),
                              ),
                              enabledBorder: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(12),
                                borderSide: BorderSide(
                                  color: AppColors2.border,
                                ),
                              ),
                              focusedBorder: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(12),
                                borderSide: BorderSide(
                                  color: AppColors2.blue,
                                  width: 2,
                                ),
                              ),
                            ),
                          ),
                          const SizedBox(height: 12),

                          // Password
                          TextField(
                            controller: _pass,
                            obscureText: _obscure,
                            style: const TextStyle(
                              color: AppColors2.textPrimary,
                            ),
                            decoration: InputDecoration(
                              hintText: 'Password',
                              hintStyle: const TextStyle(
                                color: AppColors2.textMuted,
                              ),
                              filled: true,
                              fillColor: AppColors2.surfaceHigh,
                              prefixIcon: const Icon(
                                Icons.lock,
                                color: AppColors2.textMuted,
                              ),
                              suffixIcon: IconButton(
                                icon: Icon(
                                  _obscure
                                      ? Icons.visibility
                                      : Icons.visibility_off,
                                  color: AppColors2.textMuted,
                                ),
                                onPressed: () =>
                                    setState(() => _obscure = !_obscure),
                              ),
                              border: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(12),
                                borderSide: BorderSide(
                                  color: AppColors2.border,
                                ),
                              ),
                              enabledBorder: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(12),
                                borderSide: BorderSide(
                                  color: AppColors2.border,
                                ),
                              ),
                              focusedBorder: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(12),
                                borderSide: BorderSide(
                                  color: AppColors2.blue,
                                  width: 2,
                                ),
                              ),
                            ),
                            onSubmitted: (_) => _login(),
                          ),

                          const SizedBox(height: 18),

                          SizedBox(
                            width: double.infinity,
                            height: 52,
                            child: ElevatedButton(
                              onPressed: _loading ? null : _login,
                              style: ElevatedButton.styleFrom(
                                backgroundColor: AppColors2.blue,
                                foregroundColor: AppColors2.textPrimary,
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(12),
                                ),
                                elevation: 0,
                              ),
                              child: _loading
                                  ? const SizedBox(
                                      width: 20,
                                      height: 20,
                                      child: CircularProgressIndicator(
                                        color: AppColors2.surface,
                                        strokeWidth: 2,
                                      ),
                                    )
                                  : const Text(
                                      'Login',
                                      style: TextStyle(
                                        fontSize: 16,
                                        fontWeight: FontWeight.w700,
                                      ),
                                    ),
                            ),
                          ),

                          const SizedBox(height: 12),

                          TextButton.icon(
                            onPressed: () => Provider.of<ThemeProvider>(
                              context,
                              listen: false,
                            ).toggleTheme(),
                            icon: Icon(
                              isDark ? Icons.light_mode : Icons.dark_mode,
                              color: AppColors2.textMuted,
                              size: 18,
                            ),
                            label: Text(
                              isDark ? 'Light Mode' : 'Dark Mode',
                              style: const TextStyle(
                                color: AppColors2.textMuted,
                              ),
                            ),
                          ),

                          const SizedBox(height: 8),
                          const Text(
                            'Username is "admin" and Password is "admin123" for demo purposes',
                            style: TextStyle(
                              fontSize: 12,
                              color: AppColors2.textMuted,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              ),
            )
          : Container(
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                  colors: isDark
                      ? [const Color(0xFF0A1929), const Color(0xFF1A2332)]
                      : [const Color(0xFF0B2347), const Color(0xFF184A90)],
                ),
              ),
              child: Center(
                child: SingleChildScrollView(
                  child: Container(
                    constraints: isMobilePlatform
                        ? null
                        : const BoxConstraints(maxWidth: 480),
                    margin: isMobilePlatform
                        ? const EdgeInsets.symmetric(
                            horizontal: 16,
                            vertical: 36,
                          )
                        : const EdgeInsets.all(24),
                    padding: isMobilePlatform
                        ? const EdgeInsets.symmetric(
                            horizontal: 20,
                            vertical: 28,
                          )
                        : const EdgeInsets.all(40),
                    decoration: BoxDecoration(
                      color: isDark ? const Color(0xFF1A2332) : Colors.white,
                      borderRadius: BorderRadius.circular(20),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withValues(alpha: isDark ? 0.5 : 0.3),
                          blurRadius: 30,
                          offset: const Offset(0, 15),
                        ),
                      ],
                    ),
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        // platform badge
                        Container(
                          padding: EdgeInsets.all(isMobilePlatform ? 16 : 20),
                          decoration: BoxDecoration(
                            color: const Color(0xFF184A90).withValues(alpha: 0.1),
                            shape: BoxShape.circle,
                          ),
                          child: Icon(
                            Icons.local_laundry_service,
                            size: iconSize,
                            color: const Color(0xFF2196F3),
                          ),
                        ),
                        SizedBox(height: isMobilePlatform ? 16 : 24),
                        Text(
                          'Laundry POS Pro',
                          style: TextStyle(
                            fontSize: titleSize,
                            fontWeight: FontWeight.bold,
                            color: isDark
                                ? Colors.white
                                : const Color(0xFF184A90),
                          ),
                        ),
                        const SizedBox(height: 8),
                        Text(
                          isMobilePlatform
                              ? 'Sign in to continue'
                              : 'Welcome back!',
                          style: TextStyle(
                            color: isDark
                                ? Colors.grey.shade400
                                : Colors.grey.shade600,
                          ),
                        ),
                        SizedBox(height: isMobilePlatform ? 24 : 40),

                        TextField(
                          controller: _user,
                          style: TextStyle(
                            color: isDark ? Colors.white : Colors.black87,
                          ),
                          decoration: InputDecoration(
                            labelText: 'Username',
                            labelStyle: TextStyle(
                              color: isDark
                                  ? Colors.grey.shade400
                                  : Colors.grey.shade700,
                            ),
                            border: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(12),
                              borderSide: BorderSide(
                                color: isDark
                                    ? Colors.grey.shade700
                                    : Colors.grey.shade300,
                              ),
                            ),
                            enabledBorder: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(12),
                              borderSide: BorderSide(
                                color: isDark
                                    ? Colors.grey.shade700
                                    : Colors.grey.shade300,
                              ),
                            ),
                            focusedBorder: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(12),
                              borderSide: const BorderSide(
                                color: Color(0xFF2196F3),
                                width: 2,
                              ),
                            ),
                            prefixIcon: Icon(
                              Icons.person,
                              color: isDark
                                  ? Colors.grey.shade400
                                  : Colors.grey.shade600,
                            ),
                            filled: true,
                            fillColor: isDark
                                ? Colors.grey.shade900
                                : Colors.grey.shade50,
                          ),
                        ),
                        const SizedBox(height: 20),
                        TextField(
                          controller: _pass,
                          obscureText: _obscure,
                          style: TextStyle(
                            color: isDark ? Colors.white : Colors.black87,
                          ),
                          decoration: InputDecoration(
                            labelText: 'Password',
                            labelStyle: TextStyle(
                              color: isDark
                                  ? Colors.grey.shade400
                                  : Colors.grey.shade700,
                            ),
                            border: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(12),
                              borderSide: BorderSide(
                                color: isDark
                                    ? Colors.grey.shade700
                                    : Colors.grey.shade300,
                              ),
                            ),
                            enabledBorder: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(12),
                              borderSide: BorderSide(
                                color: isDark
                                    ? Colors.grey.shade700
                                    : Colors.grey.shade300,
                              ),
                            ),
                            focusedBorder: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(12),
                              borderSide: const BorderSide(
                                color: Color(0xFF2196F3),
                                width: 2,
                              ),
                            ),
                            prefixIcon: Icon(
                              Icons.lock,
                              color: isDark
                                  ? Colors.grey.shade400
                                  : Colors.grey.shade600,
                            ),
                            filled: true,
                            fillColor: isDark
                                ? Colors.grey.shade900
                                : Colors.grey.shade50,
                            suffixIcon: IconButton(
                              icon: Icon(
                                _obscure
                                    ? Icons.visibility
                                    : Icons.visibility_off,
                                color: isDark
                                    ? Colors.grey.shade400
                                    : Colors.grey.shade600,
                              ),
                              onPressed: () =>
                                  setState(() => _obscure = !_obscure),
                            ),
                          ),
                          onSubmitted: (_) => _login(),
                        ),
                        const SizedBox(height: 30),
                        SizedBox(
                          width: double.infinity,
                          height: 55,
                          child: ElevatedButton(
                            onPressed: _loading ? null : _login,
                            style: ElevatedButton.styleFrom(
                              backgroundColor: const Color(0xFF2196F3),
                              foregroundColor: Colors.white,
                              disabledBackgroundColor: isDark
                                  ? Colors.grey.shade800
                                  : Colors.grey.shade300,
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(12),
                              ),
                              elevation: isDark ? 4 : 2,
                            ),
                            child: _loading
                                ? const CircularProgressIndicator(
                                    color: Colors.white,
                                  )
                                : const Text(
                                    'Login',
                                    style: TextStyle(
                                      fontSize: 18,
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                          ),
                        ),
                        const SizedBox(height: 20),

                        // Theme toggle
                        TextButton.icon(
                          onPressed: () {
                            Provider.of<ThemeProvider>(
                              context,
                              listen: false,
                            ).toggleTheme();
                          },
                          icon: Icon(
                            isDark ? Icons.light_mode : Icons.dark_mode,
                            color: isDark
                                ? Colors.grey.shade400
                                : Colors.grey.shade600,
                            size: 20,
                          ),
                          label: Text(
                            isDark ? 'Light Mode' : 'Dark Mode',
                            style: TextStyle(
                              color: isDark
                                  ? Colors.grey.shade400
                                  : Colors.grey.shade600,
                            ),
                          ),
                        ),

                        Text(
                          'Username is "admin" and Password is "admin123" for demo purposes',
                          style: TextStyle(
                            fontSize: 12,
                            color: isDark
                                ? Colors.grey.shade600
                                : Colors.grey.shade500,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ),
    );
  }
}
