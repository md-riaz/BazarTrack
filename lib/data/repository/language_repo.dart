import 'package:BazarTrack/data/model/response/language_model.dart';
import 'package:BazarTrack/util/app_constants.dart';

class LanguageRepo {
  List<LanguageModel> getAllLanguages() {
    return AppConstants.languages;
  }
}
