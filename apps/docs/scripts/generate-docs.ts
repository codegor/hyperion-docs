import { generateFiles } from 'fumadocs-openapi';
import { openapi } from '../src/lib/openapi';

generateFiles({
  input: openapi,
  output: './arch/content/docs/api/(generated)',
  includeDescription: true,
}).catch((error) => {
  console.error('Failed to build API documentation', error);
});
