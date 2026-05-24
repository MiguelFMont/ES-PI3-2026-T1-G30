import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:mesclainvest/core/theme/app_colors.dart';
import 'package:mesclainvest/features/perfil/data/repositories/perfil_repository.dart';
import 'package:mesclainvest/features/perfil/domain/perfil_models.dart';
import 'package:mesclainvest/shared/widgets/index.dart';

class WalletBalanceUpdate {
  const WalletBalanceUpdate({required this.wallet, required this.message});

  final WalletBalanceModel wallet;
  final String message;
}

class PaymentMethodsSheet extends StatelessWidget {
  const PaymentMethodsSheet({super.key});

  @override
  Widget build(BuildContext context) {
    return _SheetScaffold(
      title: 'Métodos de Pagamento',
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Funcionalidade visual para simulação acadêmica. Nenhum método real de pagamento será processado.',
            style: TextStyle(
              fontSize: 14,
              height: 1.5,
              color: AppColors.mutedForeground,
            ),
          ),
          const SizedBox(height: 20),
          const _SimulatedMethodCard(
            icon: Icons.credit_card_rounded,
            title: 'Cartão virtual simulado',
            subtitle: 'Interface visual para futura evolução acadêmica.',
            status: 'Simulado',
          ),
          const SizedBox(height: 12),
          const _SimulatedMethodCard(
            icon: Icons.account_balance_rounded,
            title: 'Conta bancária simulada',
            subtitle: 'Exibição conceitual sem vínculo com instituições reais.',
            status: 'Simulado',
          ),
          const SizedBox(height: 12),
          const _SimulatedMethodCard(
            icon: Icons.qr_code_2_rounded,
            title: 'Pix simulado',
            subtitle:
                'Atalho visual para um fluxo que ainda não processa dados reais.',
            status: 'Em breve',
          ),
          const SizedBox(height: 20),
          const Text(
            'Nenhum número de cartão, CPF, chave Pix ou dado bancário é solicitado nesta etapa.',
            style: TextStyle(
              fontSize: 13,
              height: 1.5,
              color: AppColors.mutedForeground,
            ),
          ),
          const SizedBox(height: 20),
          MesclaButton(
            label: 'Fechar',
            width: double.infinity,
            onPressed: () => Navigator.of(context).pop(),
          ),
        ],
      ),
    );
  }
}

class WalletBalanceSheet extends StatefulWidget {
  const WalletBalanceSheet({
    super.key,
    required this.repository,
    required this.onWalletUpdated,
    this.initialWallet,
  });

  final PerfilRepository repository;
  final WalletBalanceModel? initialWallet;
  final ValueChanged<WalletBalanceUpdate> onWalletUpdated;

  @override
  State<WalletBalanceSheet> createState() => _WalletBalanceSheetState();
}

class _WalletBalanceSheetState extends State<WalletBalanceSheet> {
  final NumberFormat _currencyFormat = NumberFormat.currency(
    locale: 'pt_BR',
    symbol: 'R\$',
  );

  WalletBalanceModel? _wallet;
  bool _isLoading = true;
  String? _errorMessage;

  @override
  void initState() {
    super.initState();
    _wallet = widget.initialWallet;
    if (_wallet != null) {
      _isLoading = false;
    } else {
      _loadWallet();
    }
  }

  Future<void> _loadWallet() async {
    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    try {
      final wallet = await widget.repository.buscarCarteira();
      if (!mounted) return;
      setState(() {
        _wallet = wallet;
        _isLoading = false;
        _errorMessage = null;
      });
    } catch (error) {
      if (!mounted) return;
      setState(() {
        _isLoading = false;
        _errorMessage = _errorText(error);
      });
    }
  }

  Future<void> _openAmountSheet(_WalletSheetAction action) async {
    final wallet = _wallet;
    if (wallet == null) return;

    final result = await showModalBottomSheet<_WalletActionResult>(
      context: context,
      isScrollControlled: true,
      useSafeArea: true,
      backgroundColor: Colors.transparent,
      builder: (_) => _WalletAmountSheet(
        repository: widget.repository,
        wallet: wallet,
        action: action,
      ),
    );

    if (!mounted || result == null) return;

    setState(() {
      _wallet = result.wallet;
      _errorMessage = null;
    });
    widget.onWalletUpdated(
      WalletBalanceUpdate(wallet: result.wallet, message: result.message),
    );
  }

  String _errorText(Object error) {
    return error.toString().replaceFirst('Exception: ', '').trim();
  }

