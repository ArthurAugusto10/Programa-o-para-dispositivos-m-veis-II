import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:previsao_tempo/app.dart';

void main() {
  testWidgets('Exibe a tela inicial de pesquisa', (tester) async {
    await tester.pumpWidget(const App());

    expect(find.text('Previsão do Tempo'), findsOneWidget);
    expect(find.text('Como estará o tempo?'), findsOneWidget);
    expect(find.byType(TextField), findsOneWidget);
    expect(find.text('Pesquisar'), findsOneWidget);
    expect(find.text('Fonte dos dados: CPTEC/INPE'), findsOneWidget);
  });
}