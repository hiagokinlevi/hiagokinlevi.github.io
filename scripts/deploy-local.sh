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
for attempt in {1..60}; do
  build="$(gh api repos/hiagokinlevi/hiagokinlevi.github.io/pages/builds/latest --jq '.commit + " " + .status')"
  if [[ "$build" == "$revision built" ]]; then
    break
  fi
  if [[ "$build" == "$revision errored" ]]; then
    echo 'GitHub Pages reported a failed build.' >&2
    exit 1
  fi
  if (( attempt == 60 )); then
    echo 'Timed out waiting for the published revision.' >&2
    exit 1
  fi
  sleep 5
done

for attempt in {1..24}; do
  live_page="$(curl --fail --silent --show-error --max-time 15 https://hiagokinlevi.github.io/)"
  if [[ "$live_page" == *'Learn cybersecurity, openly.'* && "$live_page" != *'CyberABC'* ]]; then
    echo "Personal site deployed and verified from main $revision"
    exit 0
  fi
  sleep 5
done
echo 'GitHub Pages built the revision, but the public page did not update in time.' >&2
exit 1
