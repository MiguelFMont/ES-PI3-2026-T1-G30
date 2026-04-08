// Autor: Miguel Fernandes Monteiro
// RA: 25014808
import 'package:flutter/material.dart';
import '../../data/repositories/auth_repository.dart';
import '../../../../shared/widgets/campo_texto.dart';
import '../../../../shared/widgets/campo_data.dart';
import 'package:google_fonts/google_fonts.dart';
// import '../../../../shared/validators/cpf_validator.dart';
import '../../../../shared/formatters/cpf_formatter.dart';

class CadastroPage extends StatefulWidget {
  const CadastroPage({super.key});

  @override
  State<CadastroPage> createState() => _CadastroPageState();
}

class _CadastroPageState extends State<CadastroPage> {
  final _nomeController = TextEditingController();
  final _emailController = TextEditingController();
  final _cpfController = TextEditingController();
  final _telefoneController = TextEditingController();
  final _senhaController = TextEditingController();

  // Data de nascimento armazenada como DateTime
  DateTime? _dataNascimento;

  final _pageController = PageController();
  final _repository = AuthRepository();
  int _etapaAtual = 0;

  bool _isLoading = false;

  Future<void> _cadastrar() async {
    if (_dataNascimento == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Preencha sua data de nascimento')),
      );
      return;
    }

    setState(() => _isLoading = true);

