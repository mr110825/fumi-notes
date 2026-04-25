import { defineCollection } from 'astro:content';
import { glob } from 'astro/loaders';
import { z } from 'zod';

const blog = defineCollection({
  loader: glob({ pattern: '**/*.md', base: './src/content/blog' }),
  schema: z.object({
    title: z.string().min(1).max(200),
    pubDate: z.coerce.date(),
    updatedDate: z.coerce.date().optional(),
    tags: z.array(z.string()).max(10).default([]),
    type: z.enum(['post', 'jot']).default('post'),
    draft: z.boolean().default(false),
    description: z.string().max(300).optional(),
  }),
});

export const collections = { blog };
