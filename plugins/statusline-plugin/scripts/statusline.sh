#!/usr/bin/env bash
# Powerline-style status line for Claude Code
# Displays: path, git branch, changes, model, duration, context usage, rate limits
# Requires: jq, git, Nerd Font compatible terminal

INPUT=$(cat)

# ── Parse JSON ──
MODEL_DISPLAY=$(echo "$INPUT" | jq -r '.model.display_name // "Unknown"')
MODEL_ID=$(echo "$INPUT" | jq -r '.model.id // ""')
CTX_PCT=$(echo "$INPUT" | jq -r '.context_window.used_percentage // 0')
CWD=$(echo "$INPUT" | jq -r '.cwd // ""')
LINES_ADDED=$(echo "$INPUT" | jq -r '.cost.total_lines_added // 0')
LINES_REMOVED=$(echo "$INPUT" | jq -r '.cost.total_lines_removed // 0')
DURATION_MS=$(echo "$INPUT" | jq -r '.cost.total_duration_ms // 0')

# Rate limits
FIVE_HR_USED=$(echo "$INPUT" | jq -r '.rate_limits.five_hour.used_percentage // ""')
FIVE_HR_RESETS=$(echo "$INPUT" | jq -r '.rate_limits.five_hour.resets_at // ""')
SEVEN_DAY_USED=$(echo "$INPUT" | jq -r '.rate_limits.seven_day.used_percentage // ""')
SEVEN_DAY_RESETS=$(echo "$INPUT" | jq -r '.rate_limits.seven_day.resets_at // ""')

# ── Derived values ──

# Git branch
BRANCH=$(git -C "${CWD:-.}" branch --show-current 2>/dev/null || true)
BRANCH="${BRANCH:-—}"

# Shorten path (replace $HOME with ~, then truncate if long)
SHORT_PATH="${CWD/#$HOME/~}"
if [ "${#SHORT_PATH}" -gt 20 ]; then
  PARENT=$(basename "$(dirname "$CWD")")
  DIR=$(basename "$CWD")
  SHORT_PATH="…/${PARENT}/${DIR}"
fi

# Duration: ms → Xhr Ym
DURATION_SEC=$((DURATION_MS / 1000))
HOURS=$((DURATION_SEC / 3600))
MINUTES=$(( (DURATION_SEC % 3600) / 60 ))

# Context percentage with 1 decimal
CTX_DISPLAY=$(printf "%.1f" "$CTX_PCT")

# Model version from ID
case "$MODEL_ID" in
  *opus-4-6*|*opus-4.6*)     MODEL_VER="Opus 4.6" ;;
  *sonnet-4-5*|*sonnet-4.5*) MODEL_VER="Sonnet 4.5" ;;
  *haiku-4-5*|*haiku-4.5*)   MODEL_VER="Haiku 4.5" ;;
  *opus*)   MODEL_VER="Opus" ;;
  *sonnet*) MODEL_VER="Sonnet" ;;
  *haiku*)  MODEL_VER="Haiku" ;;
  *)        MODEL_VER="$MODEL_DISPLAY" ;;
esac

