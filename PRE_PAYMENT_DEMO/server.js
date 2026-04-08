require('dotenv').config();
const express = require('express');
const bodyParser = require('body-parser');
const crypto = require('crypto');
const path = require('path');

const app = express();
app.use(bodyParser.urlencoded({ extended: true }));
app.use(bodyParser.json());
app.use(express.static(path.join(__dirname, 'public')));

const MERCHANT_ID = process.env.PAYEE_MERCHANT_ID || '123456'; // default sandbox ID
const SECRET = process.env.PAYEE_SECRET;
const PORT = process.env.PORT || 3000;

// Serve front-end
app.get('/', (req, res) => {
    res.sendFile(path.join(__dirname, 'public/index.html'));
});

// Endpoint to create sandbox payment
app.post('/create-payment', (req, res) => {
    const { first_name, last_name, email, amount } = req.body;
    const order_id = 'ORD-' + Date.now();

    // Create MD5 signature using secret key
    const dataString = `merchant_id=${MERCHANT_ID}&order_id=${order_id}&amount=${amount}&first_name=${first_name}&last_name=${last_name}&email=${email}&secret=${SECRET}`;
    const signature = crypto.createHash('md5').update(dataString).digest('hex');

    res.json({
        merchant_id: MERCHANT_ID,
        order_id,
        amount,
        first_name,
        last_name,
        email,
        signature
    });
});

app.listen(PORT, () => {
    console.log(`Server running on port ${PORT}`);
});
