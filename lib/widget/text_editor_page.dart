import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:image_editor/widget/locale_delegate.dart';
import '../flutter_image_editor.dart';

///A page for input some text to canvas.
class TextEditorPage extends StatefulWidget {
  final FloatTextModel? model;
  final LocaleDelegate localeDelegate;

  const TextEditorPage({
    super.key,
    this.model,
    required this.localeDelegate,
  });

  @override
  State<StatefulWidget> createState() {
    return TextEditorPageState();
  }
}

class TextEditorPageState extends State<TextEditorPage>
    with LittleWidgetBinding, WindowUiBinding {
  static TextConfigModel get configModel =>
      ImageEditor.uiDelegate.textConfigModel;

  final FocusNode _node = FocusNode();

  final GlobalKey filedKey = GlobalKey();

  final TextEditingController _controller = TextEditingController();

  final List<Color> textColorList = ImageEditor.uiDelegate.textColors;

  ///text's color
  late ValueNotifier<int> selectedColor;

  Color get _textColor => Color(selectedColor.value);

  ///text's size
  double _size = configModel.initSize;

  ///text font weight
  FontWeight _fontWeight = FontWeight.normal;

  FloatTextModel buildModel() {
    RenderObject? ro = filedKey.currentContext?.findRenderObject();
    Offset offset = Offset(100, 200);
    Size? textSize;
    if (ro is RenderBox) {
      //adjust text's dy value
      offset = ro
          .localToGlobal(Offset.zero)
          .translate(0, -(44 + windowStatusBarHeight));
      textSize = ro.size;
    }
    return FloatTextModel(
      text: _controller.text,
      top: widget.model != null ? widget.model!.top : offset.dy,
      left: widget.model != null ? widget.model!.left : offset.dx,
      size: textSize,
      style: TextStyle(
        fontSize: _size,
        color: _textColor,
        fontWeight: _fontWeight,
      ),
    );
  }

  void popWithResult() {
    if (widget.model != null) {
      widget.model!.text = _controller.text;
      widget.model!.style = TextStyle(
        fontSize: _size,
        color: _textColor,
        fontWeight: _fontWeight,
      );

      Navigator.pop(context, {
        'isEdit': true,
        'result': widget.model,
      });

      return;
    }

    Navigator.pop(context, {
      'isEdit': false,
      'result': buildModel(),
    });
  }

  void tapBoldBtn() {
    _fontWeight =
        _fontWeight == FontWeight.bold ? FontWeight.normal : FontWeight.bold;
    setState(() {});
  }

  @override
  void initState() {
    super.initState();
    assert(
        configModel.isLegal,
        "TextConfigModel config size is not legal : "
        "initSize must middle in up and bottom limit");
    selectedColor = ValueNotifier(textColorList.first.value);
    if (widget.model != null) {
      _controller.text = widget.model!.text;
      selectedColor = ValueNotifier<int>(
          widget.model!.style?.color?.value ?? textColorList.first.value);
      _size = widget.model!.style?.fontSize ?? configModel.initSize;
      _fontWeight = widget.model!.style?.fontWeight ?? FontWeight.normal;
    }

    Future.delayed(const Duration(milliseconds: 160), () {
      if (mounted) _node.requestFocus();
    });
  }

  @override
  void dispose() {
    _node.dispose();
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: () {
        if (!_node.hasFocus) _node.requestFocus();
      },
      child: Material(
        color: Colors.transparent,
        child: Stack(
          children: [
            ClipRect(
              child: BackdropFilter(
                filter: ImageFilter.blur(sigmaX: 10, sigmaY: 10),
                child: Container(
                  width: double.infinity,
                  height: double.infinity,
                  color: Colors.black38,
                ),
              ),
            ),
            Scaffold(
              backgroundColor: Colors.transparent,
              resizeToAvoidBottomInset: true,
              appBar: AppBar(
                backgroundColor: Colors.transparent,
                leading: GestureDetector(
                  onTap: () {
                    Navigator.pop(context);
                  },
                  child: Container(
                    height: 44,
                    alignment: Alignment.center,
                    padding: EdgeInsets.only(top: 12, bottom: 12),
                    child: Text(
                      widget.localeDelegate.cancel,
                      style: TextStyle(color: Colors.white, fontSize: 16),
                    ),
                  ),
                ),
                actions: [
                  Padding(
                    padding: EdgeInsets.only(top: 12, bottom: 12, right: 16),
                    child: GestureDetector(
                      onTap: popWithResult,
                      child: Text(
                        widget.localeDelegate.done,
                        style: TextStyle(
                          fontSize: 16,
                          color: Colors.white,
                        ),
                      ),
                    ),
                  ),
                ],
              ),
              body: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Expanded(child: SizedBox()),
                  //text area
                  Container(
                    width: screenWidth,
                    padding: EdgeInsets.symmetric(horizontal: 20),
                    child: TextField(
                      key: filedKey,
                      maxLines: 50,
                      minLines: 1,
                      controller: _controller,
                      focusNode: _node,
                      cursorColor: configModel.cursorColor,
                      style: TextStyle(
                          color: _textColor,
                          fontSize: _size,
                          fontWeight: _fontWeight),
                      decoration: InputDecoration(
                          isCollapsed: true, border: InputBorder.none),
                    ),
                  ),
                  Expanded(child: SizedBox()),
                  //slider
                  Container(
                    height: 36,
                    padding: EdgeInsets.symmetric(horizontal: 20),
                    width: double.infinity,
                    //color: Colors.white,
                    child: Row(
                      children: [
                        GestureDetector(
                          onTap: tapBoldBtn,
                          child: Text(
                            realState?.panelController.localeDelegate.bold ??
                                'Bold',
                            style: TextStyle(
                              fontSize: 16,
                              color: Colors.white,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ),
                        24.hGap,
                        Text(
                          realState?.panelController.localeDelegate.small ??
                              'Small',
                          style: TextStyle(
                              color: Colors.white.withOpacity(0.5),
                              fontSize: 13),
                        ),
                        8.hGap,
                        Expanded(child: _buildSlider()),
                        8.hGap,
                        Text(
                          realState?.panelController.localeDelegate.big ??
                              'Big',
                          style: TextStyle(
                              color: Colors.white.withOpacity(0.5),
                              fontSize: 13),
                        ),
                        2.hGap,
                      ],
                    ),
                  ),
                  //color selector
                  Container(
                    height: 41,
                    padding: EdgeInsets.symmetric(horizontal: 20),
                    width: double.infinity,
                    //color: Colors.white,
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceAround,
                      children: textColorList
                          .map<Widget>((e) => ColorPicker(
                                color: e,
                                valueListenable: selectedColor,
                                onColorSelected: (color) {
                                  setState(() {
                                    selectedColor.value = color.value;
                                  });
                                },
                              ))
                          .toList(),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSlider() {
    return SliderTheme(
        data: ImageEditor.uiDelegate.sliderThemeData(context),
        child: Slider(
          value: _size,
          max: configModel.sliderUpLimit,
          min: configModel.sliderBottomLimit,
          onChanged: (v) {
            _size = v;
            setState(() {});
          },
        ));
  }
}
