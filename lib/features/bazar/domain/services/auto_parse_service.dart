import '../entities/bazar_entities.dart';

class AutoParseService {
  const AutoParseService();

  static final RegExp _quantityWithUnitPattern = RegExp(
    r'(^|\s)([০-৯0-9]+(?:[\.,][০-৯0-9]+)?)(\s*)(কেজি|কেজি\.|kg|গ্রাম|gm|লিটার|লিটার\.|ltr|প্যাকেট|টা|টি|ডজন|হালি|পিস|pcs)(?=\s|$)',
    caseSensitive: false,
  );

  List<CreateBazarItemInput> parseLines(String rawText) {
    return rawText
        .split(RegExp(r'\r?\n'))
        .map(parseLine)
        .whereType<CreateBazarItemInput>()
        .toList(growable: false);
  }

  CreateBazarItemInput? parseLine(String rawLine) {
    final line = rawLine.trim().replaceAll(RegExp(r'\s+'), ' ');
    if (line.isEmpty) return null;

    final match = _quantityWithUnitPattern.firstMatch(line);
    if (match == null) {
      final tokens = line.split(' ');
      return CreateBazarItemInput(
        name: tokens.first,
        rawText: line,
        attributes: tokens.length > 1 ? tokens.skip(1).join(' ') : null,
      );
    }

    final quantityText = match.group(2)!;
    final unit = _normalizeUnit(match.group(4)!);
    final name = line.substring(0, match.start).trim();
    final attributes = line.substring(match.end).trimLeft();

    return CreateBazarItemInput(
      name: name.isEmpty ? line.split(' ').first : name,
      rawText: line,
      quantity: _parseBanglaNumber(quantityText),
      unit: unit,
      attributes: attributes.isEmpty ? null : attributes,
    );
  }

  double? _parseBanglaNumber(String value) {
    final normalized = value
        .replaceAll('০', '0')
        .replaceAll('১', '1')
        .replaceAll('২', '2')
        .replaceAll('৩', '3')
        .replaceAll('৪', '4')
        .replaceAll('৫', '5')
        .replaceAll('৬', '6')
        .replaceAll('৭', '7')
        .replaceAll('৮', '8')
        .replaceAll('৯', '9')
        .replaceAll(',', '.');
    return double.tryParse(normalized);
  }

  String _normalizeUnit(String value) {
    final unit = value.toLowerCase().replaceAll('.', '');
    switch (unit) {
      case 'kg':
        return 'কেজি';
      case 'gm':
        return 'গ্রাম';
      case 'ltr':
        return 'লিটার';
      case 'টি':
        return 'টা';
      case 'pcs':
        return 'পিস';
      default:
        return value.replaceAll('.', '');
    }
  }
}
