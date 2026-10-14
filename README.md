# Hiago Kin Levi — personal website

This repository publishes the static, English-language personal profile at [hiagokinlevi.github.io](https://hiagokinlevi.github.io/). It introduces [OpenCyber Academy](https://opencyber.academy/), DAI and ADAI research, and selected defensive engineering projects. The GitHub profile README lives separately in [hiagokinlevi/hiagokinlevi](https://github.com/hiagokinlevi/hiagokinlevi).

## Files and publication

- `index.html` is the accessible single-page site. It uses semantic sections, local CSS, an existing GitHub avatar and no application runtime.
- `404.html` is the custom not-found page; `favicon.svg` is the site's own icon; `robots.txt` and `sitemap.xml` describe the public homepage.
- GitHub Pages serves the `main` branch root using its **legacy branch build**, without GitHub Actions. The configured destination is `https://hiagokinlevi.github.io/`.

To publish from an authorized local checkout:

1. Make the edit, then run `python3 scripts/validate.py` and review `git diff --check` and the changed page locally.
2. Commit the verified files as `hiagokinlevi`.
3. Run `./scripts/deploy-local.sh`. It checks the GitHub account, repository, branch-based Pages source, a clean checkout and remote ancestry; it pushes without force, then compares the public HTML, 404 page, icon, robots file and sitemap byte for byte with the local files. GitHub's legacy Pages build API can lag the live site, so the deployed files are the publication check.

Do not create GitHub Actions workflows for this site. If publication is delayed, inspect the Pages status and the live URL before reporting success.
