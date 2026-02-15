import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'dart:async';

class WelcomeScreen extends StatefulWidget {
  const WelcomeScreen({super.key});

  @override
  State<WelcomeScreen> createState() => _WelcomeScreenState();
}

class _WelcomeScreenState extends State<WelcomeScreen>
    with TickerProviderStateMixin {
  late AnimationController _fadeController;
  late AnimationController _slideController;
  late AnimationController _lensFlareController;
  late List<AnimationController> _letterControllers;
  late Animation<double> _fadeAnimation;
  late Animation<Offset> _slideAnimation;
  late List<Animation<double>> _letterAnimations;

  final String welcomeText = "Welcome to...";
  final List<String> letters = [];

  @override
  void initState() {
    super.initState();
    letters.addAll(welcomeText.split(''));

    _fadeController = AnimationController(
      duration: const Duration(milliseconds: 800),
      vsync: this,
    );

    _slideController = AnimationController(
      duration: const Duration(milliseconds: 800),
      vsync: this,
    );

    // Lens flare slow movement
    _lensFlareController = AnimationController(
      duration: const Duration(seconds: 8), // Very slow for subtle effect
      vsync: this,
    );

    _fadeAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(parent: _fadeController, curve: Curves.easeIn),
    );

    _slideAnimation = Tween<Offset>(
      begin: const Offset(0, 0.5),
      end: Offset.zero,
    ).animate(
      CurvedAnimation(parent: _slideController, curve: Curves.easeOut),
    );

    // Original letter-by-letter animation (all together, no wave)
    _letterControllers = List.generate(
      letters.length,
      (index) => AnimationController(
        duration: const Duration(milliseconds: 1500),
        vsync: this,
      ),
    );

    _letterAnimations = _letterControllers.map((controller) {
      return Tween<double>(begin: 0.0, end: -8.0).animate(
        CurvedAnimation(parent: controller, curve: Curves.easeInOut),
      );
    }).toList();

    _fadeController.forward();
    _slideController.forward();
    _lensFlareController.repeat(reverse: true);

    // Start all letters at the same time (no stagger)
    for (int i = 0; i < _letterControllers.length; i++) {
      if (letters[i] != ' ') {
        _letterControllers[i].repeat(reverse: true);
      }
    }
  }

  @override
  void dispose() {
    _fadeController.dispose();
    _slideController.dispose();
    _lensFlareController.dispose();
    for (var controller in _letterControllers) {
      controller.dispose();
    }
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Stack(
        children: [
          // Original content
          Container(
            decoration: const BoxDecoration(
              image: DecorationImage(
                image: AssetImage('assets/tree1.png'),
                fit: BoxFit.cover,
                alignment: Alignment.center,
              ),
            ),
            child: Container(
              decoration: BoxDecoration(
                color: Colors.black.withOpacity(0.4),
              ),
              child: SafeArea(
                child: Column(
                  children: [
                    Expanded(
                      child: FadeTransition(
                        opacity: _fadeAnimation,
                        child: SlideTransition(
                          position: _slideAnimation,
                          child: Padding(
                            padding: const EdgeInsets.symmetric(horizontal: 30),
                            child: Column(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                            // Welcome text - original letter-by-letter animation
                            Row(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: List.generate(
                                letters.length,
                                (index) {
                                  if (letters[index] == ' ') {
                                    return const Text(
                                      '\u00A0',
                                      style: TextStyle(fontSize: 28),
                                    );
                                  }
                                  return AnimatedBuilder(
                                    animation: _letterAnimations[index],
                                    builder: (context, child) {
                                      return Transform.translate(
                                        offset: Offset(0, _letterAnimations[index].value),
                                        child: child,
                                      );
                                    },
                                    child: Text(
                                      letters[index],
                                      style: const TextStyle(
                                        fontSize: 28,
                                        fontWeight: FontWeight.w400,
                                        fontStyle: FontStyle.italic,
                                        color: Colors.white,
                                        letterSpacing: 1,
                                        shadows: [
                                          Shadow(
                                            color: Colors.black87,
                                            offset: Offset(0, 2),
                                            blurRadius: 4,
                                          ),
                                        ],
                                      ),
                                    ),
                                  );
                                },
                              ),
                            ),

                            const SizedBox(height: 8),
                            const Text(
                              'Andrographis',
                              style: TextStyle(
                                fontSize: 43,
                                fontWeight: FontWeight.bold,
                                color: Colors.white,
                                letterSpacing: 2,
                                shadows: [
                                  Shadow(
                                    color: Color(0xFF2D5016),
                                    offset: Offset(2, 2),
                                    blurRadius: 1,
                                  ),
                                ],
                              ),
                            ),
                            const SizedBox(height: 15),
                            const Text(
                              'Your Smart Farming Journey Starts Here',
                              style: TextStyle(
                                fontSize: 14,
                                color: Colors.white,
                                fontStyle: FontStyle.italic,
                                shadows: [
                                  Shadow(
                                    color: Colors.black87,
                                    offset: Offset(0, 1),
                                    blurRadius: 2,
                                  ),
                                ],
                              ),
                            ),
                            const SizedBox(height: 15),
                            Container(
                              width: 60,
                              height: 2,
                              color: const Color(0xFF2D5016),
                            ),
                            const SizedBox(height: 35),
                            // Login Button
                            SizedBox(
                              width: double.infinity,
                              child: ElevatedButton(
                                onPressed: () => context.go('/login'),
                                style: ElevatedButton.styleFrom(
                                  backgroundColor: const Color(0x8B8BC34A),
                                  padding: const EdgeInsets.symmetric(vertical: 15),
                                  shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(25),
                                  ),
                                  elevation: 5,
                                  shadowColor: Colors.black,
                                ),
                                child: const Text(
                                  'LOGIN',
                                  style: TextStyle(
                                    color: Colors.white,
                                    fontSize: 18,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                              ),
                            ),
                            const SizedBox(height: 15),
                            // Register Button
                            SizedBox(
                              width: double.infinity,
                              child: ElevatedButton(
                                onPressed: () => context.go('/register'),
                                style: ElevatedButton.styleFrom(
                                  backgroundColor: const Color(0x8B8BC34A),
                                  padding: const EdgeInsets.symmetric(vertical: 15),
                                  shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(25),
                                  ),
                                  elevation: 5,
                                  shadowColor: Colors.black,
                                ),
                                child: const Text(
                                  'REGISTER',
                                  style: TextStyle(
                                    color: Colors.white,
                                    fontSize: 18,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                              ),
                            ),
                            const SizedBox(height: 10),
                            const Padding(
                              padding: EdgeInsets.symmetric(horizontal: 20),
                              child: Text(
                                '*Please login first before using cultivation, specific vegetable, and farm management.',
                                textAlign: TextAlign.center,
                                style: TextStyle(
                                  color: Colors.white,
                                  fontSize: 11,
                                  shadows: [
                                    Shadow(
                                      color: Colors.black87,
                                      offset: Offset(0, 1),
                                      blurRadius: 2,
                                    ),
                                  ],
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
                ),
                // Footer
                Padding(
                  padding: const EdgeInsets.all(30),
                  child: Column(
                    children: [
                      Row(
                        children: const [
                          Icon(Icons.facebook, color: Colors.white, size: 20),
                          SizedBox(width: 5),
                          Text(
                            ': Andrographis Smart farm',
                            style: TextStyle(
                              color: Colors.white,
                              fontSize: 12,
                              shadows: [
                                Shadow(
                                  color: Colors.black87,
                                  offset: Offset(0, 1),
                                  blurRadius: 2,
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 5),
                      Row(
                        children: const [
                          Icon(Icons.phone, color: Colors.white, size: 16),
                          SizedBox(width: 5),
                          Text(
                            ': 093-5899990',
                            style: TextStyle(
                              color: Colors.white,
                              fontSize: 12,
                              shadows: [
                                Shadow(
                                  color: Colors.black87,
                                  offset: Offset(0, 1),
                                  blurRadius: 2,
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
        // Lens Flare Effect Overlay
        IgnorePointer(
          child: AnimatedBuilder(
            animation: _lensFlareController,
            builder: (context, child) {
              final screenWidth = MediaQuery.of(context).size.width;
              final screenHeight = MediaQuery.of(context).size.height;
              
              return Stack(
                children: [
                  // Large main flare
                  Positioned(
                    left: screenWidth * (0.1 + _lensFlareController.value * 0.6),
                    top: screenHeight * (0.15 + _lensFlareController.value * 0.2),
                    child: Container(
                      width: 120,
                      height: 120,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        gradient: RadialGradient(
                          colors: [
                            Colors.white.withOpacity(0.3),
                            Colors.orange.withOpacity(0.15),
                            Colors.transparent,
                          ],
                          stops: const [0.0, 0.4, 1.0],
                        ),
                      ),
                    ),
                  ),
                  // Medium flare
                  Positioned(
                    left: screenWidth * (0.3 + _lensFlareController.value * 0.4),
                    top: screenHeight * (0.4 + _lensFlareController.value * 0.15),
                    child: Container(
                      width: 80,
                      height: 80,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        gradient: RadialGradient(
                          colors: [
                            Colors.yellow.withOpacity(0.25),
                            Colors.orange.withOpacity(0.1),
                            Colors.transparent,
                          ],
                          stops: const [0.0, 0.5, 1.0],
                        ),
                      ),
                    ),
                  ),
                  // Small flare
                  Positioned(
                    left: screenWidth * (0.6 + _lensFlareController.value * 0.3),
                    top: screenHeight * (0.25 + _lensFlareController.value * 0.3),
                    child: Container(
                      width: 50,
                      height: 50,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        gradient: RadialGradient(
                          colors: [
                            Colors.white.withOpacity(0.2),
                            Colors.yellow.withOpacity(0.08),
                            Colors.transparent,
                          ],
                          stops: const [0.0, 0.6, 1.0],
                        ),
                      ),
                    ),
                  ),
                ],
              );
            },
          ),
        ),
        ],
      ),
    );
  }
}
