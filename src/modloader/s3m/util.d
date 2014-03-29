/*
 *             Copyright Andrej Mitrovic 2014.
 *  Distributed under the Boost Software License, Version 1.0.
 *     (See accompanying file LICENSE_1_0.txt or copy at
 *           http://www.boost.org/LICENSE_1_0.txt)
 */
module modloader.s3m.util;

//~ import modloader.mtm.types : Module, RowCount, SampleType;

//~ /// MTM comments have their own encoding.
//~ package char[] decodeComment(char[] input)
//~ {
    //~ foreach (idx, ref char ch; input)
    //~ {
        //~ if (!ch)
            //~ ch = (idx + 1) % 40 ? 0x20 : 0x0D;
    //~ }

    //~ return input;
//~ }

//~ /// Get the byte count for the sample type.
//~ package size_t toSampleSize(SampleType sampleType)
//~ {
    //~ switch (sampleType) with (SampleType)
    //~ {
        //~ case ubit8:
            //~ return 1;

        //~ case ubit16:
            //~ return 2;

        //~ default:
            //~ assert(0);
    //~ }
//~ }

//~ private immutable noteNames = ["C-", "C#", "D-", "D#", "E-", "F-", "F#", "G-", "G#", "A-", "A#", "B-"];
//~ static assert(noteNames.length == 12);

//~ /// Pretty-print a module as if displayed in a tracker.
//~ package void prettyPrint(Module mod)
//~ {
    //~ import std.algorithm : map;
    //~ import std.stdio : write, writeln, writef, writefln;
    //~ import std.typecons : tuple;

    //~ version (none)
    //~ {
        //~ writeln("Sequence:");
        //~ writeln("--------------");

        //~ size_t seqIdx;
        //~ foreach (patIdx, pattern; mod.sequence.map!(idx => tuple(idx, mod.patterns[idx])))
        //~ {
            //~ writefln("[%.2s] Pattern %s", seqIdx, patIdx);
            //~ ++seqIdx;
        //~ }

        //~ writeln("--------------");
        //~ writeln();
    //~ }

    //~ writeln("Patterns:");
    //~ writeln();

    //~ import std.range : join, repeat;

    //~ foreach (patIdx, pattern; mod.patterns)
    //~ {
        //~ writefln("Pattern %s:", patIdx);
        //~ writeln("==========\n");

        //~ enum printChannelCount = 8;

        //~ foreach (i; 0 .. printChannelCount)
            //~ writef("C-%s ", i);
        //~ writeln();

        //~ writeln("=".repeat(printChannelCount * 4 - 1).join);

        //~ foreach (rowIdx; 0 .. RowCount)
        //~ {
            //~ size_t chanIdx = 1;

            //~ foreach (voiceIdx; pattern.voices[0 .. printChannelCount])
            //~ {
                //~ if (voiceIdx == 0)
                //~ {
                    //~ write("--- ");
                //~ }
                //~ else
                //~ {
                    //~ auto note = mod.tracks[voiceIdx - 1].rows[rowIdx].pitchValue;
                    //~ if (note != 0)
                    //~ {
                        //~ writef("%s%s ", noteNames[note % 12], (note / 12) + 3);
                    //~ }
                    //~ else
                    //~ {
                        //~ write("--- ");
                    //~ }
                //~ }

                //~ ++chanIdx;
            //~ }

            //~ writeln();
        //~ }

        //~ writeln();
    //~ }
//~ }
