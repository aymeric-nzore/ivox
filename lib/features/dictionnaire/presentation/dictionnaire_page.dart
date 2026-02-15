import 'package:flutter/material.dart';
import 'package:ivox/features/dictionnaire/models/dictionnaire.dart';
import 'package:ivox/features/dictionnaire/services/dictionnaire_service.dart';

class DictionaryScreen extends StatefulWidget {
  const DictionaryScreen({super.key});

  @override
  State<DictionaryScreen> createState() => _DictionaryScreenState();
}

class _DictionaryScreenState extends State<DictionaryScreen> {
  late Future<Dictionnaire> _dictionaryFuture;

  @override
  void initState() {
    super.initState();
    _dictionaryFuture = DictionnaireService.loadDictionary();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(centerTitle: true, title: Text('Dictionnaire')),
      body: FutureBuilder<Dictionnaire>(
        future: _dictionaryFuture,
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return Center(child: CircularProgressIndicator());
          }

          if (snapshot.hasError) {
            return Center(child: Text('Erreur: ${snapshot.error}'));
          }

          final dictionary = snapshot.data!;
          final letters = dictionary.data.keys.toList();

          return ListView.builder(
            itemCount: letters.length,
            itemBuilder: (context, index) {
              final letter = letters[index];
              final words = dictionary.data[letter]!;

              return ExpansionTile(
                title: Text(
                  letter,
                  style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
                ),
                children: words
                    .map(
                      (word) => ListTile(
                        title: Text(
                          word.mot,
                          style: TextStyle(fontWeight: FontWeight.bold),
                        ),
                        subtitle: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              word.traduction,
                              style: TextStyle(color: Colors.blue),
                            ),
                            SizedBox(height: 4),
                            Text(
                              word.exemple,
                              style: TextStyle(
                                fontSize: 12,
                                fontStyle: FontStyle.italic,
                              ),
                            ),
                            Text(
                              "Exemple : ${word.traductionExemple}",
                              style: TextStyle(
                                fontSize: 12,
                                color: Colors.grey,
                              ),
                            ),
                          ],
                        ),
                      ),
                    )
                    .toList(),
              );
            },
          );
        },
      ),
    );
  }
}
