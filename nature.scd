/*
 *               _
 *   _ __   __ _| |_ _   _ _ __ ___
 *  | '_ \ / _` | __| | | | '__/ _ \
 *  | | | | (_| | |_| |_| | | |  __/
 *  |_| |_|\__,_|\__|\__,_|_|  \___|
 *
 *
 *  #+METHOD: Simulation as in `SimCity for Nature`
 *  #+AUTHOR: K E N O
 *  #+TITLE: At the beach (Tag am Meer)
 *  #+TOOL: SuperCollider
 *
 */

// Increase the server’s a,llocated memory
s.options.memSize = 1000000;
// Boot the SuperCollider Server
s.boot;

// Define Bubble Synth
(
SynthDef(\bubbleGenerator, {

	arg out=0, t_trig=0, attack=0.01, decay=0.08, pitchcurvelen=0.1, freq=400, doneAction=0, amp=0.1;
	var pitch, sig, env;

	env = amp * EnvGen.ar(Env.perc(attack, decay).delay(0.003), t_trig, doneAction: doneAction);
	pitch = freq * EnvGen.ar(Env.new([0,0,1],[0,1]).exprange(1, 2.718), t_trig, timeScale: pitchcurvelen);
	sig = SinOsc.ar(pitch);

	// Apply low-pass filter and reverb
	sig = LPF.ar(sig, 500) * env * 10;
	f = JPverb.ar(sig, 5, 0, 1, 0, 0);

	sig = Pan2.ar((sig + (f * 0.5)), FSinOsc.kr(2), 0.3);
	Out.ar(out, sig);
}).add
)

// Define Sea Gull Synth
(
SynthDef.new(\gullGenerator, {

	arg out = 0, t_trig = 0, freq=800, amp = 1, attack=0.5, decay=2, doneAction = 2;
	var sig, env, env_effect, lfo, temp, vibrato;


	lfo = XLine.ar(3, 30);

	vibrato = Vibrato.ar(100, 6, 0.8);
	env = EnvGen.ar(Env.perc(attack, decay), t_trig, doneAction: 0) * amp;
	env_effect = EnvGen.ar(Env.perc((attack * 2), (decay * 2)), t_trig, doneAction: doneAction) * amp;

	// Resonant Filter
	sig = Formant.ar(XLine.kr(freq, 600, 0.5), XLine.kr(2000, 1400, 0.5), XLine.kr(1000, 700, 0.5), mul: 0.6)!2 + Formant.ar(XLine.kr(330, 150, 0.5), 805, 880, mul: 0.25)!2 + Saw.ar(XLine.ar(330, 300, 0.5), mul: XLine.kr(0.2, 0, 0.5));

	// Apply LFO and Envelope
	sig = 0.5 * env * sig;

	// Echo + Reverb
	e = Greyhole.ar(sig, 5, 0.1, 0.2, feedback: 0.8, modDepth: 1, modFreq: 10);
	f = FreeVerb.ar(sig, 0.33, 0.8, 0.3, 0.25);

	sig = sig + (0.25 * f * env) + (0.25 * e * env);

	Out.ar(out, sig);
}).add;
)

// Define Wave Synth
(
SynthDef.new(\waveGenerator,{

	arg out = 0, t_trig=0, attack = 3, decay = 2;
	var sig, env;

	env = EnvGen.ar(Env.perc(attack, decay), t_trig, doneAction: 2);

	// Mix Pink and Brown Noise for Wave Signal
	sig = PinkNoise.ar(1)!2 * 0.75 + BrownNoise.ar(EnvGen.kr(Env.new([0.2, 1, 0], [attack, decay], [1, -1]), doneAction: 2)) * 0.25;

	f = JPverb.ar(sig, 5, 0, 1, 0, 0);

	// Apply Envelope
	sig = 0.5 * sig * env + (f * 0.2);

	sig = sig * 0.1;
	Out.ar(out, sig);
}).add;
)

// Scene
(
var w_synth, b_synth, g_synth;

b_synth = Synth(\bubbleGenerator);
g_synth = Synth(\gullGenerator);
w_synth = Synth(\waveGenerator);

// Play the bubbles
b = Pbind(
	\instrument, \bubbleGenerator,
	\sizefactor, Pwhite(0.0,1,inf),
	\dur, Pgauss(0.3, 0.2),
	\freq,  Pkey(\sizefactor).linexp(0, 1, 1000, 3000),
	\amp ,  Pkey(\sizefactor).linlin(0, 1, 0.15, 0.04),
	\decay, Pkey(\sizefactor).linlin(0, 1, 0.05, 0.08),
	\doneAction, 2
).play;

// Play the sea gulls
g = Pbind(
	\instrument, \gullGenerator,
	\sizefactor, Pwhite(0.0,1,inf),
	\dur, Pgauss(5, 10),
	\freq,  Pkey(\sizefactor).linexp(0, 1, 600, 800),
	\amp ,  Pkey(\sizefactor).linexp(0, 1, 0.05, 0.2),
	\decay, Pkey(\sizefactor).linlin(0, 1, 0.5, 1),
	\doneAction, 2
).play;

// Play the waves
w = Pbind(
	\instrument, \waveGenerator,
	\sizefactor, Pwhite(0.0,1,inf),
	\dur, Pgauss(1, 3),
	\freq,  Pkey(\sizefactor).linexp(0, 1, 1000, 3000),
	\amp ,  Pkey(\sizefactor).linlin(0, 1, 0.15, 0.04),
	\decay, Pkey(\sizefactor).linlin(0, 1, 1, 4),
	\doneAction, 2
).play;
)

// Stop everything
(
b.stop;
g.stop;
w.stop;
)