/*
 *    __                     _
 *  / _| ___  _ __ ___  ___| |_
 *  | |_ / _ \| '__/ _ \/ __| __|
 *  |  _| (_) | | |  __/\__ \ |_
 *  |_|  \___/|_|  \___||___/\__|
 *
 *
 *  #+METHOD: Simulation
 *  #+AUTHOR: K E N O
 *  #+TITLE: Forest
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
~forestPeckerFx = Bus.audio(s, 1);
~forestOwlFx = Bus.audio(s, 1);
~forestCricketFx = Bus.audio(s, 1);
~forestFrogFx = Bus.audio(s, 1);
~forestDuckFx = Bus.audio(s, 1);
~forestRealOwlFx = Bus.audio(s, 1);
~forestRealDuckFx = Bus.audio(s, 1);

// Ambisonics Encode + Transform In
~forestPeckerAmbi = Bus.audio(s, 2);
~forestOwlAmbi = Bus.audio(s, 2);
~forestCricketAmbi = Bus.audio(s, 1);
~forestFrogAmbi = Bus.audio(s, 1);
~forestDuckAmbi = Bus.audio(s, 1);
~forestRealOwlAmbi = Bus.audio(s, 2);
~forestRealDuckAmbi = Bus.audio(s, 2);
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
~realDuck = Buffer.read(Server.default, "samples/".resolveRelative ++ "duck.wav");
~realOwl = Buffer.read(Server.default, "samples/".resolveRelative ++ "owl.wav");
)

// Define woodpecker synth
(
SynthDef(\woodpeckerGenerator, {

	| out = 0, t_trig = 0, dur = 0.25,  amp = 1, attack = 0.1, decay = 0.1, doneAction = 2 |
    var env, sig;

	env = amp * EnvGen.ar(Env.perc(attack, decay), t_trig, doneAction: doneAction);

    sig = SinOsc.ar(Env([1000, 20, 20], [dur * 0.015, dur * 0.01], \lin).ar * [-0.1, 0, 0.1].midiratio);
    sig = BPeakEQ.ar(sig, XLine.kr(1000, 100, 0.1), 1.0, 10);
    sig = HPF.ar(sig, 800, 0.7);
	sig = sig * env;
	sig = sig * 10;

	// Ambisonics
	// Encode
	sig = FoaEncode.ar(sig, FoaEncoderMatrix.newOmni);
	// Transform
	sig = FoaZoom.ar(sig, pi, pi/8, (pi * 5/8));

    Out.ar(~ambisonicsBus, sig);
}).add;
)

// Define owl synth
(
SynthDef(\owlGenerator, {

	| t_trig = 0, dur = 1, amp = 1, attack = 0.1, decay = 0.5, freq = 400, out = 0, doneAction = 2 |
	var env, sig;

	env = EnvGen.kr(Env.new([0, 0.8, 1, 0], [0, dur * 0.4, dur * 0.1, dur * 0.1]), doneAction: doneAction);

	a = LFNoise2.kr(2)**0.33;
	e = EnvGen.kr(Env.new([0, 0.2, 0], [0, 0.2, 0.4]));
	5.collect({
		|i|
		sig = Formant.ar(Vibrato.ar(i * 80, 3, 0.015), XLine.ar(320, 100, 0, dur), 320);
	});
	sig = BPF.ar(sig, 320);
	sig = sig * env;
	sig = sig * amp;

	// Ambisonics
	// Encode
	sig = FoaEncode.ar(sig, FoaEncoderMatrix.newOmni);
	// Transform
	sig = FoaZoom.ar(sig, pi, pi/9, pi);

	Out.ar(~forestOwlFx, sig);

}).add;
)

// Define buffer player synth
(
SynthDef(\bufPlaySynth, {

	| out, amp = 1, buf, doneAction = 2 |
	var sig;

	sig= PlayBuf.ar(1, buf, doneAction: doneAction);
	sig = sig * amp;

	// Ambisonics
	// Encode
	sig = FoaEncode.ar(sig, FoaEncoderMatrix.newOmni);
	// Transform
	sig = FoaZoom.ar(sig, MouseX.kr(0, pi/2).poll, 0);

	Out.ar(out, sig);

}).add;
)

// Define rain synth
(
SynthDef(\rainGenerator, {

	| amp = 0.3, cutoff = 800 |
	var gaus, sig;

	sig = WhiteNoise.ar() * Crackle.ar() * LFDNoise0.ar();

	sig = HPF.ar(sig, cutoff);

	sig = sig * amp;

	// Ambisonics
	// Encode
	sig = FoaEncode.ar(sig, FoaEncoderMatrix.newOmni);
	// Transform
	sig = FoaZoom.ar(sig, 0, 0, 0);

	Out.ar(~ambisonicsBus, sig);

}).add;
)

// Define cricket synth
(
SynthDef(\cricketSynth, {

	| amp = 1 |

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
	sig = sig * amp;

	// Ambisonics
	// Encode
	sig = FoaEncode.ar(sig, FoaEncoderMatrix.newOmni);
	// Transform
	sig = FoaZoom.ar(sig, pi/4, 0, 0);

	Out.ar(~ambisonicsBus, sig);

}).add;
)

// Define frog synth
// CREDIT: Modified version of <https://sccode.org/1-4Xe> by `Manolis`.
(
SynthDef(\frogSynth, {

	| out = 0, amp = 1, rateL = 0.2, rateR = 0.3, freq = 2, feedback = 50, mul = 0.3 , lpfreq = 2500 |
	var sig;

	sig = FreeVerb.ar(
			BLowPass.ar(
				amp * SinOscFB.ar(
					LFDNoise1.kr([rateL, rateR], freq), feedback;
				, mul),
				lpfreq,
				0.2
			),
			0.3,
			0.0
		);

	// Ambisonics
	// Encode
	sig = FoaEncode.ar(sig, FoaEncoderMatrix.newOmni);
	// Transform
	sig = FoaZoom.ar(sig, pi/4, pi, 0);

	Out.ar(out, sig);

}).add;
)

// Define duck synth
// CREDIT: Modified version of <https://sccode.org/1-4Xe> by `Manolis`.
(
SynthDef(\duckSynth, {

	| out = 0, amp = 1, rateL = 1, rateR = 2, freq = 1, feedback = 90, mul = 1 , lpfreq = 1900 |
	var sig;

	sig = FreeVerb.ar(
			BLowPass.ar(
				amp * SinOscFB.ar(
					LFDNoise1.kr([rateL, rateR], freq), feedback;
				, mul),
				lpfreq,
				0.2
			),
			0.3,
			0.0
		);

	// Ambisonics
	sig = FoaEncode.ar(sig, FoaEncoderMatrix.newOmni);
	sig = FoaZoom.ar(sig, pi/4, pi, 0);

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

	| in, out |
	var effect, sig;

	sig = In.ar(in);
	sig = sig;
	effect = FreeVerb.ar(sig, 0.3, 0.5, 0.8);
	effect = Greyhole.ar(effect, 2, 0.2, diff: 0.8, feedback: 0.4);
	effect = effect;

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
SynthDef(\duckSpace, {

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
SynthDef(\frogSpace, {

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
SynthDef(\owlSpace, {

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
SynthDef(\realDuckSpace, {

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
SynthDef(\realOwlSpace, {

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
SynthDef(\peckerSpace, {

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
var p1, p2, p3,
    owl_hall, realOwl_hall,
    d_am, f_am, o_am, rd_am, ro_am, w_am,
    amp_o = 1, amp_p = 1, amp_r = 1,
    dur_o = 1, dur_p = 1, dur_r = 1;

// Effects
owl_hall = Synth.new(\hallGenerator, [
	\in, ~forestOwlFx,
	\out, ~forestOwlAmbi
]);

realOwl_hall = Synth.new(\hallGenerator, [
	\in, ~forestRealOwlFx,
	\out, ~forestRealOwlAmbi
]);

// Ambisonics Input + Transform
d_am = Synth.new(\duckSpace, [
	\in, ~forestDuckAmbi,
	\out, ~ambisonicsBus
]);
f_am = Synth.new(\frogSpace, [
	\in, ~forestFrogAmbi,
	\out, ~ambisonicsBus
]);
o_am = Synth.new(\owlSpace, [
	\in, ~forestOwlAmbi,
	\out, ~ambisonicsBus
]);
rd_am = Synth.new(\realDuckSpace, [
	\in, ~forestRealDuckAmbi,
	\out, ~ambisonicsBus
]);
ro_am = Synth.new(\realOwlSpace, [
	\in, ~forestRealOwlAmbi,
	\out, ~ambisonicsBus
]);
w_am = Synth.new(\peckerSpace, [
	\in, ~forestPeckerAmbi,
	\out, ~ambisonicsBus
]);

// Play the crickets
~cricket = Synth.new(\cricketSynth, [
	\out, ~forestCricketFx
]);

// Play the ducks
~duck = Synth.new(\duckSynth, [
	\out, ~forestDuckFx
]);

// Play the frog
~frog = Synth.new(\frogSynth, [
	\out, ~forestFrogFx
]);

// Play the river
~rain = Synth.new(\rainGenerator, [
	\out, ~forestRainFx
]);

// Play the owl
~owl= Pbind(*[

	\instrument, \owlGenerator,
	\out, ~forestOwlFx,
	\sizefactor, Pwhite(0.0,1,inf),
	\delta, 10,
	\amp , Pfuncn({ amp_o }, inf),
	\dur, Pfuncn({ dur_o }, inf),
	\freq, Pkey(\sizefactor).linexp(0, 1, 200, 300),
	\decay, Pkey(\sizefactor).linlin(0, 1, 1, 2),
	\doneAction, 2

]).play;

// Play the woodpecker
~pecker = Pbind(*[

	\instrument, \woodpeckerGenerator,
	\out, ~forestPeckerFx,
	\sizefactor, Pwhite(0.0,1,inf),
	\amp, Pfuncn({ amp_p }, inf),
	\dur, Pgauss(0.05, 0.05, inf),
	\freq, Pkey(\sizefactor).linexp(0, 1, 50, 100),
	\decay, Pkey(\sizefactor).linlin(0, 1, 0, 1),
	\doneAction, 2,

]).play;

// Trigger real owl by playing MIDI note
MIDIdef.noteOn(\triggerRealOwl, {

	| vel, nn, chan, src |

	[vel, nn, chan, src].postln;
	Synth.new(\bufPlaySynth, [\buf, ~realOwl.bufnum]);

}, 36);

// Triger real duck by playing MIDI note
MIDIdef.noteOn(\triggerRealDuck, {

	| vel, nn, chan, src |

	[vel, nn, chan, src].postln;
	Synth.new(\bufPlaySynth, [\buf, ~realDuck.bufnum]);

}, 37);


// Control the volume of the crickets
MIDIdef.cc(\amp_c, {

	| val, num, chan, src |
	var amp_c;

	[val, num].postln;
	amp_c = val.linlin(0, 127, 0, 4);
	~crickets.set(\amp, amp_c);

}, 0);

// Control the volume of the ducks
MIDIdef.cc(\amp_d, {

	| val, num, chan, src |
	var amp_d;

	[val, num].postln;
	amp_d = val.linlin(0, 127, 0, 4);
	~ducks.set(\amp, amp_d);

}, 1);

// Control the volume of the frogs
MIDIdef.cc(\amp_f, {

	| val, num, chan, src |
	var amp_f;

	[val, num].postln;
	amp_f = val.linlin(0, 127, 0, 4);
	~frogs.set(\amp, amp_f);

}, 2);

// Control the volume of the owls
MIDIdef.cc(\amp_o, {

	| val, num, chan, src |

	[val, num].postln;
	amp_o = val.linlin(0, 127, 0, 1);
	amp_o.postln;

}, 3);

// Control the volume of the woodpecker
MIDIdef.cc(\amp_p, {

	| val, num, chan, src |

	[val, num].postln;
	amp_p = val.linlin(0, 127, 0, 1);
	amp_p.postln;

}, 4);

// Control the volume of the rain
MIDIdef.cc(\amp_r, {

	| val, num, chan, src |
	var amp_r;

	[val, num].postln;
	amp_r = val.linlin(0, 127, 0, 1);
	~rain.set(\amp, amp_r);

}, 5);

// Control the duration of the owls
MIDIdef.cc(\dur_o, {

	| val, num, chan, src |

	[val, num].postln;
	dur_o = val.linlin(0, 127, 0.5, 1.5);

}, 19);

// Control the duration of the woodpecker
MIDIdef.cc(\dur_p, {

	| val, num, chan, src |

	[val, num].postln;
	dur_p = val.linlin(0, 127, 0.25, 1.25);

}, 20);

MIDIdef.cc(\filter_rain, {

	| val, num, chan, src |
	var filter_rain;

	[val, num].postln;
	filter_rain = val.linlin(0, 127, 20, 1200);
	~rain.set(\cutoff, filter_rain);

}, 21);
)

// Stop the forest
(
~cricket.free;
~duck.free;
~frog.free;
~owl.stop;
~pecker.stop;
~river.free;
)