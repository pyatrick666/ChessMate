import 'package:flutter_test/flutter_test.dart';
import 'package:chessmate/main.dart';

void main() {
  testWidgets('ChessMate home screen renders', (tester) async {
    await tester.pumpWidget(const ChessMateApp());
    expect(find.text('ChessMate'), findsOneWidget);
    expect(find.text('Start Game'), findsOneWidget);
    expect(find.text('How to Play'), findsOneWidget);
  });
}
