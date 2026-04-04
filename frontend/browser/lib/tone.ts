// TODO:
// [ ] Tone context on user gesture; AudioProvider — https://tonejs.github.io/docs/
// [ ] routing: master volume from Zustand ui store — https://tonejs.github.io/docs/classes/Volume
// [ ] loadSound(url); playSound(id) cached — https://tonejs.github.io/docs/classes/Player
// [ ] Analyser → Three uniform; FFT from NEXT_PUBLIC_AUDIO_FFT_SIZE — https://threejs.org/docs/#api/en/audio/AudioAnalyser
//
import * as Tone from "tone";

let masterReady = false;

export async function ensureToneStarted(): Promise<void> {
	if (Tone.context.state !== "running") {
		await Tone.start();
	}
	if (!masterReady) {
		await setupMasterChain();
		masterReady = true;
	}
}

let masterReverb: Tone.Reverb | null = null;
let masterEq: Tone.EQ3 | null = null;
let masterComp: Tone.Compressor | null = null;

export async function setupMasterChain(): Promise<void> {
	if (masterReverb && masterEq && masterComp) return;
	masterReverb = new Tone.Reverb({ decay: 1.2, wet: 0.12 }).toDestination();
	await masterReverb.generate();
	masterEq = new Tone.EQ3({ low: -2, mid: 0, high: 1 }).connect(masterReverb);
	masterComp = new Tone.Compressor({ threshold: -18, ratio: 3, attack: 0.003, release: 0.1 }).connect(
		masterEq,
	);
	Tone.getDestination().volume.value = -2;
}

export function getMasterOutput(): Tone.ToneAudioNode {
	if (!masterComp) {
		return Tone.getDestination();
	}
	return masterComp;
}

export function createSynth(type: "synth" | "amsynth" | "fmsynth" = "synth"): Tone.PolySynth {
	if (type === "amsynth") {
		return new Tone.PolySynth(Tone.AMSynth).connect(getMasterOutput());
	}
	if (type === "fmsynth") {
		return new Tone.PolySynth(Tone.FMSynth).connect(getMasterOutput());
	}
	return new Tone.PolySynth(Tone.Synth).connect(getMasterOutput());
}

export function createPlayer(url: string): Tone.Player {
	const player = new Tone.Player(url).connect(getMasterOutput());
	return player;
}

export function createSampler(urls: Record<string, string | string[]>): Tone.Sampler {
	return new Tone.Sampler({ urls } as ConstructorParameters<typeof Tone.Sampler>[0]).connect(
		getMasterOutput(),
	);
}

export async function playNote(
	instrument: Tone.PolySynth | Tone.Synth,
	note: string | Tone.Unit.Frequency,
	duration: Tone.Unit.Time = "8n",
): Promise<void> {
	await ensureToneStarted();
	instrument.triggerAttackRelease(note, duration);
}

export async function playChord(
	instrument: Tone.PolySynth,
	notes: (string | Tone.Unit.Frequency)[],
	duration: Tone.Unit.Time = "4n",
): Promise<void> {
	await ensureToneStarted();
	instrument.triggerAttackRelease(notes, duration);
}

export async function playSequence(
	steps: { time: Tone.Unit.Time; note: string | string[]; duration?: Tone.Unit.Time }[],
	instrument: Tone.PolySynth,
): Promise<void> {
	await ensureToneStarted();
	const part = new Tone.Part((time, ev) => {
		const dur = ev.duration ?? "8n";
		if (Array.isArray(ev.note)) {
			instrument.triggerAttackRelease(ev.note, dur, time);
		} else {
			instrument.triggerAttackRelease(ev.note, dur, time);
		}
	}, steps.map((s) => ({ time: s.time, note: s.note, duration: s.duration }))).start(0);
	Tone.Transport.start();
	part.stop(`+${steps.length * 0.25}`);
}
