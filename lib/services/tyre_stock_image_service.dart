// ============================================================
// FILE: tyre_stock_image_service.dart
//
// PURPOSE:
// Generates a PNG image containing the complete Tyre Stock
// information stored in the SQLite database.
//
// IMAGE CONTENT:
// - Sri Guru Enterprises heading
// - Generated date and time
// - Franchise
// - Vehicle Type
// - Tyre
// - Pattern
// - Size
// - Stock
// - Sell Price
// - LLP
// - Total stock for each vehicle-type section
//
// GROUPING:
//
// Franchise
//   ├── 2 Wheeler
//   └── 4 Wheeler
//
// Supported franchises:
// - Cherry
// - Tyreplex
//
// Supported vehicle types:
// - 2 Wheeler
// - 4 Wheeler
//
// IMPORTANT:
// This service does NOT contain hard-coded stock values.
//
// The Tyre Stock List Screen supplies the actual records
// retrieved from SQLite.
//
// The generated image is saved as a PNG file in the
// application documents directory.
//
// The image can then be shared using the native Android
// Share Sheet through share_plus.
// ============================================================

import 'dart:io';
import 'dart:math' as math;
import 'dart:typed_data';
import 'dart:ui' as ui;

import 'package:flutter/material.dart';
import 'package:path/path.dart' as path;
import 'package:path_provider/path_provider.dart';
import 'package:share_plus/share_plus.dart';

import '../models/tyre_stock.dart';

// ============================================================
// TYRE STOCK IMAGE SERVICE
// ============================================================

class TyreStockImageService {
  // ============================================================
  // PRIVATE CONSTRUCTOR
  // ============================================================

  TyreStockImageService._();

  // ============================================================
  // SINGLETON INSTANCE
  //
  // PURPOSE:
  // Ensures that the application uses one image-generation
  // service instance.
  // ============================================================

  static final TyreStockImageService instance =
  TyreStockImageService._();

  // ============================================================
  // IMAGE WIDTH
  //
  // PURPOSE:
  // Creates a wide landscape image similar to the supplied
  // spreadsheet-style stock image.
  // ============================================================

  static const double _imageWidth = 1800;

  // ============================================================
  // IMAGE MARGINS
  // ============================================================

  static const double _leftMargin = 50;

  static const double _rightMargin = 50;

  static const double _topMargin = 45;

  static const double _bottomMargin = 50;

  // ============================================================
  // COLUMN WIDTHS
  //
  // PURPOSE:
  // Defines the width of each table column.
  // ============================================================

  static const double _tyreWidth = 210;

  static const double _patternWidth = 240;

  static const double _sizeWidth = 220;

  static const double _stockWidth = 130;

  static const double _sellPriceWidth = 180;

  static const double _llpWidth = 180;

  // ============================================================
  // ROW HEIGHTS
  // ============================================================

  static const double _titleHeight = 70;

  static const double _subTitleHeight = 48;

  static const double _headerHeight = 58;

  static const double _rowHeight = 54;

  static const double _totalHeight = 58;

  static const double _sectionSpacing = 35;

  // ============================================================
  // IMAGE COLORS
  //
  // PURPOSE:
  // Provides a spreadsheet-like appearance similar to the
  // reference image supplied by the user.
  // ============================================================

  static const Color _titleColor =
  Color(0xFF17365D);

  static const Color _headerColor =
  Color(0xFFFFFF00);

  static const Color _sectionColor =
  Color(0xFFD9EAD3);

  static const Color _borderColor =
  Color(0xFF666666);

  static const Color _stockColor =
  Color(0xFFE2F0D9);

  static const Color _zeroStockColor =
  Color(0xFFF4CCCC);

  // ============================================================
  // GENERATE IMAGE
  //
  // PURPOSE:
  // Generates a complete PNG image from the supplied Tyre Stock
  // records.
  //
  // IMPORTANT:
  // The records passed here should come directly from SQLite.
  //
  // RETURNS:
  // The generated PNG File.
  // ============================================================

