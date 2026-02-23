import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../providers/app_providers.dart';
import '../providers/auth_provider.dart';
import '../theme/app_theme.dart';
import 'login_page.dart';

class SettingsPage extends ConsumerWidget {
  const SettingsPage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final themeMode = ref.watch(themeModeProvider);
    final primaryColor = Color(ref.watch(primaryColorProvider));
    final currentUser = ref.watch(authProvider.notifier).currentUser;

    return Scaffold(
      appBar: AppBar(
        title: const Text('设置'),
        centerTitle: true,
      ),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          // 用户信息卡片
          if (currentUser != null) ...[
            _buildUserCard(context, currentUser, primaryColor),
            const SizedBox(height: 24),
          ],
          
          // 外观设置
          _buildSectionTitle(context, '外观'),
          _buildCard(
            context,
            children: [
              // 主题模式
              ListTile(
                leading: Icon(
                  themeMode == ThemeMode.dark 
                      ? Icons.dark_mode 
                      : themeMode == ThemeMode.light 
                          ? Icons.light_mode 
                          : Icons.brightness_auto,
                  color: primaryColor,
                ),
                title: const Text('主题模式'),
                subtitle: Text(_getThemeModeText(themeMode)),
                trailing: const Icon(Icons.chevron_right),
                onTap: () => _showThemeModeDialog(context, ref),
              ),
              const Divider(height: 1),
              // 主题色
              ListTile(
                leading: Icon(Icons.palette, color: primaryColor),
                title: const Text('主题颜色'),
                trailing: Container(
                  width: 24,
                  height: 24,
                  decoration: BoxDecoration(
                    color: primaryColor,
                    shape: BoxShape.circle,
                    border: Border.all(color: Colors.grey.shade300),
                  ),
                ),
                onTap: () => _showColorPickerDialog(context, ref),
              ),
            ],
          ),

          const SizedBox(height: 24),

          // 数据管理
          _buildSectionTitle(context, '数据管理'),
          _buildCard(
            context,
            children: [
              ListTile(
                leading: const Icon(Icons.download, color: Colors.green),
                title: const Text('导出数据'),
                subtitle: const Text('导出为 CSV 格式'),
                trailing: const Icon(Icons.chevron_right),
                onTap: () {},
              ),
              const Divider(height: 1),
              ListTile(
                leading: const Icon(Icons.upload, color: Colors.blue),
                title: const Text('导入数据'),
                subtitle: const Text('从 CSV 文件导入'),
                trailing: const Icon(Icons.chevron_right),
                onTap: () {},
              ),
              const Divider(height: 1),
              ListTile(
                leading: const Icon(Icons.delete_outline, color: Colors.red),
                title: const Text('清除数据'),
                subtitle: const Text('删除所有记账数据'),
                trailing: const Icon(Icons.chevron_right),
                onTap: () => _showClearDataDialog(context),
              ),
            ],
          ),

          const SizedBox(height: 24),

          // 账户与安全
          _buildSectionTitle(context, '账户与安全'),
          _buildCard(
            context,
            children: [
              ListTile(
                leading: const Icon(Icons.logout, color: Colors.orange),
                title: const Text('退出登录'),
                subtitle: const Text('退出当前账户'),
                trailing: const Icon(Icons.chevron_right),
                onTap: () => _showLogoutDialog(context, ref),
              ),
            ],
          ),

          const SizedBox(height: 24),

          // 关于
          _buildSectionTitle(context, '关于'),
          _buildCard(
            context,
            children: [
              ListTile(
                leading: Icon(Icons.info_outline, color: primaryColor),
                title: const Text('关于 BeeCo'),
                subtitle: const Text('版本 1.0.0'),
                trailing: const Icon(Icons.chevron_right),
                onTap: () => _showAboutDialog(context),
              ),
            ],
          ),

          const SizedBox(height: 32),

          // 底部版权
          Center(
            child: Text(
              'BeeCo 记账 · 简洁高效的记账工具',
              style: TextStyle(
                color: Colors.grey.shade500,
                fontSize: 12,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildUserCard(BuildContext context, User user, Color primaryColor) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            primaryColor,
            primaryColor.withOpacity(0.8),
          ],
        ),
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: primaryColor.withOpacity(0.3),
            blurRadius: 15,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: Row(
        children: [
          Container(
            width: 60,
            height: 60,
            decoration: BoxDecoration(
              color: Colors.white.withOpacity(0.2),
              shape: BoxShape.circle,
            ),
            child: const Icon(
              Icons.person,
              color: Colors.white,
              size: 32,
            ),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  '当前登录用户',
                  style: TextStyle(
                    color: Colors.white70,
                    fontSize: 14,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  user.username,
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSectionTitle(BuildContext context, String title) {
    return Padding(
      padding: const EdgeInsets.only(left: 8, bottom: 8),
      child: Text(
        title,
        style: TextStyle(
          fontSize: 14,
          fontWeight: FontWeight.w600,
          color: Colors.grey.shade600,
        ),
      ),
    );
  }

  Widget _buildCard(BuildContext context, {required List<Widget> children}) {
    return Card(
      elevation: 0,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
      ),
      child: Column(
        children: children,
      ),
    );
  }

  String _getThemeModeText(ThemeMode mode) {
    switch (mode) {
      case ThemeMode.light:
        return '浅色模式';
      case ThemeMode.dark:
        return '深色模式';
      case ThemeMode.system:
        return '跟随系统';
    }
  }

  void _showThemeModeDialog(BuildContext context, WidgetRef ref) {
    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: const Text('选择主题模式'),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              RadioListTile<ThemeMode>(
                title: const Text('跟随系统'),
                value: ThemeMode.system,
                groupValue: ref.read(themeModeProvider),
                onChanged: (value) {
     
