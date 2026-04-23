import { createClient } from '@supabase/supabase-js';
import fs from 'fs';

const supabase = createClient(
  'https://thfphwduxzyojnnbuwey.supabase.co',
  'eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJpc3MiOiJzdXBhYmFzZSIsInJlZiI6InRoZnBod2R1eHp5b2pubmJ1d2V5Iiwicm9sZSI6InNlcnZpY2Vfcm9sZSIsImlhdCI6MTc3Mjc4MjI2NiwiZXhwIjoyMDg4MzU4MjY2fQ.1a-plPphtr88K8Jwug-9_G02TrCdfoXkmPgPBv2ELYU'
);

async function run() {
  // Reading schema files
  const schema = fs.readFileSync('src/db/schema.sql', 'utf8');
  const adminSchema = fs.readFileSync('src/db/admin_schema.sql', 'utf8');
  const fullSql = schema + '\n' + adminSchema;

  console.log('Running schema setup...');
  const { error } = await supabase.rpc('exec_sql', { sql_body: fullSql });
  
  if (error) {
    if (error.message.includes('exec_sql')) {
      console.log('NOTICE: exec_sql RPC not found. You might need to run the SQL in Supabase Dashboard manually.');
    } else {
      console.error('Error:', error);
    }
  } else {
    console.log('Schema created successfully!');
  }
}

run();
