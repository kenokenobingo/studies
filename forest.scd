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

(
SynthDef(\woodpeckerGenerator, {

	arg out=0, t_trig=0, attack=0.01, decay=0.08, pitchcurvelen=0.1, freq=400, doneAction=0, amp=0.1;
	var pitch, sig, env;

	env = amp * EnvGen.ar(Env.perc(attack, decay).delay(0.003), t_trig, doneAction: doneAction);
	pitch = freq * EnvGen.ar(Env.new([0,0,1],[0,1]).exprange(1, 2.718), t_trig, timeScale: pitchcurvelen);
	sig = SinOsc.ar(pitch);

	// Apply low-pass filter and reverb
	sig = LPF.ar(sig, 500) * env * 10;
	f = JPverb.ar(sig, 5, 0, 1, 0, 0);

	sig = Pan2.ar((sig + (f * 0.5)), 1);
	Out.ar(out, sig);
}).add
)