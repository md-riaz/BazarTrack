import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'controller/template_controller.dart';

class TemplateScreen extends StatelessWidget {
  TemplateScreen({super.key});

  final TextEditingController _textController = TextEditingController();

  @override
  Widget build(BuildContext context) {
    return GetBuilder<TemplateController>(builder: (controller) {
      return Scaffold(
        appBar: AppBar(title: Text('template_feature'.tr)),
        body: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            children: [
              Row(
                children: [
                  Expanded(
                    child: TextField(
                      controller: _textController,
                      decoration: InputDecoration(
                        hintText: 'Enter item name',
                      ),
                    ),
                  ),
                  const SizedBox(width: 8),
                  ElevatedButton(
                    onPressed: () {
                      final text = _textController.text.trim();
                      if (text.isNotEmpty) {
                        controller.addItem(text);
                        _textController.clear();
                      }
                    },
                    child: const Text('Add'),
                  )
                ],
              ),
              const SizedBox(height: 16),
              Expanded(
                child: ListView.builder(
                  itemCount: controller.items.length,
                  itemBuilder: (_, index) {
                    final item = controller.items[index];
                    return ListTile(title: Text(item.name));
                  },
                ),
              )
            ],
          ),
        ),
      );
    });
  }
}