  Future<File> generateImage({
    required List<TyreStock> stocks,
  }) async {
    // ----------------------------------------------------------
    // Get the application documents directory.
    // ----------------------------------------------------------

    final Directory applicationDirectory =
    await getApplicationDocumentsDirectory();

    // ----------------------------------------------------------
    // Create a dedicated directory for generated stock images.
    // ----------------------------------------------------------

    final Directory imageDirectory =
    Directory(
      path.join(
        applicationDirectory.path,
        'sri_guru_stock_images',
      ),
    );

    await imageDirectory.create(
      recursive: true,
    );

    // ----------------------------------------------------------
    // Calculate the required image height.
    //
    // The height depends on the number of stock records.
    // ----------------------------------------------------------

    final double imageHeight =
    _calculateImageHeight(
      stocks,
    );

    // ----------------------------------------------------------
    // Create the Flutter drawing recorder.
    // ----------------------------------------------------------

    final ui.PictureRecorder recorder =
    ui.PictureRecorder();

    final Canvas canvas =
    Canvas(recorder);

    // ----------------------------------------------------------
    // Draw the white background.
    // ----------------------------------------------------------

    final Paint backgroundPaint =
    Paint()
      ..color = Colors.white;

    canvas.drawRect(
      Rect.fromLTWH(
        0,
        0,
        _imageWidth,
        imageHeight,
      ),
      backgroundPaint,
    );

    // ----------------------------------------------------------
    // Draw application title.
    // ----------------------------------------------------------

    double currentY = _topMargin;

    currentY = _drawTitle(
      canvas,
      currentY,
    );

    // ----------------------------------------------------------
    // Sort the records.
    //
    // The sorting order is:
    //
    // 1. Cherry
    // 2. Tyreplex
    // 3. Vehicle Type
    // 4. Tyre
    // 5. Pattern
    // 6. Size
    // ----------------------------------------------------------

    final List<TyreStock> sortedStocks =
    List<TyreStock>.from(
      stocks,
    )..sort(
      _compareStocks,
    );

    // ----------------------------------------------------------
    // Group records by franchise.
    // ----------------------------------------------------------

    final Map<String, List<TyreStock>>
    franchiseGroups =
    <String, List<TyreStock>>{};

    for (final TyreStock stock
    in sortedStocks) {
      franchiseGroups
          .putIfAbsent(
        stock.franchise,
            () => <TyreStock>[],
      )
          .add(stock);
    }

    // ----------------------------------------------------------
    // Draw each franchise section.
    // ----------------------------------------------------------

    for (final MapEntry<String, List<TyreStock>>
    franchiseEntry
    in franchiseGroups.entries) {
      currentY += _sectionSpacing;

      currentY =
          _drawFranchiseSection(
            canvas,
            franchise:
            franchiseEntry.key,
            stocks:
            franchiseEntry.value,
            startY: currentY,
          );
    }

    // ----------------------------------------------------------
    // Finish the drawing.
    // ----------------------------------------------------------

    final ui.Picture picture =
    recorder.endRecording();

    final ui.Image image =
    await picture.toImage(
      _imageWidth.toInt(),
      imageHeight.ceil(),
    );

    // ----------------------------------------------------------
    // Convert the image to PNG.
    // ----------------------------------------------------------

    final ByteData? byteData =
    await image.toByteData(
      format:
      ui.ImageByteFormat.png,
    );

    // ----------------------------------------------------------
    // Release the image resource.
    // ----------------------------------------------------------

    image.dispose();

    if (byteData == null) {
      picture.dispose();

      throw const TyreStockImageException(
        'Unable to create stock image.',
      );
    }

    picture.dispose();

    // ----------------------------------------------------------
    // Create a timestamped file name.
    // ----------------------------------------------------------

    final String timestamp =
    _formatTimestamp(
      DateTime.now(),
    );

    final String fileName =
        'sri_guru_tyre_stock_$timestamp.png';

    // ----------------------------------------------------------
    // Create the final image file.
    // ----------------------------------------------------------

    final File imageFile =
    File(
      path.join(
        imageDirectory.path,
        fileName,
      ),
    );

    // ----------------------------------------------------------
    // Write PNG bytes to the file.
    // ----------------------------------------------------------

    await imageFile.writeAsBytes(
      byteData.buffer.asUint8List(
        byteData.offsetInBytes,
        byteData.lengthInBytes,
      ),
      flush: true,
    );

    return imageFile;
  }

