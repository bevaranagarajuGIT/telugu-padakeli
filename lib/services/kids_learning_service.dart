import '../models/kids_learning.dart';
import '../shared/widgets/home_artwork.dart';
import 'kids_question_service.dart';

class KidsLearningService {
  const KidsLearningService();

  List<KidsLearningActivity> getActivities() {
    final legacy = const KidsQuestionService().getLevels();
    KidsLearningActivity completion(int level, LearningCategory category) {
      final translations = level == 0
          ? [
              'A flower that blooms in water.',
              'Another word for mother.',
              'A place where children study.',
            ]
          : [
              'A sweet yellow fruit.',
              'A domesticated animal.',
              'A large plant.',
            ];
      return KidsLearningActivity(
        id: 'completion-$level',
        type: KidsActivityType.completion,
        categories: {category},
        title: 'పదాన్ని పూర్తి చేయి',
        englishTitle: 'Complete the word',
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
              englishExplanation: translations[i],
              choices: [
                for (final option in legacy[level].questions[i].options)
                  KidsChoice(option),
              ],
              difficulty: level + 1,
            ),
        ],
      );
    }

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
            imageAsset: HomeArtwork.welcome,
            imageDescription: 'పచ్చని చిలుక బొమ్మ',
            choices: [
              KidsChoice('కాకి', 'Crow'),
              KidsChoice('చిలుక', 'Parrot'),
              KidsChoice('పావురం', 'Pigeon'),
            ],
            explanation: 'చిలుక ఒక పక్షి.',
            englishExplanation: 'A parrot is a bird.',
          ),
        ],
      ),
      const KidsLearningActivity(
        id: 'letters',
        type: KidsActivityType.letter,
        categories: {LearningCategory.early, LearningCategory.explorers},
        title: 'అక్షరాలను గుర్తించు',
        englishTitle: 'Letter recognition',
        questions: [
          KidsLearningQuestion(
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
          KidsLearningQuestion(
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
          KidsLearningQuestion(
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
        ],
      ),
      completion(0, LearningCategory.explorers),
      completion(2, LearningCategory.champions),
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
      const KidsLearningActivity(
        id: 'meanings',
        type: KidsActivityType.meaning,
        categories: {LearningCategory.champions},
        title: 'అర్థాన్ని గుర్తించు',
        englishTitle: 'Meaning match',
        questions: [
          KidsLearningQuestion(
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
          KidsLearningQuestion(
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
          KidsLearningQuestion(
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
