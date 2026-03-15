import { Router } from "express";
import { cadastroController } from "./auth.controller";


const router = Router();

router.post('/cadastro', cadastroController);

export default router;
