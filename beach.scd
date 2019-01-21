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
~windFx = Bus.audio(s, 1);

// Ambisonics Encode + Transform In
~beachBubbleAmbi = Bus.audio(s, 2);
~beachGullAmbi = Bus.audio(s, 2);
~beachWaveAmbi = Bus.audio(s, 2);
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
SynthDef.new(\waveGenerator, {

	| out = 0, t_trig = 0, attack = 3, decay = 2, amp = 0.5, freqfactor = 0.75, doneAction = 2 |
	var sig, env;

	env = EnvGen.ar(Env.perc(attack, decay), t_trig, doneAction: doneAction);

	// Mix pink and brown noise for wave signal
	sig = (PinkNoise.ar(1)!2 * freqfactor) + (BrownNoise.ar(EnvGen.kr(Env.new([0.2, 1, 0], [attack, decay], [1, -1])))!2 * (1 - freqfactor));

	// Apply envelope
	sig = amp * sig * env;
	sig = sig * 0.3;

	Out.ar(out, sig);

}).add;
)

// Define wind synth
(
SynthDef.new(\windGenerator, {

	| out = 0, t_trig = 0, amp = 0.5, cutoff = 400, doneAction = 2 |
	var sig, env;

	sig = BrownNoise.ar() * LFBrownNoise1.ar(0.5) * LFNoise0.ar(0.25);
	// Bandpass Filter
	sig = BRF.ar(sig, cutoff, 0.9);
	sig = sig * amp;

	// Ambisonics
	sig = FoaEncode.ar(sig, FoaEncoderMatrix.newOmni);
	sig = FoaZoom.ar(sig, 0, 0);

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
	effect = JPverb.ar(sig, 5, 0, 1, 0, 0);
	effect = (sig * ratio) + (effect * (1 - ratio));
	effect = effect * 0.5;

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

	| in, out |
	var sig;

	sig = In.ar(in, 2);

	// Encode
	sig = FoaEncode.ar(sig, FoaEncoderMatrix.newStereo);
	// Transform
	sig = FoaZoom.ar(sig, pi/4, pi, 0);

	Out.ar(out, sig);

}).add;
)

(
SynthDef(\gullSpace, {

	| in, out |
	var sig;

	sig = In.ar(in, 2);

	// Encode
	sig = FoaEncode.ar(sig, FoaEncoderMatrix.newStereo);
	// Transform
	sig = FoaZoom.ar(sig, pi/4, 0, pi/2);

	Out.ar(out, sig);

}).add;
)

(
SynthDef(\waveSpace, {

	| in, out |
	var sig;

	sig = In.ar(in, 2);

	// Encode
	sig = FoaEncode.ar(sig, FoaEncoderMatrix.newStereo);
	// Transform
	sig = FoaZoom.ar(sig, pi/3, pi, 0);

	Out.ar(out, sig);

}).add;
)

