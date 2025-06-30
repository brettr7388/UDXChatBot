import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../models/bot_personality.dart';
import 'dart:math';

class PersonalityService extends ChangeNotifier {
  static const String _personalityKey = 'selected_bot_personality';
  BotPersonality _selectedPersonality = BotPersonality.shrek;
  final Random _random = Random();

  BotPersonality get selectedPersonality => _selectedPersonality;

  PersonalityService() {
    _loadSelectedPersonality();
  }

  Future<void> _loadSelectedPersonality() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final personalityName = prefs.getString(_personalityKey);
      
      if (personalityName != null) {
        final personality = BotPersonality.values.firstWhere(
          (p) => p.name == personalityName,
          orElse: () => BotPersonality.shrek,
        );
        _selectedPersonality = personality;
        notifyListeners();
      }
    } catch (e) {
      debugPrint('Error loading personality: $e');
    }
  }

  Future<void> setPersonality(BotPersonality personality) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString(_personalityKey, personality.name);
      _selectedPersonality = personality;
      notifyListeners();
    } catch (e) {
      debugPrint('Error saving personality: $e');
    }
  }

  String getPersonalityIcon() {
    return _selectedPersonality.emoji;
  }

  String getPersonalityGreeting() {
    return _selectedPersonality.greeting;
  }

  String getPersonalityName() {
    return _selectedPersonality.displayName;
  }

  // Generate personality-specific recommendation message
  String generateRecommendationMessage({
    required String rideName,
    required String park,
    required int waitTime,
    required int walkingTime,
    String? sessionInfo,
  }) {
    final intro = _getPersonalityIntro();
    final rideDescription = _getPersonalityRideDescription(rideName);
    final waitTimeComment = _getPersonalityWaitTimeComment(waitTime);
    final enthusiasm = _getPersonalityEnthusiasm();
    
    String message = "$intro Based on your location in $park, I $rideDescription:\n\n";
    message += "**$rideName**\n";
    message += "⏱️ Wait time: $waitTime minutes $waitTimeComment\n";
    message += "🚶 Walking time: ~$walkingTime minute${walkingTime == 1 ? '' : 's'}\n\n";
    message += "$enthusiasm${sessionInfo ?? ''}";
    
    return message;
  }

  // Generate personality-specific alternative recommendation message
  String generateAlternativeMessage({
    required String rideName,
    required String park,
    required int waitTime,
    required int walkingTime,
  }) {
    final altIntro = _getPersonalityAlternativeIntro();
    final suggestion = _getPersonalitySuggestion();
    
    String message = "$altIntro for $park!\n\n";
    message += "**$rideName**\n";
    message += "⏱️ Wait time: $waitTime minutes\n";
    message += "🚶 Walking time: ~$walkingTime minute${walkingTime == 1 ? '' : 's'}\n\n";
    message += "$suggestion";
    
    return message;
  }

  String _getPersonalityIntro() {
    switch (_selectedPersonality) {
      case BotPersonality.shrek:
        return "🟢 Well, well, well! *adjusts suspenders*";
      case BotPersonality.harryPotter:
        return "⚡ Brilliant!";
      case BotPersonality.minions:
        return "🟡 Ooooh! Banana! Wait, no... RIDE!";
      case BotPersonality.jurassicPark:
        return "🦕 *ROAR!* Life finds a way...";
      case BotPersonality.homerSimpson:
        return "🍩 D'oh! *burps* Mmm... rides!";
    }
  }

  String _getPersonalityRideDescription(String rideName) {
    List<String> descriptions = [];
    
    switch (_selectedPersonality) {
      case BotPersonality.shrek:
        if (rideName.toLowerCase().contains('water') || rideName.toLowerCase().contains('splash') || rideName.toLowerCase().contains('bilge')) {
          descriptions = ["found the perfect swampy adventure", "spotted a wonderfully wet ride", "discovered something delightfully damp"];
        } else {
          descriptions = ["found a ride worthy of an ogre", "discovered something better than onions", "spotted an adventure fit for Far Far Away"];
        }
        break;
      case BotPersonality.harryPotter:
        if (rideName.toLowerCase().contains('harry') || rideName.toLowerCase().contains('magic') || rideName.toLowerCase().contains('wizard')) {
          descriptions = ["sense powerful magic calling", "feel the wizarding world beckoning", "detect extraordinary magical energy"];
        } else {
          descriptions = ["foresee an enchanting adventure", "predict a magical experience", "divine a wondrous journey"];
        }
        break;
      case BotPersonality.minions:
        descriptions = ["found something SUPER fun", "spotted a TOTALLY awesome ride", "discovered something more exciting than bananas"];
        break;
      case BotPersonality.jurassicPark:
        if (rideName.toLowerCase().contains('jurassic') || rideName.toLowerCase().contains('dino') || rideName.toLowerCase().contains('kong')) {
          descriptions = ["tracked down a prehistoric paradise", "hunted the perfect Mesozoic adventure", "discovered a primordial thrill"];
        } else {
          descriptions = ["evolved the perfect recommendation", "adapted to find you the ideal ride", "survived to suggest this adventure"];
        }
        break;
      case BotPersonality.homerSimpson:
        descriptions = ["figured out the perfect lazy choice", "found something that doesn't require too much walking", "spotted a ride that looks... uh... fun and stuff"];
        break;
    }
    
    return descriptions[_random.nextInt(descriptions.length)];
  }

  String _getPersonalityWaitTimeComment(int waitTime) {
    switch (_selectedPersonality) {
      case BotPersonality.shrek:
        return waitTime <= 15 ? "- not bad for us impatient types!" : waitTime <= 30 ? "- eh, I've waited longer for Princess Fiona" : "- longer than my morning routine, but worth it!";
      case BotPersonality.harryPotter:
        return waitTime <= 15 ? "- quicker than a Quidditch match!" : waitTime <= 30 ? "- about as long as a Potions class" : "- longer than detention with Snape, but more fun!";
      case BotPersonality.minions:
        return waitTime <= 15 ? "- shorter than Stuart's attention span!" : waitTime <= 30 ? "- perfect banana-eating time!" : "- long enough to sing our favorite songs!";
      case BotPersonality.jurassicPark:
        return waitTime <= 15 ? "- faster than a Velociraptor!" : waitTime <= 30 ? "- about one feeding cycle" : "- longer than it takes to escape a T-Rex!";
      case BotPersonality.homerSimpson:
        return waitTime <= 15 ? "- perfect! Time for a quick donut!" : waitTime <= 30 ? "- eh, gives me time to think about beer" : "- D'oh! That's longer than my lunch break!";
    }
  }

  String _getPersonalityEnthusiasm() {
    List<String> phrases = [];
    
    switch (_selectedPersonality) {
      case BotPersonality.shrek:
        phrases = ["This looks ogre-some! Better get going before I change my mind! 🎉", "What are you waiting for? Get out there and have some fun! 🎢", "Trust me, this beats sitting in a swamp all day! ✨"];
        break;
      case BotPersonality.harryPotter:
        phrases = ["This adventure awaits - may magic be with you! ✨", "Off you go! This promises to be absolutely magical! 🎉", "Your destiny calls - have an enchanting time! 🎢"];
        break;
      case BotPersonality.minions:
        phrases = ["This is gonna be AWESOME! Woo-hoo! 🎉", "Banana-tastic choice! Have super fun! 🎢", "GELATO! Wait... I mean, have an amazing time! ✨"];
        break;
      case BotPersonality.jurassicPark:
        phrases = ["Clever choice! Now go have a roaring good time! 🎉", "Life finds a way... to have fun! Enjoy! 🎢", "Spare no expense for this adventure! ✨"];
        break;
      case BotPersonality.homerSimpson:
        phrases = ["Mmm... this ride looks good! Like a donut, but with more screaming! 🎉", "Woo-hoo! This is gonna be... uh... what was I talking about? 🎢", "D'oh! Just go have fun already! *cracks open a beer* ✨"];
        break;
    }
    
    return phrases[_random.nextInt(phrases.length)];
  }

  String _getPersonalityAlternativeIntro() {
    switch (_selectedPersonality) {
      case BotPersonality.shrek:
        return "🔄 **Hold your horses!** Here's another swamp-worthy option";
      case BotPersonality.harryPotter:
        return "🔄 **Wait!** The crystal ball shows another path";
      case BotPersonality.minions:
        return "🔄 **WAIT WAIT WAIT!** Even BETTER idea";
      case BotPersonality.jurassicPark:
        return "🔄 **HOLD EVERYTHING!** My radar detected another option";
      case BotPersonality.homerSimpson:
        return "🔄 **WAIT!** *drops donut* I got a better idea!";
    }
  }

  String _getPersonalitySuggestion() {
    List<String> suggestions = [];
    
    switch (_selectedPersonality) {
      case BotPersonality.shrek:
        suggestions = ["This one's got layers... of fun! How about it? 🎢", "Sometimes the second choice is even better! Like onions! 🎉", "Give this beauty a try instead! 🎢✨"];
        break;
      case BotPersonality.harryPotter:
        suggestions = ["Perhaps this magical alternative will suit you better? ✨", "The winds of magic suggest this path instead! 🎢", "This choice may hold even greater wonders! 🎉"];
        break;
      case BotPersonality.minions:
        suggestions = ["This one looks even MORE fun! Woo! 🎢", "Ooh! Ooh! Try this one instead! 🎉", "Even better than bananas! Well, almost! 🎢✨"];
        break;
      case BotPersonality.jurassicPark:
        suggestions = ["This specimen looks even more thrilling! 🎢", "Evolution in action - try this improved choice! 🎉", "A more ferocious option has emerged! 🎢✨"];
        break;
      case BotPersonality.homerSimpson:
        suggestions = ["This one looks even better! Like a glazed donut of fun! 🎢", "Ooh! Ooh! Try this instead! *gets distracted by snack stand* 🎉", "This ride has potential... like a beer that's actually cold! 🎢✨"];
        break;
    }
    
    return suggestions[_random.nextInt(suggestions.length)];
  }

  // Generate personality-specific greeting response
  String generateGreetingResponse() {
    List<String> greetings = [];
    
    switch (_selectedPersonality) {
      case BotPersonality.shrek:
        greetings = [
          "Well hello there! 🟢 *wipes mud off hands* \n\nFancy meeting you in this neck of the woods! I may be an ogre, but I know my way around these parts!\n\nI can help you find:\n🎢 The most ogre-some rides\n🍕 Grub that's better than bugs\n🛍️ Treasures worth hoarding\n\nWhat'll it be, friend?",
          "Hey now! 🟢 Don't be afraid - I'm much nicer than I look!\n\nSure, I'd rather be back in my swamp, but since we're here, let's make the best of it! I know all the good spots:\n🎢 Rides with real bite\n🍕 Food that won't make you green\n🛍️ Shiny things to take home\n\nWhat sounds good to ya?",
        ];
        break;
      case BotPersonality.harryPotter:
        greetings = [
          "Greetings, fellow adventurer! ⚡\n\nI sense great magic in the air today! The sorting hat may have placed me in Gryffindor, but my knowledge spans all of Universal's magical realms.\n\nI can guide you to:\n🎢 The most enchanting attractions\n🍕 Magical feasts and treats\n🛍️ Mystical shops and treasures\n\nWhat magical adventure calls to you?",
          "Hello there! ⚡ *adjusts glasses and checks marauder's map*\n\nThe stars align perfectly for an amazing day at Universal! Whether you're a Muggle or wizard, I'll help you discover:\n🎢 Spellbinding rides and attractions\n🍕 Feasts fit for Hogwarts\n🛍️ Magical artifacts and souvenirs\n\nWhere shall our magical journey begin?",
        ];
        break;
      case BotPersonality.minions:
        greetings = [
          "HELLOOOOO! 🟡 *bounces excitedly*\n\nOoh! Ooh! You want help? We LOVE helping! Is so much fun!\n\nWe know ALL the best places:\n🎢 Super duper fun rides!\n🍕 Yummy food (almost as good as bananas!)\n🛍️ Shiny sparkly things to buy!\n\nWhat we do first? TELL US TELL US!",
          "BANANA! Wait, no... HELLO! 🟡 *giggles*\n\nWe are SOOO excited you are here! Is gonna be best day EVER! We help you find:\n🎢 Most awesome rides (wheee!)\n🍕 Delicious snacks and treats\n🛍️ Perfect gifts for everyone!\n\nOoh! What sounds most fun to you?",
        ];
        break;
      case BotPersonality.jurassicPark:
        greetings = [
          "Welcome to Universal Orlando! 🦕 *thunderous footsteps approach*\n\nLife, uh, finds a way... to have an amazing time here! I've evolved quite a bit since the Mesozoic era, and now I'm your prehistoric guide to modern fun!\n\nI can hunt down:\n🎢 Thrilling expeditions and rides\n🍕 Sustenance for apex predators (and humans)\n🛍️ Fossils and treasures to collect\n\nWhat prey shall we track first?",
          "*ROAR!* 🦕 Don't worry - I'm a friendly dinosaur!\n\nSixty-five million years of evolution have taught me the best spots in Universal Orlando! \n\nLet me guide you to:\n🎢 Adventures worthy of the Cretaceous period\n🍕 Feeding grounds for all species\n🛍️ Artifacts for your collection\n\nWhere does your survival instinct lead you?",
        ];
        break;
      case BotPersonality.homerSimpson:
        greetings = [
          "D'oh! Hello there! 🍩 *scratches belly and burps*\n\nHomer Simpson here! I may work at a nuclear power plant, but today I'm your guide to... uh... whatever this place is! Universal something?\n\nI can help you find:\n🎢 Rides that don't make me motion sick\n🍕 The good snack spots (I've done my research)\n🛍️ Gift shops with beer... or donut-shaped things\n\nSo... *opens beer* what d'ya wanna do first?",
          "Woo-hoo! 🍩 *trips over own feet*\n\nMmm... Universal Orlando! Reminds me of that time I... uh... what were we talking about? Oh yeah! Fun stuff!\n\nI know all the best spots:\n🎢 Rides that are worth leaving the couch for\n🍕 Food stands with the biggest portions\n🛍️ Places to buy things Marge will yell at me for\n\nSo what'll it be? Just remember - no running! Running is for people who don't drive everywhere!",
        ];
        break;
    }
    
    return greetings[_random.nextInt(greetings.length)];
  }

  // Generate personality-specific food recommendation
  String generateFoodResponse(String parkContext) {
    List<String> responses = [];
    
    switch (_selectedPersonality) {
      case BotPersonality.shrek:
        responses = [
          "🍕 Hungry, eh? Well, you've come to the right ogre! *rubs belly*\n\nI know where to find grub that's way better than swamp rat:\n\n🏰 **Three Broomsticks** - They've got hearty meals fit for an ogre!\n🍔 **Krusty Burger** - Simple and satisfying\n🌮 **Leaky Cauldron** - Magical food that won't turn you green!\n\nBetter than anything Fiona ever cooked! Want directions to any of these?",
        ];
        break;
      case BotPersonality.harryPotter:
        responses = [
          "🍕 Ah, seeking sustenance for your magical journey! ⚡\n\nI know exactly where to find the most enchanting meals:\n\n🏰 **Three Broomsticks** - Authentic wizarding fare from Hogsmeade!\n🍔 **Krusty Burger** - Muggle food that's surprisingly magical\n🌮 **Leaky Cauldron** - Where wizards dine in Diagon Alley!\n\nShall I conjure up directions to any of these mystical dining establishments?",
        ];
        break;
      case BotPersonality.minions:
        responses = [
          "🍕 FOOD! We LOVE food! Almost as much as bananas! 🟡\n\nOoh! Ooh! We know all the yummiest places:\n\n🏰 **Three Broomsticks** - Is like fancy banana restaurant!\n🍔 **Krusty Burger** - Kevin says is very tasty!\n🌮 **Leaky Cauldron** - Stuart found it first!\n\nWant us to show you way? We are VERY good at finding food! *tummy rumbles*",
        ];
        break;
      case BotPersonality.jurassicPark:
        responses = [
          "🍕 Ah, time to refuel! Even apex predators need proper nutrition! 🦕\n\nI've scouted the best feeding grounds:\n\n🏰 **Three Broomsticks** - Hearty meals for modern hunters\n🍔 **Krusty Burger** - Quick sustenance for busy predators\n🌮 **Leaky Cauldron** - Exotic cuisine from another era\n\nLife finds a way... to satisfy hunger! Need coordinates to any of these locations?",
        ];
        break;
      case BotPersonality.homerSimpson:
        responses = [
          "🍕 Mmm... food! *drools* 🍩\n\nOh man, you came to the right guy! I know where all the good eats are:\n\n🏰 **Three Broomsticks** - They've got hearty stuff! Like a turkey leg but... uh... more magical\n🍔 **Krusty Burger** - Hey! Just like the one in Springfield! Except this one probably won't give you food poisoning\n🌮 **Leaky Cauldron** - Fancy wizard food! *whispers* But do they have beer?\n\nD'oh! I'm getting hungry just thinking about it! Want directions to stuff your face?",
        ];
        break;
    }
    
    return responses[_random.nextInt(responses.length)];
  }

  // Generate personality-specific "no rides available" message
  String generateNoRidesMessage(String park) {
    List<String> responses = [];
    
    switch (_selectedPersonality) {
      case BotPersonality.shrek:
        responses = [
          "🎢 Well, would ya look at that! You've been busier than me cleaning my swamp! 🟢\n\nLooks like you've conquered most of $park! Here's what this ogre suggests:\n• Try the other park - fresh adventures await!\n• Go back to your favorites - sometimes the best things are worth repeating\n• Grab some grub - all that fun works up an appetite!\n• Take a breather - even ogres need rest!\n\nWhat sounds good to ya?",
        ];
        break;
      case BotPersonality.harryPotter:
        responses = [
          "🎢 Incredible! You've mastered most of the magical realms in $park! ⚡\n\nYour quest options now include:\n• Journey to the other magical park for new spells and adventures\n• Revisit your most enchanting experiences\n• Discover mystical dining and shopping treasures\n• Rest and reflect on your magical accomplishments\n\nWhat magical path calls to you next?",
        ];
        break;
      case BotPersonality.minions:
        responses = [
          "🎢 WOW! You did it! You tried almost everything in $park! 🟡 *claps excitedly*\n\nOoh! Ooh! What now?\n• Go to other park - MORE FUN AWAITS!\n• Do favorite rides again - we love doing things again!\n• Find snacks - we are getting hungry!\n• Take nap - Kevin is already sleepy!\n\nWhat sounds most AWESOME?",
        ];
        break;
      case BotPersonality.jurassicPark:
        responses = [
          "🎢 Remarkable! You've dominated the ecosystem of $park like a true apex predator! 🦕\n\nEvolution suggests these survival strategies:\n• Migrate to the other territory for new hunting grounds\n• Revisit successful feeding... I mean, riding locations\n• Explore sustenance and resource gathering areas\n• Rest and conserve energy for future expeditions\n\nWhat's your next evolutionary move?",
        ];
        break;
      case BotPersonality.homerSimpson:
        responses = [
          "🎢 Wow! You did everything in $park! That's more productive than I've been... well, ever! 🍩\n\nSo now what? *scratches head*\n• Go to the other park - more rides, more fun, more... uh... walking\n• Do your favorites again - like watching TV reruns, but with more screaming\n• Find more food - my stomach is making that noise again\n• Take a nap - I mean, rest! Rest is important for... uh... safety!\n\nD'oh! What sounds good? Just remember, whatever we do, let's not tell Marge how much we spent!",
        ];
        break;
    }
    
    return responses[_random.nextInt(responses.length)];
  }
} 