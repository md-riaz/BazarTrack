import 'package:bazar_track/data/model/response/language_model.dart';
import 'package:bazar_track/util/app_constants.dart';

class LanguageRepo {
  List<LanguageModel> getAllLanguages() {
    return AppConstants.languages;
  }
}
