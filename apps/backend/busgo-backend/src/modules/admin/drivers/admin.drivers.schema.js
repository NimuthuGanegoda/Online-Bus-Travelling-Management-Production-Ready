import { z } from 'zod';

export const createDriverSchema = z.object({
  full_name: z.string().min(2),
  email:     z.string().email(),
  phone:     z.string().optional(),
  route_id:  z.string().uuid().optional().nullable(),
});

export const updateDriverSchema = z.object({
  full_name: z.string().min(2).optional(),
  email:     z.string().email().optional(),
  phone:     z.string().optional(),
  route_id:  z.string().uuid().nullable().optional(),
  rating:    z.number().min(0).max(10).optional(),
}).refine((d) => Object.keys(d).length > 0, { message: 'At least one field required' });
