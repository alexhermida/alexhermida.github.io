# alexhermida.dev

Personal blog built with [Hugo](https://gohugo.io/) and [PaperMod](https://github.com/adityatelange/hugo-PaperMod).

## Requirements

- Hugo Extended `0.166.0`
- Git with submodule support

## Development

Clone the repository including the theme:

```bash
git clone --recurse-submodules git@github.com:alexhermida/blog.git
cd blog
```

Run the development server:

```bash
hugo server -D
```

## Production build

Build the production site locally:

```bash
hugo --minify --gc
```

The generated site is written to `public/`.

## Updating PaperMod

PaperMod is tracked as a Git submodule and pinned to a specific commit. Update it explicitly when desired:

```bash
git -C themes/PaperMod fetch origin
git -C themes/PaperMod checkout <commit>
git add themes/PaperMod
git commit -m "Update PaperMod"
```

## Deployment

Pushes to `main` are built and deployed to GitHub Pages using GitHub Actions. Pull requests build the site without deploying it.

The production site is published at [alexhermida.dev](https://alexhermida.dev).