# Format reset times (convert to JST)
_to_jst() {
  local iso=$1 fmt=$2
  # Remove fractional seconds
  local clean=$(echo "$iso" | sed -E 's/\.[0-9]+//')
  local datetime="${clean:0:19}"   # 2026-03-20T12:00:00
  local tz_part="${clean:19}"      # Z, +09:00, +0000, etc.

  # Parse source timezone offset in seconds
  local offset_sec=0
  case "$tz_part" in
    Z) offset_sec=0 ;;
    +*|-*)
      local sign="${tz_part:0:1}"
      local tz_clean=$(echo "$tz_part" | tr -d ':')
      local tz_h=$((10#${tz_clean:1:2}))
      local tz_m=$((10#${tz_clean:3:2}))
      offset_sec=$(( tz_h * 3600 + tz_m * 60 ))
      [ "$sign" = "-" ] && offset_sec=$(( -offset_sec ))
      ;;
  esac

  # Parse datetime as UTC, subtract source offset to get true UTC epoch
  local epoch
  epoch=$(TZ=UTC date -j -f "%Y-%m-%dT%H:%M:%S" "$datetime" "+%s" 2>/dev/null) || { echo "--"; return; }
  epoch=$(( epoch - offset_sec ))

  # Convert UTC epoch to JST
  TZ=Asia/Tokyo date -j -r "$epoch" "+${fmt}" 2>/dev/null || echo "--"
}

if [ -n "$FIVE_HR_RESETS" ]; then
  FIVE_HR_RESET_DISPLAY=$(_to_jst "$FIVE_HR_RESETS" "%H:%M")
else
  FIVE_HR_RESET_DISPLAY="--:--"
fi

if [ -n "$SEVEN_DAY_RESETS" ]; then
  SEVEN_DAY_RESET_DISPLAY=$(_to_jst "$SEVEN_DAY_RESETS" "%m/%d %H:%M")
else
  SEVEN_DAY_RESET_DISPLAY="--/-- --:--"
fi

# Format used percentages
FIVE_HR_DISPLAY="${FIVE_HR_USED:-N/A}"
SEVEN_DAY_DISPLAY="${SEVEN_DAY_USED:-N/A}"

# Progress bar: 20 blocks (each = 5%), narrow-spaced: █ █ █ ░ ░ ░
THIN_SP=$(printf '\xe2\x80\x89')  # U+2009 thin space
_progress_bar() {
  local pct=${1:-0}
  local filled=$(( (pct + 2) / 5 ))
  [ "$filled" -gt 20 ] && filled=20
  [ "$filled" -lt 0 ] && filled=0
  local empty=$((20 - filled))
  local bar=""
  bar+="$(_fg 215)"
  for ((i=0; i<filled; i++)); do
    [ "$i" -gt 0 ] && bar+="${THIN_SP}"
    bar+="█"
  done
  bar+="$(_fg 240)"
  for ((i=0; i<empty; i++)); do
    [ "$i" -eq 0 ] && [ "$filled" -gt 0 ] && bar+="${THIN_SP}"
    [ "$i" -gt 0 ] && bar+="${THIN_SP}"
    bar+="░"
  done
  printf '%s' "$bar"
}

# ── Powerline characters (requires Nerd Font) ──
SEP=$(printf '\xee\x82\xb0')
BRANCH_ICON=$(printf '\xee\x82\xa0')

# ── Colors (256-color mode) — Blue + Orange accent ──
BG1=24; BG2=31; BG3=172
BG4=29; BG5=37; BG6=172
FG_LIGHT=255

# ANSI helpers
_bg()    { printf '\033[48;5;%dm' "$1"; }
_fg()    { printf '\033[38;5;%dm' "$1"; }
_reset() { printf '\033[0m'; }

# ── Line 1: [path] ▶ [ branch] ▶ [(+N,-N)] ──
L1=""
L1+="$(_bg $BG1)$(_fg $FG_LIGHT) ${SHORT_PATH} "
L1+="$(_fg $BG1)$(_bg $BG2)${SEP}"
L1+="$(_fg $FG_LIGHT) ${BRANCH_ICON} ${BRANCH} "
L1+="$(_fg $BG2)$(_bg $BG3)${SEP}"
L1+="$(_fg $FG_LIGHT) (+${LINES_ADDED},-${LINES_REMOVED}) "
L1+="$(_reset)"

# ── Line 2: [model] ▶ [Block: Xhr Ym] ▶ [Ctx: N.N%] ──
L2=""
L2+="$(_bg $BG1)$(_fg $FG_LIGHT) ${MODEL_VER} "
L2+="$(_fg $BG1)$(_bg $BG2)${SEP}"
L2+="$(_fg $FG_LIGHT) Block: ${HOURS}hr ${MINUTES}m "
L2+="$(_fg $BG2)$(_bg $BG3)${SEP}"
L2+="$(_fg $FG_LIGHT) Ctx: ${CTX_DISPLAY}% "
L2+="$(_reset)"

# ── Line 3: Current  ████░░░░  N%  Reset: HH:MM ──
L3=""
L3+="$(_fg $FG_LIGHT) Current  $(_progress_bar "${FIVE_HR_USED:-0}")  $(_fg $FG_LIGHT)${FIVE_HR_DISPLAY}%  Reset: ${FIVE_HR_RESET_DISPLAY} JST"
L3+="$(_reset)"

# ── Line 4: Weekly  ████░░░░  N%  Reset: MM/DD HH:MM ──
L4=""
L4+="$(_fg $FG_LIGHT) Weekly   $(_progress_bar "${SEVEN_DAY_USED:-0}")  $(_fg $FG_LIGHT)${SEVEN_DAY_DISPLAY}%  Reset: ${SEVEN_DAY_RESET_DISPLAY} JST"
L4+="$(_reset)"

DIMLINE="$(_fg 240)─────────────────────────────$(_reset)"
echo "$L1"
echo "$L2"
echo "$DIMLINE"
echo "$L3"
echo ""
echo "$L4"
