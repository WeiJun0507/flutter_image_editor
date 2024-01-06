import 'package:flutter/material.dart';
import 'package:image_editor/flutter_image_editor.dart';

class ImageEditorDelegateImpl extends ImageEditorDelegate {
  @override
  List<Color> get brushColors => const <Color>[
        Color(0xFFFA4D32),
        Color(0xFFFF7F1E),
        Color(0xFF2DA24A),
        Color(0xFFF2F2F2),
        Color(0xFF222222),
        Color(0xFF1F8BE5),
        Color(0xFF4E43DB),
      ];

  @override
  List<Color> get textColors => const <Color>[
        Color(0xFFFA4D32),
        Color(0xFFFF7F1E),
        Color(0xFF2DA24A),
        Color(0xFFF2F2F2),
        Color(0xFF222222),
        Color(0xFF1F8BE5),
        Color(0xFF4E43DB),
      ];

  Color operatorStatuscolor(bool choosen) =>
      choosen ? Colors.red : Colors.white;

  @override
  TextConfigModel get textConfigModel => DefaultTextConfigModel();

  @override
  SliderThemeData sliderThemeData(BuildContext context) =>
      SliderTheme.of(context).copyWith(
        trackHeight: 2,
        thumbColor: Colors.white,
        disabledThumbColor: Colors.white,
        activeTrackColor: const Color(0xFFF83112),
        inactiveTrackColor: Colors.white.withOpacity(0.5),
        overlayShape: CustomRoundSliderOverlayShape(),
      );

  @override
  Widget appBarDelegate(
      BuildContext context, EditorPanelController controller) {
    return const SizedBox();
  }

  @override
  Widget toolDelegate(BuildContext context, EditorPanelController controller) {
    return Row(
      children: <Widget>[
        Expanded(
          child: SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            child: ValueListenableBuilder<OperateType>(
                valueListenable: controller.operateType,
                builder: (context, OperateType type, Widget? child) {
                  return Row(
                    children: <Widget>[
                      _buildButton(
                        OperateType.drawing,
                        'Painter',
                        type == OperateType.drawing,
                        // onPressed: () => onDrawingTap(
                        //   context,
                        //   controller,
                        // ),
                      ),
                      _buildButton(
                          OperateType.text, 'Text', type == OperateType.text,
                          onPressed: () => onTextTap(context, controller)),
                      _buildButton(
                        OperateType.metrics,
                        'Metrics',
                        type == OperateType.text,
                        onPressed: () => onMetricsTap(context, controller),
                      ),
                    ],
                  );
                }),
          ),
        ),
        doneButton(context, controller),
      ],
    );
  }

  Widget _buildButton(
    OperateType type,
    String txt,
    bool choosen, {
    VoidCallback? onPressed,
  }) {
    return GestureDetector(
      onTap: onPressed,
      child: SizedBox(
        width: 44,
        height: 41,
        child: Column(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            getOperateTypeRes(type, 30, choosen: choosen),
            Text(
              txt,
              style: TextStyle(
                  color: choosen
                      ? const Color(0xFFFA4D32)
                      : const Color(0xFF999999),
                  fontSize: 11),
            )
          ],
        ),
      ),
    );
  }

  Widget getOperateTypeRes(OperateType type, double size,
      {bool choosen = false}) {
    return switch (type) {
      OperateType.drawing => Icon(
          Icons.brush_outlined,
          size: size,
          color: operatorStatuscolor(choosen),
        ),
      OperateType.text =>
        Icon(Icons.notes, size: size, color: operatorStatuscolor(choosen)),
      OperateType.metrics => Icon(
          Icons.rotate_90_degrees_ccw_outlined,
          size: size,
          color: operatorStatuscolor(choosen),
        ),
      _ => const SizedBox(),
    };
  }

  void onTextTap(
    BuildContext context,
    EditorPanelController controller,
  ) {
    controller.switchOperateType(OperateType.text);
  }

  void onMetricsTap(
    BuildContext context,
    EditorPanelController controller,
  ) {
    controller.switchOperateType(OperateType.metrics);
  }

  Widget doneButton(BuildContext context, EditorPanelController controller) {
    return Container(
      alignment: Alignment.center,
      decoration: BoxDecoration(
          borderRadius: BorderRadius.all(Radius.circular(6)),
          gradient:
              const LinearGradient(colors: [Colors.green, Colors.greenAccent])),
      child: Text(
        'Done',
        style: TextStyle(fontSize: 15, color: Colors.white),
      ),
    );
  }
}
