import type { NextConfig } from "next";
import createMDX from "@next/mdx";

const nextConfig: NextConfig = {
  pageExtensions: ["js", "jsx", "md", "mdx", "ts", "tsx"],
};

const withMDX = createMDX({
  extension: /\.(md|mdx)$/,
  options: {
    remarkPlugins: ["remark-frontmatter", "remark-gfm", "remark-mdx-frontmatter"],
    rehypePlugins: [],
  },
});

export default withMDX(nextConfig);