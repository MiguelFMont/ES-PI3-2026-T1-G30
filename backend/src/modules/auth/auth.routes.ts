import { Router } from "express";
import {
    iniciarCadastroController,
    concluirCadastroController,
    loginController,
    solicitarRecuperacaoSenhaController,
    redefinirSenhaController,
    validarTokenController,
    reenviarTokenCadastroController,
    logoutController
} from "./auth.controller";
import { authMiddleware } from '../../shared/http/auth.middleware';


const router = Router();

router.post('/logout', authMiddleware, logoutController);
router.post('/register/iniciar', iniciarCadastroController);
router.post('/register/concluir', concluirCadastroController);
router.post('/register/reenviar-token', reenviarTokenCadastroController);
router.post('/login', loginController);
router.post('/recuperar-senha', solicitarRecuperacaoSenhaController);
router.post('/redefinir-senha', redefinirSenhaController);
router.post('/validar-token', validarTokenController)

export default router;
