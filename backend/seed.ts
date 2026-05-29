import { getDb } from "./src/config/firebase";
import { Timestamp } from "firebase-admin/firestore";
import { resolveStartupTokenomicsTarget } from "./scripts/lib/startup-tokenomics-policy";

// initializeFirebase();

const db = getDb();
const DEFAULT_PRECO_TOKEN_CENTAVOS = 1000;
const DEFAULT_DESCONTO_VENDA_DIRETA_BPS = 1000;

function startupDocId(nome: string): string {
  return nome
    .normalize("NFD")
    .replace(/[\u0300-\u036f]/g, "")
    .toLowerCase()
    .replace(/[^a-z0-9]+/g, "-")
    .replace(/^-+|-+$/g, "");
}

// Aplica a politica central de tokenomia para manter capital e total de tokens
// consistentes entre a seed e os scripts de manutencao do Firestore.
function withStartupTokenomicsPolicy<T extends { nome: string; estagio: string }>(
  startup: T,
): T & StartupTokenomicsSeedFields {
  const target = resolveStartupTokenomicsTarget({
    nome: startup.nome,
    estagio: startup.estagio,
  });

  return {
    ...startup,
    capitalAportado: target.capitalAportado,
    totalTokens: target.totalTokens,
  };
}

type StartupTokenomicsSeedFields = {
  capitalAportado: number;
  totalTokens: number;
};

