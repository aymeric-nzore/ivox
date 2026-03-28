import 'package:flutter/material.dart';
import 'package:ivox/features/auth/presentation/login_page.dart';
import 'package:ivox/features/onBoarding/models/on_board.dart';
import 'package:ivox/features/onBoarding/utils/on_board_item.dart';
import 'package:smooth_page_indicator/smooth_page_indicator.dart';

class OnBoardingPage extends StatefulWidget {
  const OnBoardingPage({super.key});

  @override
  State<OnBoardingPage> createState() => _OnBoardingPageState();
}

class _OnBoardingPageState extends State<OnBoardingPage> {
  final List<OnBoard> data = [
    OnBoard(
      imageAssets: "assets/lotties/STUDENT.json",
      title: "Apprends facilement",
      description:
          "Découvre une nouvelle langue pas à pas, avec des leçons simples et claires.",
      textColor: Colors.amber,
    ),
    OnBoard(
      imageAssets: "assets/lotties/online study.json",
      title: "Pratique chaque jour",
      description:
          "Écoute, parle et entraîne-toi grâce à des exercices interactifs.",

      textColor: Colors.blue,
    ),
    OnBoard(
      imageAssets: "assets/lotties/Untitled file.json",
      title: "Progresse à ton rythme",
      description: "Suis tes progrès et gagne en confiance, où que tu sois.",
      textColor: Colors.green,
    ),
  ];
  final List<Color> _colors = [Colors.amber, Colors.blue, Colors.green];

  late final PageController _controller;
  int _currentIndex = 0;

  @override
  void initState() {
    // TODO: implement initState
    super.initState();
    _controller = PageController();
  }

  @override
  void dispose() {
    // TODO: implement dispose
    super.dispose();
    _controller.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final screenWidth = MediaQuery.sizeOf(context).width;
    final isSmall = screenWidth < 360;

    return Scaffold(
      appBar: AppBar(
        leading: Text(""),
        elevation: 0,
        backgroundColor: Colors.transparent,
        surfaceTintColor: Colors.transparent,
        actions: [
          GestureDetector(
            onTap: () {
              Navigator.push(
                context,
                MaterialPageRoute(builder: (context) => LoginPage()),
              );
            },
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16.0),
              child: Text(
                "Skip",
                textAlign: TextAlign.start,
                style: TextStyle(
                  fontSize: isSmall ? 14 : 16,
                  fontWeight: FontWeight.bold,
                  color: Colors.grey[500],
                ),
              ),
            ),
          ),
        ],
      ),
      backgroundColor: Colors.white,
      body: Stack(
        children: [
          PageView.builder(
            itemCount: data.length,
            controller: _controller,
            itemBuilder: (context, index) => OnBoardItem(
              imageAssets: data[index].imageAssets,
              title: data[index].title,
              description: data[index].description,
              textColor: data[index].textColor,
            ),
            onPageChanged: (index) {
              setState(() {
                _currentIndex = index;
              });
            },
          ),
          Positioned(
            left: 12,
            right: 12,
            bottom: isSmall ? 20 : 28,
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                //Boutton pour revenir en arriere
                IconButton(
                  iconSize: isSmall ? 36 : 44,
                  onPressed: () {
                    setState(() {
                      _controller.previousPage(
                        duration: Duration(milliseconds: 600),
                        curve: Curves.easeInOut,
                      );
                    });
                  },
                  icon: Icon(
                    Icons.arrow_circle_left_outlined,
                    color: _colors[_currentIndex],
                  ),
                ),
                SmoothPageIndicator(
                  controller: _controller,
                  count: 3,
                  effect: WormEffect(
                    activeDotColor: _colors[_currentIndex],
                    dotColor: Colors.grey[300]!,
                    dotHeight: 8,
                    dotWidth: 8,
                  ),
                ),
                _currentIndex == 2
                    ? GestureDetector(
                        onTap: () => Navigator.push(
                          context,
                          MaterialPageRoute(builder: (builder) => LoginPage()),
                        ),
                        child: Container(
                          padding: EdgeInsets.symmetric(
                            horizontal: isSmall ? 12 : 14,
                            vertical: isSmall ? 10 : 12,
                          ),
                          decoration: BoxDecoration(
                            color: Colors.blue,
                            borderRadius: BorderRadius.circular(6),
                          ),

                          child: Text(
                            "Let's Go!",
                            style: TextStyle(
                              color: Colors.white,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ),
                      )
                    : IconButton(
                        iconSize: isSmall ? 36 : 44,
                        onPressed: () {
                          setState(() {
                            _controller.nextPage(
                              duration: Duration(milliseconds: 600),
                              curve: Curves.easeInOut,
                            );
                          });
                        },
                        icon: Icon(
                          Icons.arrow_circle_right_outlined,
                          color: _colors[_currentIndex],
                        ),
                      ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
