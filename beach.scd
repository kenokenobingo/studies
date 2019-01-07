/*
 *   _                     _
 *  | |__   ___  __ _  ___| |__
 *  | '_ \ / _ \/ _` |/ __| '_ \
 *  | |_) |  __/ (_| | (__| | | |
 *  |_.__/ \___|\__,_|\___|_| |_|
 *
 *
 *  #+METHOD: Simulation as in `SimCity for Nature`
 *  #+AUTHOR: K E N O
 *  #+TITLE: At the beach (Tag am Meer)
 *  #+TOOL: SuperCollider
 *
 */


/************************************************************
 *   _           _                                   _
 *  (_)_ __  ___| |_ _ __ _   _ _ __ ___   ___ _ __ | |_ ___
 *  | | '_ \/ __| __| '__| | | | '_ ` _ \ / _ \ '_ \| __/ __|
 *  | | | | \__ \ |_| |  | |_| | | | | | |  __/ | | | |_\__ \
 *  |_|_| |_|___/\__|_|   \__,_|_| |_| |_|\___|_| |_|\__|___/
 *
 ************************************************************/

// Define bubble synth
(
SynthDef(\bubbleGenerator, {

	arg out=0, t_trig=0, attack=0.01, decay=0.08, freq=400, amp=0.1, pitchcurvelen=0.1, doneAction=2;
	var env, pitch, sig;

	env = amp * EnvGen.ar(Env.perc(attack, decay).delay(0.003), t_trig, doneAction: doneAction);
	pitch = freq * EnvGen.ar(Env.new([0,0,1],[0,1]).exprange(1, 2.718), t_trig, timeScale: pitchcurvelen);
	sig = SinOsc.ar(pitch);

	// Apply low-pass filter to the signal
	sig = LPF.ar(sig, 500) * env * 0.35;

	Out.ar(out, sig);

}).add
)

// Define sea gull synth
(
SynthDef.new(\gullGenerator, {

	arg out = 3, t_trig = 0, freq=900, amp = 1, attack = 0.5, decay = 2, dur = 0.5, doneAction = 2;
	var env, env_effect, lfo, sig, temp, vibrato;

	lfo = XLine.ar(3, 30);

	vibrato = Vibrato.ar(100, 6, 0.8);
	env = EnvGen.ar(Env.perc(attack, decay), t_trig, doneAction: doneAction) * amp;

	// Resonant filter
	sig = Formant.ar(XLine.kr(freq, 600, 0.5), XLine.kr(3000, 1400, 0.5), XLine.kr(freq * 2, 700, 0.5), mul: 0.6)!2 + Formant.ar(XLine.kr(freq / 2, 150, 0.5), 805, 880, mul: 0.25)!2 + Saw.ar(XLine.ar(freq / 2, 300, 0.5), mul: XLine.kr(0.2, 0, 0.2));

	// Apply LFO and envelope
	sig = 0.1 * env * sig;

	Out.ar(out, sig);

}).add;
)

// Define wave synth
(
SynthDef.new(\waveGenerator,{

	arg out = 0, t_trig = 0, attack = 3, decay = 2, amp = 0.5, freqfactor = 0.75, doneAction = 2;
	var sig, env;

	env = EnvGen.ar(Env.perc(attack, decay), t_trig, doneAction: doneAction);

	// Mix pink and brown noise for wave signal
	sig = (PinkNoise.ar(1)!2 * freqfactor) + (BrownNoise.ar(EnvGen.kr(Env.new([0.2, 1, 0], [attack, decay], [1, -1])))!2 * (1 - freqfactor));

	// apply envelope
	sig = amp * sig * env;

	sig = sig * 0.3;
	Out.ar(out, sig);

}).add;
)


/**********************************
 *        __  __           _
 *   ___ / _|/ _| ___  ___| |_ ___
 *  / _ \ |_| |_ / _ \/ __| __/ __|
 * |  __/  _|  _|  __/ (__| |_\__ \
 *  \___|_| |_|  \___|\___|\__|___/
 *
 **********************************/

(
SynthDef(\echoGenerator, {

	arg in = 2, out = 0, delay_time = 2;
	var effect, sig;

	sig = In.ar(in);
	effect = Greyhole.ar(sig, delay_time, 0.1, 0.2, 0.8, feedback: 0.3);

	Out.ar(out, effect);

}).add;
)

(
SynthDef(\reverbGenerator, {

	arg in = 4, out = 2;
	var effect, sig;

	sig = In.ar(in);
	effect = FreeVerb.ar(sig, 0.33, 0.8, 0.3, 0.25);

	Out.ar(out, effect);

}).add;
)

