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
~mountainRealEagleFx = Bus.audio(s, 2);
~mountainRealSheepFx = Bus.audio(s, 1);

// Ambisonics Encode + Transform In
~mountainRiverAmbi = Bus.audio(s, 1);
~mountainSheepAmbi = Bus.audio(s, 1);
~mountainEagleAmbi = Bus.audio(s, 2);
~mountainRealEagleAmbi = Bus.audio(s, 2);
~mountainRealSheepAmbi = Bus.audio(s, 2);
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
~realEagle = Buffer.read(Server.default, "samples/".resolveRelative ++ "eagle.wav");
~realSheep = Buffer.read(Server.default, "samples/".resolveRelative ++ "sheep.wav");
)

// Define eagle synth
(
SynthDef(\eagleGenerator, {

	| out = 0, t_trig = 0, amp = 0.2, dur = 1, doneAction = 2 |
	var sig = 0, env;

	5.collect({

		| i |
		sig = sig * 0.7 + ((Formant.ar(EnvGen.kr(Env([i * Rand(500, 700), i * Rand(750, 800), i * Rand(550, 625)], [0.5, 0.5, 0.3])))* 0.2) * i);

	});

	sig = BPF.ar(sig, 1000);

	env = EnvGen.kr(Env.perc(dur/8, dur/12).delay(0.003), t_trig, doneAction: doneAction);
	sig = sig * env * 0.3;
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

	sig = Formant.ar(125, XLine.ar(125, 200, 0.5), XLine.ar(125, 200, 0.5), mul: XLine.ar(1, 0.1, 0.5)) + Formant.ar(Vibrato.ar(DC.ar(125), XLine.ar(10, 20, 1), XLine.ar(0.02, 0.1, 1)), XLine.ar(700, 1500, 0, 1), 2500, mul: XLine.ar(0.1, 1, 0.5));

	sig = BPF.ar(sig, 800, 0.9);
	sig = sig * env;
	sig = 0.5 * amp * sig;

	Out.ar(out, sig);

}).add;
)

(
SynthDef(\bufPlaySynth, {

	| out = 0, amp = 1, buf, doneAction = 2 |
	var sig;

	sig= PlayBuf.ar(1, buf, doneAction: doneAction);
	sig = sig * amp;

	Out.ar(out, sig);

}).add;
)

(
SynthDef(\bufPlaySynthStereo, {

	| out = 0, amp = 1, buf, doneAction = 2 |
	var sig;

	sig= PlayBuf.ar(2, buf, doneAction: doneAction);
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

	| in, out, range = 0, spread = pi |
	var sig;

	sig = In.ar(in, 2);

	// Encode
	sig = FoaEncode.ar(sig, FoaEncoderMatrix.newStereo);
	// Transform
	sig = FoaZoom.ar(sig, range, spread, 0);

	Out.ar(out, sig);

}).add;
)

(
SynthDef(\riverSpace, {

	| in, out, spread = 0, range = 0, elevation = 0 |
	var sig;

	sig = In.ar(in);

	// Encode
	sig = FoaEncode.ar(sig, FoaEncoderMatrix.newOmni);
	// Transform
	sig = FoaZoom.ar(sig, spread, range, elevation);

	Out.ar(out, sig);

}).add;
)

(
SynthDef(\sheepSpace, {

	| in, out, spread = 0, range = 0, elevation = 0 |
	var sig;

	sig = In.ar(in);

	// Encode
	sig = FoaEncode.ar(sig, FoaEncoderMatrix.newOmni);
	// Transform
	sig = FoaZoom.ar(sig, spread, range, elevation);

	Out.ar(out, sig);

}).add;
)

(
SynthDef(\realEagleSpace, {

	| in, out, spread = 0, range = 0, elevation = pi |
	var sig;

	sig = In.ar(in);

	// Encode
	sig = FoaEncode.ar(sig, FoaEncoderMatrix.newOmni);
	// Transform
	sig = FoaZoom.ar(sig, spread, range, elevation);

	Out.ar(out, sig);

}).add;
)

