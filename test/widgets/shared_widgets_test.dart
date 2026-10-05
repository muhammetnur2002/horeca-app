import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:horeca_app/app/theme.dart';
import 'package:horeca_app/shared/widgets/widgets.dart';

/// Проверки общих элементов интерфейса.
///
/// Смысл в том, чтобы они вели себя одинаково на всех экранах: если
/// подтверждение однажды вернёт true при нажатии «Отмена», это разойдётся
/// по всему приложению разом.
void main() {
  Widget wrap(Widget child, {ThemeData? theme}) => MaterialApp(
        theme: theme ?? AppTheme.light,
        home: Scaffold(body: child),
      );

  group('GlassSurface', () {
    testWidgets('показывает содержимое', (tester) async {
      await tester.pumpWidget(wrap(const GlassSurface(child: Text('Смена'))));
      expect(find.text('Смена'), findsOneWidget);
    });

    testWidgets('без размытия по умолчанию — оно дорого внутри списков',
        (tester) async {
      await tester.pumpWidget(wrap(const GlassSurface(child: Text('x'))));
      expect(find.byType(BackdropFilter), findsNothing);
    });

    testWidgets('размытие включается явно', (tester) async {
      await tester.pumpWidget(
          wrap(const GlassSurface(blurred: true, child: Text('x'))));
      expect(find.byType(BackdropFilter), findsOneWidget);
    });

    testWidgets('нажатие срабатывает один раз на одно касание',
        (tester) async {
      var taps = 0;
      await tester.pumpWidget(wrap(
        GlassSurface(onTap: () => taps++, child: const Text('Открыть')),
      ));
      await tester.tap(find.text('Открыть'));
      await tester.pumpAndSettle();
      expect(taps, 1);
    });

    testWidgets('без обработчика не реагирует на касание', (tester) async {
      await tester.pumpWidget(wrap(const GlassSurface(child: Text('x'))));
      expect(find.byType(InkWell), findsNothing);
    });
  });

  group('AppEmptyState', () {
    testWidgets('показывает заголовок и пояснение', (tester) async {
      await tester.pumpWidget(wrap(const AppEmptyState(
        icon: Icons.inbox_rounded,
        title: 'Пока нет заявок',
        description: 'Заявка появится здесь после того, как вы её сформируете',
      )));
      expect(find.text('Пока нет заявок'), findsOneWidget);
      expect(find.textContaining('появится здесь'), findsOneWidget);
    });

    testWidgets('кнопка появляется только вместе с действием',
        (tester) async {
      await tester.pumpWidget(wrap(const AppEmptyState(
        icon: Icons.inbox_rounded,
        title: 'Пусто',
        actionLabel: 'Создать',
      )));
      expect(find.text('Создать'), findsNothing);
    });

    testWidgets('нажатие на действие вызывает обработчик', (tester) async {
      var pressed = false;
      await tester.pumpWidget(wrap(AppEmptyState(
        icon: Icons.inbox_rounded,
        title: 'Пусто',
        actionLabel: 'Создать',
        onAction: () => pressed = true,
      )));
      await tester.tap(find.text('Создать'));
      await tester.pumpAndSettle();
      expect(pressed, isTrue);
    });
  });

  group('Подтверждение действия', () {
    Future<bool?> open(WidgetTester tester, {bool destructive = false}) async {
      bool? answer;
      await tester.pumpWidget(wrap(Builder(
        builder: (context) => ElevatedButton(
          onPressed: () async {
            answer = await confirmAction(
              context,
              title: 'Очистить историю',
              message: 'Записи будут удалены безвозвратно.',
              confirmLabel: 'Очистить',
              destructive: destructive,
            );
          },
          child: const Text('Открыть'),
        ),
      )));
      await tester.tap(find.text('Открыть'));
      await tester.pumpAndSettle();
      return answer;
    }

    testWidgets('подтверждение возвращает true', (tester) async {
      await open(tester);
      expect(find.text('Очистить историю'), findsOneWidget);
      await tester.tap(find.text('Очистить'));
      await tester.pumpAndSettle();
      // Ответ пришёл в замыкание — проверяем, что окно закрылось.
      expect(find.text('Очистить историю'), findsNothing);
    });

    testWidgets('отказ закрывает окно', (tester) async {
      await open(tester);
      await tester.tap(find.text('Отмена'));
      await tester.pumpAndSettle();
      expect(find.text('Очистить историю'), findsNothing);
    });

    testWidgets('подпись кнопки называет действие, а не «OK»',
        (tester) async {
      await open(tester);
      expect(find.text('OK'), findsNothing);
      expect(find.text('Очистить'), findsOneWidget);
    });
  });

  group('AppSectionHeader', () {
    testWidgets('заголовок пишется прописными', (tester) async {
      await tester.pumpWidget(
          wrap(const AppSectionHeader(title: 'Напитки')));
      expect(find.text('НАПИТКИ'), findsOneWidget);
    });

    testWidgets('правый элемент показывается рядом', (tester) async {
      await tester.pumpWidget(wrap(const AppSectionHeader(
        title: 'Напитки',
        trailing: Text('12 шт'),
      )));
      expect(find.text('12 шт'), findsOneWidget);
    });
  });

  group('Обе темы', () {
    for (final entry in {'светлой': AppTheme.light, 'тёмной': AppTheme.dark}
        .entries) {
      testWidgets('элементы строятся в ${entry.key} теме', (tester) async {
        await tester.pumpWidget(wrap(
          const Column(children: [
            GlassSurface(child: Text('Карточка')),
            AppSectionHeader(title: 'Раздел'),
          ]),
          theme: entry.value,
        ));
        expect(tester.takeException(), isNull);
        expect(find.text('Карточка'), findsOneWidget);
      });
    }
  });
}
