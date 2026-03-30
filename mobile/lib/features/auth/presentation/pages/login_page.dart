import 'package:flutter/material.dart';
import '../../data/repositories/auth_repository.dart';
import '../../../../shared/widgets/campo_texto.dart';
import 'package:google_fonts/google_fonts.dart';

class LoginPage extends StatefulWidget {
  const LoginPage({super.key});

  @override
  State<LoginPage> createState() => _LoginPageState();
}

class _LoginPageState extends State<LoginPage> {
  final _emailController = TextEditingController();
  final _senhaController = TextEditingController();

  final _repository = AuthRepository();

  bool _isLoading = false;

  Future<void> _login() async {
    setState(() => _isLoading = true);

    try {
      await _repository.login(_emailController.text, _senhaController.text);

      if (!mounted) return;
      Navigator.pushReplacementNamed(context, '/home');
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text(e.toString())));
    } finally {
      setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF4A3F8F),
      body: Stack(
        children: [
          Container(
            decoration: const BoxDecoration(
              gradient: LinearGradient(
                colors: [Color(0xFFE91E8C), Color(0xFF4A3F8F)],
                begin: Alignment.centerLeft,
                end: Alignment.centerRight,
              ),
            ),
          ),
          // logo posicionada no topo
          Positioned(
            top: 50,
            left: 0,
            right: 0,
            child: Column(
              children: [
                Image.asset(
                  'assets/images/logoBranca.png',
                  width: 100,
                  height: 80,
                ),
                Text(
                  'MesclaInvest',
                  style: GoogleFonts.nunito(
                    textStyle: const TextStyle(
                      fontSize: 32,
                      fontWeight: FontWeight
                          .w800, // Deixa a fonte mais gordinha, parecida com a imagem
                      color: Colors.white,
                    ),
                  ),
                ),
              ],
            ),
          ),
          Column(
            children: [
              const SizedBox(height: 200),
              Expanded(
                child: Card(
                  color: Color.fromARGB(255, 255, 255, 255),
                  elevation: 4,
                  margin: EdgeInsets.zero,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.only(
                      topLeft: Radius.circular(50),
                    ),
                  ),
                  child: Container(
                    width: double.infinity,
                    padding: EdgeInsets.all(16),
                    child: Column(
                      children: [
                        Container(
                          margin: const EdgeInsets.only(bottom: 30, top: 20),
                          child: const Text(
                            'Login',
                            style: TextStyle(
                              fontSize: 24,
                              fontWeight: FontWeight.w800,
                              color: Color(0xFF2D2558), // darkNavy
                            ),
                          ),
                        ),
                        CampoTexto(
                          controller: _emailController,
                          label: 'E-mail',
                          keyboardType: TextInputType.emailAddress,
                        ),
                        SizedBox(height: 20),
                        CampoTexto(
                          controller: _senhaController,
                          label: 'Senha',
                          obscureText: true,
                        ),
                        Transform.translate(
                          offset: const Offset(
                            -16,
                            -8,
                          ), // x negativo = esquerda, y negativo = cima
                          child: Align(
                            alignment: Alignment.centerRight,
                            child: TextButton(
                              onPressed: () {},
                              style: TextButton.styleFrom(
                                splashFactory: NoSplash.splashFactory,
                                overlayColor: Colors.transparent,
                              ),
                              child: const Text(
                                'Esqueceu sua senha?',
                                style: TextStyle(
                                  color: Color.fromARGB(70, 0, 0, 0),
                                  fontSize: 14,
                                  fontWeight: FontWeight.w500,
                                ),
                              ),
                            ),
                          ),
                        ),
                        SizedBox(height: 32),
                        _isLoading
                            ? const CircularProgressIndicator(
                                color: Color(0xFF4A3F8F),
                                backgroundColor: Color(0xFFE91E8C),
                              )
                            : Transform.translate(
                                offset: const Offset(0, -30),
                                child: Container(
                                  decoration: BoxDecoration(
                                    borderRadius: BorderRadius.circular(12),
                                    boxShadow: [
                                      BoxShadow(
                                        color: Colors.black.withOpacity(0.08),
                                        blurRadius: 8,
                                        offset: const Offset(0, 2),
                                      ),
                                    ],
                                  ),
                                  child: ElevatedButton(
                                    onPressed: _login,
                                    style: ElevatedButton.styleFrom(
                                      backgroundColor: Color(0xFFE91E8C),
                                      foregroundColor: const Color.fromARGB(
                                        255,
                                        0,
                                        0,
                                        0,
                                      ),
                                      elevation: 0,
                                      shape: RoundedRectangleBorder(
                                        borderRadius: BorderRadius.circular(12),
                                        side: BorderSide.none,
                                      ),
                                    ),
                                    child: SizedBox(
                                      height: 60,
                                      width: 200,
                                      child: Container(
                                        padding: const EdgeInsets.symmetric(),
                                        child: Row(
                                          mainAxisSize: MainAxisSize.min,
                                          mainAxisAlignment:
                                              MainAxisAlignment.center,
                                          children: [
                                            const Text(
                                              'Login',
                                              style: TextStyle(
                                                fontSize: 16,
                                                fontWeight: FontWeight.w600,
                                                color: Color.fromARGB(
                                                  255,
                                                  255,
                                                  255,
                                                  255,
                                                ),
                                              ),
                                            ),
                                          ],
                                        ),
                                      ),
                                    ),
                                  ),
                                ),
                              ),
                        Container(
                          alignment: Alignment.center,
                          child: Row(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              const Text(
                                'Não tem uma conta?',
                                style: TextStyle(
                                  color: Color.fromARGB(60, 0, 0, 0),
                                  fontSize: 14,
                                  fontWeight: FontWeight.w500,
                                ),
                              ),
                              TextButton(
                                onPressed: () {
                                  Navigator.pushNamed(context, '/register');
                                },
                                style: TextButton.styleFrom(
                                  splashFactory: NoSplash.splashFactory,
                                  overlayColor: Colors.transparent,
                                ),
                                child: const Text(
                                  'Cadastre-se',
                                  style: TextStyle(
                                    color: Color(0xFF4A3F8F),
                                    fontSize: 14,
                                    fontWeight: FontWeight.w700,
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
            ],
          ),
        ],
      ),
    );
  }
}