(
SynthDef(\windSpace, {

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
)

(
 var amp_b = 1, amp_g = 1, amp_w = 1,
     dur_b = 0.5, dur_g = 1.5, dur_w = 3,
     bubble_reverb, gull_reverb, gull_echo, wave_reverb,
     b_am, g_am, w_am;

// Effects
bubble_reverb = Synth.new(\complexReverbGenerator, [
	\in, ~beachBubbleFx,
	\out, ~beachBubbleAmbi
]);
gull_reverb = Synth.new(\reverbGenerator, [
	\in, ~beachGullFx,
	\out, ~beachGullAmbi
]);
wave_reverb = Synth.new(\reverbGenerator, [
	\in, ~beachWaveFx,
	\out, ~beachWaveAmbi
]);

// Ambisonics Input + Transform
b_am = Synth.new(\bubbleSpace, [
	\in, ~beachBubbleAmbi,
	\out, ~ambisonicsBus
]);
g_am = Synth.new(\gullSpace, [
	\in, ~beachGullAmbi,
	\out, ~ambisonicsBus
]);
w_am = Synth.new(\waveSpace, [
	\in, ~beachWaveAmbi,
	\out, ~ambisonicsBus
]);

// Play the bubbles
~bubble = Pbind(*[

	\instrument, \bubbleGenerator,
	\out, ~beachBubbleFx,
	\sizefactor, Pwhite(0.0,1,inf),
	\dur , Pgauss(Pfuncn({ dur_b }, inf), Pfuncn({ dur_b }, inf) - 0.2),
	\freq, Pkey(\sizefactor).linexp(0, 1, 100, 600),
	\amp , Pkey(\sizefactor).linlin(0, 1, 0.10, 0.04),
	\amp, Pfuncn({ amp_b }, inf),
	\decay, Pkey(\sizefactor).linlin(0, 1, 0.05, 0.08),
	\pitchcurvelen, Pkey(\sizefactor).linlin(0, 1, 0.05, 0.2),
	\doneAction, 2

]).play;

// Play the sea gulls
~gull = Pbind(*[

	\instrument, \gullGenerator,
	\out, ~beachGullFx,
	\sizefactor, Pwhite(0.0,1,inf),
	\dur , Pfuncn({ dur_g }, inf),
    \freq, Pkey(\sizefactor).linexp(0, 1, 400, 800),
	\amp, Pfuncn({ amp_g }, inf),
    \attack, Pkey(\sizefactor).linexp(0, 1, 0.2, 0.8),
    \decay, Pkey(\sizefactor).linlin(0, 1, 0.3, 0.8),
	\doneAction, 2

]).play;

// Play the waves
~wave = Pbind(*[

	\instrument, \waveGenerator,
	\out, ~beachWaveFx,
	\sizefactor, Pwhite(0.0,1,inf),
	\dur, Pgauss(Pfuncn({ dur_w }, inf), Pfuncn({ dur_w }, inf) -1),
	\amp , Pfuncn({ amp_w }, inf),
	\decay, Pkey(\sizefactor).linlin(0, 1, 2, 5),
	\freqfactor, Pkey(\sizefactor).linlin(0, 1, 0.1, 0.9),
	\doneAction, 2

]).play;

// Play the wind
~wind = Synth.new(\windGenerator, [
	\out, ~windFx
]);

// Control the volume of the bubbles
MIDIdef.cc(\amp_b, {

	| val, num, chan, src |

	amp_b = val.linlin(0, 127, 0, 1);
	amp_b.postln;

}, 0);

// Control the volume of the gulls
MIDIdef.cc(\amp_g, {

	| val, num, chan, src |

	[val, num].postln;
	amp_g = val.linlin(0, 127, 0, 1);
	amp_g.postln;

}, 1);

// Control the volume of the waves
MIDIdef.cc(\amp_w, {

	| val, num, chan, src |

	[val, num].postln;
    amp_w = val.linlin(0, 127, 0, 1);
	amp_w.postln;

}, 2);

// Control the volume of the wind
MIDIdef.cc(\amp_wind, {

	| val, num, chan, src |
	var amp_wind;

	amp_wind = val.linlin(0, 127, 0, 1);
	~wind.set(\amp, amp_wind);

}, 3);

// Control the duration of the bubbles
MIDIdef.cc(\dur_b, {

	| val, num, chan, src |

	[val, num].postln;
	dur_b = val.linlin(0, 127, 0.3, 0.5);

}, 16);

// Control the duration of the gulls
MIDIdef.cc(\dur_g, {

	| val, num, chan, src |

	[val, num].postln;
	dur_g = val.linlin(0, 127, 0.5, 3);

}, 17);

// Control the volume of the waves
MIDIdef.cc(\dur_w, {

	| val, num, chan, src |

	[val, num].postln;
	dur_w = val.linlin(0, 127, 2, 8);

}, 18);

// Control the filter of the wind
MIDIdef.cc(\filter_wind, {

	| val, num, chan, src |
	var filter_wind;

	[val, num].postln;
	filter_wind = val.linexp(0, 127, 50, 10000);
	~wind.set(\cutoff, filter_wind);

}, 19);
)

// Stop the beach
(
~bubble.stop;
~gull.stop;
~wave.stop;
)