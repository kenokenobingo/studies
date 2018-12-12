/*
 *
 *               _
 *   _ __   __ _| |_ _   _ _ __ ___
 *  | '_ \ / _` | __| | | | '__/ _ \
 *  | | | | (_| | |_| |_| | | |  __/
 *  |_| |_|\__,_|\__|\__,_|_|  \___|
 *
 *
 *  #+METHOD: Simulation: `SimCity for Nature`
 *  #+AUTHOR: K E N O
 *  #+TITLE: At the beach
 *  #+TOOL: SuperCollider
 *
 */

// Increase the server’s a,llocated memory
s.options.memSize = 100000;
// Boot the SuperCollider Server
s.boot;

// Define Wave Synth
(
SynthDef.new(\waveGenerator,{

	arg out = 0, fadeIn = 3, fadeOut = 2;
	var sig, env;

	env = EnvGen.kr(Env.new([0, 0.8, 0],[fadeIn, fadeOut], [1,-1]), doneAction: 2);

	// Mix Pink and Brown Noise for Wave Signal
	sig = PinkNoise.ar(1)!2 * 0.75 + BrownNoise.ar(EnvGen.kr(Env.new([0.2, 1, 0], [fadeIn, fadeOut], [1, -1]), doneAction: 2)) * 0.25;

	f = JPverb.ar(sig, 5, 0, 1, 0, 0);

	// Apply Envelope
	sig = sig * env + (f * 0.25);

	Out.ar(out, sig);
}).add;
)

// Define Sea Gull Synth
(
SynthDef.new(\gullGenerator, {

	arg out = 0;
	var sig, env, lfo, freq, temp, vibrato;

	env = EnvGen.kr(Env.new([0, 2, 1, 0], [0.05, 1], [1, -1]), doneAction: 2);
	lfo = XLine.ar(3, 30);
	// freq = XLine.ar(600, 660, 3, doneAction: 2);


	vibrato = Vibrato.ar(100, 6, 0.8);

	// Resonant Filter
	sig = Formant.ar(XLine.kr(800, 600, 0.5), XLine.kr(2000, 1400, 0.5), XLine.kr(1000, 700, 0.5), mul: 0.6)!2 + Formant.ar(XLine.kr(330, 150, 0.5), 805, 880, mul: 0.25)!2 + Saw.ar(XLine.ar(330, 300, 0.5), mul: XLine.kr(0.2, 0, 0.5));

	// Echo + Reverb
	e = Greyhole.ar(sig, 5, 0.1, 0.2, feedback: 0.8, modDepth: 1, modFreq: 10);
	f = FreeVerb.ar(sig, 0.33, 0.8, 0.3, 0.25);

	// Apply LFO and Envelope
	sig = sig * 0.1 + (0.5 * f) + e * env;

	sig = sig * 0.5;
	Out.ar(out, sig);
}).add;
)

// Define Bubbles
(
SynthDef(\bubbleGenerator, {	|out=0, t_trig=0, attack=0.01, decay=0.08, pitchcurvelen=0.1, freq=400, doneAction=0, amp=0.1|
	var pitch, son;
	amp   = amp * EnvGen.ar(Env.perc(attack, decay).delay(0.003), t_trig, doneAction: doneAction);
	pitch = freq * EnvGen.ar(Env.new([0,0,1],[0,1]).exprange(1, 2.718), t_trig, timeScale: pitchcurvelen);
	son = SinOsc.ar(pitch);
	// Low-pass to remove any highpitched artifacts, scale amplitude
	son = LPF.ar(son, 500) * amp * 10;
	f = JPverb.ar(son, 5, 0, 1, 0, 0);
	son = son + (f * 0.5);
	Out.ar(out, son);
}).add
)

// Scene
(
var gull_dur, wave_dur, bubble_dur, gull_task, wave_task, bubble_task;
gull_dur = Prand([1, 2, 3, 0.5, 0.5, 1, 0.5, 2, 1, 0.5], 10).asStream;
wave_dur = Prand([2, 2, 1, 0.5, 0.5, 1, 1, 2, 2, 3], 12).asStream;
bubble_dur = Prand([2, 2, 1, 0.5, 0.5, 1, 1, 2, 2, 3], 12).asStream;

x = Synth(\bubbleGenerator);

// Call the sea gulls
gull_task = Task({
    var gull_delta;
    while {
        gull_delta = gull_dur.next;
        gull_delta.notNil;
    } {
        Synth(\gullGenerator);
        gull_delta.yield;
    }
}).play(quant: TempoClock.default.beats + 1.0);

// Start the waves
wave_task = Task({
    var wave_delta;
	while {
		wave_delta = wave_dur.next;
	    wave_delta.notNil;
	} {
		Synth(\waveGenerator);
		wave_delta.yield;
	}
}).play(quant: TempoClock.default.beats + 1.0);

// Bubble bath
bubble_task = Task({
    var bubble_delta;
	while {
		bubble_delta = bubble_dur.next;
	    bubble_delta.notNil;
	} {
		x.set(\t_trig, 1);
		bubble_delta.yield;
	}
}).play(quant: TempoClock.default.beats + 1.0);
)