#!/usr/bin/env bash
# One-command setup of these Hermes desktop tweaks on a device that already has
# Hermes installed. Safe to run again: every step skips what is already done.
#
#   curl -fsSL https://raw.githubusercontent.com/ThatCakeIsAPie/hermes-desktop-tweaks/main/setup.sh | bash
#
# or from a clone:  ./setup.sh
#
# What it does:
#   1. Bot Kit    installs Grokbot Override from Hermes Bot Kit (pinned release,
#                 installer checked against a known hash before it runs)
#   2. Plugins    copies this repo's plugins into <hermes home>/desktop-plugins
#   3. App        applies the Hermes app changes from the fork's dispatcher-ui
#                 branch on top of the Hermes version this device already has,
#                 then rebuilds the desktop app (about 10 minutes; a running
#                 Hermes window closes when the build finishes: reopen it)
#   4. Buttons    on a tiling window manager (Hyprland, sway, niri), turns off
#                 the app's own minimize / maximize / close buttons
#   5. Steering   a message sent while a bot is working goes into the running
#                 reply instead of waiting behind it (display.busy_input_mode:
#                 steer), for the main profile and every bot on this device
#
# Options (after `bash -s --` when piping):
#   --plugins-only           step 2 only
#   --no-botkit              skip step 1
#   --no-app                 skip steps 3 and 4
#   --no-build               apply the app changes but do not rebuild
#   --rebuild                rebuild even when nothing new was applied
#   --hide-window-buttons    step 4 on any Linux desktop
#   --keep-window-buttons    never do step 4
#   --no-steer               skip step 5
#
# Env: HERMES_HOME (default ~/.hermes).
set -euo pipefail

REPO_RAW="https://raw.githubusercontent.com/ThatCakeIsAPie/hermes-desktop-tweaks/main"
PLUGINS="btw-dismiss grokbot-tweaks"

BOTKIT_REF="v2026.11.10.4"
BOTKIT_INSTALLER="https://raw.githubusercontent.com/thomasbek3/hermes-bot-kit/${BOTKIT_REF}/install.sh"
# sha256 of that release's install.sh as reviewed. A different file is not run.
BOTKIT_INSTALLER_SHA256="a0ed1b34f65c5784e344d25b169cca4594aed4e7d8cd88cca21bff1e2aed8062"

UPSTREAM_URL="https://github.com/NousResearch/hermes-agent.git"
FORK_URL="https://github.com/ThatCakeIsAPie/hermes-agent.git"
FORK_BRANCH="dispatcher-ui"

HERMES_ROOT="${HERMES_HOME:-$HOME/.hermes}"
SRC="${HERMES_ROOT}/hermes-agent"
PLUGIN_ROOT="${HERMES_ROOT}/desktop-plugins"

DO_BOTKIT=1
DO_APP=1
DO_BUILD=1
FORCE_BUILD=0
BUTTONS=auto
DO_STEER=1

for arg in "$@"; do
  case "${arg}" in
    --plugins-only) DO_BOTKIT=0; DO_APP=0; DO_STEER=0 ;;
    --no-steer) DO_STEER=0 ;;
    --no-botkit) DO_BOTKIT=0 ;;
    --no-app) DO_APP=0 ;;
    --no-build) DO_BUILD=0 ;;
    --rebuild) FORCE_BUILD=1 ;;
    --hide-window-buttons) BUTTONS=hide ;;
    --keep-window-buttons) BUTTONS=keep ;;
    -h|--help) sed -n '2,35p' "${BASH_SOURCE[0]:-/dev/null}" 2>/dev/null | sed 's/^# \{0,1\}//'; exit 0 ;;
    *) echo "setup.sh: unknown option '${arg}' (see --help)" >&2; exit 2 ;;
  esac
done

HERE=""
if [ -n "${BASH_SOURCE:-}" ] && [ -f "${BASH_SOURCE[0]:-}" ]; then
  HERE=$(CDPATH= cd -- "$(dirname -- "${BASH_SOURCE[0]}")" && pwd)
fi

TMP=$(mktemp -d)
trap 'rm -rf "${TMP}"' EXIT

