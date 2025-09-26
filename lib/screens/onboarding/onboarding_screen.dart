import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'dart:async';
// Import your LoginScreen
import '../auth/login_screen.dart'; // Make sure this path is correct

class OnboardingScreen extends StatefulWidget {
  const OnboardingScreen({super.key});

  @override
  State<OnboardingScreen> createState() => _OnboardingScreenState();
}

class _OnboardingScreenState extends State<OnboardingScreen>
    with TickerProviderStateMixin {
  PageController _pageController = PageController();
  int _currentIndex = 0;
  Timer? _timer;
  bool _isUserInteracting = false;

  final List<OnboardingData> _slides = [
    OnboardingData(
      image: 'assets/images/bike_ride_1.png',
      title: 'Lets choose your',
      highlight: 'fav bike',
      subtitle: 'and enjoy ride',
      name: 'Prayana',
      description: 'Vestibulum tempus imperdiet sem ac porttitor. Vivamus pulvinar',
    ),
    OnboardingData(
      image: 'assets/images/bike_ride_2.png',
      title: 'Safe and secure',
      highlight: 'rides',
      subtitle: 'for everyone',
      name: 'Prayana',
      description: 'Experience the safest journey with our verified drivers and bikes',
    ),
    OnboardingData(
      image: 'assets/images/bike_ride_3.png',
      title: 'Fast delivery',
      highlight: 'service',
      subtitle: 'at your doorstep',
      name: 'Prayana',
      description: 'Quick and reliable service that gets you where you need to go',
    ),
  ];

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _startAutoScroll();
    });
  }

  void _startAutoScroll() {
    if (_timer != null && _timer!.isActive) {
      _timer!.cancel();
    }

    _timer = Timer.periodic(Duration(seconds: 4), (timer) {
      if (!_isUserInteracting && mounted) {
        int nextIndex = (_currentIndex + 1) % _slides.length;
        _pageController.animateToPage(
          nextIndex,
          duration: Duration(milliseconds: 800),
          curve: Curves.easeInOutCubic,
        );
      }
    });
  }

  void _stopAutoScroll() {
    _timer?.cancel();
    _isUserInteracting = true;
  }

  void _resumeAutoScroll() {
    _isUserInteracting = false;
    Future.delayed(Duration(seconds: 3), () {
      if (!_isUserInteracting && mounted) {
        _startAutoScroll();
      }
    });
  }

  void _navigateToLogin() {
    Navigator.pushReplacementNamed(
      context,
      '/login'
    );
  }

  @override
  void dispose() {
    _timer?.cancel();
    _pageController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final screenSize = MediaQuery.of(context).size;
    final screenHeight = screenSize.height;
    final screenWidth = screenSize.width;

    // Responsive calculations
    final bool isSmallScreen = screenHeight < 700;
    final bool isMediumScreen = screenHeight >= 700 && screenHeight < 850;
    final bool isTablet = screenWidth > 600;

    // Dynamic sizing based on screen size
    final imageSize = isSmallScreen ? screenWidth * 0.6 :
    isMediumScreen ? screenWidth * 0.65 :
    screenWidth * 0.7;
    final titleFontSize = isSmallScreen ? 22.0 :
    isMediumScreen ? 26.0 :
    28.0;
    final descriptionFontSize = isSmallScreen ? 14.0 : 16.0;
    final iconSize = isSmallScreen ? 80.0 :
    isMediumScreen ? 100.0 :
    120.0;

    return Scaffold(
      backgroundColor: Color(0xFFF5F5F5),
      body: Column(
        children: [
          // Top section with images - takes up more space now
          Expanded(
            flex: 6,
            child: Container(
              width: double.infinity,
              child: PageView.builder(
                controller: _pageController,
                onPageChanged: (index) {
                  setState(() {
                    _currentIndex = index;
                  });
                },
                itemCount: _slides.length,
                itemBuilder: (context, index) {
                  return Container(
                    padding: EdgeInsets.symmetric(
                      horizontal: screenWidth * 0.1,
                      vertical: isSmallScreen ? 20 : 40,
                    ),
                    child: Center(
                      child: Hero(
                        tag: 'onboarding_image_$index',
                        child: AnimatedContainer(
                          duration: Duration(milliseconds: 300),
                          width: imageSize.clamp(200, 350),
                          height: imageSize.clamp(200, 350),
                          decoration: BoxDecoration(
                            borderRadius: BorderRadius.circular(30),
                            boxShadow: [
                              BoxShadow(
                                color: Colors.black.withOpacity(0.15),
                                blurRadius: 25,
                                offset: Offset(0, 15),
                                spreadRadius: 0,
                              ),
                            ],
                          ),
                          child: ClipRRect(
                            borderRadius: BorderRadius.circular(30),
                            child: Container(
                              decoration: BoxDecoration(
                                gradient: LinearGradient(
                                  begin: Alignment.topLeft,
                                  end: Alignment.bottomRight,
                                  colors: [
                                    Colors.orange.shade200,
                                    Colors.orange.shade400,
                                  ],
                                ),
                              ),
                              child: Center(
                                child: AnimatedSwitcher(
                                  duration: Duration(milliseconds: 300),
                                  child: Icon(
                                    Icons.directions_bike,
                                    key: ValueKey(index),
                                    size: iconSize,
                                    color: Colors.white,
                                  ),
                                ),
                              ),
                            ),
                          ),
                        ),
                      ),
                    ),
                  );
                },
              ),
            ),
          ),

          // Dot indicators
          Container(
            margin: EdgeInsets.only(bottom: isSmallScreen ? 10 : 15),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: List.generate(
                _slides.length,
                    (index) => GestureDetector(
                  onTap: () {
                    _stopAutoScroll();
                    _pageController.animateToPage(
                      index,
                      duration: Duration(milliseconds: 500),
                      curve: Curves.easeInOut,
                    );
                    _resumeAutoScroll();
                  },
                  child: AnimatedContainer(
                    duration: Duration(milliseconds: 300),
                    margin: EdgeInsets.symmetric(horizontal: 4),
                    height: 8,
                    width: _currentIndex == index ? 24 : 8,
                    decoration: BoxDecoration(
                      color: _currentIndex == index
                          ? Colors.black
                          : Colors.grey.shade300,
                      borderRadius: BorderRadius.circular(4),
                    ),
                  ),
                ),
              ),
            ),
          ),

          // Bottom content section - takes remaining space
          Expanded(
            flex: 5,
            child: Container(
              width: double.infinity,
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.only(
                  topLeft: Radius.circular(0),
                  topRight: Radius.circular(0),
                ),
              ),
              padding: EdgeInsets.symmetric(
                horizontal: isTablet ? 40 : 24,
                vertical: isSmallScreen ? 16 : 20,
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.center,
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  // Title and description section
                  Expanded(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        // Title section with animation
                        AnimatedSwitcher(
                          duration: Duration(milliseconds: 500),
                          transitionBuilder: (Widget child, Animation<double> animation) {
                            return SlideTransition(
                              position: animation.drive(
                                Tween(begin: Offset(0.0, 0.3), end: Offset(0.0, 0.0)),
                              ),
                              child: FadeTransition(opacity: animation, child: child),
                            );
                          },
                          child: Column(
                            key: ValueKey(_currentIndex),
                            children: [
                              RichText(
                                textAlign: TextAlign.center,
                                text: TextSpan(
                                  children: [
                                    TextSpan(
                                      text: _slides[_currentIndex].title,
                                      style: GoogleFonts.montserrat(
                                        fontSize: titleFontSize,
                                        fontWeight: FontWeight.w700,
                                        color: Colors.black87,
                                        height: 1.2,
                                      ),
                                    ),
                                    TextSpan(
                                      text: '\n${_slides[_currentIndex].highlight}',
                                      style: GoogleFonts.montserrat(
                                        fontSize: titleFontSize,
                                        fontWeight: FontWeight.w700,
                                        color: Colors.black87,
                                        height: 1.2,
                                      ),
                                    ),
                                    TextSpan(
                                      text: ' ${_slides[_currentIndex].subtitle}',
                                      style: GoogleFonts.montserrat(
                                        fontSize: titleFontSize,
                                        fontWeight: FontWeight.w700,
                                        color: Colors.black87,
                                        height: 1.2,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                              SizedBox(height: 8),
                              RichText(
                                textAlign: TextAlign.center,
                                text: TextSpan(
                                  children: [
                                    TextSpan(
                                      text: 'with ',
                                      style: GoogleFonts.montserrat(
                                        fontSize: titleFontSize,
                                        fontWeight: FontWeight.w700,
                                        color: Colors.black87,
                                      ),
                                    ),
                                    TextSpan(
                                      text: _slides[_currentIndex].name,
                                      style: GoogleFonts.montserrat(
                                        fontSize: titleFontSize,
                                        fontWeight: FontWeight.w700,
                                        color: Color(0xFF65DB47),
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ],
                          ),
                        ),

                        SizedBox(height: isSmallScreen ? 12 : 16),

                        // Description with animation
                        AnimatedSwitcher(
                          duration: Duration(milliseconds: 500),
                          child: Text(
                            _slides[_currentIndex].description,
                            key: ValueKey('${_currentIndex}_description'),
                            style: GoogleFonts.montserrat(
                              fontSize: descriptionFontSize,
                              fontWeight: FontWeight.w400,
                              color: Colors.grey.shade600,
                              height: 1.4,
                            ),
                            textAlign: TextAlign.center,
                          ),
                        ),
                      ],
                    ),
                  ),

                  // Slidable button at the bottom
                  Padding(
                    padding: EdgeInsets.only(bottom: 0),
                    child: SlideToActionButton(
                      onSlideComplete: _navigateToLogin,
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class OnboardingData {
  final String image;
  final String title;
  final String highlight;
  final String subtitle;
  final String name;
  final String description;

  OnboardingData({
    required this.image,
    required this.title,
    required this.highlight,
    required this.subtitle,
    required this.name,
    required this.description,
  });
}

class SlideToActionButton extends StatefulWidget {
  final VoidCallback onSlideComplete;

  const SlideToActionButton({
    super.key,
    required this.onSlideComplete,
  });

  @override
  State<SlideToActionButton> createState() => _SlideToActionButtonState();
}

class _SlideToActionButtonState extends State<SlideToActionButton>
    with TickerProviderStateMixin {
  double _dragPosition = 0.0;
  late double _maxDrag;
  bool _isSliding = false;
  bool _isCompleted = false;
  late AnimationController _scaleAnimationController;
  late AnimationController _slideBackAnimationController;
  late Animation<double> _slideBackAnimation;
  late Animation<double> _scaleAnimation;

  @override
  void initState() {
    super.initState();

    _scaleAnimationController = AnimationController(
      duration: Duration(milliseconds: 200),
      vsync: this,
    );

    _slideBackAnimationController = AnimationController(
      duration: Duration(milliseconds: 400),
      vsync: this,
    );

    _scaleAnimation = Tween<double>(begin: 1.0, end: 1.1).animate(
      CurvedAnimation(parent: _scaleAnimationController, curve: Curves.easeInOut),
    );
  }

  @override
  void dispose() {
    _scaleAnimationController.dispose();
    _slideBackAnimationController.dispose();
    super.dispose();
  }

  void _onPanStart(DragStartDetails details) {
    if (_isCompleted) return;

    _isSliding = true;
    _scaleAnimationController.stop();
    _slideBackAnimationController.stop();
    _slideBackAnimationController.reset();
  }

  void _onPanUpdate(DragUpdateDetails details) {
    if (_isCompleted) return;

    setState(() {
      _dragPosition += details.delta.dx;
      _dragPosition = _dragPosition.clamp(0.0, _maxDrag);
    });

    if (_dragPosition > _maxDrag * 0.7) {
      if (!_scaleAnimationController.isAnimating && !_scaleAnimationController.isCompleted) {
        _scaleAnimationController.forward();
      }
    } else {
      if (_scaleAnimationController.isCompleted || _scaleAnimationController.isAnimating) {
        _scaleAnimationController.reverse();
      }
    }
  }

  void _onPanEnd(DragEndDetails details) {
    if (_isCompleted) return;

    _isSliding = false;

    if (_dragPosition > _maxDrag * 0.75) {
      _isCompleted = true;
      _scaleAnimationController.forward();

      setState(() {
        _dragPosition = _maxDrag;
      });

      Future.delayed(Duration(milliseconds: 300), () {
        widget.onSlideComplete();
      });
    } else {
      _scaleAnimationController.reverse();

      _slideBackAnimation = Tween<double>(
        begin: _dragPosition,
        end: 0.0,
      ).animate(CurvedAnimation(
        parent: _slideBackAnimationController,
        curve: Curves.easeOutCubic,
      ));

      _slideBackAnimationController.removeStatusListener(_animationStatusListener);
      _slideBackAnimation.removeListener(_slideBackListener);

      _slideBackAnimation.addListener(_slideBackListener);
      _slideBackAnimationController.addStatusListener(_animationStatusListener);

      _slideBackAnimationController.reset();
      _slideBackAnimationController.forward();
    }
  }

  void _slideBackListener() {
    if (mounted) {
      setState(() {
        _dragPosition = _slideBackAnimation.value;
      });
    }
  }

  void _animationStatusListener(AnimationStatus status) {
    if (status == AnimationStatus.completed) {
      _slideBackAnimation.removeListener(_slideBackListener);
      _slideBackAnimationController.removeStatusListener(_animationStatusListener);
    }
  }

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        _maxDrag = constraints.maxWidth - 64;

        return Container(
          width: double.infinity,
          height: 64,
          decoration: BoxDecoration(
            color: Colors.grey.shade200,
            borderRadius: BorderRadius.circular(32),
          ),
          child: Stack(
            children: [
              AnimatedContainer(
                duration: Duration(milliseconds: _isSliding ? 0 : 100),
                width: _dragPosition + 64,
                height: 64,
                decoration: BoxDecoration(
                  color: Color(0xFF65DB47).withOpacity(0.1),
                  borderRadius: BorderRadius.circular(32),
                ),
              ),
              Center(
                child: AnimatedOpacity(
                  opacity: _dragPosition < _maxDrag * 0.3 ? 1.0 : 0.0,
                  duration: Duration(milliseconds: 200),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Text(
                        'Swipe to get started',
                        style: GoogleFonts.montserrat(
                          fontSize: 14,
                          fontWeight: FontWeight.w500,
                          color: Colors.grey.shade700,
                        ),
                      ),
                      SizedBox(width: 8),
                      Icon(
                        Icons.arrow_forward,
                        color: Colors.grey.shade700,
                        size: 18,
                      ),
                    ],
                  ),
                ),
              ),
              Positioned(
                left: 4 + _dragPosition,
                top: 4,
                child: ScaleTransition(
                  scale: _scaleAnimation,
                  child: GestureDetector(
                    onPanStart: _onPanStart,
                    onPanUpdate: _onPanUpdate,
                    onPanEnd: _onPanEnd,
                    child: Container(
                      width: 56,
                      height: 56,
                      decoration: BoxDecoration(
                        color: _isCompleted ? Colors.green : Color(0xFF65DB47),
                        shape: BoxShape.circle,
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black.withOpacity(0.2),
                            blurRadius: 12,
                            offset: Offset(0, 4),
                          ),
                        ],
                      ),
                      child: AnimatedSwitcher(
                        duration: Duration(milliseconds: 200),
                        child: Icon(
                          _isCompleted ? Icons.check : Icons.directions_bike,
                          key: ValueKey(_isCompleted),
                          color: Colors.white,
                          size: 28,
                        ),
                      ),
                    ),
                  ),
                ),
              ),
            ],
          ),
        );
      },
    );
  }
}