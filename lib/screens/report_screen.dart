// ****************************************************************************
// FILE        : report_screen.dart
// PROJECT     : Sri Guru Enterprises
// DESCRIPTION : Report dashboard with date filtering and PDF/Excel export.
//
// REPORT MODULES:
// 1. Customers
// 2. Fleet Services
// 3. Emission Tests
// 4. Car Documents
// 5. Accessories
// 6. Tyre Stock
// 7. Tyre Billing
// 8. Alignment Billing
// ****************************************************************************

import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

import '../models/report_data.dart';
import '../repositories/report_repository.dart';
import '../services/excel_export_service.dart';
import '../services/pdf_export_service.dart';
import '../services/report_date_filter_service.dart';

/// Displays filtered enterprise reports and provides PDF/Excel export.
class ReportScreen extends StatefulWidget {
  const ReportScreen({super.key});

  @override
  State<ReportScreen> createState() => _ReportScreenState();
}

class _ReportScreenState extends State<ReportScreen> {
  // ---------------------------------------------------------------------------
  // REPOSITORY
  // ---------------------------------------------------------------------------

  final ReportRepository _repository = ReportRepository();

  // ---------------------------------------------------------------------------
  // REPORT FILTER STATE
  // ---------------------------------------------------------------------------

  ReportDateFilter _selectedFilter =
      ReportDateFilter.daily;

  DateTime _selectedDate =
  DateTime.now();

  DateTime? _customFrom;
  DateTime? _customTo;

  // ---------------------------------------------------------------------------
  // REPORT DATA
  // ---------------------------------------------------------------------------

  ReportDateRange? _dateRange;
  ReportData? _reportData;

  // ---------------------------------------------------------------------------
  // LOADING STATE
  // ---------------------------------------------------------------------------

  bool _isLoading = false;
  bool _isExporting = false;

  // ---------------------------------------------------------------------------
  // DATE FORMAT
  // ---------------------------------------------------------------------------

  final DateFormat _displayDateFormat =
  DateFormat('dd/MM/yyyy');

  // ===========================================================================
  // INITIALIZATION
  // ===========================================================================

  @override
  void initState() {
    super.initState();

    // Load the default Daily report.
    _loadReport();
  }

  // ===========================================================================
  // REPORT LOADING
  // ===========================================================================

  Future<void> _loadReport() async {
    // Prevent overlapping report loads.
    if (_isLoading) {
      return;
    }

    setState(() {
      _isLoading = true;
    });

    try {
      // Calculate the selected report period.
      final ReportDateRange range =
      ReportDateFilterService.getDateRange(
        filter: _selectedFilter,
        selectedDate: _selectedDate,
        customFrom: _customFrom,
        customTo: _customTo,
      );

      // Read report data from SQLite.
      final ReportData data =
      await _repository.getReportData(
        dateRange: range,
      );

      if (!mounted) {
        return;
      }

      setState(() {
        _dateRange = range;
        _reportData = data;
        _isLoading = false;
      });
    } catch (error) {
      if (!mounted) {
        return;
      }

      setState(() {
        _isLoading = false;
      });

      _showMessage(
        'Unable to load report: $error',
        isError: true,
      );
    }
  }

  // ===========================================================================
  // FILTER
  // ===========================================================================

  Future<void> _changeFilter(
      ReportDateFilter? filter,
      ) async {
    if (filter == null) {
      return;
    }

    // Custom filter requires selecting a date range.
    if (filter == ReportDateFilter.custom) {
      final bool selected =
      await _selectCustomDateRange();

      if (!selected) {
        return;
      }
    }

    setState(() {
      _selectedFilter = filter;
    });

    await _loadReport();
  }

  // ===========================================================================
  // CUSTOM DATE RANGE
  // ===========================================================================

