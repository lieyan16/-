import 'package:flutter/material.dart';
import 'package:flutter_slidable/flutter_slidable.dart';
import '../models/asset.dart';
import '../services/database.dart';
import 'asset_detail_screen.dart';

class AssetListScreen extends StatefulWidget {
  const AssetListScreen({super.key});

  @override
  State<AssetListScreen> createState() => _AssetListScreenState();
}

class _AssetListScreenState extends State<AssetListScreen> {
  List<Asset> _assets = [];
  bool _isLoading = true;
  double _totalValue = 0.0;
  final DatabaseService _dbService = DatabaseService();

  // 新统计数据
  double _dailyCostSum = 0.0;
  Asset? _mostExpensiveAsset;
  Asset? _longestOwnedAsset;
  Asset? _lowestDailyCostAsset;
  Asset? _highestDailyCostAsset;
  Asset? _cheapestAsset;

  @override
  void initState() {
    super.initState();
    _loadAssets();
  }

  Future<void> _loadAssets() async {
    setState(() => _isLoading = true);
    final assets = await _dbService.getAllAssets();

    // 计算所有统计数据
    _calculateStatistics(assets);

    setState(() {
      _assets = assets;
      _isLoading = false;
    });
  }

  void _calculateStatistics(List<Asset> assets) {
    if (assets.isEmpty) {
      _totalValue = 0.0;
      _dailyCostSum = 0.0;
      _mostExpensiveAsset = null;
      _longestOwnedAsset = null;
      _lowestDailyCostAsset = null;
      _highestDailyCostAsset = null;
      _cheapestAsset = null;
      return;
    }

    // 基本统计
    double total = 0;
    double dailySum = 0;
    Asset? mostExpensive;
    Asset? longestOwned;
    Asset? lowestDaily;
    Asset? highestDaily;
    Asset? cheapest;

    for (var asset in assets) {
      // 总价值
      total += asset.price;

      // 日均成本总和
      dailySum += asset.dailyCost;

      // 最贵资产
      if (mostExpensive == null || asset.price > mostExpensive.price) {
        mostExpensive = asset;
      }

      // 最便宜资产
      if (cheapest == null || asset.price < cheapest.price) {
        cheapest = asset;
      }

      // 持有时间最长
      if (longestOwned == null ||
          asset.purchaseDate.isBefore(longestOwned.purchaseDate)) {
        longestOwned = asset;
      }

      // 日均成本最低
      if (lowestDaily == null || asset.dailyCost < lowestDaily.dailyCost) {
        lowestDaily = asset;
      }

      // 日均成本最高
      if (highestDaily == null || asset.dailyCost > highestDaily.dailyCost) {
        highestDaily = asset;
      }
    }

    _totalValue = total;
    _dailyCostSum = dailySum;
    _mostExpensiveAsset = mostExpensive;
    _longestOwnedAsset = longestOwned;
    _lowestDailyCostAsset = lowestDaily;
    _highestDailyCostAsset = highestDaily;
    _cheapestAsset = cheapest;
  }

  // 公开的刷新方法，可以从外部调用
  void refreshData() {
    _loadAssets();
  }

  Widget _getCategoryIcon(String? category) {
    if (category == null || category.isEmpty) {
      return const Icon(Icons.category, color: Colors.blue);
    }

    final low = category.toLowerCase();
    if (low.contains('手机') || low.contains('phone') || low.contains('电子') || low.contains('iphone')) {
      return const Icon(Icons.phone_iphone, color: Colors.blue);
    } else if (low.contains('电脑') || low.contains('笔记本') || low.contains('laptop') || low.contains('mac')) {
      return const Icon(Icons.laptop, color: Colors.purple);
    } else if (low.contains('相机') || low.contains('摄影') || low.contains('camera')) {
      return const Icon(Icons.camera_alt, color: Colors.green);
    } else if (low.contains('硬盘') || low.contains('存储') || low.contains('ssd') || low.contains('hdd')) {
      return const Icon(Icons.sd_storage, color: Colors.orange);
    } else if (low.contains('耳机') || low.contains('音响')) {
      return const Icon(Icons.headphones, color: Colors.cyan);
    } else {
      return const Icon(Icons.category, color: Colors.blue);
    }
  }

