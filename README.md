# alexhermida.dev

Personal blog built with [Hugo](https://gohugo.io/) and [PaperMod](https://github.com/adityatelange/hugo-PaperMod).

## Requirements

- Hugo Extended `0.166.0`
- Git with submodule support

## Development

Clone the repository including the theme:

```bash
git clone --recurse-submodules git@github.com:alexhermida/alexhermida.github.io.git
cd blog
```

Run the development server:

```bash
hugo server -D
```

## Validate changes locally

Work on a branch created from an up-to-date `main`:

```bash
git switch main
git pull --ff-only
git switch -c <type>/<change-name>
```

Preview drafts and changes locally:

```bash
hugo server -D
```

Before committing, run the same validation used by CI:

```bash
scripts/check-site.sh
```

The check requires Hugo Extended `0.166.0`, builds into a temporary directory, verifies critical pages and assets, and rejects accidental `/blog/` deployment paths.

To retain a production build in `public/`, run:

```bash
hugo --minify --gc
```

## Updating PaperMod

PaperMod is tracked as a Git submodule and pinned to a specific commit. Update it explicitly when desired:

```bash
git -C themes/PaperMod fetch origin
git -C themes/PaperMod checkout <commit>
git add themes/PaperMod
git commit -m "Update PaperMod"
```

## Deployment

Open a pull request from the working branch into `main`. Pull requests run the complete site validation without deploying. Only a merge or direct push to `main` builds and deploys the GitHub Pages artifact.

The production site is published at [alexhermida.dev](https://alexhermida.dev).
