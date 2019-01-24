/*
 *                               _        _
 *   _ __ ___   ___  _   _ _ __ | |_ __ _(_)_ __  ___
 *  | '_ ` _ \ / _ \| | | | '_ \| __/ _` | | '_ \/ __|
 *  | | | | | | (_) | |_| | | | | || (_| | | | | \__ \
 *  |_| |_| |_|\___/ \__,_|_| |_|\__\__,_|_|_| |_|___/
 *
 *
 *  #+METHOD: Simulation
 *  #+AUTHOR: K E N O
 *  #+TITLE: In the mountains
 *  #+TOOL: SuperCollider
 *
 */


/**********************************
 *   _
 *  | |__  _   _ ___ ___  ___  ___
 *  | '_ \| | | / __/ __|/ _ \/ __|
 *  | |_) | |_| \__ \__ \  __/\__ \
 *  |_.__/ \__,_|___/___/\___||___/
 *
***********************************/

(
// Effects In
~mountainEagleFx = Bus.audio(s, 1);
~mountainRiverFx = Bus.audio(s, 1);
~mountainSheepFx = Bus.audio(s, 1);

// Ambisonics Encode + Transform In
~mountainRiverAmbi = Bus.audio(s, 1);
~mountainSheepAmbi = Bus.audio(s, 1);
~mountainEagleAmbi = Bus.audio(s, 2);
)


/************************************************************
 *   _           _                                   _
 *  (_)_ __  ___| |_ _ __ _   _ _ __ ___   ___ _ __ | |_ ___
 *  | | '_ \/ __| __| '__| | | | '_ ` _ \ / _ \ '_ \| __/ __|
 *  | | | | \__ \ |_| |  | |_| | | | | | |  __/ | | | |_\__ \
 *  |_|_| |_|___/\__|_|   \__,_|_| |_| |_|\___|_| |_|\__|___/
 *
 ************************************************************/

// Define buffers
(
~realDuck = Buffer.read(Server.default, "samples/".resolveRelative ++ "duck.wav");
~realOwl = Buffer.read(Server.default, "samples/".resolveRelative ++ "owl.wav");
)

// Define eagle synth
(
SynthDef(\eagleGenerator, {

	| out = 0, t_trig = 0, amp = 0.2, dur = 1, doneAction = 2 |
	var sig = 0, env;

	5.collect({

		| i |
		sig = sig * 0.7 + ((Formant.ar(EnvGen.kr(Env([i * 500, i * 750, i * 625], [0.5, 0.5, 0.3])))* 0.2) * i);

	});

	sig = BPF.ar(sig, 1000);

	env = EnvGen.kr(Env.perc(dur/8, dur/12).delay(0.003), t_trig, doneAction: doneAction);
	sig = sig * env * 0.5;
	sig = sig * amp;

	Out.ar(out, sig);

}).add;
)

// Define river synth
(
SynthDef(\riverGenerator, {

    | out = 0, amp = 0.2, cutoff = 1000 |
	var sig, env;

	env = SinOsc.ar(0.02) * 0.5;
	sig = env * OnePole.ar(WhiteNoise.ar(), 0.95);
	sig = sig * amp;

	Out.ar(out, sig);

}).add;
)