  // ============================================================
  // SHARE IMAGE
  //
  // PURPOSE:
  // Opens the native Android Share Sheet.
  //
  // EXAMPLES OF APPS THAT MAY APPEAR:
  // - WhatsApp
  // - Gmail
  // - Google Drive
  // - Bluetooth
  // - Quick Share
  // - Other compatible applications
  //
  // The actual applications displayed depend on the apps
  // installed on the Android device.
  // ============================================================

  Future<void> shareImage(
      File imageFile,
      ) async {
    // ----------------------------------------------------------
    // Verify that the generated image exists.
    // ----------------------------------------------------------

    final bool exists =
    await imageFile.exists();

    if (!exists) {
      throw const TyreStockImageException(
        'Stock image was not found.',
      );
    }

    // ----------------------------------------------------------
    // Open the native Android Share Sheet.
    // ----------------------------------------------------------

    await SharePlus.instance.share(
      ShareParams(
        title:
        'Sri Guru Enterprises - Tyre Stock',
        text:
        'Sri Guru Enterprises Tyre Stock',
        files: <XFile>[
          XFile(
            imageFile.path,
            mimeType: 'image/png',
          ),
        ],
      ),
    );
  }

  // ============================================================
  // CALCULATE IMAGE HEIGHT
  //
  // PURPOSE:
  // Calculates enough vertical space for all franchise and
  // vehicle-type sections.
  // ============================================================

  double _calculateImageHeight(
      List<TyreStock> stocks,
      ) {
    // ----------------------------------------------------------
    // Minimum image height when there are no records.
    // ----------------------------------------------------------

    if (stocks.isEmpty) {
      return 400;
    }

    // ----------------------------------------------------------
    // Group records by franchise.
    // ----------------------------------------------------------

    final Map<String, List<TyreStock>>
    franchiseGroups =
    <String, List<TyreStock>>{};

    for (final TyreStock stock
    in stocks) {
      franchiseGroups
          .putIfAbsent(
        stock.franchise,
            () => <TyreStock>[],
      )
          .add(stock);
    }

    // ----------------------------------------------------------
    // Start with title area.
    // ----------------------------------------------------------

    double height =
        _topMargin +
            _titleHeight +
            _subTitleHeight +
            35;

    // ----------------------------------------------------------
    // Calculate each franchise section.
    // ----------------------------------------------------------

    for (final List<TyreStock>
    franchiseStocks
    in franchiseGroups.values) {
      // --------------------------------------------------------
      // Franchise heading.
      // --------------------------------------------------------

      height +=
          _sectionSpacing +
              58;

      // --------------------------------------------------------
      // Group by vehicle type.
      // --------------------------------------------------------

      final Map<String, List<TyreStock>>
      vehicleGroups =
      _groupByVehicleType(
        franchiseStocks,
      );

      // --------------------------------------------------------
      // Calculate each vehicle section.
      // --------------------------------------------------------

      for (final List<TyreStock>
      vehicleStocks
      in vehicleGroups.values) {
        // Vehicle type heading.
        height += 52;

        // Table header.
        height +=
            _headerHeight;

        // Data rows.
        height +=
            vehicleStocks.length *
                _rowHeight;

        // Total row.
        height +=
            _totalHeight;

        // Space after table.
        height += 25;
      }
    }

    // ----------------------------------------------------------
    // Bottom margin.
    // ----------------------------------------------------------

    height +=
        _bottomMargin;

    return math.max(
      height,
      400,
    );
  }

