import 'dart:convert';
import 'dart:developer';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:http/http.dart' as http;
import 'package:timely/api/endpoint.dart';
import 'package:timely/models/register_models.dart';
import 'package:timely/services/auth_services.dart';
import 'package:timely/views/auth/login_page.dart';
import 'package:timely/views/main/main_wrapper.dart';

class RegisterPage extends StatefulWidget {
  const RegisterPage({super.key});

  @override
  State<RegisterPage> createState() => _RegisterPageState();
}

class _RegisterPageState extends State<RegisterPage>
    with TickerProviderStateMixin {
  // Controllers
  final _nameController = TextEditingController();
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  final _confirmPasswordController = TextEditingController();
  final _formKey = GlobalKey<FormState>();
  final _pageController = PageController();

  // Dropdown values
  String? _selectedTraining;
  String? _selectedBatch;
  String? _selectedGender;

  // API IDs
  String? _selectedTrainingId;
  String? _selectedBatchId;

  // Dropdown options
  List<Map<String, dynamic>> _trainings = [];
  List<Map<String, dynamic>> _batches = [];
  final List<String> _genders = ['Laki-laki', 'Perempuan'];

  // Animations
  late AnimationController _fadeController;
  late AnimationController _slideController;
  late AnimationController _scaleController;
  late Animation<double> _fadeAnimation;
  late Animation<Offset> _slideAnimation;
  late Animation<double> _scaleAnimation;

  // State variables
  bool _obscurePassword = true;
  bool _obscureConfirmPassword = true;
  bool _isLoading = false;
  int _currentStep = 0;

  // Constants
  static const List<String> _stepTitles = [
    'Informasi Personal',
    'Informasi Training',
    'Keamanan Akun',
  ];

  @override
  void initState() {
    super.initState();
    _initializeAnimations();
    _loadDropdownData();
  }

  void _initializeAnimations() {
    _fadeController = AnimationController(
      duration: const Duration(milliseconds: 800),
      vsync: this,
    );

    _slideController = AnimationController(
      duration: const Duration(milliseconds: 600),
      vsync: this,
    );

    _scaleController = AnimationController(
      duration: const Duration(milliseconds: 500),
      vsync: this,
    );

    _fadeAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(parent: _fadeController, curve: Curves.easeOutQuart),
    );

    _slideAnimation =
        Tween<Offset>(begin: const Offset(0, 0.2), end: Offset.zero).animate(
          CurvedAnimation(parent: _slideController, curve: Curves.easeOutCubic),
        );

    _scaleAnimation = Tween<double>(begin: 0.9, end: 1.0).animate(
      CurvedAnimation(parent: _scaleController, curve: Curves.easeOutBack),
    );

    // Start animations
    _fadeController.forward();
    Future.delayed(const Duration(milliseconds: 100), _slideController.forward);
    Future.delayed(const Duration(milliseconds: 200), _scaleController.forward);
  }

  Future<void> _loadDropdownData() async {
    try {
      await _loadTrainings();
      await _loadBatches();
    } catch (e) {
      _handleDropdownError(e);
    }
  }

  Future<void> _loadTrainings() async {
    final response = await http.get(Uri.parse(Endpoint.training));
    if (response.statusCode == 200) {
      final data = json.decode(response.body);
      if (data['data'] != null && data['data'] is List) {
        setState(() {
          _trainings = List<Map<String, dynamic>>.from(
            data['data'].map(
              (training) => {
                'id': training['id']?.toString() ?? '',
                'title': training['title'] ?? 'Training',
              },
            ),
          );
        });
      }
    } else {
      log("Failed to load trainings: ${response.statusCode}");
    }
  }

  Future<void> _loadBatches() async {
    final response = await http.get(Uri.parse(Endpoint.batches));
    if (response.statusCode == 200) {
      final data = json.decode(response.body);
      if (data['data'] != null && data['data'] is List) {
        setState(() {
          _batches = List<Map<String, dynamic>>.from(
            data['data'].map(
              (batch) => {
                'id': batch['id']?.toString() ?? '',
                'batch_ke': batch['batch_ke']?.toString() ?? 'Batch',
              },
            ),
          );
        });
      }
    } else {
      log("Failed to load batches: ${response.statusCode}");
    }
  }

  void _handleDropdownError(dynamic error) {
    log("Error loading dropdown data: $error");
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: const Text("Gagal memuat data training/batch"),
          backgroundColor: Theme.of(context).colorScheme.error,
        ),
      );
    }
  }

  @override
  void dispose() {
    _fadeController.dispose();
    _slideController.dispose();
    _scaleController.dispose();
    _nameController.dispose();
    _emailController.dispose();
    _passwordController.dispose();
    _confirmPasswordController.dispose();
    _pageController.dispose();
    super.dispose();
  }

  void _nextStep() {
    if (_currentStep < 2) {
      setState(() => _currentStep++);
      _pageController.nextPage(
        duration: const Duration(milliseconds: 400),
        curve: Curves.easeInOutCubic,
      );
      HapticFeedback.selectionClick();
    }
  }

  void _previousStep() {
    if (_currentStep > 0) {
      setState(() => _currentStep--);
      _pageController.previousPage(
        duration: const Duration(milliseconds: 400),
        curve: Curves.easeInOutCubic,
      );
      HapticFeedback.selectionClick();
    }
  }

  bool _validateCurrentStep() {
    switch (_currentStep) {
      case 0:
        return _nameController.text.isNotEmpty &&
            _nameController.text.length >= 3 &&
            _emailController.text.isNotEmpty &&
            RegExp(
              r'^[\w-\.]+@([\w-]+\.)+[\w-]{2,4}$',
            ).hasMatch(_emailController.text) &&
            _selectedGender != null;
      case 1:
        return _selectedTraining != null && _selectedBatch != null;
      case 2:
        return _passwordController.text.isNotEmpty &&
            _passwordController.text.length >= 6 &&
            _confirmPasswordController.text == _passwordController.text;
      default:
        return false;
    }
  }

  void _handleStepButtonPress() {
    if (_isLoading) return;

    if (_currentStep < 2) {
      if (_validateCurrentStep()) {
        _nextStep();
      } else {
        _formKey.currentState!.validate();
      }
    } else {
      _handleRegister();
    }
  }

  void _handleRegister() async {
    if (!_validateCurrentStep()) {
      _formKey.currentState!.validate();
      return;
    }

    setState(() => _isLoading = true);
    HapticFeedback.lightImpact();

    try {
      final registrationData = {
        "name": _nameController.text.trim(),
        "email": _emailController.text.trim(),
        "password": _passwordController.text.trim(),
        "batch_id": int.parse(_selectedBatchId ?? "0"),
        "training_id": int.parse(_selectedTrainingId ?? "0"),
        "jenis_kelamin": _selectedGender ?? "Laki-laki",
      };

      final response = await http.post(
        Uri.parse(Endpoint.register),
        headers: {"Content-Type": "application/json"},
        body: jsonEncode(registrationData),
      );

      final responseData = json.decode(response.body);

      if (response.statusCode == 200 || response.statusCode == 201) {
        await _handleRegistrationSuccess(responseData);
      } else {
        _handleRegistrationError(responseData);
      }
    } catch (e) {
      _handleRegistrationException(e);
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  Future<void> _handleRegistrationSuccess(
    Map<String, dynamic> responseData,
  ) async {
    final registerResponse = registerModelFromJson(jsonEncode(responseData));
    final authService = AuthService();

    if (registerResponse.data != null) {
      final token = registerResponse.data!.token ?? "";
      final email = registerResponse.data!.user?.email ?? "";
      final name = registerResponse.data!.user?.name ?? "User";

      await authService.saveLogin(email, token, name);

      if (mounted) {
        Navigator.pushReplacement(
          context,
          PageRouteBuilder(
            pageBuilder: (context, animation, secondaryAnimation) =>
                const MainWrapper(),
            transitionsBuilder:
                (context, animation, secondaryAnimation, child) {
                  return FadeTransition(
                    opacity: animation,
                    child: SlideTransition(
                      position:
                          Tween<Offset>(
                            begin: const Offset(1.0, 0.0),
                            end: Offset.zero,
                          ).animate(
                            CurvedAnimation(
                              parent: animation,
                              curve: Curves.easeInOutCubic,
                            ),
                          ),
                      child: child,
                    ),
                  );
                },
            transitionDuration: const Duration(milliseconds: 600),
          ),
        );
      }
    }
  }

  void _handleRegistrationError(Map<String, dynamic> responseData) {
    final errorMessage =
        responseData['message'] ??
        responseData['error'] ??
        'Registrasi gagal. Silakan coba lagi.';

    if (responseData['errors'] != null) {
      final errors = responseData['errors'] as Map<String, dynamic>;
      final firstError = errors.values.first;
      if (firstError is List) {
        throw Exception(firstError.first ?? errorMessage);
      } else {
        throw Exception(firstError.toString());
      }
    } else {
      throw Exception(errorMessage);
    }
  }

  void _handleRegistrationException(dynamic error) {
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text("Registrasi gagal: ${error.toString()}"),
          backgroundColor: Theme.of(context).colorScheme.error,
          duration: const Duration(seconds: 3),
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    return Scaffold(
      backgroundColor: colorScheme.surface,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        leading: IconButton(
          icon: Icon(
            Icons.arrow_back_ios_rounded,
            color: colorScheme.onSurface,
          ),
          onPressed: () {
            HapticFeedback.selectionClick();
            Navigator.pop(context);
          },
        ),
        title: Text(
          'Daftar Akun',
          style: theme.textTheme.titleLarge?.copyWith(
            fontWeight: FontWeight.w600,
          ),
        ),
        centerTitle: true,
      ),
      body: FadeTransition(
        opacity: _fadeAnimation,
        child: SlideTransition(
          position: _slideAnimation,
          child: Column(
            children: [
              _buildProgressIndicator(context),
              const SizedBox(height: 16),
              _buildStepTitle(context),
              const SizedBox(height: 16),
              Expanded(
                child: ScaleTransition(
                  scale: _scaleAnimation,
                  child: _buildFormSteps(context),
                ),
              ),
              _buildBottomNavigation(context),
              _buildLoginLink(context),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildProgressIndicator(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 24),
      child: Column(
        children: [
          Row(
            children: List.generate(3, (index) {
              final isActive = index <= _currentStep;
              return Expanded(
                child: Container(
                  margin: EdgeInsets.only(right: index < 2 ? 8 : 0),
                  child: AnimatedContainer(
                    duration: const Duration(milliseconds: 300),
                    height: 4,
                    decoration: BoxDecoration(
                      color: isActive
                          ? colorScheme.primary
                          : colorScheme.outline.withOpacity(0.3),
                      borderRadius: BorderRadius.circular(2),
                    ),
                  ),
                ),
              );
            }),
          ),
          const SizedBox(height: 8),
          Text(
            '${_currentStep + 1}/3',
            style: Theme.of(context).textTheme.bodySmall?.copyWith(
              color: colorScheme.onSurface.withOpacity(0.6),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildStepTitle(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 24),
      child: AnimatedSwitcher(
        duration: const Duration(milliseconds: 300),
        child: Text(
          _stepTitles[_currentStep],
          key: ValueKey(_currentStep),
          style: Theme.of(
            context,
          ).textTheme.headlineSmall?.copyWith(fontWeight: FontWeight.w700),
          textAlign: TextAlign.center,
          maxLines: 2,
          overflow: TextOverflow.ellipsis,
        ),
      ),
    );
  }

  Widget _buildFormSteps(BuildContext context) {
    return Form(
      key: _formKey,
      child: PageView(
        controller: _pageController,
        physics: const NeverScrollableScrollPhysics(),
        children: [
          _buildPersonalInfoStep(context),
          _buildTrainingInfoStep(context),
          _buildSecurityStep(context),
        ],
      ),
    );
  }

  Widget _buildPersonalInfoStep(BuildContext context) {
    return SingleChildScrollView(
      physics: const BouncingScrollPhysics(),
      padding: const EdgeInsets.symmetric(horizontal: 24),
      child: Column(
        children: [
          _buildFormCard(
            context,
            children: [
              _buildTextField(
                context,
                controller: _nameController,
                label: 'Nama Lengkap',
                hint: 'Masukkan nama lengkap Anda',
                icon: Icons.person_outline,
                validator: _validateName,
              ),
              const SizedBox(height: 20),
              _buildTextField(
                context,
                controller: _emailController,
                label: 'Email',
                hint: 'Masukkan email Anda',
                icon: Icons.email_outlined,
                keyboardType: TextInputType.emailAddress,
                validator: _validateEmail,
              ),
              const SizedBox(height: 20),
              _buildDropdownField(
                context,
                value: _selectedGender,
                label: 'Jenis Kelamin',
                hint: 'Pilih jenis kelamin',
                icon: Icons.person_outline,
                items: _genders,
                onChanged: _handleGenderChange,
                validator: _validateGender,
              ),
            ],
          ),
        ],
      ),
    );
  }

  String? _validateName(String? value) {
    if (value == null || value.isEmpty) return 'Nama tidak boleh kosong';
    if (value.length < 3) return 'Nama minimal 3 karakter';
    return null;
  }

  String? _validateEmail(String? value) {
    if (value == null || value.isEmpty) return 'Email tidak boleh kosong';
    if (!RegExp(r'^[\w-\.]+@([\w-]+\.)+[\w-]{2,4}$').hasMatch(value)) {
      return 'Format email tidak valid';
    }
    return null;
  }

  String? _validateGender(String? value) {
    if (value == null || value.isEmpty) return 'Pilih jenis kelamin';
    return null;
  }

  void _handleGenderChange(String? value) {
    setState(() => _selectedGender = value);
    HapticFeedback.selectionClick();
  }

  Widget _buildTrainingInfoStep(BuildContext context) {
    return SingleChildScrollView(
      physics: const BouncingScrollPhysics(),
      padding: const EdgeInsets.symmetric(horizontal: 24),
      child: Column(
        children: [
          _buildFormCard(
            context,
            children: [
              _buildDropdownField(
                context,
                value: _selectedTraining,
                label: 'Training',
                hint: 'Pilih program training',
                icon: Icons.school_outlined,
                items: _trainings.map((t) => t['title'] as String).toList(),
                onChanged: _handleTrainingChange,
                validator: _validateTraining,
              ),
              const SizedBox(height: 20),
              _buildDropdownField(
                context,
                value: _selectedBatch,
                label: 'Batch',
                hint: 'Pilih batch training',
                icon: Icons.confirmation_number_outlined,
                items: _batches.map((b) => b['batch_ke'] as String).toList(),
                onChanged: _handleBatchChange,
                validator: _validateBatch,
              ),
            ],
          ),
        ],
      ),
    );
  }

  String? _validateTraining(String? value) {
    if (value == null || value.isEmpty) return 'Training tidak boleh kosong';
    return null;
  }

  String? _validateBatch(String? value) {
    if (value == null || value.isEmpty) return 'Batch tidak boleh kosong';
    return null;
  }

  void _handleTrainingChange(String? value) {
    setState(() {
      _selectedTraining = value;
      _selectedTrainingId = _trainings
          .firstWhere((t) => t['title'] == value)['id']
          .toString();
    });
    HapticFeedback.selectionClick();
  }

  void _handleBatchChange(String? value) {
    setState(() {
      _selectedBatch = value;
      _selectedBatchId = _batches
          .firstWhere((b) => b['batch_ke'] == value)['id']
          .toString();
    });
    HapticFeedback.selectionClick();
  }

  Widget _buildSecurityStep(BuildContext context) {
    return SingleChildScrollView(
      physics: const BouncingScrollPhysics(),
      padding: const EdgeInsets.symmetric(horizontal: 24),
      child: Column(
        children: [
          _buildFormCard(
            context,
            children: [
              _buildPasswordField(
                context,
                controller: _passwordController,
                label: 'Password',
                hint: 'Masukkan password',
                obscureText: _obscurePassword,
                onVisibilityToggle: _togglePasswordVisibility,
                validator: _validatePassword,
              ),
              const SizedBox(height: 20),
              _buildPasswordField(
                context,
                controller: _confirmPasswordController,
                label: 'Konfirmasi Password',
                hint: 'Masukkan ulang password',
                obscureText: _obscureConfirmPassword,
                onVisibilityToggle: _toggleConfirmPasswordVisibility,
                validator: _validateConfirmPassword,
              ),
            ],
          ),
        ],
      ),
    );
  }

  String? _validatePassword(String? value) {
    if (value == null || value.isEmpty) return 'Password tidak boleh kosong';
    if (value.length < 6) return 'Password minimal 6 karakter';
    return null;
  }

  String? _validateConfirmPassword(String? value) {
    if (value == null || value.isEmpty) {
      return 'Konfirmasi password tidak boleh kosong';
    }
    if (value != _passwordController.text) return 'Password tidak cocok';
    return null;
  }

  void _togglePasswordVisibility() {
    setState(() => _obscurePassword = !_obscurePassword);
    HapticFeedback.selectionClick();
  }

  void _toggleConfirmPasswordVisibility() {
    setState(() => _obscureConfirmPassword = !_obscureConfirmPassword);
    HapticFeedback.selectionClick();
  }

  Widget _buildFormCard(
    BuildContext context, {
    required List<Widget> children,
  }) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    return Container(
      width: double.infinity,
      constraints: const BoxConstraints(maxWidth: 400),
      padding: const EdgeInsets.all(24),
      margin: const EdgeInsets.only(bottom: 16),
      decoration: BoxDecoration(
        color: colorScheme.surface,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 16,
            offset: const Offset(0, 4),
          ),
        ],
        border: Border.all(
          color: colorScheme.outline.withOpacity(0.1),
          width: 1,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: children,
      ),
    );
  }

  Widget _buildTextField(
    BuildContext context, {
    required TextEditingController controller,
    required String label,
    required String hint,
    required IconData icon,
    TextInputType? keyboardType,
    String? Function(String?)? validator,
  }) {
    final theme = Theme.of(context);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: theme.textTheme.titleSmall?.copyWith(
            fontWeight: FontWeight.w600,
          ),
        ),
        const SizedBox(height: 8),
        TextFormField(
          controller: controller,
          keyboardType: keyboardType,
          textInputAction: TextInputAction.next,
          validator: validator,
          decoration: InputDecoration(
            hintText: hint,
            prefixIcon: Icon(
              icon,
              color: theme.colorScheme.onSurface.withOpacity(0.6),
            ),
            contentPadding: const EdgeInsets.symmetric(
              vertical: 16,
              horizontal: 16,
            ),
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: BorderSide(
                color: theme.colorScheme.outline.withOpacity(0.3),
              ),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildDropdownField(
    BuildContext context, {
    required String? value,
    required String label,
    required String hint,
    required IconData icon,
    required List<String> items,
    required Function(String?) onChanged,
    String? Function(String?)? validator,
  }) {
    final theme = Theme.of(context);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: theme.textTheme.titleSmall?.copyWith(
            fontWeight: FontWeight.w600,
          ),
        ),
        const SizedBox(height: 8),
        DropdownButtonFormField<String>(
          initialValue: value,
          items: items.map((String item) {
            return DropdownMenuItem<String>(
              value: item,
              child: Text(
                item,
                style: theme.textTheme.bodyMedium,
                overflow: TextOverflow.ellipsis,
              ),
            );
          }).toList(),
          onChanged: onChanged,
          validator: validator,
          decoration: InputDecoration(
            hintText: hint,
            prefixIcon: Icon(
              icon,
              color: theme.colorScheme.onSurface.withOpacity(0.6),
            ),
            contentPadding: const EdgeInsets.symmetric(
              vertical: 16,
              horizontal: 16,
            ),
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: BorderSide(
                color: theme.colorScheme.outline.withOpacity(0.3),
              ),
            ),
          ),
          icon: Icon(
            Icons.arrow_drop_down_rounded,
            color: theme.colorScheme.onSurface.withOpacity(0.6),
          ),
          isExpanded: true,
          dropdownColor: theme.colorScheme.surface,
        ),
      ],
    );
  }

  Widget _buildPasswordField(
    BuildContext context, {
    required TextEditingController controller,
    required String label,
    required String hint,
    required bool obscureText,
    required VoidCallback onVisibilityToggle,
    String? Function(String?)? validator,
  }) {
    final theme = Theme.of(context);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: theme.textTheme.titleSmall?.copyWith(
            fontWeight: FontWeight.w600,
          ),
        ),
        const SizedBox(height: 8),
        TextFormField(
          controller: controller,
          obscureText: obscureText,
          textInputAction: TextInputAction.done,
          validator: validator,
          decoration: InputDecoration(
            hintText: hint,
            prefixIcon: Icon(
              Icons.lock_outline,
              color: theme.colorScheme.onSurface.withOpacity(0.6),
            ),
            suffixIcon: IconButton(
              icon: Icon(
                obscureText
                    ? Icons.visibility_outlined
                    : Icons.visibility_off_outlined,
                color: theme.colorScheme.onSurface.withOpacity(0.6),
              ),
              onPressed: onVisibilityToggle,
            ),
            contentPadding: const EdgeInsets.symmetric(
              vertical: 16,
              horizontal: 16,
            ),
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: BorderSide(
                color: theme.colorScheme.outline.withOpacity(0.3),
              ),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildBottomNavigation(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      decoration: BoxDecoration(
        color: colorScheme.surface,
        border: Border(
          top: BorderSide(
            color: colorScheme.outline.withOpacity(0.1),
            width: 1,
          ),
        ),
      ),
      child: SafeArea(
        top: false,
        child: Row(
          children: [
            _buildBackButton(context),
            const SizedBox(width: 8),
            _buildNextButton(context),
          ],
        ),
      ),
    );
  }

  Widget _buildBackButton(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    return Expanded(
      child: OutlinedButton(
        onPressed: _isLoading
            ? null
            : () {
                if (_currentStep == 0) {
                  Navigator.pop(context);
                } else {
                  _previousStep();
                }
              },
        style: OutlinedButton.styleFrom(
          minimumSize: const Size(0, 48),
          padding: const EdgeInsets.symmetric(horizontal: 8),
          side: BorderSide(
            color: _currentStep == 0 ? Colors.transparent : colorScheme.primary,
          ),
          backgroundColor: _currentStep == 0
              ? Colors.transparent
              : colorScheme.surface,
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.arrow_back_ios_rounded,
              size: 14,
              color: _currentStep == 0
                  ? theme.disabledColor
                  : colorScheme.primary,
            ),
            const SizedBox(width: 4),
            Text(
              'Kembali',
              style: theme.textTheme.labelMedium?.copyWith(
                fontSize: 12,
                color: _currentStep == 0
                    ? theme.disabledColor
                    : colorScheme.primary,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildNextButton(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    return Expanded(
      child: ElevatedButton(
        onPressed: _isLoading ? null : _handleStepButtonPress,
        style: ElevatedButton.styleFrom(
          minimumSize: const Size(0, 48),
          padding: const EdgeInsets.symmetric(horizontal: 8),
          backgroundColor: colorScheme.primary,
          foregroundColor: Colors.white,
          elevation: 2,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
        ),
        child: _isLoading
            ? SizedBox(
                height: 18,
                width: 18,
                child: CircularProgressIndicator(
                  strokeWidth: 2,
                  valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                ),
              )
            : Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Text(
                    _currentStep < 2 ? 'Selanjutnya' : 'Daftar',
                    style: theme.textTheme.labelMedium?.copyWith(
                      fontSize: 12,
                      fontWeight: FontWeight.w600,
                      color: Colors.white,
                    ),
                  ),
                  if (_currentStep < 2) ...[
                    const SizedBox(width: 4),
                    Icon(
                      Icons.arrow_forward_ios_rounded,
                      size: 14,
                      color: Colors.white,
                    ),
                  ],
                ],
              ),
      ),
    );
  }

  Widget _buildLoginLink(BuildContext context) {
    final theme = Theme.of(context);

    return Padding(
      padding: const EdgeInsets.only(bottom: 16),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Text(
            'Sudah punya akun? ',
            style: theme.textTheme.bodyMedium?.copyWith(
              color: theme.colorScheme.onSurface.withOpacity(0.7),
            ),
          ),
          GestureDetector(
            onTap: _navigateToLogin,
            child: Text(
              'Masuk',
              style: theme.textTheme.bodyMedium?.copyWith(
                color: theme.colorScheme.primary,
                fontWeight: FontWeight.w600,
                decoration: TextDecoration.underline,
              ),
            ),
          ),
        ],
      ),
    );
  }

  void _navigateToLogin() {
    HapticFeedback.selectionClick();
    Navigator.pushReplacement(
      context,
      PageRouteBuilder(
        pageBuilder: (context, animation, secondaryAnimation) =>
            const LoginPage(),
        transitionsBuilder: (context, animation, secondaryAnimation, child) {
          return FadeTransition(
            opacity: animation,
            child: SlideTransition(
              position:
                  Tween<Offset>(
                    begin: const Offset(-1.0, 0.0),
                    end: Offset.zero,
                  ).animate(
                    CurvedAnimation(
                      parent: animation,
                      curve: Curves.easeInOutCubic,
                    ),
                  ),
              child: child,
            ),
          );
        },
        transitionDuration: const Duration(milliseconds: 400),
      ),
    );
  }
}