(
SynthDef(\realSheepSpace, {

	| in, out, spread = 0, range = 0, elevation = 0 |
	var sig;

	sig = In.ar(in);

	// Encode
	sig = FoaEncode.ar(sig, FoaEncoderMatrix.newOmni);
	// Transform
	sig = FoaZoom.ar(sig, spread, range, elevation);

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
var ampEagle = 0.1, ampSheep = 1,
    durEagle = 4, durSheep = 1;

// Ambisonics Input + Transform
~eagleAmbi = Synth.new(\eagleSpace, [
	\in, ~mountainEagleAmbi,
	\out, ~ambisonicsBus
]);
~riverAmbi = Synth.new(\riverSpace, [
	\in, ~mountainRiverAmbi,
	\out, ~ambisonicsBus
]);
~sheepAmbi = Synth.new(\sheepSpace, [
	\in, ~mountainSheepAmbi,
	\out, ~ambisonicsBus
]);
~realEagleAmbi = Synth.new(\realEagleSpace, [
	\in, ~mountainRealEagleAmbi,
	\out, ~ambisonicsBus
]);
~realSheepAmbi = Synth.new(\realSheepSpace, [
	\in, ~mountainRealSheepAmbi,
	\out, ~ambisonicsBus
]);

// Effects
~eagleEcho = Synth.new(\mountainEchoGenerator, [
	\in, ~mountainEagleFx,
	\out, ~mountainEagleAmbi
]);

~sheepReverb = Synth.new(\mountainReverbGenerator, [
	\in, ~mountainSheepFx,
	\out, ~mountainSheepAmbi
]);

~riverReverb = Synth.new(\mountainReverbGenerator, [
	\in, ~mountainRiverFx,
	\out, ~mountainRiverAmbi
]);

~realEagleEcho = Synth.new(\mountainEchoGenerator, [
	\in, ~mountainRealEagleFx,
	\out, ~mountainRealEagleAmbi
]);

~realSheepReverb = Synth.new(\mountainReverbGenerator, [
	\in, ~mountainRealSheepFx,
	\out, ~mountainRealSheepAmbi
]);

/* MIDI CONTROLS */

// Control the volume of the eagles
MIDIdef.cc(\ampEagle, {

	| val, num, chan, src |

	[val, num].postln;
	ampEagle = val.linlin(0, 127, 0, 1);

}, 32);

// Control the duration of the eagles
MIDIdef.cc(\durEagle, {

	|val, num, chan, src|

	[val, num].postln;
	durEagle = val.linlin(0, 127, 0.5, 1.5);

}, 40);

MIDIdef.cc(\spreadEagle, {

	| val, num, chan, src |
	var spread;

	[val, num].postln;
	spread = val.linlin(0, 127, -pi/2, pi/2);

}, 33);

// Control the duration of the eagles
MIDIdef.cc(\rangeEagle, {

	| val, num, chan, src |
	var range;

	[val, num].postln;
	range = val.linlin(0, 127, 0, pi);
	~eagleAmbi.set(\range, range);

}, 41);

// Control the volume of the sheep
MIDIdef.cc(\ampSheep, {

	| val, num, chan, src |

	[val, num].postln;
	ampSheep = val.linlin(0, 127, 0, 1);

}, 34);

// Control the duration of the sheep
MIDIdef.cc(\durSheep, {

	|val, num, chan, src|

	[val, num].postln;
	durSheep = val.linlin(0, 127, 2, 6);

}, 42);

MIDIdef.cc(\ampRiver, {

	| val, num, chan, src |
	var amp_r;

	[val, num].postln;
	amp_r = val.linlin(0 ,127, 0, 1);
	~river.set(\amp, amp_r);

}, 35);

// Trigger real owl by playing MIDI note
MIDIdef.noteOn(\triggerRealEagle, {

	| vel, nn, chan, src |

	[vel, nn, chan, src].postln;
	Synth.new(\bufPlaySynthStereo, [
		\buf, ~realEagle,
		\out, ~mountainRealEagleFx
	]);

}, 40);

// Triger real duck by playing MIDI note
MIDIdef.noteOn(\triggerRealSheep, {

	| vel, nn, chan, src |

	[vel, nn, chan, src].postln;
	Synth.new(\bufPlaySynth, [
		\buf, ~realSheep,
		\out, ~forestRealSheepFx
	]);

}, 41);

/* -- */

// Play the river
~river = Synth.new(\riverGenerator, [
	\out, ~mountainRiverFx
]);

// Play the eagle
~eagle = Pbind(*[

	\instrument, \eagleGenerator,
	\out, ~mountainEagleFx,
	\sizefactor, Pwhite(0.0,1,inf),
	\dur , Pgauss(Pfuncn({ durEagle }, inf), Pfuncn({ durEagle }, inf) - 0.1),
    \amp, Pfuncn({ ampEagle }, inf),
	\doneAction, 2

]).play;

// Play the sheep
~sheep = Pbind(*[

	\instrument, \sheepGenerator,
	\sizefactor, Pwhite(0.0,1,inf),
	\out, ~mountainSheepFx,
	\dur , Pgauss(Pfuncn({ durSheep }, inf), Pfuncn({ durSheep }, inf) - 0.25),
    \amp, Pfuncn({ ampSheep }, inf),
	\doneAction, 2

]).play;
)

// Stop the mountains
(
~eagle.stop;
~river.free;
~sheep.stop;
)