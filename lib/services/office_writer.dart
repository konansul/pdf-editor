import 'dart:typed_data';

import 'package:archive/archive.dart';

class OfficeWriter {
  const OfficeWriter();

  Uint8List wordDocument(List<String> pages) {
    final body = StringBuffer();

    for (var index = 0; index < pages.length; index++) {
      if (index > 0) {
        body.write('<w:p><w:r><w:br w:type="page"/></w:r></w:p>');
      }

      final lines = pages[index].split('\n');
      final written = lines.where((line) => line.trim().isNotEmpty);

      if (written.isEmpty) {
        body.write('<w:p/>');
        continue;
      }

      for (final line in written) {
        body.write(
          '<w:p><w:r><w:t xml:space="preserve">${_escape(line)}</w:t></w:r></w:p>',
        );
      }
    }

    final archive = Archive()
      ..add(ArchiveFile.string('[Content_Types].xml', _wordContentTypes))
      ..add(ArchiveFile.string('_rels/.rels', _packageRels('word/document.xml')))
      ..add(
        ArchiveFile.string(
          'word/document.xml',
          '$_xmlHeader'
          '<w:document xmlns:w="http://schemas.openxmlformats.org/wordprocessingml/2006/main">'
          '<w:body>$body'
          '<w:sectPr><w:pgSz w:w="11906" w:h="16838"/>'
          '<w:pgMar w:top="1134" w:right="1134" w:bottom="1134" w:left="1134"/></w:sectPr>'
          '</w:body></w:document>',
        ),
      );

    return ZipEncoder().encodeBytes(archive);
  }

  Uint8List slideDeck(List<Uint8List> pages, {required double aspect}) {
    const width = 9144000;
    final height = (width * aspect).round();

    final archive = Archive();
    final slideIds = StringBuffer();
    final presentationRels = StringBuffer()
      ..write(
        '<Relationship Id="rId1" '
        'Type="http://schemas.openxmlformats.org/officeDocument/2006/relationships/slideMaster" '
        'Target="slideMasters/slideMaster1.xml"/>',
      );
    final overrides = StringBuffer();

    for (var index = 0; index < pages.length; index++) {
      final number = index + 1;
      final relationship = number + 1;

      archive.add(ArchiveFile.bytes('ppt/media/image$number.jpeg', pages[index]));
      archive.add(ArchiveFile.string('ppt/slides/slide$number.xml', _slide(number, width, height)));
      archive.add(
        ArchiveFile.string(
          'ppt/slides/_rels/slide$number.xml.rels',
          '$_xmlHeader<Relationships xmlns="$_relsNamespace">'
          '<Relationship Id="rId1" '
          'Type="http://schemas.openxmlformats.org/officeDocument/2006/relationships/slideLayout" '
          'Target="../slideLayouts/slideLayout1.xml"/>'
          '<Relationship Id="rId2" '
          'Type="http://schemas.openxmlformats.org/officeDocument/2006/relationships/image" '
          'Target="../media/image$number.jpeg"/>'
          '</Relationships>',
        ),
      );

      slideIds.write('<p:sldId id="${255 + number}" r:id="rId$relationship"/>');
      presentationRels.write(
        '<Relationship Id="rId$relationship" '
        'Type="http://schemas.openxmlformats.org/officeDocument/2006/relationships/slide" '
        'Target="slides/slide$number.xml"/>',
      );
      overrides.write(
        '<Override PartName="/ppt/slides/slide$number.xml" '
        'ContentType="application/vnd.openxmlformats-officedocument.presentationml.slide+xml"/>',
      );
    }

    archive
      ..add(ArchiveFile.string('[Content_Types].xml', _slideContentTypes(overrides.toString())))
      ..add(ArchiveFile.string('_rels/.rels', _packageRels('ppt/presentation.xml')))
      ..add(
        ArchiveFile.string(
          'ppt/presentation.xml',
          '$_xmlHeader<p:presentation xmlns:a="$_drawingNamespace" '
          'xmlns:r="$_officeRelsNamespace" xmlns:p="$_presentationNamespace">'
          '<p:sldMasterIdLst><p:sldMasterId id="2147483648" r:id="rId1"/></p:sldMasterIdLst>'
          '<p:sldIdLst>$slideIds</p:sldIdLst>'
          '<p:sldSz cx="$width" cy="$height"/>'
          '<p:notesSz cx="$height" cy="$width"/>'
          '</p:presentation>',
        ),
      )
      ..add(
        ArchiveFile.string(
          'ppt/_rels/presentation.xml.rels',
          '$_xmlHeader<Relationships xmlns="$_relsNamespace">$presentationRels</Relationships>',
        ),
      )
      ..add(ArchiveFile.string('ppt/slideMasters/slideMaster1.xml', _slideMaster))
      ..add(
        ArchiveFile.string(
          'ppt/slideMasters/_rels/slideMaster1.xml.rels',
          '$_xmlHeader<Relationships xmlns="$_relsNamespace">'
          '<Relationship Id="rId1" '
          'Type="http://schemas.openxmlformats.org/officeDocument/2006/relationships/slideLayout" '
          'Target="../slideLayouts/slideLayout1.xml"/>'
          '<Relationship Id="rId2" '
          'Type="http://schemas.openxmlformats.org/officeDocument/2006/relationships/theme" '
          'Target="../theme/theme1.xml"/>'
          '</Relationships>',
        ),
      )
      ..add(ArchiveFile.string('ppt/slideLayouts/slideLayout1.xml', _slideLayout))
      ..add(
        ArchiveFile.string(
          'ppt/slideLayouts/_rels/slideLayout1.xml.rels',
          '$_xmlHeader<Relationships xmlns="$_relsNamespace">'
          '<Relationship Id="rId1" '
          'Type="http://schemas.openxmlformats.org/officeDocument/2006/relationships/slideMaster" '
          'Target="../slideMasters/slideMaster1.xml"/>'
          '</Relationships>',
        ),
      )
      ..add(ArchiveFile.string('ppt/theme/theme1.xml', _theme));

    return ZipEncoder().encodeBytes(archive);
  }

