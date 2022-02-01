import 'package:adaptive_theme/adaptive_theme.dart';
import 'package:flutter/material.dart';
import 'package:english_words/english_words.dart';
import 'package:flutter/services.dart';
import 'package:http/http.dart' as http;

void main() {
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({Key? key}) : super(key: key);

  // This widget is the root of your application.
  @override
  Widget build(BuildContext context) {
    return AdaptiveTheme(
      light: ThemeData(
        brightness: Brightness.light,
        primarySwatch: Colors.teal,
        appBarTheme: const AppBarTheme(
          backgroundColor: Colors.teal,
        ),
      ),
      dark: ThemeData(
        brightness: Brightness.dark,
        primarySwatch: Colors.teal,
        appBarTheme: const AppBarTheme(
          backgroundColor: Colors.teal,
        ),
      ),
      initial: AdaptiveThemeMode.light,
      builder: (theme, darkTheme) => MaterialApp(
        title: 'Startup Name Generator',
        theme: theme,
        darkTheme: darkTheme,
        home: const RandomWords(),
      ),
    );
  }
}

class RandomWords extends StatefulWidget {
  const RandomWords({Key? key}) : super(key: key);

  @override
  _RandomWordsState createState() => _RandomWordsState();
}

class _RandomWordsState extends State<RandomWords> {
  final _suggestions = <WordPair>[];
  final _saved = <WordPair>{};
  final _biggerFont = const TextStyle(fontSize: 18);

  var _isLightTheme = true;

  @override
  Widget build(BuildContext context) {
    // final wordPair = WordPair.random();
    // return Text(wordPair.asPascalCase);
    return Scaffold(
      appBar: AppBar(
        title: const Text('Startup Name Generator'),
        // backgroundColor: ThemeData.,
        actions: [
          IconButton(
              onPressed: _toggleTheme,
              icon: _isLightTheme
                  ? const Icon(Icons.dark_mode_outlined)
                  : const Icon(Icons.light_mode_outlined)),
          IconButton(
            icon: const Icon(Icons.list),
            onPressed: _pushSaved,
            tooltip: 'Saved Suggestions',
          ),
        ],
      ),
      body: _buildSuggestions(),
      floatingActionButton: FloatingActionButton(
        onPressed: _resetSaved,
        tooltip: 'Reset List',
        child: const Icon(Icons.refresh),
        backgroundColor: Colors.teal,
      ),
      floatingActionButtonLocation: FloatingActionButtonLocation.centerFloat,
    );
  }

  Widget _buildSuggestions() {
    return RefreshIndicator(
        child: ListView.builder(
          padding: const EdgeInsets.all(16),
          // The itemBuilder callback is called once per suggested
          // word pairing, and places each suggestion into a ListTile
          // row. For even rows, the function adds a ListTile row for
          // the word pairing. For odd rows, the function adds a
          // Divider widget to visually separate the entries. Note that
          // the divider may be difficult to see on smaller devices.
          itemBuilder: (context, i) {
            // Add a one-pixel-high divider widget before each row
            // in the ListView.
            if (i.isOdd) {
              return const Divider();
            }

            // The syntax "i ~/ 2" divides i by 2 and returns an
            // integer result.
            // For example: 1, 2, 3, 4, 5 becomes 0, 1, 1, 2, 2.
            // This calculates the actual number of word pairings
            // in the ListView,minus the divider widgets.
            final index = i ~/ 2;
            // If you've reached the end of the available word
            // pairings...
            if (index >= _suggestions.length) {
              // ...then generate 10 more and add them to the
              // suggestions list.
              _suggestions.addAll(generateWordPairs().take(10));
            }
            return _buildRow(_suggestions[index]);
          },
        ),
        onRefresh: () {
          return Future.delayed(
            const Duration(seconds: 1),
            () {
              _resetSaved();
              // showing snackbar
              ScaffoldMessenger.of(context)
                  .showSnackBar(const SnackBar(content: Text('Page Refresed')));
            },
          );
        });
  }

  Widget _buildRow(WordPair pair) {
    final alreadySaved = _saved.contains(pair);
    return ListTile(
      title: Text(
        pair.asPascalCase,
        style: _biggerFont,
      ),
      trailing: Icon(
        alreadySaved ? Icons.favorite : Icons.favorite_border,
        color: alreadySaved ? Colors.red : null,
        semanticLabel: alreadySaved ? 'Remove from saved' : 'Save',
      ),
      onTap: () {
        setState(() {
          if (alreadySaved) {
            _saved.remove(pair);
          } else {
            _saved.add(pair);
          }
        });
      },
    );
  }

  void _toggleTheme() {
    setState(() {
      _isLightTheme = !_isLightTheme;
      _isLightTheme
          ? AdaptiveTheme.of(context).setLight()
          : AdaptiveTheme.of(context).setDark();
    });
  }

  void _resetSaved() {
    setState(() {
      _suggestions.clear();
      _saved.clear();
    });
  }

  void _copyToClipboard(String inputText) {
    Clipboard.setData(ClipboardData(text: inputText)).then((_) {
      ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Copied work to clipboard !')));
    });
  }

  Future<http.Response> checkDomainAvailability(String domain) {
    return http.get(Uri.parse('https://jsonplaceholder.typicode.com/albums/1'));
  }

  void _pushSaved() {
    Navigator.of(context).push(
      // Add lines from here...
      MaterialPageRoute<void>(
        builder: (context) {
          final tiles = _saved.map(
            (pair) {
              final domainName = pair.toString() + '.com';
              return ListTile(
                title: Text(
                  pair.asPascalCase,
                  style: _biggerFont,
                ),
                trailing: const Icon(Icons.copy),
                onTap: () {
                  _copyToClipboard(pair.asPascalCase);
                },
                subtitle: FutureBuilder(
                  future: http.get(Uri.parse('http://' + domainName)),
                  builder: (context, snapshot) {
                    bool isAccessible = false;
                    // Widget availabilityStatus = const Widget(
                    List<Widget> children = const <Widget>[];
                    if (snapshot.hasData) {
                      final data = snapshot.data as http.Response;
                      if (data != null && data.statusCode == 200) {
                        isAccessible = true;
                      }
                    } else if (snapshot.hasError) {
                      // children = <Widget>[Text('${snapshot.error}')];
                    } else {
                      return const LinearProgressIndicator();
                    }

                    if (!isAccessible) {
                      children = <Widget>[
                        const Icon(
                          Icons.check_circle_outline,
                          color: Colors.green,
                        ),
                        const Padding(
                          padding: EdgeInsets.all(8.0),
                          child: Text('.com Domain is Available'),
                        ),
                      ];
                    } else {
                      children = <Widget>[
                        const Icon(
                          Icons.error_outline,
                          color: Colors.red,
                        ),
                        const Padding(
                          padding: EdgeInsets.all(8.0),
                          child: Text('.com Domain is not Available'),
                        ),
                      ];
                    }

                    return Center(
                      child: Row(
                        children: children,
                      ),
                    );
                  },
                ),
                // subtitle: Text(
                //     "'${pair.asPascalCase}' is ${available ? 'available' : 'not available'}"),
              );
            },
          );
          final divided = tiles.isNotEmpty
              ? ListTile.divideTiles(
                  context: context,
                  tiles: tiles,
                ).toList()
              : <Widget>[];

          return Scaffold(
            appBar: AppBar(
              title: const Text('Saved Suggestions'),
            ),
            body: ListView(children: divided),
          );
        },
      ), // ...to here.
    );
  }
}
