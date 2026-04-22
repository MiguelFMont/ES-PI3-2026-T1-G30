/*
significado do arquivo:

importa a wallet (repositório)
recebe o uid do usuário
valida se o uid foi informado 
chama o repo para buscar os dados 
retorna uma mensagem e a lista de operações 

verifica se o usuário tem wallet cadastrada
se tem, retorna os dados (wallet, tokense e operações)
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
    if (!historico || historico.lenght === 0){
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
    const { wallet, tokens, operacoes } = dados;

    // calcula valor total atual de todos os tokens
    // .reduce percorre o array e soma os valores 
    const valorTotalCarteira = tokens.reduce(
        (soma: number, token: any) => soma + (token.quantidade * token.precoAtual),
        0);
    
    // calcula o total investido somando todas as compras de tokens
    // filtra as operações do tipo 'compra' 
    const totalInvestido = operacoes 
        .filter((op: any) => op.tipo == 'compra') 
        .reduce(
            (soma: number, op: any) => soma + (op.quantidade * op.preco),
            0
        );
        
    // calcula o lucro 
    const lucro = valorTotalCarteira - totalInvestido;

    // calcula o retorno em porcentagem 
    // se não houver investimento retorna '0.00'
    const retorno = totalInvestido > 0 
        ? ((lucro / totalInvestido) * 100).toFixed(2) // limita duas casas decimais 
        : '0.00';

    // monta os pontos do gráfico a partir das operações 
    // cada ponto tem data e valor 
    const pontosGrafico = operacoes.map((op: any) => ({
        data: op.data, // eixo x 
        valor: op.quantidade * op.preco, // eixo y
    }));

    // retorna todos os dados calculados 
    return {
        message: 'Dados do dashboard retornados com sucesso',
        dashboard: {
            saldoDisponivel: wallet?.saldo ?? 0, // se a wallet existir: pega o saldo, se não retorna 0
            valorTotalCarteira,
            totalInvestido,
            retorno: `${retorno}%`,
            pontosGrafico,
        },
    };
}