  Future<bool> _selectCustomDateRange() async {
    DateTime firstDate =
        _customFrom ?? DateTime.now();

    DateTime lastDate =
        _customTo ?? DateTime.now();

    // Make sure the end date is not before the start date.
    if (lastDate.isBefore(firstDate)) {
      lastDate = firstDate;
    }

    final DateTimeRange? picked =
    await showDateRangePicker(
      context: context,
      firstDate: DateTime(2000),
      lastDate: DateTime(2100),
      initialDateRange: DateTimeRange(
        start: firstDate,
        end: lastDate,
      ),
      helpText: 'Select Report Date Range',
      saveText: 'APPLY',
    );

    if (picked == null) {
      return false;
    }

    setState(() {
      _customFrom =
          _dateOnly(picked.start);

      _customTo =
          _dateOnly(picked.end);
    });

    return true;
  }

  // ===========================================================================
  // SINGLE DATE
  // ===========================================================================

  Future<void> _selectSingleDate() async {
    final DateTime? picked =
    await showDatePicker(
      context: context,
      initialDate: _selectedDate,
      firstDate: DateTime(2000),
      lastDate: DateTime(2100),
      helpText: 'Select Report Date',
    );

    if (picked == null) {
      return;
    }

    setState(() {
      _selectedDate =
          _dateOnly(picked);
    });

    await _loadReport();
  }

  // ===========================================================================
  // EXCEL EXPORT
  // ===========================================================================

  Future<void> _exportExcel() async {
    if (_reportData == null ||
        _dateRange == null ||
        _isExporting) {
      return;
    }

    setState(() {
      _isExporting = true;
    });

    try {
      final file =
      await ExcelExportService.instance
          .exportReport(
        reportData: _reportData!,
        dateRange: _dateRange!,
      );

      if (!mounted) {
        return;
      }

      _showMessage(
        'Excel report created successfully.\n'
            '${file.path}',
      );
    } catch (error) {
      if (!mounted) {
        return;
      }

      _showMessage(
        'Unable to create Excel report: $error',
        isError: true,
      );
    } finally {
      if (mounted) {
        setState(() {
          _isExporting = false;
        });
      }
    }
  }

  // ===========================================================================
  // EXCEL SHARE
  // ===========================================================================

  Future<void> _shareExcel() async {
    if (_reportData == null ||
        _dateRange == null ||
        _isExporting) {
      return;
    }

    setState(() {
      _isExporting = true;
    });

    try {
      await ExcelExportService.instance
          .shareReport(
        reportData: _reportData!,
        dateRange: _dateRange!,
      );

      if (!mounted) {
        return;
      }

      _showMessage(
        'Excel report is ready to share.',
      );
    } catch (error) {
      if (!mounted) {
        return;
      }

      _showMessage(
        'Unable to share Excel report: $error',
        isError: true,
      );
    } finally {
      if (mounted) {
        setState(() {
          _isExporting = false;
        });
      }
    }
  }

  // ===========================================================================
  // PDF EXPORT
  // ===========================================================================

  Future<void> _exportPdf() async {
    if (_reportData == null ||
        _dateRange == null ||
        _isExporting) {
      return;
    }

    setState(() {
      _isExporting = true;
    });

    try {
      final file =
      await PdfExportService.instance
          .exportReport(
        reportData: _reportData!,
        dateRange: _dateRange!,
      );

      if (!mounted) {
        return;
      }

      _showMessage(
        'PDF report created successfully.\n'
            '${file.path}',
      );
    } catch (error) {
      if (!mounted) {
        return;
      }

      _showMessage(
        'Unable to create PDF report: $error',
        isError: true,
      );
    } finally {
      if (mounted) {
        setState(() {
          _isExporting = false;
        });
      }
    }
  }

  // ===========================================================================
  // PDF SHARE
  // ===========================================================================

