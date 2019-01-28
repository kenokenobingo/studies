/*
 *   _                     _
 *  | |__   ___  __ _  ___| |__
 *  | '_ \ / _ \/ _` |/ __| '_ \
 *  | |_) |  __/ (_| | (__| | | |
 *  |_.__/ \___|\__,_|\___|_| |_|
 *
 *
 *  #+METHOD: Simulation
 *  #+AUTHOR: K E N O
 *  #+TITLE: At the beach (Tag am Meer)
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
~beachBubbleFx = Bus.audio(s, 1);
~beachGullFx = Bus.audio(s, 1);
~beachWaveFx = Bus.audio(s, 1);
~beachRealGullFx = Bus.audio(s, 1);
~windFx = Bus.audio(s, 1);

// Ambisonics Encode + Transform In
~beachBubbleAmbi = Bus.audio(s, 2);
~beachGullAmbi = Bus.audio(s, 2);
~beachWaveAmbi = Bus.audio(s, 2);
~beachRealGullAmbi = Bus.audio(s, 2);
~windAmbi = Bus.audio(s, 1);
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
~realGull = Buffer.read(Server.default, "samples/".resolveRelative ++ "seagull.wav");
)

// Define bubble synth
(
SynthDef(\bubbleGenerator, {

	| out = 0, t_trig = 0, attack = 0.01, decay = 0.08, freq = 400, amp = 0.1, pitchcurvelen = 0.1, doneAction = 2 |
	var env, pitch, sig;

	env = amp * EnvGen.ar(Env.perc(attack, decay).delay(0.003), t_trig, doneAction: doneAction);
	pitch = freq * EnvGen.ar(Env.new([0,0,1],[0,1]).exprange(1, 2.718), t_trig, timeScale: pitchcurvelen);
	sig = SinOsc.ar(pitch);

	// Apply low-pass filter to the signal
	sig = LPF.ar(sig, 500) * env * 0.35;

	Out.ar(out, sig);

}).add;
)

// Define sea gull synth
(
SynthDef.new(\gullGenerator, {

	| out = 0, t_trig = 0, freq=900, amp = 1, attack = 0.5, decay = 2, dur = 0.5, doneAction = 2 |
	var env, env_effect, lfo, sig, temp, vibrato;

	lfo = XLine.ar(3, 30);

	vibrato = Vibrato.ar(100, 6, 0.8);
	env = EnvGen.ar(Env.perc(Rand(attack - 0.2, attack), Rand(decay - 0.1, decay)), t_trig, doneAction: doneAction) * amp;

	// Resonant filter
	sig = Formant.ar(XLine.kr(freq, 600, 0.5), XLine.kr(3000, 1400, 0.5), XLine.kr(freq * 2, 700, 0.5), mul: 0.6) + Formant.ar(XLine.kr(freq * 2, 150, 0.5), 805, 880, mul: 0.25) + Saw.ar(XLine.ar(freq / 2, 300, 0.5), mul: XLine.kr(0.2, 0, 0.2));

	// Apply LFO and envelope
	sig = 0.6 * env * sig;

	Out.ar(out, sig);

}).add;
)

// Define wave synth
(
SynthDef.new(\waveGenerator, {

	| out = 0, t_trig = 0, attack = 3, decay = 2, amp = 0.8, freqfactor = 0.75, doneAction = 2 |
	var sig, env;

	env = EnvGen.ar(Env.perc(attack, decay), t_trig, doneAction: doneAction);

	// Mix pink and brown noise for wave signal
	sig = (PinkNoise.ar(1) * freqfactor) + (BrownNoise.ar(EnvGen.kr(Env.new([0.2, 1, 0], [attack, decay], [1, -1]))) * (1 - freqfactor));

	// Apply envelope
	sig = amp * sig * env;
	sig = sig * 0.3;

	Out.ar(out, sig);

}).add;
)

// Define wind synth
(
SynthDef.new(\windGenerator, {

	| out = 0, amp = 0.5, cutoff = 400, doneAction = 2 |
	var sig, env;

	sig = BrownNoise.ar() * LFBrownNoise1.ar(0.5) * LFNoise0.ar(0.25);
	// Bandpass Filter
	sig = BRF.ar(sig, cutoff, 0.9);
	sig = sig * amp;

	Out.ar(out, sig);

}).add;
)

// Define buffer player synth
(
SynthDef.new(\bufPlaySynth, {

	| out = 0, amp = 1, buf, doneAction = 2 |
	var sig;

	sig = PlayBuf.ar(2, buf, doneAction: doneAction);
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

(
SynthDef(\echoGenerator, {

	| in, out, delay_time = 2 |
	var effect, sig;

	sig = In.ar(in);
	effect = Greyhole.ar(sig, delay_time, 0.1, 0.2, 0.8, feedback: 0.3);

	Out.ar(out, effect);

}).add;
)

(
SynthDef(\reverbGenerator, {

	| in, out |
	var effect, sig;

	sig = In.ar(in);
	effect = FreeVerb.ar(sig, 0.33, 0.8, 0.3, 0.25);

	Out.ar(out, effect);

}).add;
)

(
SynthDef(\complexReverbGenerator, {

	| in, out, ratio = 0.75 |
	var effect, sig;

	sig = In.ar(in);
	effect = JPverb.ar(sig, 5, 0.5, 1, 0, 0);
	effect = (sig * ratio) + (effect * (1 - ratio));
	effect = effect * 0.3;

	Out.ar(out, effect);

}).add;
)

(
SynthDef(\bandpassGenerator, {
	| in, out, cutoff = 200 |
	var effect, sig;

	sig = In.ar(in);
	effect = BPF.ar(sig, cutoff);

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
SynthDef(\bubbleSpace, {

	| in, out, spread = 0, range = 0, elevation = 0 |
	var sig;

	sig = In.ar(in, 2);

	// Encode

	sig = FoaEncode.ar(sig, FoaEncoderMatrix.newStereo);
	// Transform
	sig = FoaZoom.ar(sig, spread, range, elevation);

	Out.ar(out, sig);

}).add;
)

(
SynthDef(\gullSpace, {

	| in, out, spread = (pi/2), range = pi, elevation = pi |
	var sig;

	sig = In.ar(in, 2);

	// Encode
	sig = FoaEncode.ar(sig, FoaEncoderMatrix.newStereo);
	// Transform
	sig = FoaZoom.ar(sig, spread, range, elevation);

	Out.ar(out, sig);

}).add;
)

(
SynthDef(\waveSpace, {

	| in, out, spread = 0, range = 0, elevation = 0 |
	var sig;

	sig = In.ar(in, 2);

	// Encode
	sig = FoaEncode.ar(sig, FoaEncoderMatrix.newStereo);
	// Transform
	sig = FoaZoom.ar(sig, spread, range, elevation);

	Out.ar(out, sig);

}).add;
)

(
SynthDef(\windSpace, {

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
SynthDef(\realGullSpace, {

	| in, out, spread = 0, range = 0, elevation = pi |
	var sig;

	sig = In.ar(in, 2);

	// Encode
	sig = FoaEncode.ar(sig, FoaEncoderMatrix.newStereo);
	// Transform
	sig = FoaZoom.ar(sig, spread, range, elevation);

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
var ampBubble = 1, ampGull = 1, ampWave = 1,
    durBubble = 1, durGull = 1, durWave = 1;

// Ambisonics Input + Transform
~bubbleAmbi = Synth.new(\bubbleSpace, [
	\in, ~beachBubbleAmbi,
	\out, ~ambisonicsBus
]);
~gullAmbi = Synth.new(\gullSpace, [
	\in, ~beachGullAmbi,
	\out, ~ambisonicsBus,
	\range, (pi/2),
	\spread, pi
]);
~waveAmbi = Synth.new(\waveSpace, [
	\in, ~beachWaveAmbi,
	\out, ~ambisonicsBus
]);

~windA = Synth.new(\windSpace, [
	\in, ~windAmbi,
	\out, ~ambisonicsBus
]);

~realGullAmbi = Synth.new(\realGullSpace, [
	\in, ~beachRealGullAmbi,
	\out, ~ambisonicsBus
]);

//Effects
~bubbleHall = Synth.new(\complexReverbGenerator, [
	\in, ~beachBubbleFx,
	\out, ~beachBubbleAmbi
]);
~gullHall = Synth.new(\reverbGenerator, [
	\in, ~beachGullFx,
	\out, ~beachGullAmbi
]);
~waveHall = Synth.new(\reverbGenerator, [
	\in, ~beachWaveFx,
	\out, ~beachWaveAmbi
]);
~windBand = Synth.new(\bandpassGenerator, [
	\in, ~windFx,
	\out, ~windAmbi
]);
~realGullHall = Synth.new(\reverbGenerator, [
	\in, ~beachRealGullFx,
	\out, ~beachRealGullAmbi
]);

// Play the bubbles
~bubble = Pbind(*[

	\instrument, \bubbleGenerator,
	\out, ~beachBubbleFx,
	\sizefactor, Pwhite(0.0,1,inf),
	\dur , Pgauss(Pfuncn({ durBubble }, inf), Pfuncn({ durBubble }, inf) - 0.2),
	\freq, Pkey(\sizefactor).linexp(0, 1, 100, 600),
	\amp, Pfuncn({ ampBubble }, inf),
	\decay, Pkey(\sizefactor).linlin(0, 1, 0.05, 0.08),
	\pitchcurvelen, Pkey(\sizefactor).linlin(0, 1, 0.05, 0.2),
	\doneAction, 2

]).play;

// Play the sea gulls
~gull = Pbind(*[

	\instrument, \gullGenerator,
	\out, ~beachGullFx,
	\sizefactor, Pwhite(0.0,1,inf),
	\dur , Pgauss(Pfuncn({ durBubble }, inf), Pfuncn({ durBubble }, inf) + 1),
    \freq, Pkey(\sizefactor).linexp(0, 1, 400, 1000),
	\amp, Pfuncn({ ampGull }, inf),
    \attack, Pkey(\sizefactor).linexp(0, 1, 0.2, 0.8),
    \decay, Pkey(\sizefactor).linlin(0, 1, 0.3, 0.8),
	\doneAction, 2

]).play;

// Play the waves
~wave = Pbind(*[

	\instrument, \waveGenerator,
	\out, ~beachWaveFx,
	\sizefactor, Pwhite(0.0,1,inf),
	\dur, Pgauss(Pfuncn({ durWave }, inf), Pfuncn({ durWave }, inf) -1),
	\amp , Pfuncn({ ampWave }, inf),
	\decay, Pkey(\sizefactor).linlin(0, 1, 2, 10),
	\freqfactor, Pkey(\sizefactor).linlin(0, 1, 0.1, 0.9),
	\doneAction, 2

]).play;

// Play the wind
~wind = Synth.new(\windGenerator, [

	\out, ~windFx

]);

// Control the volume of the bubbles
MIDIdef.cc(\ampBubble, {

	| val, num, chan, src |

	ampBubble = val.linlin(0, 127, 0, 1);
	ampBubble.postln;

}, 0);

// Control the duration of the bubbles
MIDIdef.cc(\durBubble, {

	| val, num, chan, src |

	[val, num].postln;
	durBubble = val.linlin(0, 127, 0.3, 0.5);

}, 8);

// Control the volume of the gulls
MIDIdef.cc(\ampGull, {

	| val, num, chan, src |

	[val, num].postln;
	ampGull = val.linlin(0, 127, 0, 1);
	ampGull.postln;

}, 1);

/* MIDI CONTROLS */