async function seed(): Promise<void> {
  console.log("Iniciando seed...");

  const startups = [
    withStartupTokenomicsPolicy({
      nome: "AgroIA",
      logo: "https://placehold.co/200x200?text=AgroIA",
      descricao:
        "Plataforma de inteligêcia artificial para monitoramento de lavoura via sátelite.",
      estagio: "Em Expansão",
      setor: "Agritech",
      resumoExecutivo:
        "A AgroIA moderniza o agronégocio brasileiro com tecnologia de ponta.",
      socios: [
        {
          nome: "Lucas Ferreira",
          foto: "https://placehold.co/100x100?text=LF",
          participacao: 50,
        },
        {
          nome: "Ana Souza",
          foto: "https://placehold.co/100x100?text=AS",
          participacao: 50,
        },
      ],
      conselho: [
        {
          nome: "Dr. Roberto Lima",
          foto: "https://placehold.co/100x100?text=RL",
          cargo: "Advisor",
          area: "Agronegócio",
        },
      ],
      mentores: [
        {
          nome: "Fernanda Dias",
          foto: "https://placehold.co/100x100?text=FD",
          cargo: "Mentor",
          area: "Tecnologia",
        },
      ],
      videos: [
        {
          titulo: "Pitch AgroIA",
          url: "#",
          thumbnail: "https://placehold.co/320x180?text=Pitch",
        },
      ],
      atualizacoes: [
        {
          titulo: "Captação concluída",
          descricao: "Rodada de investimento encerrada com sucesso.",
          data: Timestamp.fromDate(new Date("2025-06-01")),
        },
        {
          titulo: "Expansão para novo estado",
          descricao: "Operações iniciadas no Mato Grosso.",
          data: Timestamp.fromDate(new Date("2025-09-15")),
        },
      ],
      createdAt: Timestamp.fromDate(new Date()),
    }),
    withStartupTokenomicsPolicy({
      nome: "MedFácil",
      logo: "https://placehold.co/200x200?text=Medfacil",
      descricao:
        "Conecta pacientes a médicos para consultas online com prontuários digital integrado.",
      estagio: "Em Operação",
      setor: "Saúde",
      resumoExecutivo:
        "A MedFácil democratiza o acesso à saúde através de telemedicina acessível.",
      socios: [
        {
          nome: "Camila Ramos",
          foto: "https://placehold.co/100x100?text=CR",
          participacao: 60,
        },
        {
          nome: "Jorge Alemida",
          foto: "https://placehold.co/100x100?text=JA",
          participacao: 40,
        },
      ],
      conselho: [
        {
          nome: "Dra. Patrícia Nunes",
          foto: "https://placehold.co/100x100?text=PN",
          cargo: "Advisor",
          area: "Saúde",
        },
      ],
      mentores: [
        {
          nome: "Carlos Melo",
          foto: "https://placehold.co/100x100?text=CM",
          cargo: "Mentor",
          area: "Negócios",
        },
      ],
      videos: [
        {
          titulo: "Demo MedFácil",
          url: "#",
          thumbnail: "https://placehold.co/320x180?text=Demo",
        },
      ],
      atualizacoes: [
        {
          titulo: "Lançamento do app",
          descricao: "Versão 1.0 disponível na Play Store e App Store.",
          data: Timestamp.fromDate(new Date("2025-03-10")),
        },
      ],
      createdAt: Timestamp.fromDate(new Date()),
    }),
    withStartupTokenomicsPolicy({
      nome: "EduBlocks",
      logo: "https://placehold.co/200x200?text=EduBlocks",
      descricao:
        "Ensino de programação para crianças de 6 a 14 anos através de jogos e desafios.",
      estagio: "Nova",
      setor: "Educação",
      resumoExecutivo:
        "A EduBlocks acredita que toda criança pode aprender a programar de forma lúdica.",
      socios: [
        {
          nome: "Beatriz Costa",
          foto: "https://placehold.co/100x100?text=BC",
          participacao: 70,
        },
        {
          nome: "Rafael Pinto",
          foto: "https://placehold.co/100x100?text=RP",
          participacao: 30,
        },
      ],
      conselho: [],
      mentores: [
        {
          nome: "Prof. André Silva",
          foto: "https://placehold.co/100x100?text=AS",
          cargo: "Mentor",
          area: "Educação",
        },
      ],
      videos: [],
      atualizacoes: [],
      createdAt: Timestamp.fromDate(new Date()),
    }),
    withStartupTokenomicsPolicy({
      nome: "FinTrack",
      logo: "https://placehold.co/200x200?text=FinTrack",
      descricao:
        "Plataforma de gestão financeira pessoal com categorização automática de gastos por IA.",
      estagio: "Em Operação",
      setor: "Fintech",
      resumoExecutivo:
        "A FinTrack ajuda brasileiros a organizarem suas finanças com inteligência artificial acessível.",
      socios: [
        {
          nome: "Pedro Henrique",
          foto: "https://placehold.co/100x100?text=PH",
          participacao: 55,
        },
        {
          nome: "Larissa Matos",
          foto: "https://placehold.co/100x100?text=LM",
          participacao: 45,
        },
      ],
      conselho: [
        {
          nome: "Eduardo Fonseca",
          foto: "https://placehold.co/100x100?text=EF",
          cargo: "Advisor",
          area: "Finanças",
        },
      ],
      mentores: [
        {
          nome: "Renata Borges",
          foto: "https://placehold.co/100x100?text=RB",
          cargo: "Mentor",
          area: "Tecnologia",
        },
        {
          nome: "Thiago Martins",
          foto: "https://placehold.co/100x100?text=TM",
          cargo: "Mentor",
          area: "Negócios",
        },
      ],
      videos: [
        {
          titulo: "Pitch FinTrack",
          url: "#",
          thumbnail: "https://placehold.co/320x180?text=Pitch",
        },
        {
          titulo: "Demo do produto",
          url: "#",
          thumbnail: "https://placehold.co/320x180?text=Demo",
        },
      ],
      atualizacoes: [
        {
          titulo: "Primeiro milestone",
          descricao: "Atingimos 1.000 usuários ativos.",
          data: Timestamp.fromDate(new Date("2025-08-20")),
        },
      ],
      createdAt: Timestamp.fromDate(new Date()),
    }),
    withStartupTokenomicsPolicy({
      nome: "GreenRoute",
      logo: "https://placehold.co/200x200?text=GreenRoute",
      descricao:
        "App de mobilidade urbana sustentável que calcula rotas com menor emissão de carbono.",
      estagio: "Nova",
      setor: "Mobilidade",
      resumoExecutivo:
        "A GreenRoute quer transformar o jeito que as pessoas se locomovem nas cidades, priorizando o meio ambiente.",
      socios: [
        {
          nome: "Mariana Lopes",
          foto: "https://placehold.co/100x100?text=ML",
          participacao: 60,
        },
        {
          nome: "Felipe Castro",
          foto: "https://placehold.co/100x100?text=FC",
          participacao: 40,
        },
      ],
      conselho: [],
      mentores: [
        {
          nome: "Dra. Silvia Prado",
          foto: "https://placehold.co/100x100?text=SP",
          cargo: "Mentor",
          area: "Sustentabilidade",
        },
      ],
      videos: [],
      atualizacoes: [],
      createdAt: Timestamp.fromDate(new Date()),
    }),
  ];

  for (const startup of startups) {
    const existingSnapshot = await db
      .collection("startups")
      .where("nome", "==", startup.nome)
      .limit(1)
      .get();

    if (!existingSnapshot.empty) {
      console.log(`${startup.nome} já existe. Inserção ignorada.`);
      continue;
    }

    await db
      .collection("startups")
      .doc(startupDocId(startup.nome))
      .set({
        ...startup,
        tokensDisponiveis: startup.totalTokens,
        precoTokenInicialCentavos: DEFAULT_PRECO_TOKEN_CENTAVOS,
        precoTokenAtualCentavos: DEFAULT_PRECO_TOKEN_CENTAVOS,
        descontoVendaDiretaBps: DEFAULT_DESCONTO_VENDA_DIRETA_BPS,
        updatedAt: Timestamp.fromDate(new Date()),
      });
    console.log(`${startup.nome} inserida`);
  }
  console.log("\nSeed concluída verifique o FireBase console");
  process.exit(0);
}

seed().catch((err) => {
  console.error("Erro no seed:", err);
  process.exit(1);
});
