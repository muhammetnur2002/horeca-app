import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:horeca_app/app/design/tokens.dart';

/// Панель «матового стекла»: карточка, плитка, строка списка.
///
/// Раньше такой вид собирался вручную на каждом экране связкой
/// `ClipRRect` + `BackdropFilter(ImageFilter.blur)` + `Container`.
/// Размытие фона — самая дорогая операция для видеоядра телефона: оно
/// заставляет заново прочитать уже нарисованный кадр. В приложении таких
/// мест набралось 39, и девять из них стояли внутри списков, то есть
/// повторялись на каждом элементе. Отсюда и подтормаживание прокрутки.
///
/// Вид сохранён полупрозрачной заливкой поверх фона и светлой границей.
/// Отличие от настоящего размытия заметно только на пёстрой подложке,
/// а стоит оно почти ничего.
///
/// Если размытие всё же нужно — например, у неподвижной шапки экрана,
/// которая одна на весь кадр, — используйте [blurred]: там оно уместно.
class GlassSurface extends StatelessWidget {
  const GlassSurface({
    super.key,
    required this.child,
    this.padding = const EdgeInsets.all(AppSpacing.lg),
    this.margin,
    this.radius = AppRadii.md,
    this.onTap,
    this.selected = false,
    this.blurred = false,
    this.tint,
  });

  final Widget child;
  final EdgeInsetsGeometry padding;
  final EdgeInsetsGeometry? margin;
  final double radius;

  /// Если задан, панель становится нажимаемой — с эффектом нажатия
  /// и правильной областью касания.
  final VoidCallback? onTap;

  /// Выделенное состояние: более заметная граница и лёгкая подсветка.
  final bool selected;

  /// Настоящее размытие фона. Допустимо только для одиночных элементов,
  /// которых на экране один-два. Внутри списка использовать нельзя.
  final bool blurred;

  /// Своя подложка вместо стандартной — например, для плашки состояния.
  final Color? tint;

  @override
  Widget build(BuildContext context) {
    final palette = context.palette;
    final borderRadius = BorderRadius.circular(radius);

    final decoration = BoxDecoration(
      borderRadius: borderRadius,
      color: tint ??
          (selected
              ? palette.action.withValues(alpha: 0.10)
              : palette.surface.withValues(alpha: 0.75)),
      border: Border.all(
        color: selected ? palette.action : palette.border,
        width: selected ? 1.5 : 1,
      ),
    );

    Widget content = Container(
      padding: padding,
      decoration: decoration,
      child: child,
    );

    if (blurred) {
      content = ClipRRect(
        borderRadius: borderRadius,
        child: BackdropFilter(
          filter: ImageFilter.blur(sigmaX: 10, sigmaY: 10),
          child: content,
        ),
      );
    }

    if (onTap != null) {
      content = Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: onTap,
          borderRadius: borderRadius,
          child: content,
        ),
      );
    }

    return margin == null ? content : Padding(padding: margin!, child: content);
  }
}
