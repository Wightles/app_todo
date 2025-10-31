import 'package:flutter/material.dart';
import 'package:app_todo/main.dart';
import 'package:app_todo/models/user_model.dart';
import 'package:uuid/uuid.dart';

class RegisterScene extends StatefulWidget {
  const RegisterScene({super.key});

  @override
  State<RegisterScene> createState() => _RegisterScene();
}

class _RegisterScene extends State<RegisterScene> {
  bool isLogin = true;
  bool _hidePass = true;
  final _formKey = GlobalKey<FormState>();
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  final _confirmPasswordController = TextEditingController();
  final _nameController = TextEditingController();

  // Генератор уникальных ID
  final Uuid _uuid = Uuid();

  // Генерация короткого ID (первые 8 символов)
  String _generateShortId() {
    return _uuid.v4().substring(0, 8);
  }

  void _toggleAuthMode() {
    setState(() {
      isLogin = !isLogin;
    });
  }

  void _submitForm() {
    if (_formKey.currentState!.validate()) {
      if (isLogin) {
        _loginUser();
      } else {
        _registerUser();
      }
    }
  }

  void _loginUser() {
    User user = User(
      name: _nameController.text.isNotEmpty
          ? _nameController.text
          : 'Пользователь',
      email: _emailController.text,
      id: _generateShortId(), // Короткий ID
    );
    Navigator.of(context).pushReplacement(
      MaterialPageRoute(
        builder: (context) => MainNavigationScreen(user: user),
      ),
    );
  }

  void _registerUser() {
    User user = User(
      name: _nameController.text,
      email: _emailController.text,
      id: _generateShortId(), // Короткий ID
    );
    Navigator.of(context).pushReplacement(
      MaterialPageRoute(
        builder: (context) => MainNavigationScreen(user: user),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      body: SingleChildScrollView(
        child: Padding(
          padding: EdgeInsets.all(20),
          child: Column(
            children: [
              SizedBox(height: 20),
              Image.asset(
                'assets/images/test2.png',
                height: 200,
                width: 200,
                fit: BoxFit.contain,
              ),
              SizedBox(height: 30),
              Text(
                isLogin ? 'Вход' : 'Регистрация',
                style: TextStyle(
                  fontSize: 28,
                  fontWeight: FontWeight.bold,
                  color: Color.fromARGB(255, 16, 134, 134),
                ),
              ),
              SizedBox(height: 30),
              Form(
                key: _formKey,
                child: Column(
                  children: [
                    if (!isLogin)
                      TextFormField(
                        controller: _nameController,
                        decoration: InputDecoration(
                          labelText: 'Имя',
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(10),
                          ),
                          prefixIcon: Icon(Icons.person),
                        ),
                        validator: (value) {
                          if (value == null || value.isEmpty) {
                            return 'Введите имя';
                          }
                          return null;
                        },
                      ),
                    if (!isLogin) const SizedBox(height: 15),
                    TextFormField(
                      controller: _emailController,
                      decoration: InputDecoration(
                        labelText: 'Почта',
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(10),
                        ),
                        prefixIcon: Icon(Icons.email),
                      ),
                      keyboardType: TextInputType.emailAddress,
                      validator: (value) {
                        if (value == null || value.isEmpty) {
                          return 'Введите почту';
                        }
                        if (!value.contains('@')) {
                          return 'Введите корректный email';
                        }
                        return null;
                      },
                    ),
                    SizedBox(height: 15),
                    TextFormField(
                      controller: _passwordController,
                      decoration: InputDecoration(
                        labelText: 'Пароль',
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(10),
                        ),
                        prefixIcon: Icon(Icons.lock),
                        suffixIcon: IconButton(
                          onPressed: () {
                            setState(() {
                              _hidePass = !_hidePass;
                            });
                          },
                          icon: Icon(_hidePass
                              ? Icons.visibility
                              : Icons.visibility_off),
                        ),
                      ),
                      obscureText: _hidePass,
                      validator: (value) {
                        if (value == null || value.isEmpty) {
                          return 'Введите пароль';
                        }
                        if (value.length < 6) {
                          return 'Пароль должен быть не менее 6 символов';
                        }
                        return null;
                      },
                    ),
                    if (!isLogin) const SizedBox(height: 15),
                    if (!isLogin)
                      TextFormField(
                        controller: _confirmPasswordController,
                        decoration: InputDecoration(
                          labelText: 'Подтвердите пароль',
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(10),
                          ),
                          prefixIcon: Icon(Icons.lock_outline),
                          suffixIcon: IconButton(
                            onPressed: () {
                              setState(() {
                                _hidePass = !_hidePass;
                              });
                            },
                            icon: Icon(_hidePass
                                ? Icons.visibility
                                : Icons.visibility_off),
                          ),
                        ),
                        obscureText: _hidePass,
                        validator: (value) {
                          if (value == null || value.isEmpty) {
                            return 'Подтвердите пароль';
                          }
                          if (value != _passwordController.text) {
                            return 'Пароли должны совпадать';
                          }
                          return null;
                        },
                      ),
                    SizedBox(height: 20),
                    ElevatedButton(
                      onPressed: _submitForm,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Color.fromARGB(255, 16, 134, 134),
                        foregroundColor: Colors.white,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(10),
                        ),
                      ),
                      child: Text(
                        isLogin ? 'Войти' : 'Зарегистрироваться',
                        style: const TextStyle(fontSize: 16),
                      ),
                    ),
                    SizedBox(height: 20),
                    TextButton(
                      onPressed: _toggleAuthMode,
                      child: Text(
                        isLogin
                            ? 'Нет аккаунта? Зарегистрироваться'
                            : 'Уже есть аккаунт? Войти',
                        style: const TextStyle(
                          color: Color.fromARGB(255, 16, 134, 134),
                          fontSize: 16,
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
    );
  }

  @override
  void dispose() {
    _emailController.dispose();
    _passwordController.dispose();
    _confirmPasswordController.dispose();
    _nameController.dispose();
    super.dispose();
  }
}