  // 显示详细统计弹窗
  void _showStatisticsDialog() {
    if (_assets.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('暂无资产数据'),
          duration: Duration(seconds: 1),
        ),
      );
      return;
    }

    showDialog(
      context: context,
      builder: (context) => _buildStatisticsDialog(),
    );
  }

  // 格式化数字显示，处理大数字
  String _formatNumber(double value, {bool isPrice = true}) {
    if (value >= 1000000) {
      return isPrice ?
      '¥${(value / 10000).toStringAsFixed(1)}万' :
      '${(value / 10000).toStringAsFixed(1)}万';
    } else if (value >= 1000) {
      return isPrice ?
      '¥${value.toStringAsFixed(0)}' :
      value.toStringAsFixed(0);
    } else {
      return isPrice ?
      '¥${value.toStringAsFixed(value >= 10 ? 0 : 1)}' :
      value.toStringAsFixed(value >= 10 ? 0 : 1);
    }
  }

  // 格式化日期显示：2025-11-5
  String _formatDate(DateTime date) {
    return '${date.year}-${date.month.toString().padLeft(2, '0')}-${date.day.toString().padLeft(2, '0')}';
  }

  Widget _buildStatisticsDialog() {
    final screenHeight = MediaQuery.of(context).size.height;

    return Dialog(
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(20.0),
      ),
      insetPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 32),
      child: ConstrainedBox(
        constraints: BoxConstraints(
          maxHeight: screenHeight * 0.78,
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            // 标题栏
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
              decoration: BoxDecoration(
                color: Colors.blue.shade50,
                borderRadius: const BorderRadius.only(
                  topLeft: Radius.circular(20),
                  topRight: Radius.circular(20),
                ),
              ),
              child: Row(
                children: [
                  Container(
                    width: 36,
                    height: 36,
                    decoration: BoxDecoration(
                      color: Colors.blue,
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: const Icon(Icons.analytics, color: Colors.white, size: 20),
                  ),
                  const SizedBox(width: 12),
                  const Expanded(
                    child: Text(
                      '资产详细统计',
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                        color: Colors.blue,
                      ),
                    ),
                  ),
                  Container(
                    width: 32,
                    height: 32,
                    decoration: BoxDecoration(
                      color: Colors.grey.shade200,
                      borderRadius: BorderRadius.circular(16),
                    ),
                    child: IconButton(
                      icon: const Icon(Icons.close, size: 18),
                      onPressed: () => Navigator.pop(context),
                      padding: EdgeInsets.zero,
                      constraints: const BoxConstraints(),
                    ),
                  ),
                ],
              ),
            ),

            // 内容区域
            Expanded(
              child: SingleChildScrollView(
                physics: const BouncingScrollPhysics(),
                padding: const EdgeInsets.all(16),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // 基本信息网格
                    GridView.count(
                      shrinkWrap: true,
                      physics: const NeverScrollableScrollPhysics(),
                      crossAxisCount: 2,
                      childAspectRatio: 1.6,
                      crossAxisSpacing: 10,
                      mainAxisSpacing: 10,
                      children: [
                        _buildStatItem('总资产数', '${_assets.length}个', Icons.inventory, Colors.blue),
                        _buildStatItem('总价值', _formatNumber(_totalValue), Icons.monetization_on, Colors.green),
                        _buildStatItem('平均价值', _formatNumber(_assets.isEmpty ? 0 : (_totalValue / _assets.length)), Icons.calculate, Colors.purple),
                        _buildStatItem('日均成本', '${_formatNumber(_dailyCostSum, isPrice: false)}/天', Icons.trending_up, Colors.orange),
                      ],
                    ),

                    const SizedBox(height: 20),

                    // 分割线
                    Container(
                      height: 1,
                      color: Colors.grey.shade300,
                    ),

                    const SizedBox(height: 20),

                    // 资产排行标题
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 6),
                      decoration: BoxDecoration(
                        color: Colors.blue.shade50,
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Row(
                        children: [
                          Icon(Icons.leaderboard, color: Colors.blue.shade700, size: 18),
                          const SizedBox(width: 8),
                          const Text(
                            '资产明细排行',
                            style: TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.bold,
                              color: Colors.blue,
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 12),

                    // 排行项目
                    Column(
                      mainAxisSize: MainAxisSize.min,
                      children: _buildRankingItems(),
                    ),

                    const SizedBox(height: 16),

                    // 说明卡片
                    Container(
                      padding: const EdgeInsets.all(14),
                      decoration: BoxDecoration(
                        color: Colors.blue.shade50.withOpacity(0.5),
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(color: Colors.blue.shade100, width: 1),
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: [
                              Container(
                                width: 28,
                                height: 28,
                                decoration: BoxDecoration(
                                  color: Colors.blue,
                                  borderRadius: BorderRadius.circular(14),
                                ),
                                child: const Icon(Icons.lightbulb_outline, color: Colors.white, size: 14),
                              ),
                              const SizedBox(width: 10),
                              const Text(
                                '资产使用成本分析',
                                style: TextStyle(
                                  fontWeight: FontWeight.bold,
                                  color: Colors.blue,
                                  fontSize: 15,
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 8),
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 4),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                _buildInfoPoint('日均成本 = 购买价格 ÷ 持有天数'),
                                const SizedBox(height: 4),
                                _buildInfoPoint('持有时间越长，日均成本越低'),
                                const SizedBox(height: 4),
                                _buildInfoPoint('日均成本总和反映了资产维护成本'),
                                const SizedBox(height: 4),
                                _buildInfoPoint('点击资产卡片可查看详细信息'),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildStatItem(String label, String value, IconData icon, Color color) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: color.withOpacity(0.2), width: 1),
      ),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(icon, size: 14, color: color),
              const SizedBox(width: 4),
              Text(
                label,
                style: TextStyle(
                  fontSize: 11,
                  color: color,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ],
          ),
          const SizedBox(height: 6),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 3),
            decoration: BoxDecoration(
              color: color.withOpacity(0.2),
              borderRadius: BorderRadius.circular(6),
            ),
            child: Text(
              value,
              style: TextStyle(
                fontSize: 13,
                fontWeight: FontWeight.bold,
                color: color,
              ),
              textAlign: TextAlign.center,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
          ),
        ],
      ),
    );
  }

  List<Widget> _buildRankingItems() {
    final List<Widget> items = [];

    // 最贵资产
    if (_mostExpensiveAsset != null) {
      items.add(_buildRankingItem(
        '💰 最贵资产',
        _mostExpensiveAsset!.name,
        _formatNumber(_mostExpensiveAsset!.price),
        '日均: ${_formatNumber(_mostExpensiveAsset!.dailyCost, isPrice: false)}/天',
        Colors.red,
        Icons.attach_money,
      ));
      items.add(const SizedBox(height: 8));
    }

    // 最便宜资产
    if (_cheapestAsset != null) {
      items.add(_buildRankingItem(
        '📉 最便宜资产',
        _cheapestAsset!.name,
        _formatNumber(_cheapestAsset!.price),
        '日均: ${_formatNumber(_cheapestAsset!.dailyCost, isPrice: false)}/天',
        Colors.green,
        Icons.money_off,
      ));
      items.add(const SizedBox(height: 8));
    }

    // 持有时间最长
    if (_longestOwnedAsset != null) {
      items.add(_buildRankingItem(
        '⏳ 持有时间最长',
        _longestOwnedAsset!.name,
        _longestOwnedAsset!.daysOwnedFormatted,
        '购买于${_formatDate(_longestOwnedAsset!.purchaseDate)}',
        Colors.purple,
        Icons.history,
      ));
      items.add(const SizedBox(height: 8));
    }

    // 日均成本最低
    if (_lowestDailyCostAsset != null) {
      items.add(_buildRankingItem(
        '📊 日均成本最低',
        _lowestDailyCostAsset!.name,
        '${_formatNumber(_lowestDailyCostAsset!.dailyCost, isPrice: false)}/天',
        '总价${_formatNumber(_lowestDailyCostAsset!.price)}',
        Colors.teal,
        Icons.trending_down,
      ));
      items.add(const SizedBox(height: 8));
    }

    // 日均成本最高
    if (_highestDailyCostAsset != null) {
      items.add(_buildRankingItem(
        '📈 日均成本最高',
        _highestDailyCostAsset!.name,
        '${_formatNumber(_highestDailyCostAsset!.dailyCost, isPrice: false)}/天',
        '总价${_formatNumber(_highestDailyCostAsset!.price)}',
        Colors.orange,
        Icons.trending_up,
      ));
    }

    // 如果没有任何数据，显示提示
    if (items.isEmpty) {
      items.add(
        Container(
          padding: const EdgeInsets.symmetric(vertical: 32),
          decoration: BoxDecoration(
            color: Colors.grey.shade50,
            borderRadius: BorderRadius.circular(10),
          ),
          child: Column(
            children: [
              Icon(Icons.bar_chart, size: 40, color: Colors.grey.shade400),
              const SizedBox(height: 12),
              const Text(
                '暂无排行数据',
                style: TextStyle(color: Colors.grey, fontSize: 14),
              ),
            ],
          ),
        ),
      );
    }

    return items;
  }

  Widget _buildRankingItem(String title, String assetName, String value, String subtitle, Color color, IconData icon) {
    return Container(
      padding: const EdgeInsets.all(10),
      decoration: BoxDecoration(
        color: color.withOpacity(0.05),
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: color.withOpacity(0.2), width: 1),
      ),
      child: Row(
        children: [
          // 左侧图标
          Container(
            width: 36,
            height: 36,
            decoration: BoxDecoration(
              color: color,
              borderRadius: BorderRadius.circular(8),
            ),
            child: Icon(icon, color: Colors.white, size: 18),
          ),

          const SizedBox(width: 10),

          // 信息区域
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.bold,
                    color: color,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  assetName,
                  style: const TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.w600,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
                const SizedBox(height: 2),
                Row(
                  children: [
                    Expanded(
                      child: Container(
                        padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 3),
                        decoration: BoxDecoration(
                          color: color.withOpacity(0.1),
                          borderRadius: BorderRadius.circular(5),
                        ),
                        child: Text(
                          value,
                          style: TextStyle(
                            fontSize: 11,
                            color: Colors.grey.shade800,
                            fontWeight: FontWeight.bold,
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                    ),
                    const SizedBox(width: 6),
                    Expanded(
                      child: Text(
                        subtitle,
                        style: TextStyle(
                          fontSize: 10,
                          color: Colors.grey.shade600,
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildInfoPoint(String text) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Container(
          width: 5,
          height: 5,
          margin: const EdgeInsets.only(top: 5, right: 6),
          decoration: BoxDecoration(
            color: Colors.blue,
            borderRadius: BorderRadius.circular(2.5),
          ),
        ),
        Expanded(
          child: Text(
            text,
            style: TextStyle(
              fontSize: 12,
              color: Colors.grey.shade700,
              height: 1.4,
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildStatsCard() {
    return GestureDetector(
      onTap: _showStatisticsDialog,
      child: Card(
        margin: const EdgeInsets.all(12),
        elevation: 2,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16),
        ),
        child: Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(16),
            gradient: LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: [
                Colors.blue.shade50,
                Colors.white,
                Colors.blue.shade50,
              ],
            ),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // 标题和箭头
              Row(
                children: [
                  Container(
                    width: 36,
                    height: 36,
                    decoration: BoxDecoration(
                      color: Colors.blue,
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: const Icon(Icons.analytics, color: Colors.white, size: 20),
                  ),
                  const SizedBox(width: 10),
                  const Expanded(
                    child: Text(
                      '资产总览',
                      style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Colors.blue),
                    ),
                  ),
                  Container(
                    width: 28,
                    height: 28,
                    decoration: BoxDecoration(
                      color: Colors.blue.withOpacity(0.2),
                      borderRadius: BorderRadius.circular(14),
                    ),
                    child: const Icon(Icons.arrow_forward_ios, size: 14, color: Colors.blue),
                  ),
                ],
              ),
              const SizedBox(height: 14),

              // 主要统计指标
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  _buildCompactStatItem('总资产数', '${_assets.length}个', Colors.blue),
                  _buildCompactStatItem('总价值', _formatNumber(_totalValue), Colors.green),
                  _buildCompactStatItem(
                    '日均成本',
                    '${_formatNumber(_assets.isEmpty ? 0 : _dailyCostSum, isPrice: false)}/天',
                    Colors.orange,
                  ),
                ],
              ),
              const SizedBox(height: 10),

              // 提示文字
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 6),
                decoration: BoxDecoration(
                  color: Colors.blue.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Row(
                  children: [
                    Icon(Icons.touch_app, size: 14, color: Colors.blue.shade600),
                    const SizedBox(width: 6),
                    Text(
                      '点击查看详细统计',
                      style: TextStyle(
                        fontSize: 12,
                        color: Colors.blue.shade600,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildCompactStatItem(String label, String value, Color color) {
    return Expanded(
      child: Container(
        margin: const EdgeInsets.symmetric(horizontal: 2),
        padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 8),
        decoration: BoxDecoration(
          color: color.withOpacity(0.08),
          borderRadius: BorderRadius.circular(10),
          border: Border.all(color: color.withOpacity(0.2), width: 1),
        ),
        child: Column(
          children: [
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 3),
              decoration: BoxDecoration(
                color: color,
                borderRadius: BorderRadius.circular(6),
              ),
              child: Text(
                value,
                style: TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.bold,
                  color: Colors.white,
                ),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
            ),
            const SizedBox(height: 4),
            Text(
              label,
              style: TextStyle(
                fontSize: 10,
                color: Colors.grey.shade600,
                fontWeight: FontWeight.w500,
              ),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildAssetCard(Asset asset) {
    return Slidable(
      key: ValueKey(asset.id),
      endActionPane: ActionPane(
        motion: const DrawerMotion(),
        children: [
          SlidableAction(
            onPressed: (context) async {
              bool confirm = await _showDeleteConfirmationDialog(asset);
              if (confirm) {
                _deleteAsset(asset.id);
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    content: Text('"${asset.name}" 已删除'),
                    action: SnackBarAction(
                      label: '撤销',
                      onPressed: () {
                        _undoDelete(asset);
                      },
                    ),
                    duration: const Duration(seconds: 4),
                  ),
                );
              }
            },
            backgroundColor: Colors.red,
            foregroundColor: Colors.white,
            icon: Icons.delete,
            label: '删除',
          ),
        ],
      ),
      child: GestureDetector(
        onLongPress: () {
          _showQuickActions(context, asset);
        },
        child: _buildAssetCardContent(asset),
      ),
    );
  }

  Widget _buildAssetCardContent(Asset asset) {
    return GestureDetector(
      onTap: () {
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (_) => AssetDetailScreen(assetId: asset.id),
          ),
        ).then((needRefresh) {
          if (needRefresh == true) {
            _loadAssets();
          }
        });
      },
      child: Card(
        margin: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
        elevation: 1,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(12),
        ),
        child: Container(
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: Colors.grey.shade100, width: 1),
          ),
          child: Padding(
            padding: const EdgeInsets.all(10),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // 左侧图标
                Container(
                  width: 46,
                  height: 46,
                  margin: const EdgeInsets.only(right: 12),
                  decoration: BoxDecoration(
                    color: Colors.blue.shade50,
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: Center(child: _getCategoryIcon(asset.category)),
                ),

                // 主要信息区域
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // 资产名称
                      Text(
                        asset.name,
                        style: const TextStyle(
                          fontSize: 15,
                          fontWeight: FontWeight.bold,
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),

                      const SizedBox(height: 6),

                      // 信息行 - 更紧凑的布局
                      Row(
                        children: [
                          // 类别标签
                          if (asset.category != null && asset.category!.isNotEmpty)
                            Container(
                              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                              margin: const EdgeInsets.only(right: 8),
                              decoration: BoxDecoration(
                                color: Colors.blue.shade50,
                                borderRadius: BorderRadius.circular(6),
                                border: Border.all(color: Colors.blue.shade100, width: 1),
                              ),
                              child: Text(
                                asset.category!,
                                style: TextStyle(
                                  fontSize: 11,
                                  color: Colors.blue.shade700,
                                  fontWeight: FontWeight.w500,
                                ),
                              ),
                            ),

                          // 日期
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                            decoration: BoxDecoration(
                              color: Colors.grey.shade50,
                              borderRadius: BorderRadius.circular(4),
                            ),
                            child: Text(
                              _formatDate(asset.purchaseDate),
                              style: TextStyle(
                                fontSize: 10,
                                color: Colors.grey.shade700,
                              ),
                            ),
                          ),
                        ],
                      ),

                      const SizedBox(height: 6),

                      // 价格信息行
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          // 购买价格 - 确保有单位
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                            decoration: BoxDecoration(
                              color: Colors.green.shade50,
                              borderRadius: BorderRadius.circular(6),
                            ),
                            child: Text(
                              _formatNumber(asset.price),
                              style: TextStyle(
                                fontSize: 13,
                                fontWeight: FontWeight.bold,
                                color: Colors.green.shade700,
                              ),
                            ),
                          ),

                          // 日均成本 - 确保有单位
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                            decoration: BoxDecoration(
                              color: Colors.orange.shade50,
                              borderRadius: BorderRadius.circular(6),
                            ),
                            child: Text(
                              '${_formatNumber(asset.dailyCost, isPrice: false)}/天',
                              style: TextStyle(
                                fontSize: 12,
                                fontWeight: FontWeight.bold,
                                color: Colors.orange.shade700,
                              ),
                            ),
                          ),
                        ],
                      ),

                      // 如果有位置信息，显示在底部
                      if (asset.location != null && asset.location!.isNotEmpty)
                        Container(
                          margin: const EdgeInsets.only(top: 6),
                          child: Row(
                            children: [
                              Icon(Icons.location_on, size: 12, color: Colors.grey.shade600),
                              const SizedBox(width: 4),
                              Text(
                                asset.location!,
                                style: TextStyle(
                                  fontSize: 11,
                                  color: Colors.grey.shade600,
                                ),
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                              ),
                            ],
                          ),
                        ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Future<bool> _showDeleteConfirmationDialog(Asset asset) async {
    bool? shouldDelete = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('确认删除'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('确定要删除 "${asset.name}" 吗？'),
            const SizedBox(height: 8),
            Text(
              '价格: ${_formatNumber(asset.price)}',
              style: const TextStyle(color: Colors.grey),
            ),
            Text(
              '日均成本: ${_formatNumber(asset.dailyCost, isPrice: false)}/天',
              style: const TextStyle(color: Colors.grey),
            ),
            if (asset.category != null && asset.category!.isNotEmpty)
              Text(
                '类别: ${asset.category}',
                style: const TextStyle(color: Colors.grey),
              ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('取消'),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(context, true),
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.red,
              foregroundColor: Colors.white,
            ),
            child: const Text('删除'),
          ),
        ],
      ),
    );
    return shouldDelete ?? false;
  }

  void _deleteAsset(String id) async {
    await _dbService.softDeleteAsset(id);
    setState(() {
      _assets.removeWhere((asset) => asset.id == id);
      _calculateStatistics(_assets);
    });
  }

  void _undoDelete(Asset asset) async {
    await _dbService.restoreAsset(asset.id);
    await _loadAssets();
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('已恢复 "${asset.name}"'),
        duration: const Duration(seconds: 2),
      ),
    );
  }

  // 快捷操作菜单
  void _showQuickActions(BuildContext context, Asset asset) {
    showModalBottomSheet(
      context: context,
      builder: (context) {
        return SafeArea(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              ListTile(
                leading: const Icon(Icons.edit, color: Colors.blue),
                title: const Text('编辑资产'),
                onTap: () {
                  Navigator.pop(context);
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (_) => AssetDetailScreen(assetId: asset.id),
                    ),
                  ).then((needRefresh) {
                    if (needRefresh == true) {
                      _loadAssets();
                    }
                  });
                },
              ),
              ListTile(
                leading: const Icon(Icons.delete, color: Colors.red),
                title: const Text('删除资产'),
                onTap: () {
                  Navigator.pop(context);
                  _deleteAssetWithConfirmation(asset);
                },
              ),
              ListTile(
                leading: const Icon(Icons.copy, color: Colors.green),
                title: const Text('复制资产'),
                onTap: () {
                  Navigator.pop(context);
                  _copyAsset(asset);
                },
              ),
              ListTile(
                leading: const Icon(Icons.cancel),
                title: const Text('取消'),
                onTap: () => Navigator.pop(context),
              ),
            ],
          ),
        );
      },
    );
  }

  void _deleteAssetWithConfirmation(Asset asset) async {
    bool confirm = await _showDeleteConfirmationDialog(asset);
    if (confirm) {
      _deleteAsset(asset.id);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('"${asset.name}" 已删除'),
          action: SnackBarAction(
            label: '撤销',
            onPressed: () {
              _undoDelete(asset);
            },
          ),
          duration: const Duration(seconds: 4),
        ),
      );
    }
  }

  void _copyAsset(Asset asset) async {
    final newAsset = Asset(
      name: '${asset.name} (副本)',
      price: asset.price,
      purchaseDate: asset.purchaseDate,
      category: asset.category,
      location: asset.location,
      notes: asset.notes,
    );

    await _dbService.insertAsset(newAsset);
    _loadAssets();

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('已复制 "${asset.name}"'),
        duration: const Duration(seconds: 2),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        _buildStatsCard(),
        Expanded(
          child: _isLoading
              ? const Center(child: CircularProgressIndicator())
              : _assets.isEmpty
              ? _buildEmptyState()
              : RefreshIndicator(
            onRefresh: _loadAssets,
            child: ListView.builder(
              itemCount: _assets.length,
              itemBuilder: (context, index) {
                return _buildAssetCard(_assets[index]);
              },
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.inventory_2_outlined,
            size: 80,
            color: Colors.grey.shade300,
          ),
          const SizedBox(height: 16),
          const Text(
            '暂无资产',
            style: TextStyle(fontSize: 20, color: Colors.grey),
          ),
          const SizedBox(height: 8),
          const Text(
            '点击下方 + 按钮添加你的第一个资产',
            style: TextStyle(fontSize: 14, color: Colors.grey),
          ),
        ],
      ),
    );
  }
}