// Define sheep synth
(
SynthDef(\sheepGenerator, {

	| out = 0, amp = 1, dur = 1, doneAction = 2, t_trig = 0 |
	var sig = 0, env;

	env = EnvGen.kr(Env.perc(dur/2, dur/2).delay(0.003), t_trig, doneAction: doneAction);

	sig = sig + Formant.ar(125, XLine.ar(125, 200, 0.5), XLine.ar(125, 200, 0.5), mul: XLine.ar(1, 0.1, 0.5)) + Formant.ar(Vibrato.ar(DC.ar(125), XLine.ar(10, 20, 1), XLine.ar(0.02, 0.1, 1)), XLine.ar(700, 1500, 0, 1), 2500, mul: XLine.ar(0.1, 1, 0.5));

	sig = BPF.ar(sig, 750, 0.9);
	sig = sig * env;
	sig = amp * sig;

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

// Define mountain echo
(
SynthDef(\mountainEchoGenerator, {

	| in, out |
	var effect, sig;

	sig = In.ar(in);
	effect = JPverb.ar(sig, 5);
	effect = Greyhole.ar(effect, 5, feedback: 0.7);

	Out.ar(out, effect);

}).add;
)

// Define mountain reverb
(
SynthDef(\mountainReverbGenerator, {

	| in, out |
	var effect, sig;

	sig = In.ar(in);
	effect = FreeVerb.ar(sig, 0.2, 0.8);
	effect = effect * 2;

	Out.ar(out, effect);

}).add;
)

/************************************************************
 *
 *   ___ _ __   __ _  ___ ___
 *  / __| '_ \ / _` |/ __/ _ \
 *  \__ \ |_) | (_| | (_|  __/
 *  |___/ .__/ \__,_|\___\___|
 *      |_|
 *
 ************************************************************/

(
SynthDef(\eagleSpace, {

	| in, out |
	var sig;

	sig = In.ar(in, 2);

	// Encode
	sig = FoaEncode.ar(sig, FoaEncoderMatrix.newStereo);
	// Transform
	sig = FoaZoom.ar(sig, 0, 0, 0);

	Out.ar(out, sig);

}).add;
)

(
SynthDef(\riverSpace, {

	| in, out |
	var sig;

	sig = In.ar(in);

	// Encode
	sig = FoaEncode.ar(sig, FoaEncoderMatrix.newOmni);
	// Transform
	sig = FoaZoom.ar(sig, 0, 0, 0);

	Out.ar(out, sig);

}).add;
)

(
SynthDef(\sheepSpace, {

	| in, out |
	var sig;

	sig = In.ar(in);

	// Encode
	sig = FoaEncode.ar(sig, FoaEncoderMatrix.newOmni);
	// Transform
	sig = FoaZoom.ar(sig, 0, 0, 0);

	Out.ar(out, sig);

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
var amp_e = 0.1, amp_s = 1, amp_r = 1,
    dur_e = 4, dur_s = 1,
    eagleAmbi, riverAmbi, sheepAmbi,
    eagleEcho, riverReverb, sheepReverb;

// Ambisonics Input + Transform
eagleAmbi = Synth.new(\eagleSpace, [
	\in, ~mountainEagleAmbi,
	\out, ~ambisonicsBus
]);
riverAmbi = Synth.new(\riverSpace, [
	\in, ~mountainRiverAmbi,
	\out, ~ambisonicsBus
]);
sheepAmbi = Synth.new(\sheepSpace, [
	\in, ~mountainSheepAmbi,
	\out, ~ambisonicsBus
]);

// Effects
eagleEcho = Synth.new(\mountainEchoGenerator, [
	\in, ~mountainEagleFx,
	\out, ~mountainEagleAmbi
]);

sheepReverb = Synth.new(\mountainReverbGenerator, [
	\in, ~mountainSheepFx,
	\out, ~mountainSheepAmbi
]);

riverReverb = Synth.new(\mountainReverbGenerator, [
	\in, ~mountainRiverFx,
	\out, ~mountainRiverAmbi
]);

// Control the volume of the eagles
MIDIdef.cc(\ampEagle, {

	| val, num, chan, src |

	[val, num].postln;
	amp_e = val.linlin(0, 127, 0, 1);

}, 0);

MIDIdef.cc(\ampRiver, {

	| val, num, chan, src |
	var amp_r;

	[val, num].postln;
	amp_r = val.linlin(0 ,127, 0, 1);
	~river.set(\amp, amp_r);

}, 1);

// Control the volume of the sheep
MIDIdef.cc(\ampSheep, {

	| val, num, chan, src |

	[val, num].postln;
	amp_s = val.linlin(0, 127, 0, 1);

}, 2);

// Control the duration of the eagles
MIDIdef.cc(\durEagle, {

	|val, num, chan, src|

	[val, num].postln;
	dur_e = val.linlin(0, 127, 0.5, 1.5);

}, 16);

// Control the duration of the sheep
MIDIdef.cc(\durSheep, {

	|val, num, chan, src|

	[val, num].postln;
	dur_s = val.linlin(0, 127, 2, 6);

}, 18);

// Play the river
~river = Synth.new(\riverGenerator, [
	\out, ~mountainRiverFx
]);

// Play the eagle
~eagle = Pbind(*[

	\instrument, \eagleGenerator,
	\out, ~mountainEagleFx,
	\sizefactor, Pwhite(0.0,1,inf),
	\dur , Pgauss(Pfuncn({ dur_e }, inf), Pfuncn({ dur_e }, inf) - 0.1),
    \amp, Pfuncn({ amp_e }, inf),
	\doneAction, 2

]).play;

// Play the sheep
~sheep = Pbind(*[

	\instrument, \sheepGenerator,
	\sizefactor, Pwhite(0.0,1,inf),
	\out, ~mountainSheepFx,
	\dur , Pgauss(Pfuncn({ dur_s }, inf), Pfuncn({ dur_s }, inf) - 0.25),
    \amp, Pfuncn({ amp_s }, inf),
	\doneAction, 2

]).play;
)

// Stop the mountains
(
~eagle.stop;
~river.free;
~sheep.stop;
)