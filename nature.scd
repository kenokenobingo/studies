/*****************************************



*****************************************/

s.boot;

// Wave Synth
(
SynthDef.new(\waveGenerator,{
	arg out = 0;
	var sig, env;
	env = EnvGen.kr(Env.new([0, 0.8, 0],[3, 2], [1,-1]), doneAction: 2);
	sig = PinkNoise.ar(1)!2;
	sig = sig * env;
	Out.ar(out, sig);
}).add;
)

//Bird Synth
(
SynthDef.new(\birdGenerator,{
	arg out = 0;
	var sig, env;
	env = EnvGen.kr(Env.new([0, 0.4, 0, 0.1], [0.1, 0.1], [1, -1]), doneAction: 2);
	sig = SinOsc.ar(660);
	Out.ar(out, sig);
}).add;
)

w = Synth.new(\waveGenerator);

b = Synth.new(\birdGenerator);