SUMMARY=""
report() { # report <step> <text>
  printf '%-8s %s\n' "$1" "$2"
  SUMMARY="${SUMMARY}$(printf '  %-8s %s' "$1" "$2")
"
}

sha256_of() {
  if command -v sha256sum >/dev/null 2>&1; then
    sha256sum -- "$1" | awk '{print $1}'
  else
    shasum -a 256 -- "$1" | awk '{print $1}'
  fi
}

if [ ! -d "${HERMES_ROOT}" ]; then
  echo "setup.sh: no Hermes home at ${HERMES_ROOT}. Install Hermes first:" >&2
  echo "  curl -fsSL https://hermes-agent.nousresearch.com/install.sh | bash" >&2
  exit 1
fi

# ── 1. Bot Kit ───────────────────────────────────────────────────────────────
step_botkit() {
  local file="${TMP}/botkit-install.sh" actual
  if ! curl -fsSL "${BOTKIT_INSTALLER}" -o "${file}"; then
    report "Bot Kit" "FAILED: could not download the ${BOTKIT_REF} installer"
    return 0
  fi
  actual=$(sha256_of "${file}")
  if [ "${actual}" != "${BOTKIT_INSTALLER_SHA256}" ]; then
    report "Bot Kit" "FAILED: installer does not match the reviewed copy (got ${actual}); not run"
    return 0
  fi
  if KIT_SKIP_COMPUTER=1 HERMES_HOME="${HERMES_ROOT}" bash "${file}" > "${TMP}/botkit.log" 2>&1; then
    report "Bot Kit" "Grokbot Override ${BOTKIT_REF} installed"
  else
    report "Bot Kit" "FAILED: its installer exited with an error:"
    sed 's/^/    /' "${TMP}/botkit.log" | tail -n 8
  fi
}

# ── 2. This repo's plugins ───────────────────────────────────────────────────
step_plugins() {
  local name src dest changed="" same="" failed=""
  for name in ${PLUGINS}; do
    src="${TMP}/${name}.plugin.js"
    if [ -n "${HERE}" ] && [ -f "${HERE}/${name}/plugin.js" ]; then
      cp "${HERE}/${name}/plugin.js" "${src}"
    elif ! curl -fsSL "${REPO_RAW}/${name}/plugin.js" -o "${src}"; then
      failed="${failed} ${name}"
      continue
    fi
    if ! grep -q 'export default' "${src}"; then
      failed="${failed} ${name}"
      continue
    fi
    dest="${PLUGIN_ROOT}/${name}/plugin.js"
    mkdir -p "${PLUGIN_ROOT}/${name}"
    if cmp -s "${src}" "${dest}" 2>/dev/null; then
      same="${same} ${name}"
    else
      cp "${src}" "${dest}"
      changed="${changed} ${name}"
    fi
  done
  [ -z "${changed}" ] || report "Plugins" "installed:${changed}"
  [ -z "${same}" ] || report "Plugins" "already up to date:${same}"
  [ -z "${failed}" ] || report "Plugins" "FAILED to fetch:${failed}"
}

# ── 3. Hermes app changes ────────────────────────────────────────────────────
APPLIED=0
APP_READY=0 # the checkout carries every app change (now or from an earlier run)

