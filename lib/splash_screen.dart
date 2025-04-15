import 'package:flutter/material.dart';
import 'dart:async';

class SplashScreen extends StatefulWidget {
  const SplashScreen({super.key});

  @override
  State<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen> {
  double _opacity = 0.0; // Controle da opacidade

  @override
  void initState() {
    super.initState();

    // Iniciar a animação de fade-in
    Timer(const Duration(milliseconds: 500), () {
      setState(() {
        _opacity = 1.0;
      });
    });

    // Navegar para a tela de login após 5 segundos
    Timer(const Duration(seconds: 5), () {
      Navigator.pushReplacementNamed(context, '/login');
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Container(
        width: double.infinity,
        height: double.infinity,
        color:Color(0xFF07063a), // Cor de fundo #D90000
        child: Center(
          child: AnimatedOpacity(
            opacity: _opacity,
            duration: const Duration(seconds: 1), // Tempo da animação
            curve: Curves.easeInOut,
            child: Image.asset(
              'assets/logo1.png', // Caminho correto do arquivo
              width: 200, // Ajuste de tamanho
            ),
          ),
        ),
      ),
    );
  }
}
