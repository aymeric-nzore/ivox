import 'package:flutter/material.dart';
import 'package:ivox/features/auth/services/auth_service.dart';
import 'package:ivox/features/lessons/utils/grid_courses.dart';
import 'package:ivox/features/quizz/listview_quizz.dart';
import 'package:ivox/features/quizz/quizz_page.dart';
import 'package:ivox/shared/widgets/main_bottom_nav_bar.dart';
import 'package:lottie/lottie.dart';

class LessonsPage extends StatefulWidget {
  final int currentIndex;
  final ValueChanged<int> onTabSelected;

  const LessonsPage({
    super.key,
    required this.currentIndex,
    required this.onTabSelected,
  });

  @override
  State<LessonsPage> createState() => _LessonsPageState();
}

class _LessonsPageState extends State<LessonsPage> {
  final _authService = AuthService();
  final List<GridCourses> data = [
    GridCourses(
      title: "Tous les cours",
      icon: Icons.library_books,
      isAll: true,
      circleColor: Colors.white,
    ),
    GridCourses(
      title: "Chapitre 1",
      icon: Icons.flag_circle_outlined,
      isAll: false,
      circleColor: Colors.blue,
    ),
    GridCourses(
      title: "Chapitre 2",
      icon: Icons.computer,
      isAll: false,
      circleColor: Colors.orangeAccent,
    ),
    GridCourses(
      title: "Chapitre 3",
      icon: Icons.star,
      isAll: false,
      circleColor: Colors.green,
    ),
  ];
  final List<ListviewQuizz> quizz_data = [
    ListviewQuizz(
      imagePath: "assets/lotties/Quiz mode.json",
      title: "Quiz 1",
      description: "Basique",
      times: "15 min",
      bgColor: Colors.blue.shade400,
      starCompt: 1,
    ),
    ListviewQuizz(
      imagePath: "assets/lotties/Books stack.json",
      title: "Quiz 2",
      description: "Moyen",
      times: "20 min",
      bgColor: Colors.cyan.shade300,
      starCompt: 2,
    ),
    ListviewQuizz(
      imagePath: "assets/lotties/STUDENT.json",
      title: "Quiz 3",
      description: "Avancé",
      times: "25 min",
      bgColor: Colors.teal.shade300,
      starCompt: 3,
    ),
  ];
  @override
  Widget build(BuildContext context) {
    final isDarkMode = Theme.of(context).brightness == Brightness.dark;
    final primaryColor = Theme.of(context).primaryColor;
    final cardColor = isDarkMode ? Colors.grey[800] : Colors.white;

    return Scaffold(
      appBar: AppBar(
        actions: [
          StreamBuilder(
            stream: _authService.userDocStream(),
            builder: (context, snapshot) {
              final data = snapshot.data?.data();
              final level = data?["level"] as int? ?? 1;
              final xp = data?["xp"] as int? ?? 0;
              int requiredXp = 100 + (level * 25);
              double progress = xp / requiredXp;

              double maxWidth = 110;
              double progressWidth = maxWidth * progress.clamp(0.0, 1.0);
              return Padding(
                padding: const EdgeInsets.only(right: 15.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisAlignment: MainAxisAlignment.end,
                  children: [
                    Row(
                      children: [
                        Text(
                          "Lv $level",
                          style: TextStyle(
                            color: Colors.blue,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ],
                    ),
                    Row(
                      children: [
                        Stack(
                          children: [
                            SizedBox(
                              height: 7,
                              width: maxWidth,
                              child: Container(
                                decoration: BoxDecoration(
                                  borderRadius: BorderRadius.circular(30),
                                  color: Colors.grey[300],
                                ),
                              ),
                            ),
                            SizedBox(
                              height: 7,
                              width: progressWidth,
                              child: AnimatedContainer(
                                duration: Duration(milliseconds: 400),
                                decoration: BoxDecoration(
                                  borderRadius: BorderRadius.circular(30),
                                  color: Colors.green,
                                ),
                              ),
                            ),
                          ],
                        ),
                        SizedBox(width: 8),
                        Icon(
                          Icons.auto_awesome,
                          size: 16,
                          color: Colors.green[300],
                        ),
                      ],
                    ),
                  ],
                ),
              );
            },
          ),
        ],
        leading: Padding(
          padding: const EdgeInsets.only(left: 20.0),
          child: StreamBuilder(
            stream: _authService.userDocStream(),
            builder: (context, snapshot) {
              if (!snapshot.hasData) {
                return const CircleAvatar(child: Icon(Icons.person));
              }

              final data = snapshot.data!.data();
              final photoUrl = data["photoUrl"] as String?;

              return CircleAvatar(
                backgroundImage: (photoUrl != null && photoUrl.isNotEmpty)
                    ? NetworkImage(photoUrl)
                    : null,
                child: (photoUrl == null || photoUrl.isEmpty)
                    ? const Icon(Icons.person)
                    : null,
              );
            },
          ),
        ),

        title: StreamBuilder(
          stream: _authService.userDocStream(),
          builder: (context, snapshot) {
            final data = snapshot.data?.data();
            final username = (data?["username"] as String?) ?? "";
            return Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Text(
                      "Hi , ",
                      style: TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                    Text(
                      username,
                      style: TextStyle(
                        color: Colors.blue,
                        fontWeight: FontWeight.bold,
                        fontSize: 18,
                      ),
                    ),
                  ],
                ),
                Text("Bienvenue 👋", style: TextStyle(fontSize: 14)),
              ],
            );
          },
        ),
      ),
      bottomNavigationBar: MainBottomNavBar(
        currentIndex: widget.currentIndex,
        onTap: widget.onTabSelected,
      ),
      body: CustomScrollView(
        slivers: [
          SliverPadding(
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 22),
            sliver: SliverToBoxAdapter(
              child: Column(
                children: [
                  TextField(
                    decoration: InputDecoration(
                      labelText: "Recherchez des cours...",
                      prefixIcon: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Padding(
                            padding: EdgeInsets.symmetric(horizontal: 8),
                            child: Icon(Icons.search),
                          ),
                          Container(
                            width: 1,
                            height: 24,
                            color: Colors.grey.shade400,
                          ),
                        ],
                      ),
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(16),
                      ),
                    ),
                  ),
                  SizedBox(height: 8),
                ],
              ),
            ),
          ),
          SliverPadding(
            padding: const EdgeInsets.only(left: 20, bottom: 10),
            sliver: SliverToBoxAdapter(
              child: Text(
                "Leçons",
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  color: isDarkMode ? Colors.white : Colors.black,
                ),
              ),
            ),
          ),
          SliverPadding(
            padding: const EdgeInsets.symmetric(horizontal: 20),
            sliver: SliverGrid(
              gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                crossAxisCount: 2,
                mainAxisSpacing: 10,
                crossAxisSpacing: 15,
                childAspectRatio: 3,
              ),
              delegate: SliverChildBuilderDelegate((context, index) {
                final course = data[index];
                final isAll = course.isAll == true;

                final iconColor = isAll && !isDarkMode
                    ? Colors.blue
                    : (isDarkMode ? Colors.black : Colors.white);

                return GestureDetector(
                  onTap: () {},
                  child: Container(
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(16),
                      color: isAll
                          ? (isDarkMode ? primaryColor : Colors.blue)
                          : cardColor,
                      border: Border.all(
                        color: isDarkMode
                            ? Colors.grey[700]!
                            : Colors.grey[300]!,
                        width: 1,
                      ),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withOpacity(
                            isDarkMode ? 0.3 : 0.1,
                          ),
                          blurRadius: 8,
                          offset: Offset(0, 2),
                        ),
                      ],
                    ),
                    child: Row(
                      children: [
                        SizedBox(width: 12),
                        CircleAvatar(
                          radius: 22,
                          backgroundColor: course.circleColor,
                          child: Icon(course.icon, color: iconColor, size: 22),
                        ),
                        SizedBox(width: 8),
                        Expanded(
                          child: Text(
                            course.title,
                            maxLines: 2,
                            overflow: TextOverflow.ellipsis,
                            style: TextStyle(
                              fontWeight: FontWeight.bold,
                              color: isAll
                                  ? Colors.white
                                  : (isDarkMode ? Colors.white : Colors.black),
                              fontSize: 12,
                            ),
                          ),
                        ),
                        SizedBox(width: 12),
                      ],
                    ),
                  ),
                );
              }, childCount: data.length),
            ),
          ),
          SliverPadding(
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
            sliver: SliverToBoxAdapter(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    "QUIZZ",
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                      color: isDarkMode ? Colors.white : Colors.black,
                    ),
                  ),
                  SizedBox(height: 12),
                  SizedBox(
                    height: 350,
                    child: ListView.builder(
                      itemCount: quizz_data.length,
                      scrollDirection: Axis.horizontal,
                      itemBuilder: (context, index) {
                        return GestureDetector(
                          onTap: () {
                            Navigator.push(
                              context,
                              MaterialPageRoute(
                                builder: (context) => QuizzPage(index: index),
                              ),
                            );
                          },
                          child: Container(
                            margin: EdgeInsets.symmetric(horizontal: 8),
                            width: 270,
                            decoration: BoxDecoration(
                              color: quizz_data[index].bgColor,
                              borderRadius: BorderRadius.circular(20),
                              boxShadow: [
                                BoxShadow(
                                  color: quizz_data[index].bgColor.withOpacity(
                                    0.4,
                                  ),
                                  blurRadius: 8,
                                  offset: Offset(0, 4),
                                ),
                              ],
                            ),
                            child: Column(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                LottieBuilder.asset(
                                  quizz_data[index].imagePath,
                                  height: 220,
                                  alignment: Alignment.center,
                                  
                                ),
                                SizedBox(height: 8),
                                Text(
                                  quizz_data[index].title,
                                  style: TextStyle(
                                    fontWeight: FontWeight.bold,
                                    color: Colors.white,
                                    fontSize: 24,
                                  ),
                                  textAlign: TextAlign.center,
                                ),
                                SizedBox(height: 4),
                                Row(
                                  mainAxisAlignment: MainAxisAlignment.center,
                                  spacing: 4,
                                  children: List.generate(
                                    quizz_data[index].starCompt,
                                    (index) =>
                                        Icon(Icons.star, color: Colors.amber),
                                  ),
                                ),
                                Padding(
                                  padding: const EdgeInsets.symmetric(
                                    horizontal: 20.0,
                                  ),
                                  child: Row(
                                    mainAxisAlignment:
                                        MainAxisAlignment.spaceBetween,
                                    children: [
                                      Text(
                                        quizz_data[index].description,
                                        style: TextStyle(
                                          color: Colors.white70,
                                          fontSize: 12,
                                          fontWeight: FontWeight.bold,
                                        ),
                                      ),
                                      SizedBox(height: 4),
                                      Container(
                                        padding: EdgeInsets.symmetric(
                                          horizontal: 12,
                                          vertical: 8,
                                        ),
                                        decoration: BoxDecoration(
                                          borderRadius: BorderRadius.circular(
                                            16,
                                          ),
                                          color: Color(0xfff5f2ed),
                                        ),
                                        child: Row(
                                          spacing: 6,
                                          children: [
                                            Icon(
                                              Icons.timelapse,
                                              color: Colors.blue,
                                            ),
                                            Text(
                                              quizz_data[index].times,
                                              style: TextStyle(
                                                color: Colors.black,
                                                fontSize: 11,
                                                fontWeight: FontWeight.bold,
                                              ),
                                            ),
                                          ],
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                              ],
                            ),
                          ),
                        );
                      },
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
