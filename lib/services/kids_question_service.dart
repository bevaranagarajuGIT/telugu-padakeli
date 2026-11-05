import '../models/kids_question.dart';

class KidsQuestionService {
  const KidsQuestionService();

  List<KidsQuestionLevel> getLevels() {
    return const [
      KidsQuestionLevel(
        name: 'Beginner',
        title: 'ప్రారంభ స్థాయి',
        questions: [
          KidsQuestion(
            prompt: 'కమ_ం',
            answer: 'ల',
            hint: 'నీటిలో పూసే పువ్వు',
            options: ['ల', 'ర', 'మ', 'ప'],
          ),
          KidsQuestion(
            prompt: 'అ_ము',
            answer: 'మ',
            hint: 'అమ్మ అనే పదానికి దగ్గరగా ఉంటుంది',
            options: ['మ', 'ల', 'న', 'క'],
          ),
          KidsQuestion(
            prompt: 'పా_శాల',
            answer: 'ఠ',
            hint: 'చదివే చోటు',
            options: ['ఠ', 'థ', 'ట', 'ద'],
          ),
        ],
      ),
      KidsQuestionLevel(
        name: 'Easy',
        title: 'సులభ స్థాయి',
        questions: [
          KidsQuestion(
            prompt: 'ఆ_ు',
            answer: 'క',
            hint: 'చెట్టు మీద ఉంటుంది',
            options: ['క', 'ల', 'ర', 'మ'],
          ),
          KidsQuestion(
            prompt: 'పూ_ు',
            answer: 'ల',
            hint: 'తోటలో కనిపించే పువ్వులు',
            options: ['ల', 'మ', 'న', 'ప'],
          ),
          KidsQuestion(
            prompt: 'గో_ు',
            answer: 'ర',
            hint: 'వేలి చివర ఉండేది',
            options: ['ర', 'క', 'మ', 'ల'],
          ),
        ],
      ),
      KidsQuestionLevel(
        name: 'Medium',
        title: 'మధ్యస్థ స్థాయి',
        questions: [
          KidsQuestion(
            prompt: 'మా_ిడి',
            answer: 'మి',
            hint: 'పసుపు రంగు తియ్యని పండు',
            options: ['మి', 'కు', 'ని', 'రు'],
          ),
          KidsQuestion(
            prompt: 'ప_ువు',
            answer: 'శు',
            hint: 'పెంపుడు జంతువులలో ఒకటి',
            options: ['శు', 'ము', 'కు', 'లు'],
          ),
          KidsQuestion(
            prompt: 'చె_ు',
            answer: 'ట్టు',
            hint: 'పెద్ద మొక్క',
            options: ['ట్టు', 'క్కు', 'మ్ము', 'య్యి'],
          ),
        ],
      ),
      KidsQuestionLevel(
        name: 'Hard',
        title: 'కఠిన స్థాయి',
        questions: [
          KidsQuestion(
            prompt: 'పర్యా_రణం',
            answer: 'వ',
            hint: 'మన చుట్టూ ఉన్న ప్రకృతి',
            options: ['వ', 'ల', 'మ', 'స'],
          ),
          KidsQuestion(
            prompt: 'స్వా_ంత్ర్యం',
            answer: 'తం',
            hint: 'స్వేచ్ఛకు మరో పేరు',
            options: ['తం', 'రం', 'కం', 'నం'],
          ),
          KidsQuestion(
            prompt: 'నైపు_్యం',
            answer: 'ణ',
            hint: 'ఒక పనిని చక్కగా చేయగలగడం',
            options: ['ణ', 'న', 'మ', 'ల'],
          ),
        ],
      ),
      KidsQuestionLevel(
        name: 'Expert',
        title: 'నిపుణ స్థాయి',
        questions: [
          KidsQuestion(
            prompt: 'సామా_ికం',
            answer: 'జి',
            hint: 'సమాజానికి సంబంధించినది',
            options: ['జి', 'మి', 'ని', 'తి'],
          ),
          KidsQuestion(
            prompt: 'విద్యా_ి',
            answer: 'ర్థి',
            hint: 'చదువుకునే వ్యక్తి',
            options: ['ర్థి', 'ర్తి', 'ర్ధి', 'ర్తు'],
          ),
          KidsQuestion(
            prompt: 'సామర్థ్య_ం',
            answer: 'య',
            hint: 'పని చేయగల శక్తి',
            options: ['య', 'ర', 'త', 'న'],
          ),
        ],
      ),
    ];
  }
}
