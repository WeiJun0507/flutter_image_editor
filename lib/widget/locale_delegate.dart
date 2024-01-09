List<LocaleDelegate> localeDelegates = [
  LocaleDelegate(),
  ChineseLocaleDelegate(),
];

class LocaleDelegate {
  String get languageCode => 'en';

  String get drawing => 'drawing';

  String get text => 'text';

  String get done => 'Done';

  String get cancel => 'Cancel';

  String get small => 'Small';

  String get big => 'Big';

  String get bold => 'Bold';
}

class ChineseLocaleDelegate extends LocaleDelegate {
  @override
  String get languageCode => 'zh';

  @override
  String get drawing => '绘图';

  @override
  String get text => '文字';

  @override
  String get done => '完成';

  @override
  String get cancel => '取消';

  @override
  String get small => '小';

  @override
  String get big => '大';

  @override
  String get bold => '粗体';
}