  String _slide(int number, int width, int height) {
    return '$_xmlHeader<p:sld xmlns:a="$_drawingNamespace" xmlns:r="$_officeRelsNamespace" '
        'xmlns:p="$_presentationNamespace"><p:cSld><p:spTree>'
        '$_emptyGroup'
        '<p:pic><p:nvPicPr><p:cNvPr id="2" name="Page $number"/>'
        '<p:cNvPicPr><a:picLocks noChangeAspect="1"/></p:cNvPicPr><p:nvPr/></p:nvPicPr>'
        '<p:blipFill><a:blip r:embed="rId2"/><a:stretch><a:fillRect/></a:stretch></p:blipFill>'
        '<p:spPr><a:xfrm><a:off x="0" y="0"/><a:ext cx="$width" cy="$height"/></a:xfrm>'
        '<a:prstGeom prst="rect"><a:avLst/></a:prstGeom></p:spPr></p:pic>'
        '</p:spTree></p:cSld><p:clrMapOvr><a:masterClrMapping/></p:clrMapOvr></p:sld>';
  }

  String _packageRels(String target) {
    return '$_xmlHeader<Relationships xmlns="$_relsNamespace">'
        '<Relationship Id="rId1" '
        'Type="http://schemas.openxmlformats.org/officeDocument/2006/relationships/officeDocument" '
        'Target="$target"/></Relationships>';
  }

  String _slideContentTypes(String overrides) {
    return '$_xmlHeader<Types xmlns="http://schemas.openxmlformats.org/package/2006/content-types">'
        '<Default Extension="rels" '
        'ContentType="application/vnd.openxmlformats-package.relationships+xml"/>'
        '<Default Extension="xml" ContentType="application/xml"/>'
        '<Default Extension="jpeg" ContentType="image/jpeg"/>'
        '<Override PartName="/ppt/presentation.xml" '
        'ContentType="application/vnd.openxmlformats-officedocument.presentationml.presentation.main+xml"/>'
        '<Override PartName="/ppt/slideMasters/slideMaster1.xml" '
        'ContentType="application/vnd.openxmlformats-officedocument.presentationml.slideMaster+xml"/>'
        '<Override PartName="/ppt/slideLayouts/slideLayout1.xml" '
        'ContentType="application/vnd.openxmlformats-officedocument.presentationml.slideLayout+xml"/>'
        '<Override PartName="/ppt/theme/theme1.xml" '
        'ContentType="application/vnd.openxmlformats-officedocument.theme+xml"/>'
        '$overrides</Types>';
  }

  String _escape(String value) {
    return value
        .replaceAll('&', '&amp;')
        .replaceAll('<', '&lt;')
        .replaceAll('>', '&gt;')
        .replaceAll('"', '&quot;');
  }
}

const _xmlHeader = '<?xml version="1.0" encoding="UTF-8" standalone="yes"?>';
const _relsNamespace = 'http://schemas.openxmlformats.org/package/2006/relationships';
const _officeRelsNamespace =
    'http://schemas.openxmlformats.org/officeDocument/2006/relationships';
const _drawingNamespace = 'http://schemas.openxmlformats.org/drawingml/2006/main';
const _presentationNamespace = 'http://schemas.openxmlformats.org/presentationml/2006/main';

const _emptyGroup = '<p:nvGrpSpPr><p:cNvPr id="1" name=""/><p:cNvGrpSpPr/><p:nvPr/></p:nvGrpSpPr>'
    '<p:grpSpPr><a:xfrm><a:off x="0" y="0"/><a:ext cx="0" cy="0"/>'
    '<a:chOff x="0" y="0"/><a:chExt cx="0" cy="0"/></a:xfrm></p:grpSpPr>';

const _wordContentTypes =
    '$_xmlHeader<Types xmlns="http://schemas.openxmlformats.org/package/2006/content-types">'
    '<Default Extension="rels" '
    'ContentType="application/vnd.openxmlformats-package.relationships+xml"/>'
    '<Default Extension="xml" ContentType="application/xml"/>'
    '<Override PartName="/word/document.xml" '
    'ContentType="application/vnd.openxmlformats-officedocument.wordprocessingml.document.main+xml"/>'
    '</Types>';