  // ============================================================
  // DRAW TITLE
  //
  // PURPOSE:
  // Draws the main heading and generation date.
  // ============================================================

  double _drawTitle(
      Canvas canvas,
      double startY,
      ) {
    double currentY =
        startY;

    // ----------------------------------------------------------
    // MAIN BUSINESS NAME
    // ----------------------------------------------------------

    _drawText(
      canvas,
      text:
      'SRI GURU ENTERPRISES',
      x:
      _leftMargin,
      y:
      currentY,
      width:
      _imageWidth -
          _leftMargin -
          _rightMargin,
      height:
      _titleHeight,
      fontSize: 36,
      fontWeight:
      FontWeight.bold,
      color:
      _titleColor,
      align:
      TextAlign.center,
      verticalCenter:
      true,
    );

    currentY +=
        _titleHeight;

    // ----------------------------------------------------------
    // REPORT TITLE
    // ----------------------------------------------------------

    _drawText(
      canvas,
      text:
      'TYRE STOCK',
      x:
      _leftMargin,
      y:
      currentY,
      width:
      _imageWidth -
          _leftMargin -
          _rightMargin,
      height:
      _subTitleHeight,
      fontSize: 24,
      fontWeight:
      FontWeight.bold,
      color:
      Colors.black,
      align:
      TextAlign.center,
      verticalCenter:
      true,
    );

    currentY +=
        _subTitleHeight;

    // ----------------------------------------------------------
    // GENERATION DATE
    // ----------------------------------------------------------

    final DateTime now =
    DateTime.now();

    final String dateText =
        'Generated: '
        '${_twoDigits(now.day)}/'
        '${_twoDigits(now.month)}/'
        '${now.year} '
        '${_twoDigits(now.hour)}:'
        '${_twoDigits(now.minute)}';

    _drawText(
      canvas,
      text:
      dateText,
      x:
      _leftMargin,
      y:
      currentY,
      width:
      _imageWidth -
          _leftMargin -
          _rightMargin,
      height: 35,
      fontSize: 16,
      color:
      Colors.black54,
      align:
      TextAlign.center,
      verticalCenter:
      true,
    );

    currentY += 35;

    return currentY;
  }

  // ============================================================
  // DRAW FRANCHISE SECTION
  //
  // PURPOSE:
  // Draws one franchise such as Cherry or Tyreplex.
  // ============================================================

  double _drawFranchiseSection(
      Canvas canvas, {
        required String franchise,
        required List<TyreStock> stocks,
        required double startY,
      }) {
    double currentY =
        startY;

    // ----------------------------------------------------------
    // FRANCHISE HEADING
    // ----------------------------------------------------------

    _drawFilledCell(
      canvas,
      x:
      _leftMargin,
      y:
      currentY,
      width:
      _imageWidth -
          _leftMargin -
          _rightMargin,
      height: 58,
      color:
      _sectionColor,
      borderColor:
      _borderColor,
    );

    _drawText(
      canvas,
      text:
      franchise,
      x:
      _leftMargin + 16,
      y:
      currentY,
      width:
      _imageWidth -
          _leftMargin -
          _rightMargin -
          32,
      height: 58,
      fontSize: 25,
      fontWeight:
      FontWeight.bold,
      color:
      Colors.black,
      verticalCenter:
      true,
    );

    currentY += 58;

    // ----------------------------------------------------------
    // GROUP BY VEHICLE TYPE
    // ----------------------------------------------------------

    final Map<String, List<TyreStock>>
    vehicleGroups =
    _groupByVehicleType(
      stocks,
    );

    // ----------------------------------------------------------
    // DRAW EACH VEHICLE TYPE
    // ----------------------------------------------------------

    for (final MapEntry<String, List<TyreStock>>
    vehicleEntry
    in vehicleGroups.entries) {
      // --------------------------------------------------------
      // Space before vehicle type.
      // --------------------------------------------------------

      currentY += 25;

      // --------------------------------------------------------
      // VEHICLE TYPE TITLE
      // --------------------------------------------------------

      _drawText(
        canvas,
        text:
        vehicleEntry.key,
        x:
        _leftMargin,
        y:
        currentY,
        width:
        _imageWidth -
            _leftMargin -
            _rightMargin,
        height: 52,
        fontSize: 22,
        fontWeight:
        FontWeight.bold,
        color:
        _titleColor,
        verticalCenter:
        true,
      );

      currentY += 52;

      // --------------------------------------------------------
      // VEHICLE TYPE TABLE
      // --------------------------------------------------------

      currentY =
          _drawVehicleTable(
            canvas,
            stocks:
            vehicleEntry.value,
            startY:
            currentY,
          );

      currentY += 25;
    }

    return currentY;
  }