step_app() {
  local up tip base commits branch start local_subjects c subject missing="" count=0 created=0 kept=""
  if ! command -v git >/dev/null 2>&1 || [ ! -d "${SRC}/.git" ]; then
    report "App" "skipped: ${SRC} is not a git checkout of Hermes, so its app cannot be rebuilt from here"
    return 0
  fi
  if ! git -C "${SRC}" diff --quiet || ! git -C "${SRC}" diff --cached --quiet; then
    report "App" "skipped: ${SRC} has uncommitted changes; commit or stash them and run this again"
    return 0
  fi

  if ! git -C "${SRC}" fetch -q "${UPSTREAM_URL}" main 2>"${TMP}/git.log"; then
    report "App" "FAILED: could not fetch Hermes from GitHub"
    return 0
  fi
  up=$(git -C "${SRC}" rev-parse FETCH_HEAD)
  if ! git -C "${SRC}" fetch -q "${FORK_URL}" "${FORK_BRANCH}" 2>"${TMP}/git.log"; then
    report "App" "FAILED: could not fetch ${FORK_BRANCH} from the fork"
    return 0
  fi
  tip=$(git -C "${SRC}" rev-parse FETCH_HEAD)

  # The app changes are the fork branch's commits that upstream does not have.
  base=$(git -C "${SRC}" merge-base "${up}" "${tip}")
  commits=$(git -C "${SRC}" rev-list --reverse "${base}..${tip}")
  if [ -z "${commits}" ]; then
    report "App" "nothing to apply: the fork branch has no changes of its own"
    APP_READY=1
    return 0
  fi

  # Already applied = an ancestor of HEAD, or a local commit with the same
  # subject (a cherry-pick here, or the same change after the fork was rebased).
  local_subjects=$(git -C "${SRC}" log --format=%s "${up}..HEAD")
  for c in ${commits}; do
    if git -C "${SRC}" merge-base --is-ancestor "${c}" HEAD; then
      continue
    fi
    subject=$(git -C "${SRC}" log -1 --format=%s "${c}")
    if printf '%s\n' "${local_subjects}" | grep -qxF -- "${subject}"; then
      continue
    fi
    missing="${missing} ${c}"
  done

  if [ -z "${missing}" ]; then
    report "App" "changes already applied"
    APP_READY=1
    return 0
  fi

  # Keep the changes on their own branch so `main` still matches upstream.
  branch=$(git -C "${SRC}" branch --show-current)
  start=$(git -C "${SRC}" rev-parse HEAD)
  if [ "${branch}" != "${FORK_BRANCH}" ]; then
    if git -C "${SRC}" show-ref --verify --quiet "refs/heads/${FORK_BRANCH}"; then
      # Left behind by an earlier run, then a Hermes update moved the checkout
      # off it. Keep it under another name and rebuild the branch from here.
      kept="${FORK_BRANCH}-before-$(date +%Y%m%d-%H%M%S)"
      git -C "${SRC}" branch -q -m "${FORK_BRANCH}" "${kept}"
    fi
    git -C "${SRC}" switch -q -c "${FORK_BRANCH}"
    created=1
  fi

  local ident=()
  git -C "${SRC}" config user.email >/dev/null 2>&1 || ident=(-c user.name="Hermes tweaks" -c user.email="hermes-tweaks@localhost")

  for c in ${missing}; do
    if git -C "${SRC}" ${ident[@]+"${ident[@]}"} cherry-pick -x "${c}" > "${TMP}/pick.log" 2>&1; then
      count=$((count + 1))
    else
      git -C "${SRC}" cherry-pick --abort >/dev/null 2>&1 || true
      if [ "${count}" -eq 0 ] && [ "${created}" -eq 1 ]; then
        # Nothing landed: put the checkout back exactly where it was.
        if [ -n "${branch}" ]; then
          git -C "${SRC}" switch -q "${branch}"
        else
          git -C "${SRC}" switch -q --detach "${start}"
        fi
        git -C "${SRC}" branch -q -D "${FORK_BRANCH}"
        [ -z "${kept}" ] || git -C "${SRC}" branch -q -m "${kept}" "${FORK_BRANCH}"
      fi
      report "App" "FAILED: '$(git -C "${SRC}" log -1 --format=%s "${c}")' does not apply to this device's Hermes version ($(git -C "${SRC}" describe --tags --always "${start}" 2>/dev/null)). ${count} change(s) applied before it."
      APPLIED=${count}
      return 0
    fi
  done
  APPLIED=${count}
  APP_READY=1
  report "App" "applied ${count} change(s) on branch '${FORK_BRANCH}'${kept:+ (the earlier one is kept as '${kept}')}"
}

step_build() {
  if [ "${APPLIED}" -eq 0 ] && [ "${FORCE_BUILD}" -ne 1 ]; then
    return 0
  fi
  if [ "${DO_BUILD}" -ne 1 ]; then
    report "Build" "skipped (--no-build): run 'hermes desktop --build-only' to finish"
    return 0
  fi
  if ! command -v hermes >/dev/null 2>&1; then
    report "Build" "skipped: no 'hermes' command on PATH; run 'hermes desktop --build-only' yourself"
    return 0
  fi
  echo "Build    rebuilding the desktop app (about 10 minutes; an open Hermes window will close)…"
  if (cd "${SRC}" && NODE_OPTIONS="${NODE_OPTIONS:---max-old-space-size=4096}" hermes desktop --build-only) > "${TMP}/build.log" 2>&1; then
    report "Build" "desktop app rebuilt: reopen Hermes"
  else
    report "Build" "FAILED: last lines of the build output:"
    tail -n 12 "${TMP}/build.log" | sed 's/^/    /'
  fi
}

