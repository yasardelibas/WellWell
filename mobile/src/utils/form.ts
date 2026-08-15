import type { FieldValues, Resolver } from 'react-hook-form';
import type { ZodType } from 'zod';

/**
 * Minimal Zod resolver for React Hook Form. Written locally so validation stays on the
 * schema version the app already depends on, without an extra adapter package.
 */
export function zodValidator<TValues extends FieldValues>(schema: ZodType<TValues>): Resolver<TValues> {
  return async (values) => {
    const result = await schema.safeParseAsync(values);

    if (result.success) {
      return { values: result.data, errors: {} };
    }

    const errors: Record<string, { type: string; message: string }> = {};

    for (const issue of result.error.issues) {
      const path = issue.path.join('.');

      if (path.length > 0 && !errors[path]) {
        errors[path] = { type: issue.code, message: issue.message };
      }
    }

    return { values: {} as TValues, errors: errors as never };
  };
}