  // ============================================================
  // DRAW VEHICLE TABLE
  //
  // PURPOSE:
  // Draws the stock table for one vehicle type.
  // ============================================================

  double _drawVehicleTable(
      Canvas canvas, {
        required List<TyreStock> stocks,
        required double startY,
      }) {
    double currentY =
        startY;

    final double tableX =
        _leftMargin;

    // ----------------------------------------------------------
    // COLUMN DEFINITIONS
    // ----------------------------------------------------------

    const List<_ColumnDefinition>
    columns =
    <_ColumnDefinition>[
      _ColumnDefinition(
        title: 'Tyre',
        width: _tyreWidth,
      ),
      _ColumnDefinition(
        title: 'Pattern',
        width: _patternWidth,
      ),
      _ColumnDefinition(
        title: 'Size',
        width: _sizeWidth,
      ),
      _ColumnDefinition(
        title: 'Stock',
        width: _stockWidth,
      ),
      _ColumnDefinition(
        title: 'Sell Price',
        width: _sellPriceWidth,
      ),
      _ColumnDefinition(
        title: 'LLP',
        width: _llpWidth,
      ),
    ];

    // ----------------------------------------------------------
    // DRAW HEADER
    // ----------------------------------------------------------

    double currentX =
        tableX;

    for (final _ColumnDefinition
    column
    in columns) {
      _drawFilledCell(
        canvas,
        x:
        currentX,
        y:
        currentY,
        width:
        column.width,
        height:
        _headerHeight,
        color:
        _headerColor,
        borderColor:
        _borderColor,
      );

      _drawText(
        canvas,
        text:
        column.title,
        x:
        currentX + 8,
        y:
        currentY,
        width:
        column.width - 16,
        height:
        _headerHeight,
        fontSize: 18,
        fontWeight:
        FontWeight.bold,
        color:
        Colors.black,
        verticalCenter:
        true,
      );

      currentX +=
          column.width;
    }

    currentY +=
        _headerHeight;

    // ----------------------------------------------------------
    // SORT ROWS
    // ----------------------------------------------------------

    final List<TyreStock>
    sortedRows =
    List<TyreStock>.from(
      stocks,
    )..sort(
          (
          TyreStock a,
          TyreStock b,
          ) {
        final int tyreResult =
        a.tyre.compareTo(
          b.tyre,
        );

        if (tyreResult != 0) {
          return tyreResult;
        }

        final int patternResult =
        a.pattern.compareTo(
          b.pattern,
        );

        if (patternResult != 0) {
          return patternResult;
        }

        return a.size.compareTo(
          b.size,
        );
      },
    );

    // ----------------------------------------------------------
    // DRAW EACH STOCK ROW
    // ----------------------------------------------------------

    for (final TyreStock stock
    in sortedRows) {
      currentX =
          tableX;

      // --------------------------------------------------------
      // Zero stock rows are highlighted.
      // --------------------------------------------------------

      final Color rowColor =
      stock.stock <= 0
          ? _zeroStockColor
          : Colors.white;

      // --------------------------------------------------------
      // Values displayed in the table.
      // --------------------------------------------------------

      final List<String> values =
      <String>[
        stock.tyre,
        stock.pattern,
        stock.size,
        stock.stock.toString(),
        _formatAmount(
          stock.sellPrice,
        ),
        _formatAmount(
          stock.llp,
        ),
      ];

      // --------------------------------------------------------
      // Draw every cell in the row.
      // --------------------------------------------------------

      for (int index = 0;
      index < columns.length;
      index++) {
        final _ColumnDefinition
        column =
        columns[index];

        _drawFilledCell(
          canvas,
          x:
          currentX,
          y:
          currentY,
          width:
          column.width,
          height:
          _rowHeight,
          color:
          rowColor,
          borderColor:
          _borderColor,
        );

        // ------------------------------------------------------
        // Numeric columns are right aligned.
        // ------------------------------------------------------

        final bool isNumber =
            index >= 3;

        _drawText(
          canvas,
          text:
          values[index],
          x:
          currentX + 8,
          y:
          currentY,
          width:
          column.width - 16,
          height:
          _rowHeight,
          fontSize: 17,
          fontWeight:
          index == 0
              ? FontWeight.bold
              : FontWeight.normal,
          color:
          Colors.black,
          align:
          isNumber
              ? TextAlign.right
              : TextAlign.left,
          verticalCenter:
          true,
        );

        currentX +=
            column.width;
      }

      currentY +=
          _rowHeight;
    }

    // ----------------------------------------------------------
    // CALCULATE TOTAL STOCK
    // ----------------------------------------------------------

    final int totalStock =
    sortedRows.fold(
      0,
          (
          int total,
          TyreStock stock,
          ) {
        return total + stock.stock;
      },
    );

    // ----------------------------------------------------------
    // TOTAL ROW
    // ----------------------------------------------------------

    final double totalTableWidth =
    columns.fold(
      0,
          (
          double total,
          _ColumnDefinition column,
          ) {
        return total + column.width;
      },
    );

    _drawFilledCell(
      canvas,
      x:
      tableX,
      y:
      currentY,
      width:
      totalTableWidth,
      height:
      _totalHeight,
      color:
      _stockColor,
      borderColor:
      _borderColor,
    );

    // ----------------------------------------------------------
    // TOTAL LABEL
    // ----------------------------------------------------------

    _drawText(
      canvas,
      text:
      'TOTAL STOCK',
      x:
      tableX + 12,
      y:
      currentY,
      width:
      totalTableWidth - 180,
      height:
      _totalHeight,
      fontSize: 18,
      fontWeight:
      FontWeight.bold,
      color:
      Colors.black,
      verticalCenter:
      true,
    );

    // ----------------------------------------------------------
    // TOTAL VALUE
    // ----------------------------------------------------------

    _drawText(
      canvas,
      text:
      totalStock.toString(),
      x:
      tableX +
          totalTableWidth -
          150,
      y:
      currentY,
      width: 125,
      height:
      _totalHeight,
      fontSize: 20,
      fontWeight:
      FontWeight.bold,
      color:
      Colors.black,
      align:
      TextAlign.right,
      verticalCenter:
      true,
    );

    currentY +=
        _totalHeight;

    return currentY;
  }

