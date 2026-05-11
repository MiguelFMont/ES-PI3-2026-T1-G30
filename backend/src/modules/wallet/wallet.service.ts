/*
Autora: Maria Júlia Lazarini Oleto
RA: 25006031
significado do arquivo:

importa a wallet (repositório)
recebe o uid do usuário
valida se o uid foi informado 
chama o repo para buscar os dados 
retorna uma mensagem e a lista de operações 

verifica se o usuário tem wallet cadastrada
se tem, retorna os dados (wallet, holdings e transações)
tranforma esses dados em variáveis 
faz os calculos de: valor total da carteira, total investido, lucro, retorno
faz os pontos do gráfico com data e valor 
retorna os dados pro dashboard 
*/

import { WalletRepo } from "./wallet.repo";

const walletRepo = new WalletRepo();

// retorna o histórico de operações do usuário
export async function getHistoricoOperacoesService(uid: string) {
    // valida se o uid foi informado 
    if (!uid) {
        throw new Error ('UID do usuário é obrigatório');
    }

    // busca o histórico no repositório e guarda na const 
    const historico = await walletRepo.getHistoricoOperacoes(uid);

    // valida se encontrou as operações 
    if (!historico || historico.length === 0){
        return {
            message: 'Nenhuma operação encontrada',
            operacoes: [],
        };
    }

    // retorna o histórico de operações
    return {
        message: 'Histórico retornado com sucesso',
        operacoes: historico,
    };
}

// retorna os dados agregados da wallet para o dashboard 
export async function getDadosDashboardService(uid: string) {
    // valida se o uid foi informado 
    if (!uid){
        throw new Error('UID do usuário é obrigatório');
    }

    // busca os dados no repo
    // retorna a coleção de dados 
    const dados = await walletRepo.getDadosDashboard(uid);

    // valida se encontrou a wallet
    if(!dados) {
        throw new Error('Wallet não encontrada');
    }

    // torna a coleção de objetos recebida em tres variáveis separadas 
    const { wallet, holdings, transacoes } = dados;

    // converte o saldo de centavos para reais 
    const saldoDisponivel = (wallet?.saldoCentavos ?? 0) / 100;

    // calcula valor total atual de todos os holdings 
    // .reduce percorre o array e soma os valores 
    const valorTotalCarteira = holdings.reduce(
        (soma: number, holding: any) => soma + (holding.quantidade * holding.precoMedioCentavos) / 100,
        0);
    
    // calcula o total investido somando todas as compras de tokens (holdings)
    // filtra as transações do tipo 'DIRECT_BUY' ou 'MARKET_BUY' e soma os valores
    const totalInvestido = transacoes 
        .filter((tx: any) => tx.tipo === 'DIRECT_BUY' || tx.tipo === 'MARKET_BUY') 
        .reduce(
            (soma: number, tx: any) => soma + (tx.valorTotalCentavos / 100),
            0
        );
        
    // calcula o lucro 
    const lucro = valorTotalCarteira - totalInvestido;

    // calcula o retorno em porcentagem 
    // se não houver investimento retorna '0.00'
    const retorno = totalInvestido > 0 
        ? ((lucro / totalInvestido) * 100).toFixed(2) // limita duas casas decimais 
        : '0.00';

    // monta os pontos do gráfico a partir das transações 
    // cada ponto tem data e valor 
    const pontosGrafico = transacoes.map((tx: any) => ({
        data: tx.createdAt, // eixo x 
        valor: tx.valorTotalCentavos / 100, // eixo y
    }));

    // retorna todos os dados calculados 
    return {
        message: 'Dados do dashboard retornados com sucesso',
        dashboard: {
            saldoDisponivel,
            valorTotalCarteira,
            totalInvestido,
            lucro,
            retorno: `${retorno}%`,
            pontosGrafico,
        },
    };
}