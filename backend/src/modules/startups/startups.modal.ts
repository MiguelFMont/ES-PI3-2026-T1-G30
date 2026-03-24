import { Timestamp } from 'firebase-admin/firestore';

export interface Video {
    title: string;
    url: string;
    thumbnail: string;
}

export interface Socio {
    name: string;
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
    estagio: 'Nova' | 'Em Operacao' | 'Em Expansao';
    capitalAportado: number;
    resumoExecutivo: string;
    socios: Socio[];
    conselho: Membro[];
    mentores: Membro[];
    videos: Video[];
    atualizacoes: Atualizacao[];
    createdAt: Timestamp;
}
