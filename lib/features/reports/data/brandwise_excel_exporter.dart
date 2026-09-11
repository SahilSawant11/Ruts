import 'dart:io';

import 'models/brandwise_report_dto.dart';

/// Generates an XML Spreadsheet 2003 (.xls) file matching the excise
/// register format: BEER A : WINE BR. II BRANDWISE STOCK REPORT.
class BrandwiseExcelExporter {
  Future<File> exportBrandwiseReport(BrandwiseReportDto report) async {
    final outputDir = await _resolveOutputDirectory();
    await outputDir.create(recursive: true);

    final fileName = 'brandwise_stock_report_${_dateStamp(report.reportDate)}.xls';
    final file = File('${outputDir.path}${Platform.pathSeparator}$fileName');
    await file.writeAsString(_buildWorkbook(report));
    return file;
  }

  Future<Directory> _resolveOutputDirectory() async {
    final home = Platform.environment['HOME'] ?? Platform.environment['USERPROFILE'];
    if (home != null && home.isNotEmpty) {
      final downloads = Directory('$home${Platform.pathSeparator}Downloads');
      if (await downloads.exists()) {
        return Directory('${downloads.path}${Platform.pathSeparator}Caskly Reports');
      }
      return Directory('$home${Platform.pathSeparator}Caskly Reports');
    }
    return Directory('${Directory.current.path}${Platform.pathSeparator}Caskly Reports');
  }

  // ---------------------------------------------------------------
  //  Column layout — 30 data columns total
  //  [0] BRAND NAME  [1] T.P. No.
  //  OPENING BALANCE: [2-4] wine 750/375/180  [5-8] beer 650/500can/330can/330
  //  PURCHASE:        [9-11] wine             [12-15] beer
  //  SALE:            [16-18] wine            [19-22] beer
  //  CLOSING BALANCE: [23-25] wine            [26-29] beer
  // ---------------------------------------------------------------

  static const _totalColumns = 30;

