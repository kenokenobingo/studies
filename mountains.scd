/*
 *                               _        _
 *   _ __ ___   ___  _   _ _ __ | |_ __ _(_)_ __  ___
 *  | '_ ` _ \ / _ \| | | | '_ \| __/ _` | | '_ \/ __|
 *  | | | | | | (_) | |_| | | | | || (_| | | | | \__ \
 *  |_| |_| |_|\___/ \__,_|_| |_|\__\__,_|_|_| |_|___/
 *
 *
 *  #+METHOD: Simulation as in `SimCity for Nature`
 *  #+AUTHOR: K E N O
 *  #+TITLE: In the mountains
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

// Define river synth
(
SynthDef(\riverGenerator, {

    | out = 0, amp = 1, cutoff = 1000 |
	var sig, env;

	env = SinOsc.ar(0.02);
	sig = env * OnePole.ar(WhiteNoise.ar(), 0.95);
	sig = sig * amp;

	Out.ar(out, sig);

}).add
)

// Define sheep synth
(
SynthDef(\sheepGenerator, {

	| out = 0, amp = 1, dur = 4, doneAction = 2, t_trig = 0 |
	var sig = 0, env;

	env = EnvGen.kr(Env.perc(dur/2, dur/2).delay(0.003), t_trig, doneAction: doneAction);

	sig = 5.collect({
		arg i;

		sig = sig + Formant.ar(i * 125, XLine.ar(125, 200, 0.5), XLine.ar(125, 200, 0.5), mul: XLine.ar(1, 0.1, 0.5)) + Formant.ar(Vibrato.ar(DC.ar(i * 125), XLine.ar(10, 20, 1), 0.02), XLine.ar(700, 1500, 0, 1), 2500, mul: XLine.ar(0.1, 1, 0.5)) * (1/(i+1));
	});

	sig = BPF.ar(sig, 800, 0.9);
	sig = sig * env;
	sig = amp * sig.dup;

	Out.ar(out, sig);

}).add
)

// Define eagle synth
(
SynthDef(\eagleGenerator, {

	| out = 0, t_trig = 0, amp = 1, dur = 1, doneAction = 2 |
	var sig = 0, env;

	5.collect({

		arg i;
		sig = sig + (Formant.ar(EnvGen.kr(Env([i * 500, i * 750, i * 625], [0.5, 0.5, 0.5])))* 0.2);

	});

	BPF.ar(sig, 800);

	env = EnvGen.kr(Env.perc(dur/2, dur/2).delay(0.003), t_trig, doneAction: doneAction);
	sig = sig * env * 0.5;
	sig = sig.dup * amp;

	Out.ar(out, sig);

}).add
)


/****************************
 *   ___  ___ ___ _ __   ___
 *  / __|/ __/ _ \ '_ \ / _ \
 *  \__ \ (_|  __/ | | |  __/
 *  |___/\___\___|_| |_|\___|
 *
 ****************************/

(
var amp_e = 1, amp_s = 1,
    dur_e = 1, dur_s = 0.5;

// Play the river
~river = Synth.new(\riverGenerator);

// Play the eagle
~eagle = Pbind(*[

	\instrument, \eagleGenerator,
	\out, 0,
	\sizefactor, Pwhite(0.0,1,inf),
	\dur , Pgauss(Pfuncn({ dur_e }, inf), Pfuncn({ dur_e }, inf) - 0.1),
    \amp, Pfuncn({ amp_e }, inf),
	\doneAction, 2

]).play;

// Play the sheep
~sheep = Pbind(*[

	\instrument, \sheepGenerator,
	\out, 0,
	\sizefactor, Pwhite(0.0,1,inf),
	\dur , Pgauss(Pfuncn({ dur_s }, inf), Pfuncn({ dur_s }, inf) - 0.1),
    \amp, Pfuncn({ amp_s }, inf),
	\doneAction, 2

]).play;

// Control the volume of the eagles
MIDIdef.cc(\amp_e, {

	|val, num, chan, src|

	[val, num].postln;
	amp_e = val.linlin(0, 127, 0, 1);

}, 0);

MIDIdef.cc(\amp_r, {

	| val, num, chan, src |
	var amp_r;

	[val, num].postln;
	amp_r = val.linlin(0 ,127, 0, 1);
	~river.set(\amp, amp_r);

}, 1);

// Control the volume of the sheep
MIDIdef.cc(\amp_s, {

	|val, num, chan, src|

	[val, num].postln;
	amp_s = val.linlin(0, 127, 0, 1);

}, 2);

// Control the duration of the eagles
MIDIdef.cc(\dur_e, {

	|val, num, chan, src|

	[val, num].postln;
	dur_e = val.linlin(0, 127, 0.5, 1.5);

}, 16);

// Control the duration of the sheep
MIDIdef.cc(\dur_s, {

	|val, num, chan, src|

	[val, num].postln;
	dur_s = val.linlin(0, 127, 1, 2);

}, 18);
)

// Stop the mountains
(
~eagle.stop;
~river.free;
~sheep.stop;
)