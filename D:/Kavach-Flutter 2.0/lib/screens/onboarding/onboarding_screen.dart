import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:url_launcher/url_launcher.dart';
import '../../core/utils/local_storage.dart';
import '../../providers/auth_provider.dart';

class OnboardSlide {
  final String emoji;
  final String title;
  final String desc;
  final Color color;

  OnboardSlide({
    required this.emoji,
    required this.title,
    required this.desc,
    required this.color,
  });
}

class OnboardingScreen extends StatefulWidget {
  const OnboardingScreen({super.key});

  @override
  State<OnboardingScreen> createState() => _OnboardingScreenState();
}

class _OnboardingScreenState extends State<OnboardingScreen> {
  final PageController _pageController = PageController();
  final LocalStorage _storage = LocalStorage();
  int _currentIndex = 0;

  final List<OnboardSlide> _slides = [
    OnboardSlide(
      emoji: '🛡️',
      title: 'Welcome to KavachBot',
      desc: 'KavachBot powered by Digikavach Technologies Private Limited is India\'s AI-powered scam shield. We check messages, calls, QR codes, and files for fraud — before you fall victim.',
      color: const Color(0xFF028090),
    ),
    OnboardSlide(
      emoji: '🔍',
      title: 'Check any suspicious message',
      desc: 'Got a message asking for OTP, KYC, or money? Paste it in and our 4-tier detection engine analyses it in under 4 seconds.',
      color: const Color(0xFF2563EB),
    ),
    OnboardSlide(
      emoji: '📷',
      title: 'Scan QR codes & files',
      desc: 'Scan payment QR codes before paying. Upload APK files or PDFs to check for malware and phishing content.',
      color: const Color(0xFF7C3AED),
    ),
    OnboardSlide(
      emoji: '🚨',
      title: 'Emergency SOS',
      desc: 'If you\'re being scammed right now, tap Emergency SOS. We\'ll help you freeze accounts and file a cybercrime report instantly.',
      color: const Color(0xFFDC2626),
    ),
    OnboardSlide(
      emoji: '📞',
      title: 'National Cybercrime Helpline',
      desc: 'Remember: If in doubt, call 1930. It\'s free, available 24/7, and works in all Indian states. DigiKavach always shows you this number.',
      color: const Color(0xFF059669),
    ),
  ];

  void _onPageChanged(int index) {
    setState(() {
      _currentIndex = index;
    });
  }

  Future<void> _finishOnboarding() async {
    await _storage.setOnboarded(true);
    if (mounted) {
      Navigator.pushReplacementNamed(context, '/terms-accept');
    }
  }

  Future<void> _skipOnboarding() async {
    await _storage.setOnboarded(true);
    if (mounted) {
      Navigator.pushReplacementNamed(context, '/terms-accept');
    }
  }

  @override
  Widget build(BuildContext context) {
    final currentSlide = _slides[_currentIndex];
    final isLast = _currentIndex == _slides.length - 1;

    return Scaffold(
      body: Container(
        color: currentSlide.color.withOpacity(0.05),
        child: SafeArea(
          child: Column(
            children: [
              // Header Banner & Skip button
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 8.0),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      'KavachBot',
                      style: Theme.of(context).textTheme.titleLarge?.copyWith(
                        fontWeight: FontWeight.bold,
                        color: currentSlide.color,
                      ),
                    ),
                    if (!isLast)
                      TextButton(
                        onPressed: _skipOnboarding,
                        child: Text(
                          'Skip',
                          style: TextStyle(
                            color: currentSlide.color,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      )
                    else
                      const SizedBox(height: 48), // Spacer to maintain alignment
                  ],
                ),
              ),
              const SizedBox(height: 8),
              // Step counter
              Text(
                'Step ${_currentIndex + 1} of ${_slides.length}',
                style: TextStyle(
                  color: currentSlide.color,
                  fontWeight: FontWeight.w600,
                  fontSize: 14,
                ),
              ),
              const SizedBox(height: 8),
              // Slide Progress Bar
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 48.0),
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(4),
                  child: LinearProgressIndicator(
                    value: (_currentIndex + 1) / _slides.length,
                    backgroundColor: currentSlide.color.withOpacity(0.1),
                    valueColor: AlwaysStoppedAnimation<Color>(currentSlide.color),
                    minHeight: 6,
                  ),
                ),
              ),
              // Carousel Slides
              Expanded(
                child: PageView.builder(
                  controller: _pageController,
                  onPageChanged: _onPageChanged,
                  itemCount: _slides.length,
                  itemBuilder: (context, index) {
                    final slide = _slides[index];
                    return Padding(
                      padding: const EdgeInsets.all(32.0),
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Text(
                            slide.emoji,
                            style: const TextStyle(fontSize: 100),
                          ),
                          const SizedBox(height: 32),
                          Text(
                            slide.title,
                            textAlign: TextAlign.center,
                            style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                              fontWeight: FontWeight.bold,
                              color: slide.color,
                            ),
                          ),
                          const SizedBox(height: 16),
                          Text(
                            slide.desc,
                            textAlign: TextAlign.center,
                            style: const TextStyle(
                              fontSize: 16,
                              height: 1.5,
                              color: Colors.black87,
                            ),
                          ),
                        ],
                      ),
                    );
                  },
                ),
              ),
              // Dots indicator
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: List.generate(
                  _slides.length,
                  (index) => Container(
                    margin: const EdgeInsets.symmetric(horizontal: 4),
                    width: _currentIndex == index ? 12 : 8,
                    height: 8,
                    decoration: BoxDecoration(
                      color: _currentIndex == index 
                        ? currentSlide.color 
                        : currentSlide.color.withOpacity(0.2),
                      borderRadius: BorderRadius.circular(4),
                    ),
                  ),
                ),
              ),
              const SizedBox(height: 32),
              // Next / Action Button
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 32.0),
                child: SizedBox(
                  width: double.infinity,
                  child: ElevatedButton(
                    onPressed: () {
                      if (isLast) {
                        _finishOnboarding();
                      } else {
                        _pageController.nextPage(
                          duration: const Duration(milliseconds: 300),
                          curve: Curves.easeIn,
                        );
                      }
                    },
                    style: ElevatedButton.styleFrom(
                      backgroundColor: currentSlide.color,
                      padding: const EdgeInsets.symmetric(vertical: 16),
                    ),
                    child: Text(
                      isLast ? 'Get Started →' : 'Next →',
                      style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                    ),
                  ),
                ),
              ),
              const SizedBox(height: 16),
              // Helpline link on last page
              if (isLast)
                Padding(
                  padding: const EdgeInsets.only(bottom: 24.0),
                  child: InkWell(
                    onTap: () async {
                      final url = Uri.parse('tel:1930');
                      if (await canLaunchUrl(url)) {
                        await launchUrl(url);
                      }
                    },
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        const Text(
                          '📞 Cybercrime Helpline: ',
                          style: TextStyle(fontWeight: FontWeight.w600, color: Colors.black54),
                        ),
                        Text(
                          '1930',
                          style: TextStyle(
                            fontWeight: FontWeight.bold,
                            color: currentSlide.color,
                            decoration: TextDecoration.underline,
                          ),
                        ),
                      ],
                    ),
                  ),
                )
              else
                const SizedBox(height: 40),
            ],
          ),
        ),
      ),
    );
  }
}