  // ============================================================
  // GROUP BY VEHICLE TYPE
  //
  // PURPOSE:
  // Separates 2 Wheeler and 4 Wheeler stock.
  //
  // ORDER:
  // 1. 2 Wheeler
  // 2. 4 Wheeler
  // ============================================================

  Map<String, List<TyreStock>>
  _groupByVehicleType(
      List<TyreStock> stocks,
      ) {
    final Map<String, List<TyreStock>>
    groups =
    <String, List<TyreStock>>{};

    for (final TyreStock stock
    in stocks) {
      groups
          .putIfAbsent(
        stock.vehicleType,
            () => <TyreStock>[],
      )
          .add(stock);
    }

    // ----------------------------------------------------------
    // Preferred vehicle-type order.
    // ----------------------------------------------------------

    const List<String>
    vehicleTypeOrder =
    <String>[
      '2 Wheeler',
      '4 Wheeler',
    ];

    final List<String> keys =
    groups.keys.toList();

    keys.sort(
          (
          String a,
          String b,
          ) {
        final int aIndex =
        vehicleTypeOrder.indexOf(
          a,
        );

        final int bIndex =
        vehicleTypeOrder.indexOf(
          b,
        );

        // ------------------------------------------------------
        // Both are unexpected values.
        // ------------------------------------------------------

        if (aIndex == -1 &&
            bIndex == -1) {
          return a.compareTo(b);
        }

        // ------------------------------------------------------
        // Unknown values go to the end.
        // ------------------------------------------------------

        if (aIndex == -1) {
          return 1;
        }

        if (bIndex == -1) {
          return -1;
        }

        return aIndex.compareTo(
          bIndex,
        );
      },
    );

    // ----------------------------------------------------------
    // Create ordered map.
    // ----------------------------------------------------------

    final Map<String, List<TyreStock>>
    ordered =
    <String, List<TyreStock>>{};

    for (final String key
    in keys) {
      ordered[key] =
      groups[key]!;
    }

    return ordered;
  }

