import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../models/budget.dart';
import '../models/transaction.dart';
import '../theme/design_system.dart';

class BudgetTrendsScreen extends StatefulWidget {
  final Budget budget;

  const BudgetTrendsScreen({super.key, required this.budget});

  @override
  State<BudgetTrendsScreen> createState() => _BudgetTrendsScreenState();
}

class _BudgetTrendsScreenState extends State<BudgetTrendsScreen> {
  late List<FlSpot> _spots;
  late double _minY;
  late double _maxY;
  late List<DateTime> _dates;

  @override
  void initState() {
    super.initState();
    _processData();
  }

  void _processData() {
    final transactions = List<Transaction>.from(widget.budget.transactions);
    transactions.sort((a, b) => a.date.compareTo(b.date));

    if (transactions.isEmpty) {
      _spots = [const FlSpot(0, 0)];
      _dates = [DateTime.now()];
      _minY = 0;
      _maxY = widget.budget.budget;
      return;
    }

    // 1. Determine Date Range
    // Normalize to start of day
    DateTime toDate(DateTime dt) => DateTime(dt.year, dt.month, dt.day);
    
    final firstDate = toDate(transactions.first.date);
    final lastDate = toDate(DateTime.now()); // Show trend up to today
    
    final int totalDays = lastDate.difference(firstDate).inDays + 1;

    // 2. Group transactions by day
    Map<DateTime, double> dailyChange = {};
    for (var t in transactions) {
      final date = toDate(t.date);
      if (!dailyChange.containsKey(date)) dailyChange[date] = 0.0;
      if (t.isExpense) {
        dailyChange[date] = dailyChange[date]! - t.amount;
      } else {
        dailyChange[date] = dailyChange[date]! + t.amount;
      }
    }

    // 3. Generate "Start of Day" Balances
    // Logic: 
    // Point at X=0 (First Date) -> Initial Budget
    // Point at X=1 (Next Day) -> Balance at end of First Date
    // ...
    // Point at X=N (Today) -> Current Balance
    
    List<FlSpot> spots = [];
    List<DateTime> dates = []; // Map X index to Date description
    
    double currentBalance = widget.budget.budget;
    
    // Safety check: calculate backwards to ensure Today matches UI?
    // Using forward calculation as discussed.
    
    _minY = currentBalance;
    _maxY = currentBalance;

    // We plot (N+1) points for N days of history logic? 
    // Actually, let's plot discrete points for each day we care about.
    // X = 0 corresponds to 'Start of firstDate'. Y = Initial.
    
    spots.add(FlSpot(0, currentBalance));
    dates.add(firstDate);

    for (int i = 0; i < totalDays; i++) {
        final date = firstDate.add(Duration(days: i));
        // Apply change for this day
        if (dailyChange.containsKey(date)) {
           currentBalance += dailyChange[date]!;
        }
        
        // Update Min/Max
        if (currentBalance < _minY) _minY = currentBalance;
        if (currentBalance > _maxY) _maxY = currentBalance;

        // Plot the balance for the NEXT day (Start of i+1)
        // X = i + 1
        spots.add(FlSpot((i + 1).toDouble(), currentBalance));
        dates.add(date.add(const Duration(days: 1)));
    }

    // Add padding to Y
    double yRange = _maxY - _minY;
    if (yRange == 0) yRange = 100; // Default range if flat
    _minY -= yRange * 0.1;
    _maxY += yRange * 0.1;

    _spots = spots;
    _dates = dates;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: AppColors.textPrimary),
          onPressed: () => Navigator.pop(context),
        ),
        title: Text(
          '${widget.budget.name} Trends',
          style: const TextStyle(color: AppColors.textPrimary,  fontWeight: FontWeight.bold),
        ),
        centerTitle: true,
      ),
      body: Padding(
        padding: const EdgeInsets.all(AppSpacing.lg),
        child: Column(
          children: [
            Container(
              padding: const EdgeInsets.all(AppSpacing.md),
              decoration: BoxDecoration(
                color: AppColors.cardBackground,
                borderRadius: BorderRadius.circular(AppRadius.lg),
                boxShadow: [AppShadows.cardShadow],
              ),
              child: Column(
                children: [
                   const Text(
                    'Balance History',
                    style: TextStyle(color: AppColors.textSecondary,  fontSize: 16),
                  ),
                  const SizedBox(height: AppSpacing.lg),
                  SizedBox(
                    height: 300,
                    child: LineChart(
                      LineChartData(
                        gridData: FlGridData(
                          show: true,
                          drawVerticalLine: false,
                          horizontalInterval: (_maxY - _minY) / 5 == 0 ? 1 : (_maxY - _minY) / 5, // Auto-interval
                          getDrawingHorizontalLine: (value) {
                            return FlLine(
                              color: AppColors.border,
                              strokeWidth: 1,
                              dashArray: [5, 5],
                            );
                          },
                        ),
                        titlesData: FlTitlesData(
                          show: true,
                          bottomTitles: AxisTitles(
                            sideTitles: SideTitles(
                              showTitles: true,
                              reservedSize: 30,
                              interval: 1, // Fix: Ensure integer usage for indices
                              getTitlesWidget: (value, meta) {
                                int index = value.toInt();
                                if (index < 0 || index >= _dates.length) return const SizedBox();
                                
                                // Smart label skipping
                                int total = _dates.length;
                                int skip = (total / 5).ceil(); 
                                if (index % skip != 0 && index != total - 1) return const SizedBox();
                                
                                final date = _dates[index];
                                return Padding(
                                  padding: const EdgeInsets.only(top: 8.0),
                                  child: Text(
                                    DateFormat('MM/dd').format(date),
                                    style: const TextStyle(color: AppColors.textSecondary, fontSize: 10, fontFamily: 'Inter'),
                                  ),
                                );
                              },
                            ),
                          ),
                          leftTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
                          topTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
                          rightTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
                        ),
                        borderData: FlBorderData(show: false),
                        minX: 0,
                        maxX: (_spots.length - 1).toDouble(),
                        minY: _minY,
                        maxY: _maxY,
                        lineBarsData: [
                          LineChartBarData(
                            spots: _spots,
                            isCurved: true,
                            gradient: const LinearGradient(
                              colors: [AppColors.primary, AppColors.accent],
                            ),
                            barWidth: 3,
                            isStrokeCapRound: true,
                            dotData: FlDotData(
                              show: true,
                              getDotPainter: (spot, percent, barData, index) {
                                return FlDotCirclePainter(
                                  radius: 4,
                                  color: AppColors.cardBackground,
                                  strokeWidth: 2,
                                  strokeColor: AppColors.primary,
                                );
                              },
                            ),
                            belowBarData: BarAreaData(
                              show: true,
                              gradient: LinearGradient(
                                colors: [
                                  AppColors.primary.withOpacity(0.3),
                                  AppColors.primary.withOpacity(0.0),
                                ],
                                begin: Alignment.topCenter,
                                end: Alignment.bottomCenter,
                              ),
                            ),
                          ),
                        ],
                        lineTouchData: LineTouchData(
                          touchTooltipData: LineTouchTooltipData(
                            getTooltipColor: (_) => AppColors.textPrimary.withOpacity(0.8),
                            getTooltipItems: (touchedSpots) {
                              return touchedSpots.map((spot) {
                                final date = _dates[spot.x.toInt()];
                                return LineTooltipItem(
                                  '${DateFormat('MMM d').format(date)}\n',
                                  const TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
                                  children: [
                                    TextSpan(
                                      text: spot.y.toStringAsFixed(2),
                                      style: const TextStyle(color: AppColors.accent, fontWeight: FontWeight.bold),
                                    ),
                                  ],
                                );
                              }).toList();
                            },
                          ),
                        ),
                      ),
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
}
