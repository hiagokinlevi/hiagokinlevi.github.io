#!/usr/bin/env bash
set -euo pipefail
cd "$(dirname "$0")/.."

expected_repo='https://github.com/hiagokinlevi/hiagokinlevi.github.io.git'
if [[ "$(git remote get-url origin)" != "$expected_repo" ]]; then
  echo 'Unexpected GitHub destination.' >&2
  exit 1
fi
if [[ "$(gh api user --jq .login)" != 'hiagokinlevi' ]]; then
  echo 'Unexpected authenticated GitHub account.' >&2
  exit 1
fi
if [[ "$(gh api repos/hiagokinlevi/hiagokinlevi.github.io/pages --jq '.build_type + ":" + .source.branch + ":" + .source.path')" != 'legacy:main:/' ]]; then
  echo 'Unexpected GitHub Pages source. Refusing to use an Actions-based deployment.' >&2
  exit 1
fi

python3 scripts/validate.py
if [[ -n "$(git status --porcelain)" ]]; then
  echo 'Commit the verified site before deploying.' >&2
  exit 1
fi
git fetch origin main
if ! git merge-base --is-ancestor origin/main HEAD; then
  echo 'Remote main has newer work. Reconcile it before publishing.' >&2
  exit 1
fi

revision="$(git rev-parse HEAD)"
git push origin HEAD:main
verification_dir="$(mktemp -d)"
trap 'rm -rf "$verification_dir"' EXIT
for attempt in {1..60}; do
  all_match=true
  for path in index.html 404.html robots.txt sitemap.xml; do
    if [[ "$path" == index.html ]]; then
      url="https://hiagokinlevi.github.io/?revision=$revision"
    else
      url="https://hiagokinlevi.github.io/$path?revision=$revision"
    fi
    if ! curl --fail --silent --show-error --max-time 15 --output "$verification_dir/$path" "$url" ||
       ! cmp -s "$path" "$verification_dir/$path"; then
      all_match=false
      break
    fi
  done
  if [[ "$all_match" == true ]]; then
    echo "Personal site deployed and verified from main $revision"
    exit 0
  fi
  sleep 5
done
echo 'Timed out waiting for the public site to match the verified local files.' >&2
exit 1