// Control the duration of the gulls
MIDIdef.cc(\durGull, {

	| val, num, chan, src |
	var range;

	[val, num].postln;
	durGull = val.linlin(0, 127, 0.5, 3);
	~gullAmbi.set(\range, range);

}, 9);

// Control the spread of the gulls
MIDIdef.cc(\spreadGull, {

	| val, num, chan, src |
	var spread;

	[val, num].postln;
	spread = val.linlin(0, 127, -pi/2, pi/2);
	~gullAmbi.set(\spread, spread);

}, 2);

// Control the range of the gulls
MIDIdef.cc(\rangeGull, {

	| val, num, chan, src |
	var range;

	[val, num].postln;
	range = val.linlin(0, 127, 0, pi);
	~gullAmbi.set(\range, range);

}, 10);

// Control the volume of the waves
MIDIdef.cc(\ampWave, {

	| val, num, chan, src |

	[val, num].postln;
    ampWave = val.linlin(0, 127, 0, 1);
	ampWave.postln;

}, 3);

// Control the volume of the waves
MIDIdef.cc(\durWave, {

	| val, num, chan, src |

	[val, num].postln;
	durWave = val.linlin(0, 127, 2, 8);

}, 11);


// Control the spread of the gulls
MIDIdef.cc(\spreadWave, {

	| val, num, chan, src |
	var spread;

	[val, num].postln;
	spread = val.linlin(0, 127, -pi/2, pi/2);
	~waveAmbi.set(\spread, spread);

}, 4);

