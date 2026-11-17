#!/usr/bin/env bash
# Narrated lesson video for a deck: slide PNGs (Slidev export) + macOS `say` reading <deck>/narration.md.
# Usage: scripts/make-video.sh <deck> [voice] [rate]   e.g. scripts/make-video.sh ios-swift Samantha 175
# Output: dist/<deck>-lesson.mp4. Needs macOS (say), ffmpeg, and `npx playwright install chromium-headless-shell`.
set -euo pipefail

deck=${1:?usage: make-video.sh <deck> [voice] [rate]}
voice=${2:-Samantha}
rate=${3:-175}
root=$(cd "$(dirname "$0")/.." && pwd)
work="$root/dist/.video-$deck"
out="$root/dist/$deck-lesson.mp4"

rm -rf "$work" && mkdir -p "$work/png" "$work/txt" "$work/clips"
cd "$root"

npx slidev export "$deck/slides.md" --format png --output "$work/png" --timeout 120000 --wait 2000 >/dev/null

# narration.md: an HTML comment header, then one block per slide split by lines of "---"
sed '/^<!--/,/-->$/d' "$deck/narration.md" |
  awk -v dir="$work/txt" 'BEGIN{n=1} /^---$/{n++; next} {print > (dir "/" n ".txt")}'

slides=$(ls "$work/png" | wc -l | tr -d ' ')
blocks=$(ls "$work/txt" | wc -l | tr -d ' ')
[[ "$slides" == "$blocks" ]] || { echo "narration has $blocks blocks but the deck has $slides slides" >&2; exit 1; }

: > "$work/list.txt"
for i in $(seq 1 "$slides"); do
  say -v "$voice" -r "$rate" -o "$work/clips/$i.aiff" -f "$work/txt/$i.txt"
  # 0.4 s lead-in and 0.8 s tail of silence so slides don't feel rushed
  ffmpeg -loglevel error -y -loop 1 -framerate 30 -i "$work/png/$i.png" -i "$work/clips/$i.aiff" \
    -filter_complex "[0:v]scale=1920:1080:force_original_aspect_ratio=decrease,pad=1920:1080:(ow-iw)/2:(oh-ih)/2:white,format=yuv420p[v];[1:a]adelay=400|400,apad=pad_dur=0.8[a]" \
    -map "[v]" -map "[a]" -c:v libx264 -tune stillimage -preset veryfast -r 30 -c:a aac -b:a 160k -ar 48000 -shortest \
    "$work/clips/$i.mp4"
  echo "file '$work/clips/$i.mp4'" >> "$work/list.txt"
  echo "slide $i/$slides"
done

ffmpeg -loglevel error -y -f concat -safe 0 -i "$work/list.txt" -c copy -movflags +faststart "$out"
echo "wrote $out ($(ffprobe -v error -show_entries format=duration -of csv=p=0 "$out" | cut -d. -f1) s)"
