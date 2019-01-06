/*
 *                   _
 *   _ __ ___   __ _(_)_ __
 *  | '_ ` _ \ / _` | | '_ \
 *  | | | | | | (_| | | | | |
 *  |_| |_| |_|\__,_|_|_| |_|
 *
 *
 *  #+METHOD: Simulation as in `SimCity for Nature`
 *  #+AUTHOR: K E N O
 *  #+TITLE: Start up a SuperCollider server.
 *  #+TOOL: SuperCollider
 *
 */


/************************************************************
 *
 *   ___  ___ _ ____   _____ _ __
 *  / __|/ _ \ '__\ \ / / _ \ '__|
 *  \__ \  __/ |   \ V /  __/ |
 *  |___/\___|_|    \_/ \___|_|
 *
 ************************************************************/

(
// Increase the server’s allocated memory
s.options.memSize = 1000000;
// Increase the number of the server’s input and output busses
s.options.numInputBusChannels = 8;
s.options.numOutputBusChannels = 8;
// Boot the SuperCollider server
s.boot;
)


/************************************************************
 *             _     _ _
 *   _ __ ___ (_) __| (_)
 *  | '_ ` _ \| |/ _` | |
 *  | | | | | | | (_| | |
 *  |_| |_| |_|_|\__,_|_|
 *
 ************************************************************/

(
MIDIClient.init;
MIDIIn.connectAll;
)