  @override
  Widget build(BuildContext context) {
    return _SheetScaffold(
      title: 'Saldo e Depósitos',
      trailing: IconButton(
        onPressed: _isLoading
            ? null
            : () {
                _loadWallet();
              },
        icon: const Icon(Icons.refresh_rounded, color: AppColors.primary),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          if (_isLoading && _wallet == null)
            const Padding(
              padding: EdgeInsets.symmetric(vertical: 36),
              child: Center(
                child: CircularProgressIndicator(color: AppColors.primary),
              ),
            )
          else if (_wallet == null)
            _WalletInlineError(
              message:
                  _errorMessage ??
                  'Não foi possível carregar a carteira agora.',
              onRetry: _loadWallet,
            )
          else ...[
            _WalletBalanceCard(
              balanceLabel: _currencyFormat.format(_wallet!.saldoReais),
            ),
            const SizedBox(height: 20),
            _WalletActionCard(
              icon: Icons.add_card_rounded,
              title: 'Adicionar saldo na carteira',
              subtitle:
                  'Faça uma recarga simulada da carteira para investir nas startups.',
              onTap: () {
                _openAmountSheet(_WalletSheetAction.deposit);
              },
            ),
            const SizedBox(height: 12),
            _WalletActionCard(
              icon: Icons.account_balance_wallet_outlined,
              title: 'Sacar',
              subtitle:
                  'Solicite a retirada do saldo disponível da sua carteira digital.',
              onTap: () {
                _openAmountSheet(_WalletSheetAction.withdraw);
              },
            ),
            if (_errorMessage != null) ...[
              const SizedBox(height: 12),
              Text(
                _errorMessage!,
                style: const TextStyle(
                  fontSize: 13,
                  fontWeight: FontWeight.w600,
                  color: AppColors.destructive,
                ),
              ),
            ],
            const SizedBox(height: 20),
            OutlinedButton(
              onPressed: () => Navigator.of(context).pop(),
              style: OutlinedButton.styleFrom(
                foregroundColor: AppColors.mutedForeground,
                side: const BorderSide(color: AppColors.muted),
                minimumSize: const Size.fromHeight(52),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(14),
                ),
              ),
              child: const Text(
                'Fechar',
                style: TextStyle(fontWeight: FontWeight.w700),
              ),
            ),
          ],
        ],
      ),
    );
  }
}

enum _WalletSheetAction { deposit, withdraw }

class _WalletAmountSheet extends StatefulWidget {
  const _WalletAmountSheet({
    required this.repository,
    required this.wallet,
    required this.action,
  });

  final PerfilRepository repository;
  final WalletBalanceModel wallet;
  final _WalletSheetAction action;

  @override
  State<_WalletAmountSheet> createState() => _WalletAmountSheetState();
}

class _WalletAmountSheetState extends State<_WalletAmountSheet> {
  final GlobalKey<FormState> _formKey = GlobalKey<FormState>();
  final TextEditingController _valueController = TextEditingController();
  final NumberFormat _currencyFormat = NumberFormat.currency(
    locale: 'pt_BR',
    symbol: 'R\$',
  );

  bool _isSubmitting = false;
  String? _backendError;

  bool get _isDeposit => widget.action == _WalletSheetAction.deposit;
  String get _title =>
      _isDeposit ? 'Adicionar saldo na carteira' : 'Sacar da carteira';
  String get _submitLabel =>
      _isDeposit ? 'Confirmar depósito' : 'Confirmar saque';
  String get _successMessage => _isDeposit
      ? 'Saldo adicionado com sucesso.'
      : 'Saque realizado com sucesso.';

