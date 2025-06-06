import 'package:get/get.dart';
import '../model/template_item.dart';
import '../repository/template_repo.dart';

class TemplateController extends GetxController {
  final TemplateRepo templateRepo;
  TemplateController({required this.templateRepo});

  final List<TemplateItem> _items = [];
  List<TemplateItem> get items => _items;

  @override
  void onInit() {
    _items.addAll(templateRepo.getItems());
    super.onInit();
  }

  Future<void> addItem(String name) async {
    final item = TemplateItem(
      id: DateTime.now().millisecondsSinceEpoch.toString(),
      name: name,
    );
    _items.add(item);
    await templateRepo.saveItems(_items);
    update();
  }
}
