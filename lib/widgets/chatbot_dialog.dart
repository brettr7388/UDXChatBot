import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'dart:math';
import '../services/recommendation_service.dart';
import '../services/location_service.dart';
import '../models/recommendation.dart';

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

  // Track recommended rides in this chat session
  final Set<String> _recommendedRides = {};
  final List<String> _conversationHistory = [];

  // List of popular rides to use as a fallback if no location/last ride is available
  final List<String> _fallbackPopularRides = [
    "The Amazing Adventures of Spider-Man®",
    "Harry Potter and the Forbidden Journey™",
    "Jurassic World VelociCoaster",
    "The Incredible Hulk Coaster®",
  ];

  @override
  void initState() {
    super.initState();
    _messages.add(
      ChatMessage(
        text: "Hi there! 👋 I'm your Universal Orlando assistant. I'm tracking your location to give you the best recommendations!\n\nWhat can I recommend for you today?",
        isBot: true,
        timestamp: DateTime.now(),
      ),
    );
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

  Future<String> _generateBotResponse(String userMessage) async {
    final recommendationService = context.read<RecommendationService>();
    final locationService = context.read<LocationService>();
    
    // Add to conversation history
    _conversationHistory.add(userMessage.toLowerCase());
    
    final message = userMessage.toLowerCase();
    
    if (message.contains('ride') || message.contains('attraction') || message.contains('next')) {
      String? lastRide = locationService.lastVisitedRide;
      String currentPark = locationService.currentPark ?? "Islands of Adventure";

      // If we've recommended many rides, suggest taking a break
      if (_recommendedRides.length >= 5) {
        return "🎢 Wow, you're really making the most of your day! You've gotten ${_recommendedRides.length} recommendations so far.\n\n"
               "Maybe it's time for a break? I can suggest:\n"
               "🍕 Food options\n"
               "🛍️ Gift shops\n" 
               "💧 Water fountains or rest areas\n\n"
               "Or if you want another ride recommendation, just ask! 😊";
      }

      // Use the most recently recommended ride as the "last ride" if we have session history
      if (lastRide == null && _recommendedRides.isNotEmpty) {
        lastRide = _recommendedRides.last;
      }

      if (lastRide == null) {
        lastRide = _fallbackPopularRides[_random.nextInt(_fallbackPopularRides.length)];
        _messages.add(ChatMessage(
          text: "(Since I'm not sure what you rode last, I'll start with a popular one: $lastRide)",
          isBot: true,
          isSystemMessage: true,
          timestamp: DateTime.now(),
        ));
      } else {
         _messages.add(ChatMessage(
          text: "(Okay, I see your last ride was $lastRide in $currentPark. Let's find something new!)",
          isBot: true,
          isSystemMessage: true,
          timestamp: DateTime.now(),
        ));
      }
      
      // IMPORTANT: Add the starting/last ride to the exclusion list if it's not already there
      // This ensures we don't recommend the ride they just came from
      if (lastRide != null && !_recommendedRides.contains(lastRide)) {
        _recommendedRides.add(lastRide);
      }
      
      // Get recommendation with excluded rides (now includes the starting ride)
      final recommendation = await recommendationService.getRecommendation(
        lastRide: lastRide,
        park: currentPark,
        excludeRides: _recommendedRides.toList(),
      );
      
      if (recommendation != null) {
        // Add the new recommendation to our session tracking
        _recommendedRides.add(recommendation.rideName);
        locationService.addVisitedRide(recommendation.rideName);
        
        String sessionInfo = "";
        if (_recommendedRides.length > 2) {
          // Show previous rides but exclude the starting ride from the "recommendations" count
          List<String> actualRecommendations = _recommendedRides.where((ride) => ride != lastRide).toList();
          sessionInfo = "\n\n📋 Today's recommendations: ${actualRecommendations.length}\n"
                       "Previous: ${actualRecommendations.reversed.skip(1).take(2).join(', ')}${actualRecommendations.length > 3 ? '...' : ''}";
        }
        
        final responseText = "🎢 Perfect! Based on your last ride ($lastRide) in $currentPark, I recommend:\n\n"
               "**${recommendation.rideName}**\n"
               "⏱️ Wait time: ${recommendation.waitTime} minutes\n"
               "🚶 Walking time: ~${recommendation.walkingMinutes} minute${recommendation.walkingMinutes == 1 ? '' : 's'}\n\n"
               "This looks like a great choice right now! Have fun! 🎉$sessionInfo";
        
        // Add the recommendation message with direction data
        setState(() {
          _messages.add(ChatMessage(
            text: responseText,
            isBot: true,
            timestamp: DateTime.now(),
            fromRide: lastRide,
            toRide: recommendation.rideName,
            recommendedRideName: recommendation.rideName,
          ));
          _isLoading = false;
        });
        
        return ""; // Return empty since we're handling the message creation manually
      } else {
        return "I'm having trouble getting current wait times for $currentPark, or we might have covered most of the available rides! Would you like me to suggest some popular attractions instead? 🎢";
      }
    } else if (message.contains('visited') || message.contains('history') || message.contains('done') || message.contains('went on')) {
      final visitedRides = locationService.visitedRides;
      final lastRide = locationService.lastVisitedRide;
      
      if (visitedRides.isEmpty && _recommendedRides.isEmpty) {
        return "🎢 You haven't visited any rides yet today! Ready to start your adventure? Just ask me for a ride recommendation! 🎉";
      }
      
      String response = "📋 **Your Universal Orlando Activity Today:**\n\n";
      
      if (lastRide != null && _recommendedRides.contains(lastRide)) {
        response += "🎯 **Starting Point:** $lastRide\n\n";
      }
      
      if (_recommendedRides.isNotEmpty) {
        // Filter out the starting ride from recommendations display
        List<String> actualRecommendations = _recommendedRides.where((ride) => ride != lastRide).toList();
        if (actualRecommendations.isNotEmpty) {
          response += "🎯 **Rides I've recommended** (${actualRecommendations.length}):\n";
          for (int i = 0; i < actualRecommendations.length; i++) {
            response += "${i + 1}. ${actualRecommendations[i]}\n";
          }
        }
      }
      
      if (visitedRides.isNotEmpty) {
        response += "\n🏁 **Rides you've actually visited** (${visitedRides.length}):\n";
        for (int i = 0; i < visitedRides.length; i++) {
          response += "${i + 1}. ${visitedRides[i]}\n";
        }
      }
      
      response += "\nWhat would you like to do next? 🎢";
      return response;
    } else if (message.contains('reset') || message.contains('clear') || message.contains('start over')) {
      _recommendedRides.clear();
      _conversationHistory.clear();
      locationService.clearHistory();
      return "🔄 **Fresh Start!** I've cleared your session history.\n\n"
             "Ready to begin a new adventure? Ask me for a ride recommendation! 🎢✨";
    } else if (message.contains('food') || message.contains('eat') || message.contains('restaurant')) {
      String parkContext = locationService.currentPark ?? "the park";
      return "🍕 Great question! Looking for food in $parkContext? Here are some popular dining options overall:\n\n"
             "🏰 **Three Broomsticks** (Islands of Adventure)\n"
             "🍔 **Krusty Burger** (Universal Studios)\n"
             "🌮 **Leaky Cauldron** (Universal Studios)\n\n"
             "I can give walking directions if you'd like!";
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
      return "Hello! 👋 I'm excited to help you make the most of your Universal Orlando visit!\n\n"
             "I can help you with:\n"
             "🎢 Ride recommendations\n"
             "🍕 Food suggestions\n"
             "🛍️ Shopping locations\n"
             "⏰ Wait time info\n\n"
             "What sounds most interesting to you?";
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
                  const Icon(Icons.smart_toy, color: Colors.white, size: 24),
                  const SizedBox(width: 8),
                  const Expanded(
                    child: Text(
                      'Universal Assistant',
                      style: TextStyle(
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
                  return _buildMessage(_messages[index]);
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
  }

  Widget _buildMessage(ChatMessage message) {
    return Align(
      alignment: message.isBot ? Alignment.centerLeft : Alignment.centerRight,
      child: Column(
        crossAxisAlignment: message.isBot ? CrossAxisAlignment.start : CrossAxisAlignment.end,
        children: [
          Container(
            margin: const EdgeInsets.only(bottom: 12),
            padding: const EdgeInsets.all(12),
            constraints: BoxConstraints(
              maxWidth: MediaQuery.of(context).size.width * 0.75,
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
          // Add directions button for recommendation messages
          if (message.isBot && 
              message.fromRide != null && 
              message.toRide != null &&
              widget.onDirectionsRequested != null)
            Container(
              margin: const EdgeInsets.only(bottom: 12, left: 12),
              child: ElevatedButton.icon(
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

  @override
  void dispose() {
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