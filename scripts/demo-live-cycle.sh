#!/usr/bin/env bash
# demo-live-cycle.sh — grade-F live demo for payments-service-grade-f
#
#   ./scripts/demo-live-cycle.sh start    # bump snakeyaml 1.30 → 1.33 + open PR
#   ./scripts/demo-live-cycle.sh finish   # close PR(s) without merge; restore community 1.30
#   ./scripts/demo-live-cycle.sh status
#
# Expected pipeline: headline F → grade-gate FAILS (fail-on D).
# Do not bump json-path here (that is payments-service-grade-c).
set -euo pipefail
ROOT="$(cd "$(dirname "$0")/.." && pwd)"
cd "$ROOT"

POM=pom.xml
COMMUNITY='1.30'
TARGET='1.33'
PROP='snakeyaml.version'
BRANCH_PREFIX='demo/live-snakeyaml'
LABEL='demo-live-pom'
SCORECARD='https://scorecard-gradef-upgrade-delta-demo.apps.asaran.na-launch.com/out/reports/scorecard.html'

die() { echo "FATAL: $*" >&2; exit 1; }
need() { command -v "$1" >/dev/null || die "'$1' required"; }

prop_ver() {
  local f="${1:-$POM}"
  sed -n "s/.*<${PROP}>\\([^<]*\\)<\\/${PROP}>.*/\\1/p" "$f" | head -1
}

ensure_baseline() {
  local v
  v=$(prop_ver "$POM")
  [ "$v" = "$COMMUNITY" ] || die \
    "$POM has ${PROP}=$v (want $COMMUNITY on the branch you start from). Run: $0 finish"
}

cmd_status() {
  echo "${PROP} in $POM: $(prop_ver "$POM")  (baseline=$COMMUNITY demo=$TARGET)"
  echo "branch: $(git rev-parse --abbrev-ref HEAD)  sha: $(git rev-parse --short HEAD)"
  if command -v gh >/dev/null; then
    echo "open demo PRs:"
    gh pr list --label "$LABEL" --state open 2>/dev/null || \
      gh pr list --search "head:$BRANCH_PREFIX" --state open 2>/dev/null || true
  fi
}

