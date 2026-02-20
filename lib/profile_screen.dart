
import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:email_otp/email_otp.dart';
import 'services/auth_service.dart';
import 'services/firestore_service.dart';

class ProfileScreen extends StatefulWidget {
  const ProfileScreen({super.key});

  @override
  State<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends State<ProfileScreen> with SingleTickerProviderStateMixin {
  final AuthService _authService = AuthService();
  final FirestoreService _firestoreService = FirestoreService();
  
  late TabController _tabController;
  final _formKey = GlobalKey<FormState>(); // Form Key for validation
  
  // Controllers
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  final _nameController = TextEditingController();
  final _mobileController = TextEditingController();
  final _dobController = TextEditingController();
  final _otpController = TextEditingController();

  bool _isLoading = false;
  bool _otpSent = false;
  bool _isEmailVerified = false;
  
  // OTP Auth
  final EmailOTP _myAuth = EmailOTP();

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
  }

  @override
  void dispose() {
    _tabController.dispose();
    _emailController.dispose();
    _passwordController.dispose();
    _nameController.dispose();
    _mobileController.dispose();
    _dobController.dispose();
    _otpController.dispose();
    super.dispose();
  }

  // Validators
  String? _validateEmail(String? value) {
    if (value == null || value.isEmpty) return 'Email is required';
    final emailRegex = RegExp(r"^[a-zA-Z0-9.a-zA-Z0-9.!#$%&'*+-/=?^_`{|}~]+@[a-zA-Z0-9]+\.[a-zA-Z]+");
    if (!emailRegex.hasMatch(value)) return 'Enter a valid email';
    return null;
  }

  String? _validateRequired(String? value, String fieldName) {
    if (value == null || value.isEmpty) return '$fieldName is required';
    return null;
  }

  String? _validateMobile(String? value) {
    if (value == null || value.isEmpty) return 'Mobile number is required';
    if (value.length < 10) return 'Enter a valid mobile number';
    return null;
  }

