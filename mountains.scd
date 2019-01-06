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


(
SynthDef(\riverGenerator, {

	arg out=0, t_trig=0, attack=0.01, decay=0.08, freq=400, amp=0.1, pitchcurvelen=0.1, doneAction=2;
	var env, pitch, sig;

	env = amp * EnvGen.ar(Env.perc(attack, decay).delay(0.003), t_trig, doneAction: doneAction);
	pitch = freq * EnvGen.ar(Env.new([0,0,1],[0,1]).exprange(1, 2.718), t_trig, timeScale: pitchcurvelen);
	sig = SinOsc.ar(pitch);

	// Apply low-pass filter to the signal
	sig = LPF.ar(sig, 500) * env * 0.35;

	Out.ar(out, sig);

}).add
)

(
SynthDef(\, {

	arg out=0, t_trig=0, attack=0.01, decay=0.08, freq=400, amp=0.1, pitchcurvelen=0.1, doneAction=2;
	var env, pitch, sig;

	env = amp * EnvGen.ar(Env.perc(attack, decay).delay(0.003), t_trig, doneAction: doneAction);
	pitch = freq * EnvGen.ar(Env.new([0,0,1],[0,1]).exprange(1, 2.718), t_trig, timeScale: pitchcurvelen);
	sig = SinOsc.ar(pitch);

	// Apply low-pass filter to the signal
	sig = LPF.ar(sig, 500) * env * 0.35;

	Out.ar(out, sig);

}).add
)