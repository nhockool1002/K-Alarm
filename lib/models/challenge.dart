/// The kind of task the user must complete to dismiss a ringing alarm.
enum ChallengeType {
  none,
  math,
  qrScan,
  shake,
  retypeSentence,
}

extension ChallengeTypeLabel on ChallengeType {
  String get label {
    switch (this) {
      case ChallengeType.none:
        return 'Không cần (vuốt để tắt)';
      case ChallengeType.math:
        return 'Giải toán';
      case ChallengeType.qrScan:
        return 'Quét mã QR';
      case ChallengeType.shake:
        return 'Lắc điện thoại';
      case ChallengeType.retypeSentence:
        return 'Gõ lại câu';
    }
  }

  String get description {
    switch (this) {
      case ChallengeType.none:
        return 'Chỉ cần vuốt/nhấn nút để tắt báo thức.';
      case ChallengeType.math:
        return 'Phải giải đúng một phép tính ngẫu nhiên.';
      case ChallengeType.qrScan:
        return 'Phải quét đúng mã QR đã đặt trước bằng camera.';
      case ChallengeType.shake:
        return 'Phải lắc điện thoại đủ số lần yêu cầu.';
      case ChallengeType.retypeSentence:
        return 'Phải gõ lại chính xác một câu hiển thị trên màn hình.';
    }
  }
}

/// Difficulty presets for the math challenge.
enum MathDifficulty { easy, medium, hard }

extension MathDifficultyLabel on MathDifficulty {
  String get label {
    switch (this) {
      case MathDifficulty.easy:
        return 'Dễ (cộng/trừ, số nhỏ)';
      case MathDifficulty.medium:
        return 'Trung bình (cộng/trừ/nhân, số lớn hơn)';
      case MathDifficulty.hard:
        return 'Khó (nhân/chia nhiều bước)';
    }
  }
}

/// Full configuration for whichever [ChallengeType] an alarm uses.
class ChallengeConfig {
  ChallengeType type;

  /// Math challenge settings.
  MathDifficulty mathDifficulty;

  /// QR challenge: the exact text/content the target QR code must decode to.
  String qrExpectedContent;

  /// Shake challenge: how many shakes are required.
  int shakeCount;

  /// Retype-sentence challenge: a custom sentence, or null to pick a random one.
  String? customSentence;

  ChallengeConfig({
    this.type = ChallengeType.math,
    this.mathDifficulty = MathDifficulty.easy,
    this.qrExpectedContent = '',
    this.shakeCount = 15,
    this.customSentence,
  });

  ChallengeConfig copyWith({
    ChallengeType? type,
    MathDifficulty? mathDifficulty,
    String? qrExpectedContent,
    int? shakeCount,
    String? customSentence,
  }) {
    return ChallengeConfig(
      type: type ?? this.type,
      mathDifficulty: mathDifficulty ?? this.mathDifficulty,
      qrExpectedContent: qrExpectedContent ?? this.qrExpectedContent,
      shakeCount: shakeCount ?? this.shakeCount,
      customSentence: customSentence ?? this.customSentence,
    );
  }

  Map<String, dynamic> toJson() => {
        'type': type.name,
        'mathDifficulty': mathDifficulty.name,
        'qrExpectedContent': qrExpectedContent,
        'shakeCount': shakeCount,
        'customSentence': customSentence,
      };

  factory ChallengeConfig.fromJson(Map<String, dynamic> json) {
    return ChallengeConfig(
      type: ChallengeType.values.firstWhere(
        (e) => e.name == json['type'],
        orElse: () => ChallengeType.math,
      ),
      mathDifficulty: MathDifficulty.values.firstWhere(
        (e) => e.name == json['mathDifficulty'],
        orElse: () => MathDifficulty.easy,
      ),
      qrExpectedContent: json['qrExpectedContent'] as String? ?? '',
      shakeCount: json['shakeCount'] as int? ?? 15,
      customSentence: json['customSentence'] as String?,
    );
  }
}