# ── 4. Window buttons (Linux, needs the app changes) ─────────────────────────
on_tiling_wm() {
  [ -n "${HYPRLAND_INSTANCE_SIGNATURE:-}" ] || [ -n "${SWAYSOCK:-}" ] || [ -n "${NIRI_SOCKET:-}" ] && return 0
  case "${XDG_CURRENT_DESKTOP:-}" in *[Hh]yprland*|*sway*|*niri*) return 0 ;; esac
  pgrep -x Hyprland >/dev/null 2>&1 || pgrep -x sway >/dev/null 2>&1 || pgrep -x niri >/dev/null 2>&1
}

step_buttons() {
  local file="${XDG_CONFIG_HOME:-$HOME/.config}/Hermes/window-controls.json"
  [ "$(uname -s)" = "Linux" ] || return 0
  [ "${BUTTONS}" != "keep" ] || return 0
  if [ "${APP_READY}" -ne 1 ]; then
    return 0
  fi
  if [ -f "${file}" ]; then
    report "Buttons" "left as set in ${file}"
    return 0
  fi
  if [ "${BUTTONS}" = "hide" ] || on_tiling_wm; then
    mkdir -p "$(dirname -- "${file}")"
    printf '{\n  "hidden": true\n}\n' > "${file}"
    report "Buttons" "window buttons turned off (${file}); applies the next time Hermes starts"
  else
    report "Buttons" "left on: no tiling window manager found (--hide-window-buttons turns them off)"
  fi
}

# ── 5. Messages sent while a bot is working steer it ────────────────────────
set_steer() { # set_steer <profile name>
  if [ "$1" = "default" ]; then
    HERMES_HOME="${HERMES_ROOT}" hermes config set display.busy_input_mode steer >/dev/null 2>&1
  else
    HERMES_HOME="${HERMES_ROOT}" hermes -p "$1" config set display.busy_input_mode steer >/dev/null 2>&1
  fi
}

step_steer() {
  local home name changed="" same="" failed=""
  if ! command -v hermes >/dev/null 2>&1; then
    report "Steering" "skipped: no 'hermes' command on PATH"
    return 0
  fi
  for home in "${HERMES_ROOT}" "${HERMES_ROOT}"/profiles/*/; do
    home="${home%/}"
    [ -f "${home}/config.yaml" ] || continue
    if [ "${home}" = "${HERMES_ROOT}" ]; then name="default"; else name=$(basename -- "${home}"); fi
    if grep -qE '^[[:space:]]+busy_input_mode:[[:space:]]*"?steer"?[[:space:]]*$' "${home}/config.yaml"; then
      same="${same} ${name}"
    elif set_steer "${name}" \
        && grep -qE '^[[:space:]]+busy_input_mode:[[:space:]]*"?steer"?[[:space:]]*$' "${home}/config.yaml"; then
      changed="${changed} ${name}"
    else
      failed="${failed} ${name}"
    fi
  done
  [ -z "${changed}" ] || report "Steering" "turned on for:${changed}"
  [ -z "${same}" ] || report "Steering" "already on for:${same}"
  [ -z "${failed}" ] || report "Steering" "FAILED for:${failed} (run: hermes -p <name> config set display.busy_input_mode steer)"
}

[ "${DO_BOTKIT}" -ne 1 ] || step_botkit
step_plugins
if [ "${DO_APP}" -eq 1 ]; then
  step_app
  step_buttons
  step_build
fi
[ "${DO_STEER}" -ne 1 ] || step_steer

echo
echo "Summary"
printf '%s' "${SUMMARY}"
echo
echo "If the Bots tab looks unchanged, run 'Reload desktop plugins' from the command palette, or restart Hermes."
case "${SUMMARY}" in
  *FAILED*) exit 1 ;;
esac
