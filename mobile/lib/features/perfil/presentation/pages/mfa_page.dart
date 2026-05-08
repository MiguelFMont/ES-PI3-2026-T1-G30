// lib/features/perfil/presentation/pages/mfa_page.dart
// Autor: Miguel Fernandes Monteiro

import 'package:flutter/material.dart';
import '../../../../core/theme/app_colors.dart';
import '../../data/repositories/perfil_repository.dart';
import '../../domain/perfil_models.dart';
import '../../../../shared/widgets/index.dart';

class MfaPage extends StatefulWidget {
  const MfaPage({super.key});

  @override
  State<MfaPage> createState() => _MfaPageState();
}

class _MfaPageState extends State<MfaPage> {
  final _repo = PerfilRepository();
  late Future<PerfilModel> _perfilFuture;

  // Estado local para controle
  bool _inicializado = false;
  late bool _mfaAppAtivo;

  static const double _sobreposicaoCard = 120.0;

  @override
  void initState() {
    super.initState();
    _perfilFuture = _repo.buscarPerfil();
  }

  int _calcularMetodosAtivos() {
    int contagem = 1; // E-mail é sempre 1 (verificado no cadastro)
    if (_mfaAppAtivo) contagem++;
    return contagem;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.secondary,
      extendBodyBehindAppBar: true,
      body: FutureBuilder<PerfilModel>(
        future: _perfilFuture,
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator(color: AppColors.primary));
          }
          if (snapshot.hasError) {
            return TelaErro(
              mensagem: snapshot.error.toString(),
              onTentarNovamente: () => setState(() => _perfilFuture = _repo.buscarPerfil()),
            );
          }

          final data = snapshot.data!;

          // Carrega o estado do banco apenas na primeira renderização
          if (!_inicializado) {
            _mfaAppAtivo = data.mfaAtivo; // Representa o App Autenticador
            _inicializado = true;
          }

          final metodosAtivos = _calcularMetodosAtivos();

