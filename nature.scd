/*
 *
 *               _
 *   _ __   __ _| |_ _   _ _ __ ___
 *  | '_ \ / _` | __| | | | '__/ _ \
 *  | | | | (_| | |_| |_| | | |  __/
 *  |_| |_|\__,_|\__|\__,_|_|  \___|
 *
 *
 *  SuperCollider
 *
 */

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

	// Apply Envelope
	sig = sig * env;

	Out.ar(out, sig);
}).add;
)

// Define Bird Synth
(
SynthDef.new(\birdGenerator,{

	arg out = 0;
	var sig, env, lfo, freq;

	env = EnvGen.kr(Env.new([0, 1, 1, 0], [2, 1], [1, -1]), doneAction: 2);
	lfo = Vibrato.ar(EnvGen.kr(Env.new([30, 0, 30],[2, 1], [1,-1]), doneAction: 0), 6, 1);
	freq = XLine.ar(600, 1000, 3, doneAction: 2);

	// Resonant Filter
	sig = DFM1.ar(0, freq, 0.2)!2;

	// Apply LFO and Envelope
	sig = sig * env * lfo;

	Out.ar(out, sig);
}).add;
)

w = Synth.new(\waveGenerator);

b = Synth.new(\birdGenerator);

s.meter;
