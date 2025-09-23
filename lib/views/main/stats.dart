import 'dart:io';

import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:path_provider/path_provider.dart';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:printing/printing.dart';
import 'package:syncfusion_flutter_charts/charts.dart';
import 'package:timely/api/attendance_api.dart';
import 'package:timely/models/absen_stats.dart';
import 'package:timely/models/historyabsen_model.dart';

class StatisticsPage extends StatefulWidget {
  const StatisticsPage({super.key});

  @override
  State<StatisticsPage> createState() => _StatisticsPageState();
}

class _StatisticsPageState extends State<StatisticsPage>
    with TickerProviderStateMixin {
  final AbsenService _absenService = AbsenService();
  AbsenStatsModel? _statsData;
  HistoryAbsenModel? _historyData;
  bool _isLoading = true;
  String _errorMessage = '';
  bool _isExporting = false;

  late AnimationController _fadeController;
  late AnimationController _slideController;
  late AnimationController _scaleController;

  late Animation<double> _fadeAnimation;
  late Animation<Offset> _slideAnimation;
  late Animation<double> _scaleAnimation;

  @override
  void initState() {
    super.initState();
    _initAnimations();
    _loadData();
  }

  void _initAnimations() {
    _fadeController = AnimationController(
      duration: const Duration(milliseconds: 800),
      vsync: this,
    );
    _slideController = AnimationController(
      duration: const Duration(milliseconds: 600),
      vsync: this,
    );
    _scaleController = AnimationController(
      duration: const Duration(milliseconds: 400),
      vsync: this,
    );

    _fadeAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(parent: _fadeController, curve: Curves.easeInOut),
    );

    _slideAnimation = Tween<Offset>(
      begin: const Offset(0, 0.3),
      end: Offset.zero,
    ).animate(CurvedAnimation(parent: _slideController, curve: Curves.easeOut));

    _scaleAnimation = Tween<double>(begin: 0.8, end: 1.0).animate(
      CurvedAnimation(parent: _scaleController, curve: Curves.elasticOut),
    );
  }

  @override
  void dispose() {
    _fadeController.dispose();
    _slideController.dispose();
    _scaleController.dispose();
    super.dispose();
  }

  Future<void> _loadData() async {
    try {
      setState(() => _isLoading = true);

      final stats = await _absenService.getAbsenStats();
      final history = await _absenService.getHistoryAbsen();

      setState(() {
        _statsData = stats;
        _historyData = history;
        _isLoading = false;
        _errorMessage = '';
      });

      // Start animations
      _fadeController.forward();
      Future.delayed(const Duration(milliseconds: 200), () {
        _slideController.forward();
      });
      Future.delayed(const Duration(milliseconds: 400), () {
        _scaleController.forward();
      });
    } catch (e) {
      setState(() {
        _errorMessage = 'Gagal memuat data: $e';
        _isLoading = false;
      });
      print('Error loading data: $e');
    }
  }

  Future<void> _exportToPdf() async {
    if (_statsData == null || _statsData!.data == null) {
      _showSnackBar('Tidak ada data statistik untuk diekspor', isError: true);
      return;
    }

    setState(() => _isExporting = true);

    try {
      final pdf = pw.Document();

      pdf.addPage(
        pw.Page(
          pageFormat: PdfPageFormat.a4,
          build: (pw.Context context) {
            return pw.Column(
              crossAxisAlignment: pw.CrossAxisAlignment.start,
              children: [
                // Header
                pw.Center(
                  child: pw.Text(
                    'LAPORAN STATISTIK ABSENSI',
                    style: pw.TextStyle(
                      fontSize: 20,
                      fontWeight: pw.FontWeight.bold,
                    ),
                  ),
                ),
                pw.SizedBox(height: 20),

                // Statistics Summary
                pw.Text(
                  'RINGKASAN STATISTIK',
                  style: pw.TextStyle(
                    fontSize: 16,
                    fontWeight: pw.FontWeight.bold,
                  ),
                ),
                pw.SizedBox(height: 10),

                pw.Container(
                  padding: const pw.EdgeInsets.all(10),
                  decoration: pw.BoxDecoration(
                    border: pw.Border.all(color: PdfColors.grey),
                    borderRadius: pw.BorderRadius.circular(5),
                  ),
                  child: pw.Column(
                    children: [
                      _buildPdfStatRow(
                        'Total Hari Absen',
                        _statsData!.data!.totalAbsen ?? 0,
                      ),
                      _buildPdfStatRow(
                        'Total Hadir',
                        _statsData!.data!.totalMasuk ?? 0,
                      ),
                      _buildPdfStatRow(
                        'Total Izin',
                        _statsData!.data!.totalIzin ?? 0,
                      ),
                      _buildPdfStatRow('Total Alpha', _calculateTotalAlpha()),
                    ],
                  ),
                ),
                pw.SizedBox(height: 20),

                // Attendance History
                if (_historyData != null &&
                    _historyData!.data != null &&
                    _historyData!.data!.isNotEmpty) ...[
                  pw.Text(
                    'RIWAYAT ABSENSI',
                    style: pw.TextStyle(
                      fontSize: 16,
                      fontWeight: pw.FontWeight.bold,
                    ),
                  ),
                  pw.SizedBox(height: 10),
                  _buildHistoryTable(),
                  pw.SizedBox(height: 20),
                ],

                pw.Text(
                  'Dibuat pada: ${DateFormat('dd MMMM yyyy HH:mm').format(DateTime.now())}',
                  style: pw.TextStyle(fontSize: 10, color: PdfColors.grey),
                ),
              ],
            );
          },
        ),
      );

      // Save PDF to file
      final directory = await getApplicationDocumentsDirectory();
      final file = File(
        '${directory.path}/laporan_absensi_${DateTime.now().millisecondsSinceEpoch}.pdf',
      );
      await file.writeAsBytes(await pdf.save());

      await Printing.layoutPdf(
        onLayout: (PdfPageFormat format) async => pdf.save(),
      );

      _showSnackBar('PDF berhasil diekspor dan dibuka');
    } catch (e) {
      print('Error exporting PDF: $e');
      _showSnackBar('Gagal mengekspor PDF: $e', isError: true);
    } finally {
      setState(() => _isExporting = false);
    }
  }

  void _showSnackBar(String message, {bool isError = false}) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: isError
            ? Theme.of(context).colorScheme.error
            : Theme.of(context).colorScheme.primary,
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        margin: const EdgeInsets.all(16),
      ),
    );
  }

  int _calculateTotalAlpha() {
    final totalAbsen = _statsData!.data!.totalAbsen ?? 0;
    final totalMasuk = _statsData!.data!.totalMasuk ?? 0;
    final totalIzin = _statsData!.data!.totalIzin ?? 0;
    final totalAlpha = totalAbsen - (totalMasuk + totalIzin);
    return totalAlpha > 0 ? totalAlpha : 0;
  }

  pw.Widget _buildPdfStatRow(String label, int value) {
    return pw.Padding(
      padding: const pw.EdgeInsets.symmetric(vertical: 4),
      child: pw.Row(
        mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
        children: [
          pw.Text(label),
          pw.Text(
            value.toString(),
            style: pw.TextStyle(fontWeight: pw.FontWeight.bold),
          ),
        ],
      ),
    );
  }

  pw.Widget _buildHistoryTable() {
    final historyRecords = _historyData!.data!;

    return pw.Table(
      border: pw.TableBorder.all(color: PdfColors.grey),
      columnWidths: {
        0: const pw.FlexColumnWidth(1.5),
        1: const pw.FlexColumnWidth(1),
        2: const pw.FlexColumnWidth(1),
        3: const pw.FlexColumnWidth(1),
      },
      children: [
        pw.TableRow(
          decoration: const pw.BoxDecoration(color: PdfColors.grey200),
          children: [
            pw.Padding(
              padding: const pw.EdgeInsets.all(8),
              child: pw.Text(
                'Tanggal',
                style: pw.TextStyle(fontWeight: pw.FontWeight.bold),
              ),
            ),
            pw.Padding(
              padding: const pw.EdgeInsets.all(8),
              child: pw.Text(
                'Check In',
                style: pw.TextStyle(fontWeight: pw.FontWeight.bold),
              ),
            ),
            pw.Padding(
              padding: const pw.EdgeInsets.all(8),
              child: pw.Text(
                'Check Out',
                style: pw.TextStyle(fontWeight: pw.FontWeight.bold),
              ),
            ),
            pw.Padding(
              padding: const pw.EdgeInsets.all(8),
              child: pw.Text(
                'Status',
                style: pw.TextStyle(fontWeight: pw.FontWeight.bold),
              ),
            ),
          ],
        ),
        ...historyRecords.map((record) {
          return pw.TableRow(
            children: [
              pw.Padding(
                padding: const pw.EdgeInsets.all(8),
                child: pw.Text(
                  record.attendanceDate != null
                      ? DateFormat('dd/MM/yyyy').format(record.attendanceDate!)
                      : '-',
                ),
              ),
              pw.Padding(
                padding: const pw.EdgeInsets.all(8),
                child: pw.Text(record.checkInTime ?? '-'),
              ),
              pw.Padding(
                padding: const pw.EdgeInsets.all(8),
                child: pw.Text(record.checkOutTime ?? '-'),
              ),
              pw.Padding(
                padding: const pw.EdgeInsets.all(8),
                child: pw.Text(
                  record.status ?? '-',
                  style: pw.TextStyle(
                    color: _getStatusColorPdf(record.status ?? ''),
                  ),
                ),
              ),
            ],
          );
        }),
      ],
    );
  }

  PdfColor _getStatusColorPdf(String status) {
    switch (status.toLowerCase()) {
      case 'hadir':
        return PdfColors.green;
      case 'terlambat':
        return PdfColors.orange;
      case 'izin':
        return PdfColors.blue;
      case 'alpha':
        return PdfColors.red;
      default:
        return PdfColors.black;
    }
  }

  Widget _buildAnimatedCard({
    required Widget child,
    required int index,
    EdgeInsetsGeometry? margin,
  }) {
    return Container(
      margin: margin ?? const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      child: TweenAnimationBuilder<double>(
        duration: Duration(milliseconds: 800 + (index * 150)),
        tween: Tween(begin: 0.0, end: 1.0),
        curve: Curves.easeOutCubic,
        builder: (context, value, child) {
          // Ensure opacity is always within valid range
          final clampedOpacity = value.clamp(0.0, 1.0);
          final clampedScale = (0.8 + (0.2 * value)).clamp(0.0, 1.0);

          return Transform.scale(
            scale: clampedScale,
            child: Opacity(opacity: clampedOpacity, child: child),
          );
        },
        child: child,
      ),
    );
  }

  Widget _buildStatsOverview() {
    if (_statsData == null || _statsData!.data == null)
      return const SizedBox.shrink();

    final totalAbsen = _statsData!.data!.totalAbsen ?? 0;
    final totalMasuk = _statsData!.data!.totalMasuk ?? 0;
    final totalIzin = _statsData!.data!.totalIzin ?? 0;
    final totalAlpha = _calculateTotalAlpha();

    return _buildAnimatedCard(
      index: 0,
      child: Container(
        width: double.infinity,
        padding: const EdgeInsets.all(24),
        decoration: BoxDecoration(
          gradient: LinearGradient(
            colors: [
              Theme.of(context).colorScheme.primary,
              Theme.of(context).colorScheme.primary.withOpacity(0.8),
            ],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
          borderRadius: BorderRadius.circular(20),
          boxShadow: [
            BoxShadow(
              color: Theme.of(context).colorScheme.primary.withOpacity(0.3),
              blurRadius: 20,
              offset: const Offset(0, 8),
            ),
          ],
        ),
        child: Column(
          children: [
            Text(
              'Ringkasan Statistik',
              style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                color: Colors.white,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 24),
            Row(
              children: [
                Expanded(
                  child: _buildOverviewItem(
                    'Total Hari',
                    totalAbsen.toString(),
                    Icons.calendar_today_outlined,
                  ),
                ),
                Container(
                  width: 1,
                  height: 60,
                  color: Colors.white.withOpacity(0.3),
                ),
                Expanded(
                  child: _buildOverviewItem(
                    'Kehadiran',
                    totalAbsen > 0
                        ? '${((totalMasuk / totalAbsen) * 100).toStringAsFixed(1)}%'
                        : '0%',
                    Icons.trending_up,
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildOverviewItem(String label, String value, IconData icon) {
    return Column(
      children: [
        Icon(icon, size: 32, color: Colors.white.withOpacity(0.9)),
        const SizedBox(height: 8),
        Text(
          value,
          style: const TextStyle(
            fontSize: 24,
            fontWeight: FontWeight.bold,
            color: Colors.white,
          ),
        ),
        const SizedBox(height: 4),
        Text(
          label,
          style: TextStyle(fontSize: 14, color: Colors.white.withOpacity(0.8)),
        ),
      ],
    );
  }

  Widget _buildStatsGrid() {
    if (_statsData == null || _statsData!.data == null)
      return const SizedBox.shrink();

    final totalAbsen = _statsData!.data!.totalAbsen ?? 0;
    final totalMasuk = _statsData!.data!.totalMasuk ?? 0;
    final totalIzin = _statsData!.data!.totalIzin ?? 0;
    final totalAlpha = _calculateTotalAlpha();

    final stats = [
      _StatItem(
        title: 'Hadir',
        value: totalMasuk,
        icon: Icons.check_circle_outline,
        color: Theme.of(context).colorScheme.secondary,
        percentage: totalAbsen > 0 ? (totalMasuk / totalAbsen) * 100 : 0,
      ),
      _StatItem(
        title: 'Izin',
        value: totalIzin,
        icon: Icons.event_available_outlined,
        color: Theme.of(context).colorScheme.tertiary,
        percentage: totalAbsen > 0 ? (totalIzin / totalAbsen) * 100 : 0,
      ),
      _StatItem(
        title: 'Alpha',
        value: totalAlpha,
        icon: Icons.cancel_outlined,
        color: Theme.of(context).colorScheme.error,
        percentage: totalAbsen > 0 ? (totalAlpha / totalAbsen) * 100 : 0,
      ),
    ];

    return Column(
      children: stats.map((stat) {
        final index = stats.indexOf(stat);
        return _buildAnimatedCard(
          index: index + 1,
          child: _buildStatCard(stat),
        );
      }).toList(),
    );
  }

  Widget _buildStatCard(_StatItem stat) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.surface,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: Theme.of(context).colorScheme.outline.withOpacity(0.2),
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: stat.color.withOpacity(0.1),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Icon(stat.icon, size: 32, color: stat.color),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  stat.title,
                  style: Theme.of(context).textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.w600,
                  ),
                ),
                const SizedBox(height: 4),
                Row(
                  children: [
                    Text(
                      stat.value.toString(),
                      style: Theme.of(context).textTheme.headlineSmall
                          ?.copyWith(
                            color: stat.color,
                            fontWeight: FontWeight.bold,
                          ),
                    ),
                    const SizedBox(width: 8),
                    Text(
                      '(${stat.percentage.toStringAsFixed(1)}%)',
                      style: Theme.of(context).textTheme.bodySmall?.copyWith(
                        color: Theme.of(
                          context,
                        ).colorScheme.onSurface.withOpacity(0.6),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
          SizedBox(
            width: 60,
            height: 60,
            child: CircularProgressIndicator(
              value: stat.percentage / 100,
              backgroundColor: stat.color.withOpacity(0.2),
              valueColor: AlwaysStoppedAnimation<Color>(stat.color),
              strokeWidth: 4,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildPieChart() {
    if (_statsData == null || _statsData!.data == null)
      return const SizedBox.shrink();

    final totalMasuk = _statsData!.data!.totalMasuk ?? 0;
    final totalIzin = _statsData!.data!.totalIzin ?? 0;
    final totalAlpha = _calculateTotalAlpha();
    final total = totalMasuk + totalIzin + totalAlpha;

    if (total == 0) {
      return _buildAnimatedCard(index: 4, child: _buildEmptyChart());
    }

    final data = [
      _ChartData('Hadir', totalMasuk, Theme.of(context).colorScheme.secondary),
      _ChartData('Izin', totalIzin, Theme.of(context).colorScheme.tertiary),
      _ChartData('Alpha', totalAlpha, Theme.of(context).colorScheme.error),
    ].where((item) => item.value > 0).toList();

    return _buildAnimatedCard(
      index: 4,
      child: Container(
        padding: const EdgeInsets.all(24),
        decoration: BoxDecoration(
          color: Theme.of(context).colorScheme.surface,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(
            color: Theme.of(context).colorScheme.outline.withOpacity(0.2),
          ),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.05),
              blurRadius: 10,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: Column(
          children: [
            Text(
              'Distribusi Absensi',
              style: Theme.of(
                context,
              ).textTheme.headlineSmall?.copyWith(fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 24),
            SizedBox(
              height: 300,
              child: ScaleTransition(
                scale: _scaleAnimation,
                child: SfCircularChart(
                  series: <CircularSeries<_ChartData, String>>[
                    DoughnutSeries<_ChartData, String>(
                      dataSource: data,
                      xValueMapper: (_ChartData data, _) => data.label,
                      yValueMapper: (_ChartData data, _) => data.value,
                      pointColorMapper: (_ChartData data, _) => data.color,
                      dataLabelSettings: const DataLabelSettings(
                        isVisible: true,
                        labelPosition: ChartDataLabelPosition.outside,
                        useSeriesColor: true,
                      ),
                      enableTooltip: true,
                      innerRadius: '60%',
                      cornerStyle: CornerStyle.bothCurve,
                      animationDuration: 1500,
                    ),
                  ],
                  legend: Legend(
                    isVisible: true,
                    position: LegendPosition.bottom,
                    overflowMode: LegendItemOverflowMode.wrap,
                    textStyle: Theme.of(context).textTheme.bodyMedium,
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildEmptyChart() {
    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.surface,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(
          color: Theme.of(context).colorScheme.outline.withOpacity(0.2),
        ),
      ),
      child: Column(
        children: [
          Text(
            'Distribusi Absensi',
            style: Theme.of(
              context,
            ).textTheme.headlineSmall?.copyWith(fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 40),
          Icon(
            Icons.pie_chart_outline,
            size: 80,
            color: Theme.of(context).colorScheme.outline.withOpacity(0.5),
          ),
          const SizedBox(height: 16),
          Text(
            'Belum ada data absensi',
            style: Theme.of(context).textTheme.bodyLarge?.copyWith(
              color: Theme.of(context).colorScheme.onSurface.withOpacity(0.6),
            ),
          ),
          const SizedBox(height: 40),
        ],
      ),
    );
  }

  Widget _buildExportButton() {
    return _buildAnimatedCard(
      index: 5,
      child: Container(
        width: double.infinity,
        margin: const EdgeInsets.symmetric(horizontal: 0),
        child: FilledButton.icon(
          onPressed: _isExporting ? null : _exportToPdf,
          icon: _isExporting
              ? SizedBox(
                  width: 20,
                  height: 20,
                  child: CircularProgressIndicator(
                    strokeWidth: 2,
                    valueColor: AlwaysStoppedAnimation<Color>(
                      Theme.of(context).colorScheme.onPrimary,
                    ),
                  ),
                )
              : const Icon(Icons.file_download_outlined),
          label: Text(_isExporting ? 'Mengekspor...' : 'Export Laporan PDF'),
          style: FilledButton.styleFrom(
            padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildErrorView() {
    return Center(
      child: Container(
        margin: const EdgeInsets.all(24),
        padding: const EdgeInsets.all(32),
        decoration: BoxDecoration(
          color: Theme.of(context).colorScheme.errorContainer,
          borderRadius: BorderRadius.circular(20),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              Icons.error_outline,
              size: 64,
              color: Theme.of(context).colorScheme.error,
            ),
            const SizedBox(height: 16),
            Text(
              'Oops! Terjadi Kesalahan',
              style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                color: Theme.of(context).colorScheme.error,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              _errorMessage,
              textAlign: TextAlign.center,
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                color: Theme.of(context).colorScheme.onErrorContainer,
              ),
            ),
            const SizedBox(height: 24),
            FilledButton.icon(
              onPressed: _loadData,
              icon: const Icon(Icons.refresh),
              label: const Text('Coba Lagi'),
              style: FilledButton.styleFrom(
                backgroundColor: Theme.of(context).colorScheme.error,
                foregroundColor: Theme.of(context).colorScheme.onError,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildLoadingView() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Container(
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              color: Theme.of(context).colorScheme.primary.withOpacity(0.1),
              shape: BoxShape.circle,
            ),
            child: CircularProgressIndicator(
              strokeWidth: 3,
              valueColor: AlwaysStoppedAnimation<Color>(
                Theme.of(context).colorScheme.primary,
              ),
            ),
          ),
          const SizedBox(height: 24),
          Text(
            'Memuat data statistik...',
            style: Theme.of(context).textTheme.bodyLarge?.copyWith(
              color: Theme.of(context).colorScheme.onSurface.withOpacity(0.7),
            ),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Statistik Absensi'),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: _isLoading ? null : _loadData,
            tooltip: 'Refresh Data',
          ),
        ],
      ),
      body: _isLoading
          ? _buildLoadingView()
          : _errorMessage.isNotEmpty
          ? _buildErrorView()
          : _statsData == null || _statsData!.data == null
          ? Center(
              child: Container(
                margin: const EdgeInsets.all(24),
                padding: const EdgeInsets.all(32),
                decoration: BoxDecoration(
                  color: Theme.of(context).colorScheme.surfaceContainerHighest,
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(
                      Icons.analytics_outlined,
                      size: 64,
                      color: Theme.of(context).colorScheme.primary,
                    ),
                    const SizedBox(height: 16),
                    Text(
                      'Tidak ada data statistik',
                      style: Theme.of(context).textTheme.headlineSmall,
                    ),
                  ],
                ),
              ),
            )
          : RefreshIndicator(
              onRefresh: _loadData,
              child: SingleChildScrollView(
                physics: const AlwaysScrollableScrollPhysics(),
                child: Padding(
                  padding: const EdgeInsets.only(bottom: 24),
                  child: Column(
                    children: [
                      const SizedBox(height: 8),
                      _buildStatsOverview(),
                      const SizedBox(height: 8),
                      _buildStatsGrid(),
                      const SizedBox(height: 8),
                      _buildPieChart(),
                      const SizedBox(height: 16),
                      _buildExportButton(),
                    ],
                  ),
                ),
              ),
            ),
    );
  }
}

class _StatItem {
  final String title;
  final int value;
  final IconData icon;
  final Color color;
  final double percentage;

  _StatItem({
    required this.title,
    required this.value,
    required this.icon,
    required this.color,
    required this.percentage,
  });
}

class _ChartData {
  final String label;
  final int value;
  final Color color;

  _ChartData(this.label, this.value, this.color);
}
