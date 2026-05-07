import '../domain/startup_model.dart';

// usando apenas para teste, depois volta pra api real
const bool kUseMock = false;

final List<Startup> mockStartups = [
  Startup(
    id: 'mock-001',
    nome: 'VerdeTech',
    logo:
        'https://ui-avatars.com/api/?name=VT&size=128&background=22c55e&color=fff&bold=true',
    descricao:
        'Monitoramento de safras por IoT e IA para pequenos agricultores',
    estagio: 'Em Expansão',
    capitalAportado: 1200000,
    totalTokens: 50000,
    resumoExecutivo:
        'A VerdeTech desenvolve sensores IoT de baixo custo integrados a '
        'uma plataforma de IA que permite ao agricultor monitorar umidade do '
        'solo, temperatura e pragas em tempo real pelo celular. Já atende 340 '
        'propriedades no interior de SP e MG, com redução média de 22% no uso '
        'de defensivos agrícolas.',
    socios: [
      Socio(nome: 'Ana Lima', foto: '', participacao: 55),
      Socio(nome: 'Carlos Mota', foto: '', participacao: 45),
    ],
    conselho: [
      Membro(
        nome: 'Dr. Roberto Farias',
        foto: '',
        cargo: 'Conselheiro',
        area: 'Agronegócio',
      ),
    ],
    mentores: [
      Membro(
        nome: 'Patrícia Souza',
        foto: '',
        cargo: 'Mentora',
        area: 'Inovação & Go-to-Market',
      ),
    ],
    videos: [
      Video(
        titulo: 'VerdeTech no Agrishow 2024',
        url: 'https://www.youtube.com/watch?v=dQw4w9WgXcQ',
        thumbnail: '',
      ),
    ],
    atualizacoes: [
      Atualizacao(
        titulo: 'Expansão para o Mato Grosso',
        descricao:
            'Firmamos contrato com cooperativa de soja para pilotar '
            'em 80 propriedades a partir de julho.',
        data: '2025-04-10',
      ),
    ],
  ),
  Startup(
    id: 'mock-002',
    nome: 'MedConnect',
    logo:
        'https://ui-avatars.com/api/?name=MC&size=128&background=3b82f6&color=fff&bold=true',
    descricao: 'Telemedicina acessível para regiões com baixa cobertura médica',
    estagio: 'Em Operação',
    capitalAportado: 320000,
    totalTokens: 25000,
    resumoExecutivo:
        'A MedConnect conecta pacientes de municípios com menos de 50 mil '
        'habitantes a especialistas via videoconsulta assíncrona. A plataforma '
        'funciona offline-first e sincroniza prontuários quando há conexão. '
        'Em operação em 18 municípios do Nordeste com mais de 12 mil consultas '
        'realizadas.',
    socios: [
      Socio(nome: 'Fernanda Costa', foto: '', participacao: 50),
      Socio(nome: 'Rafael Nunes', foto: '', participacao: 30),
      Socio(nome: 'Mariana Eto', foto: '', participacao: 20),
    ],
    conselho: [],
    mentores: [
      Membro(
        nome: 'Dr. Augusto Pires',
        foto: '',
        cargo: 'Mentor',
        area: 'HealthTech & Regulatório',
      ),
    ],
    videos: [],
    atualizacoes: [
      Atualizacao(
        titulo: 'Certificação CFM aprovada',
        descricao:
            'Recebemos o aval do Conselho Federal de Medicina para '
            'expandir o modelo de consulta assíncrona.',
        data: '2025-03-02',
      ),
      Atualizacao(
        titulo: 'Parceria com Secretaria de Saúde do Ceará',
        descricao: 'Piloto com 5 UBSs começa em junho de 2025.',
        data: '2025-01-18',
      ),
    ],
  ),
  Startup(
    id: 'mock-003',
    nome: 'EduSpace',
    logo:
        'https://ui-avatars.com/api/?name=ES&size=128&background=a855f7&color=fff&bold=true',
    descricao: 'Plataforma adaptativa de ensino com IA para escolas públicas',
    estagio: 'Nova',
    capitalAportado: 80000,
    totalTokens: 10000,
    resumoExecutivo:
        'A EduSpace usa modelos de linguagem leves para personalizar exercícios '
        'de matemática e português conforme o ritmo de cada aluno do ensino '
        'fundamental. O sistema roda no próprio dispositivo, dispensando internet '
        'constante. MVP validado com 3 escolas municipais em Campinas, alcançando '
        '1.200 alunos.',
    socios: [
      Socio(nome: 'Lucas Oliveira', foto: '', participacao: 70),
      Socio(nome: 'Beatriz Han', foto: '', participacao: 30),
    ],
    conselho: [],
    mentores: [
      Membro(
        nome: 'Prof. Cláudia Rezende',
        foto: '',
        cargo: 'Mentora',
        area: 'EdTech & Pedagogia',
      ),
    ],
    videos: [],
    atualizacoes: [
      Atualizacao(
        titulo: 'MVP aprovado pela Secretaria de Educação',
        descricao:
            'Avaliação pedagógica concluída com nota máxima. '
            'Expansão para mais 10 escolas prevista para agosto.',
        data: '2025-04-28',
      ),
    ],
  ),
];
