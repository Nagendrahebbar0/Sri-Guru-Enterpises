import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

import '../models/report_data.dart';
import '../repositories/report_repository.dart';
import '../services/excel_export_service.dart';
import '../services/pdf_export_service.dart';
import '../services/report_date_filter_service.dart';

/// Report screen for viewing and exporting Sri Guru Enterprises data.
class ReportScreen extends StatefulWidget {
  const ReportScreen({super.key});

  @override
  State<ReportScreen> createState() => _ReportScreenState();
}

class _ReportScreenState extends State<ReportScreen> {
  final ReportRepository _repository = ReportRepository();

  ReportDateFilter _selectedFilter = ReportDateFilter.daily;

  DateTime _selectedDate = DateTime.now();
  DateTime? _customFrom;
  DateTime? _customTo;

  ReportDateRange? _dateRange;
  ReportData? _reportData;

  bool _isLoading = false;
  bool _isExporting = false;

  final DateFormat _displayDateFormat = DateFormat('dd/MM/yyyy');

  @override
  void initState() {
    super.initState();
    _loadReport();
  }

  // ---------------------------------------------------------------------------
  // REPORT LOADING
  // ---------------------------------------------------------------------------

  Future<void> _loadReport() async {
    setState(() {
      _isLoading = true;
    });

    try {
      final ReportDateRange range =
      ReportDateFilterService.getDateRange(
        filter: _selectedFilter,
        selectedDate: _selectedDate,
        customFrom: _customFrom,
        customTo: _customTo,
      );

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

  // ---------------------------------------------------------------------------
  // FILTER
  // ---------------------------------------------------------------------------

  Future<void> _changeFilter(
      ReportDateFilter? filter,
      ) async {
    if (filter == null) {
      return;
    }

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

  Future<bool> _selectCustomDateRange() async {
    DateTime firstDate =
        _customFrom ?? DateTime.now();

    DateTime lastDate =
        _customTo ?? DateTime.now();

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
      _customFrom = _dateOnly(picked.start);
      _customTo = _dateOnly(picked.end);
    });

    return true;
  }

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
      _selectedDate = _dateOnly(picked);
    });

    await _loadReport();
  }

  // ---------------------------------------------------------------------------
  // EXCEL
  // ---------------------------------------------------------------------------

  Future<void> _exportExcel() async {
    if (_reportData == null || _dateRange == null) {
      return;
    }

    setState(() {
      _isExporting = true;
    });

    try {
      final file =
      await ExcelExportService.instance.exportReport(
        reportData: _reportData!,
        dateRange: _dateRange!,
      );

      if (!mounted) {
        return;
      }

      _showMessage(
        'Excel report created successfully.\n${file.path}',
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

  Future<void> _shareExcel() async {
    if (_reportData == null || _dateRange == null) {
      return;
    }

    setState(() {
      _isExporting = true;
    });

    try {
      await ExcelExportService.instance.shareReport(
        reportData: _reportData!,
        dateRange: _dateRange!,
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

  // ---------------------------------------------------------------------------
  // PDF
  // ---------------------------------------------------------------------------

  Future<void> _exportPdf() async {
    if (_reportData == null || _dateRange == null) {
      return;
    }

    setState(() {
      _isExporting = true;
    });

    try {
      final file = await PdfExportService.instance.exportReport(
        reportData: _reportData!,
        dateRange: _dateRange!,
      );

      if (!mounted) {
        return;
      }

      _showMessage(
        'PDF report created successfully.\n${file.path}',
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

  Future<void> _sharePdf() async {
    if (_reportData == null || _dateRange == null) {
      return;
    }

    setState(() {
      _isExporting = true;
    });

    try {
      await PdfExportService.instance.shareReport(
        reportData: _reportData!,
        dateRange: _dateRange!,
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

  // ---------------------------------------------------------------------------
  // UI
  // ---------------------------------------------------------------------------

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Reports'),
        centerTitle: true,
      ),
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

  Widget _buildBody() {
    final ReportData? data = _reportData;

    if (data == null || _dateRange == null) {
      return ListView(
        physics: const AlwaysScrollableScrollPhysics(),
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
      physics: const AlwaysScrollableScrollPhysics(),
      padding: const EdgeInsets.all(16),
      children: <Widget>[
        _buildFilterCard(),
        const SizedBox(height: 16),
        _buildDateRangeCard(),
        const SizedBox(height: 16),
        _buildSummaryCard(data),
        const SizedBox(height: 16),
        _buildModuleCards(data),
        const SizedBox(height: 20),
        _buildExportButtons(),
        const SizedBox(height: 20),
      ],
    );
  }

  // ---------------------------------------------------------------------------
  // FILTER CARD
  // ---------------------------------------------------------------------------

  Widget _buildFilterCard() {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment:
          CrossAxisAlignment.start,
          children: <Widget>[
            const Text(
              'Report Period',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 12),
            DropdownButtonFormField<ReportDateFilter>(
              initialValue: _selectedFilter,
              decoration: const InputDecoration(
                labelText: 'Select Period',
                border: OutlineInputBorder(),
              ),
              items: const <DropdownMenuItem<ReportDateFilter>>[
                DropdownMenuItem(
                  value: ReportDateFilter.daily,
                  child: Text('Daily'),
                ),
                DropdownMenuItem(
                  value: ReportDateFilter.weekly,
                  child: Text('Weekly'),
                ),
                DropdownMenuItem(
                  value: ReportDateFilter.monthly,
                  child: Text('Monthly'),
                ),
                DropdownMenuItem(
                  value: ReportDateFilter.quarterly,
                  child: Text('Quarterly'),
                ),
                DropdownMenuItem(
                  value: ReportDateFilter.yearly,
                  child: Text('Yearly'),
                ),
                DropdownMenuItem(
                  value: ReportDateFilter.custom,
                  child: Text('Custom Date'),
                ),
              ],
              onChanged: _changeFilter,
            ),
            const SizedBox(height: 12),
            OutlinedButton.icon(
              onPressed: _selectedFilter ==
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

  // ---------------------------------------------------------------------------
  // DATE RANGE
  // ---------------------------------------------------------------------------

  Widget _buildDateRangeCard() {
    final ReportDateRange range = _dateRange!;

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
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
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    '${_displayDateFormat.format(range.from)}'
                        ' - '
                        '${_displayDateFormat.format(range.to)}',
                    style: const TextStyle(
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

  // ---------------------------------------------------------------------------
  // SUMMARY
  // ---------------------------------------------------------------------------

  Widget _buildSummaryCard(
      ReportData data,
      ) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(18),
        child: Column(
          children: <Widget>[
            const Text(
              'Report Summary',
              style: TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 16),
            Text(
              '${data.totalRecords}',
              style: const TextStyle(
                fontSize: 36,
                fontWeight: FontWeight.bold,
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

  // ---------------------------------------------------------------------------
  // MODULE CARDS
  // ---------------------------------------------------------------------------

  Widget _buildModuleCards(
      ReportData data,
      ) {
    return Column(
      children: <Widget>[
        _buildModuleCard(
          title: 'Customers',
          count: data.customers.length,
          icon: Icons.people,
        ),
        _buildModuleCard(
          title: 'Fleet Services',
          count: data.fleetServices.length,
          icon: Icons.car_repair,
        ),
        _buildModuleCard(
          title: 'Emission Tests',
          count: data.emissionTests.length,
          icon: Icons.air,
        ),
        _buildModuleCard(
          title: 'Car Documents',
          count: data.carDocuments.length,
          icon: Icons.description,
        ),
        _buildModuleCard(
          title: 'Accessories',
          count: data.accessories.length,
          icon: Icons.inventory_2,
        ),
      ],
    );
  }

  Widget _buildModuleCard({
    required String title,
    required int count,
    required IconData icon,
  }) {
    return Card(
      margin: const EdgeInsets.only(
        bottom: 10,
      ),
      child: ListTile(
        leading: CircleAvatar(
          child: Icon(icon),
        ),
        title: Text(
          title,
          style: const TextStyle(
            fontWeight: FontWeight.w600,
          ),
        ),
        trailing: Text(
          count.toString(),
          style: const TextStyle(
            fontSize: 20,
            fontWeight: FontWeight.bold,
          ),
        ),
      ),
    );
  }

  // ---------------------------------------------------------------------------
  // EXPORT BUTTONS
  // ---------------------------------------------------------------------------

  Widget _buildExportButtons() {
    return Column(
      crossAxisAlignment:
      CrossAxisAlignment.stretch,
      children: <Widget>[
        SizedBox(
          height: 52,
          child: ElevatedButton.icon(
            onPressed:
            _isExporting ? null : _exportExcel,
            icon: const Icon(
              Icons.table_view,
            ),
            label: const Text(
              'Export Excel',
            ),
          ),
        ),
        const SizedBox(height: 12),
        SizedBox(
          height: 52,
          child: OutlinedButton.icon(
            onPressed:
            _isExporting ? null : _shareExcel,
            icon: const Icon(
              Icons.share,
            ),
            label: const Text(
              'Share Excel',
            ),
          ),
        ),
        const SizedBox(height: 12),
        SizedBox(
          height: 52,
          child: ElevatedButton.icon(
            onPressed:
            _isExporting ? null : _exportPdf,
            icon: const Icon(
              Icons.picture_as_pdf_outlined,
            ),
            label: const Text(
              'Export PDF',
            ),
          ),
        ),
        const SizedBox(height: 12),
        SizedBox(
          height: 52,
          child: OutlinedButton.icon(
            onPressed:
            _isExporting ? null : _sharePdf,
            icon: const Icon(
              Icons.picture_as_pdf_outlined,
            ),
            label: const Text(
              'Share PDF',
            ),
          ),
        ),
      ],
    );
  }

  // ---------------------------------------------------------------------------
  // HELPERS
  // ---------------------------------------------------------------------------

  DateTime _dateOnly(DateTime date) {
    return DateTime(
      date.year,
      date.month,
      date.day,
    );
  }

  void _showMessage(
      String message, {
        bool isError = false,
      }) {
    ScaffoldMessenger.of(context)
      ..hideCurrentSnackBar()
      ..showSnackBar(
        SnackBar(
          content: Text(message),
          backgroundColor:
          isError ? Colors.red : null,
        ),
      );
  }
}