  // ============================================================
  // SORT STOCKS
  //
  // PURPOSE:
  // Provides a consistent order for the generated image.
  // ============================================================

  int _compareStocks(
      TyreStock a,
      TyreStock b,
      ) {
    // ----------------------------------------------------------
    // Franchise order.
    // ----------------------------------------------------------

    const List<String>
    franchiseOrder =
    <String>[
      'Cherry',
      'Tyreplex',
    ];

    final int aIndex =
    franchiseOrder.indexOf(
      a.franchise,
    );

    final int bIndex =
    franchiseOrder.indexOf(
      b.franchise,
    );

    if (aIndex != bIndex) {
      if (aIndex == -1) {
        return 1;
      }

      if (bIndex == -1) {
        return -1;
      }

      return aIndex.compareTo(
        bIndex,
      );
    }

    // ----------------------------------------------------------
    // Vehicle type.
    // ----------------------------------------------------------

    const List<String>
    vehicleTypeOrder =
    <String>[
      '2 Wheeler',
      '4 Wheeler',
    ];

    final int aVehicleIndex =
    vehicleTypeOrder.indexOf(
      a.vehicleType,
    );

    final int bVehicleIndex =
    vehicleTypeOrder.indexOf(
      b.vehicleType,
    );

    if (aVehicleIndex !=
        bVehicleIndex) {
      if (aVehicleIndex == -1) {
        return 1;
      }

      if (bVehicleIndex == -1) {
        return -1;
      }

      return aVehicleIndex.compareTo(
        bVehicleIndex,
      );
    }

    // ----------------------------------------------------------
    // Tyre.
    // ----------------------------------------------------------

    final int tyreResult =
    a.tyre.compareTo(
      b.tyre,
    );

    if (tyreResult != 0) {
      return tyreResult;
    }

    // ----------------------------------------------------------
    // Pattern.
    // ----------------------------------------------------------

    final int patternResult =
    a.pattern.compareTo(
      b.pattern,
    );

    if (patternResult != 0) {
      return patternResult;
    }

    // ----------------------------------------------------------
    // Size.
    // ----------------------------------------------------------

    return a.size.compareTo(
      b.size,
    );
  }

  // ============================================================
  // DRAW FILLED CELL
  //
  // PURPOSE:
  // Draws the background and border of a table cell.
  // ============================================================

