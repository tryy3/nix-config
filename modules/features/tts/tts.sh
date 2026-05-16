#!/usr/bin/env bash
set -euo pipefail

# KOKORO_MODEL_DIR, MATCHA_MODEL_DIR, VOCOS_VOCODER, and TTS_BIN are prepended by the Nix wrapper

# Auto-detect optimal threads (cap at 12, diminishing returns beyond physical cores)
NUM_THREADS=$(nproc 2>/dev/null || echo 4)
[ "$NUM_THREADS" -gt 12 ] && NUM_THREADS=12

declare -A VOICE_ID
VOICE_ID[af]=0
VOICE_ID[af_bella]=1
VOICE_ID[af_nicole]=2
VOICE_ID[af_sarah]=3
VOICE_ID[af_sky]=4
VOICE_ID[am_adam]=5
VOICE_ID[am_michael]=6
VOICE_ID[bf_emma]=7
VOICE_ID[bf_isabella]=8
VOICE_ID[bm_george]=9
VOICE_ID[bm_lewis]=10

DEFAULT_VOICE="af_bella"
DEFAULT_SPEED="1.0"
DEFAULT_MODEL="kokoro"

usage() {
	cat <<'EOF'
Usage: tts [OPTIONS] [TEXT]

Read text aloud using local TTS (Kokoro or Matcha-TTS).

Options:
  -f, --file FILE     Read text from FILE
  -u, --url URL       Read text from URL
  -m, --model NAME    TTS model: kokoro (default) or matcha
  -v, --voice NAME    Voice name for Kokoro model (default: af_bella)
  -s, --speed FACTOR  Speech speed (default: 1.0)
  -o, --output FILE   Write audio to FILE instead of playing
  -l, --list-voices   List available Kokoro voices
  -h, --help          Show this help

If no TEXT and no other input options, reads from stdin.

Models:
  kokoro  Best quality, 11 voices, slower (~330MB)
  matcha  Faster, 1 female voice, good quality (~122MB)

Available Kokoro voices:
  American Female: af, af_bella, af_nicole, af_sarah, af_sky
  American Male:   am_adam, am_michael
  British Female:  bf_emma, bf_isabella
  British Male:    bm_george, bm_lewis
EOF
}

voice_to_id() {
	local id="${VOICE_ID[$1]:-}"
	if [ -z "$id" ]; then
		echo "Unknown voice: $1" >&2
		echo "Run 'tts --list-voices' to see available voices." >&2
		return 1
	fi
	echo "$id"
}

list_voices() {
	echo "Available Kokoro voices:"
	echo "  American Female: af, af_bella, af_nicole, af_sarah, af_sky"
	echo "  American Male:   am_adam, am_michael"
	echo "  British Female:  bf_emma, bf_isabella"
	echo "  British Male:    bm_george, bm_lewis"
}

VOICE="$DEFAULT_VOICE"
SPEED="$DEFAULT_SPEED"
MODEL="$DEFAULT_MODEL"
OUTPUT=""
TEXT=""

while [ $# -gt 0 ]; do
	case "$1" in
	-f | --file)
		TEXT=$(cat "${2:?missing file argument}")
		shift 2
		;;
	-u | --url)
		TEXT=$(curl -sL "${2:?missing URL}" | pandoc -f html -t plain --wrap=none 2>/dev/null || true)
		shift 2
		;;
	-m | --model)
		MODEL="${2:?missing model name}"
		shift 2
		;;
	-v | --voice)
		VOICE="${2:?missing voice name}"
		shift 2
		;;
	-s | --speed)
		SPEED="${2:?missing speed factor}"
		shift 2
		;;
	-o | --output)
		OUTPUT="${2:?missing output file}"
		shift 2
		;;
	-l | --list-voices)
		list_voices
		exit 0
		;;
	-h | --help)
		usage
		exit 0
		;;
	--)
		shift
		TEXT="$*"
		break
		;;
	-*)
		echo "Unknown option: $1" >&2
		usage >&2
		exit 1
		;;
	*)
		TEXT="$*"
		break
		;;
	esac
done

if [ -z "$TEXT" ]; then
	TEXT=$(cat)
fi

if [ -z "$(echo "$TEXT" | tr -d '[:space:]')" ]; then
	echo "Error: no text provided." >&2
	usage >&2
	exit 1
fi

case "$MODEL" in
kokoro)
	SID=$(voice_to_id "$VOICE") || exit 1

	LENGTH_SCALE="1.0"
	case "$SPEED" in
	0.25) LENGTH_SCALE="4.0" ;;
	0.5) LENGTH_SCALE="2.0" ;;
	0.75) LENGTH_SCALE="1.3333" ;;
	1.0) LENGTH_SCALE="1.0" ;;
	1.25) LENGTH_SCALE="0.8" ;;
	1.5) LENGTH_SCALE="0.6667" ;;
	2.0) LENGTH_SCALE="0.5" ;;
	*) LENGTH_SCALE="1.0" ;;
	esac

	TTS_CMD=(
		"$TTS_BIN"
		--kokoro-model="$KOKORO_MODEL_DIR/model.onnx"
		--kokoro-voices="$KOKORO_MODEL_DIR/voices.bin"
		--kokoro-tokens="$KOKORO_MODEL_DIR/tokens.txt"
		--kokoro-data-dir="$KOKORO_MODEL_DIR/espeak-ng-data"
		--sid="$SID"
		--kokoro-length-scale="$LENGTH_SCALE"
		--num-threads="$NUM_THREADS"
	)
	;;

matcha)
	TTS_CMD=(
		"$TTS_BIN"
		--matcha-acoustic-model="$MATCHA_MODEL_DIR/model-steps-3.onnx"
		--matcha-vocoder="$VOCOS_VOCODER"
		--matcha-tokens="$MATCHA_MODEL_DIR/tokens.txt"
		--matcha-data-dir="$MATCHA_MODEL_DIR/espeak-ng-data"
		--num-threads="$NUM_THREADS"
	)
	;;

*)
	echo "Unknown model: $MODEL" >&2
	echo "Valid models: kokoro, matcha" >&2
	exit 1
	;;
esac

if [ -n "$OUTPUT" ]; then
	"${TTS_CMD[@]}" --output-filename="$OUTPUT" "$TEXT"
	echo "Audio saved to $OUTPUT"
else
	TMPFILE=$(mktemp --suffix=.wav)
	trap 'rm -f "$TMPFILE"' EXIT

	"${TTS_CMD[@]}" --output-filename="$TMPFILE" "$TEXT"

	if command -v pw-play >/dev/null 2>&1; then
		pw-play "$TMPFILE"
	elif command -v paplay >/dev/null 2>&1; then
		paplay "$TMPFILE"
	elif command -v aplay >/dev/null 2>&1; then
		aplay "$TMPFILE"
	else
		echo "No audio player found." >&2
		echo "Audio written to: $TMPFILE" >&2
		trap - EXIT
		exit 1
	fi
fi