(
SynthDef(\complexReverbGenerator, {

	arg in = 6, out = 0, ratio = 0.75;
	var effect, sig;

	sig = In.ar(in);
	effect = JPverb.ar(sig, 5, 0, 1, 0, 0);
	effect = (sig * ratio) + (effect * (1 - ratio));
	effect = effect * 0.5;

	Out.ar(out, effect);
}).add;
)


/****************************
 *   ___  ___ ___ _ __   ___
 *  / __|/ __/ _ \ '_ \ / _ \
 *  \__ \ (_|  __/ | | |  __/
 *  |___/\___\___|_| |_|\___|
 *
 ****************************/

(
var c_fx, e_fx, r_fx,
    amp_b = 1, amp_g = 1, amp_w = 1,
    dur_b = 0.5, dur_g = 1.5, dur_w = 3;

c_fx = Synth.new(\complexReverbGenerator, [\input, 6,]);
e_fx = Synth.new(\echoGenerator, [\input, 4]);
r_fx = Synth.new(\reverbGenerator, [\input, 2]);

// Play the bubbles
b = Pbind(*[
	\instrument, \bubbleGenerator,
	\sizefactor, Pwhite(0.0,1,inf),
	\dur , Pgauss(Pfuncn({ dur_b }, inf), Pfuncn({ dur_b }, inf) - 0.2),
	\out, 6,
	\freq, Pkey(\sizefactor).linexp(0, 1, 100, 600),
	\amp , Pkey(\sizefactor).linlin(0, 1, 0.10, 0.04),
	\amp, Pfuncn({ amp_b }, inf),
	\decay, Pkey(\sizefactor).linlin(0, 1, 0.05, 0.08),
	\pitchcurvelen, Pkey(\sizefactor).linlin(0, 1, 0.05, 0.2),
	\doneAction, 2
]).play;

// Play the sea gulls
g = Pbind(*[
	\instrument, \gullGenerator,
	\sizefactor, Pwhite(0.0,1,inf),
	\out, 4,
	\dur , Pgauss(Pfuncn({ dur_g }, inf), Pfuncn({ dur_g }, inf) - 0.1),
    \freq, Pkey(\sizefactor).linexp(0, 1, 600, 800),
    \amp, Pfuncn({ amp_g }, inf),
    \attack, Pkey(\sizefactor).linexp(0, 1, 0.2, 0.5),
    \decay, Pkey(\sizefactor).linlin(0, 1, 0.3, 0.7),
	\doneAction, 2
]).play;

// Play the waves
w = Pbind(*[
	\instrument, \waveGenerator,
	\sizefactor, Pwhite(0.0,1,inf),
	\out, 4,
	//\dur, Pgauss(2, 5),
	\dur, Pgauss(Pfuncn({ dur_w }, inf), Pfuncn({ dur_w }, inf) -1),
	\amp , Pfuncn({ amp_w }, inf),
	\decay, Pkey(\sizefactor).linlin(0, 1, 2, 5),
	\freqfactor, Pkey(\sizefactor).linlin(0, 1, 0.1, 0.9),
	\doneAction, 2
]).play;

// Control the volume of the bubbles
MIDIdef.cc(\amp_b, { |val, num, chan, src|
	[val, num].postln;
	amp_b = val.linlin(0, 127, 0, 1);
	amp_b.postln;
}, 0);

// Control the volume of the gulls
MIDIdef.cc(\amp_g, { |val, num, chan, src|
	[val, num].postln;
	amp_g = val.linlin(0, 127, 0, 1);
	amp_g.postln;
}, 1);

// Control the volume of the waves
MIDIdef.cc(\amp_w, { |val, num, chan, src|
	[val, num].postln;
    amp_w = val.linlin(0, 127, 0, 1);
	amp_w.postln;
}, 2);

// Control the duration of the bubbles
MIDIdef.cc(\dur_b, { |val, num, chan, src|
	[val, num].postln;
	dur_b = val.linlin(0, 127, 0.3, 0.5);
}, 16);

// Control the duration of the gulls
MIDIdef.cc(\dur_g, { |val, num, chan, src|
	[val, num].postln;
	dur_g = val.linlin(0, 127, 0.5, 3);
}, 17);

// Control the volume of the waves
MIDIdef.cc(\dur_w, { |val, num, chan, src|
	[val, num].postln;
	dur_w = val.linlin(0, 127, 2, 8);
}, 18);
)

(
b.stop; g.stop; w.stop;
)