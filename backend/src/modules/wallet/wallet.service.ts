/*
significado do arquivo:

importa a wallet (repositório)
recebe o uid do usuário
valida se o uid foi informado 
chama o repo para buscar os dados 
retorna uma mensagem e a lista de operações 
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