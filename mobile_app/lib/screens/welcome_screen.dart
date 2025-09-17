import 'package:flutter/material.dart';

class WelcomeScreen extends StatefulWidget {
  const WelcomeScreen({super.key});

  @override
  State<WelcomeScreen> createState() => _WelcomeScreenState();
}

class _WelcomeScreenState extends State<WelcomeScreen> {
  final PageController _pageController = PageController();
  int _currentPage = 0;

  @override
  void dispose() {
    _pageController.dispose();
    super.dispose();
  }

  // Function to build a single onboarding page
  Widget _buildPage({
    required IconData icon,
    required String title,
    required String subtitle,
    required String buttonText,
    required VoidCallback onButtonPressed,
  }) {
    return Padding(
      padding: const EdgeInsets.all(24.0),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          // Placeholder icon for illustration
          Icon(
            icon,
            size: 120.0,
            color: Theme.of(context).primaryColor,
          ),
          const SizedBox(height: 40.0),
          // Title
          Text(
            title,
            textAlign: TextAlign.center,
            style: const TextStyle(
              fontSize: 28.0,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 16.0),
          // Subtitle
          Text(
            subtitle,
            textAlign: TextAlign.center,
            style: TextStyle(
              fontSize: 18.0,
              color: Colors.grey[600],
            ),
          ),
          const SizedBox(height: 60.0),
          // Action button
          SizedBox(
            width: double.infinity,
            height: 50.0,
            child: ElevatedButton(
              onPressed: onButtonPressed,
              style: ElevatedButton.styleFrom(
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(10.0),
                ),
              ),
              child: Text(
                buttonText,
                style: const TextStyle(fontSize: 18.0),
              ),
            ),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Column(
        children: [
          Expanded(
            child: PageView(
              controller: _pageController,
              onPageChanged: (int page) {
                setState(() {
                  _currentPage = page;
                });
              },
              children: [
                // Page 1: Welcome to Swasthya-Setu
                _buildPage(
                  icon: Icons.local_hospital,
                  title: 'Swasthya-Setu',
                  subtitle: 'Your Village\'s Digital Clinic',
                  buttonText: 'Next',
                  onButtonPressed: () {
                    _pageController.nextPage(
                      duration: const Duration(milliseconds: 300),
                      curve: Curves.easeIn,
                    );
                  },
                ),
                // Page 2: Talk to a Doctor
                _buildPage(
                  icon: Icons.video_call,
                  title: 'Talk to a Doctor from Home',
                  subtitle: 'No need to travel for hours',
                  buttonText: 'Next',
                  onButtonPressed: () {
                    _pageController.nextPage(
                      duration: const Duration(milliseconds: 300),
                      curve: Curves.easeIn,
                    );
                  },
                ),
                // Page 3: Offline Health Records
                _buildPage(
                  icon: Icons.folder_off,
                  title: 'Health Records, Always with You',
                  subtitle: 'Works even without an internet connection',
                  buttonText: 'Get Started',
                  onButtonPressed: () {
                    // Navigate to the AuthGate which handles authentication state
                    Navigator.of(context).pushReplacementNamed('/auth_gate');
                  },
                ),
              ],
            ),
          ),
          // Page indicator dots
          Container(
            margin: const EdgeInsets.only(bottom: 30.0),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: List.generate(3, (index) => _buildDot(index)),
            ),
          ),
        ],
      ),
    );
  }

  // Helper to build page indicator dots
  Widget _buildDot(int index) {
    return AnimatedContainer(
      duration: const Duration(milliseconds: 150),
      margin: const EdgeInsets.symmetric(horizontal: 8.0),
      height: 10.0,
      width: _currentPage == index ? 24.0 : 10.0,
      decoration: BoxDecoration(
        color: _currentPage == index ? Theme.of(context).primaryColor : Colors.grey,
        borderRadius: BorderRadius.circular(5.0),
      ),
    );
  }
}
