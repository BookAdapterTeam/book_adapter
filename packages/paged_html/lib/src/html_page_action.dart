import 'dart:convert';

import 'package:equatable/equatable.dart';

/// Callback with the current event, previous action, and action
/// that should be performed
///
/// Arguments:
/// - event: The status of the page
/// - removeAction: The amount of content that should be removed
/// - addAction: The amount of content that should be added
typedef RebuildRequestCallback = void Function(
  HtmlPageEvent event,
  HtmlPageAction removeAction,
  HtmlPageAction addAction,
);

class HtmlPageAction extends Equatable {
  const HtmlPageAction({
    required this.type,
    required this.amount,
  });

  bool get isAdd => type == HtmlPageActionType.add;

  bool get isRemove => type == HtmlPageActionType.remove;

  const HtmlPageAction.none()
      : type = HtmlPageActionType.none,
        amount = HtmlPageChangeAmount.none;

  // const HtmlPageAction.addNone()
  //     : type = HtmlPageActionType.add,
  //       amount = HtmlPageChangeAmount.none;

  const HtmlPageAction.addParagraph()
      : type = HtmlPageActionType.add,
        amount = HtmlPageChangeAmount.paragraph;

  const HtmlPageAction.addSentence()
      : type = HtmlPageActionType.add,
        amount = HtmlPageChangeAmount.sentence;

  const HtmlPageAction.addWord()
      : type = HtmlPageActionType.add,
        amount = HtmlPageChangeAmount.word;

  // const HtmlPageAction.removeNone()
  //     : type = HtmlPageActionType.remove,
  //       amount = HtmlPageChangeAmount.none;

  const HtmlPageAction.removeParagraph()
      : type = HtmlPageActionType.remove,
        amount = HtmlPageChangeAmount.paragraph;

  const HtmlPageAction.removeSentence()
      : type = HtmlPageActionType.remove,
        amount = HtmlPageChangeAmount.sentence;

  const HtmlPageAction.removeWord()
      : type = HtmlPageActionType.remove,
        amount = HtmlPageChangeAmount.word;

  /// Determines how [amount] should be used
  ///
  /// enum
  final HtmlPageActionType type;

  /// The amount of html that should be added or removed, depending on [type]
  ///
  /// enum
  final HtmlPageChangeAmount amount;

  HtmlPageAction copyWith({
    HtmlPageActionType? type,
    HtmlPageChangeAmount? amount,
  }) {
    return HtmlPageAction(
      type: type ?? this.type,
      amount: amount ?? this.amount,
    );
  }

  @override
  List<Object> get props => [type, amount];

  @override
  String toString() => 'HtmlPageAction(type: $type, amount: $amount)';

  Map<String, dynamic> toMap() {
    return {
      'type': type.name,
      'amount': amount.name,
    };
  }

  factory HtmlPageAction.fromMap(Map<String, dynamic> map) {
    return HtmlPageAction(
      type: HtmlPageActionType.values.byName(map['type']),
      amount: HtmlPageChangeAmount.values.byName(map['amount']),
    );
  }

  String toJson() => json.encode(toMap());

  factory HtmlPageAction.fromJson(String source) =>
      HtmlPageAction.fromMap(json.decode(source));
}

enum HtmlPageEvent {
  /// The html page has extra space available, so extra content can be added.
  hasExtraSpace,

  /// The html is too long for the page, so some content should be removed.
  hasNoExtraSpace,
}

enum HtmlPageActionType {
  /// Add the changed amount of html
  add,

  /// Remove the changed amount of html
  remove,

  /// Do not change the html
  none,
}

enum HtmlPageChangeAmount {
  /// Add or remove a paragraph from the html content, depending on the event.
  paragraph,

  /// Add or remove a sentence from the html content, depending on the event.
  sentence,

  /// Add or remove a word from the html content, depending on the event.
  word,

  /// Do nothing.
  none,
}
