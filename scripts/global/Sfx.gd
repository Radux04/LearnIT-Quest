extends Node

## Tiny procedural sound engine: every cue is synthesised at startup, so the
## project needs no external audio files.

const MIX_RATE := 22050
const VOICES := 6

var _streams: Dictionary = {}
var _players: Array[AudioStreamPlayer] = []
var _next_player: int = 0


func _ready() -> void:
	process_mode = Node.PROCESS_MODE_ALWAYS
	for i in range(VOICES):
		var player: AudioStreamPlayer = AudioStreamPlayer.new()
		player.bus = "Master"
		add_child(player)
		_players.append(player)

	_streams["click"] = _tone([880.0, 1320.0], 0.07, 0.25, "square")
	_streams["place"] = _tone([523.0, 784.0, 1046.0], 0.16, 0.32, "sine")
	_streams["correct"] = _tone([659.0, 880.0, 1174.0], 0.22, 0.30, "sine")
	_streams["error"] = _tone([196.0, 165.0, 110.0], 0.30, 0.30, "saw")
	_streams["packet"] = _tone([1046.0, 1318.0], 0.10, 0.22, "sine")
	_streams["scan"] = _tone([784.0, 988.0], 0.09, 0.24, "sine")
	_streams["alarm"] = _tone([440.0, 330.0, 440.0, 330.0], 0.45, 0.28, "square")
	_streams["victory"] = _tone([523.0, 659.0, 784.0, 1046.0], 0.55, 0.30, "sine")
	_streams["fail"] = _tone([330.0, 262.0, 196.0, 131.0], 0.70, 0.30, "saw")


func play(cue: String) -> void:
	if not _streams.has(cue):
		return
	var player: AudioStreamPlayer = _players[_next_player]
	_next_player = (_next_player + 1) % VOICES
	player.stream = _streams[cue]
	player.play()


## Builds a short arpeggio from the given frequencies with a soft envelope.
func _tone(freqs: Array, duration: float, volume: float, wave: String) -> AudioStreamWAV:
	var frame_count: int = int(MIX_RATE * duration)
	var data: PackedByteArray = PackedByteArray()
	data.resize(frame_count * 2)
	var step_count: int = freqs.size()
	@warning_ignore("integer_division")
	var frames_per_step: int = maxi(frame_count / step_count, 1)

	for i in range(frame_count):
		@warning_ignore("integer_division")
		var step: int = mini(i / frames_per_step, step_count - 1)
		var freq: float = float(freqs[step])
		var local_t: float = float(i % frames_per_step) / float(frames_per_step)
		var t: float = float(i) / float(MIX_RATE)
		var phase: float = fposmod(t * freq, 1.0)

		var sample: float = 0.0
		match wave:
			"square":
				sample = 1.0 if phase < 0.5 else -1.0
			"saw":
				sample = phase * 2.0 - 1.0
			_:
				sample = sin(phase * TAU)

		# Attack / decay envelope per step, plus a global fade out.
		var env: float = minf(local_t * 12.0, 1.0) * (1.0 - local_t * 0.55)
		var global_env: float = 1.0 - pow(float(i) / float(frame_count), 3.0)
		var value: float = sample * env * global_env * volume
		var pcm: int = clampi(int(value * 32767.0), -32768, 32767)
		if pcm < 0:
			pcm += 65536
		data[i * 2] = pcm & 0xFF
		data[i * 2 + 1] = (pcm >> 8) & 0xFF

	var stream: AudioStreamWAV = AudioStreamWAV.new()
	stream.format = AudioStreamWAV.FORMAT_16_BITS
	stream.mix_rate = MIX_RATE
	stream.stereo = false
	stream.data = data
	return stream
