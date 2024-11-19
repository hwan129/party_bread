import 'package:flutter/material.dart';

class OnboardingPage extends StatefulWidget {
  @override
  _OnboardingPageState createState() => _OnboardingPageState();
}

class _OnboardingPageState extends State<OnboardingPage> {
  final PageController _pageController = PageController();
  int _currentPage = 0;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text('Onboarding')),
      body: Column(
        children: [
          Expanded(
            child: PageView(
              controller: _pageController,
              onPageChanged: (index) {
                setState(() {
                  _currentPage = index;
                });
              },
              children: [
                _buildPage('Onboarding 1', 'Welcome to the app!'),
                _buildPage('Onboarding 2', 'Get to know our features!'),
                _buildPage('Onboarding 3', 'Start your journey with us!'),
              ],
            ),
          ),
          _buildPageIndicator(),
          SizedBox(height: 20), // 페이지 인디케이터와 버튼 간 간격
          _currentPage == 2
              ? ElevatedButton(
                  onPressed: () {
                    // 온보딩 완료 후 메인 페이지로 이동 설정
                    Navigator.popUntil(context, (route) => route.isFirst);
                  },
                  child: Text('Get Started'),
                )
              : SizedBox(height: 50), // 하단 여백
        ],
      ),
    );
  }

  Widget _buildPage(String title, String description) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Text(title,
              style: TextStyle(fontSize: 28, fontWeight: FontWeight.bold)),
          SizedBox(height: 16),
          Text(description, style: TextStyle(fontSize: 18)),
        ],
      ),
    );
  }

  Widget _buildPageIndicator() {
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: List.generate(3, (index) {
        return AnimatedContainer(
          duration: Duration(milliseconds: 300),
          margin: EdgeInsets.symmetric(horizontal: 4.0),
          height: 10.0,
          width: 10.0,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            color: _currentPage == index ? Colors.black : Colors.white,
            border: Border.all(color: Colors.black),
          ),
        );
      }),
    );
  }
}
