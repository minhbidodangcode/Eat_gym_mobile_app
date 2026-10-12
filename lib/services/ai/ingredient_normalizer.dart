class IngredientNormalizer {
  static final Map<String, String> _mapping = {
    "yellow onion": "onion",
    "red onion": "onion",
    "white onion": "onion",
    "chicken breast": "chicken",
    "chicken": "chicken",
    "oyster mushroom": "mushroom",
    "button mushroom": "mushroom",
    "tomato": "tomato",
    "carrot": "carrot",
    "potato": "potato",
    "garlic": "garlic",
    "egg": "egg",
    "beef": "beef",
    "pork": "pork",
    "steak": "beef",
    "fresh meat": "beef",
    "leafy greens": "lettuce",
    "chicken duck": "chicken",
    "rice": "rice",
    "broccoli": "broccoli",
    "cucumber": "cucumber",
  };

  static String normalize(String ingredient) {
    final normalized = ingredient.toLowerCase().trim();
    return _mapping[normalized] ?? normalized;
  }
}