  String _buildWorkbook(BrandwiseReportDto report) {
    final buf = StringBuffer()
      ..writeln('<?xml version="1.0"?>')
      ..writeln('<?mso-application progid="Excel.Sheet"?>')
      ..writeln('<Workbook xmlns="urn:schemas-microsoft-com:office:spreadsheet"')
      ..writeln(' xmlns:o="urn:schemas-microsoft-com:office:office"')
      ..writeln(' xmlns:x="urn:schemas-microsoft-com:office:excel"')
      ..writeln(' xmlns:ss="urn:schemas-microsoft-com:office:spreadsheet"')
      ..writeln(' xmlns:html="http://www.w3.org/TR/REC-html40">')
      ..writeln(_stylesXml)
      ..writeln('<Worksheet ss:Name="BrandwiseStock">')
      ..writeln('<Table>');

    // Column widths
    buf.writeln('<Column ss:Width="220"/>'); // Brand Name
    buf.writeln('<Column ss:Width="65"/>'); // T.P. No.
    for (var i = 0; i < 28; i++) {
      buf.writeln('<Column ss:Width="52"/>');
    }

    // ── Row 1: Title ──
    buf
      ..writeln('<Row ss:Height="24">')
      ..writeln('<Cell ss:MergeAcross="${_totalColumns - 1}" ss:StyleID="title">'
          '<Data ss:Type="String">${_xml(report.licenseHeader)}</Data></Cell>')
      ..writeln('</Row>');

    // ── Row 2: Date ──
    buf
      ..writeln('<Row ss:Height="20">')
      ..writeln('<Cell ss:MergeAcross="${_totalColumns - 1}" ss:StyleID="dateRow">'
          '<Data ss:Type="String">DATE: ${_displayDate(report.reportDate)}</Data></Cell>')
      ..writeln('</Row>');

    // ── Row 3: Top-tier headers (merged groups) ──
    buf.writeln('<Row ss:Height="20">');
    // BRAND NAME spans 1 col, merges down 1 row
    buf.writeln('<Cell ss:StyleID="header" ss:MergeDown="1"><Data ss:Type="String">BRAND NAME</Data></Cell>');
    // T.P. No. spans 1 col, merges down 1 row
    buf.writeln('<Cell ss:StyleID="header" ss:MergeDown="1"><Data ss:Type="String">T.P. No.</Data></Cell>');
    // OPENING BALANCE — 7 cols
    buf.writeln('<Cell ss:StyleID="header" ss:MergeAcross="6"><Data ss:Type="String">OPENING BALANCE</Data></Cell>');
    // PURCHASE — 7 cols
    buf.writeln('<Cell ss:StyleID="header" ss:MergeAcross="6"><Data ss:Type="String">PURCHASE</Data></Cell>');
    // SALE — 7 cols
    buf.writeln('<Cell ss:StyleID="header" ss:MergeAcross="6"><Data ss:Type="String">SALE</Data></Cell>');
    // CLOSING BALANCE — 7 cols
    buf.writeln('<Cell ss:StyleID="header" ss:MergeAcross="6"><Data ss:Type="String">CLOSING BALANCE</Data></Cell>');
    buf.writeln('</Row>');

    // ── Row 4: Sub-tier headers (size columns) ──
    buf.writeln('<Row ss:Height="20">');
    // First two cells skipped (Brand Name + T.P. No. merged down from row 3)
    // Actually in XML Spreadsheet, merged-down cells don't need placeholders
    // in subsequent rows at all — the merge covers them. But we do need
    // to start at the right column index.
    buf.writeln('<Cell ss:Index="3" ss:StyleID="subHeader"><Data ss:Type="String">WINE</Data></Cell>');
    buf.writeln('<Cell ss:StyleID="subHeader"><Data ss:Type="String"></Data></Cell>');
    buf.writeln('<Cell ss:StyleID="subHeader"><Data ss:Type="String"></Data></Cell>');
    buf.writeln('<Cell ss:StyleID="subHeader"><Data ss:Type="String">BEER</Data></Cell>');
    buf.writeln('<Cell ss:StyleID="subHeader"><Data ss:Type="String"></Data></Cell>');
    buf.writeln('<Cell ss:StyleID="subHeader"><Data ss:Type="String"></Data></Cell>');
    buf.writeln('<Cell ss:StyleID="subHeader"><Data ss:Type="String"></Data></Cell>');
    // Repeat for Purchase, Sale, Closing Balance
    for (var g = 0; g < 3; g++) {
      buf.writeln('<Cell ss:StyleID="subHeader"><Data ss:Type="String">WINE</Data></Cell>');
      buf.writeln('<Cell ss:StyleID="subHeader"><Data ss:Type="String"></Data></Cell>');
      buf.writeln('<Cell ss:StyleID="subHeader"><Data ss:Type="String"></Data></Cell>');
      buf.writeln('<Cell ss:StyleID="subHeader"><Data ss:Type="String">BEER</Data></Cell>');
      buf.writeln('<Cell ss:StyleID="subHeader"><Data ss:Type="String"></Data></Cell>');
      buf.writeln('<Cell ss:StyleID="subHeader"><Data ss:Type="String"></Data></Cell>');
      buf.writeln('<Cell ss:StyleID="subHeader"><Data ss:Type="String"></Data></Cell>');
    }
    buf.writeln('</Row>');

    // ── Row 5: Size labels ──
    buf.writeln('<Row ss:Height="18">');
    buf.writeln('<Cell ss:StyleID="subHeader"><Data ss:Type="String"></Data></Cell>');
    buf.writeln('<Cell ss:StyleID="subHeader"><Data ss:Type="String"></Data></Cell>');
    for (var g = 0; g < 4; g++) {
      buf.writeln('<Cell ss:StyleID="sizeHeader"><Data ss:Type="String">750ml</Data></Cell>');
      buf.writeln('<Cell ss:StyleID="sizeHeader"><Data ss:Type="String">375ml</Data></Cell>');
      buf.writeln('<Cell ss:StyleID="sizeHeader"><Data ss:Type="String">180ml</Data></Cell>');
      buf.writeln('<Cell ss:StyleID="sizeHeader"><Data ss:Type="String">650ml</Data></Cell>');
      buf.writeln('<Cell ss:StyleID="sizeHeader"><Data ss:Type="String">500ml (CAN)</Data></Cell>');
      buf.writeln('<Cell ss:StyleID="sizeHeader"><Data ss:Type="String">330ml (CAN)</Data></Cell>');
      buf.writeln('<Cell ss:StyleID="sizeHeader"><Data ss:Type="String">330ml</Data></Cell>');
    }
    buf.writeln('</Row>');

    // ── Category sections ──
    for (final category in report.categories) {
      // Category header row
      buf
        ..writeln('<Row ss:Height="20">')
        ..writeln('<Cell ss:MergeAcross="${_totalColumns - 1}" ss:StyleID="categoryHeader">'
            '<Data ss:Type="String">${_xml(category.name)}</Data></Cell>')
        ..writeln('</Row>');

      // Data rows
      for (final item in category.items) {
        buf.writeln('<Row>');
        buf.writeln('<Cell ss:StyleID="text"><Data ss:Type="String">${_xml(item.brandName)}</Data></Cell>');
        buf.writeln('<Cell ss:StyleID="text"><Data ss:Type="String">${_xml(item.tpNo ?? '')}</Data></Cell>');
        _writeSizeQty(buf, item.openingBalance);
        _writeSizeQty(buf, item.purchase);
        _writeSizeQty(buf, item.sale);
        _writeSizeQty(buf, item.closingBalance);
        buf.writeln('</Row>');
      }

      // Subtotal row
      buf.writeln('<Row>');
      buf.writeln('<Cell ss:StyleID="total"><Data ss:Type="String">Total</Data></Cell>');
      buf.writeln('<Cell ss:StyleID="total"><Data ss:Type="String"></Data></Cell>');
      _writeSizeQtyBold(buf, category.subtotal.openingBalance);
      _writeSizeQtyBold(buf, category.subtotal.purchase);
      _writeSizeQtyBold(buf, category.subtotal.sale);
      _writeSizeQtyBold(buf, category.subtotal.closingBalance);
      buf.writeln('</Row>');
    }

    buf
      ..writeln('</Table>')
      ..writeln('</Worksheet>')
      ..writeln('</Workbook>');

    return buf.toString();
  }

