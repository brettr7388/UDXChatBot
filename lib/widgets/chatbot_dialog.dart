import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'dart:math';
import '../services/recommendation_service.dart';
import '../services/location_service.dart';
import '../services/personality_service.dart';
import '../models/recommendation.dart';
import 'personality_avatar.dart';

class ChatbotDialog extends StatefulWidget {
  final Function(String fromRide, String toRide)? onDirectionsRequested;
  
  const ChatbotDialog({super.key, this.onDirectionsRequested});

  @override
  State<ChatbotDialog> createState() => _ChatbotDialogState();
}

class _ChatbotDialogState extends State<ChatbotDialog> {
  final TextEditingController _messageController = TextEditingController();
  final List<ChatMessage> _messages = [];
  final ScrollController _scrollController = ScrollController();
  final Random _random = Random();
  bool _isLoading = false;

  // Track only new recommendations in this chat session (not persistent)
  final Set<String> _sessionRecommendations = {};
  final List<String> _conversationHistory = [];
  
  // Track the last recommendation context for refresh functionality
  String? _lastRecommendationContext;
  String? _lastFromRide;
  String? _lastPark;
  List<String>? _lastExcludeRides;
  String? _lastRecommendedRide; // Track the last recommended ride for exclusion on refresh

  // List of popular rides to use as a fallback if no location/last ride is available
  final List<String> _fallbackPopularRides = [
    'Harry Potter and the Forbidden Journey™',
    'Jurassic World VelociCoaster',
    'The Incredible Hulk Coaster®',
    'Revenge of the Mummy™',
    'TRANSFORMERS™: The Ride-3D',
  ];

  // Park-specific ride lists for fallback recommendations
  final Map<String, List<String>> _parkRides = {
    'Islands of Adventure': [
      'Harry Potter and the Forbidden Journey™',
      'Flight of the Hippogriff™',
      'Hagrid\'s Magical Creatures Motorbike Adventure™',
      'Jurassic World VelociCoaster',
      'The Incredible Hulk Coaster®',
      'The Amazing Adventures of Spider-Man®',
      'Skull Island: Reign of Kong™',
      'Jurassic Park River Adventure™',
      'Pteranodon Flyers™',
      'Doctor Doom\'s Fearfall®',
      'Storm Force Accelatron®',
      'Caro-Seuss-el™',
      'One Fish, Two Fish, Red Fish, Blue Fish™',
      'The Cat In The Hat™',
      'The High in the Sky Seuss Trolley Train Ride!™',
      'Dudley Do-Right\'s Ripsaw Falls®',
      'Popeye & Bluto\'s Bilge-Rat Barges®',
    ],
    'Universal Studios': [
      'Revenge of the Mummy™',
      'Hollywood Rip Ride Rockit™',
      'E.T. Adventure™',
      'Despicable Me Minion Mayhem™',
      'Illumination\'s Villain-Con Minion Blast',
      'Race Through New York Starring Jimmy Fallon™',
      'TRANSFORMERS™: The Ride-3D',
      'Fast & Furious - Supercharged™',
      'Harry Potter and the Escape from Gringotts™',
      'Kang & Kodos\' Twirl \'n\' Hurl',
      'MEN IN BLACK™ Alien Attack!™',
      'The Simpsons Ride™',
    ],
  };

  @override
  void initState() {
    super.initState();
    // Initial message will be set in build method after PersonalityService is available
  }

  void _sendMessage() async {
    if (_messageController.text.trim().isEmpty) return;

    final userMessage = _messageController.text.trim();
    _messageController.clear();

    setState(() {
      _messages.add(ChatMessage(
        text: userMessage,
        isBot: false,
        timestamp: DateTime.now(),
      ));
      _isLoading = true;
    });

    _scrollToBottom();

    try {
      final response = await _generateBotResponse(userMessage);
      
      // Only add response if it's not empty (recommendation messages handle themselves)
      if (response.isNotEmpty) {
        setState(() {
          _messages.add(ChatMessage(
            text: response,
            isBot: true,
            timestamp: DateTime.now(),
          ));
          _isLoading = false;
        });
      } else {
        setState(() {
          _isLoading = false;
        });
      }
    } catch (e) {
      setState(() {
        _messages.add(ChatMessage(
          text: "Sorry, I'm having trouble connecting. Please try again. 🔄",
          isBot: true,
          timestamp: DateTime.now(),
        ));
        _isLoading = false;
      });
    }
    _scrollToBottom();
  }

