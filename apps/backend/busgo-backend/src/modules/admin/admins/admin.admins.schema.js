import { z } from 'zod';

export const createAdminSchema = z.object({
  full_name: z.string().min(2),
  email:     z.string().email(),
  phone:     z.string().optional(),
  password:  z.string().min(8),
  role:      z.enum(['super_admin', 'admin', 'moderator']).default('admin'),
});

export const updateAdminSchema = z.object({
  full_name: z.string().min(2).optional(),
  phone:     z.string().optional(),
  role:      z.enum(['super_admin', 'admin', 'moderator']).optional(),
}).refine((d) => Object.keys(d).length > 0, { message: 'At least one field required' });
