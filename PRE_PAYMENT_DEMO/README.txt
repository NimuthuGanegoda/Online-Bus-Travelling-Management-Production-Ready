This project demonstrates a full end-to-end integration of the Payee payment gateway in sandbox mode. 
It allows you to test payments in Sri Lankan applications without using real money. 
The setup includes a backend server to securely generate sandbox payment payloads and a frontend form 
to initiate transactions and redirect to the Payee sandbox checkout page.

Features:
- Backend built with Node.js and Express.
- Secure sandbox payment payload generation using your merchant secret key.
- Frontend HTML form for entering customer details and payment amount.
- Automatic redirection to Payee sandbox checkout page for end-to-end testing.
- Environment variables support via .env for secret key and port configuration.

Folder Structure:
my-payee-app/
├─ .env                 # Environment variables (merchant secret, port)
├─ package.json         # Project dependencies and scripts
├─ server.js            # Backend server (creates sandbox payment payload)
└─ public/
    └─ index.html       # Frontend payment form

How to Run:
1. Clone or download the repository.
2. Install dependencies:
   npm install
3. Add your .env file with the following:
   PAYEE_MERCHANT_ID=123456
   PAYEE_SECRET=your_sandbox_secret_key
   PORT=3000
4. Start the server:
   npm start
5. Open your browser: http://localhost:3000
6. Fill the payment form and click "Pay Now" to be redirected to the sandbox checkout page.

Notes:
- This setup uses sandbox credentials only; no real payments are processed.
- The signature is generated on the server using your secret key to ensure the sandbox request is valid.
- Ideal for testing payment flows in Sri Lankan applications before going live.
