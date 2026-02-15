import 'package:flutter/material.dart';
import 'package:ivox/features/quizz/quizz_tile.dart';
import 'package:ivox/features/quizz/quizz_tile_data.dart';

class QuizzPage extends StatelessWidget {
  final int index;
  const QuizzPage({super.key, required this.index});

  String _buildQuizzAppBarTitle(int selectedIndex) {
    switch (selectedIndex) {
      case 0:
        return "Niveau Basique";
      case 1:
        return "Niveau Moyen";
      case 2:
        return "Niveau Avancé";
      default :
      return "Niveau Basique";
    }
  }

  List<QuizzTileData> _buildQuizzData(int selectedIndex) {
    switch (selectedIndex) {
      case 0:
        return [
          QuizzTileData(
            title: "Quiz 1: Vocabulaire",
            desc: "Mots usuels et definitions",
            times: "6 min",
            imagePath: "assets/quizz_assets/Audiobook-pana.svg",
            onTap: () {},
            bgColor: Colors.teal.shade300,
            progress: 0.35,
          ),
          QuizzTileData(
            title: "Quiz 2: Synonymes",
            desc: "Choisir le bon mot",
            times: "7 min",
            imagePath: "assets/quizz_assets/Teacher student-cuate.svg",
            onTap: () {},
            bgColor: Color.fromARGB(255, 255, 211, 91),
            progress: 0.12,
          ),
          QuizzTileData(
            title: "Quiz 3: Orthographe",
            desc: "Pieges frequents",
            times: "9 min",
            imagePath: "assets/quizz_assets/Raising hand-pana.svg",
            onTap: () {},
            bgColor: Colors.blue.shade300,
            progress: 0.0,
          ),
          QuizzTileData(
            title: "Quiz 4: Expression",
            desc: "Tournures courantes",
            times: "7 min",
            imagePath: "assets/images/Studying-cuate.svg",
            onTap: () {},
            bgColor: Colors.purple.shade300,
            progress: 0.4,
          ),
        ];
      case 1:
        return [
          QuizzTileData(
            title: "Quiz 1: Grammaire",
            desc: "Accords dans la phrase",
            times: "8 min",
            imagePath: "assets/quizz_assets/Audiobook-pana.svg",
            onTap: () {},
            bgColor: Colors.teal.shade300,
            progress: 0.62,
          ),
          QuizzTileData(
            title: "Quiz 2: Conjugaison",
            desc: "Temps simples",
            times: "10 min",
            imagePath: "assets/quizz_assets/Teacher student-cuate.svg",
            onTap: () {},
            bgColor: Color.fromARGB(255, 255, 211, 91),
            progress: 0.3,
          ),
          QuizzTileData(
            title: "Quiz 3: Ponctuation",
            desc: "Choix des signes",
            times: "6 min",
            imagePath: "assets/quizz_assets/Raising hand-pana.svg",
            onTap: () {},
            bgColor: Colors.blue.shade300,
            progress: 0.0,
          ),
          QuizzTileData(
            title: "Quiz 4: Subordination",
            desc: "Propositions complexes",
            times: "9 min",
            imagePath: "assets/images/Studying-cuate.svg",
            onTap: () {},
            bgColor: Colors.purple.shade300,
            progress: 0.25,
          ),
        ];
      case 2:
        return [
          QuizzTileData(
            title: "Quiz 1: Compréhension",
            desc: "Idee principale",
            times: "10 min",
            imagePath: "assets/quizz_assets/Audiobook-pana.svg",
            onTap: () {},
            bgColor: Colors.teal.shade300,
            progress: 1.0,
          ),
          QuizzTileData(
            title: "Quiz 2: Vitesse",
            desc: "Lecture rapide",
            times: "7 min",
            imagePath: "assets/quizz_assets/Teacher student-cuate.svg",
            onTap: () {},
            bgColor: Color.fromARGB(255, 255, 211, 91),
            progress: 0.55,
          ),
          QuizzTileData(
            title: "Quiz 3: Details",
            desc: "Questions precises",
            times: "8 min",
            imagePath: "assets/quizz_assets/Raising hand-pana.svg",
            onTap: () {},
            bgColor: Colors.blue.shade300,
            progress: 0.2,
          ),
          QuizzTileData(
            title: "Quiz 4: Critique",
            desc: "Analyse profonde",
            times: "12 min",
            imagePath: "assets/images/Studying-cuate.svg",
            onTap: () {},
            bgColor: Colors.purple.shade300,
            progress: 0.75,
          ),
        ];
      default:
        return [
          QuizzTileData(
            title: "Quiz 1: Vocabulaire",
            desc: "Mots usuels et definitions",
            times: "6 min",
            imagePath: "assets/quizz_assets/Audiobook-pana.svg",
            onTap: () {},
            bgColor: Colors.teal.shade300,
            progress: 0.35,
          ),
          QuizzTileData(
            title: "Quiz 2: Grammaire",
            desc: "Accords et conjugaison",
            times: "8 min",
            imagePath: "assets/quizz_assets/Teacher student-cuate.svg",
            onTap: () {},
            bgColor: Color.fromARGB(255, 249, 209, 100),
            progress: 0.62,
          ),
          QuizzTileData(
            title: "Quiz 3: Compréhension",
            desc: "Phrase et contexte",
            times: "10 min",
            imagePath: "assets/quizz_assets/Raising hand-pana.svg",
            onTap: () {},
            bgColor: Colors.blue.shade300,
            progress: 1.0,
          ),
          QuizzTileData(
            title: "Quiz 4: Synthese",
            desc: "Resume et conclusions",
            times: "8 min",
            imagePath: "assets/images/Studying-cuate.svg",
            onTap: () {},
            bgColor: Colors.purple.shade300,
            progress: 0.5,
          ),
        ];
    }
  }

  @override
  Widget build(BuildContext context) {
    final quizzTileData = _buildQuizzData(index);
    return Scaffold(
      appBar: AppBar(
        title: Text(_buildQuizzAppBarTitle(index)),
        centerTitle: true,
      ),
      body: Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 500),
          child: SingleChildScrollView(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                for (int i = 0; i < quizzTileData.length; i++)
                  Padding(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 24.0,
                      vertical: 6,
                    ),
                    child: QuizzTile(
                      title: quizzTileData[i].title,
                      desc: quizzTileData[i].desc,
                      times: quizzTileData[i].times,
                      imagePath: quizzTileData[i].imagePath,
                      onTap: quizzTileData[i].onTap,
                      bgColor: quizzTileData[i].bgColor,
                      progress: quizzTileData[i].progress,
                    ),
                  ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
