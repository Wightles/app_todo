import 'package:flutter/material.dart';
import 'package:fl_chart/fl_chart.dart';
import 'package:shared_preferences/shared_preferences.dart';

class StatScene extends StatefulWidget {
  const StatScene({super.key});

  @override
  State<StatScene> createState() => _StatSceneState();
}

class _StatSceneState extends State<StatScene> {
  int totalTasks = 0;
  int completedTasks = 0;
  int deletedTasks = 0;
  int overdueTasks = 0;
  int activeTasks = 0; // Добавляем счетчик активных задач
  List<int> weeklyCreatedData = [0, 0, 0, 0, 0, 0, 0];
  List<int> weeklyCompletedData = [0, 0, 0, 0, 0, 0, 0];
  List<int> weeklyDeletedData = [0, 0, 0, 0, 0, 0, 0];
  List<int> weeklyOverdueData = [0, 0, 0, 0, 0, 0, 0];
  List<int> weeklyActiveData = [0, 0, 0, 0, 0, 0, 0]; // Добавляем данные по активным задачам

  late SharedPreferences prefs;

  final List<String> filterOptions = ['Все', 'Создано', 'Выполнено', 'Удалено', 'Просрочено', 'Активно'];
  String selectedFilter = 'Все';

  @override
  void initState() {
    super.initState();
    _initPrefs();
  }

  Future<void> _initPrefs() async {
    prefs = await SharedPreferences.getInstance();
    _loadStatistics();
  }

  void _loadStatistics() {
    setState(() {
      totalTasks = prefs.getInt('total_tasks') ?? 0;
      completedTasks = prefs.getInt('completed_tasks') ?? 0;
      deletedTasks = prefs.getInt('deleted_tasks') ?? 0;
      overdueTasks = prefs.getInt('overdue_tasks') ?? 0;
      
      // Рассчитываем активные задачи: всего - выполненные - удаленные
      activeTasks = (totalTasks - completedTasks - deletedTasks).clamp(0, totalTasks);

      weeklyCreatedData =
          List.generate(7, (index) => prefs.getInt('created_week_$index') ?? 0);
      weeklyCompletedData = List.generate(
          7, (index) => prefs.getInt('completed_week_$index') ?? 0);
      weeklyDeletedData =
          List.generate(7, (index) => prefs.getInt('deleted_week_$index') ?? 0);
      weeklyOverdueData =
          List.generate(7, (index) => prefs.getInt('overdue_week_$index') ?? 0);
      
      // Рассчитываем активные задачи по дням
      weeklyActiveData = List.generate(7, (index) {
        final created = prefs.getInt('created_week_$index') ?? 0;
        final completed = prefs.getInt('completed_week_$index') ?? 0;
        final deleted = prefs.getInt('deleted_week_$index') ?? 0;
        return (created - completed - deleted).clamp(0, created);
      });
    });
  }

  List<int> get _currentWeeklyData {
    switch (selectedFilter) {
      case 'Создано':
        return weeklyCreatedData;
      case 'Выполнено':
        return weeklyCompletedData;
      case 'Удалено':
        return weeklyDeletedData;
      case 'Просрочено':
        return weeklyOverdueData;
      case 'Активно':
        return weeklyActiveData;
      default:
        return List.generate(
            7,
            (index) =>
                weeklyCreatedData[index] +
                weeklyCompletedData[index] +
                weeklyDeletedData[index] +
                weeklyOverdueData[index] +
                weeklyActiveData[index]);
    }
  }

  Color get _currentFilterColor {
    switch (selectedFilter) {
      case 'Создано':
        return Colors.blue;
      case 'Выполнено':
        return Colors.green;
      case 'Удалено':
        return Colors.red.shade400;
      case 'Просрочено':
        return const Color.fromARGB(255, 255, 0, 174);
      case 'Активно':
        return Colors.orange.shade400; // Цвет для активных задач
      case 'Все':
      default:
        return const Color.fromARGB(255, 7, 222, 193);
    }
  }