  void _drawFilledCell(
      Canvas canvas, {
        required double x,
        required double y,
        required double width,
        required double height,
        required Color color,
        required Color borderColor,
      }) {
    // ----------------------------------------------------------
    // Cell background.
    // ----------------------------------------------------------

    final Paint fillPaint =
    Paint()
      ..color = color;

    canvas.drawRect(
      Rect.fromLTWH(
        x,
        y,
        width,
        height,
      ),
      fillPaint,
    );

    // ----------------------------------------------------------
    // Cell border.
    // ----------------------------------------------------------

    final Paint borderPaint =
    Paint()
      ..color = borderColor
      ..style =
          PaintingStyle.stroke
      ..strokeWidth = 1;

    canvas.drawRect(
      Rect.fromLTWH(
        x,
        y,
        width,
        height,
      ),
      borderPaint,
    );
  }

  // ============================================================
  // DRAW TEXT
  //
  // PURPOSE:
  // Draws text inside a table cell.
  // ============================================================

  void _drawText(
      Canvas canvas, {
        required String text,
        required double x,
        required double y,
        required double width,
        required double height,
        double fontSize = 16,
        FontWeight fontWeight =
            FontWeight.normal,
        Color color = Colors.black,
        TextAlign align =
            TextAlign.left,
        bool verticalCenter = false,
      }) {
    // ----------------------------------------------------------
    // Create text painter.
    // ----------------------------------------------------------

    final TextPainter painter =
    TextPainter(
      text: TextSpan(
        text: text,
        style: TextStyle(
          fontSize: fontSize,
          fontWeight:
          fontWeight,
          color: color,
        ),
      ),
      textAlign: align,
      textDirection:
      TextDirection.ltr,
      maxLines: 2,
      ellipsis: '...',
    );

    // ----------------------------------------------------------
    // Calculate text size.
    // ----------------------------------------------------------

    painter.layout(
      maxWidth: width,
    );

    // ----------------------------------------------------------
    // Calculate vertical position.
    // ----------------------------------------------------------

    double textY = y;

    if (verticalCenter) {
      textY =
          y +
              (height -
                  painter.height) /
                  2;
    }

    // ----------------------------------------------------------
    // Draw text.
    // ----------------------------------------------------------

    painter.paint(
      canvas,
      Offset(
        x,
        textY,
      ),
    );
  }

  // ============================================================
  // FORMAT AMOUNT
  //
  // PURPOSE:
  // Removes unnecessary decimal places from whole numbers.
  //
  // Example:
  // 4200.00 -> 4200
  // 4200.50 -> 4200.50
  // ============================================================

  String _formatAmount(
      double value,
      ) {
    if (value ==
        value.roundToDouble()) {
      return value.toStringAsFixed(
        0,
      );
    }

    return value.toStringAsFixed(
      2,
    );
  }

  // ============================================================
  // FORMAT TIMESTAMP
  //
  // PURPOSE:
  // Creates a file-safe timestamp.
  // ============================================================

  String _formatTimestamp(
      DateTime dateTime,
      ) {
    return '${dateTime.year}_'
        '${_twoDigits(dateTime.month)}_'
        '${_twoDigits(dateTime.day)}_'
        '${_twoDigits(dateTime.hour)}_'
        '${_twoDigits(dateTime.minute)}_'
        '${_twoDigits(dateTime.second)}';
  }

  // ============================================================
  // TWO DIGIT NUMBER
  // ============================================================

  String _twoDigits(
      int value,
      ) {
    return value
        .toString()
        .padLeft(
      2,
      '0',
    );
  }
}

// ============================================================
// COLUMN DEFINITION
//
// PURPOSE:
// Stores the title and width of one table column.
// ============================================================

class _ColumnDefinition {
  const _ColumnDefinition({
    required this.title,
    required this.width,
  });

  final String title;

  final double width;
}

// ============================================================
// TYRE STOCK IMAGE EXCEPTION
//
// PURPOSE:
// Represents an error related to stock-image generation.
// ============================================================

class TyreStockImageException
    implements Exception {
  const TyreStockImageException(
      this.message,
      );

  final String message;

  @override
  String toString() {
    return 'TyreStockImageException: '
        '$message';
  }
}