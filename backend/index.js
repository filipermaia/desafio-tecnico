import http from 'http';
import PG from 'pg';

const user = process.env.user;
const pass = process.env.pass;
const host = process.env.host;
const db_port = process.env.db_port;
const db_name = process.env.db_name;
const port = Number(process.env.port);
const client = new PG.Client(
  `postgres://${user}:${pass}@${host}:${db_port}/${db_name}`
);

let successfulConnection = false;

async function runMigrations(client) {
  console.log('[MIGRATION] Inserindo dados iniciais...');
  const adminPass = process.env.ADMIN_PASSWORD;
  
  if (!adminPass) {
    console.error('[MIGRATION] ✗ ADMIN_PASSWORD não definido');
    process.exit(1);
  }
  
  try {
    const existing = await client.query(`
      SELECT username FROM "users" WHERE username = 'admin' LIMIT 1;
    `);
    
    if (existing.rows.length === 0) {
      await client.query(`
        INSERT INTO "users" (username, password, role)
        VALUES ('admin', $1, 'admin');
      `, [adminPass]);
      console.log('[MIGRATION] ✓ Usuário admin criado');
    } else {
      console.log('[MIGRATION] ✓ Usuário admin já existe');
    }
  } catch (error) {
    console.error('[MIGRATION] Erro:', error.message);
  }
}

client.connect()
  .then(() => {
    successfulConnection = true;
    console.log('[BACKEND] ✓ Conectado ao banco de dados');
    return runMigrations(client);
  })
  .then(() => {
    console.log('[BACKEND] Pronto para receber requisições');
  })
  .catch(err => {
    console.error('[BACKEND] ✗ Erro:', err.message);
    process.exit(1);
  });

http.createServer(async (req, res) => {
  console.log(`Request: ${req.url}`);

  if (req.url === "/api") {
    res.setHeader("Content-Type", "application/json");
    res.writeHead(200);

    let result;

    try {
      result = (await client.query("SELECT * FROM users")).rows[0];
    } catch (error) {
      console.error(error)
    }

    const data = {
      database: successfulConnection,
      userAdmin: result?.role === "admin"
    }

    res.end(JSON.stringify(data));
  } else {
    res.writeHead(503);
    res.end("Internal Server Error");
  }

}).listen(port, () => {
  console.log(`Server is listening on port ${port}`);
});