  String get _chartTitle {
    switch (selectedFilter) {
      case 'Создано':
        return 'Созданные задачи за неделю';
      case 'Выполнено':
        return 'Выполненные задачи за неделю';
      case 'Удалено':
        return 'Удаленные задачи за неделю';
      case 'Просрочено':
        return 'Просроченные задачи за неделю';
      case 'Активно':
        return 'Активные задачи за неделю';
      case 'Все':
      default:
        return 'Активность за неделю';
    }
  }

  Widget _buildFilterChips() {
    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      child: Row(
        children: filterOptions.map((filter) {
          final isSelected = filter == selectedFilter;
          return Padding(
            padding: const EdgeInsets.only(right: 8),
            child: FilterChip(
              label: Text(
                filter,
                style: TextStyle(
                  color: isSelected ? Colors.white : Colors.grey[700],
                  fontWeight: FontWeight.w500,
                ),
              ),
              selected: isSelected,
              onSelected: (selected) {
                setState(() {
                  selectedFilter = filter;
                });
              },
              backgroundColor: Colors.white,
              selectedColor: _getFilterColor(filter),
              side: BorderSide(
                color: isSelected ? _getFilterColor(filter) : Colors.grey[300]!,
                width: 1,
              ),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(20),
              ),
              checkmarkColor: Colors.white,
            ),
          );
        }).toList(),
      ),
    );
  }

  Color _getFilterColor(String filter) {
    switch (filter) {
      case 'Создано':
        return Colors.blue.shade400;
      case 'Выполнено':
        return Colors.green.shade400;
      case 'Удалено':
        return Colors.red.shade400;
      case 'Просрочено':
        return const Color.fromARGB(255, 255, 0, 174);
      case 'Активно':
        return Colors.orange.shade400; // Цвет для активных задач
      case 'Все':
      default:
        return const Color.fromARGB(255, 7, 222, 193);
    }
  }

  Widget _buildStatCard(String title, int count, Color color) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.grey.withOpacity(0.2),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Text(
            count.toString(),
            style: TextStyle(
              fontSize: 28,
              fontWeight: FontWeight.bold,
              color: color,
            ),
          ),
          SizedBox(height: 8),
          Text(
            title,
            style: TextStyle(
              fontSize: 14,
              color: Colors.grey,
            ),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }

  Widget _buildBarChart() {
    final currentData = _currentWeeklyData;
    final maxValue = currentData.isNotEmpty
        ? currentData.reduce((a, b) => a > b ? a : b)
        : 0;

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.grey.withOpacity(0.2),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            _chartTitle,
            style: const TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
              color: Colors.black87,
            ),
          ),
          const SizedBox(height: 16),
          SizedBox(
            height: 200,
            child: BarChart(
              BarChartData(
                alignment: BarChartAlignment.spaceAround,
                maxY: maxValue > 0 ? maxValue.toDouble() + 1 : 5,
                barTouchData: BarTouchData(
                  enabled: true,
                  touchTooltipData: BarTouchTooltipData(
                    tooltipBgColor: Colors.blueGrey,
                    getTooltipItem: (group, groupIndex, rod, rodIndex) {
                      final dayNames = [
                        'Пн',
                        'Вт',
                        'Ср',
                        'Чт',
                        'Пт',
                        'Сб',
                        'Вс'
                      ];
                      return BarTooltipItem(
                        '${dayNames[group.x.toInt()]}: ${rod.toY.toInt()}',
                        const TextStyle(color: Colors.white),
                      );
                    },
                  ),
                ),
                titlesData: FlTitlesData(
                  show: true,
                  bottomTitles: AxisTitles(
                    sideTitles: SideTitles(
                      showTitles: true,
                      getTitlesWidget: (value, meta) {
                        final days = ['Пн', 'Вт', 'Ср', 'Чт', 'Пт', 'Сб', 'Вс'];
                        return value.toInt() < days.length
                            ? Padding(
                                padding: const EdgeInsets.only(top: 8.0),
                                child: Text(
                                  days[value.toInt()],
                                  style: const TextStyle(
                                    fontSize: 12,
                                    color: Colors.grey,
                                  ),
                                ),
                              )
                            : const SizedBox();
                      },
                    ),
                  ),
                  leftTitles: AxisTitles(
                    sideTitles: SideTitles(
                      showTitles: true,
                      getTitlesWidget: (value, meta) {
                        return Text(
                          value.toInt().toString(),
                          style: const TextStyle(
                            fontSize: 12,
                            color: Colors.grey,
                          ),
                        );
                      },
                      reservedSize: 40,
                    ),
                  ),
                  rightTitles: AxisTitles(
                    sideTitles: SideTitles(showTitles: false),
                  ),
                  topTitles: AxisTitles(
                    sideTitles: SideTitles(showTitles: false),
                  ),
                ),
                gridData: FlGridData(
                  show: true,
                  drawVerticalLine: false,
                  horizontalInterval: 1,
                  getDrawingHorizontalLine: (value) => FlLine(
                    color: Colors.grey.withOpacity(0.2),
                    strokeWidth: 1,
                  ),
                ),
                borderData: FlBorderData(
                  show: false,
                ),
                barGroups: currentData.asMap().entries.map((entry) {
                  final index = entry.key;
                  final value = entry.value;
                  return BarChartGroupData(
                    x: index,
                    barRods: [
                      BarChartRodData(
                        toY: value.toDouble(),
                        gradient: LinearGradient(
                          colors: [
                            _currentFilterColor.withOpacity(0.8),
                            _currentFilterColor.withOpacity(0.4),
                          ],
                          begin: Alignment.bottomCenter,
                          end: Alignment.topCenter,
                        ),
                        width: 20,
                        borderRadius: BorderRadius.circular(4),
                        backDrawRodData: BackgroundBarChartRodData(
                          show: true,
                          toY: maxValue > 0 ? maxValue.toDouble() + 1 : 5,
                          color: Colors.grey.withOpacity(0.1),
                        ),
                      ),
                    ],
                  );
                }).toList(),
              ),
            ),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color.fromARGB(255, 254, 243, 243),
      body: SingleChildScrollView(
        padding: EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Статистика задач',
              style: TextStyle(
                fontSize: 24,
                fontWeight: FontWeight.bold,
                color: Colors.black87,
              ),
            ),
            SizedBox(height: 16),
            _buildFilterChips(),
            SizedBox(height: 20),
            GridView(
              shrinkWrap: true,
              physics: NeverScrollableScrollPhysics(),
              gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                crossAxisCount: 2,
                crossAxisSpacing: 16,
                mainAxisSpacing: 16,
                childAspectRatio: 1.2,
              ),
              children: [
                _buildStatCard('Всего задач', totalTasks, Colors.blue),
                _buildStatCard('Выполнено', completedTasks, Colors.green),
                _buildStatCard('Удалено', deletedTasks, Colors.red.shade400),
                _buildStatCard('Просрочено', overdueTasks, const Color.fromARGB(255, 255, 0, 174)),
                _buildStatCard('Активно', activeTasks, Colors.orange.shade400), // Изменено с "В процессе" на "Активно"
              ],
            ),
            SizedBox(height: 24),
            _buildBarChart(),
            SizedBox(height: 24),
            Container(
              padding: EdgeInsets.all(16),
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(16),
                boxShadow: [
                  BoxShadow(
                    color: Colors.grey.withOpacity(0.2),
                    blurRadius: 10,
                    offset: Offset(0, 4),
                  ),
                ],
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Продуктивность',
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                      color: Colors.black87,
                    ),
                  ),
                  SizedBox(height: 12),
                  Row(
                    children: [
                      Expanded(
                        child: LinearProgressIndicator(
                          value:
                              totalTasks > 0 ? completedTasks / totalTasks : 0,
                          backgroundColor: Colors.grey.shade200,
                          valueColor: AlwaysStoppedAnimation<Color>(
                            Colors.green.shade400,
                          ),
                          borderRadius: BorderRadius.circular(8),
                        ),
                      ),
                      SizedBox(width: 12),
                      Text(
                        '${totalTasks > 0 ? ((completedTasks / totalTasks) * 100).toStringAsFixed(1) : 0}%',
                        style: const TextStyle(
                          fontWeight: FontWeight.bold,
                          color: Colors.green,
                        ),
                      ),
                    ],
                  ),
                  SizedBox(height: 8),
                  Text(
                    'Процент выполнения задач',
                    style: TextStyle(
                      fontSize: 12,
                      color: Colors.grey,
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