cmd_start() {
  need git
  need gh
  [ -f "$POM" ] || die "missing $POM"
  git rev-parse --is-inside-work-tree >/dev/null

  local base="${DEMO_BASE_BRANCH:-main}"
  echo "== sync $base =="
  git fetch origin "$base" 2>/dev/null || true
  git checkout "$base"
  git pull --ff-only origin "$base" 2>/dev/null || git pull --ff-only || true
  ensure_baseline

  if [ ! -f .tekton/pull-request-live.yaml ]; then
    echo "WARN: .tekton/pull-request-live.yaml missing — live pipeline will not fire."
  fi

  local stamp branch
  stamp=$(date +%Y%m%d-%H%M)
  branch="${BRANCH_PREFIX}-${stamp}"
  echo "== create $branch =="
  git checkout -b "$branch"

  if grep -q "<${PROP}>${COMMUNITY}</${PROP}>" "$POM"; then
    sed -i.bak "s|<${PROP}>${COMMUNITY}</${PROP}>|<${PROP}>${TARGET}</${PROP}>|" "$POM"
    rm -f "${POM}.bak"
  else
    die "expected <${PROP}>${COMMUNITY}</${PROP}> in $POM"
  fi
  [ "$(prop_ver "$POM")" = "$TARGET" ] || die "bump failed"

  git add "$POM"
  git commit -m "$(cat <<EOF
demo: adopt snakeyaml ${TARGET} (grade F / reachable break)

Live-pipeline demo trigger. Close without merging when done
(./scripts/demo-live-cycle.sh finish) so ${base} stays on community ${COMMUNITY}.
EOF
)"

  echo "== push + open PR =="
  git push -u origin HEAD

  local body
  body=$(cat <<EOF
## Live pom.xml demo — grade **F** (reachable break)

Bumps \`${PROP}\` \`${COMMUNITY}\` → \`${TARGET}\` (community, not Lightwell) so
\`upgrade-delta-live\` grades a reachable API removal via \`ConfigLoader\`
(expected project grade **F**). Grade-gate **fails** (\`fail-on: D\`) — that is the demo.

### Reset
**Do not merge.** When done:

\`\`\`bash
./scripts/demo-live-cycle.sh finish
\`\`\`

See upgrade-delta [docs/DEMO-LIVE-POM.md](https://github.com/anurag-saran/upgrade-delta/blob/main/docs/DEMO-LIVE-POM.md).
EOF
)

  local url
  url=$(gh pr create \
    --base "$base" \
    --title "demo: snakeyaml ${COMMUNITY} to ${TARGET} (grade F)" \
    --body "$body" \
    --label "$LABEL" 2>&1) || {
      gh label create "$LABEL" --description "Live pom.xml demo PR — close without merge" --color "0E8A16" 2>/dev/null || true
      url=$(gh pr create \
        --base "$base" \
        --title "demo: snakeyaml ${COMMUNITY} to ${TARGET} (grade F)" \
        --body "$body")
      local n
      n=$(gh pr view --json number -q .number)
      gh pr edit "$n" --add-label "$LABEL" 2>/dev/null || true
    }
  echo "$url"
  echo
  echo "Watch: OpenShift PipelineRun upgrade-delta-live-pr-gradef-..."
  echo "Scorecard: ${SCORECARD}"
  echo "Expect: headline F → grade-gate fails"
  echo "When done:  ./scripts/demo-live-cycle.sh finish"
}

cmd_finish() {
  need git
  need gh
  local base="${DEMO_BASE_BRANCH:-main}"

  echo "== close open demo PRs (no merge) =="
  local nums
  nums=$(gh pr list --label "$LABEL" --state open --json number -q '.[].number' 2>/dev/null || true)
  if [ -z "$nums" ]; then
    nums=$(gh pr list --search "head:${BRANCH_PREFIX}" --state open --json number -q '.[].number' 2>/dev/null || true)
  fi
  if [ -z "$nums" ]; then
    echo "(no open demo PRs found)"
  else
    for n in $nums; do
      echo "closing PR #$n"
      gh pr close "$n" --comment \
        "Demo complete — closed without merge so \`${base}\` stays on community ${PROP} (${COMMUNITY}) for the next \`./scripts/demo-live-cycle.sh start\`." \
        || true
    done
  fi

  echo "== ensure $base baseline =="
  git fetch origin "$base" 2>/dev/null || true
  git checkout "$base"
  git pull --ff-only origin "$base" 2>/dev/null || git pull --ff-only || true

  local v
  v=$(prop_ver "$POM")
  if [ "$v" != "$COMMUNITY" ]; then
    echo "WARN: $base has ${PROP}=$v — restoring community ${COMMUNITY}"
    sed -i.bak "s|<${PROP}>${v}</${PROP}>|<${PROP}>${COMMUNITY}</${PROP}>|" "$POM"
    rm -f "${POM}.bak"
    git add "$POM"
    git commit -m "demo: restore community ${PROP} ${COMMUNITY} on ${base} after live demo"
    git push origin "$base"
  else
    echo "OK: $POM already on community ${COMMUNITY}"
  fi

  git branch --list "${BRANCH_PREFIX}-*" | while read -r b; do
    b=$(echo "$b" | tr -d ' *')
    [ -n "$b" ] && git branch -D "$b" 2>/dev/null || true
  done

  cmd_status
  echo "Ready for next: ./scripts/demo-live-cycle.sh start"
}

usage() {
  echo "Usage: $0 {start|finish|status}"
  echo "  start   — bump snakeyaml 1.30 → 1.33 (grade F) on a new branch + open PR"
  echo "  finish  — close demo PR(s) without merge; restore community snakeyaml on main"
  echo "  status  — show current snakeyaml version and open demo PRs"
}

case "${1:-}" in
  start)  cmd_start ;;
  finish) cmd_finish ;;
  status) cmd_status ;;
  *) usage; exit 2 ;;
esac
