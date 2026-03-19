// Importa o tipo CorsOptions da biblioteca cors
// é uma interface que define quais opções são aceitas na configuração do CORS
import { CorsOptions } from 'cors';

// Exporta a configuração do CORS para ser usada no server.ts
// ": CorsOptions" garante que só opções válidas sejam colocadas aqui
export const corsOptions: CorsOptions = {

  // Define quais origens podem fazer requisições ao backend
  // '*' significa qualquer origem — em produção trocar pelo domínio real
  // ex: origin: 'https://meuapp.com'
  origin: '*',

  // Define quais métodos HTTP são permitidos
  // GET    → buscar dados
  // POST   → criar dados
  // PUT    → atualizar dados
  // DELETE → deletar dados
  methods: ['GET', 'POST', 'PUT', 'DELETE'],

  // Define quais headers o Flutter pode enviar nas requisições
  // Content-Type   → indica que o body é JSON
  // Authorization  → onde o token JWT do Firebase é enviado
  allowedHeaders: ['Content-Type', 'Authorization'],
};