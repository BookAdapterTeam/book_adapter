import 'package:flutter/material.dart';
import 'package:paged_html/paged_html.dart';

void main() {
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Flutter PagedHtml Example',
      theme: ThemeData(
        primarySwatch: Colors.blue,
      ),
      home: const PagedHtmlExample(),
    );
  }
}

class PagedHtmlExample extends StatefulWidget {
  const PagedHtmlExample({Key? key}) : super(key: key);

  @override
  State<PagedHtmlExample> createState() => _PagedHtmlExampleState();
}

class _PagedHtmlExampleState extends State<PagedHtmlExample> {
  final controller = PagedHtmlController();

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Flutter PagedHtml Example')),
      body: PagedHtml(
        key: const ValueKey('HtmlReader'),
        controller: controller,
        physics: const PageScrollPhysics(),
        restorationId: 'PagedHtmlExample',
        showEndPage: true,
        html:
            // ignore: prefer_interpolation_to_compose_strings
            '''
<html xmlns="http://www.w3.org/1999/xhtml" xml:lang="en">
<head>
<meta content="text/html; charset=UTF-8" http-equiv="Content-Type"/>
<title>Guardians of Ga’Hoole: The Rise of a Legend</title>
<link href="page-template.xpgt" rel="stylesheet" type="application/vnd.adobe-page-template+xml"/>
<link href="css/9780545509800.css" rel="stylesheet" type="text/css"/>
<meta content="urn:uuid:4168cd53-296a-4c04-b54f-f332a0745246" name="Adept.expected.resource"/>
</head>
<body class="text" id="text">
<div class="chapter" id="ch1">
<div class="chapterHead"><p class="centerImage"><img alt="image" class="epubimage" src="images/ch1.jpg"/></p>
</div>
<p class="paraNoIndent" style="text-indent: 0%;">The first crack in the egg that held me occurred just before midnight. My mum and da weren’t there, of course, as the action in the century-long War of the Ice Claws had heated up and they were both away fighting. So they’d gotten a hire broody for the egg — common practice in the war-torn Northern Kingdoms. When my first crack started, the hire broody, Gundesfyrr, sent out Mrs. Grinkle, our nest-maid snake, to inform the neighbors. Hatchings were treasured occasions, particularly during times of war, for every new chick was viewed as a potential fighter. Most likely, everyone bent over my shell urging me to soldier on in my first battle — getting out of this egg that had sheltered me for nearly two moons.</p>
<p class="para" style="text-indent: 5%;">“C’mon, chickie! Follow in the flight marks of your da — the old general!”</p>
<p class="para" style="text-indent: 5%;">“And his mum, don’t forget his mum! The commando.” The words were muffled through the shell and I really didn’t understand much. But I would soon learn that my mum was a commando in the Ice Dagger unit, and Da was supreme commander of all the allied forces of the Kielian League, which included the famous Frost Beaks as well as the Hot Blades and other divisions. In short, they didn’t come home too much.</p>
<p class="para" style="text-indent: 5%;">“Why did <span class="italic">she</span> have to show up?”</p>
<div class="extract">
<p class="paraNoIndent" style="text-indent: 0%;"><span class="italic">Lick the slime,</span></p>
<p class="paraNoIndent" style="text-indent: 0%;"><span class="italic">There is time.</span></p>
<p class="paraNoIndent" style="text-indent: 0%;"><span class="italic">Dear owlet,</span></p>
</div>
<p class="para" style="text-indent: 5%;">Hanja continued, “Now we must all pull ourselves together because I think this is a precious little chick here. I have a feeling he’s bound for greatness.”</p>
<p class="para" style="text-indent: 5%;">“Oh, dear,” Mrs. Grinkle the nest-maid snake whispered. “What she feels is greatness is sometimes tragedy — the tragedy of heroism like dear Edvard!”</p>
<p class="centerImage"><img alt="image" class="epubimage" src="images/sbni.jpg"/></p>
<p class="paraNoIndent" style="text-indent: 0%;">Two days later, Tantya Hanja left and there was a great sigh of relief at our end of Stormfast Island. And before I knew it, it was time for my First Insect ceremony. But even more memorable would be my First Meat ceremony, for my mum and da had returned by then.</p>
</div>
</body>
</html>
''',
      ),
    );
  }
}
