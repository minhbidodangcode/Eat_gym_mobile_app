import 'voice_ingredient_result.dart';

enum ChatMessageType {
  text,
  ingredientsAction,
  recipeSuggestions,
  inventorySummary,
  mealPlanProposal,
  interactiveQuestionnaire,
}

class ChatMessage {
  final String id;
  final String text;
  final bool isUser;
  final DateTime timestamp;
  final ChatMessageType type;
  final List<VoiceIngredientResult>? ingredients;
  final List<Map<String, dynamic>>? recipes;
  final List<Map<String, dynamic>>? inventoryItems;
  final Map<String, dynamic>? mealPlanData;
  final Map<String, dynamic>? questionnaireData;
  bool isActionDone;

  ChatMessage({
    required this.id,
    required this.text,
    required this.isUser,
    required this.timestamp,
    this.type = ChatMessageType.text,
    this.ingredients,
    this.recipes,
    this.inventoryItems,
    this.mealPlanData,
    this.questionnaireData,
    this.isActionDone = false,
  });

  factory ChatMessage.user(String text) {
    return ChatMessage(
      id: DateTime.now().microsecondsSinceEpoch.toString(),
      text: text,
      isUser: true,
      timestamp: DateTime.now(),
      type: ChatMessageType.text,
    );
  }

  factory ChatMessage.botText(String text) {
    return ChatMessage(
      id: DateTime.now().microsecondsSinceEpoch.toString(),
      text: text,
      isUser: false,
      timestamp: DateTime.now(),
      type: ChatMessageType.text,
    );
  }

  factory ChatMessage.botIngredients({
    required String text,
    required List<VoiceIngredientResult> ingredients,
  }) {
    return ChatMessage(
      id: DateTime.now().microsecondsSinceEpoch.toString(),
      text: text,
      isUser: false,
      timestamp: DateTime.now(),
      type: ChatMessageType.ingredientsAction,
      ingredients: ingredients,
    );
  }

  factory ChatMessage.botRecipes({
    required String text,
    required List<Map<String, dynamic>> recipes,
  }) {
    return ChatMessage(
      id: DateTime.now().microsecondsSinceEpoch.toString(),
      text: text,
      isUser: false,
      timestamp: DateTime.now(),
      type: ChatMessageType.recipeSuggestions,
      recipes: recipes,
    );
  }

  factory ChatMessage.botInventory({
    required String text,
    required List<Map<String, dynamic>> inventoryItems,
  }) {
    return ChatMessage(
      id: DateTime.now().microsecondsSinceEpoch.toString(),
      text: text,
      isUser: false,
      timestamp: DateTime.now(),
      type: ChatMessageType.inventorySummary,
      inventoryItems: inventoryItems,
    );
  }

  factory ChatMessage.botMealPlan({
    required String text,
    required Map<String, dynamic> mealPlanData,
  }) {
    return ChatMessage(
      id: DateTime.now().microsecondsSinceEpoch.toString(),
      text: text,
      isUser: false,
      timestamp: DateTime.now(),
      type: ChatMessageType.mealPlanProposal,
      mealPlanData: mealPlanData,
    );
  }
}
