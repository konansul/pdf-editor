import 'dart:convert';
import 'dart:typed_data';

import 'package:archive/archive.dart';
import 'package:collate/services/office_writer.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:image/image.dart' as img;
import 'package:path/path.dart' as p;
import 'package:xml/xml.dart';

Archive _open(Uint8List bytes) => ZipDecoder().decodeBytes(bytes);

String _read(Archive archive, String name) {
  final file = archive.files.firstWhere((entry) => entry.name == name);
  return utf8.decode(file.readBytes()!);
}

void _expectWellFormed(Archive archive) {
  for (final file in archive.files) {
    if (!file.name.endsWith('.xml') && !file.name.endsWith('.rels')) continue;
    expect(
      () => XmlDocument.parse(utf8.decode(file.readBytes()!)),
      returnsNormally,
      reason: '${file.name} is not well-formed XML',
    );
  }
}

void _expectRelationshipsResolve(Archive archive) {
  final names = archive.files.map((file) => file.name).toSet();

  for (final file in archive.files) {
    if (!file.name.endsWith('.rels')) continue;

    final base = p.dirname(p.dirname(file.name));
    final document = XmlDocument.parse(utf8.decode(file.readBytes()!));

    for (final relationship in document.findAllElements('Relationship')) {
      final target = relationship.getAttribute('Target')!;
      final resolved = p.normalize(p.join(base == '.' ? '' : base, target));
      expect(names, contains(resolved), reason: '${file.name} points at a missing part');
    }
  }
}

void _expectContentTypesCoverEveryPart(Archive archive) {
  final types = XmlDocument.parse(_read(archive, '[Content_Types].xml'));
  final defaults = types
      .findAllElements('Default')
      .map((node) => node.getAttribute('Extension')!.toLowerCase())
      .toSet();
  final overrides =
      types.findAllElements('Override').map((node) => node.getAttribute('PartName')!).toSet();

  for (final file in archive.files) {
    if (file.name == '[Content_Types].xml') continue;

    final basename = p.basename(file.name);
    final dot = basename.lastIndexOf('.');
    final extension = dot == -1 ? '' : basename.substring(dot + 1).toLowerCase();

    final covered = overrides.contains('/${file.name}') || defaults.contains(extension);
    expect(covered, isTrue, reason: '${file.name} has no declared content type');
  }
}

void main() {
  const writer = OfficeWriter();

  group('word document', () {
    test('is a package Word can open', () {
      final archive = _open(writer.wordDocument(['First line\nSecond line', 'Page two']));

      expect(
        archive.files.map((file) => file.name),
        containsAll(['[Content_Types].xml', '_rels/.rels', 'word/document.xml']),
      );

      _expectWellFormed(archive);
      _expectRelationshipsResolve(archive);
      _expectContentTypesCoverEveryPart(archive);
    });

    test('writes one paragraph per line and a break between pages', () {
      final archive = _open(writer.wordDocument(['First line\nSecond line', 'Page two']));
      final document = XmlDocument.parse(_read(archive, 'word/document.xml'));

      final runs = document.findAllElements('w:t').map((node) => node.innerText).toList();
      expect(runs, ['First line', 'Second line', 'Page two']);
      expect(document.findAllElements('w:br').length, 1);
    });

    test('escapes characters that would break the XML', () {
      final archive = _open(writer.wordDocument(['Tom & Jerry <b>']));
      final document = XmlDocument.parse(_read(archive, 'word/document.xml'));

      expect(document.findAllElements('w:t').single.innerText, 'Tom & Jerry <b>');
    });
  });

  group('slide deck', () {
    final page = Uint8List.fromList(img.encodeJpg(img.Image(width: 8, height: 12)));

    test('is a package PowerPoint can open', () {
      final archive = _open(writer.slideDeck([page, page], aspect: 1.4));

      expect(
        archive.files.map((file) => file.name),
        containsAll([
          '[Content_Types].xml',
          '_rels/.rels',
          'ppt/presentation.xml',
          'ppt/_rels/presentation.xml.rels',
          'ppt/slideMasters/slideMaster1.xml',
          'ppt/slideLayouts/slideLayout1.xml',
          'ppt/theme/theme1.xml',
          'ppt/slides/slide1.xml',
          'ppt/slides/slide2.xml',
          'ppt/media/image1.jpeg',
          'ppt/media/image2.jpeg',
        ]),
      );

      _expectWellFormed(archive);
      _expectRelationshipsResolve(archive);
      _expectContentTypesCoverEveryPart(archive);
    });

    test('lists every slide in the presentation', () {
      final archive = _open(writer.slideDeck([page, page, page], aspect: 1.4));
      final presentation = XmlDocument.parse(_read(archive, 'ppt/presentation.xml'));

      expect(presentation.findAllElements('p:sldId').length, 3);
      expect(presentation.findAllElements('p:sldSz').single.getAttribute('cx'), '9144000');
      expect(presentation.findAllElements('p:sldSz').single.getAttribute('cy'), '12801600');
    });

    test('each slide embeds its own page image', () {
      final archive = _open(writer.slideDeck([page, page], aspect: 1.4));

      for (final number in [1, 2]) {
        final rels = XmlDocument.parse(_read(archive, 'ppt/slides/_rels/slide$number.xml.rels'));
        final image = rels
            .findAllElements('Relationship')
            .firstWhere((node) => node.getAttribute('Id') == 'rId2');
        expect(image.getAttribute('Target'), '../media/image$number.jpeg');
      }
    });
  });
}
