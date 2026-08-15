import 'dart:io';

import 'models/sales_report_dto.dart';

class ReportExcelExporter {
  Future<File> exportDailySalesReport(SalesReportDto report) async {
    final outputDir = await _resolveOutputDirectory();
    await outputDir.create(recursive: true);

    final fileName = _buildFileName(report);
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

  String _buildFileName(SalesReportDto report) {
    final from = _dateStamp(report.fromDate);
    final to = _dateStamp(report.toDate);
    final suffix = from == to ? from : '${from}_to_$to';
    return 'daily_sale_report_$suffix.xls';
  }

  String _buildWorkbook(SalesReportDto report) {
    final buffer = StringBuffer()
      ..writeln('<?xml version="1.0"?>')
      ..writeln('<?mso-application progid="Excel.Sheet"?>')
      ..writeln('<Workbook xmlns="urn:schemas-microsoft-com:office:spreadsheet"')
      ..writeln(' xmlns:o="urn:schemas-microsoft-com:office:office"')
      ..writeln(' xmlns:x="urn:schemas-microsoft-com:office:excel"')
      ..writeln(' xmlns:ss="urn:schemas-microsoft-com:office:spreadsheet"')
      ..writeln(' xmlns:html="http://www.w3.org/TR/REC-html40">')
      ..writeln(_stylesXml)
      ..writeln('<Worksheet ss:Name="DailySaleReport">')
      ..writeln('<Table>');

    const columnWidths = [90, 130, 250, 90, 95, 130];
    for (final width in columnWidths) {
      buffer.writeln('<Column ss:Width="$width"/>');
    }

    final title = report.fromDate.year == report.toDate.year &&
            report.fromDate.month == report.toDate.month &&
            report.fromDate.day == report.toDate.day
        ? 'Daily Sale Report - ${_displayDate(report.fromDate)}'
        : 'Daily Sale Report - ${_displayDate(report.fromDate)} to ${_displayDate(report.toDate)}';

    buffer
      ..writeln('<Row ss:Height="22">')
      ..writeln('<Cell ss:MergeAcross="5" ss:StyleID="title"><Data ss:Type="String">${_xml(title)}</Data></Cell>')
      ..writeln('</Row>')
      ..writeln('<Row ss:Height="20">')
      ..writeln('<Cell ss:StyleID="header"><Data ss:Type="String">Sale Date</Data></Cell>')
      ..writeln('<Cell ss:StyleID="header"><Data ss:Type="String">Local Item Code</Data></Cell>')
      ..writeln('<Cell ss:StyleID="header"><Data ss:Type="String">Brand Name</Data></Cell>')
      ..writeln('<Cell ss:StyleID="header"><Data ss:Type="String">Size</Data></Cell>')
      ..writeln('<Cell ss:StyleID="header"><Data ss:Type="String">Quantity(Case)</Data></Cell>')
      ..writeln('<Cell ss:StyleID="header"><Data ss:Type="String">Quantity(Loose Bottle)</Data></Cell>')
      ..writeln('</Row>');

    final saleDateLabel = report.fromDate == report.toDate
        ? _slashDate(report.fromDate)
        : '${_slashDate(report.fromDate)} to ${_slashDate(report.toDate)}';

    for (final item in report.items) {
      buffer
        ..writeln('<Row>')
        ..writeln('<Cell ss:StyleID="text"><Data ss:Type="String">${_xml(saleDateLabel)}</Data></Cell>')
        ..writeln('<Cell ss:StyleID="text"><Data ss:Type="String">${_xml(item.materialId)}</Data></Cell>')
        ..writeln('<Cell ss:StyleID="text"><Data ss:Type="String">${_xml(item.materialName)}</Data></Cell>')
        ..writeln('<Cell ss:StyleID="text"><Data ss:Type="String">${_xml(item.packing ?? '')}</Data></Cell>')
        ..writeln('<Cell ss:StyleID="number"><Data ss:Type="Number">${item.qtyCase}</Data></Cell>')
        ..writeln('<Cell ss:StyleID="number"><Data ss:Type="Number">${item.qtyLoose}</Data></Cell>')
        ..writeln('</Row>');
    }

    buffer
      ..writeln('<Row>')
      ..writeln('<Cell ss:StyleID="total"><Data ss:Type="String"></Data></Cell>')
      ..writeln('<Cell ss:StyleID="total"><Data ss:Type="String"></Data></Cell>')
      ..writeln('<Cell ss:StyleID="total"><Data ss:Type="String">Total</Data></Cell>')
      ..writeln('<Cell ss:StyleID="total"><Data ss:Type="String"></Data></Cell>')
      ..writeln('<Cell ss:StyleID="totalNumber"><Data ss:Type="Number">${report.totalQtyCase}</Data></Cell>')
      ..writeln('<Cell ss:StyleID="totalNumber"><Data ss:Type="Number">${report.totalQtyLoose}</Data></Cell>')
      ..writeln('</Row>')
      ..writeln('</Table>')
      ..writeln('</Worksheet>')
      ..writeln('</Workbook>');

    return buffer.toString();
  }

  String _dateStamp(DateTime value) =>
      '${value.year}${value.month.toString().padLeft(2, '0')}${value.day.toString().padLeft(2, '0')}';

  String _displayDate(DateTime value) =>
      '${value.day.toString().padLeft(2, '0')}-${value.month.toString().padLeft(2, '0')}-${value.year}';

  String _slashDate(DateTime value) =>
      '${value.month.toString().padLeft(2, '0')}/${value.day.toString().padLeft(2, '0')}/${value.year}';

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
    <Font ss:Bold="1" ss:Size="12"/>
    <Borders>
      <Border ss:Position="Bottom" ss:LineStyle="Continuous" ss:Weight="1"/>
      <Border ss:Position="Left" ss:LineStyle="Continuous" ss:Weight="1"/>
      <Border ss:Position="Right" ss:LineStyle="Continuous" ss:Weight="1"/>
      <Border ss:Position="Top" ss:LineStyle="Continuous" ss:Weight="1"/>
    </Borders>
  </Style>
  <Style ss:ID="header">
    <Alignment ss:Horizontal="Center" ss:Vertical="Center"/>
    <Font ss:Bold="1"/>
    <Interior ss:Color="#F7E08B" ss:Pattern="Solid"/>
    <Borders>
      <Border ss:Position="Bottom" ss:LineStyle="Continuous" ss:Weight="1"/>
      <Border ss:Position="Left" ss:LineStyle="Continuous" ss:Weight="1"/>
      <Border ss:Position="Right" ss:LineStyle="Continuous" ss:Weight="1"/>
      <Border ss:Position="Top" ss:LineStyle="Continuous" ss:Weight="1"/>
    </Borders>
  </Style>
  <Style ss:ID="text">
    <Alignment ss:Vertical="Center"/>
    <Borders>
      <Border ss:Position="Bottom" ss:LineStyle="Continuous" ss:Weight="1"/>
      <Border ss:Position="Left" ss:LineStyle="Continuous" ss:Weight="1"/>
      <Border ss:Position="Right" ss:LineStyle="Continuous" ss:Weight="1"/>
      <Border ss:Position="Top" ss:LineStyle="Continuous" ss:Weight="1"/>
    </Borders>
  </Style>
  <Style ss:ID="number">
    <Alignment ss:Horizontal="Right" ss:Vertical="Center"/>
    <Borders>
      <Border ss:Position="Bottom" ss:LineStyle="Continuous" ss:Weight="1"/>
      <Border ss:Position="Left" ss:LineStyle="Continuous" ss:Weight="1"/>
      <Border ss:Position="Right" ss:LineStyle="Continuous" ss:Weight="1"/>
      <Border ss:Position="Top" ss:LineStyle="Continuous" ss:Weight="1"/>
    </Borders>
  </Style>
  <Style ss:ID="total">
    <Font ss:Bold="1"/>
    <Borders>
      <Border ss:Position="Bottom" ss:LineStyle="Continuous" ss:Weight="1"/>
      <Border ss:Position="Left" ss:LineStyle="Continuous" ss:Weight="1"/>
      <Border ss:Position="Right" ss:LineStyle="Continuous" ss:Weight="1"/>
      <Border ss:Position="Top" ss:LineStyle="Continuous" ss:Weight="1"/>
    </Borders>
  </Style>
  <Style ss:ID="totalNumber">
    <Alignment ss:Horizontal="Right" ss:Vertical="Center"/>
    <Font ss:Bold="1"/>
    <Borders>
      <Border ss:Position="Bottom" ss:LineStyle="Continuous" ss:Weight="1"/>
      <Border ss:Position="Left" ss:LineStyle="Continuous" ss:Weight="1"/>
      <Border ss:Position="Right" ss:LineStyle="Continuous" ss:Weight="1"/>
      <Border ss:Position="Top" ss:LineStyle="Continuous" ss:Weight="1"/>
    </Borders>
  </Style>
</Styles>
''';
