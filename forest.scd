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

// Define real own buffer
(
~realDuck = Buffer.read(Server.default, ".../samples/".resolveRelative ++ "duck.wav");
~realOwl = Buffer.read(Server.default, ".../samples/".resolveRelative ++ "owl.wav");
)

// Define woodpecker synth
(
SynthDef(\woodpeckerGenerator, {

	arg out = 0, t_trig = 0, dur = 0.25,  amp = 1, attack = 0.1, decay = 0.1, doneAction = 2;
    var env, sig;

	env = amp * EnvGen.ar(Env.perc(attack, decay), t_trig, doneAction: doneAction);

    sig = SinOsc.ar(Env([1000, 20, 20], [dur * 0.015, dur * 0.01], \lin).ar * [-0.1, 0, 0.1].midiratio);
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

	arg t_trig = 0, dur = 1, amp = 1, attack = 0.1, decay = 0.5, freq = 400, out = 0, doneAction = 2;
	var env, sig;

	env = EnvGen.kr(Env.new([0, 0.8, 1, 0], [0, dur * 0.4, dur * 0.1, dur * 0.1]), doneAction: doneAction);

	a = LFNoise2.kr(2)**0.33;
	e = EnvGen.kr(Env.new([0, 0.2, 0], [0, 0.2, 0.4]));
	5.collect({
		|i|
		sig = Formant.ar(Vibrato.ar(i * 80, 3, 0.015), XLine.ar(320, 100, 0, dur), 320);
	});
	sig = BPeakEQ.ar(sig, 320, 0.1, 2);
	sig = sig.dup * env * 0.2;
	sig = sig * 0.5;
	sig = sig * amp;

	Out.ar(out, sig);

}).add;
)

// Define real owl synth
(
SynthDef(\realOwlGenerator, {

	arg amp = 1, out = 0, buf, doneAction = 2;
	var sig;

	sig= PlayBuf.ar(1, buf, doneAction: doneAction);
	sig = sig * amp;
	sig = sig!4;

	Out.ar(out, sig);

}).add;
)

// Define buffer player synth
(
SynthDef(\bufPlaySynth, {

	arg amp = 1, out = 0, buf, doneAction = 2;
	var sig;

	sig= PlayBuf.ar(1, buf, doneAction: doneAction);
	sig = sig * amp;
	sig = sig!4;

	Out.ar(out, sig);

}).add;
)

// Define rain synth
(
SynthDef(\rainGenerator, {

	| amp = 0.5, out = 0 |
	var gaus, sig;
	gaus = {PinkNoise.ar}.dup(12).sum;
	gaus = LPF.ar(BPF.ar(gaus, 100, 1/0.4), 500);

	sig = SinOsc.ar(gaus.linlin(-1, 1, 40, 80)) * gaus.squared * 10;
	sig = (sig - 0.35).max(0);

	sig = HPF.ar(sig, 800);

	sig = sig.dup;
	sig = sig * amp;

	Out.ar(out, sig);

}).add;
)

// Define cricket synth
(
SynthDef(\cricketSynth, {

	| amp, out = 0 |
	var trig, seq, demand, sig;

	trig = Impulse.kr(58.82);

	seq = Dseq(Array.fill(41, {|i| if(i<7, {(i+2)/9},{0}) }),inf);
	demand = Demand.kr(trig,0,seq);

	sig = EnvGen.ar(Env.new([0, 1, 0], [4/44100, 0]), trig) * demand;


	sig = OnePole.ar(sig, exp(-2pi * (1000 * SampleDur.ir)));
	sig = (
			BPF.ar(sig, 4500 + ((0..2)*50), 300.reciprocal, 100)).sum
			+ BPF.ar(sig, 9000, 500.reciprocal, 42
	);
	sig = ((sig - OnePole.ar(sig, exp(-2pi * (4000 * SampleDur.ir)))) * 0.5)!2;

	Out.ar(out, sig);

}).add;
)

//Define frog synth
(
SynthDef(\frogSynth, {

	| amp = 1, out = 0 |
	var sig, env;

	sig = Impulse.ar(440) * amp;

	Out.ar(out, sig);

}).add;
)

Synth.new(\frogSynth);


// Define duck synth
(
SynthDef(\duckSynth, {

	| amp, out = 0 |
	var sig, env;

	sig = SinOsc.ar(440);

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

	arg in = 5, out = 0;
	var effect, sig;

	sig = In.ar(in);
	sig = sig;
	effect = FreeVerb.ar(sig, 0.3, 0.5, 0.8);
	effect = Greyhole.ar(effect, 2, 0.2, diff: 0.8, feedback: 0.4);
	effect = effect!4;

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
var p1, p2, p3,
    h_fx,
    amp_o = 1, amp_p = 1, amp_r = 1,
    dur_o = 1, dur_p = 1, dur_r = 1;

h_fx = Synth.new(\hallGenerator, [\input, 5]);

// Play the owl
o = Pbind(*[
	\instrument, \owlGenerator,
	\sizefactor, Pwhite(0.0,1,inf),
	\delta, 10,
	\out, 5,
	\amp , Pfuncn({ amp_o }, inf),
	\dur, Pfuncn({ dur_o }, inf),
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
	\dur, Pgauss(0.05, 0.05, inf),
	\freq, Pkey(\sizefactor).linexp(0, 1, 50, 100),
	\decay, Pkey(\sizefactor).linlin(0, 1, 0, 1),
	\doneAction, 2,
]).play;

// Play the river
r = Synth.new(\rainGenerator);

// Trigger real owl by playing MIDI note
MIDIdef.noteOn(\triggerRealOwl, {
	arg vel, nn, chan, src;
	[vel, nn, chan, src].postln;
	Synth.new(\bufPlaySynth, [\buf, ~realOwl.bufnum]);
});

// Triger real duck by playing MIDI note
MIDIdef.noteOn(\triggerRealDuck, {
	arg vel, nn, chan, src;
	[vel, nn, chan, src].postln;
	Synth.new(\bufPlaySynth, [\buf, ~realDuck.bufnum]);
});

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
	dur_o = val.linlin(0, 127, 0.5, 1.5);
}, 19);

// Control the duration of the woodpecker
MIDIdef.cc(\dur_p, { |val, num, chan, src|
	[val, num].postln;
	dur_p = val.linlin(0, 127, 0.25, 1.25);
}, 20);
)

// Stop the forest
(
o.stop;
p.stop;
)