          return LayoutBuilder(
            builder: (context, constraints) {
              return SingleChildScrollView(
                child: Wrap(
                  direction: Axis.vertical,
                  spacing: -_sobreposicaoCard,
                  children: [
                    SizedBox(
                      width: constraints.maxWidth,
                      child: const AppGradientHeader(titulo: ''),
                    ),
                    SizedBox(
                      width: constraints.maxWidth,
                      child: Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 16),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const Padding(
                              padding: EdgeInsets.only(bottom: 12),
                              child: Text(
                                'Autenticação de Múltiplos Fatores (MFA)',
                                style: TextStyle(
                                  color: Colors.white,
                                  fontWeight: FontWeight.w800,
                                  fontSize: 20,
                                ),
                              ),
                            ),
                            _cardStatusProtecao(metodosAtivos),
                            const SizedBox(height: 24),
                            _cardInformativo(),
                            const SizedBox(height: 32),
                            const RotuloSecao('MÉTODOS DE VERIFICAÇÃO'),
                            const SizedBox(height: 12),
                            
                            // APP AUTENTICADOR (Editável)
                            _itemMetodo(
                              icon: Icons.smartphone_rounded,
                              titulo: 'App Autenticador',
                              descricao: 'Google Authenticator, Authy, 1Password. Gera códigos de 6 dígitos a cada 30s, mesmo offline. Mais seguro.',
                              valor: _mfaAppAtivo,
                              onChanged: (v) => setState(() => _mfaAppAtivo = v),
                            ),
                            
                            const SizedBox(height: 12), 
                            
                            // EMAIL (Fixo/Não editável)
                            _itemMetodo(
                              icon: Icons.email_outlined,
                              titulo: 'Email',
                              descricao: 'Código enviado por email. Envia para ${data.email}.',
                              valor: true, // Sempre true
                              onChanged: null, // Passar null desabilita o Switch visualmente
                            ),
                            
                            const SizedBox(height: 40),
                          ],
                        ),
                      ),
                    ),
                  ],
                ),
              );
            },
          );
        },
      ),
    );
  }

  Widget _cardStatusProtecao(int metodosAtivos) {
    final isProtegida = metodosAtivos >= 2;

    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: AppColors.card,
        borderRadius: BorderRadius.circular(24),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 10,
            offset: const Offset(0, 4),
          )
        ],
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: (isProtegida ? Colors.green : Colors.orange).withOpacity(0.1),
              shape: BoxShape.circle,
            ),
            child: Icon(
              Icons.shield_outlined, 
              color: isProtegida ? Colors.green : Colors.orange, 
              size: 32,
            ),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'MFA Configurado',
                  style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: AppColors.foreground),
                ),
                Text(
                  '$metodosAtivos método(s) de verificação ativo(s)',
                  style: const TextStyle(color: AppColors.mutedForeground, fontSize: 14),
                ),
                if (isProtegida) ...[
                  const SizedBox(height: 8),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                    decoration: BoxDecoration(
                      color: Colors.green.withOpacity(0.1),
                      borderRadius: BorderRadius.circular(20),
                      border: Border.all(color: Colors.green.withOpacity(0.3)),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: const [
                        Icon(Icons.check, color: Colors.green, size: 14),
                        SizedBox(width: 4),
                        Text('Conta Protegida', style: TextStyle(color: Colors.green, fontSize: 12, fontWeight: FontWeight.w600)),
                      ],
                    ),
                  )
                ]
              ],
            ),
          )
        ],
      ),
    );
  }

  Widget _cardInformativo() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.card.withOpacity(0.5),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.muted.withOpacity(0.2)),
      ),
      child: const Text(
        'A autenticação de múltiplos fatores (MFA) adiciona uma camada extra de segurança à sua conta MesclaInvest. Recomendamos manter o App Autenticador ativo.',
        style: TextStyle(color: AppColors.mutedForeground, fontSize: 14, height: 1.5),
      ),
    );
  }

  Widget _itemMetodo({
    required IconData icon,
    required String titulo,
    String? tag,
    required String descricao,
    required bool valor,
    required ValueChanged<bool>? onChanged,
  }) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        // Mantém o fundo verde claro se ativado
        color: valor ? Colors.green.withOpacity(0.08) : Colors.transparent,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: valor ? Colors.green.withOpacity(0.3) : Colors.transparent,
          width: 1,
        ),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
              // O fundo acompanha o ícone: verdinho se ativo, magenta se inativo
              color: valor ? Colors.green.withOpacity(0.1) : AppColors.primary.withOpacity(0.05), 
              borderRadius: BorderRadius.circular(12),
            ),
            // Alteração principal: Verde quando ativado, magenta quando desativado
            child: Icon(
              icon, 
              color: valor ? Colors.green : AppColors.primary.withOpacity(0.7), 
              size: 24,
            ), 
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Text(titulo, style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: AppColors.foreground)),
                    if (tag != null) ...[
                      const SizedBox(width: 8),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                        decoration: BoxDecoration(color: Colors.blue.withOpacity(0.1), borderRadius: BorderRadius.circular(4)),
                        child: Text(tag, style: const TextStyle(color: Colors.blue, fontSize: 10, fontWeight: FontWeight.bold)),
                      ),
                    ],
                  ],
                ),
                const SizedBox(height: 4),
                Text(descricao, style: const TextStyle(color: AppColors.foreground, fontSize: 13, height: 1.4)),
              ],
            ),
          ),
          Switch(
            value: valor,
            onChanged: onChanged, 
            // Controla a cor da bolinha (thumb) em todos os estados
            thumbColor: WidgetStateProperty.resolveWith<Color>((Set<WidgetState> states) {
              if (states.contains(WidgetState.disabled)) {
                return AppColors.foreground; // Cor quando desativado (Email com onChanged nulo)
              }
              if (states.contains(WidgetState.selected)) {
                return AppColors.foreground; // Cor quando ativado
              }
              return Colors.white; // Cor padrão da bolinha inativa, ajuste se necessário
            }),
            // Controla a cor do fundo (track) em todos os estados
            trackColor: WidgetStateProperty.resolveWith<Color>((Set<WidgetState> states) {
              if (states.contains(WidgetState.disabled)) {
                return AppColors.foreground.withOpacity(0.3); // Fundo quando desativado
              }
              if (states.contains(WidgetState.selected)) {
                return AppColors.foreground.withOpacity(0.5); // Fundo quando ativado
              }
              return Colors.grey.withOpacity(0.3); // Fundo inativo padrão
            }),
            // Remove o contorno cinza que o Material 3 adiciona em switches inativos/desativados (opcional)
            trackOutlineColor: WidgetStateProperty.all(Colors.transparent),
          ),
        ],
      ),
    );
  }
}