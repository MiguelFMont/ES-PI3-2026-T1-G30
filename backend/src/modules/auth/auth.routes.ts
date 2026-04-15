import { Router } from "express";
import {
    cadastroController,
    loginController,
    solicitarRecuperacaoSenha,
    redefinirSenha
} from "./auth.controller";


const router = Router();

router.post('/register', cadastroController);
router.post('/login', loginController);
router.post('/recuperar-senha', solicitarRecuperacaoSenha);
router.post('/redefinir-senha', redefinirSenha);



export default router;
