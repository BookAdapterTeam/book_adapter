A Flutter package for displaying HTML content in a PageView.

## Features

Splits the HTML content into pages and displays them in a PageView.

Limitations:

- It is impossible to get the number of pages
- The HTML widget is measured during layout and rebuilt multiple times
until it fits in the available space.
- No support for jumping to a specific location in the html (Epub CFI)

## Getting started

In the pubspec.yaml of your flutter project, add the following dependency:

<!-- ```yaml
dependencies:
  paged_html: ^0.0.1
``` -->
```yaml
dependencies:
  paged_html:
    git: https://github.com/BookAdapterTeam/book_adapter/blob/main/packages/paged_html
```

In your library add the following import:

```yaml
import 'package:paged_html/paged_html.dart';
```

## Usage

Example:

```dart
  @override
  Widget build(BuildContext context) {
    return PagedHtml(
        html: '<h1>Hello World</h1>',
    );
  }
```

<!-- ## Additional information

TODO: Tell users more about the package: where to find more information, how to 
contribute to the package, how to file issues, what response they can expect 
from the package authors, and more. -->
