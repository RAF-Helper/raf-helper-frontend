import 'package:flutter/material.dart';
import 'package:flutter_math_fork/flutter_math.dart';
import 'package:gpt_markdown/gpt_markdown.dart';
import 'package:gpt_markdown/custom_widgets/markdown_config.dart';

/// Базовый размер текста в markdown-ответах ассистента.
const double _kMdFontSize = 15;

/// Размер текста в пунктах списков.
const double _kListFontSize = 13;

/// Размер текста в ячейках таблиц.
const double _kTableFontSize = 13;

/// Стиль markdown-заголовка (#, ##, ###…) заданного размера.
TextStyle _heading(double size) => TextStyle(
      fontSize: size,
      fontWeight: FontWeight.bold,
      color: Colors.white,
    );

/// Тема markdown с аккуратной иерархией заголовков. Считается один раз, чтобы
/// не пересоздавать её (вместе с ThemeData.dark внутри) на каждый build пузыря.
final GptMarkdownThemeData _mdTheme = GptMarkdownThemeData(
  brightness: Brightness.dark,
  h1: _heading(18),
  h2: _heading(17),
  h3: _heading(16),
  h4: _heading(15),
  h5: _heading(15),
  h6: _heading(15),
);

/// Маркированный список с уменьшенным размером текста пунктов: переиспользуем
/// стандартный [UnOrderedList], лишь подменив размер шрифта в конфиге.
class _SmallUnorderedList extends UnOrderedList {
  @override
  Widget build(
    BuildContext context,
    String text,
    GptMarkdownConfig config,
  ) {
    final smallConfig = config.copyWith(
      style: (config.style ?? const TextStyle())
          .copyWith(fontSize: _kListFontSize),
    );
    return super.build(context, text, smallConfig);
  }
}

/// Таблица с уменьшенным размером текста ячеек: переиспользуем всю логику
/// стандартного [TableMd], лишь подменив размер шрифта в конфиге.
class _SmallTable extends TableMd {
  @override
  Widget build(
    BuildContext context,
    String text,
    GptMarkdownConfig config,
  ) {
    final smallConfig = config.copyWith(
      style: (config.style ?? const TextStyle())
          .copyWith(fontSize: _kTableFontSize),
    );
    return super.build(context, text, smallConfig);
  }
}

/// Рендер формул: блочные (`$$...$$`) оборачиваем в горизонтальный скролл,
/// чтобы длинную формулу можно было прокрутить, а не обрезать. Инлайн-формулы
/// (`$...$`) остаются в строке текста.
Widget _latexBuilder(
  BuildContext context,
  String tex,
  TextStyle textStyle,
  bool inline,
) {
  final math = Math.tex(
    tex,
    textStyle: textStyle,
    mathStyle: inline ? MathStyle.text : MathStyle.display,
    onErrorFallback: (err) => Text(tex, style: textStyle),
  );
  if (inline) return math;
  return SingleChildScrollView(
    scrollDirection: Axis.horizontal,
    child: math,
  );
}

final List<MarkdownComponent> _components = MarkdownComponent.globalComponents
    .map((c) => switch (c) {
          UnOrderedList() => _SmallUnorderedList(),
          TableMd() => _SmallTable(),
          _ => c,
        })
    .toList();

class ChatBubble extends StatelessWidget {
  final String message;
  final bool isUser;
  final bool isLoading;

  const ChatBubble({
    super.key,
    required this.message,
    required this.isUser,
    this.isLoading = false,
  });

  @override
  Widget build(BuildContext context) {
    return Align(
      alignment: isUser ? Alignment.centerRight : Alignment.centerLeft,
      child: Container(
        margin: const EdgeInsets.symmetric(vertical: 4),
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        constraints: BoxConstraints(
          maxWidth: MediaQuery.of(context).size.width * 0.75,
        ),
        decoration: BoxDecoration(
          color: isUser ? const Color(0xFF0A84FF) : const Color(0xFF2C2C2E),
          borderRadius: BorderRadius.circular(20),
        ),
        child: isLoading
            ? Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  _buildDot(0),
                  const SizedBox(width: 4),
                  _buildDot(1),
                  const SizedBox(width: 4),
                  _buildDot(2),
                ],
              )
            : SelectionArea(
                child: isUser
                    ? Text(
                        message,
                        style: const TextStyle(
                          fontSize: 15,
                          color: Colors.white,
                        ),
                      )
                    : GptMarkdownTheme(
                        gptThemeData: _mdTheme,
                        child: GptMarkdown(
                          message,
                          components: _components,
                          latexBuilder: _latexBuilder,
                          useDollarSignsForLatex: true,
                          style: const TextStyle(
                            fontSize: _kMdFontSize,
                            color: Colors.white,
                          ),
                        ),
                      ),
              ),
      ),
    );
  }

  Widget _buildDot(int index) {
    return TweenAnimationBuilder<double>(
      tween: Tween(begin: 0.0, end: 1.0),
      duration: const Duration(milliseconds: 600),
      builder: (context, value, child) {
        return Opacity(
          opacity: (value + index * 0.3) % 1.0,
          child: Container(
            width: 8,
            height: 8,
            decoration: const BoxDecoration(
              color: Colors.white54,
              shape: BoxShape.circle,
            ),
          ),
        );
      },
    );
  }
}
