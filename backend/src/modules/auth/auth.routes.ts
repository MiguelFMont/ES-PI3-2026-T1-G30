import { Router } from "express";
import { cadastroController, loginController, recoverPasswordController } from "./auth.controller";


const router = Router();

router.post('/register', cadastroController);
router.post('/login', loginController);
router.post('/recover-password', recoverPasswordController);

export default router;