  void _writeSizeQty(StringBuffer buf, BrandwiseSizeQty qty) {
    for (var i = 0; i < 7; i++) {
      final v = qty.byIndex(i);
      if (v == 0) {
        buf.writeln('<Cell ss:StyleID="number"><Data ss:Type="String"></Data></Cell>');
      } else {
        buf.writeln('<Cell ss:StyleID="number"><Data ss:Type="Number">$v</Data></Cell>');
      }
    }
  }

  void _writeSizeQtyBold(StringBuffer buf, BrandwiseSizeQty qty) {
    for (var i = 0; i < 7; i++) {
      final v = qty.byIndex(i);
      if (v == 0) {
        buf.writeln('<Cell ss:StyleID="totalNumber"><Data ss:Type="String"></Data></Cell>');
      } else {
        buf.writeln('<Cell ss:StyleID="totalNumber"><Data ss:Type="Number">$v</Data></Cell>');
      }
    }
  }

  String _dateStamp(DateTime value) =>
      '${value.year}${value.month.toString().padLeft(2, '0')}${value.day.toString().padLeft(2, '0')}';

  String _displayDate(DateTime value) {
    const months = [
      'JANUARY', 'FEBRUARY', 'MARCH', 'APRIL', 'MAY', 'JUNE',
      'JULY', 'AUGUST', 'SEPTEMBER', 'OCTOBER', 'NOVEMBER', 'DECEMBER',
    ];
    return '${value.day.toString().padLeft(2, '0')}-${months[value.month - 1]}-${value.year}';
  }

  String _xml(String input) => input
      .replaceAll('&', '&amp;')
      .replaceAll('<', '&lt;')
      .replaceAll('>', '&gt;')
      .replaceAll('"', '&quot;')
      .replaceAll("'", '&apos;');
}