  @override
  void dispose() {
    _valueController.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    final form = _formKey.currentState;
    if (form == null || !form.validate()) {
      return;
    }

    final valorCentavos = _parseCurrencyToCents(_valueController.text);
    if (valorCentavos == null) {
      return;
    }

    setState(() {
      _isSubmitting = true;
      _backendError = null;
    });

    try {
      final wallet = _isDeposit
          ? await widget.repository.adicionarSaldo(valorCentavos)
          : await widget.repository.sacar(valorCentavos);

      if (!mounted) return;
      Navigator.of(
        context,
      ).pop(_WalletActionResult(wallet: wallet, message: _successMessage));
    } catch (error) {
      if (!mounted) return;
      setState(() {
        _backendError = error.toString().replaceFirst('Exception: ', '').trim();
        _isSubmitting = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final saldoAtual = _currencyFormat.format(widget.wallet.saldoReais);

    return _SheetScaffold(
      title: _title,
      child: Form(
        key: _formKey,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Saldo atual: $saldoAtual',
              style: const TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.w700,
                color: AppColors.foreground,
              ),
            ),
            const SizedBox(height: 16),
            TextFormField(
              controller: _valueController,
              enabled: !_isSubmitting,
              keyboardType: const TextInputType.numberWithOptions(
                decimal: true,
              ),
              decoration: _inputDecoration(
                label: 'Valor em reais',
                hint: 'Ex.: 150,00',
              ),
              validator: (value) {
                final valorCentavos = _parseCurrencyToCents(value ?? '');
                if (valorCentavos == null || valorCentavos <= 0) {
                  return 'Informe um valor válido.';
                }

                if (!_isDeposit &&
                    valorCentavos > widget.wallet.saldoCentavos) {
                  return 'O valor não pode exceder o saldo disponível.';
                }

                return null;
              },
            ),
            const SizedBox(height: 14),
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(14),
              decoration: BoxDecoration(
                color: const Color(0xFFF8FAFC),
                borderRadius: BorderRadius.circular(16),
              ),
              child: Text(
                _isDeposit
                    ? 'O valor será convertido em centavos e enviado para a carteira autenticada.'
                    : 'O backend valida saldo suficiente e impede que a carteira fique negativa.',
                style: const TextStyle(
                  fontSize: 13,
                  height: 1.5,
                  color: AppColors.mutedForeground,
                ),
              ),
            ),
            if (_backendError != null) ...[
              const SizedBox(height: 12),
              Text(
                _backendError!,
                style: const TextStyle(
                  fontSize: 13,
                  fontWeight: FontWeight.w600,
                  color: AppColors.destructive,
                ),
              ),
            ],
            const SizedBox(height: 20),
            MesclaButton(
              label: _isSubmitting ? 'Processando...' : _submitLabel,
              width: double.infinity,
              onPressed: _isSubmitting
                  ? null
                  : () {
                      _submit();
                    },
            ),
            const SizedBox(height: 12),
            OutlinedButton(
              onPressed: _isSubmitting
                  ? null
                  : () => Navigator.of(context).pop(),
              style: OutlinedButton.styleFrom(
                foregroundColor: AppColors.mutedForeground,
                side: const BorderSide(color: AppColors.muted),
                minimumSize: const Size.fromHeight(52),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(14),
                ),
              ),
              child: const Text(
                'Cancelar',
                style: TextStyle(fontWeight: FontWeight.w700),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _WalletActionResult {
  const _WalletActionResult({required this.wallet, required this.message});

  final WalletBalanceModel wallet;
  final String message;
}

class _SheetScaffold extends StatelessWidget {
  const _SheetScaffold({
    required this.title,
    required this.child,
    this.trailing,
  });

  final String title;
  final Widget child;
  final Widget? trailing;

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      top: false,
      child: Container(
        decoration: const BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
        ),
        child: Padding(
          padding: EdgeInsets.only(
            left: 20,
            right: 20,
            top: 18,
            bottom: MediaQuery.of(context).viewInsets.bottom + 20,
          ),
          child: SingleChildScrollView(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Center(
                  child: Container(
                    width: 40,
                    height: 4,
                    decoration: BoxDecoration(
                      color: AppColors.muted,
                      borderRadius: BorderRadius.circular(999),
                    ),
                  ),
                ),
                const SizedBox(height: 18),
                Row(
                  children: [
                    Expanded(
                      child: Text(
                        title,
                        style: const TextStyle(
                          fontSize: 22,
                          fontWeight: FontWeight.w800,
                          color: AppColors.foreground,
                        ),
                      ),
                    ),
                    ...[trailing].whereType<Widget>(),
                  ],
                ),
                const SizedBox(height: 20),
                child,
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _SimulatedMethodCard extends StatelessWidget {
  const _SimulatedMethodCard({
    required this.icon,
    required this.title,
    required this.subtitle,
    required this.status,
  });

  final IconData icon;
  final String title;
  final String subtitle;
  final String status;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: const Color(0xFFF8FAFC),
        borderRadius: BorderRadius.circular(18),
      ),
      child: Row(
        children: [
          Container(
            width: 44,
            height: 44,
            decoration: BoxDecoration(
              color: AppColors.primary.withValues(alpha: 0.10),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Icon(icon, color: AppColors.primary),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: const TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w700,
                    color: AppColors.foreground,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  subtitle,
                  style: const TextStyle(
                    fontSize: 12,
                    height: 1.4,
                    color: AppColors.mutedForeground,
                  ),
                ),
              ],
            ),
          ),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
            decoration: BoxDecoration(
              color: AppColors.primary.withValues(alpha: 0.10),
              borderRadius: BorderRadius.circular(999),
            ),
            child: Text(
              status,
              style: const TextStyle(
                fontSize: 11,
                fontWeight: FontWeight.w700,
                color: AppColors.primary,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _WalletBalanceCard extends StatelessWidget {
  const _WalletBalanceCard({required this.balanceLabel});

  final String balanceLabel;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [Color(0xFFFFF5F8), Color(0xFFFFFFFF)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(22),
        border: Border.all(color: AppColors.primary.withValues(alpha: 0.12)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Saldo atual da carteira',
            style: TextStyle(
              fontSize: 13,
              fontWeight: FontWeight.w700,
              color: AppColors.mutedForeground,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            balanceLabel,
            style: const TextStyle(
              fontSize: 28,
              fontWeight: FontWeight.w800,
              color: AppColors.foreground,
            ),
          ),
        ],
      ),
    );
  }
}

class _WalletActionCard extends StatelessWidget {
  const _WalletActionCard({
    required this.icon,
    required this.title,
    required this.subtitle,
    required this.onTap,
  });

  final IconData icon;
  final String title;
  final String subtitle;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(18),
        child: Ink(
          width: double.infinity,
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: AppColors.card,
            borderRadius: BorderRadius.circular(18),
            boxShadow: [
              BoxShadow(
                color: AppColors.accent.withValues(alpha: 0.05),
                blurRadius: 12,
                offset: const Offset(0, 4),
              ),
            ],
          ),
          child: Row(
            children: [
              Container(
                width: 46,
                height: 46,
                decoration: BoxDecoration(
                  color: AppColors.primary.withValues(alpha: 0.10),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Icon(icon, color: AppColors.primary),
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      title,
                      style: const TextStyle(
                        fontSize: 15,
                        fontWeight: FontWeight.w700,
                        color: AppColors.foreground,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      subtitle,
                      style: const TextStyle(
                        fontSize: 12,
                        height: 1.4,
                        color: AppColors.mutedForeground,
                      ),
                    ),
                  ],
                ),
              ),
              const Icon(
                Icons.chevron_right_rounded,
                color: AppColors.mutedForeground,
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _WalletInlineError extends StatelessWidget {
  const _WalletInlineError({required this.message, required this.onRetry});

  final String message;
  final Future<void> Function() onRetry;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(
          color: AppColors.destructive.withValues(alpha: 0.14),
        ),
      ),
      child: Column(
        children: [
          const Icon(
            Icons.cloud_off_rounded,
            color: AppColors.mutedForeground,
            size: 34,
          ),
          const SizedBox(height: 12),
          Text(
            message,
            textAlign: TextAlign.center,
            style: const TextStyle(
              fontSize: 13,
              height: 1.5,
              color: AppColors.mutedForeground,
            ),
          ),
          const SizedBox(height: 16),
          MesclaButton(
            label: 'Tentar novamente',
            width: double.infinity,
            onPressed: () {
              onRetry();
            },
          ),
        ],
      ),
    );
  }
}

InputDecoration _inputDecoration({
  required String label,
  required String hint,
}) {
  return InputDecoration(
    labelText: label,
    hintText: hint,
    filled: true,
    fillColor: const Color(0xFFF8FAFC),
    contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
    border: OutlineInputBorder(
      borderRadius: BorderRadius.circular(16),
      borderSide: BorderSide.none,
    ),
    enabledBorder: OutlineInputBorder(
      borderRadius: BorderRadius.circular(16),
      borderSide: const BorderSide(color: Color(0xFFE2E8F0)),
    ),
    focusedBorder: OutlineInputBorder(
      borderRadius: BorderRadius.circular(16),
      borderSide: const BorderSide(color: AppColors.primary, width: 1.3),
    ),
  );
}

int? _parseCurrencyToCents(String rawValue) {
  var normalized = rawValue.trim();
  if (normalized.isEmpty) return null;

  normalized = normalized.replaceAll('R\$', '').replaceAll(' ', '');
  if (normalized.contains(',') && normalized.contains('.')) {
    normalized = normalized.replaceAll('.', '').replaceAll(',', '.');
  } else {
    normalized = normalized.replaceAll(',', '.');
  }

  final value = double.tryParse(normalized);
  if (value == null || value <= 0) {
    return null;
  }

  return (value * 100).round();
}
