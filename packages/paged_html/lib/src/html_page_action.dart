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

class HtmlPageAction {
  const HtmlPageAction({
    required this.type,
    required this.amount,
  });

  const HtmlPageAction.addNone()
      : type = HtmlPageActionType.add,
        amount = HtmlPageChangeAmount.none;

  const HtmlPageAction.addParagraph()
      : type = HtmlPageActionType.add,
        amount = HtmlPageChangeAmount.paragraph;

  const HtmlPageAction.addSentence()
      : type = HtmlPageActionType.add,
        amount = HtmlPageChangeAmount.sentence;

  const HtmlPageAction.addWord()
      : type = HtmlPageActionType.add,
        amount = HtmlPageChangeAmount.word;

  const HtmlPageAction.removeNone()
      : type = HtmlPageActionType.remove,
        amount = HtmlPageChangeAmount.none;

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
  final HtmlPageActionType type;

  /// The amount of html that should be added or removed, depending on [type]
  final HtmlPageChangeAmount amount;
}

enum HtmlPageEvent {
  /// The html page has extra space available, so extra content can be added.
  hasExtraSpace,

  /// The html is too long for the page, so some content should be removed.
  hasNoExtraSpace,
}

enum HtmlPageActionType {
  add,
  remove,
}

enum HtmlPageChangeAmount {
  /// Add or remove a paragraph from the html content, depending on the event.
  paragraph,

  /// Add or remove a sentence from the html content, depending on the event.
  sentence,

  /// Add or remove a word from the html content, depending on the event.
  word,

  /// No action is required.
  none,
}
