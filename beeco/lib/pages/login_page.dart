import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'dart:ui' show ImageFilter;
import '../providers/auth_provider.dart';
import '../widgets/animated_background.dart';
import 'main_page.dart';

class LoginPage extends ConsumerStatefulWidget {
  const LoginPage({super.key});

  @override
  ConsumerState<LoginPage> createState() => _LoginPageState();
}

class _LoginPageState extends ConsumerState<LoginPage>
    with SingleTickerProviderStateMixin {
  final _usernameController = TextEditingController();
  final _passwordController = TextEditingController();
  bool _rememberMe = false;
  bool _isLoading = false;
  String? _errorMessage;
  bool _obscurePassword = true;
  
  late AnimationController _shakeController;
  late Animation<double> _shakeAnimation;

  @override
  void initState() {
    super.initState();
    _shakeController = AnimationController(
      duration: const Duration(milliseconds: 400),
      vsync: this,
    );
    _shakeAnimation = Tween<double>(
      begin: 0,
      end: 1,
    ).animate(CurvedAnimation(
      parent: _shakeController,
      curve: Curves.easeInOut,
    ));
    
    // 加载记住的用户名
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final rememberedUsername = ref.read(authProvider.notifier).rememberedUsername;
      if (rememberedUsername != null) {
        _usernameController.text = rememberedUsername;
        setState(() => _rememberMe = true);
      }
    });
  }

  @override
  void dispose() {
    _usernameController.dispose();
    _passwordController.dispose();
    _shakeController.dispose();
    super.dispose();
  }

  Future<void> _login() async {
    if (_isLoading) return;
    
    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    final success = await ref.read(authProvider.notifier).login(
      _usernameController.text.trim(),
      _passwordController.text,
      rememberMe: _rememberMe,
    );

    if (success) {
      if (mounted) {
        Navigator.of(context).pushReplacement(
          MaterialPageRoute(builder: (_) => const MainPage()),
        );
      }
    } else {
      if (mounted) {
        setState(() {
          _errorMessage = '用户名或密码错误，请重试。';
          _isLoading = false;
        });
        _passwordController.clear();
        _shakeController.forward(from: 0);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBackground(
      child: SafeArea(
        child: Center(
          child: SingleChildScrollView(
            padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 40),
            child: AnimatedBuilder(
              animation: _shakeController,
              builder: (context, child) {
                final shakeOffset = math.sin(_shakeAnimation.value * math.pi * 4) * 5 * (1 - _shakeAnimation.value);
                return Transform.translate(
                  offset: Offset(shakeOffset, 0),
                  child: child,
                );
              },
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  // Logo 区域
                  _buildLogo(),
                  const SizedBox(height: 40),
                  // 玻璃卡片
                  _buildGlassCard(),
                  const SizedBox(height: 32),
                  // 底部链接
                  _buildFooter(),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildLogo() {
    return Column(
      children: [
        // 蜜蜂图标
        Container(
          width: 80,
          height: 80,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            gradient: const RadialGradient(
              colors: [Color(0xFFFFB800), Color(0xFFFF9500)],
            ),
            boxShadow: [
              BoxShadow(
                color: const Color(0xFFFFB800).withOpacity(0.4),
                blurRadius: 20,
                spreadRadius: 5,
              ),
            ],
          ),
          child: const Icon(
            Icons.account_balance_wallet,
            size: 40,
            color: Colors.white,
          ),
        ),
        const SizedBox(height: 16),
        // 标题
        ShaderMask(
          shaderCallback: (bounds) => const LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [Colors.white, Color(0xFFFFB800)],
          ).createShader(bounds),
          child: const Text(
            '黄成财专业版',
            style: TextStyle(
              fontSize: 32,
              fontWeight: FontWeight.bold,
              color: Colors.white,
              letterSpacing: -1,
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildGlassCard() {
    return ClipRRect(
      borderRadius: BorderRadius.circular(24),
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 20, sigmaY: 20),
        child: Container(
          width: double.infinity,
          constraints: const BoxConstraints(maxWidth: 400),
          decoration: BoxDecoration(
            color: Colors.white.withOpacity(0.03),
            borderRadius: BorderRadius.circular(24),
            border: Border.all(
              color: const Color(0xFFFFB800).withOpacity(0.15),
            ),
          ),
          padding: const EdgeInsets.all(32),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // 标题
              const Center(
                child: Column(
                  children: [
                    Text(
                      '欢迎回来',
                      style: TextStyle(
                        fontSize: 24,
                        fontWeight: FontWeight.w600,
                        color: Colors.white,
                      ),
                    ),
                    SizedBox(height: 8),
                    Text(
                      '请登录您的账户以继续',
                      style: TextStyle(
                        fontSize: 14,
                        color: Colors.grey,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 32),
              
              // 用户名输入框
              _buildInputLabel('用户名'),
              const SizedBox(height: 8),
              _buildTextField(
                controller: _usernameController,
                hintText: '请输入用户名',
                prefixIcon: Icons.person_outline,
                onSubmitted: (_) => _login(),
              ),
              const SizedBox(height: 20),
              
              // 密码输入框
              _buildInputLabel('密码'),
              const SizedBox(height: 8),
              _buildTextField(
                controller: _passwordController,
                hintText: '请输入密码',
                prefixIcon: Icons.lock_outline,
                obscureText: _obscurePassword,
                suffixIcon: IconButton(
                  icon: Icon(
                    _obscurePassword ? Icons.visibility_off : Icons.visibility,
                    color: Colors.white.withOpacity(0.6),
                    size: 20,
                  ),
                  onPressed: () {
                    setState(() => _obscurePassword = !_obscurePassword);
                  },
                ),
                onSubmitted: (_) => _login(),
              ),
              const SizedBox(height: 16),
              
              // 记住我和忘记密码
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  // 记住我
                  GestureDetector(
                    onTap: () {
                      setState(() => _rememberMe = !_rememberMe);
                    },
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Container(
                          width: 18,
                          height: 18,
                          de
