import { app } from './server';

const port = Number(process.env.PORT ?? 3000);

app.listen(port, () => {
  console.log(`Backend local disponível em http://localhost:${port}/v1`);
});