  void _sendQuickMessage(String message) {
    _messageController.text = message;
    _sendMessage();
  }

  // Refresh the last recommendation with an alternative
  Future<void> _refreshLastRecommendation() async {
    if (_lastFromRide == null || _lastPark == null || _lastExcludeRides == null) {
      return; // No previous recommendation to refresh
    }

    setState(() {
      _isLoading = true;
    });

    try {
      final recommendationService = context.read<RecommendationService>();
      
      // Create updated exclusion list that includes the last recommended ride
      Set<String> refreshExcludeRides = Set<String>.from(_lastExcludeRides!);
      if (_lastRecommendedRide != null) {
        refreshExcludeRides.add(_lastRecommendedRide!);
      }
      
      // Get alternative recommendation
      final recommendation = await recommendationService.getRecommendation(
        lastRide: _lastFromRide!,
        park: _lastPark!,
        excludeRides: refreshExcludeRides.toList(),
      );
      
      String? recommendedRide;
      int waitTime = 15;
      int walkingMinutes = 5;
      
      if (recommendation != null) {
        recommendedRide = recommendation.rideName;
        waitTime = recommendation.waitTime;
        walkingMinutes = recommendation.walkingMinutes;
      } else {
        // Fallback: Get park-specific recommendation excluding the previous one
        recommendedRide = _getParkSpecificRecommendation(_lastPark!, refreshExcludeRides.toList());
      }
      
      if (recommendedRide != null) {
        // Remove the old recommendation from session tracking and add the new one
        if (_lastRecommendedRide != null) {
          _sessionRecommendations.remove(_lastRecommendedRide!);
        }
        _sessionRecommendations.add(recommendedRide);
        
        final personalityService = context.read<PersonalityService>();
        final responseText = personalityService.generateAlternativeMessage(
          rideName: recommendedRide,
          park: _lastPark!,
          waitTime: waitTime,
          walkingTime: walkingMinutes,
        );
        
        setState(() {
          _messages.add(ChatMessage(
            text: responseText,
            isBot: true,
            timestamp: DateTime.now(),
            fromRide: _lastFromRide,
            toRide: recommendedRide,
            recommendedRideName: recommendedRide,
          ));
          _isLoading = false;
        });
        
        // Update the context for potential future refreshes
        _lastRecommendationContext = responseText;
        _lastRecommendedRide = recommendedRide;
        _lastExcludeRides = refreshExcludeRides.toList();
        
      } else {
        setState(() {
          _messages.add(ChatMessage(
            text: "🎢 I've run out of fresh recommendations for $_lastPark! You might want to:\n\n"
                   "• Try the other park for new adventures\n"
                   "• Re-visit some favorites\n"
                   "• Take a break and grab some food! 🍕",
            isBot: true,
            timestamp: DateTime.now(),
          ));
          _isLoading = false;
        });
      }
    } catch (e) {
      setState(() {
        _messages.add(ChatMessage(
          text: "Sorry, I had trouble getting an alternative recommendation. Please try asking for a new recommendation! 🔄",
          isBot: true,
          timestamp: DateTime.now(),
        ));
        _isLoading = false;
      });
    }
    
    _scrollToBottom();
  }

