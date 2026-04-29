import { z } from 'zod';

export const scanSchema = z.object({
  // Scanned QR payload — expected format: "BUSGO-<user-uuid>"
  qr_code: z
    .string()
    .min(8, 'qr_code is required')
    .max(128, 'qr_code is too long'),
});