const _slideMaster =
    '$_xmlHeader<p:sldMaster xmlns:a="$_drawingNamespace" xmlns:r="$_officeRelsNamespace" '
    'xmlns:p="$_presentationNamespace"><p:cSld>'
    '<p:bg><p:bgPr><a:solidFill><a:srgbClr val="FFFFFF"/></a:solidFill>'
    '<a:effectLst/></p:bgPr></p:bg>'
    '<p:spTree>$_emptyGroup</p:spTree></p:cSld>'
    '<p:clrMap bg1="lt1" tx1="dk1" bg2="lt2" tx2="dk2" hlink="hlink" folHlink="folHlink"/>'
    '<p:sldLayoutIdLst><p:sldLayoutId id="2147483649" r:id="rId1"/></p:sldLayoutIdLst>'
    '</p:sldMaster>';

const _slideLayout =
    '$_xmlHeader<p:sldLayout xmlns:a="$_drawingNamespace" xmlns:r="$_officeRelsNamespace" '
    'xmlns:p="$_presentationNamespace" type="blank" preserve="1">'
    '<p:cSld name="Blank"><p:spTree>$_emptyGroup</p:spTree></p:cSld>'
    '<p:clrMapOvr><a:masterClrMapping/></p:clrMapOvr></p:sldLayout>';

const _theme = '$_xmlHeader<a:theme xmlns:a="$_drawingNamespace" name="PDF Editor">'
    '<a:themeElements>'
    '<a:clrScheme name="PDF Editor">'
    '<a:dk1><a:sysClr val="windowText" lastClr="000000"/></a:dk1>'
    '<a:lt1><a:sysClr val="window" lastClr="FFFFFF"/></a:lt1>'
    '<a:dk2><a:srgbClr val="1A1A18"/></a:dk2>'
    '<a:lt2><a:srgbClr val="FAF9F7"/></a:lt2>'
    '<a:accent1><a:srgbClr val="2F6B5F"/></a:accent1>'
    '<a:accent2><a:srgbClr val="4FA391"/></a:accent2>'
    '<a:accent3><a:srgbClr val="8A8781"/></a:accent3>'
    '<a:accent4><a:srgbClr val="C0392B"/></a:accent4>'
    '<a:accent5><a:srgbClr val="E6E3DE"/></a:accent5>'
    '<a:accent6><a:srgbClr val="2C2B28"/></a:accent6>'
    '<a:hlink><a:srgbClr val="2F6B5F"/></a:hlink>'
    '<a:folHlink><a:srgbClr val="8A8781"/></a:folHlink>'
    '</a:clrScheme>'
    '<a:fontScheme name="PDF Editor">'
    '<a:majorFont><a:latin typeface="Helvetica"/><a:ea typeface=""/><a:cs typeface=""/></a:majorFont>'
    '<a:minorFont><a:latin typeface="Helvetica"/><a:ea typeface=""/><a:cs typeface=""/></a:minorFont>'
    '</a:fontScheme>'
    '<a:fmtScheme name="PDF Editor">'
    '<a:fillStyleLst>'
    '<a:solidFill><a:schemeClr val="phClr"/></a:solidFill>'
    '<a:solidFill><a:schemeClr val="phClr"/></a:solidFill>'
    '<a:solidFill><a:schemeClr val="phClr"/></a:solidFill>'
    '</a:fillStyleLst>'
    '<a:lnStyleLst>'
    '<a:ln w="6350" cap="flat" cmpd="sng" algn="ctr">'
    '<a:solidFill><a:schemeClr val="phClr"/></a:solidFill><a:prstDash val="solid"/></a:ln>'
    '<a:ln w="12700" cap="flat" cmpd="sng" algn="ctr">'
    '<a:solidFill><a:schemeClr val="phClr"/></a:solidFill><a:prstDash val="solid"/></a:ln>'
    '<a:ln w="19050" cap="flat" cmpd="sng" algn="ctr">'
    '<a:solidFill><a:schemeClr val="phClr"/></a:solidFill><a:prstDash val="solid"/></a:ln>'
    '</a:lnStyleLst>'
    '<a:effectStyleLst>'
    '<a:effectStyle><a:effectLst/></a:effectStyle>'
    '<a:effectStyle><a:effectLst/></a:effectStyle>'
    '<a:effectStyle><a:effectLst/></a:effectStyle>'
    '</a:effectStyleLst>'
    '<a:bgFillStyleLst>'
    '<a:solidFill><a:schemeClr val="phClr"/></a:solidFill>'
    '<a:solidFill><a:schemeClr val="phClr"/></a:solidFill>'
    '<a:solidFill><a:schemeClr val="phClr"/></a:solidFill>'
    '</a:bgFillStyleLst>'
    '</a:fmtScheme>'
    '</a:themeElements></a:theme>';