  Future<String> _generateBotResponse(String userMessage) async {
    final recommendationService = context.read<RecommendationService>();
    final locationService = context.read<LocationService>();
    
    // Add to conversation history
    _conversationHistory.add(userMessage.toLowerCase());
    
    final message = userMessage.toLowerCase();
    
    if (message.contains('ride') || message.contains('attraction') || message.contains('next')) {
      String? lastRide = locationService.lastVisitedRide;
      String currentPark = locationService.currentPark ?? "Islands of Adventure";

      // Get actually visited rides from location service
      final visitedRides = locationService.visitedRides;

      // If we've recommended many rides, suggest taking a break
      if (_sessionRecommendations.length >= 5) {
        return "🎢 Wow, you're really making the most of your day! You've gotten ${_sessionRecommendations.length} recommendations so far.\n\n"
               "Maybe it's time for a break? I can suggest:\n"
               "🍕 Food options\n"
               "🛍️ Gift shops\n" 
               "💧 Water fountains or rest areas\n\n"
               "Or if you want another ride recommendation, just ask! 😊";
      }

      if (lastRide == null) {
        lastRide = _fallbackPopularRides[_random.nextInt(_fallbackPopularRides.length)];
        _messages.add(ChatMessage(
          text: "(Since I'm not sure what you rode last, I'll start with a popular one: $lastRide)",
          isBot: true,
          isSystemMessage: true,
          timestamp: DateTime.now(),
        ));
      
         _messages.add(ChatMessage(
          text: "(Okay, I see your last ride was $lastRide in $currentPark. Let's find something new!)",
          isBot: true,
          isSystemMessage: true,
          timestamp: DateTime.now(),
        ));
      }
      
      // Create exclusion list: visited rides + session recommendations + last ride
      Set<String> excludeRides = Set<String>.from(visitedRides);
      excludeRides.addAll(_sessionRecommendations);
      if (lastRide != null) {
        excludeRides.add(lastRide);
      }
      
      // Try to get recommendation from service first
      final recommendation = await recommendationService.getRecommendation(
        lastRide: lastRide,
        park: currentPark,
        excludeRides: excludeRides.toList(),
      );
      
      String? recommendedRide;
      int waitTime = 15; // Default wait time
      int walkingMinutes = 5; // Default walking time
      
      if (recommendation != null) {
        recommendedRide = recommendation.rideName;
        waitTime = recommendation.waitTime;
        walkingMinutes = recommendation.walkingMinutes;
      } else {
        // Fallback: Get park-specific recommendation
        recommendedRide = _getParkSpecificRecommendation(currentPark, excludeRides.toList());
        if (recommendedRide == null) {
          return                  context.read<PersonalityService>().generateNoRidesMessage(currentPark);
        }
      }
      
      if (recommendedRide != null) {
        // Add the new recommendation to our session tracking
        _sessionRecommendations.add(recommendedRide);
        
        String sessionInfo = "";
        if (visitedRides.isNotEmpty || _sessionRecommendations.length > 1) {
          // Show comprehensive session info
          List<String> todaysRecommendations = _sessionRecommendations.toList();
          String visitedInfo = visitedRides.isNotEmpty ? "\n🏁 Visited today: ${visitedRides.length} ride${visitedRides.length == 1 ? '' : 's'}" : "";
          sessionInfo = "\n\n📋 Session summary:"
                       "$visitedInfo\n"
                       "💡 Today's recommendations: ${todaysRecommendations.length}";
        }
        
        final personalityService = context.read<PersonalityService>();
        final responseText = personalityService.generateRecommendationMessage(
          rideName: recommendedRide,
          park: currentPark,
          waitTime: waitTime,
          walkingTime: walkingMinutes,
          sessionInfo: sessionInfo,
        );
        
        // Add the recommendation message with direction data
        setState(() {
          _messages.add(ChatMessage(
            text: responseText,
            isBot: true,
            timestamp: DateTime.now(),
            fromRide: lastRide,
            toRide: recommendedRide,
            recommendedRideName: recommendedRide,
          ));
          _isLoading = false;
        });
        
        // Update the last recommendation context
        _lastRecommendationContext = responseText;
        _lastFromRide = lastRide;
        _lastPark = currentPark;
        _lastExcludeRides = excludeRides.toList();
        _lastRecommendedRide = recommendedRide;
        
        return ""; // Return empty since we're handling the message creation manually
      } else {
        return "I'm having trouble getting current wait times for $currentPark, or we might have covered most of the available rides! Would you like me to suggest some popular attractions instead? 🎢";
      }
    } else if (message.contains('visited') || message.contains('history') || message.contains('done') || message.contains('went on')) {
      final visitedRides = locationService.visitedRides;
      final lastRide = locationService.lastVisitedRide;
      
      if (visitedRides.isEmpty && _sessionRecommendations.isEmpty) {
        return "🎢 You haven't visited any rides yet today! Ready to start your adventure? Just ask me for a ride recommendation! 🎉";
      }
      
      String response = "📋 **Your Universal Orlando Activity Today:**\n\n";
      
      if (visitedRides.isNotEmpty) {
        response += "🏁 **Rides you've actually visited** (${visitedRides.length}):\n";
        for (int i = 0; i < visitedRides.length; i++) {
          response += "${i + 1}. ${visitedRides[i]}\n";
        }
      }
      
      if (_sessionRecommendations.isNotEmpty) {
        // Filter out visited rides from recommendations display
        List<String> pendingRecommendations = _sessionRecommendations.where((ride) => !visitedRides.contains(ride)).toList();
        if (pendingRecommendations.isNotEmpty) {
          response += "\n💡 **Pending recommendations** (${pendingRecommendations.length}):\n";
          for (int i = 0; i < pendingRecommendations.length; i++) {
            response += "${i + 1}. ${pendingRecommendations[i]}\n";
          }
        }
      }
      
      response += "\nWhat would you like to do next? 🎢";
      return response;
    } else if (message.contains('clear') || message.contains('reset')) {
      _sessionRecommendations.clear();
      _conversationHistory.clear();
      return "🔄 **Session Reset!** I've cleared this chat session's recommendations.\n\n"
             "Your actual visited rides (from GPS tracking) are still remembered.\n"
             "Ready to get some fresh recommendations? 🎢✨";
    } else if (message.contains('debug') || message.contains('status')) {
      final visitedRides = locationService.visitedRides;
      final lastRide = locationService.lastVisitedRide;
      final currentPark = locationService.currentPark;
      final currentLoc = locationService.currentLocationLatLng;
      
      String debugInfo = "🔧 **Debug Information:**\n\n";
      debugInfo += "📍 **Location:**\n";
      if (currentLoc != null) {
        debugInfo += "• Current: ${currentLoc.latitude.toStringAsFixed(5)}, ${currentLoc.longitude.toStringAsFixed(5)}\n";
      } else {
        debugInfo += "• Current: Location not available\n";
      }
      debugInfo += "• Park: ${currentPark ?? 'Unknown'}\n";
      debugInfo += "• Last visited: ${lastRide ?? 'None'}\n\n";
      
      debugInfo += "🎢 **Visited Rides:** ${visitedRides.length}\n";
      if (visitedRides.isNotEmpty) {
        for (int i = 0; i < visitedRides.length; i++) {
          debugInfo += "${i + 1}. ${visitedRides[i]}\n";
        }
      } else {
        debugInfo += "None yet\n";
      }
      
      debugInfo += "\n💡 **Session Recommendations:** ${_sessionRecommendations.length}\n";
      if (_sessionRecommendations.isNotEmpty) {
        for (int i = 0; i < _sessionRecommendations.length; i++) {
          debugInfo += "${i + 1}. ${_sessionRecommendations.toList()[i]}\n";
        }
      } else {
        debugInfo += "None yet\n";
      }
      
      return debugInfo;
    } else if (message.contains('food') || message.contains('eat') || message.contains('restaurant')) {
      String parkContext = locationService.currentPark ?? "the park";
      return context.read<PersonalityService>().generateFoodResponse(parkContext);
    } else if (message.contains('where am i') || message.contains('current location')){
      final currentLoc = locationService.currentLocationLatLng;
      final currentPark = locationService.currentPark;
      if (currentLoc != null) {
        String parkInfo = currentPark != null ? "You are currently in $currentPark." : "I'm not sure which park you're in right now.";
        String rideInfo = locationService.lastVisitedRide != null ? " The last ride I saw you near was ${locationService.lastVisitedRide}." : "";
        return "🌍 $parkInfo$rideInfo\nYour current coordinates are: ${currentLoc.latitude.toStringAsFixed(5)}, ${currentLoc.longitude.toStringAsFixed(5)}.";
      }
      return "I'm having trouble getting your exact current location. Make sure location services are enabled!";
    } else if (message.contains('shop') || message.contains('gift') || message.contains('buy')) {
      return "🛍️ Shopping time! Here are some must-visit stores:\n\n"
             "⚡ **Ollivanders** (Both parks)\n"
             "Get your magic wand!\n\n"
             "🕷️ **The Amazing Adventures of Spider-Man Store**\n"
             "Marvel merchandise galore\n\n"
             "🦄 **Honeydukes** (Islands of Adventure)\n"
             "Magical sweets and treats\n\n"
             "Looking for anything specific? 🎁";
    } else if (message.contains('wait') || message.contains('time') || message.contains('busy')) {
      return "⏰ I can check current wait times! The parks are typically:\n\n"
             "🟢 **Less crowded**: Early morning (9-11am) & late evening (6-8pm)\n"
             "🟡 **Moderate**: Mid-morning & afternoon\n"
             "🔴 **Busiest**: Lunch time (12-2pm) & early evening (4-6pm)\n\n"
             "Would you like me to recommend rides with shorter wait times right now?";
    } else if (message.contains('hello') || message.contains('hi') || message.contains('hey')) {
      return context.read<PersonalityService>().generateGreetingResponse();
    } else {
      return "I'd love to help! I specialize in Universal Orlando recommendations. Try asking me about:\n\n"
             "🎢 \"What ride should I go on next?\"\n"
             "🍕 \"Where should I eat?\"\n"
             "🛍️ \"What are the best gift shops?\"\n"
             "⏰ \"What are the current wait times?\"\n"
             "📋 \"What have I visited today?\"\n\n"
             "What would you like to know? 😊";
    }
  }

