import 'package:bazar/features/bazar/domain/services/auto_parse_service.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  const service = AutoParseService();

  test('parses Bangla quantity and normalizes unit', () {
    final item = service.parseLine('আলু ২.৫ কেজি দেশি');

    expect(item, isNotNull);
    expect(item!.name, 'আলু');
    expect(item.quantity, 2.5);
    expect(item.unit, 'কেজি');
    expect(item.attributes, 'দেশি');
    expect(item.rawText, 'আলু ২.৫ কেজি দেশি');
  });

  test('parses ascii shorthand units into Bangla labels', () {
    final item = service.parseLine('চিনি 1 kg');

    expect(item, isNotNull);
    expect(item!.name, 'চিনি');
    expect(item.quantity, 1);
    expect(item.unit, 'কেজি');
  });

  test('parses multiple non-empty lines', () {
    final items = service.parseLines('ডিম ১২টা\n\nদুধ ২ প্যাকেট');

    expect(items, hasLength(2));
    expect(items.first.name, 'ডিম');
    expect(items.last.name, 'দুধ');
  });
}
