const { Client } = require('pg');

async function main() {
  // Connect to the default 'postgres' database
  const dbUrl = process.env.DATABASE_URL || 'postgresql://postgres:postgres@localhost:5432/x_physics';
  // Replace the database name at the end of the URL with 'postgres' to connect to default DB
  const defaultUrl = dbUrl.replace(/\/x_physics$/, '/postgres');
  
  console.log('Connecting to database:', defaultUrl);
  const client = new Client({ connectionString: defaultUrl });

  try {
    await client.connect();
    console.log('Connected to default postgres database successfully!');
    
    // Check if x_physics database exists
    const res = await client.query("SELECT 1 FROM pg_database WHERE datname='x_physics'");
    if (res.rowCount === 0) {
      console.log("Database 'x_physics' does not exist. Creating it...");
      await client.query("CREATE DATABASE x_physics");
      console.log("Database 'x_physics' created successfully.");
    } else {
      console.log("Database 'x_physics' already exists.");
    }
  } catch (err) {
    console.error('Error connecting to/creating database:', err.message);
    console.error('Make sure PostgreSQL is running on localhost:5432 and the credentials (postgres/postgres) are correct.');
  } finally {
    await client.end();
  }
}

main();