const _stylesXml = '''
<Styles>
  <Style ss:ID="title">
    <Alignment ss:Horizontal="Center" ss:Vertical="Center"/>
    <Font ss:Bold="1" ss:Size="13"/>
    <Borders>
      <Border ss:Position="Bottom" ss:LineStyle="Continuous" ss:Weight="1"/>
      <Border ss:Position="Left" ss:LineStyle="Continuous" ss:Weight="1"/>
      <Border ss:Position="Right" ss:LineStyle="Continuous" ss:Weight="1"/>
      <Border ss:Position="Top" ss:LineStyle="Continuous" ss:Weight="1"/>
    </Borders>
  </Style>
  <Style ss:ID="dateRow">
    <Alignment ss:Horizontal="Left" ss:Vertical="Center"/>
    <Font ss:Bold="1" ss:Size="10"/>
    <Borders>
      <Border ss:Position="Bottom" ss:LineStyle="Continuous" ss:Weight="1"/>
      <Border ss:Position="Left" ss:LineStyle="Continuous" ss:Weight="1"/>
      <Border ss:Position="Right" ss:LineStyle="Continuous" ss:Weight="1"/>
      <Border ss:Position="Top" ss:LineStyle="Continuous" ss:Weight="1"/>
    </Borders>
  </Style>
  <Style ss:ID="header">
    <Alignment ss:Horizontal="Center" ss:Vertical="Center"/>
    <Font ss:Bold="1" ss:Size="9"/>
    <Interior ss:Color="#D9E1F2" ss:Pattern="Solid"/>
    <Borders>
      <Border ss:Position="Bottom" ss:LineStyle="Continuous" ss:Weight="1"/>
      <Border ss:Position="Left" ss:LineStyle="Continuous" ss:Weight="1"/>
      <Border ss:Position="Right" ss:LineStyle="Continuous" ss:Weight="1"/>
      <Border ss:Position="Top" ss:LineStyle="Continuous" ss:Weight="1"/>
    </Borders>
  </Style>
  <Style ss:ID="subHeader">
    <Alignment ss:Horizontal="Center" ss:Vertical="Center"/>
    <Font ss:Bold="1" ss:Size="8"/>
    <Interior ss:Color="#E2EFDA" ss:Pattern="Solid"/>
    <Borders>
      <Border ss:Position="Bottom" ss:LineStyle="Continuous" ss:Weight="1"/>
      <Border ss:Position="Left" ss:LineStyle="Continuous" ss:Weight="1"/>
      <Border ss:Position="Right" ss:LineStyle="Continuous" ss:Weight="1"/>
      <Border ss:Position="Top" ss:LineStyle="Continuous" ss:Weight="1"/>
    </Borders>
  </Style>
  <Style ss:ID="sizeHeader">
    <Alignment ss:Horizontal="Center" ss:Vertical="Center"/>
    <Font ss:Bold="1" ss:Size="7"/>
    <Interior ss:Color="#FFF2CC" ss:Pattern="Solid"/>
    <Borders>
      <Border ss:Position="Bottom" ss:LineStyle="Continuous" ss:Weight="1"/>
      <Border ss:Position="Left" ss:LineStyle="Continuous" ss:Weight="1"/>
      <Border ss:Position="Right" ss:LineStyle="Continuous" ss:Weight="1"/>
      <Border ss:Position="Top" ss:LineStyle="Continuous" ss:Weight="1"/>
    </Borders>
  </Style>
  <Style ss:ID="categoryHeader">
    <Alignment ss:Horizontal="Left" ss:Vertical="Center"/>
    <Font ss:Bold="1" ss:Size="10"/>
    <Interior ss:Color="#FCE4D6" ss:Pattern="Solid"/>
    <Borders>
      <Border ss:Position="Bottom" ss:LineStyle="Continuous" ss:Weight="1"/>
      <Border ss:Position="Left" ss:LineStyle="Continuous" ss:Weight="1"/>
      <Border ss:Position="Right" ss:LineStyle="Continuous" ss:Weight="1"/>
      <Border ss:Position="Top" ss:LineStyle="Continuous" ss:Weight="1"/>
    </Borders>
  </Style>
  <Style ss:ID="text">
    <Alignment ss:Vertical="Center"/>
    <Font ss:Size="8"/>
    <Borders>
      <Border ss:Position="Bottom" ss:LineStyle="Continuous" ss:Weight="1"/>
      <Border ss:Position="Left" ss:LineStyle="Continuous" ss:Weight="1"/>
      <Border ss:Position="Right" ss:LineStyle="Continuous" ss:Weight="1"/>
      <Border ss:Position="Top" ss:LineStyle="Continuous" ss:Weight="1"/>
    </Borders>
  </Style>
  <Style ss:ID="number">
    <Alignment ss:Horizontal="Right" ss:Vertical="Center"/>
    <Font ss:Size="8"/>
    <Borders>
      <Border ss:Position="Bottom" ss:LineStyle="Continuous" ss:Weight="1"/>
      <Border ss:Position="Left" ss:LineStyle="Continuous" ss:Weight="1"/>
      <Border ss:Position="Right" ss:LineStyle="Continuous" ss:Weight="1"/>
      <Border ss:Position="Top" ss:LineStyle="Continuous" ss:Weight="1"/>
    </Borders>
  </Style>
  <Style ss:ID="total">
    <Font ss:Bold="1" ss:Size="9"/>
    <Borders>
      <Border ss:Position="Bottom" ss:LineStyle="Continuous" ss:Weight="2"/>
      <Border ss:Position="Left" ss:LineStyle="Continuous" ss:Weight="1"/>
      <Border ss:Position="Right" ss:LineStyle="Continuous" ss:Weight="1"/>
      <Border ss:Position="Top" ss:LineStyle="Continuous" ss:Weight="1"/>
    </Borders>
  </Style>
  <Style ss:ID="totalNumber">
    <Alignment ss:Horizontal="Right" ss:Vertical="Center"/>
    <Font ss:Bold="1" ss:Size="9"/>
    <Borders>
      <Border ss:Position="Bottom" ss:LineStyle="Continuous" ss:Weight="2"/>
      <Border ss:Position="Left" ss:LineStyle="Continuous" ss:Weight="1"/>
      <Border ss:Position="Right" ss:LineStyle="Continuous" ss:Weight="1"/>
      <Border ss:Position="Top" ss:LineStyle="Continuous" ss:Weight="1"/>
    </Borders>
  </Style>
</Styles>
''';
