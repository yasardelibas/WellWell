import { z } from 'zod';

export const signInSchema = z.object({
  email: z.string().trim().min(1, 'Enter your email address.').email('Enter a valid email address.'),
  password: z.string().min(1, 'Enter your password.'),
});

export const signUpSchema = z.object({
  displayName: z.string().trim().min(2, 'Enter the name you would like to be called.'),
  email: z.string().trim().min(1, 'Enter your email address.').email('Enter a valid email address.'),
  password: z
    .string()
    .min(10, 'Use at least 10 characters.')
    .max(128, 'Use at most 128 characters.')
    .regex(/[A-Za-z]/, 'Use at least 10 characters with a mix of letters and numbers.')
    .regex(/\d/, 'Use at least 10 characters with a mix of letters and numbers.'),
});

export const forgotPasswordSchema = z.object({
  email: z.string().trim().min(1, 'Enter your email address.').email('Enter a valid email address.'),
});

export type SignInValues = z.infer<typeof signInSchema>;
export type SignUpValues = z.infer<typeof signUpSchema>;
export type ForgotPasswordValues = z.infer<typeof forgotPasswordSchema>;
