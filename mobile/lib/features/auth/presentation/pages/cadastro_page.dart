// Autor: Miguel Fernandes Monteiro
// RA: 25014808

import 'package:flutter/material.dart';
import '../../data/repositories/auth_repository.dart';
import '../../../../shared/widgets/campo_texto.dart';

class CadastroPage extends StatefulWidget {
  const CadastroPage({super.key});

  @override
  State<CadastroPage> createState() => _CadastroPageState();
}

class _CadastroPageState extends State<CadastroPage> {
  // Controladores — capturam o texto digitado em cada campo
  final _nomeController = TextEditingController();
  final _emailController = TextEditingController();
  final _cpfController = TextEditingController();
  final _telefoneController = TextEditingController();
  final _senhaController = TextEditingController();

  final _repository = AuthRepository();

  // Controla o estado de carregamento (Future pendente)
  bool _isLoading = false;

  Future<void> _cadastrar() async {
    setState(() => _isLoading = true);

    try {
      await _repository.cadastro(
        _nomeController.text,
        _emailController.text,
        _cpfController.text,
        _telefoneController.text,
        _senhaController.text,
      );

      // Verifica se o widget ainda está na tela antes de usar context
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
    //O mounted é uma propriedade do StatefulWidget que retorna true se o widget ainda está ativo na tela.
    //Se o usuário saiu da tela enquanto a requisição estava rodando,
    //o mounted será false e o código para antes de usar o context
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Cadastro')),
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            CampoTexto(controller: _nomeController, label: 'Nome Completo'),
            SizedBox(height: 16),
            CampoTexto(
              controller: _emailController,
              label: 'E-mail',
              keyboardType: TextInputType.emailAddress,
            ),
            SizedBox(height: 16),
            CampoTexto(
              controller: _cpfController,
              label: 'CPF',
              keyboardType: TextInputType.number,
            ),
            SizedBox(height: 16),
            CampoTexto(
              controller: _telefoneController,
              label: 'Telefone',
              keyboardType: TextInputType.phone,
            ),
            SizedBox(height: 16),
            CampoTexto(
              controller: _senhaController,
              label: 'Senha',
              obscureText: true,
            ),
            SizedBox(height: 32),
            // Mostra spinner enquanto aguarda a API (Future pendente)
            _isLoading
                ? const CircularProgressIndicator()
                : ElevatedButton(
                    onPressed: _cadastrar,
                    child: const Text('Cadastrar'),
                  ),
          ],
        ),
      ),
    );
  }
}