// Control the range of the gulls
MIDIdef.cc(\rangeWave, {

	| val, num, chan, src |
	var range;

	[val, num].postln;
	range = val.linlin(0, 127, 0, pi);
	~waveAmbi.set(\range, range);

}, 12);

// Control the volume of the wind
MIDIdef.cc(\ampWind, {

	| val, num, chan, src |
	var amp;

	[val, num].postln;
	amp = val.linlin(0, 127, 0, 1);
	~wind.set(\amp, amp);

}, 7);

// Control the filter of the wind
MIDIdef.cc(\filterWind, {

	| val, num, chan, src |
	var filterWind;

	[val, num].postln;
    filterWind = val.linexp(0, 127, 50, 10000);
	~wind.set(\cutoff, filterWind);

}, 15);

MIDIdef.cc(\spreadWind, {

	| val, num, chan, src |
	var spread;

	[val, num].postln;
	spread = val.linlin(0, 127, -pi/2, pi/2);
	~windAmbi.set(\spread, spread);

}, 6);

// Control the range of the gulls
MIDIdef.cc(\rangeWind, {

	| val, num, chan, src |
	var range;

	[val, num].postln;
	range = val.linlin(0, 127, 0, pi);
	~windAmbi.set(\range, range);

}, 14);

// Trigger real gull by playing MIDI note
MIDIdef.noteOn(\triggerRealGull, {

	| vel, nn, chan, src |

	[vel, nn, chan, src].postln;

	Synth.new(\bufPlaySynth, [
		\buf, ~realGull.bufnum,
		\out, ~beachRealGullFx
	]);

}, 36);
)

/* -- */

// Stop the beach
(
~bubble.stop;
~gull.stop;
~wave.stop;
)

(
~wind.free;
)