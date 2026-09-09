import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart';
import 'package:provider/provider.dart';
import '../auth/login_screen.dart';
import '../../core/utils/theme_provider.dart';

class SplashScreen extends StatefulWidget {
  @override
  _SplashScreenState createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen>
    with SingleTickerProviderStateMixin {
  late AnimationController _ctrl;
  late Animation<double> _fade;

  @override
  void initState() {
    super.initState();
    _ctrl = AnimationController(duration: Duration(seconds: 2), vsync: this);
    _fade = Tween<double>(begin: 0.0, end: 1.0).animate(_ctrl);
    _ctrl.forward();
    Future.delayed(Duration(seconds: 5), () {
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(builder: (_) => LoginScreen()),
      );
    });
  }

  @override
  void dispose() {
    _ctrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Provider.of<ThemeProvider>(context).isDarkMode;

    final bool isMobilePlatform =
        defaultTargetPlatform == TargetPlatform.android ||
        defaultTargetPlatform == TargetPlatform.iOS ||
        MediaQuery.of(context).size.width < 600;

    final iconPadding = isMobilePlatform ? 20.0 : 30.0;
    final iconSize = isMobilePlatform ? 56.0 : 80.0;
    final titleSize = isMobilePlatform ? 28.0 : 36.0;
    final subtitleSize = isMobilePlatform ? 14.0 : 16.0;
    final verticalSpacing = isMobilePlatform ? 20.0 : 30.0;

    return Scaffold(
      body: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: isDark
                ? [const Color(0xFF0A1929), const Color(0xFF1A2332)]
                : [Colors.blue.shade400, Colors.blue.shade700],
          ),
        ),
        child: Center(
          child: FadeTransition(
            opacity: _fade,
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Container(
                  padding: EdgeInsets.all(iconPadding),
                  decoration: BoxDecoration(
                    color: isDark ? const Color(0xFF2196F3) : Colors.white,
                    shape: BoxShape.circle,
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withOpacity(isDark ? 0.5 : 0.26),
                        blurRadius: 20,
                        offset: Offset(0, 10),
                      ),
                    ],
                  ),
                  child: Icon(
                    Icons.local_laundry_service,
                    size: iconSize,
                    color: isDark ? Colors.white : Colors.blue.shade700,
                  ),
                ),
                SizedBox(height: verticalSpacing),
                Text(
                  'Laundry POS Pro',
                  style: TextStyle(
                    fontSize: titleSize,
                    fontWeight: FontWeight.bold,
                    color: Colors.white,
                  ),
                ),
                SizedBox(height: 8),
                Text(
                  'Professional Management System',
                  style: TextStyle(
                    fontSize: subtitleSize,
                    color: isDark ? Colors.white60 : Colors.white70,
                  ),
                ),
                const SizedBox(height: 16),

                SizedBox(height: isMobilePlatform ? 20 : 40),
                CircularProgressIndicator(color: Colors.white, strokeWidth: 3),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
