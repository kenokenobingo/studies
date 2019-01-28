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
~forestRealPeckerFx = Bus.audio(s, 2);
~forestOwlFx = Bus.audio(s, 1);
~forestCricketFx = Bus.audio(s, 1);
~forestFrogFx = Bus.audio(s, 2);
~forestDuckFx = Bus.audio(s, 1);
~forestRealOwlFx = Bus.audio(s, 1);
~forestRealDuckFx = Bus.audio(s, 1);
~forestRainFx = Bus.audio(s, 1);

// Ambisonics Encode + Transform In
~forestRealPeckerAmbi = Bus.audio(s, 2);
~forestOwlAmbi = Bus.audio(s, 2);
~forestCricketAmbi = Bus.audio(s, 2);
~forestFrogAmbi = Bus.audio(s, 2);
~forestDuckAmbi = Bus.audio(s, 1);
~forestRealOwlAmbi = Bus.audio(s, 2);
~forestRealDuckAmbi = Bus.audio(s, 2);
~forestRainAmbi = Bus.audio(s, 1);
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
~realPecker = Buffer.read(Server.default, "samples/".resolveRelative ++ "woodpecker.wav");
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
		sig = Formant.ar(Vibrato.ar(i * 80, 3, 0.015), XLine.ar(320, 100, 0, dur), 320, mul: 0.2);
	});
	sig = BPF.ar(sig, 320);
	sig = sig * env;
	sig = sig * amp;

	Out.ar(out, sig);

}).add;
)

// Define buffer player synth
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

// Define rain synth
(
SynthDef(\rainGenerator, {

	| out = 0, amp = 1, cutoff = 800 |
	var gaus, sig;

	sig = WhiteNoise.ar() * Crackle.ar() * LFDNoise0.ar();

	sig = HPF.ar(sig, cutoff);

	sig = sig * amp * 0.1;

	Out.ar(out, sig);

}).add;
)

// Define cricket synth
(
SynthDef(\cricketSynth, {

	| out, amp = 1 |

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
	sig = sig * amp * 0.5;

	Out.ar(out, sig);

}).add;
)

// Define frog synth
// CREDIT: Modified version of <https://sccode.org/1-4Xe> by `Manolis`.
(
SynthDef(\frogSynth, {

	| out = 0, amp = 1, rateL = 0.2, rateR = 0.3, freq = 2, feedback = 50, mul = 0.3, lpfreq = 2500 |
	var sig;

	sig = FreeVerb.ar(
			BLowPass.ar(
				0.2 * amp * SinOscFB.ar(
					LFDNoise1.kr([rateL, rateR], freq), feedback;
				, (amp * mul)),
				lpfreq,
				0.2
			),
			0.3,
			0.0
		);

	Out.ar(out, sig);

}).add;
)

