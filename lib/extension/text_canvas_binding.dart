import 'package:flutter/material.dart';
import '../flutter_image_editor.dart';

///text painting
mixin TextCanvasBinding<T extends StatefulWidget> on State<T> {
  late StateSetter textSetter;

  void addText(FloatTextModel model) {
    PaintOperation value = PaintOperation(
      type: OperationType.text,
      data: model,
    );
    realState?.panelController.operationHistory.add(value);
    if (mounted) setState(() {});
  }

  ///delete a text from canvas
  void deleteTextWidget(FloatTextModel target) {
    int index = realState?.panelController.operationHistory
            .indexWhere((element) => element.data == target) ??
        -1;
    if (index != -1) {
      realState?.panelController.operationHistory.removeAt(index);
    }

    if (mounted) setState(() {});
  }

  void toTextEditorPage({FloatTextModel? model}) {
    Navigator.of(context)
        .push(PageRouteBuilder(
            opaque: false,
            pageBuilder: (BuildContext context, Animation<double> animation,
                Animation<double> secondaryAnimation) {
              return TextEditorPage(model: model);
            }))
        .then((value) {
      realState?.panelController.cancelOperateType();
      if (value is Map) {
        if (value['isEdit']) {
          model = value['result'];
          if (mounted) setState(() {});
        } else if (value['result'] is FloatTextModel) {
          addText(value['result']);
        }
      }
    });
  }

  Widget buildTextComponent(dynamic model) {
    if (model is! FloatTextModel) return const SizedBox();

    return Positioned(
      left: model.left,
      top: model.top,
      child: Container(
        width: model.size?.width,
        height: model.size?.height,
        child: GestureDetector(
          onTap: () => toTextEditorPage(model: model),
        ),
      ),
    );
  }
}
