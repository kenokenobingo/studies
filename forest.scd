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

// Define woodpecker synth
(
SynthDef(\woodpeckerGenerator, {

	arg t_trig = 0, attack = 0, decay = 0;
    var env, sig;

	env = EnvGen.ar(Env.perc(attack, decay), t_trig, doneAction: 2);

    sig = SinOsc.ar(Env([1000, 20, 20], [0.015, 0.1], \exp).ar * [-0.1, 0, 0.1].midiratio);
    sig = Mix(sig);
    sig = BPeakEQ.ar(sig, XLine.kr(1000, 100, 0.1), 1.0, 10);
    sig = sig + DelayC.ar(sig, 0.2, SinOsc.ar(2).range(0.0, 0.001));
    sig = HPF.ar(sig, 800, 0.7);
	sig = sig * env;
    sig = (sig * 0.6).clip(-1, 1);

    Out.ar(\out.kr(0), Pan2.ar(sig, \pan.kr(0), \amp.kr(0.1)));
}).add;
)

// Define owl synth
(
SynthDef(\owlGenerator, {

	arg t_trig = 0, dur = 1, attack = 0.1, decay = 0.5, freq = 400, out = 0, doneAction = 2;
	var env, sig;

	env = EnvGen.kr(Env.new([0, 0.8, 1, 0], [0, 0.4, 0.1, 0.1]), doneAction: 0);

	a = LFNoise2.kr(2)**0.33;
	e = EnvGen.kr(Env.new([0, 0.2, 0], [0, 0.2, 0.4]));
	sig = SinOsc.ar(320) + Formant.ar(320, 320, 320);
	sig = BPeakEQ.ar(sig, 320, 1.0, 10);
	sig = sig.dup * env * 0.2;
	sig = Greyhole.ar(sig, 20);

	Out.ar(out, sig);
}).add;
)

(
var o_synth, w_synth;

o_synth = Synth(\owlGenerator);
//w_synth = Synth(\woodpeckerGenerator);

o = Pbind(
	\instrument, \owlGenerator,
	\sizefactor, Pwhite(0.0,1,inf),
	\delta, 3,
	\dur, Pkey(\sizefactor).linlin(0, 1, 1, 1.5),
	\freq, Pkey(\sizefactor).linexp(0, 1, 200, 300),
	\amp , Pkey(\sizefactor).linlin(0, 1, 0.10, 0.04),
	\decay, Pkey(\sizefactor).linlin(0, 1, 1, 2),
	\doneAction, 2
).play;

// Play the woodpecker
/*w = Pbind(
	\instrument, \woodpeckerGenerator,
	\sizefactor, Pwhite(0.0,1,inf),
	\dur, Pseq([0.05, 0.05, 0.05, 0, 0, 0], inf, 10),
	\freq, Pkey(\sizefactor).linexp(0, 1, 50, 100),
	\amp , Pkey(\sizefactor).linlin(0, 1, 0.10, 0.04),
	\decay, Pkey(\sizefactor).linlin(0, 1, 0.01, 0.1),
	\doneAction, 2
).play;*/
)

// Stop everything
(
o.stop;
w.stop;
)

