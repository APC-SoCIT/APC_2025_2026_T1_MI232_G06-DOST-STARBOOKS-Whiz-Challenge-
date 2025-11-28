class Question {
  final String question;
  final List<String> options;
  final String correctAnswer;

  Question({
    required this.question,
    required this.options,
    required this.correctAnswer,
  });
}

class QuizData {
  static List<Question> getQuestions(String category, String difficulty) {
    if (category == "Science") {
      switch (difficulty) {
        case "EASY":
          return _scienceEasy;
        case "AVERAGE":
          return _scienceAverage;
        case "DIFFICULT":
          return _scienceDifficult;
        default:
          return _scienceEasy;
      }
    } else if (category == "Math") {
      switch (difficulty) {
        case "EASY":
          return _mathEasy;
        case "AVERAGE":
          return _mathAverage;
        case "DIFFICULT":
          return _mathDifficult;
        default:
          return _mathEasy;
      }
    }
    return [];
  }

  // SCIENCE - EASY
  static final List<Question> _scienceEasy = [
    Question(
      question: "What is the largest planet in our solar system?",
      options: ["Earth", "Jupiter", "Uranus", "Saturn"],
      correctAnswer: "Jupiter",
    ),
    Question(
      question: "What gas do plants absorb from the atmosphere?",
      options: ["Oxygen", "Nitrogen", "Carbon Dioxide", "Hydrogen"],
      correctAnswer: "Carbon Dioxide",
    ),
    Question(
      question: "How many bones does an adult human have?",
      options: ["186", "206", "226", "246"],
      correctAnswer: "206",
    ),
    Question(
      question: "What is the closest star to Earth?",
      options: ["Alpha Centauri", "The Sun", "Sirius", "Polaris"],
      correctAnswer: "The Sun",
    ),
    Question(
      question: "What is the chemical symbol for water?",
      options: ["H2O", "O2", "CO2", "H2"],
      correctAnswer: "H2O",
    ),
    Question(
      question: "What force pulls objects toward the Earth?",
      options: ["Magnetism", "Friction", "Gravity", "Tension"],
      correctAnswer: "Gravity",
    ),
    Question(
      question: "What is the boiling point of water?",
      options: ["90°C", "100°C", "110°C", "120°C"],
      correctAnswer: "100°C",
    ),
    Question(
      question: "Which animal is known as the 'King of the Jungle'?",
      options: ["Tiger", "Elephant", "Lion", "Bear"],
      correctAnswer: "Lion",
    ),
    Question(
      question: "What organ pumps blood through the body?",
      options: ["Lungs", "Brain", "Liver", "Heart"],
      correctAnswer: "Heart",
    ),
    Question(
      question: "How many planets are in our solar system?",
      options: ["7", "8", "9", "10"],
      correctAnswer: "8",
    ),
  ];

  // SCIENCE - AVERAGE
  static final List<Question> _scienceAverage = [
    Question(
      question: "What is the process by which plants make their food?",
      options: ["Respiration", "Photosynthesis", "Digestion", "Fermentation"],
      correctAnswer: "Photosynthesis",
    ),
    Question(
      question: "What is the speed of light?",
      options: ["300,000 km/s", "150,000 km/s", "450,000 km/s", "200,000 km/s"],
      correctAnswer: "300,000 km/s",
    ),
    Question(
      question: "What is the smallest unit of life?",
      options: ["Atom", "Molecule", "Cell", "Organ"],
      correctAnswer: "Cell",
    ),
    Question(
      question: "Which element has the chemical symbol 'Fe'?",
      options: ["Iron", "Fluorine", "Fermium", "Francium"],
      correctAnswer: "Iron",
    ),
    Question(
      question: "What type of rock is formed by cooling magma?",
      options: ["Sedimentary", "Metamorphic", "Igneous", "Limestone"],
      correctAnswer: "Igneous",
    ),
    Question(
      question: "What is the powerhouse of the cell?",
      options: ["Nucleus", "Mitochondria", "Ribosome", "Chloroplast"],
      correctAnswer: "Mitochondria",
    ),
    Question(
      question: "What is the most abundant gas in Earth's atmosphere?",
      options: ["Oxygen", "Carbon Dioxide", "Nitrogen", "Argon"],
      correctAnswer: "Nitrogen",
    ),
    Question(
      question: "How long does it take for Earth to orbit the Sun?",
      options: ["365 days", "360 days", "400 days", "300 days"],
      correctAnswer: "365 days",
    ),
    Question(
      question: "What is the chemical formula for table salt?",
      options: ["NaCl", "KCl", "CaCl2", "MgCl2"],
      correctAnswer: "NaCl",
    ),
    Question(
      question: "Which planet is known as the Red Planet?",
      options: ["Venus", "Mars", "Jupiter", "Saturn"],
      correctAnswer: "Mars",
    ),
  ];

