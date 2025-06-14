import 'package:flutter_boilerplate/data/model/response/language_model.dart';
import 'package:flutter_boilerplate/util/images.dart';

class AppConstants {
  static const String appName = 'BazarTrack';

  static const String baseUrl = 'https://bazartrack.dev.alpha.net.bd';

  // Shared Key
  static const String theme = 'theme';
  static const String token = 'token';
  static const String countryCode = 'country_code';
  static const String languageCode = 'language_code';
  static const String cartList = 'cart_list';
  static const String userPassword = 'user_password';
  static const String userAddress = 'user_address';
  static const String userNumber = 'user_number';
  static const String searchAddress = 'search_address';
  static const String topic = 'notify';
  static const String userData = 'user_data';

  static List<LanguageModel> languages = [
    LanguageModel(imageUrl: Images.unitedKingdom, languageName: 'English', countryCode: 'US', languageCode: 'en'),
    LanguageModel(imageUrl: Images.unitedKingdom, languageName: 'Bengali', countryCode: 'BD', languageCode: 'bn'),
  ];
}
