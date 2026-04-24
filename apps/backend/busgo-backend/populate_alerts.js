import { createClient } from '@supabase/supabase-js';
import dotenv from 'dotenv';

dotenv.config();

const supabase = createClient(
  process.env.SUPABASE_URL,
  process.env.SUPABASE_SERVICE_ROLE_KEY
);

async function populate() {
  // Get some valid IDs
  const { data: users } = await supabase.from('users').select('id').limit(10);
  const { data: buses } = await supabase.from('buses').select('id').limit(10);
  const { data: drivers } = await supabase.from('drivers').select('id').limit(10);

  if (!users?.length || !buses?.length) {
    console.error('Need users and buses to seed alerts.');
    return;
  }

  console.log('Generating emergency alerts...');
  const alerts = Array.from({ length: 20 }, (_, i) => ({
    user_id: users[i % users.length].id,
    bus_id: buses[i % buses.length].id,
    driver_id: drivers ? drivers[i % drivers.length].id : null,
    alert_type: ['medical', 'criminal', 'breakdown', 'harassment', 'other'][i % 5],
    priority: `P${(i % 3) + 1}`,
    description: `Automated emergency alert #${i + 1}`,
    latitude: 6.9 + (Math.random() * 0.1),
    longitude: 79.8 + (Math.random() * 0.1),
    status: i % 2 === 0 ? 'resolved' : 'pending'
  }));

  const { error } = await supabase.from('emergency_alerts').insert(alerts);
  if (error) console.error('Error seeding alerts:', error.message);
  else console.log('Successfully seeded 20 emergency alerts.');
}

populate();
