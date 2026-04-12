import { z } from 'zod';

export const adminLoginSchema = z.object({
  email:    z.string().email(),
  password: z.string().min(6),
});

export const adminRefreshSchema = z.object({
  refresh_token: z.string().min(1),
});
