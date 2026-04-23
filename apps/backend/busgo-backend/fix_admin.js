import { createClient } from '@supabase/supabase-js';
import bcrypt from 'bcryptjs';

const supabase = createClient(
  'https://thfphwduxzyojnnbuwey.supabase.co',
  'eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJpc3MiOiJzdXBhYmFzZSIsInJlZiI6InRoZnBod2R1eHp5b2pubmJ1d2V5Iiwicm9sZSI6InNlcnZpY2Vfcm9sZSIsImlhdCI6MTc3Mjc4MjI2NiwiZXhwIjoyMDg4MzU4MjY2fQ.1a-plPphtr88K8Jwug-9_G02TrCdfoXkmPgPBv2ELYU'
);

async function fix() {
  const hash = await bcrypt.hash('Admin123!', 12);
  const { data, error } = await supabase
    .from('admins')
    .upsert({
      id: 'a0000000-0000-0000-0000-000000000001',
      full_name: 'Admin Master',
      email: 'admin@busgo.lk',
      password_hash: hash,
      role: 'super_admin',
      status: 'active'
    }, { onConflict: 'email' });

  if (error) {
    console.error('Error:', error);
  } else {
    console.log('Admin account fixed successfully!');
  }
}

fix();