    try {
      await _repository.cadastro(
        _dataNascimento!.toIso8601String(),
        _nomeController.text,
        _emailController.text,
        _cpfController.text,
        _telefoneController.text,
        _senhaController.text,
      );

      if (!mounted) return;
      Navigator.pushReplacementNamed(context, '/login');
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
  void initState() {
    super.initState();
    _pageController.addListener(() {
      setState(() {
        _etapaAtual = _pageController.page?.round() ?? 0;
      });
    });
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
                colors: [Color(0xFF4A3F8F), Color(0xFFE91E8C)],
                begin: Alignment.centerLeft,
                end: Alignment.centerRight,
              ),
            ),
          ),
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
                      fontWeight: FontWeight.w800,
                      color: Colors.white,
                    ),
                  ),
                ),
              ],
            ),
          ),
          SingleChildScrollView(
            child: SizedBox(
              height: MediaQuery.of(context).size.height,
              child: Column(
                children: [
                  const SizedBox(height: 200),
                  Expanded(
                    child: Card(
                      color: Colors.white,
                      elevation: 4,
                      margin: EdgeInsets.zero,
                      shape: const RoundedRectangleBorder(
                        borderRadius: BorderRadius.only(
                          topRight: Radius.circular(50),
                        ),
                      ),
                      child: Container(
                        width: double.infinity,
                        padding: const EdgeInsets.all(16),
                        child: Column(
                          children: [
                            Container(
                              margin: const EdgeInsets.only(bottom: 30, top: 5),
                              child: const Text(
                                'Cadastro',
                                style: TextStyle(
                                  fontSize: 24,
                                  fontWeight: FontWeight.w800,
                                  color: Color(0xFF2D2558),
                                ),
                              ),
                            ),
                            Expanded(
                              child: PageView(
                                controller: _pageController,
                                physics: const NeverScrollableScrollPhysics(),
                                children: [
                                  // --- ETAPA 1: Data de nascimento e CPF ---
                                  SingleChildScrollView(
                                    child: Column(
                                      children: [
                                        CampoData(
                                          onDateChanged: (date) {
                                            setState(
                                              () => _dataNascimento = date,
                                            );
                                          },
                                        ),
                                        const SizedBox(height: 16),
                                        CampoTexto(
                                          controller: _cpfController,
                                          label: 'CPF',
                                          keyboardType: TextInputType.number,
                                          inputFormatters: [CpfFormatter()],
                                        ),
                                        Padding(
                                          padding: const EdgeInsets.only(
                                            top: 20,
                                          ),
                                          child: _botaoAvancar(),
                                        ),
                                      ],
                                    ),
                                  ),
                                  // --- ETAPA 2: Nome Completo ---
                                  SingleChildScrollView(
                                    child: Column(
                                      children: [
                                        CampoTexto(
                                          controller: _telefoneController,
                                          label: 'Telefone',
                                          keyboardType: TextInputType.phone,
                                        ),
                                        const SizedBox(height: 10),
                                        CampoTexto(
                                          controller: _nomeController,
                                          label: 'Nome Completo',
                                          keyboardType: TextInputType.name,
                                        ),
                                        Padding(
                                          padding: const EdgeInsets.only(
                                            top: 20,
                                          ),
                                          child: _botaoAvancar(),
                                        ),
                                        const SizedBox(height: 10),
                                        _botaoVoltar(),
                                      ],
                                    ),
                                  ),
                                  // --- ETAPA 3: Telefone, E-mail e Senha ---
                                  SingleChildScrollView(
                                    child: Column(
                                      children: [
                                        CampoTexto(
                                          controller: _emailController,
                                          label: 'E-mail',
                                          keyboardType:
                                              TextInputType.emailAddress,
                                        ),
                                        const SizedBox(height: 10),
                                        CampoTexto(
                                          controller: _senhaController,
                                          label: 'Senha',
                                          obscureText: true,
                                        ),
                                        const SizedBox(height: 20),
                                        _isLoading
                                            ? const CircularProgressIndicator(
                                                color: Color(0xFF4A3F8F),
                                                backgroundColor: Color(
                                                  0xFFE91E8C,
                                                ),
                                              )
                                            : Column(
                                                children: [
                                                  _botaoCadastrar(),
                                                  const SizedBox(height: 10),
                                                  _botaoVoltar(),
                                                ],
                                              ),
                                      ],
                                    ),
                                  ),
                                ],
                              ),
                            ),
                            // Indicador de etapas
                            Padding(
                              padding: const EdgeInsets.only(top: 16),
                              child: Row(
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: List.generate(3, (index) {
                                  return Container(
                                    margin: const EdgeInsets.symmetric(
                                      horizontal: 4,
                                    ),
                                    width: 8,
                                    height: 8,
                                    decoration: BoxDecoration(
                                      shape: BoxShape.circle,
                                      color: _etapaAtual == index
                                          ? const Color(0xFFE91E8C)
                                          : const Color(0xFFEAE8F5),
                                    ),
                                  );
                                }),
                              ),
                            ),
                            Row(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                const Text(
                                  'Já tem uma conta?',
                                  style: TextStyle(
                                    color: Color.fromARGB(60, 0, 0, 0),
                                    fontSize: 14,
                                    fontWeight: FontWeight.w500,
                                  ),
                                ),
                                TextButton(
                                  onPressed: () {
                                    Navigator.pushNamed(context, '/login');
                                  },
                                  style: TextButton.styleFrom(
                                    splashFactory: NoSplash.splashFactory,
                                    overlayColor: Colors.transparent,
                                  ),
                                  child: const Text(
                                    'Login',
                                    style: TextStyle(
                                      color: Color(0xFF4A3F8F),
                                      fontSize: 14,
                                      fontWeight: FontWeight.w700,
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  // --- Widgets auxiliares extraídos para evitar repetição ---

  Widget _botaoAvancar() {
    return Container(
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
        onPressed: () {
          // if (!CpfValidator.isValid(_cpfController.text)) {
          //   ScaffoldMessenger.of(
          //     context,
          //   ).showSnackBar(const SnackBar(content: Text('CPF inválido')));
          //   return;
          // }
          _pageController.nextPage(
            duration: const Duration(milliseconds: 300),
            curve: Curves.easeInOut,
          );
        },
        style: ElevatedButton.styleFrom(
          backgroundColor: const Color(0xFFE91E8C),
          foregroundColor: Colors.black,
          elevation: 0,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
        ),
        child: const SizedBox(
          height: 60,
          width: 200,
          child: Center(
            child: Text(
              'Avançar',
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.w600,
                color: Colors.white,
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _botaoCadastrar() {
    return Container(
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
        onPressed: _cadastrar,
        style: ElevatedButton.styleFrom(
          backgroundColor: const Color(0xFFE91E8C),
          foregroundColor: Colors.black,
          elevation: 0,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
        ),
        child: const SizedBox(
          height: 60,
          width: 200,
          child: Center(
            child: Text(
              'Cadastrar',
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.w600,
                color: Colors.white,
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _botaoVoltar() {
    return TextButton(
      onPressed: () {
        _pageController.previousPage(
          duration: const Duration(milliseconds: 300),
          curve: Curves.easeInOut,
        );
      },
      child: const Text(
        'Voltar',
        style: TextStyle(color: Color(0xFF4A3F8F), fontWeight: FontWeight.w600),
      ),
    );
  }
}
