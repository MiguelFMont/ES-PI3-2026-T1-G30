//repositório base genérico que todos os outros repositórios vão herdar.
//Ele contém as operações básicas do Firestore que se repetem em todo módulo

import { getDb } from '../../config/firebase';

// Define uma classe chamada FirestoreBaseRepo
// "export" permite que outros arquivos importem essa classe
export class FirestoreBaseRepo {

  // Propriedade que armazena o nome da coleção no Firestore (ex: 'users', 'startups')
  // "protected" significa que só essa classe e as classes filhas podem acessar
  // se fosse "private" só essa classe poderia acessar
  // se fosse "public" qualquer um poderia acessar
  protected collectionName: string;

  // Construtor é executado automaticamente quando a classe é instanciada
  // ex: new FirestoreBaseRepo('users')
  // "collectionName: string" é o parâmetro que você passa na criação
  constructor(collectionName: string) {

    // "this" se refere à instância atual da classe
    // aqui está dizendo: pegue o parâmetro recebido e salve na propriedade da classe
    // depois disso qualquer método da classe pode acessar via this.collectionName
    this.collectionName = collectionName;
}

  // Busca um documento pelo ID
  async findById(id: string) {
    const doc = await getDb().collection(this.collectionName).doc(id).get();
    if (!doc.exists) return null;
    return { id: doc.id, ...doc.data() };
  }

  // Busca todos os documentos da coleção
  async findAll() {
    const snapshot = await getDb().collection(this.collectionName).get();
    return snapshot.docs.map((doc) => ({ id: doc.id, ...doc.data() }));
  }

  // Cria um novo documento
  async create(data: object) {
    const ref = await getDb().collection(this.collectionName).add({
      ...data,
      createdAt: new Date(),
      updatedAt: new Date(),
    });
    return ref.id;
  }

  // Atualiza um documento existente
  async update(id: string, data: object) {
    await getDb().collection(this.collectionName).doc(id).update({
      ...data,
      updatedAt: new Date(),
    });
  }

  // Remove um documento
  async delete(id: string) {
    await getDb().collection(this.collectionName).doc(id).delete();
  }
}