// Define duck synth
// CREDIT: Modified version of <https://sccode.org/1-4Xe> by `Manolis`.
(
SynthDef(\duckSynth, {

	| out = 0, amp = 1, rateL = 1, rateR = 2, freq = 4, feedback = 90, mul = 0.3, lpfreq = 1500 |
	var sig;

	sig = FreeVerb.ar(
			BLowPass.ar(
				 SinOscFB.ar(
					LFDNoise1.kr([rateL, rateR], freq), feedback;
				, (amp * mul)),
				lpfreq,
				0.2
			),
			0.3,
			0.0
		);

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
SynthDef(\forestReverbGenerator, {

	| in, out |
	var effect, sig;

	sig = In.ar(in);
	effect = FreeVerb.ar(sig, 0.3, 0.2, 0.1);

	Out.ar(out, effect);
}).add;
)

(
SynthDef(\peckerReverbGenerator, {

	| in, out |
	var effect, sig;

	sig = In.ar(in);
	effect = FreeVerb.ar(sig, 0.01, 0.01, 0.1);

	Out.ar(out, effect);
}).add;
)

(
SynthDef(\hallGenerator, {

	| in, out |
	var effect, sig;

	sig = In.ar(in);
	effect = FreeVerb.ar(sig, 0.3, 0.5, 0.8);
	effect = Greyhole.ar(effect, 2, 0.2, diff: 0.8, feedback: 0.4);

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
SynthDef(\cricketSpace, {

	| in, out, spread = (1.25 * pi), range = (1), elevation = 0 |
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
SynthDef(\duckSpace, {

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
SynthDef(\frogSpace, {

	| in, out, spread = 0, range = pi, elevation = 0 |
	var sig;

	sig = In.ar(in, 2);

	// Encode
	sig = FoaEncode.ar(sig, FoaEncoderMatrix.newOmni);
	// Transform
	sig = FoaZoom.ar(sig, spread, range, elevation);

	Out.ar(out, sig);

}).add;
)

(
SynthDef(\owlSpace, {

	| in, out, range = 0, spread = pi, elevation = pi |
	var sig;

	sig = In.ar(in, 2);

	// Encode
	sig = FoaEncode.ar(sig, FoaEncoderMatrix.newStereo);
	// Transform
	sig = FoaZoom.ar(sig, range, spread, elevation);

	Out.ar(out, sig);

}).add;
)

(
SynthDef(\realDuckSpace, {

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
SynthDef(\realOwlSpace, {

	| in, out, spread = pi, range = -pi, elevation = pi |
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
SynthDef(\realPeckerSpace, {

	| in, out, spread = 0, range = 0, elevation = pi |
	var sig;

	sig = In.ar(in, 2);

	// Encode
	sig = FoaEncode.ar(sig, FoaEncoderMatrix.newOmni);
	// Transform
	sig = FoaZoom.ar(sig, spread, range, elevation);

	Out.ar(out, sig);

}).add;
)

(
SynthDef(\rainSpace, {

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


/****************************
 *   ___  ___ ___ _ __   ___
 *  / __|/ __/ _ \ '_ \ / _ \
 *  \__ \ (_|  __/ | | |  __/
 *  |___/\___\___|_| |_|\___|
 *
 ****************************/

(
var ampOwl = 1, ampPecker = 1, ampRain = 1,
    durOwl = 1, durPecker = 1, durRain = 1;

// Ambisonics Input + Transform
~cricketAmbi = Synth.new(\cricketSpace, [
	\in, ~forestCricketAmbi,
	\out, ~ambisonicsBus
]);
~duckAmbi = Synth.new(\duckSpace, [
	\in, ~forestDuckAmbi,
	\out, ~ambisonicsBus
]);
~frogAmbi = Synth.new(\frogSpace, [
	\in, ~forestFrogAmbi,
	\out, ~ambisonicsBus,
	\range, -pi,
	\spread, pi
]);
~owlAmbi = Synth.new(\owlSpace, [
	\in, ~forestOwlAmbi,
	\out, ~ambisonicsBus
]);
~realDuckAmbi = Synth.new(\realDuckSpace, [
	\in, ~forestRealDuckAmbi,
	\out, ~ambisonicsBus
]);
~realOwlAmbi = Synth.new(\realOwlSpace, [
	\in, ~forestRealOwlAmbi,
	\out, ~ambisonicsBus
]);
~realPeckerAmbi = Synth.new(\realPeckerSpace, [
	\in, ~forestRealPeckerAmbi,
	\out, ~ambisonicsBus
]);
~rainAmbi = Synth.new(\rainSpace, [
	\in, ~forestRainAmbi,
	\out, ~ambisonicsBus
]);

// Effects
~cricketHall = Synth.new(\peckerReverbGenerator, [
	\in, ~forestCricketFx,
	\out, ~forestCricketAmbi
]);
~duckHall = Synth.new(\forestReverbGenerator, [
	\in, ~forestDuckFx,
	\out, ~forestDuckAmbi
]);
~realDuckHall = Synth.new(\forestReverbGenerator, [
	\in, ~forestRealDuckFx,
	\out, ~forestRealDuckAmbi
]);
~frogHall = Synth.new(\forestReverbGenerator, [
	\in, ~forestFrogFx,
	\out, ~forestFrogAmbi
]);
~owlHall = Synth.new(\hallGenerator, [
	\in, ~forestOwlFx,
	\out, ~forestOwlAmbi
]);
~realOwlHall = Synth.new(\hallGenerator, [
	\in, ~forestRealOwlFx,
	\out, ~forestRealOwlAmbi
]);
~realPeckerHall = Synth.new(\forestReverbGenerator, [
	\in, ~forestRealPeckerFx,
	\out, ~forestRealPeckerAmbi
]);
~rainHall = Synth.new(\forestReverbGenerator, [
	\in, ~forestRainFx,
	\out, ~forestRainAmbi
]);

// Control the volume of the crickets
MIDIdef.cc(\ampCricket, {

	| val, num, chan, src |
	var amp;

	[val, num].postln;
	amp = val.linlin(0, 127, 0, 4);
	~cricket.set(\amp, amp);

}, 16);

// Control the duration of the crickets
MIDIdef.cc(\durCricket, {

	| val, num, chan, src |
	var dur;

	[val, num].postln;
	dur = val.linlin(0, 127, 0.25, 1.25);
	~cricket.set(\dur, dur);

}, 24);

// Control the volume of the ducks
MIDIdef.cc(\ampFrog, {

	| val, num, chan, src |
	var amp;

	[val, num].postln;
	amp = val.linlin(0, 127, 0, 1);
	~frog.set(\amp, amp);

}, 17);

/* MIDI CONTROLS */

// Control the volume of the ducks
MIDIdef.cc(\ampDuck, {

	| val, num, chan, src |
	var amp;

	[val, num].postln;
	amp = val.linlin(0, 127, 0, 1);
	~duck.set(\amp, amp);

}, 25);

// Control the volume of the owls
MIDIdef.cc(\ampOwl, {

	| val, num, chan, src |

	[val, num].postln;
	ampOwl = val.linlin(0, 127, 0, 1);
	ampOwl.postln;

}, 19);

// Control the duration of the owls
MIDIdef.cc(\durOwl, {

	| val, num, chan, src |

	[val, num].postln;
	durOwl = val.linlin(0, 127, 0, 1);
	durOwl.postln;

}, 27);

MIDIdef.cc(\spreadOwl, {

	| val, num, chan, src |
	var spread;

	[val, num].postln;
	spread = val.linlin(0, 127, -pi/2, pi/2);
	~owlAmbi.set(\spread, spread);

}, 20);

// Control the duration of the owls
MIDIdef.cc(\rangeOwl, {

	| val, num, chan, src |
	var range;

	[val, num].postln;
	range = val.linlin(0, 127, 0, pi);
	~owlAmbi.set(\range, range);

}, 28);

// Control the volume of the woodpecker
MIDIdef.cc(\ampPecker, {

	| val, num, chan, src |

	[val, num].postln;
	ampPecker = val.linlin(0, 127, 0, 1);
	ampPecker.postln;

}, 21);

// Control the volume of the woodpecker
MIDIdef.cc(\durPecker, {

	| val, num, chan, src |

	[val, num].postln;
	durPecker = val.linlin(0, 127, 0, 1);
	durPecker.postln;

}, 29);

// Control the volume of the rain
MIDIdef.cc(\ampRain, {

	| val, num, chan, src |
	var amp;

	[val, num].postln;
	amp = val.linlin(0, 127, 0, 1);
	~rain.set(\amp, amp);

}, 23);

// Control the volume of the rain
MIDIdef.cc(\ampWind, {

	| val, num, chan, src |
	var amp;

	[val, num].postln;
	amp = val.linlin(0, 127, 0, 1);
	~wind.set(\amp, amp);

}, 31);

// Trigger real owl by playing MIDI note
MIDIdef.noteOn(\triggerRealOwl, {

	| vel, nn, chan, src |

	[vel, nn, chan, src].postln;
	Synth.new(\bufPlaySynth, [
		\buf, ~realOwl.bufnum,
		\out, ~forestRealOwlFx
	]);

}, 37);

// Triger real duck by playing MIDI note
MIDIdef.noteOn(\triggerRealDuck, {

	| vel, nn, chan, src |

	[vel, nn, chan, src].postln;
	Synth.new(\bufPlaySynth, [
		\buf, ~realDuck.bufnum,
		\out, ~forestRealDuckFx
	]);

}, 38);

MIDIdef.noteOn(\triggerRealPecker, {

	| vel, nn, chan, src |

	[vel, nn, chan, src].postln;
	Synth.new(\bufPlaySynthStereo, [
		\buf, ~realPecker.bufnum,
		\out, ~forestRealPeckerFx
	]);

}, 39);

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

/* -- */

// Play the owl
~owl= Pbind(*[

	\instrument, \owlGenerator,
	\out, ~forestOwlFx,
	\sizefactor, Pwhite(0.0,1,inf),
	\delta, 10,
	\amp , Pfuncn({ ampOwl }, inf),
	\dur, Pfuncn({ durOwl }, inf),
	\freq, Pkey(\sizefactor).linexp(0, 1, 200, 300),
	\decay, Pkey(\sizefactor).linlin(0, 1, 1, 2),
	\doneAction, 2

]).play;

// Play the woodpecker
~pecker = Pbind(*[

	\instrument, \woodpeckerGenerator,
	\out, ~forestPeckerFx,
	\sizefactor, Pwhite(0.0,1,inf),
	\amp, Pfuncn({ ampPecker }, inf),
	\dur, Pgauss(0.1, 0.5, inf),
	\freq, Pkey(\sizefactor).linexp(0, 1, 50, 100),
	\decay, Pkey(\sizefactor).linlin(0, 1, 0, 1),
	\doneAction, 2,

]).play;
)

// Stop the forest
(
~cricket.free;
~duck.free;
~frog.free;
~owl.stop;
~pecker.stop;
~rain.free;
)