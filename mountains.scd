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

    arg out = 0, amp = 1, cutoff = 1000;
	var sig, env;

	//env =
	sig = SinOsc.ar(0.5) * WhiteNoise.ar();

	Out.ar(out, sig);

}).add
)

// Define sheep synth
(
SynthDef(\sheepGenerator, {

	arg out = 0, amp = 1, dur = 0.5, doneAction = 2, t_trig = 0;
	var sig, env;

	env = EnvGen.kr(Env.perc(dur/2, dur/2).delay(0.003), t_trig, doneAction: doneAction);

	sig = SinOsc.ar(Vibrato.ar(DC.ar(400.0), 15, 0.2));
	sig = sig * env;
	sig = amp * sig.dup;

	Out.ar(out, sig);

}).add
)

// Define eagle synth
(
SynthDef(\eagleGenerator, {

	arg out = 0, t_trig = 0, amp = 1, dur = 1, doneAction = 2;
	var sig = 0, env;

	5.do({

		arg item, i;
		sig = sig + (Formant.ar(EnvGen.kr(Env([item * 500, item * 750, item * 625], [0.5, 0.5, 0.5])))* 0.2);

	});

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

r = Synth.new(\riverGenerator);

// Play the eagle
e = Pbind(*[
	\instrument, \eagleGenerator,
	\sizefactor, Pwhite(0.0,1,inf),
	\out, 0,
	\dur , Pgauss(Pfuncn({ dur_e }, inf), Pfuncn({ dur_e }, inf) - 0.1),
    \amp, Pfuncn({ amp_e }, inf),
	\doneAction, 2
]).play;

// Play the sheep
s = Pbind(*[
	\instrument, \sheepGenerator,
	\sizefactor, Pwhite(0.0,1,inf),
	\dur , Pgauss(Pfuncn({ dur_s }, inf), Pfuncn({ dur_s }, inf) - 0.1),
    \amp, Pfuncn({ amp_s }, inf),
	\out, 0,
	\doneAction, 2
]).play;

// Control the volume of the eagles
MIDIdef.cc(\amp_e, { |val, num, chan, src|
	[val, num].postln;
	amp_e = val.linlin(0, 127, 0, 1);
	amp_e.postln;
}, 5);

// Control the duration of the eagles
MIDIdef.cc(\dur_e, { |val, num, chan, src|
	[val, num].postln;
	dur_e = val.linlin(0, 127, 0.5, 1.5);
}, 21);

// Control the volume of the sheep
MIDIdef.cc(\amp_s, { |val, num, chan, src|
	[val, num].postln;
	amp_s = val.linlin(0, 127, 0, 1);
	amp_s.postln;
}, 6);

// Control the duration of the sheep
MIDIdef.cc(\dur_s, { |val, num, chan, src|
	[val, num].postln;
	dur_s = val.linlin(0, 127, 0.5, 0.8);
}, 22);
)

// Stop the mountains
(
e.stop;
)