const { Pool } = require('pg');
require('dotenv').config();

const pool = new Pool({
  connectionString: process.env.DATABASE_URL,
});

async function checkTables() {
  try {
    const result = await pool.query("SELECT table_name FROM information_schema.tables WHERE table_schema = 'public' AND table_name LIKE 'rcd_%'");
    console.log('RCD Tables:', result.rows.map(r => r.table_name));
    
    const constraints = await pool.query("SELECT conname, pg_get_constraintdef(oid) FROM pg_constraint WHERE contype = 'c' AND conrelid = 'rcd_learning_events'::regclass");
    console.log('Event type constraints:', constraints.rows);
    
  } catch (error) {
    console.error('DB Error:', error.message);
  } finally {
    await pool.end();
  }
}

checkTables();
