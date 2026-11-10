import '../models/kids_learning.dart';
import '../models/telugu_akshara.dart';
import 'kids_question_service.dart';

class KidsLearningService {
  const KidsLearningService();

  List<KidsLearningActivity> getActivities() {
    final legacy = const KidsQuestionService().getLevels();
    KidsLearningActivity completion(int level, LearningCategory category) {
      return KidsLearningActivity(
        id: 'completion-$level',
        type: KidsActivityType.completion,
        categories: {category},
        title: 'పదాన్ని పూర్తి చేయి — ${legacy[level].title}',
        englishTitle: 'Complete the word — ${legacy[level].name}',
        questions: [
          for (var i = 0; i < legacy[level].questions.length; i++)
            KidsLearningQuestion(
              id: 'completion-$level-$i',
              prompt: 'తప్పిన అక్షరాన్ని ఎంచుకోండి',
              englishPrompt: 'Choose the missing letter.',
              display: legacy[level].questions[i].prompt,
              answer: legacy[level].questions[i].answer,
              completedWord: legacy[level].questions[i].prompt.replaceFirst(
                '_',
                legacy[level].questions[i].answer,
              ),
              explanation: legacy[level].questions[i].hint,
              englishExplanation: legacy[level].questions[i].englishHint,
              choices: [
                for (final option in legacy[level].questions[i].options)
                  KidsChoice(option),
              ],
              difficulty: legacy[level].difficulty,
            ),
        ],
      );
    }

    KidsLearningQuestion letter(
      String id,
      String display,
      String answer,
      String english,
      List<KidsChoice> choices,
    ) => KidsLearningQuestion(
      id: id,
      display: display,
      prompt: 'ఈ అక్షరంతో మొదలయ్యే పదం ఏది?',
      englishPrompt: 'Which word begins with this letter?',
      answer: answer,
      choices: choices,
      explanation: '$display — $answer',
      englishExplanation: english,
    );

    KidsLearningQuestion meaning(
      String id,
      String display,
      String answer,
      String englishDisplay,
      String englishAnswer,
      List<KidsChoice> choices, {
      bool opposite = false,
      int difficulty = 3,
    }) => KidsLearningQuestion(
      id: id,
      display: display,
      prompt: opposite
          ? 'దీనికి వ్యతిరేక పదం ఏది?'
          : 'దీనికి దగ్గర అర్థం ఉన్న పదం ఏది?',
      englishPrompt: opposite
          ? 'Which word is the opposite?'
          : 'Which word has a similar meaning?',
      answer: answer,
      choices: choices,
      explanation: opposite
          ? '$display అనే పదానికి వ్యతిరేక పదం $answer.'
          : '$display, $answer దగ్గర అర్థాలు కలిగిన పదాలు.',
      englishExplanation: opposite
          ? '$englishAnswer is the opposite of $englishDisplay.'
          : '$englishDisplay and $englishAnswer have similar meanings.',
      difficulty: difficulty,
    );

    final activities = [
      const KidsLearningActivity(
        id: 'pictures',
        type: KidsActivityType.picture,
        categories: {LearningCategory.early},
        title: 'బొమ్మను గుర్తించు',
        englishTitle: 'Picture matching',
        questions: [
          KidsLearningQuestion(
            id: 'picture-mango',
            prompt: 'ఇది ఏమిటి?',
            englishPrompt: 'What is this?',
            answer: 'మామిడి',
            imageAsset: 'assets/artwork/kids/mango.png',
            imageDescription: 'ఆకులతో పసుపు రంగు మామిడి పండు బొమ్మ',
            choices: [
              KidsChoice('మామిడి', 'Mango'),
              KidsChoice('అరటి', 'Banana'),
              KidsChoice('జామ', 'Guava'),
            ],
            explanation: 'మామిడి ఒక పండు.',
            englishExplanation: 'A mango is a fruit.',
          ),
          KidsLearningQuestion(
            id: 'picture-parrot',
            prompt: 'ఇది ఏమిటి?',
            englishPrompt: 'What is this?',
            answer: 'చిలుక',
            imageAsset: 'assets/artwork/kids/parrot.png',
            imageDescription: 'పచ్చని చిలుక బొమ్మ',
            choices: [
              KidsChoice('కాకి', 'Crow'),
              KidsChoice('చిలుక', 'Parrot'),
              KidsChoice('పావురం', 'Pigeon'),
            ],
            explanation: 'చిలుక ఒక పక్షి.',
            englishExplanation: 'A parrot is a bird.',
          ),
          KidsLearningQuestion(
            id: 'picture-mango-colour',
            prompt: 'ఈ పండు ఏ రంగులో ఉంది?',
            englishPrompt: 'What colour is this fruit?',
            answer: 'పసుపు',
            imageAsset: 'assets/artwork/kids/mango.png',
            imageDescription: 'ఆకులతో పసుపు రంగు మామిడి పండు బొమ్మ',
            choices: [
              KidsChoice('నీలం', 'Blue'),
              KidsChoice('పసుపు', 'Yellow'),
              KidsChoice('ఎరుపు', 'Red'),
            ],
            explanation: 'ఈ బొమ్మలో మామిడి పండు పసుపు రంగులో ఉంది.',
            englishExplanation: 'The mango in this picture is yellow.',
          ),
          KidsLearningQuestion(
            id: 'picture-parrot-kind',
            prompt: 'ఈ చిలుక దేనికి ఉదాహరణ?',
            englishPrompt: 'What kind of animal is this parrot?',
            answer: 'పక్షి',
            imageAsset: 'assets/artwork/kids/parrot.png',
            imageDescription: 'పచ్చని చిలుక బొమ్మ',
            choices: [
              KidsChoice('చేప', 'Fish'),
              KidsChoice('కీటకం', 'Insect'),
              KidsChoice('పక్షి', 'Bird'),
            ],
            explanation: 'చిలుకకు రెక్కలు ఉంటాయి. చిలుక ఒక పక్షి.',
            englishExplanation: 'A parrot has wings. It is a bird.',
          ),
          KidsLearningQuestion(
            id: 'picture-mango-kind',
            prompt: 'ఈ మామిడి దేనికి ఉదాహరణ?',
            englishPrompt: 'What kind of food is this mango?',
            answer: 'పండు',
            imageAsset: 'assets/artwork/kids/mango.png',
            imageDescription: 'ఆకులతో పసుపు రంగు మామిడి పండు బొమ్మ',
            choices: [
              KidsChoice('పండు', 'Fruit'),
              KidsChoice('ధాన్యం', 'Grain'),
              KidsChoice('పప్పు', 'Pulse'),
            ],
            explanation: 'మామిడి చెట్టుకు కాసే ఒక పండు.',
            englishExplanation: 'A mango is a fruit that grows on a tree.',
          ),
        ],
      ),
      KidsLearningActivity(
        id: 'letters',
        type: KidsActivityType.letter,
        categories: {LearningCategory.early, LearningCategory.explorers},
        title: 'అక్షరాలను గుర్తించు',
        englishTitle: 'Letter recognition',
        questions: [
          const KidsLearningQuestion(
            id: 'letter-a',
            display: 'అ',
            prompt: 'ఈ అక్షరంతో మొదలయ్యే పదం ఏది?',
            englishPrompt: 'Which word begins with this letter?',
            answer: 'అరటి',
            choices: [
              KidsChoice('అరటి', 'Banana'),
              KidsChoice('ఆవు', 'Cow'),
              KidsChoice('ఇల్లు', 'House'),
            ],
            explanation: 'అ — అరటి',
            englishExplanation: 'Banana.',
          ),
          const KidsLearningQuestion(
            id: 'letter-aa',
            display: 'ఆ',
            prompt: 'ఈ అక్షరంతో మొదలయ్యే పదం ఏది?',
            englishPrompt: 'Which word begins with this letter?',
            answer: 'ఆవు',
            choices: [
              KidsChoice('ఇల్లు', 'House'),
              KidsChoice('అరటి', 'Banana'),
              KidsChoice('ఆవు', 'Cow'),
            ],
            explanation: 'ఆ — ఆవు',
            englishExplanation: 'Cow.',
          ),
          const KidsLearningQuestion(
            id: 'letter-ka',
            display: 'క',
            prompt: 'ఈ అక్షరంతో మొదలయ్యే పదం ఏది?',
            englishPrompt: 'Which word begins with this letter?',
            answer: 'కలం',
            choices: [
              KidsChoice('ఆవు', 'Cow'),
              KidsChoice('కలం', 'Pen'),
              KidsChoice('ఇల్లు', 'House'),
            ],
            explanation: 'క — కలం',
            englishExplanation: 'Pen.',
          ),
          letter('letter-cha', 'చి', 'చిలుక', 'Parrot.', const [
            KidsChoice('గడియారం', 'Clock'),
            KidsChoice('చిలుక', 'Parrot'),
            KidsChoice('కలం', 'Pen'),
          ]),
          letter('letter-ga', 'గ', 'గడియారం', 'Clock.', const [
            KidsChoice('గడియారం', 'Clock'),
            KidsChoice('చిలుక', 'Parrot'),
            KidsChoice('అరటి', 'Banana'),
          ]),
        ],
      ),
      KidsLearningActivity(
        id: 'letters-2',
        type: KidsActivityType.letter,
        categories: const {LearningCategory.early},
        title: 'అచ్చులతో ఆట',
        englishTitle: 'Vowel word game',
        questions: [
          letter('letter-i', 'ఇ', 'ఇల్లు', 'House.', const [
            KidsChoice('ఈగ', 'Fly'),
            KidsChoice('ఇల్లు', 'House'),
            KidsChoice('ఉడుత', 'Squirrel'),
          ]),
          letter('letter-ii', 'ఈ', 'ఈగ', 'Fly.', const [
            KidsChoice('ఈగ', 'Fly'),
            KidsChoice('ఇల్లు', 'House'),
            KidsChoice('ఊయల', 'Swing'),
          ]),
          letter('letter-u', 'ఉ', 'ఉడుత', 'Squirrel.', const [
            KidsChoice('ఎలుక', 'Mouse'),
            KidsChoice('ఇల్లు', 'House'),
            KidsChoice('ఉడుత', 'Squirrel'),
          ]),
          letter('letter-uu', 'ఊ', 'ఊయల', 'Swing.', const [
            KidsChoice('ఊయల', 'Swing'),
            KidsChoice('ఉడుత', 'Squirrel'),
            KidsChoice('ఈగ', 'Fly'),
          ]),
          letter('letter-e', 'ఎ', 'ఎలుక', 'Mouse.', const [
            KidsChoice('ఊయల', 'Swing'),
            KidsChoice('ఎలుక', 'Mouse'),
            KidsChoice('ఇల్లు', 'House'),
          ]),
        ],
      ),
      KidsLearningActivity(
        id: 'letters-3',
        type: KidsActivityType.letter,
        categories: const {LearningCategory.early},
        title: 'మరిన్ని అక్షరాలు',
        englishTitle: 'More letter discoveries',
        questions: [
          letter('letter-ee', 'ఏ', 'ఏనుగు', 'Elephant.', const [
            KidsChoice('ఏనుగు', 'Elephant'),
            KidsChoice('ఒంటె', 'Camel'),
            KidsChoice('ఓడ', 'Ship'),
          ]),
          letter('letter-ai', 'ఐ', 'ఐదు', 'Five.', const [
            KidsChoice('ఒంటె', 'Camel'),
            KidsChoice('ఐదు', 'Five'),
            KidsChoice('తల', 'Head'),
          ]),
          letter('letter-o', 'ఒం', 'ఒంటె', 'Camel.', const [
            KidsChoice('ఓడ', 'Ship'),
            KidsChoice('ఏనుగు', 'Elephant'),
            KidsChoice('ఒంటె', 'Camel'),
          ]),
          letter('letter-oo', 'ఓ', 'ఓడ', 'Ship.', const [
            KidsChoice('ఓడ', 'Ship'),
            KidsChoice('ఒంటె', 'Camel'),
            KidsChoice('ఐదు', 'Five'),
          ]),
          letter('letter-ta', 'త', 'తల', 'Head.', const [
            KidsChoice('ఏనుగు', 'Elephant'),
            KidsChoice('తల', 'Head'),
            KidsChoice('ఓడ', 'Ship'),
          ]),
        ],
      ),
      completion(0, LearningCategory.explorers),
      completion(1, LearningCategory.explorers),
      const KidsLearningActivity(
        id: 'builder',
        type: KidsActivityType.builder,
        categories: {LearningCategory.explorers, LearningCategory.champions},
        title: 'పదాలు నిర్మించు',
        englishTitle: 'Word builder',
        questions: [
          KidsLearningQuestion(
            id: 'build-mango',
            prompt: 'పండు పేరు నిర్మించండి',
            englishPrompt: 'Build the word for mango.',
            answer: 'మామిడి',
            tiles: ['మి', 'డి', 'మా'],
            explanation: 'మా + మి + డి = మామిడి',
            englishExplanation: 'Mango.',
          ),
          KidsLearningQuestion(
            id: 'build-mother',
            prompt: 'తల్లి అనే అర్థం వచ్చే పదం నిర్మించండి',
            englishPrompt: 'Build the word for mother.',
            answer: 'అమ్మ',
            tiles: ['మ్మ', 'అ'],
            explanation: 'అ + మ్మ = అమ్మ',
            englishExplanation: 'Mother.',
          ),
          KidsLearningQuestion(
            id: 'build-baby',
            prompt: 'చిన్న బిడ్డను పిలిచే పదం నిర్మించండి',
            englishPrompt: 'Build the word for baby.',
            answer: 'పాప',
            tiles: ['ప', 'పా'],
            explanation: 'పా + ప = పాప',
            englishExplanation: 'Baby.',
          ),
          KidsLearningQuestion(
            id: 'build-uncle',
            prompt: 'అమ్మ సోదరుడిని పిలిచే పదం నిర్మించండి',
            englishPrompt: "Build the word for mother's brother.",
            answer: 'మామ',
            tiles: ['మ', 'మా'],
            explanation: 'మా + మ = మామ',
            englishExplanation: "Mother's brother.",
          ),
          KidsLearningQuestion(
            id: 'build-chatter',
            prompt: 'నవ్వుల సందడి శబ్దాన్ని నిర్మించండి',
            englishPrompt: 'Build the word for cheerful chatter.',
            answer: 'కలకల',
            tiles: ['ల', 'క', 'ల', 'క'],
            explanation: 'క + ల + క + ల = కలకల',
            englishExplanation: 'Cheerful chatter.',
          ),
        ],
      ),
      KidsLearningActivity(
        id: 'meanings',
        type: KidsActivityType.meaning,
        categories: {LearningCategory.champions},
        title: 'అర్థాన్ని గుర్తించు',
        englishTitle: 'Meaning match',
        questions: [
          const KidsLearningQuestion(
            id: 'meaning-courage',
            display: 'ధైర్యం',
            prompt: 'దీనికి దగ్గర అర్థం ఉన్న పదం ఏది?',
            englishPrompt: 'Which word has a similar meaning?',
            answer: 'సాహసం',
            choices: [
              KidsChoice('సాహసం', 'Bravery'),
              KidsChoice('భయం', 'Fear'),
              KidsChoice('అలసట', 'Tiredness'),
            ],
            explanation: 'ధైర్యం అంటే భయపడకుండా ముందుకు వెళ్లే గుణం.',
            englishExplanation: 'Courage means facing something without fear.',
            difficulty: 3,
          ),
          const KidsLearningQuestion(
            id: 'meaning-joy',
            display: 'ఆనందం',
            prompt: 'దీనికి దగ్గర అర్థం ఉన్న పదం ఏది?',
            englishPrompt: 'Which word has a similar meaning?',
            answer: 'సంతోషం',
            choices: [
              KidsChoice('దుఃఖం', 'Sadness'),
              KidsChoice('సంతోషం', 'Happiness'),
              KidsChoice('నిద్ర', 'Sleep'),
            ],
            explanation: 'ఆనందం, సంతోషం దగ్గర అర్థాలు కలిగిన పదాలు.',
            englishExplanation: 'Joy and happiness have similar meanings.',
            difficulty: 3,
          ),
          const KidsLearningQuestion(
            id: 'meaning-dark',
            display: 'వెలుగు',
            prompt: 'దీనికి వ్యతిరేక పదం ఏది?',
            englishPrompt: 'Which word is the opposite?',
            answer: 'చీకటి',
            choices: [
              KidsChoice('వేడి', 'Heat'),
              KidsChoice('గాలి', 'Air'),
              KidsChoice('చీకటి', 'Darkness'),
            ],
            explanation: 'వెలుగుకు వ్యతిరేక పదం చీకటి.',
            englishExplanation: 'Darkness is the opposite of light.',
            difficulty: 3,
          ),
          meaning(
            'meaning-truth',
            'నిజం',
            'సత్యం',
            'truth',
            'truthfulness',
            const [
              KidsChoice('అబద్ధం', 'Lie'),
              KidsChoice('సత్యం', 'Truth'),
              KidsChoice('భయం', 'Fear'),
            ],
          ),
          meaning('meaning-anger', 'కోపం', 'ఆగ్రహం', 'anger', 'rage', const [
            KidsChoice('ఆగ్రహం', 'Anger'),
            KidsChoice('శాంతి', 'Peace'),
            KidsChoice('ఆనందం', 'Joy'),
          ]),
        ],
      ),
      completion(2, LearningCategory.champions),
      KidsLearningActivity(
        id: 'builder-2',
        type: KidsActivityType.builder,
        categories: const {
          LearningCategory.explorers,
          LearningCategory.champions,
        },
        title: 'మరిన్ని పదాలు నిర్మించు',
        englishTitle: 'Word builder challenge',
        questions: [
          for (final (index, word) in const [
            (
              'పలక',
              'రాసి చెరిపే సాధనం పేరు నిర్మించండి',
              'Build the word for slate.',
            ),
            (
              'కమలం',
              'నీటిలో పూసే పువ్వు పేరు నిర్మించండి',
              'Build the word for lotus.',
            ),
            (
              'పుస్తకం',
              'పేజీలు ఉండే చదివే వస్తువు పేరు నిర్మించండి',
              'Build the word for book.',
            ),
            (
              'ఇల్లు',
              'మనం నివసించే చోటు పేరు నిర్మించండి',
              'Build the word for house.',
            ),
            (
              'చిలుక',
              'పచ్చని పక్షి పేరు నిర్మించండి',
              'Build the word for parrot.',
            ),
            (
              'అరటి',
              'గుత్తిగా పెరిగే పండు పేరు నిర్మించండి',
              'Build the word for banana.',
            ),
            (
              'ఆకాశం',
              'మేఘాలు కనిపించే చోటు పేరు నిర్మించండి',
              'Build the word for sky.',
            ),
          ].indexed)
            KidsLearningQuestion(
              id: 'build-2-$index',
              prompt: word.$2,
              englishPrompt: word.$3,
              answer: word.$1,
              tiles: [
                ...TeluguAkshara.split(word.$1).skip(1),
                TeluguAkshara.split(word.$1).first,
              ],
              explanation:
                  '${TeluguAkshara.split(word.$1).join(' + ')} = ${word.$1}',
              englishExplanation: word.$3,
              difficulty: 3,
            ),
        ],
      ),
      completion(5, LearningCategory.champions),
      KidsLearningActivity(
        id: 'meanings-2',
        type: KidsActivityType.meaning,
        categories: const {LearningCategory.champions},
        title: 'అర్థాలు, వ్యతిరేక పదాలు',
        englishTitle: 'Synonyms and opposites',
        questions: [
          meaning(
            'meaning-big',
            'చిన్న',
            'పెద్ద',
            'small',
            'big',
            const [
              KidsChoice('పెద్ద', 'Big'),
              KidsChoice('కొత్త', 'New'),
              KidsChoice('మంచి', 'Good'),
            ],
            opposite: true,
            difficulty: 4,
          ),
          meaning(
            'meaning-cold',
            'వేడి',
            'చలి',
            'heat',
            'cold',
            const [
              KidsChoice('వెలుగు', 'Light'),
              KidsChoice('చలి', 'Cold'),
              KidsChoice('గాలి', 'Air'),
            ],
            opposite: true,
            difficulty: 4,
          ),
          meaning(
            'meaning-night',
            'పగలు',
            'రాత్రి',
            'day',
            'night',
            const [
              KidsChoice('ఉదయం', 'Morning'),
              KidsChoice('మధ్యాహ్నం', 'Noon'),
              KidsChoice('రాత్రి', 'Night'),
            ],
            opposite: true,
            difficulty: 4,
          ),
          meaning(
            'meaning-bad',
            'మంచి',
            'చెడు',
            'good',
            'bad',
            const [
              KidsChoice('చెడు', 'Bad'),
              KidsChoice('కొత్త', 'New'),
              KidsChoice('పెద్ద', 'Big'),
            ],
            opposite: true,
            difficulty: 4,
          ),
          meaning(
            'meaning-old',
            'కొత్త',
            'పాత',
            'new',
            'old',
            const [
              KidsChoice('మంచి', 'Good'),
              KidsChoice('పాత', 'Old'),
              KidsChoice('చిన్న', 'Small'),
            ],
            opposite: true,
            difficulty: 4,
          ),
          meaning(
            'meaning-far',
            'దగ్గర',
            'దూరం',
            'near',
            'far',
            const [
              KidsChoice('వేడి', 'Heat'),
              KidsChoice('చలి', 'Cold'),
              KidsChoice('దూరం', 'Far'),
            ],
            opposite: true,
            difficulty: 4,
          ),
          meaning('meaning-water', 'నీరు', 'జలం', 'water', 'water', const [
            KidsChoice('జలం', 'Water'),
            KidsChoice('నిప్పు', 'Fire'),
            KidsChoice('గాలి', 'Air'),
          ], difficulty: 4),
          meaning('meaning-earth', 'భూమి', 'పృథ్వి', 'earth', 'earth', const [
            KidsChoice('ఆకాశం', 'Sky'),
            KidsChoice('పృథ్వి', 'Earth'),
            KidsChoice('సముద్రం', 'Sea'),
          ], difficulty: 4),
          meaning(
            'meaning-friend',
            'మిత్రుడు',
            'స్నేహితుడు',
            'friend',
            'friend',
            const [
              KidsChoice('శత్రువు', 'Enemy'),
              KidsChoice('అతిథి', 'Guest'),
              KidsChoice('స్నేహితుడు', 'Friend'),
            ],
            difficulty: 4,
          ),
          meaning('meaning-forest', 'వనం', 'అడవి', 'woodland', 'forest', const [
            KidsChoice('అడవి', 'Forest'),
            KidsChoice('ఊరు', 'Village'),
            KidsChoice('ఇల్లు', 'House'),
          ], difficulty: 4),
        ],
      ),
    ];
    validate(activities);
    return List.unmodifiable(activities);
  }

  static void validate(List<KidsLearningActivity> activities) {
    final ids = <String>{};
    final questions = <String>{};
    for (final activity in activities) {
      activity.validate();
      if (!ids.add(activity.id)) {
        throw FormatException('Duplicate activity: ${activity.id}');
      }
      for (final question in activity.questions) {
        if (!questions.add(question.id)) {
          throw FormatException('Duplicate content: ${question.id}');
        }
      }
    }
  }
}
