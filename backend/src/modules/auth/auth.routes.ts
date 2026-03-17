import { Router } from "express";
import { cadastroController, loginController } from "./auth.controller";


const router = Router();

router.post('/register', cadastroController);
router.post('/login', loginController);

export default router;
