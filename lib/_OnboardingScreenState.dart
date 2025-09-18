import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'dart:async';
// Import your LoginScreen
import 'LoginScreen.dart'; // Make sure this path is correct

class OnboardingScreen extends StatefulWidget {
  @override
  _OnboardingScreenState createState() => _OnboardingScreenState();
}

class _OnboardingScreenState extends State<OnboardingScreen>
    with TickerProviderStateMixin {
  PageController _pageController = PageController();
  int _currentIndex = 0;
  Timer? _timer;
  bool _isUserInteracting = false;

  final List<OnboardingData> _slides = [
    OnboardingData(
      image: 'assets/images/bike_ride_1.png', // Replace with your actual image
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

  // NAVIGATION FUNCTION - This handles the slide completion
  void _navigateToLogin() {
    Navigator.pushReplacement(
      context,
      MaterialPageRoute(
        builder: (context) => LoginScreen(),
      ),
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
    return Scaffold(
      backgroundColor: Color(0xFFF5F5F5),
      body: SafeArea(
        child: Column(
          children: [
            // Top section with images
            Expanded(
              flex: 3,
              child: Container(
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
                      padding: EdgeInsets.symmetric(horizontal: 40, vertical: 60),
                      child: Center(
                        child: Hero(
                          tag: 'onboarding_image_$index',
                          child: AnimatedContainer(
                            duration: Duration(milliseconds: 300),
                            width: 300,
                            height: 300,
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
                                      size: 120,
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
              margin: EdgeInsets.only(bottom: 20),
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
                        color: _currentIndex == index ? Colors.black : Colors.grey.shade300,
                        borderRadius: BorderRadius.circular(4),
                      ),
                    ),
                  ),
                ),
              ),
            ),

            // Bottom content section
            Expanded(
              flex: 2,
              child: Container(
                width: double.infinity,
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.only(
                    topLeft: Radius.circular(0),
                    topRight: Radius.circular(0),
                  ),
                ),
                padding: EdgeInsets.symmetric(horizontal: 24, vertical: 20),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.center,
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
                                    fontSize: 28, // Same size for all
                                    fontWeight: FontWeight.w700, // Bold
                                    color: Colors.black87,
                                    height: 1.2,
                                  ),
                                ),
                                TextSpan(
                                  text: '\n${_slides[_currentIndex].highlight}',
                                  style: GoogleFonts.montserrat(
                                    fontSize: 28, // Same size
                                    fontWeight: FontWeight.w700, // Bold
                                    color: Colors.black87,
                                    height: 1.2,
                                  ),
                                ),
                                TextSpan(
                                  text: ' ${_slides[_currentIndex].subtitle}',
                                  style: GoogleFonts.montserrat(
                                    fontSize: 28, // Same size
                                    fontWeight: FontWeight.w700, // Bold
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
                                    fontSize: 28, // Same size as above text
                                    fontWeight: FontWeight.w700, // Bold
                                    color: Colors.black87,
                                  ),
                                ),
                                TextSpan(
                                  text: _slides[_currentIndex].name,
                                  style: GoogleFonts.montserrat(
                                    fontSize: 28, // Same size as above text
                                    fontWeight: FontWeight.w700, // Bold
                                    color: Color(0xFF65DB47), // Your specified green color
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ),

                    SizedBox(height: 16),

                    // Description with animation
                    AnimatedSwitcher(
                      duration: Duration(milliseconds: 500),
                      child: Text(
                        _slides[_currentIndex].description,
                        key: ValueKey('${_currentIndex}_description'),
                        style: GoogleFonts.montserrat(
                          fontSize: 16, // H2 size
                          fontWeight: FontWeight.w400,
                          color: Colors.grey.shade600,
                          height: 1.4,
                        ),
                        textAlign: TextAlign.center,
                      ),
                    ),

                    Spacer(),

                    // Slidable button - UPDATED WITH NAVIGATION CALLBACK
                    SlideToActionButton(
                      onSlideComplete: _navigateToLogin, // Pass the navigation function
                    ),

                    SizedBox(height: 20),
                  ],
                ),
              ),
            ),
          ],
        ),
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
    Key? key,
    required this.onSlideComplete,
  }) : super(key: key);

  @override
  _SlideToActionButtonState createState() => _SlideToActionButtonState();
}

class _SlideToActionButtonState extends State<SlideToActionButton>
    with SingleTickerProviderStateMixin {
  double _dragPosition = 0.0;
  late double _maxDrag;
  bool _isSliding = false;
  bool _isCompleted = false;
  late AnimationController _animationController;
  late Animation<double> _slideBackAnimation;
  late Animation<double> _scaleAnimation;

  @override
  void initState() {
    super.initState();
    _animationController = AnimationController(
      duration: Duration(milliseconds: 300),
      vsync: this,
    );
    _scaleAnimation = Tween<double>(begin: 1.0, end: 1.1).animate(
      CurvedAnimation(parent: _animationController, curve: Curves.easeInOut),
    );
  }

  @override
  void dispose() {
    _animationController.dispose();
    super.dispose();
  }

  void _onPanStart(DragStartDetails details) {
    if (_isCompleted) return;
    _isSliding = true;
    _animationController.stop();
  }

  void _onPanUpdate(DragUpdateDetails details) {
    if (_isCompleted) return;
    setState(() {
      _dragPosition += details.delta.dx;
      _dragPosition = _dragPosition.clamp(0.0, _maxDrag);
    });

    // Scale effect when near completion
    if (_dragPosition > _maxDrag * 0.7) {
      if (!_animationController.isAnimating) {
        _animationController.forward();
      }
    } else {
      if (_animationController.isCompleted) {
        _animationController.reverse();
      }
    }
  }

  void _onPanEnd(DragEndDetails details) {
    if (_isCompleted) return;
    _isSliding = false;

    // Check if dragged far enough (75% of the way)
    if (_dragPosition > _maxDrag * 0.75) {
      // Complete the slide
      _isCompleted = true;
      setState(() {
        _dragPosition = _maxDrag;
      });

      // Haptic feedback if available
      // HapticFeedback.heavyImpact();

      // Call the completion callback after a short delay
      Future.delayed(Duration(milliseconds: 300), () {
        widget.onSlideComplete();
      });
    } else {
      // Slide back to start with smooth animation
      _slideBackAnimation = Tween<double>(
        begin: _dragPosition,
        end: 0.0,
      ).animate(CurvedAnimation(
        parent: _animationController,
        curve: Curves.easeOutCubic,
      ));

      _slideBackAnimation.addListener(() {
        setState(() {
          _dragPosition = _slideBackAnimation.value;
        });
      });

      _animationController.reset();
      _animationController.forward();
    }
  }

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        _maxDrag = constraints.maxWidth - 64; // Button width is 64

        return Container(
          width: double.infinity,
          height: 64,
          decoration: BoxDecoration(
            color: Colors.grey.shade200,
            borderRadius: BorderRadius.circular(32),
          ),
          child: Stack(
            children: [
              // Progress indicator
              AnimatedContainer(
                duration: Duration(milliseconds: 100),
                width: _dragPosition + 64,
                height: 64,
                decoration: BoxDecoration(
                  color: Color(0xFF65DB47).withOpacity(0.1),
                  borderRadius: BorderRadius.circular(32),
                ),
              ),
              // Background text
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
                          fontSize: 14, // P1 size
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
              // Draggable button
              AnimatedPositioned(
                duration: _isSliding ? Duration.zero : Duration(milliseconds: 200),
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