import '../models/kids_question.dart';

class KidsQuestionService {
  const KidsQuestionService();

  List<KidsQuestionLevel> getLevels() {
    const levels = [
      KidsQuestionLevel(
        name: 'Beginner',
        title: 'ప్రారంభ స్థాయి',
        questions: [
          KidsQuestion(
            prompt: 'కమ_',
            answer: 'లం',
            hint: 'నీటిలో పూసే పువ్వు',
            englishHint: 'A flower that blooms in water.',
            options: ['లం', 'రం', 'మం', 'పం'],
          ),
          KidsQuestion(
            prompt: 'అ_',
            answer: 'మ్మ',
            hint: 'తల్లి అనే అర్థం వచ్చే పదం',
            englishHint: 'Another word for mother.',
            options: ['మ్మ', 'ల్ల', 'న్న', 'క్క'],
          ),
          KidsQuestion(
            prompt: 'పా_శాల',
            answer: 'ఠ',
            hint: 'చదివే చోటు',
            englishHint: 'A place where children study.',
            options: ['ఠ', 'థ', 'ట', 'ద'],
          ),
          KidsQuestion(
            prompt: 'చి_క',
            answer: 'లు',
            hint: 'పచ్చగా ఉండే ఒక పక్షి',
            englishHint: 'A green bird: parrot.',
            options: ['లు', 'రు', 'ను', 'ము'],
          ),
          KidsQuestion(
            prompt: 'క_',
            answer: 'లం',
            hint: 'రాయడానికి ఉపయోగించే సాధనం',
            englishHint: 'A tool used for writing: pen.',
            options: ['లం', 'రం', 'మం', 'నం'],
          ),
        ],
      ),
      KidsQuestionLevel(
        name: 'Easy',
        title: 'సులభ స్థాయి',
        questions: [
          KidsQuestion(
            prompt: 'ఆ_',
            answer: 'కు',
            hint: 'చెట్టు మీద ఉంటుంది',
            englishHint: 'It grows on a tree: leaf.',
            options: ['కు', 'లు', 'రు', 'ము'],
          ),
          KidsQuestion(
            prompt: 'పూ_',
            answer: 'లు',
            hint: 'తోటలో కనిపించే పువ్వులు',
            englishHint: 'Flowers found in a garden.',
            options: ['లు', 'ము', 'ను', 'పు'],
          ),
          KidsQuestion(
            prompt: 'గో_',
            answer: 'రు',
            hint: 'వేలి చివర ఉండేది',
            englishHint: 'It grows at the tip of a finger: nail.',
            options: ['రు', 'కు', 'ము', 'లు'],
          ),
          KidsQuestion(
            prompt: 'పా_',
            answer: 'లు',
            hint: 'ఆవు ఇచ్చే తెల్లని పానీయం',
            englishHint: 'The white drink a cow gives: milk.',
            options: ['లు', 'ము', 'రు', 'కు'],
          ),
          KidsQuestion(
            prompt: 'చే_',
            answer: 'యి',
            hint: 'వస్తువులను పట్టుకోవడానికి ఉపయోగించే శరీర భాగం',
            englishHint: 'The body part used to hold things: hand.',
            options: ['యి', 'లి', 'ని', 'రి'],
          ),
        ],
      ),
      KidsQuestionLevel(
        name: 'Medium',
        title: 'మధ్యస్థ స్థాయి',
        difficulty: 2,
        questions: [
          KidsQuestion(
            prompt: 'మా_డి',
            answer: 'మి',
            hint: 'పసుపు రంగు తియ్యని పండు',
            englishHint: 'A sweet yellow fruit: mango.',
            options: ['మి', 'కు', 'ని', 'రు'],
          ),
          KidsQuestion(
            prompt: 'ప_వు',
            answer: 'శు',
            hint: 'పెంపుడు జంతువులలో ఒకటి',
            englishHint: 'A domesticated animal.',
            options: ['శు', 'ము', 'కు', 'లు'],
          ),
          KidsQuestion(
            prompt: 'చె_',
            answer: 'ట్టు',
            hint: 'పెద్ద మొక్క',
            englishHint: 'A large plant: tree.',
            options: ['ట్టు', 'క్కు', 'మ్ము', 'య్యి'],
          ),
          KidsQuestion(
            prompt: 'పు_కం',
            answer: 'స్త',
            hint: 'చదవడానికి పేజీలు ఉండే వస్తువు',
            englishHint: 'An object with pages to read: book.',
            options: ['స్త', 'స్క', 'త్త', 'ష్ట'],
          ),
          KidsQuestion(
            prompt: 'ప_క',
            answer: 'ల',
            hint: 'పిల్లలు రాసి చెరిపే సాధనం',
            englishHint: 'A slate that children write on.',
            options: ['ల', 'మ', 'న', 'ర'],
          ),
          KidsQuestion(
            prompt: 'నీ_',
            answer: 'రు',
            hint: 'దాహం వేసినప్పుడు తాగేది',
            englishHint: 'We drink it when thirsty: water.',
            options: ['రు', 'లు', 'కు', 'ము'],
          ),
          KidsQuestion(
            prompt: 'గ_యారం',
            answer: 'డి',
            hint: 'సమయాన్ని చూపించే వస్తువు',
            englishHint: 'It shows the time: clock.',
            options: ['డి', 'ని', 'లి', 'పి'],
          ),
        ],
      ),
      KidsQuestionLevel(
        name: 'Hard',
        title: 'కఠిన స్థాయి',
        difficulty: 3,
        questions: [
          KidsQuestion(
            prompt: 'పర్యా_రణం',
            answer: 'వ',
            hint: 'మన చుట్టూ ఉన్న ప్రకృతి',
            englishHint: 'The natural world around us: environment.',
            options: ['వ', 'ల', 'మ', 'స'],
          ),
          KidsQuestion(
            prompt: 'స్వా_త్ర్యం',
            answer: 'తం',
            hint: 'స్వేచ్ఛకు మరో పేరు',
            englishHint: 'Another word for freedom: independence.',
            options: ['తం', 'రం', 'కం', 'నం'],
          ),
          KidsQuestion(
            prompt: 'నైపు_',
            answer: 'ణ్యం',
            hint: 'ఒక పనిని చక్కగా చేయగలగడం',
            englishHint: 'The ability to do a task well: skill.',
            options: ['ణ్యం', 'న్యం', 'మ్యం', 'ల్యం'],
          ),
          KidsQuestion(
            prompt: 'ప్ర_తి',
            answer: 'కృ',
            hint: 'చెట్లు, నదులు, కొండలు కలిసిన సహజ ప్రపంచం',
            englishHint: 'The natural world: nature.',
            options: ['కృ', 'క్ర', 'కి', 'కు'],
          ),
          KidsQuestion(
            prompt: 'స్నే_',
            answer: 'హం',
            hint: 'మిత్రుల మధ్య ఉండే అనుబంధం',
            englishHint: 'The bond between friends: friendship.',
            options: ['హం', 'రం', 'లం', 'నం'],
          ),
          KidsQuestion(
            prompt: 'వి_నం',
            answer: 'జ్ఞా',
            hint: 'అధ్యయనం ద్వారా పొందే జ్ఞానం',
            englishHint: 'Knowledge gained through study.',
            options: ['జ్ఞా', 'జా', 'క్షా', 'శా'],
          ),
          KidsQuestion(
            prompt: 'పరి_భ్రత',
            answer: 'శు',
            hint: 'మనల్ని, మన పరిసరాలను శుభ్రంగా ఉంచడం',
            englishHint: 'Keeping ourselves and our surroundings clean.',
            options: ['శు', 'సు', 'షు', 'చు'],
          ),
        ],
      ),
      KidsQuestionLevel(
        name: 'Expert',
        title: 'నిపుణ స్థాయి',
        difficulty: 4,
        questions: [
          KidsQuestion(
            prompt: 'సామా_కం',
            answer: 'జి',
            hint: 'సమాజానికి సంబంధించినది',
            englishHint: 'Something related to society: social.',
            options: ['జి', 'మి', 'ని', 'తి'],
          ),
          KidsQuestion(
            prompt: 'విద్యా_',
            answer: 'ర్థి',
            hint: 'చదువుకునే వ్యక్తి',
            englishHint: 'A person who studies: student.',
            options: ['ర్థి', 'ర్తి', 'ర్ధి', 'ర్తు'],
          ),
          KidsQuestion(
            prompt: 'సామ_',
            answer: 'ర్థ్యం',
            hint: 'పని చేయగల శక్తి',
            englishHint: 'The capacity to do something: ability.',
            options: ['ర్థ్యం', 'ర్త్యం', 'ర్ధ్యం', 'ర్ణ్యం'],
          ),
          KidsQuestion(
            prompt: 'ఆ_గ్యం',
            answer: 'రో',
            hint: 'శరీరం, మనసు బాగుండే స్థితి',
            englishHint: 'The well-being of body and mind: health.',
            options: ['రో', 'లో', 'నో', 'మో'],
          ),
          KidsQuestion(
            prompt: 'అవ_శం',
            answer: 'కా',
            hint: 'ఒక పని చేయడానికి దొరికే వీలు',
            englishHint: 'A chance to do something: opportunity.',
            options: ['కా', 'గా', 'చా', 'జా'],
          ),
          KidsQuestion(
            prompt: 'ప్ర_త్నం',
            answer: 'య',
            hint: 'ఒక పని సాధించడానికి చేసే కృషి',
            englishHint: 'An effort to achieve something.',
            options: ['య', 'ర', 'ల', 'వ'],
          ),
          KidsQuestion(
            prompt: 'సం_తి',
            answer: 'స్కృ',
            hint: 'ఒక సమాజపు ఆచారాలు, కళలు, జీవన విధానం',
            englishHint: 'The customs and arts of a society: culture.',
            options: ['స్కృ', 'స్క్ర', 'శ్కృ', 'స్తృ'],
          ),
          KidsQuestion(
            prompt: 'గ్రం_లయం',
            answer: 'థా',
            hint: 'చదవడానికి పుస్తకాలు దొరికే చోటు',
            englishHint: 'A place with books to read: library.',
            options: ['థా', 'తా', 'దా', 'ధా'],
          ),
          KidsQuestion(
            prompt: 'సహ_రం',
            answer: 'కా',
            hint: 'ఒకరికొకరు తోడ్పడుతూ కలిసి పని చేయడం',
            englishHint:
                'Working together and helping each other: cooperation.',
            options: ['కా', 'గా', 'చా', 'జా'],
          ),
          KidsQuestion(
            prompt: 'నాయ_త్వం',
            answer: 'క',
            hint: 'ఇతరులను మంచి దారిలో నడిపించే గుణం',
            englishHint: 'The ability to guide others: leadership.',
            options: ['క', 'గ', 'చ', 'జ'],
          ),
        ],
      ),
      KidsQuestionLevel(
        name: 'Master',
        title: 'పద నైపుణ్యం',
        difficulty: 4,
        questions: [
          KidsQuestion(
            prompt: 'పరి_ధన',
            answer: 'శో',
            hint: 'కొత్త విషయాలు తెలుసుకోవడానికి చేసే అధ్యయనం',
            englishHint: 'Study to discover new facts: research.',
            options: ['శో', 'సో', 'షో', 'చో'],
          ),
          KidsQuestion(
            prompt: 'కృత_త',
            answer: 'జ్ఞ',
            hint: 'సాయం చేసినవారికి చూపే ధన్యవాద భావం',
            englishHint: 'Thankfulness for help: gratitude.',
            options: ['జ్ఞ', 'జ', 'క్ష', 'గ్న'],
          ),
          KidsQuestion(
            prompt: 'బా_త',
            answer: 'ధ్య',
            hint: 'మనకు అప్పగించిన పనిని సరిగ్గా నిర్వర్తించడం',
            englishHint: 'Being accountable for a duty: responsibility.',
            options: ['ధ్య', 'ద్య', 'ధ', 'థ్య'],
          ),
          KidsQuestion(
            prompt: 'ప్రజా_మ్యం',
            answer: 'స్వా',
            hint: 'ప్రజలు తమ ప్రతినిధులను ఎన్నుకునే పాలన',
            englishHint:
                'Government through representatives chosen by people: democracy.',
            options: ['స్వా', 'శ్వా', 'సా', 'శా'],
          ),
          KidsQuestion(
            prompt: 'సమా_నం',
            answer: 'ధా',
            hint: 'ప్రశ్నకు ఇచ్చే జవాబు',
            englishHint: 'A response to a question: answer.',
            options: ['ధా', 'దా', 'థా', 'తా'],
          ),
          KidsQuestion(
            prompt: 'సూ_డు',
            answer: 'ర్యు',
            hint: 'భూమికి వెలుగు, వేడి ఇచ్చే నక్షత్రం',
            englishHint: 'The star that gives Earth light and warmth: the Sun.',
            options: ['ర్యు', 'రు', 'ల్యు', 'ర్యూ'],
          ),
          KidsQuestion(
            prompt: 'చం_డు',
            answer: 'ద్రు',
            hint: 'రాత్రి ఆకాశంలో కనిపించే భూమి సహజ ఉపగ్రహం',
            englishHint: 'Earth’s natural satellite: the Moon.',
            options: ['ద్రు', 'ద్రూ', 'ధ్రు', 'త్రు'],
          ),
          KidsQuestion(
            prompt: 'సమా_రం',
            answer: 'చా',
            hint: 'ఒక విషయం గురించి తెలిసే వివరాలు',
            englishHint: 'Facts or details about something: information.',
            options: ['చా', 'జా', 'ఛా', 'శా'],
          ),
          KidsQuestion(
            prompt: 'అభి_ద్ధి',
            answer: 'వృ',
            hint: 'ముందుకు సాగుతూ మెరుగుపడడం',
            englishHint: 'Progress and improvement: development.',
            options: ['వృ', 'వ్ర', 'వు', 'వి'],
          ),
          KidsQuestion(
            prompt: 'అను_వం',
            answer: 'భ',
            hint: 'ఒక పని చేయడం ద్వారా పొందే అవగాహన',
            englishHint: 'Understanding gained by doing: experience.',
            options: ['భ', 'బ', 'ప', 'ఫ'],
          ),
        ],
      ),
      KidsQuestionLevel(
        name: 'Champion',
        title: 'పద ఛాంపియన్',
        difficulty: 5,
        questions: [
          KidsQuestion(
            prompt: 'పట్టు_ల',
            answer: 'ద',
            hint: 'కష్టం వచ్చినా ప్రయత్నం ఆపకుండా ఉండడం',
            englishHint: 'Continuing despite difficulty: perseverance.',
            options: ['ద', 'ధ', 'త', 'థ'],
          ),
          KidsQuestion(
            prompt: 'క్ర_శిక్షణ',
            answer: 'మ',
            hint: 'నియమాలను పాటిస్తూ పద్ధతిగా ఉండడం',
            englishHint: 'Following rules and good routines: discipline.',
            options: ['మ', 'న', 'ర', 'ల'],
          ),
          KidsQuestion(
            prompt: 'పరి_మం',
            answer: 'ణా',
            hint: 'కాలక్రమంలో కలిగే మార్పు',
            englishHint: 'Change over time: evolution or transformation.',
            options: ['ణా', 'నా', 'న్యా', 'మా'],
          ),
          KidsQuestion(
            prompt: 'సమా_త్వం',
            answer: 'న',
            hint: 'అందరికీ సమానమైన గౌరవం, హక్కులు ఉండడం',
            englishHint: 'Equal dignity and rights for everyone: equality.',
            options: ['న', 'ణ', 'మ', 'ర'],
          ),
          KidsQuestion(
            prompt: 'స్వావ_బన',
            answer: 'లం',
            hint: 'తన శక్తితో తన పనులు చేసుకోగలగడం',
            englishHint: 'Being able to rely on oneself: self-reliance.',
            options: ['లం', 'రం', 'నం', 'మం'],
          ),
          KidsQuestion(
            prompt: 'ప్ర_త్వం',
            answer: 'భు',
            hint: 'ప్రజల పాలనను నిర్వహించే వ్యవస్థ',
            englishHint:
                'The system that administers public affairs: government.',
            options: ['భు', 'బు', 'పు', 'ఫు'],
          ),
          KidsQuestion(
            prompt: 'పౌర_త్వం',
            answer: 'స',
            hint: 'ఒక దేశపు పౌరుడిగా ఉండే స్థితి',
            englishHint: 'The status of being a citizen: citizenship.',
            options: ['స', 'శ', 'ష', 'చ'],
          ),
          KidsQuestion(
            prompt: 'సాంకే_కం',
            answer: 'తి',
            hint: 'సాంకేతిక పరిజ్ఞానానికి సంబంధించినది',
            englishHint: 'Something related to technology: technical.',
            options: ['తి', 'థి', 'ది', 'ధి'],
          ),
          KidsQuestion(
            prompt: 'సా_త్యం',
            answer: 'హి',
            hint: 'కవితలు, కథలు వంటి రచనల సమాహారం',
            englishHint: 'Written works such as poems and stories: literature.',
            options: ['హి', 'హీ', 'కి', 'ఖి'],
          ),
          KidsQuestion(
            prompt: 'సం_దాయం',
            answer: 'ప్ర',
            hint: 'తరతరాలుగా కొనసాగుతున్న ఆచారం',
            englishHint: 'A custom passed down through generations: tradition.',
            options: ['ప్ర', 'బ్ర', 'భ్ర', 'ఫ్ర'],
          ),
        ],
      ),
    ];
    final names = <String>{};
    final words = <String>{};
    for (final level in levels) {
      if (!names.add(level.name) || level.questions.isEmpty) {
        throw FormatException('Invalid original-practice level: ${level.name}');
      }
      for (final question in level.questions) {
        question.validate();
        if (!words.add(question.completedWord)) {
          throw FormatException(
            'Duplicate practice word: ${question.completedWord}',
          );
        }
      }
    }
    return List.unmodifiable(levels);
  }
}