  // OTP Logic
  Future<void> _sendOTP() async {
    if (_validateEmail(_emailController.text) != null) {
      _showError('Please enter a valid email first');
      return;
    }
    
    setState(() => _isLoading = true);
    
    // Config OTP
    _myAuth.setConfig(
      appEmail: "me@rohitchouhan.com", // Default sender from package
      appName: "QR Master",
      userEmail: _emailController.text,
      otpLength: 6,
      otpType: OTPType.digitsOnly
    );

    if (await _myAuth.sendOTP() == true) {
      if (mounted) {
        setState(() {
          _isLoading = false;
          _otpSent = true;
        });
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text("OTP sent to your email")));
      }
    } else {
      if (mounted) {
        setState(() => _isLoading = false);
        _showError("Failed to send OTP. Try again.");
      }
    }
  }

  Future<void> _verifyOTP() async {
    if (_otpController.text.length != 6) {
      _showError('Enter 6-digit OTP');
      return;
    }
    
    if (await _myAuth.verifyOTP(otp: _otpController.text) == true) {
      if (mounted) {
        setState(() {
           _isEmailVerified = true;
           _otpSent = false; // Hide OTP field
        });
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text("Email Verified Successfully!")));
      }
    } else {
      _showError("Invalid OTP");
    }
  }

  Future<void> _login() async {
    setState(() => _isLoading = true);
    try {
      if (_emailController.text.isEmpty || _passwordController.text.isEmpty) {
         throw FirebaseAuthException(code: 'empty-fields', message: 'Please enter email and password');
      }
      await _authService.signInWithEmail(_emailController.text.trim(), _passwordController.text.trim());
    } on FirebaseAuthException catch (e) {
      _showError(e.message ?? 'Login failed');
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  Future<void> _register() async {
    if (!_formKey.currentState!.validate()) return;
    if (!_isEmailVerified) {
       _showError('Please verify your email with OTP first');
       return;
    }

    setState(() => _isLoading = true);
    try {
      final user = await _authService.registerWithEmail(_emailController.text.trim(), _passwordController.text.trim());
      if (user != null) {
        if (_nameController.text.isNotEmpty) {
           await user.updateDisplayName(_nameController.text.trim());
        }
        await _firestoreService.saveUserProfile(
          mobile: _mobileController.text.trim(),
          dob: _dobController.text.trim()
        );
        
        // No need to send link verification as we did OTP
        
        if (mounted) {
           _showError('Account Created Successfully!');
           _tabController.animateTo(0); // Go to login
        }
      }
    } on FirebaseAuthException catch (e) {
      _showError(e.message ?? 'Registration failed');
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  Future<void> _googleLogin() async {
     setState(() => _isLoading = true);
     try {
       final userCredential = await _authService.signInWithGoogle();
       if (userCredential != null) {
          await _firestoreService.saveUserProfile();
       }
     } catch (e) {
       _showError('Google Sign-In failed');
     } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  Future<void> _resetPassword() async {
    if (_emailController.text.isEmpty) {
      _showError('Please enter your email to reset password');
      return;
    }
    try {
      await _authService.sendPasswordResetEmail(_emailController.text.trim());
      if (mounted) ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Password reset email sent')));
    } catch (e) {
      _showError('Failed to send reset email');
    }
  }

  void _showError(String message) {
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(message), backgroundColor: Colors.red));
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Profile'),
        backgroundColor: Colors.transparent,
        elevation: 0,
        foregroundColor: Colors.deepPurple,
      ),
      extendBodyBehindAppBar: true, 
      body: Container(
         height: double.infinity,
         decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [Colors.deepPurple.shade50, Colors.white],
          ),
        ),
        child: StreamBuilder<User?>(
          stream: _authService.authStateChanges,
          builder: (context, snapshot) {
            if (snapshot.connectionState == ConnectionState.waiting) {
              return const Center(child: CircularProgressIndicator());
            }
            if (snapshot.data != null) {
              return _LoggedInView(user: snapshot.data!, firestoreService: _firestoreService, authService: _authService);
            }
            return _buildAuthView();
          },
        ),
      ),
    );
  }

  Widget _buildAuthView() {
    return SafeArea(
      child: Center(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(24),
          child: Card(
            elevation: 8,
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
            child: Padding(
              padding: const EdgeInsets.all(24),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  TabBar(
                    controller: _tabController,
                    labelColor: Colors.deepPurple,
                    unselectedLabelColor: Colors.grey,
                    indicatorColor: Colors.deepPurple,
                    tabs: const [
                       Tab(text: 'Login'),
                       Tab(text: 'Register'),
                    ],
                  ),
                  const SizedBox(height: 24),
                  SizedBox(
                    height: 550, // Increased height for form
                    child: TabBarView(
                      controller: _tabController,
                      children: [
                        // Login Tab (Unchanged)
                        Column(
                          children: [
                            TextField(
                              controller: _emailController,
                              decoration: const InputDecoration(labelText: 'Email', prefixIcon: Icon(Icons.email)),
                              keyboardType: TextInputType.emailAddress,
                            ),
                            TextField(
                              controller: _passwordController,
                              decoration: const InputDecoration(labelText: 'Password', prefixIcon: Icon(Icons.lock)),
                              obscureText: true,
                            ),
                            Align(
                              alignment: Alignment.centerRight,
                              child: TextButton(
                                onPressed: _resetPassword,
                                child: const Text('Forgot Password?'),
                              ),
                            ),
                            const SizedBox(height: 16),
                            if (_isLoading) const CircularProgressIndicator() else 
                            ElevatedButton(
                              onPressed: _login,
                              style: ElevatedButton.styleFrom(minimumSize: const Size(double.infinity, 50)),
                              child: const Text('Login'),
                            ),
                            const SizedBox(height: 16),
                            const Text('OR'),
                            const SizedBox(height: 16),
                            OutlinedButton.icon(
                              onPressed: _googleLogin,
                              icon: const Icon(Icons.g_mobiledata, size: 28),
                              label: const Text('Sign in with Google'), 
                              style: OutlinedButton.styleFrom(minimumSize: const Size(double.infinity, 50)),
                            ),
                          ],
                        ),
                        // Register Tab (With OTP)
                        SingleChildScrollView(
                          child: Form(
                            key: _formKey,
                            child: Column(
                              children: [
                                TextFormField(
                                  controller: _nameController,
                                  decoration: const InputDecoration(labelText: 'Full Name *', prefixIcon: Icon(Icons.person)),
                                  validator: (v) => _validateRequired(v, 'Name'),
                                ),
                                Row(
                                  children: [
                                    Expanded(
                                      child: TextFormField(
                                        controller: _emailController, 
                                        decoration: InputDecoration(
                                          labelText: 'Email *', 
                                          prefixIcon: const Icon(Icons.email),
                                          suffixIcon: _isEmailVerified 
                                            ? const Icon(Icons.check_circle, color: Colors.green)
                                            : null
                                        ),
                                        keyboardType: TextInputType.emailAddress,
                                        validator: _validateEmail,
                                        readOnly: _isEmailVerified, // Lock email after verification
                                      ),
                                    ),
                                    if (!_isEmailVerified)
                                      TextButton(
                                        onPressed: _otpSent ? null : _sendOTP,
                                        child: Text(_otpSent ? 'Sent' : 'Send OTP'),
                                      ),
                                  ],
                                ),
                                
                                if (_otpSent && !_isEmailVerified)
                                  Row(
                                    children: [
                                      Expanded(
                                        child: TextField(
                                          controller: _otpController,
                                          decoration: const InputDecoration(labelText: 'Enter 6-digit OTP', prefixIcon: Icon(Icons.lock_clock)),
                                          keyboardType: TextInputType.number,
                                          maxLength: 6,
                                        ),
                                      ),
                                      TextButton(
                                        onPressed: _verifyOTP,
                                        child: const Text('Verify'),
                                      ),
                                    ],
                                  ),

                                TextFormField(
                                  controller: _passwordController,
                                  decoration: const InputDecoration(labelText: 'Password *', prefixIcon: Icon(Icons.lock)),
                                  obscureText: true,
                                  validator: (v) => _validateRequired(v, 'Password'),
                                ),
                                TextFormField(
                                  controller: _mobileController,
                                  decoration: const InputDecoration(labelText: 'Mobile Number *', prefixIcon: Icon(Icons.phone)),
                                  keyboardType: TextInputType.phone,
                                  validator: _validateMobile,
                                ),
                                 TextFormField(
                                  controller: _dobController,
                                  decoration: const InputDecoration(labelText: 'Date of Birth * (YYYY-MM-DD)', prefixIcon: Icon(Icons.calendar_today)),
                                  readOnly: true,
                                  validator: (v) => _validateRequired(v, 'Date of Birth'),
                                  onTap: () async {
                                    final date = await showDatePicker(
                                      context: context, 
                                      initialDate: DateTime.now(), 
                                      firstDate: DateTime(1900), 
                                      lastDate: DateTime.now()
                                    );
                                    if (date != null) {
                                      _dobController.text = "${date.year}-${date.month.toString().padLeft(2,'0')}-${date.day.toString().padLeft(2,'0')}";
                                    }
                                  },
                                ),
                                const SizedBox(height: 24),
                                 if (_isLoading) const CircularProgressIndicator() else 
                                ElevatedButton(
                                  onPressed: _isEmailVerified ? _register : null, // Disable until Verified
                                  style: ElevatedButton.styleFrom(minimumSize: const Size(double.infinity, 50)),
                                  child: const Text('Register'),
                                ),
                              ],
                            ),
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
      ),
    );
  }
}

// LoggedIn View remains the same
class _LoggedInView extends StatefulWidget {
  final User user;
  final FirestoreService firestoreService;
  final AuthService authService;

  const _LoggedInView({required this.user, required this.firestoreService, required this.authService});

  @override
  State<_LoggedInView> createState() => _LoggedInViewState();
}

class _LoggedInViewState extends State<_LoggedInView> {
  final _mobileController = TextEditingController();
  final _dobController = TextEditingController();
  bool _editing = false;
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    _loadProfile();
  }

  Future<void> _loadProfile() async {
    final data = await widget.firestoreService.getUserProfile();
    if (data != null) {
      _mobileController.text = data['mobile'] ?? '';
      _dobController.text = data['dob'] ?? '';
    }
    if (mounted) setState(() => _loading = false);
  }

  Future<void> _saveProfile() async {
     setState(() => _loading = true);
     await widget.firestoreService.saveUserProfile(
       mobile: _mobileController.text,
       dob: _dobController.text,
     );
     setState(() {
       _loading = false;
       _editing = false;
     });
     if (mounted) ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Profile Updated')));
  }

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      child: Center(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(24),
          child: Column(
            children: [
              CircleAvatar(
                radius: 50,
                backgroundImage: widget.user.photoURL != null ? NetworkImage(widget.user.photoURL!) : null,
                child: widget.user.photoURL == null ? const Icon(Icons.person, size: 60) : null,
              ),
              const SizedBox(height: 16),
              Text(widget.user.displayName ?? 'User', style: const TextStyle(fontSize: 24, fontWeight: FontWeight.bold)),
              
              Text(widget.user.email ?? '', style: TextStyle(color: Colors.grey[600])),
              const SizedBox(height: 32),
              
              Card(
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                child: Padding(
                  padding: const EdgeInsets.all(16),
                   child: _loading ? const Center(child: CircularProgressIndicator()) : Column(
                     children: [
                       Row(
                         mainAxisAlignment: MainAxisAlignment.spaceBetween,
                         children: [
                           const Text('Profile Details', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                           IconButton(
                             icon: Icon(_editing ? Icons.check : Icons.edit),
                             onPressed: _editing ? _saveProfile : () => setState(() => _editing = true),
                           )
                         ],
                       ),
                       const Divider(),
                       TextField(
                         controller: _mobileController,
                         enabled: _editing,
                         decoration: const InputDecoration(labelText: 'Mobile Number', prefixIcon: Icon(Icons.phone)),
                       ),
                       TextField(
                         controller: _dobController,
                         enabled: _editing,
                         decoration: const InputDecoration(labelText: 'Date of Birth', prefixIcon: Icon(Icons.calendar_today)),
                       ),
                     ],
                   ),
                ),
              ),
              const SizedBox(height: 24),
              ElevatedButton.icon(
                onPressed: () => widget.authService.signOut(),
                icon: const Icon(Icons.logout),
                label: const Text('Sign Out'),
                style: ElevatedButton.styleFrom(backgroundColor: Colors.redAccent, foregroundColor: Colors.white),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
