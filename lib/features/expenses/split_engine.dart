enum SplitType {
  equal('Equal', 'Equal split'),
  amounts('Amounts', 'Split by exact amounts'),
  percentage('Percentage', 'Split by percentage'),
  shares('Shares', 'Split by ratio');

  const SplitType(this.label, this.description);

  final String label;
  final String description;
}

class MemberSplit {
  const MemberSplit({required this.memberId, required this.amountCents});

  final String memberId;
  final int amountCents;
}

class SplitEngine {
  const SplitEngine._();

  static List<MemberSplit> compute({
    required SplitType type,
    required int totalCents,
    required String payerId,
    required List<String> memberIds,
    Map<String, int> amountCents = const {},
    Map<String, double> percentages = const {},
    Map<String, double> shares = const {},
  }) {
    switch (type) {
      case SplitType.equal:
        return computeEqual(totalCents, memberIds);
      case SplitType.amounts:
        return computeAmounts(totalCents, payerId, memberIds, amountCents);
      case SplitType.percentage:
        return computePercentage(totalCents, memberIds, percentages);
      case SplitType.shares:
        return computeShares(totalCents, memberIds, shares);
    }
  }

  static List<MemberSplit> computeEqual(
    int totalCents,
    List<String> memberIds,
  ) {
    if (memberIds.isEmpty || totalCents <= 0) return const [];
    final base = totalCents ~/ memberIds.length;
    var remainder = totalCents - base * memberIds.length;
    final result = <MemberSplit>[];
    for (var i = 0; i < memberIds.length; i++) {
      var cents = base;
      if (remainder > 0) {
        cents++;
        remainder--;
      }
      result.add(MemberSplit(memberId: memberIds[i], amountCents: cents));
    }
    return result;
  }

  static List<MemberSplit> computeAmounts(
    int totalCents,
    String payerId,
    List<String> memberIds,
    Map<String, int> amounts,
  ) {
    if (memberIds.isEmpty || totalCents <= 0) return const [];
    final result = <MemberSplit>[];
    var sum = 0;
    for (final id in memberIds) {
      final value = amounts[id] ?? 0;
      sum += value;
      result.add(MemberSplit(memberId: id, amountCents: value));
    }
    final remainder = totalCents - sum;
    if (remainder != 0 && memberIds.contains(payerId)) {
      final index = memberIds.indexOf(payerId);
      final current = result[index];
      result[index] = MemberSplit(
        memberId: current.memberId,
        amountCents: current.amountCents + remainder,
      );
    } else if (remainder > 0) {
      result.add(MemberSplit(memberId: payerId, amountCents: remainder));
    }
    return result;
  }

  static List<MemberSplit> computePercentage(
    int totalCents,
    List<String> memberIds,
    Map<String, double> percentages,
  ) {
    if (memberIds.isEmpty || totalCents <= 0) return const [];
    final result = <MemberSplit>[];
    for (final id in memberIds) {
      final pct = percentages[id] ?? 0;
      result.add(
        MemberSplit(
          memberId: id,
          amountCents: (totalCents * pct / 100).round(),
        ),
      );
    }
    _fixRounding(result, totalCents);
    return result;
  }

  static List<MemberSplit> computeShares(
    int totalCents,
    List<String> memberIds,
    Map<String, double> shares,
  ) {
    if (memberIds.isEmpty || totalCents <= 0) return const [];
    var totalShares = 0.0;
    for (final id in memberIds) {
      totalShares += shares[id] ?? 0;
    }
    if (totalShares <= 0) return const [];
    final result = <MemberSplit>[];
    for (final id in memberIds) {
      final share = shares[id] ?? 0;
      result.add(
        MemberSplit(
          memberId: id,
          amountCents: (totalCents * share / totalShares).round(),
        ),
      );
    }
    _fixRounding(result, totalCents);
    return result;
  }

  static void _fixRounding(List<MemberSplit> result, int totalCents) {
    if (result.isEmpty) return;
    var diff = totalCents -
        result.fold(0, (sum, item) => sum + item.amountCents);
    var index = 0;
    while (diff != 0) {
      final current = result[index % result.length];
      final adjustment = diff > 0 ? 1 : -1;
      result[index % result.length] = MemberSplit(
        memberId: current.memberId,
        amountCents: current.amountCents + adjustment,
      );
      diff -= adjustment;
      index++;
    }
  }
}