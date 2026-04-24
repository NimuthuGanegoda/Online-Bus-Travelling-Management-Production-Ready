const URL = 'https://thfphwduxzyojnnbuwey.supabase.co/rest/v1';
const KEY = 'eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJpc3MiOiJzdXBhYmFzZSIsInJlZiI6InRoZnBod2R1eHp5b2pubmJ1d2V5Iiwicm9sZSI6InNlcnZpY2Vfcm9sZSIsImlhdCI6MTc3Mjc4MjI2NiwiZXhwIjoyMDg4MzU4MjY2fQ.1a-plPphtr88K8Jwug-9_G02TrCdfoXkmPgPBv2ELYU';

async function post(path, data) {
    const res = await fetch(`${URL}/${path}`, {
        method: 'POST',
        headers: {
            'apikey': KEY,
            'Authorization': `Bearer ${KEY}`,
            'Content-Type': 'application/json',
            'Prefer': 'return=minimal'
        },
        body: JSON.stringify(data)
    });
    if (!res.ok) console.error(`Error on ${path}:`, await res.text());
}

async function run() {
    console.log("Generating 200 transactions (lowercase)...");
    const txs = Array.from({length: 200}, (_, i) => ({
        id: i + 1,
        user_id: (i % 200) + 1,
        ride_id: i + 1,
        amount: 50 + (Math.random() * 100),
        transaction_type: 'payment',
        payment_method: 'wallet',
        status: 'completed'
    }));
    for (let i = 0; i < txs.length; i += 50) await post('transactions', txs.slice(i, i + 50));

    console.log("Generating 100 emergency alerts (lowercase)...");
    const alerts = Array.from({length: 100}, (_, i) => ({
        id: i + 1,
        sender_type: 'driver',
        sender_id: (i % 50) + 1,
        bus_id: (i % 50) + 1,
        alert_type: i % 3 === 0 ? 'traffic' : 'medical',
        severity_level: (i % 3) + 1,
        description: "Incident reported near Colombo Hub.",
        latitude: 6.9 + (Math.random() * 0.05),
        longitude: 79.8 + (Math.random() * 0.1),
        status: 'resolved',
        priority: `P${(i % 3) + 1}`
    }));
    for (let i = 0; i < alerts.length; i += 50) await post('emergency_alerts', alerts.slice(i, i + 50));

    console.log("Generating 200 QR scans (lowercase)...");
    const scans = Array.from({length: 200}, (_, i) => ({
        id: i + 1,
        user_id: (i % 200) + 1,
        bus_id: (i % 50) + 1,
        stop_id: (i % 20) + 1,
        scan_type: i % 2 === 0 ? 'board' : 'alight',
        scanned_by_driver_id: (i % 50) + 1
    }));
    for (let i = 0; i < scans.length; i += 50) await post('qr_scans', scans.slice(i, i + 50));

    console.log("Final Heavy Lifting Completed!");
}

run();
