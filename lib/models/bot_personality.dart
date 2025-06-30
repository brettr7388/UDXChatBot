enum BotPersonality {
  shrek('Shrek', '🟢', 'assets/images/personalities/shrek.png', 'Better out than in, I always say! Let me help you find the best swamp... I mean rides!'),
  harryPotter('Harry Potter', '⚡', 'assets/images/personalities/harry_potter.png', 'Magical recommendations await! Let me guide you through the wizarding world and beyond.'),
  minions('Minions', '🟡', 'assets/images/personalities/minions.png', 'Banana! Papoy! Let me help you find the most despicable... I mean wonderful rides!'),
  jurassicPark('T-Rex', '🦕', 'assets/images/personalities/trex.png', 'Welcome to Jurassic Park! Life finds a way... to have fun on amazing rides!'),
  homerSimpson('Homer Simpson', '🍩', 'assets/images/personalities/homer_simpson.png', 'D\'oh! *scratches belly* Mmm... Universal Orlando! Let me help you find the most... uh... fun stuff!');

  const BotPersonality(this.displayName, this.emoji, this.imagePath, this.greeting);

  final String displayName;
  final String emoji; // Fallback emoji if image fails to load
  final String imagePath;
  final String greeting;

  String get description {
    switch (this) {
      case BotPersonality.shrek:
        return 'The lovable ogre from Far Far Away';
      case BotPersonality.harryPotter:
        return 'The boy who lived, ready to help';
      case BotPersonality.minions:
        return 'Gru\'s adorable yellow helpers';
      case BotPersonality.jurassicPark:
        return 'Prehistoric wisdom for modern fun';
      case BotPersonality.homerSimpson:
        return 'Nuclear power plant safety inspector';
    }
  }
} 