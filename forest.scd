/*
 *    __                     _
 *  / _| ___  _ __ ___  ___| |_
 *  | |_ / _ \| '__/ _ \/ __| __|
 *  |  _| (_) | | |  __/\__ \ |_
 *  |_|  \___/|_|  \___||___/\__|
 *
 *
 *  #+METHOD: Simulation as in `SimCity for Nature`
 *  #+AUTHOR: K E N O
 *  #+TITLE: Forest
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

// Define woodpecker synth
(
SynthDef(\woodpeckerGenerator, {

	arg out = 0, t_trig = 0, dur = 1,  amp = 1, attack = 1, decay = 1, doneAction = 2;
    var env, sig;

	env = amp * EnvGen.ar(Env.perc(attack, decay), t_trig, doneAction: doneAction);

    sig = SinOsc.ar(Env([1000, 20, 20], [0.015, 0.1], \exp).ar * [-0.1, 0, 0.1].midiratio);
    sig = BPeakEQ.ar(sig, XLine.kr(1000, 100, 0.1), 1.0, 10);
    sig = HPF.ar(sig, 800, 0.7);
	sig = sig * env;
	sig = sig * 10;

    Out.ar(out, sig);
}).add;
)

// Define owl synth
(
SynthDef(\owlGenerator, {

	arg t_trig = 0, dur, amp = 1, attack = 0.1, decay = 0.5, freq = 400, out = 0, doneAction = 2;
	var env, sig;

	env = EnvGen.kr(Env.new([0, 0.8, 1, 0], [0, 0.4, 0.1, 0.1]), doneAction: doneAction);

	a = LFNoise2.kr(2)**0.33;
	e = EnvGen.kr(Env.new([0, 0.2, 0], [0, 0.2, 0.4]));
	sig = SinOsc.ar(320) + Formant.ar(320, 320, 320);
	sig = BPeakEQ.ar(sig, 320, 1.0, 10);
	sig = sig.dup * env * 0.2;
	sig = sig * 0.05;
	sig = sig * amp;

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

// Define effect consisting of reverb and echo
(
SynthDef(\hallGenerator, {

	arg in = 3, out = 0;
	var effect, sig;

	sig = In.ar(in);
	sig = sig;
	effect = FreeVerb.ar(sig, 0.3, 0.5, 0.8);
	effect = Greyhole.ar(effect, 2, 0.2, diff: 0.8, feedback: 0.4);

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
var h_fx,
    amp_o = 1, amp_p = 1,
    dur_o, dur_p;

h_fx = Synth.new(\hallGenerator, [\input, 3]);

// Play the owl
o = Pbind(*[
	\instrument, \owlGenerator,
	\sizefactor, Pwhite(0.0,1,inf),
	\delta, 10,
	\out, 3,
	//\dur, Pfuncn({ dur_o }, inf),
	\amp , Pfuncn({ amp_o }, inf),
	\freq, Pkey(\sizefactor).linexp(0, 1, 200, 300),
	\decay, Pkey(\sizefactor).linlin(0, 1, 1, 2),
	\doneAction, 2
]).play;

// Play the woodpecker
p = Pbind(*[
	\instrument, \woodpeckerGenerator,
	\sizefactor, Pwhite(0.0,1,inf),
	\out, 0,
	\amp, Pfuncn({ amp_p }, inf),
	//\dur, Pfuncn({ dur_p }, inf),
	\freq, Pkey(\sizefactor).linexp(0, 1, 50, 100),
	\amp , Pkey(\sizefactor).linlin(0, 1, 0.10, 0.04),
	\decay, Pkey(\sizefactor).linlin(0, 1, 0.01, 0.1)
]).play;

// Control the volume of the owls
MIDIdef.cc(\amp_o, { |val, num, chan, src|
	[val, num].postln;
	amp_o = val.linlin(0, 127, 0, 1);
	amp_o.postln;
}, 3);

// Control the volume of the woodpecker
MIDIdef.cc(\amp_p, { |val, num, chan, src|
	[val, num].postln;
	amp_p = val.linlin(0, 127, 0, 1);
	amp_p.postln;
}, 4);

// Control the duration of the owls
MIDIdef.cc(\dur_o, { |val, num, chan, src|
	[val, num].postln;
	dur_o = val.linlin(0, 127, 0, 1);
	dur_o.postln;
}, 19);

// Control the duration of the woodpecker
MIDIdef.cc(\dur_p, { |val, num, chan, src|
	[val, num].postln;
	dur_p = val.linlin(0, 127, 0, 1);
	dur_p.postln;
}, 20);
)

(
o.stop;
p.stop;
)