  Future<void> _sharePdf() async {
    if (_reportData == null ||
        _dateRange == null ||
        _isExporting) {
      return;
    }

    setState(() {
      _isExporting = true;
    });

    try {
      await PdfExportService.instance
          .shareReport(
        reportData: _reportData!,
        dateRange: _dateRange!,
      );

      if (!mounted) {
        return;
      }

      _showMessage(
        'PDF report is ready to share.',
      );
    } catch (error) {
      if (!mounted) {
        return;
      }

      _showMessage(
        'Unable to share PDF report: $error',
        isError: true,
      );
    } finally {
      if (mounted) {
        setState(() {
          _isExporting = false;
        });
      }
    }
  }

  // ===========================================================================
  // BUILD
  // ===========================================================================

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Reports'),
        centerTitle: true,
      ),

      // --------------------------------------------------------------
      // BODY
      // --------------------------------------------------------------

      body: _isLoading
          ? const Center(
        child: CircularProgressIndicator(),
      )
          : RefreshIndicator(
        onRefresh: _loadReport,
        child: _buildBody(),
      ),
    );
  }

  // ===========================================================================
  // BODY
  // ===========================================================================

  Widget _buildBody() {
    final ReportData? data =
        _reportData;

    if (data == null ||
        _dateRange == null) {
      return ListView(
        physics:
        const AlwaysScrollableScrollPhysics(),
        children: const <Widget>[
          SizedBox(height: 250),
          Center(
            child: Text(
              'No report data available.',
            ),
          ),
        ],
      );
    }

    return ListView(
      physics:
      const AlwaysScrollableScrollPhysics(),
      padding:
      const EdgeInsets.all(16),
      children: <Widget>[
        // Report period filter.
        _buildFilterCard(),

        const SizedBox(height: 16),

        // Selected date range.
        _buildDateRangeCard(),

        const SizedBox(height: 16),

        // Summary.
        _buildSummaryCard(data),

        const SizedBox(height: 16),

        // Individual module counts.
        _buildModuleCards(data),

        const SizedBox(height: 20),

        // Export and sharing actions.
        _buildExportSection(),

        const SizedBox(height: 20),
      ],
    );
  }

  // ===========================================================================
  // FILTER CARD
  // ===========================================================================

  Widget _buildFilterCard() {
    return Card(
      child: Padding(
        padding:
        const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment:
          CrossAxisAlignment.start,
          children: <Widget>[
            const Text(
              'Report Period',
              style: TextStyle(
                fontSize: 18,
                fontWeight:
                FontWeight.bold,
              ),
            ),

            const SizedBox(height: 12),

            DropdownButtonFormField<
                ReportDateFilter>(
              initialValue:
              _selectedFilter,

              decoration:
              const InputDecoration(
                labelText:
                'Select Period',
                border:
                OutlineInputBorder(),
              ),

              items: const <
                  DropdownMenuItem<
                      ReportDateFilter>>[
                DropdownMenuItem(
                  value:
                  ReportDateFilter.daily,
                  child:
                  Text('Daily'),
                ),
                DropdownMenuItem(
                  value:
                  ReportDateFilter.weekly,
                  child:
                  Text('Weekly'),
                ),
                DropdownMenuItem(
                  value:
                  ReportDateFilter.monthly,
                  child:
                  Text('Monthly'),
                ),
                DropdownMenuItem(
                  value:
                  ReportDateFilter.quarterly,
                  child:
                  Text('Quarterly'),
                ),
                DropdownMenuItem(
                  value:
                  ReportDateFilter.yearly,
                  child:
                  Text('Yearly'),
                ),
                DropdownMenuItem(
                  value:
                  ReportDateFilter.custom,
                  child:
                  Text('Custom Date'),
                ),
              ],

              onChanged:
              _isExporting
                  ? null
                  : _changeFilter,
            ),

            const SizedBox(height: 12),

            OutlinedButton.icon(
              onPressed:
              _isExporting
                  ? null
                  : _selectedFilter ==
                  ReportDateFilter.custom
                  ? _selectCustomDateRange
                  : _selectSingleDate,

              icon: const Icon(
                Icons.calendar_month,
              ),

              label: Text(
                _selectedFilter ==
                    ReportDateFilter.custom
                    ? 'Change Date Range'
                    : 'Change Date',
              ),
            ),
          ],
        ),
      ),
    );
  }

  // ===========================================================================
  // DATE RANGE CARD
  // ===========================================================================

  Widget _buildDateRangeCard() {
    final ReportDateRange range =
    _dateRange!;

    return Card(
      child: Padding(
        padding:
        const EdgeInsets.all(16),
        child: Row(
          children: <Widget>[
            const Icon(
              Icons.date_range,
              size: 30,
            ),

            const SizedBox(width: 12),

            Expanded(
              child: Column(
                crossAxisAlignment:
                CrossAxisAlignment.start,
                children: <Widget>[
                  const Text(
                    'Report Date Range',
                    style: TextStyle(
                      fontWeight:
                      FontWeight.bold,
                    ),
                  ),

                  const SizedBox(height: 4),

                  Text(
                    '${_displayDateFormat.format(range.from)}'
                        ' - '
                        '${_displayDateFormat.format(range.to)}',

                    style:
                    const TextStyle(
                      fontSize: 16,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  // ===========================================================================
  // SUMMARY CARD
  // ===========================================================================

  Widget _buildSummaryCard(
      ReportData data,
      ) {
    return Card(
      child: Padding(
        padding:
        const EdgeInsets.all(18),
        child: Column(
          children: <Widget>[
            const Text(
              'Report Summary',
              style: TextStyle(
                fontSize: 20,
                fontWeight:
                FontWeight.bold,
              ),
            ),

            const SizedBox(height: 16),

            Text(
              '${data.totalRecords}',
              style: const TextStyle(
                fontSize: 36,
                fontWeight:
                FontWeight.bold,
              ),
            ),

            const Text(
              'Total Records',
              style: TextStyle(
                fontSize: 15,
              ),
            ),
          ],
        ),
      ),
    );
  }

  // ===========================================================================
  // MODULE CARDS
  // ===========================================================================

  Widget _buildModuleCards(
      ReportData data,
      ) {
    return Column(
      children: <Widget>[
        _buildModuleCard(
          title: 'Customers',
          count:
          data.customers.length,
          icon: Icons.people,
        ),

        _buildModuleCard(
          title: 'Fleet Services',
          count:
          data.fleetServices.length,
          icon:
          Icons.car_repair,
        ),

        _buildModuleCard(
          title: 'Emission Tests',
          count:
          data.emissionTests.length,
          icon: Icons.air,
        ),

        _buildModuleCard(
          title: 'Car Documents',
          count:
          data.carDocuments.length,
          icon: Icons.description,
        ),

        _buildModuleCard(
          title: 'Accessories',
          count:
          data.accessories.length,
          icon:
          Icons.inventory_2,
        ),

        _buildModuleCard(
          title: 'Tyre Stock',
          count:
          data.tyreStocks.length,
          icon:
          Icons.tire_repair_outlined,
        ),

        _buildModuleCard(
          title: 'Tyre Billing',
          count:
          data.tyreBills.length,
          icon:
          Icons.receipt_long_outlined,
        ),

        _buildModuleCard(
          title: 'Alignment Billing',
          count:
          data.alignmentBills.length,
          icon:
          Icons.car_repair_outlined,
        ),
      ],
    );
  }

  // ===========================================================================
  // SINGLE MODULE CARD
  // ===========================================================================

  Widget _buildModuleCard({
    required String title,
    required int count,
    required IconData icon,
  }) {
    return Card(
      margin:
      const EdgeInsets.only(
        bottom: 10,
      ),
      child: ListTile(
        leading: CircleAvatar(
          child: Icon(icon),
        ),

        title: Text(
          title,
          style: const TextStyle(
            fontWeight:
            FontWeight.w600,
          ),
        ),

        trailing: Text(
          count.toString(),
          style: const TextStyle(
            fontSize: 20,
            fontWeight:
            FontWeight.bold,
          ),
        ),
      ),
    );
  }

  // ===========================================================================
  // EXPORT SECTION
  // ===========================================================================

  Widget _buildExportSection() {
    return Card(
      child: Padding(
        padding:
        const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment:
          CrossAxisAlignment.start,
          children: <Widget>[
            const Text(
              'Export & Share',
              style: TextStyle(
                fontSize: 18,
                fontWeight:
                FontWeight.bold,
              ),
            ),

            const SizedBox(height: 6),

            const Text(
              'Generate the current report as PDF or Excel.',
              style: TextStyle(
                color: Colors.grey,
              ),
            ),

            const SizedBox(height: 16),

            // ----------------------------------------------------------
            // EXPORT EXCEL
            // ----------------------------------------------------------

            _buildExportButton(
              icon:
              Icons.table_view,
              label:
              'Export Excel',
              onPressed:
              _exportExcel,
            ),

            const SizedBox(height: 10),

            // ----------------------------------------------------------
            // SHARE EXCEL
            // ----------------------------------------------------------

            _buildExportButton(
              icon: Icons.share,
              label:
              'Share Excel',
              outlined: true,
              onPressed:
              _shareExcel,
            ),

            const SizedBox(height: 10),

            // ----------------------------------------------------------
            // EXPORT PDF
            // ----------------------------------------------------------

            _buildExportButton(
              icon:
              Icons.picture_as_pdf_outlined,
              label:
              'Export PDF',
              onPressed:
              _exportPdf,
            ),

            const SizedBox(height: 10),

            // ----------------------------------------------------------
            // SHARE PDF
            // ----------------------------------------------------------

            _buildExportButton(
              icon:
              Icons.picture_as_pdf_outlined,
              label:
              'Share PDF',
              outlined: true,
              onPressed:
              _sharePdf,
            ),

            // ----------------------------------------------------------
            // EXPORT PROGRESS
            // ----------------------------------------------------------

            if (_isExporting) ...<Widget>[
              const SizedBox(height: 16),

              const Row(
                children: <Widget>[
                  SizedBox(
                    width: 20,
                    height: 20,
                    child:
                    CircularProgressIndicator(
                      strokeWidth: 2,
                    ),
                  ),

                  SizedBox(width: 10),

                  Expanded(
                    child: Text(
                      'Preparing report...',
                    ),
                  ),
                ],
              ),
            ],
          ],
        ),
      ),
    );
  }

  // ===========================================================================
  // EXPORT BUTTON
  // ===========================================================================

  Widget _buildExportButton({
    required IconData icon,
    required String label,
    required VoidCallback onPressed,
    bool outlined = false,
  }) {
    final Widget button =
    outlined
        ? OutlinedButton.icon(
      onPressed:
      _isExporting
          ? null
          : onPressed,
      icon: Icon(icon),
      label: Text(label),
    )
        : ElevatedButton.icon(
      onPressed:
      _isExporting
          ? null
          : onPressed,
      icon: Icon(icon),
      label: Text(label),
    );

    return SizedBox(
      width: double.infinity,
      height: 50,
      child: button,
    );
  }

  // ===========================================================================
  // DATE ONLY
  // ===========================================================================

  DateTime _dateOnly(
      DateTime date,
      ) {
    return DateTime(
      date.year,
      date.month,
      date.day,
    );
  }

  // ===========================================================================
  // MESSAGE
  // ===========================================================================

  void _showMessage(
      String message, {
        bool isError = false,
      }) {
    ScaffoldMessenger.of(context)
      ..hideCurrentSnackBar()
      ..showSnackBar(
        SnackBar(
          content:
          Text(message),
          backgroundColor:
          isError
              ? Colors.red
              : null,
        ),
      );
  }
}