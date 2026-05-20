import { Timestamp } from 'firebase-admin/firestore';

export interface Video {
    titulo: string;
    url: string;
    thumbnail: string;
}

export interface Socio {
    nome: string;
    foto: string;
    participacao: number;
}

export interface Membro {
    nome: string;
    foto: string;
    cargo: string;
    area: string;
}

export interface Atualizacao {
    titulo: string;
    descricao: string;
    data: Timestamp;
}

export interface Startup {
    id?: string;
    nome: string;
    logo: string;
    descricao: string;
    estagio: 'Nova' | 'Em Operação' | 'Em Expansão';
    setor?: string;
    capitalAportado: number;
    totalTokens: number;
    precoToken?: number;
    precoTokenAtualCentavos?: number;
    variacaoPreco?: number;
    investido?: boolean;
    resumoExecutivo: string;
    socios: Socio[];
    conselho: Membro[];
    mentores: Membro[];
    videos: Video[];
    atualizacoes: Atualizacao[];
    createdAt: Timestamp;
}
