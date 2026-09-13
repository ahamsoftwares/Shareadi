import 'package:flutter_test/flutter_test.dart';
import 'package:share_adi/features/expenses/split_engine.dart';

void main() {
  const a = 'a';
  const b = 'b';
  const c = 'c';

  int totalOf(List<MemberSplit> splits) =>
      splits.fold(0, (sum, s) => sum + s.amountCents);

  group('equal split', () {
    test('divides evenly with empty value', () {
      final result = SplitEngine.computeEqual(600, [a, b, c]);
      expect(totalOf(result), 600);
      expect(result.map((s) => s.amountCents).toList(), [200, 200, 200]);
    });

    test('distributes remainder cents', () {
      final result = SplitEngine.computeEqual(100, [a, b, c]);
      expect(totalOf(result), 100);
      expect(result.map((s) => s.amountCents).toList(), [34, 33, 33]);
    });
  });

  group('amounts split', () {
    test('remainder goes to payer when underpaid', () {
      final result = SplitEngine.computeAmounts(1000, c, [a, b, c], {
        a: 250,
        b: 250,
      });
      expect(totalOf(result), 1000);
      expect(result.where((s) => s.memberId == c).single.amountCents, 500);
    });

    test('exact amounts unchanged', () {
      final result = SplitEngine.computeAmounts(500, c, [a, b, c], {
        a: 300,
        b: 200,
        c: 0,
      });
      expect(totalOf(result), 500);
      expect(result.where((s) => s.memberId == a).single.amountCents, 300);
      expect(result.where((s) => s.memberId == b).single.amountCents, 200);
    });
  });

  group('percentage split', () {
    test('splits by percentage and sums to total', () {
      final result = SplitEngine.computePercentage(1000, [a, b, c], {
        a: 20,
        b: 30,
        c: 50,
      });
      expect(totalOf(result), 1000);
      expect(result.where((s) => s.memberId == a).single.amountCents, 200);
      expect(result.where((s) => s.memberId == b).single.amountCents, 300);
      expect(result.where((s) => s.memberId == c).single.amountCents, 500);
    });

    test('odd cents round to exact total', () {
      final result = SplitEngine.computePercentage(100, [a, b, c], {
        a: 33.33,
        b: 33.33,
        c: 33.34,
      });
      expect(totalOf(result), 100);
    });
  });

  group('shares split', () {
    test('splits by ratio and sums to total', () {
      final result = SplitEngine.computeShares(600, [a, b, c], {
        a: 1,
        b: 2,
        c: 3,
      });
      expect(totalOf(result), 600);
      expect(result.where((s) => s.memberId == a).single.amountCents, 100);
      expect(result.where((s) => s.memberId == b).single.amountCents, 200);
      expect(result.where((s) => s.memberId == c).single.amountCents, 300);
    });
  });

  group('compute wrapper', () {
    test('dispatches by type and keeps total', () {
      final result = SplitEngine.compute(
        type: SplitType.equal,
        totalCents: 100,
        payerId: a,
        memberIds: [a, b, c],
      );
      expect(totalOf(result), 100);
    });
  });
}