  // SCIENCE - DIFFICULT
  static final List<Question> _scienceDifficult = [
    Question(
      question: "What is the Heisenberg Uncertainty Principle?",
      options: [
        "Energy cannot be created or destroyed",
        "You cannot know both position and momentum precisely",
        "Light behaves as both wave and particle",
        "Time is relative to the observer",
      ],
      correctAnswer: "You cannot know both position and momentum precisely",
    ),
    Question(
      question: "What is the first element on the periodic table?",
      options: ["Helium", "Hydrogen", "Lithium", "Carbon"],
      correctAnswer: "Hydrogen",
    ),
    Question(
      question: "What is the half-life of Carbon-14?",
      options: ["5,730 years", "10,000 years", "2,500 years", "8,000 years"],
      correctAnswer: "5,730 years",
    ),
    Question(
      question: "What particle has no electric charge?",
      options: ["Electron", "Proton", "Neutron", "Positron"],
      correctAnswer: "Neutron",
    ),
    Question(
      question: "What is the study of fungi called?",
      options: ["Mycology", "Virology", "Bacteriology", "Phycology"],
      correctAnswer: "Mycology",
    ),
    Question(
      question: "What is the SI unit of electric current?",
      options: ["Volt", "Ohm", "Ampere", "Watt"],
      correctAnswer: "Ampere",
    ),
    Question(
      question: "What is the chemical formula for sulfuric acid?",
      options: ["HCl", "H2SO4", "HNO3", "H3PO4"],
      correctAnswer: "H2SO4",
    ),
    Question(
      question: "Which organelle is responsible for protein synthesis?",
      options: ["Ribosome", "Golgi apparatus", "Lysosome", "Peroxisome"],
      correctAnswer: "Ribosome",
    ),
    Question(
      question: "What is the largest organ in the human body?",
      options: ["Liver", "Brain", "Skin", "Heart"],
      correctAnswer: "Skin",
    ),
    Question(
      question: "What is the most abundant element in the universe?",
      options: ["Oxygen", "Carbon", "Helium", "Hydrogen"],
      correctAnswer: "Hydrogen",
    ),
  ];

  // MATH - EASY
  static final List<Question> _mathEasy = [
    Question(
      question: "What is 5 + 7?",
      options: ["10", "11", "12", "13"],
      correctAnswer: "12",
    ),
    Question(
      question: "What is 9 × 6?",
      options: ["54", "56", "52", "48"],
      correctAnswer: "54",
    ),
    Question(
      question: "What is 100 ÷ 4?",
      options: ["20", "25", "30", "15"],
      correctAnswer: "25",
    ),
    Question(
      question: "What is 15 - 8?",
      options: ["6", "7", "8", "9"],
      correctAnswer: "7",
    ),
    Question(
      question: "What is half of 50?",
      options: ["20", "25", "30", "35"],
      correctAnswer: "25",
    ),
    Question(
      question: "How many sides does a triangle have?",
      options: ["2", "3", "4", "5"],
      correctAnswer: "3",
    ),
    Question(
      question: "What is 3 × 3?",
      options: ["6", "9", "12", "15"],
      correctAnswer: "9",
    ),
    Question(
      question: "What is 20 + 30?",
      options: ["40", "50", "60", "70"],
      correctAnswer: "50",
    ),
    Question(
      question: "What is 8 × 5?",
      options: ["35", "40", "45", "50"],
      correctAnswer: "40",
    ),
    Question(
      question: "What is 64 ÷ 8?",
      options: ["6", "7", "8", "9"],
      correctAnswer: "8",
    ),
  ];

