import 'package:flutter/material.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:mesclainvest/app/app.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();

  try {
    // O app depende do .env logo no bootstrap. Se essa carga falhar no Web,
    // a inicialização inteira morre antes do runApp e o Chrome fica em branco.
    await dotenv.load(fileName: '.env');

    // O projeto atual usa a API/backend para o fluxo principal e não possui
    // a configuração Web do Firebase versionada. Por isso, evitamos iniciar
    // o Firebase aqui no bootstrap até existir um firebase_options.dart real.
    runApp(const MesclaInvestApp());
  } catch (error, stackTrace) {
    // Reporta o erro para o pipeline padrão do Flutter e renderiza uma tela
    // explícita de falha em vez de deixar o navegador em branco.
    FlutterError.reportError(
      FlutterErrorDetails(
        exception: error,
        stack: stackTrace,
        library: 'app bootstrap',
      ),
    );
    runApp(_BootstrapErrorApp(message: error.toString()));
  }
}

class _BootstrapErrorApp extends StatelessWidget {
  const _BootstrapErrorApp({required this.message});

  final String message;

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      home: Scaffold(
        backgroundColor: const Color(0xFFF7F7F7),
        body: Center(
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 480),
            child: Padding(
              padding: const EdgeInsets.all(24),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Tela de fallback para expor o motivo do bootstrap ter falhado
                  // quando o app nem chegou a montar a primeira rota.
                  const Text(
                    'Falha ao iniciar o app',
                    style: TextStyle(fontSize: 24, fontWeight: FontWeight.w700),
                  ),
                  const SizedBox(height: 12),
                  const Text(
                    'Verifique o arquivo .env e a configuracao inicial do projeto.',
                  ),
                  const SizedBox(height: 16),
                  SelectableText(
                    message,
                    style: const TextStyle(color: Colors.redAccent),
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
