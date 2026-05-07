import { Router } from 'express';
import authRoutes from './auth/auth.routes';
import startupsRoutes from './startups/startups.routes';
// import usersRoutes from './users/users.routes';
// import tokensRoutes from './tokens/tokens.routes';
// import walletRoutes from './wallet/wallet.routes';
// import questionsRoutes from './questions/questions.routes';
import walletRoutes from './wallet/wallet.routes';
// import usersRoutes from './users/users.routes';
// import tokensRoutes from './tokens/tokens.routes';
// import questionsRoutes from './questions/questions.routes';

const router = Router();

router.use('/auth', authRoutes);
router.use('/startups', startupsRoutes);
// router.use('/users', usersRoutes);
// router.use('/tokens', tokensRoutes);
// router.use('/wallet', walletRoutes);
// router.use('/questions', questionsRoutes);
router.use('/wallet', walletRoutes);
// router.use('/users', usersRoutes);
// router.use('/tokens', tokensRoutes);
// router.use('/questions', questionsRoutes);

export default router;