# 📱 MesclaInvest

> Plataforma mobile simulada de negociação de tokens representativos de startups vinculadas ao ecossistema Mescla da PUC-Campinas.

---

## 📋 Descrição do Projeto

O **MesclaInvest** é um aplicativo móvel desenvolvido como projeto acadêmico na disciplina **Projeto Integrador 3** do curso de Engenharia de Software da PUC-Campinas (2026).

A proposta simula um ambiente digital de investimentos baseado na negociação de tokens representativos de startups vinculadas ao **Mescla** — o ecossistema de inovação e empreendedorismo universitário da PUC-Campinas.

### Funcionalidades principais

- **Autenticação** — Cadastro e login com e-mail, CPF, telefone e senha. Recuperação de senha via e-mail e suporte a autenticação multifator (MFA/2FA).
- **Catálogo de Startups** — Navegação, filtros por estágio (Nova / Em operação / Em expansão), visualização de sumário executivo, estrutura societária, vídeos, Q&A e documentos públicos.
- **Balcão de Tokens** — Simulação de compra e venda de tokens entre usuários cadastrados, com carteira digital de saldo fictício em reais.
- **Dashboard de Valorização** — Acompanhamento gráfico da variação de valor dos tokens nos períodos: diário, semanal, mensal, últimos 6 meses e YTD.

> ⚠️ Todas as operações são **exclusivamente simuladas**. O sistema não realiza captação real de investimentos nem integração com sistemas financeiros externos.

---

## 👥 Integrantes

| Nome Completo | RA |
|---|---|
| Caio Ávila Marchi | 25008101 |
| Gabriel Martins de Almeida | 25006162 |
| Maria Júlia Lazarini Oleto | 25006031 |
| Miguel Fernandes Monteiro | 25014808 |
| Samuel Campovilla | 25009747 |

---

## 🛠️ Tecnologias Utilizadas

### Backend
| Tecnologia | Descrição |
|---|---|
| Node.js (LTS) | Runtime JavaScript para o servidor |
| TypeScript / JavaScript | Linguagens de desenvolvimento |
| Firebase Firestore | Banco de dados não relacional |

### Frontend (Mobile)
| Tecnologia | Descrição |
|---|---|
| Flutter | Framework de desenvolvimento mobile |
| Dart | Linguagem de programação |

### Ferramentas e Infraestrutura
| Tecnologia | Descrição |
|---|---|
| Git + GitHub | Controle de versão e repositório remoto |
| GitHub Projects | Gestão de tarefas e apontamento de esforço |
| VS Code / Android Studio | IDEs de desenvolvimento |

---

## 🚀 Como Executar o Projeto

### Pré-requisitos

Certifique-se de ter instalado em sua máquina:

- [Node.js LTS](https://nodejs.org/)
- [Flutter SDK](https://docs.flutter.dev/get-started/install)
- [Dart SDK](https://dart.dev/get-dart) (incluído no Flutter)
- [Git](https://git-scm.com/)
- Conta no [Firebase](https://firebase.google.com/) com acesso ao projeto configurado
- Um emulador Android/iOS ou dispositivo físico conectado

---

### 1. Clonar o repositório

```bash
git clone https://github.com/[seu-usuario]/ES-PI3-2026-T1-G30.git
cd ES-PI3-2026-T1-G30
```

---

### 2. Configurar e executar o Backend

```bash
# Acesse a pasta do backend
cd backend

# Instale as dependências
npm install

# Configure as variáveis de ambiente
cp .env.example .env
# Edite o arquivo .env com as credenciais do Firebase e demais configurações

# Execute em modo de desenvolvimento
npm run dev
```

> O servidor estará disponível em `http://localhost:3000` (ou a porta configurada no `.env`).

---

### 3. Configurar e executar o Aplicativo Mobile

```bash
# Acesse a pasta do frontend
cd mobile

# Instale as dependências do Flutter
flutter pub get

# Verifique se há um emulador rodando ou dispositivo conectado
flutter devices

# Execute o aplicativo
flutter run
```

---

### 4. Variáveis de Ambiente

Crie o arquivo `backend/.env` com base no `.env.example`. As principais variáveis necessárias são:

```env
PORT=3000
FIREBASE_PROJECT_ID=seu_project_id
FIREBASE_PRIVATE_KEY=sua_private_key
FIREBASE_CLIENT_EMAIL=seu_client_email
```

---

## 📁 Estrutura do Repositório

```
ES-PI3-2026-T1-G30/
├── backend/          # API Node.js + TypeScript
│   ├── src/
│   ├── package.json
│   └── .env.example
├── mobile/           # Aplicativo Flutter
│   ├── lib/
│   └── pubspec.yaml
└── README.md
```

---

## 📌 Informações Acadêmicas

| Campo | Informação |
|---|---|
| Instituição | PUC-Campinas |
| Curso | Engenharia de Software |
| Disciplina | Projeto Integrador 3 |
| Ano | 2026 |
| Professor Orientador | Prof. Me. Mateus Pereira Dias |
| Repositório | `ES-PI3-2026-T1-G30` |

---

*Projeto desenvolvido exclusivamente para fins acadêmicos. Não representa oferta pública de valores mobiliários ou captação real de investimentos.*
