import 'package:flutter/material.dart';
import 'package:fl_chart/fl_chart.dart';
import '../../../models/app_user.dart';
import '../../../services/database_service.dart';

class RankingPage extends StatefulWidget {
  const RankingPage({super.key});

  @override
  State<RankingPage> createState() => _RankingPageState();
}

class _RankingPageState extends State<RankingPage> {
  bool _isQuizRanking = true; // true: 作問数, false: 練習数

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF8F9FA),
      appBar: AppBar(
        title: const Text(
          'ランキング',
          style: TextStyle(color: Colors.black, fontWeight: FontWeight.bold),
        ),
        backgroundColor: Colors.white,
        elevation: 0,
        iconTheme: const IconThemeData(color: Colors.black),
      ),
      body: Column(
        children: [
          _buildToggle(),
          Expanded(
            child: FutureBuilder<List<AppUser>>(
              future: _isQuizRanking
                  ? DatabaseService().getTopCreators()
                  : DatabaseService().getTopPractitioners(),
              builder: (context, snapshot) {
                if (snapshot.connectionState == ConnectionState.waiting) {
                  return const Center(child: CircularProgressIndicator());
                }

                final topUsers = snapshot.data ?? [];

                return Padding(
                  padding: const EdgeInsets.all(24),
                  child: Column(
                    children: [
                      Text(
                        _isQuizRanking ? '総作問数 TOP 5' : '総練習数 TOP 5',
                        style: const TextStyle(
                          fontWeight: FontWeight.bold,
                          fontSize: 16,
                        ),
                      ),
                      const SizedBox(height: 32),
                      // グラフエリア（データがなくても枠を表示）
                      SizedBox(height: 250, child: _buildChart(topUsers)),
                      const SizedBox(height: 32),
                      // リストエリア
                      Expanded(
                        child: topUsers.isEmpty
                            ? _buildEmptyState()
                            : _buildList(topUsers),
                      ),
                    ],
                  ),
                );
              },
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildToggle() {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 16),
      child: SegmentedButton<bool>(
        segments: const [
          ButtonSegment(
            value: true,
            label: Text('作問数'),
            icon: Icon(Icons.create),
          ),
          ButtonSegment(
            value: false,
            label: Text('練習数'),
            icon: Icon(Icons.bolt),
          ),
        ],
        selected: {_isQuizRanking},
        onSelectionChanged: (val) => setState(() => _isQuizRanking = val.first),
      ),
    );
  }

  Widget _buildChart(List<AppUser> users) {
    // データが空の場合のガードとダミー最大値の計算
    final bool isEmpty = users.isEmpty;
    double maxValue = 10;
    if (!isEmpty) {
      for (var u in users) {
        final val = _isQuizRanking ? u.totalQuizCount : u.practiceCount;
        if (val > maxValue) maxValue = val.toDouble();
      }
    }

    return BarChart(
      BarChartData(
        alignment: BarChartAlignment.spaceAround,
        maxY: maxValue + (maxValue * 0.2), // 上部に少し余裕を持たせる
        barGroups: isEmpty
            ? [] // 空のときは棒を表示しない（枠だけ残る）
            : users.asMap().entries.map((e) {
                final count = _isQuizRanking
                    ? e.value.totalQuizCount
                    : e.value.practiceCount;
                return BarChartGroupData(
                  x: e.key,
                  barRods: [
                    BarChartRodData(
                      toY: count.toDouble(),
                      color: _isQuizRanking ? Colors.indigo : Colors.redAccent,
                      width: 22,
                      borderRadius: const BorderRadius.vertical(
                        top: Radius.circular(6),
                      ),
                      backDrawRodData: BackgroundBarChartRodData(
                        show: true,
                        toY: maxValue + (maxValue * 0.2),
                        color: Colors.black.withOpacity(0.05),
                      ),
                    ),
                  ],
                );
              }).toList(),
        titlesData: FlTitlesData(
          bottomTitles: AxisTitles(
            sideTitles: SideTitles(
              showTitles: true,
              getTitlesWidget: (v, m) {
                if (isEmpty || v.toInt() >= users.length)
                  return const SizedBox();
                return Padding(
                  padding: const EdgeInsets.only(top: 8),
                  child: Text(
                    users[v.toInt()].name.substring(0, 1),
                    style: const TextStyle(
                      fontSize: 10,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                );
              },
            ),
          ),
          leftTitles: const AxisTitles(
            sideTitles: SideTitles(showTitles: true, reservedSize: 30),
          ),
          topTitles: const AxisTitles(
            sideTitles: SideTitles(showTitles: false),
          ),
          rightTitles: const AxisTitles(
            sideTitles: SideTitles(showTitles: false),
          ),
        ),
        gridData: FlGridData(
          show: true,
          drawVerticalLine: false,
          horizontalInterval: maxValue / 5,
        ),
        borderData: FlBorderData(
          show: true,
          border: Border(
            bottom: BorderSide(color: Colors.black.withOpacity(0.1), width: 2),
            left: BorderSide(color: Colors.black.withOpacity(0.1), width: 2),
          ),
        ),
      ),
    );
  }

  Widget _buildList(List<AppUser> users) {
    return ListView.builder(
      itemCount: users.length,
      itemBuilder: (context, i) => Card(
        elevation: 0,
        color: Colors.white,
        margin: const EdgeInsets.only(bottom: 8),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        child: ListTile(
          leading: CircleAvatar(
            backgroundColor: i == 0 ? Colors.amber : Colors.indigo[50],
            child: Text(
              '${i + 1}',
              style: TextStyle(
                color: i == 0 ? Colors.white : Colors.indigo,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
          title: Text(
            users[i].name,
            style: const TextStyle(fontWeight: FontWeight.bold),
          ),
          trailing: Text(
            '${_isQuizRanking ? users[i].totalQuizCount : users[i].practiceCount} 回',
            style: const TextStyle(
              fontWeight: FontWeight.w900,
              color: Colors.black87,
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.leaderboard_outlined,
            size: 64,
            color: Colors.black.withOpacity(0.1),
          ),
          const SizedBox(height: 16),
          const Text(
            'まだデータがありません',
            style: TextStyle(
              color: Colors.black26,
              fontWeight: FontWeight.bold,
            ),
          ),
          const Text(
            '問題を投稿したり練習したりして\nランクインを目指そう！',
            textAlign: TextAlign.center,
            style: TextStyle(color: Colors.black26, fontSize: 12),
          ),
        ],
      ),
    );
  }
}
