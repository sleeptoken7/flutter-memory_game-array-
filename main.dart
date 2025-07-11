import 'package:flutter/material.dart';
import 'dart:math';
import 'package:audioplayers/audioplayers.dart';

void main() {
  runApp(const MemoryGameApp());
}

class MemoryGameApp extends StatelessWidget {
  const MemoryGameApp({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Memory Game',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(primarySwatch: Colors.blue),
      home: const MemoryGameScreen(),
    );
  }
}

class MemoryGameScreen extends StatefulWidget {
  const MemoryGameScreen({Key? key}) : super(key: key);

  @override
  State<MemoryGameScreen> createState() => _MemoryGameScreenState();
}

class _MemoryGameScreenState extends State<MemoryGameScreen> {
  final List<String> fruitImages = [
    'assets/images/apple.png',
    'assets/images/banana.png',
    'assets/images/cherry.png',
    'assets/images/grape.png',
    'assets/images/lemon.png',
    'assets/images/orange.png',
  ];

  late List<CardItem> cards;
  int? firstCardIndex;
  bool canFlip = true;
  int pairsFound = 0;
  int attempts = 0;

  final AudioPlayer _audioPlayer = AudioPlayer();

  @override
  void initState() {
    super.initState();
    initializeGame();
  }

  @override
  void dispose() {
    _audioPlayer.dispose();
    super.dispose();
  }

  void playSound(String fileName) {
    _audioPlayer.play(AssetSource('sounds/$fileName'));
  }

  void initializeGame() {
    cards = [];
    List<String> cardPairs = [...fruitImages, ...fruitImages];
    cardPairs.shuffle(Random());

    for (var path in cardPairs) {
      cards.add(CardItem(imagePath: path, isFlipped: false, isMatched: false));
    }

    firstCardIndex = null;
    canFlip = true;
    pairsFound = 0;
    attempts = 0;
    setState(() {});
  }

  void flipCard(int index) {
    if (!canFlip || cards[index].isFlipped || cards[index].isMatched) return;

    setState(() {
      cards[index].isFlipped = true;
    });

    if (firstCardIndex == null) {
      firstCardIndex = index;
    } else {
      attempts++;
      canFlip = false;

      if (cards[firstCardIndex!].imagePath == cards[index].imagePath) {
        cards[firstCardIndex!].isMatched = true;
        cards[index].isMatched = true;
        pairsFound++;

        playSound('match.mp3');

        firstCardIndex = null;
        canFlip = true;

        if (pairsFound == fruitImages.length) {
          Future.delayed(const Duration(milliseconds: 300), () {
            playSound('gameover.mp3');
            showGameCompleteDialog();
          });
        }
      } else {
        playSound('wrong.mp3');

        Future.delayed(const Duration(seconds: 1), () {
          setState(() {
            cards[firstCardIndex!].isFlipped = false;
            cards[index].isFlipped = false;
            firstCardIndex = null;
            canFlip = true;
          });
        });
      }
    }
  }

  void showGameCompleteDialog() {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => AlertDialog(
        title: const Text('Congratulations!'),
        content: Text('You completed the game in $attempts attempts.'),
        actions: [
          TextButton(
            onPressed: () {
              Navigator.of(context).pop();
              initializeGame();
            },
            child: const Text('Play Again'),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.lightBlue[50],
      appBar: AppBar(
        title: const Text('Fruit Memory Game'),
        centerTitle: true,
      ),
      body: LayoutBuilder(
        builder: (context, constraints) {
          double maxGridWidth = 500;
          int crossAxisCount = 4;
          double spacing = 8.0;

          return Center(
            child: ConstrainedBox(
              constraints: BoxConstraints(maxWidth: maxGridWidth),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Padding(
                    padding: const EdgeInsets.all(8.0),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceAround,
                      children: [
                        Text('Pairs: $pairsFound/${fruitImages.length}'),
                        Text('Attempts: $attempts'),
                      ],
                    ),
                  ),
                  Flexible(
                    child: GridView.builder(
                      shrinkWrap: true,
                      physics: const NeverScrollableScrollPhysics(),
                      padding: const EdgeInsets.all(8.0),
                      itemCount: cards.length,
                      gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                        crossAxisCount: crossAxisCount,
                        crossAxisSpacing: spacing,
                        mainAxisSpacing: spacing,
                        childAspectRatio: 1.0,
                      ),
                      itemBuilder: (context, index) {
                        return GestureDetector(
                          onTap: () => flipCard(index),
                          child: Card(
                            color: cards[index].isMatched
                                ? Colors.green[100]
                                : cards[index].isFlipped
                                    ? Colors.white
                                    : Colors.blue,
                            child: cards[index].isFlipped ||
                                    cards[index].isMatched
                                ? Padding(
                                    padding: const EdgeInsets.all(8.0),
                                    child: Image.asset(cards[index].imagePath),
                                  )
                                : const Center(
                                    child: Text(
                                      '?',
                                      style: TextStyle(
                                        fontSize: 24,
                                        fontWeight: FontWeight.bold,
                                        color: Colors.white,
                                      ),
                                    ),
                                  ),
                          ),
                        );
                      },
                    ),
                  ),
                  Padding(
                    padding: const EdgeInsets.all(8.0),
                    child: ElevatedButton(
                      onPressed: () {
                        initializeGame();
                      },
                      child: const Text('Restart Game'),
                    ),
                  ),
                ],
              ),
            ),
          );
        },
      ),
    );
  }
}

class CardItem {
  final String imagePath;
  bool isFlipped;
  bool isMatched;

  CardItem({
    required this.imagePath,
    required this.isFlipped,
    required this.isMatched,
  });
}