  // MATH - AVERAGE
  static final List<Question> _mathAverage = [
    Question(
      question: "What is the square root of 144?",
      options: ["10", "11", "12", "13"],
      correctAnswer: "12",
    ),
    Question(
      question: "What is 25% of 200?",
      options: ["25", "50", "75", "100"],
      correctAnswer: "50",
    ),
    Question(
      question: "What is 7²?",
      options: ["42", "45", "49", "56"],
      correctAnswer: "49",
    ),
    Question(
      question: "Solve: 3x = 15. What is x?",
      options: ["3", "4", "5", "6"],
      correctAnswer: "5",
    ),
    Question(
      question: "What is the value of π (pi) rounded to two decimals?",
      options: ["3.12", "3.14", "3.16", "3.18"],
      correctAnswer: "3.14",
    ),
    Question(
      question: "How many degrees are in a right angle?",
      options: ["45°", "60°", "90°", "180°"],
      correctAnswer: "90°",
    ),
    Question(
      question: "What is 15 × 12?",
      options: ["160", "170", "180", "190"],
      correctAnswer: "180",
    ),
    Question(
      question: "What is the perimeter of a square with side 5cm?",
      options: ["15cm", "20cm", "25cm", "30cm"],
      correctAnswer: "20cm",
    ),
    Question(
      question: "What is 0.5 as a fraction?",
      options: ["1/3", "1/2", "1/4", "2/3"],
      correctAnswer: "1/2",
    ),
    Question(
      question: "What is 2³?",
      options: ["4", "6", "8", "10"],
      correctAnswer: "8",
    ),
  ];

  // MATH - DIFFICULT
  static final List<Question> _mathDifficult = [
    Question(
      question: "What is the derivative of x² with respect to x?",
      options: ["x", "2x", "x²", "2x²"],
      correctAnswer: "2x",
    ),
    Question(
      question: "What is the sum of interior angles of a hexagon?",
      options: ["540°", "720°", "900°", "1080°"],
      correctAnswer: "720°",
    ),
    Question(
      question: "Solve: log₁₀(1000) = ?",
      options: ["2", "3", "4", "5"],
      correctAnswer: "3",
    ),
    Question(
      question: "What is the quadratic formula?",
      options: [
        "x = -b ± √(b²-4ac) / 2a",
        "x = b ± √(b²+4ac) / 2a",
        "x = -b ± √(b²+4ac) / a",
        "x = b ± √(b²-4ac) / a",
      ],
      correctAnswer: "x = -b ± √(b²-4ac) / 2a",
    ),
    Question(
      question: "What is the Fibonacci sequence's 8th number?",
      options: ["13", "21", "34", "55"],
      correctAnswer: "21",
    ),
    Question(
      question: "What is sin(90°)?",
      options: ["0", "0.5", "1", "√2/2"],
      correctAnswer: "1",
    ),
    Question(
      question: "What is the area of a circle with radius 7?",
      options: ["49π", "14π", "21π", "7π"],
      correctAnswer: "49π",
    ),
    Question(
      question: "What is the integral of 2x?",
      options: ["x²", "x² + C", "2x²", "2x² + C"],
      correctAnswer: "x² + C",
    ),
    Question(
      question: "What is the slope of a line y = 3x + 5?",
      options: ["3", "5", "8", "15"],
      correctAnswer: "3",
    ),
    Question(
      question: "What is e (Euler's number) approximately?",
      options: ["2.18", "2.52", "2.72", "3.14"],
      correctAnswer: "2.72",
    ),
  ];
}