  void _scrollToBottom() {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (_scrollController.hasClients) {
        _scrollController.animateTo(
          _scrollController.position.maxScrollExtent,
          duration: const Duration(milliseconds: 300),
          curve: Curves.easeOut,
        );
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    return Consumer<PersonalityService>(
      builder: (context, personalityService, child) {
        // Add initial message if empty
        if (_messages.isEmpty) {
          _messages.add(
            ChatMessage(
              text: "${personalityService.getPersonalityGreeting()}\n\nWhat can I recommend for you today?",
              isBot: true,
              timestamp: DateTime.now(),
            ),
          );
        }
        
        return Dialog(
          insetPadding: const EdgeInsets.all(16),
          child: Container(
        height: MediaQuery.of(context).size.height * 0.7,
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(16),
          color: Colors.white,
        ),
        child: Column(
          children: [
            // Header
            Container(
              padding: const EdgeInsets.all(16),
              decoration: const BoxDecoration(
                color: Color(0xFF1976D2),
                borderRadius: BorderRadius.only(
                  topLeft: Radius.circular(16),
                  topRight: Radius.circular(16),
                ),
              ),
              child: Row(
                children: [
                  PersonalityAvatar(
                    personality: personalityService.selectedPersonality,
                    size: 24,
                    backgroundColor: Colors.white.withOpacity(0.2),
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      personalityService.getPersonalityName(),
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                  IconButton(
                    onPressed: () => Navigator.of(context).pop(),
                    icon: const Icon(Icons.close, color: Colors.white),
                  ),
                ],
              ),
            ),
            // Messages
            Expanded(
              child: ListView.builder(
                controller: _scrollController,
                padding: const EdgeInsets.all(16),
                itemCount: _messages.length + (_isLoading ? 1 : 0),
                itemBuilder: (context, index) {
                  if (index == _messages.length && _isLoading) {
                    return _buildLoadingMessage();
                  }
                  return _buildMessage(_messages[index], personalityService);
                },
              ),
            ),
            // Input field
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Colors.grey[50],
                border: Border(top: BorderSide(color: Colors.grey[200]!)),
              ),
              child: Column(
                children: [
                  // Quick action buttons
                  if (_messages.length <= 2) // Only show on initial conversation
                    Container(
                      margin: const EdgeInsets.only(bottom: 12),
                      height: 40,
                      child: ListView(
                        scrollDirection: Axis.horizontal,
                        children: [
                          _buildQuickActionButton('rides', '🎢 Rides'),
                          const SizedBox(width: 8),
                          _buildQuickActionButton('food', '🍕 Food'),
                          const SizedBox(width: 8),
                          _buildQuickActionButton('shops', '🛍️ Shopping'),
                          const SizedBox(width: 8),
                          _buildQuickActionButton('visited today', '📋 History'),
                        ],
                      ),
                    ),
                  Row(
                    children: [
                      Expanded(
                        child: TextField(
                          controller: _messageController,
                          decoration: InputDecoration(
                            hintText: 'Ask me about rides, food, or shops...',
                            border: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(24),
                              borderSide: BorderSide.none,
                            ),
                            filled: true,
                            fillColor: Colors.white,
                            contentPadding: const EdgeInsets.symmetric(
                              horizontal: 16,
                              vertical: 12,
                            ),
                          ),
                          onSubmitted: (_) => _sendMessage(),
                        ),
                      ),
                      const SizedBox(width: 8),
                      FloatingActionButton.small(
                        onPressed: _sendMessage,
                        backgroundColor: const Color(0xFF1976D2),
                        child: const Icon(Icons.send, color: Colors.white, size: 18),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
      },
    );
  }

  Widget _buildMessage(ChatMessage message, PersonalityService personalityService) {
    return Align(
      alignment: message.isBot ? Alignment.centerLeft : Alignment.centerRight,
      child: Column(
        crossAxisAlignment: message.isBot ? CrossAxisAlignment.start : CrossAxisAlignment.end,
        children: [
          Row(
            mainAxisAlignment: message.isBot ? MainAxisAlignment.start : MainAxisAlignment.end,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Bot avatar - only show for bot messages
              if (message.isBot) ...[
                Container(
                  margin: const EdgeInsets.only(right: 8, top: 4),
                  child: PersonalityAvatar(
                    personality: personalityService.selectedPersonality,
                    size: 32,
                  ),
                ),
              ],
              // Message bubble
              Container(
                margin: const EdgeInsets.only(bottom: 12),
                padding: const EdgeInsets.all(12),
                constraints: BoxConstraints(
                  maxWidth: MediaQuery.of(context).size.width * 0.65, // Reduced to accommodate avatar
                ),
                decoration: BoxDecoration(
                  color: message.isBot ? Colors.grey[100] : const Color(0xFF1976D2),
                  borderRadius: BorderRadius.circular(16),
                ),
                child: Text(
                  message.text,
                  style: TextStyle(
                    color: message.isBot ? Colors.black87 : Colors.white,
                    fontSize: 14,
                  ),
                ),
              ),
            ],
          ),
          // Add refresh and directions buttons for recommendation messages
          if (message.isBot && message.recommendedRideName != null)
            Container(
              margin: const EdgeInsets.only(bottom: 12, left: 12),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  // Refresh button
                  ElevatedButton.icon(
                    onPressed: _isLoading ? null : _refreshLastRecommendation,
                    icon: const Icon(Icons.refresh, size: 16),
                    label: const Text('Different Ride'),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.orange,
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                      textStyle: const TextStyle(fontSize: 12),
                      minimumSize: Size.zero,
                      tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                    ),
                  ),
                  // Directions button (if callback is provided)
                  if (message.fromRide != null && 
                      message.toRide != null &&
                      widget.onDirectionsRequested != null) ...[
                    const SizedBox(width: 8),
                    ElevatedButton.icon(
                      onPressed: () {
                        // Close the dialog and request directions
                        Navigator.of(context).pop();
                        widget.onDirectionsRequested!(message.fromRide!, message.toRide!);
                      },
                      icon: const Icon(Icons.directions, size: 16),
                      label: const Text('Get Directions'),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: const Color(0xFF1976D2),
                        foregroundColor: Colors.white,
                        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                        textStyle: const TextStyle(fontSize: 12),
                        minimumSize: Size.zero,
                        tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                      ),
                    ),
                  ],
                ],
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildLoadingMessage() {
    return Align(
      alignment: Alignment.centerLeft,
      child: Container(
        margin: const EdgeInsets.only(bottom: 12),
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: Colors.grey[100],
          borderRadius: BorderRadius.circular(16),
        ),
        child: const Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            SizedBox(
              width: 16,
              height: 16,
              child: CircularProgressIndicator(strokeWidth: 2),
            ),
            SizedBox(width: 8),
            Text('Thinking...'),
          ],
        ),
      ),
    );
  }

  Widget _buildQuickActionButton(String message, String label) {
    return OutlinedButton(
      onPressed: () => _sendQuickMessage(message),
      style: OutlinedButton.styleFrom(
        side: const BorderSide(color: Color(0xFF1976D2)),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(20),
        ),
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      ),
      child: Text(
        label,
        style: const TextStyle(
          color: Color(0xFF1976D2),
          fontSize: 12,
          fontWeight: FontWeight.w500,
        ),
      ),
    );
  }

  String? _getParkSpecificRecommendation(String park, List<String> excludeRides) {
    final parkRides = _parkRides[park] ?? [];
    final availableRides = parkRides.where((ride) => !excludeRides.contains(ride)).toList();
    
    if (availableRides.isEmpty) {
      return null; // No available rides in this park
    }
    
    // Return a random available ride from the current park
    return availableRides[_random.nextInt(availableRides.length)];
  }

  @override
  void dispose() {
    // Clear session-specific recommendations when dialog closes
    _sessionRecommendations.clear();
    _messageController.dispose();
    _scrollController.dispose();
    super.dispose();
  }
}

class ChatMessage {
  final String text;
  final bool isBot;
  final DateTime timestamp;
  final bool isSystemMessage;
  final String? fromRide;
  final String? toRide;
  final String? recommendedRideName;

  ChatMessage({
    required this.text,
    required this.isBot,
    required this.timestamp,
    this.isSystemMessage = false,
    this.fromRide,
    this.toRide,
    this.recommendedRideName,
  });
} 