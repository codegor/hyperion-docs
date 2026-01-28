import { defineConfig, defineDocs, frontmatterSchema, metaSchema } from 'fumadocs-mdx/config';

export const docs = defineDocs({
  docs: {
    dir: 'arch/content/docs',
    schema: frontmatterSchema,
    postprocess: {
      includeProcessedMarkdown: true,
    },
  },
  meta: {
    dir: 'arch/content/docs',
    schema: metaSchema,
  },
});

export default defineConfig({
  mdxOptions: {},
});
