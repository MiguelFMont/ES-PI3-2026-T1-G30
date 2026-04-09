import { Router } from 'express';
import { StartupsController } from './startups.controller';

const router = Router();
const controller = new StartupsController();

router.get('/', (req, res) => controller.listar(req, res));
router.get('/:id', (req, res) => controller.buscarPorId(req, res));

export default router;