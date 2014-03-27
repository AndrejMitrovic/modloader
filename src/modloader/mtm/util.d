/*
 *             Copyright Andrej Mitrovic 2014.
 *  Distributed under the Boost Software License, Version 1.0.
 *     (See accompanying file LICENSE_1_0.txt or copy at
 *           http://www.boost.org/LICENSE_1_0.txt)
 */
module modloader.mtm.util;

import modloader.mtm.types : Module, RowCount, SampleType;

/// MTM comments have their own encoding.
package char[] decodeComment(char[] input)
{
    foreach (idx, ref char ch; input)
    {
        if (!ch)
            ch = (idx + 1) % 40 ? 0x20 : 0x0D;
    }

    return input;
}

/// Get the byte count for the sample type.
package size_t toSampleSize(SampleType sampleType)
{
    switch (sampleType) with (SampleType)
    {
        case ubit8:
            return 1;

        case ubit16:
            return 2;

        default:
            assert(0);
    }
}

// Period table for Protracker octaves 0-5:
private immutable short[6 * 12] ProTrackerPeriodTable =
[
    1712, 1616, 1524, 1440, 1356, 1280, 1208, 1140, 1076, 1016, 960, 907,
    856, 808, 762, 720, 678, 640, 604, 570, 538, 508, 480, 453,
    428, 404, 381, 360, 339, 320, 302, 285, 269, 254, 240, 226,
    214, 202, 190, 180, 170, 160, 151, 143, 135, 127, 120, 113,
    107, 101, 95, 90, 85, 80, 75, 71, 67, 63, 60, 56,
    53, 50, 47, 45, 42, 40, 37, 35, 33, 31, 30, 28
];

private size_t pitchToNote(uint pitch)
{
    import std.stdio;
    stderr.writefln("Pitch: %s", pitch);

    if (!pitch)
        return 0;

    for (size_t i = 0; i < ProTrackerPeriodTable.length; i++)
    {
        if (pitch >= ProTrackerPeriodTable[i])
        {
            if (i && pitch != ProTrackerPeriodTable[i])
            {
                auto p1 = ProTrackerPeriodTable[i - 1];
                auto p2 = ProTrackerPeriodTable[i];

                if (p1 - pitch < (pitch - p2))
                    return i + 36;
            }
            return i + 1 + 36;
        }
    }

    return 6 * 12 + 36;
}

/// Pretty-print a module as if displayed in a tracker
package void prettyPrint(Module mod)
{
    import std.algorithm : map;
    import std.stdio : write, writeln, writef, writefln;
    import std.typecons : tuple;

    version (none)
    {
        writeln("Sequence:");
        writeln("--------------");

        size_t seqIdx;
        foreach (patIdx, pattern; mod.sequence.map!(idx => tuple(idx, mod.patterns[idx])))
        {
            writefln("[%.2s] Pattern %s", seqIdx, patIdx);
            ++seqIdx;
        }

        writeln("--------------");
        writeln();
    }

    writeln("Patterns:");
    writeln();

    foreach (patIdx, pattern; mod.patterns[3 .. 4])
    {
        writefln("Pattern %s:", patIdx);
        writeln("--------------");

        foreach (rowIdx; 0 .. RowCount)
        {
            size_t chanIdx = 1;

            foreach (voiceIdx; pattern.voices)
            {
                if (voiceIdx == 0)
                {
                    write("--- ");
                }
                else
                {
                    auto note = mod.tracks[voiceIdx - 1].rows[rowIdx].pitchValue;
                    if (note != 0)
                    {
                        static immutable chars = ["C-", "C#", "D-", "D#", "E-", "F-", "F#", "G-", "G#", "A-", "A#", "B-"];
                        static assert(chars.length == 12);

                        writef("%s%s ", chars[note % 12], (note / 12) + 3);
                    }
                    else
                    {
                        write("--- ");
                    }
                }

                ++chanIdx;
            }

            writeln();
        }

        writeln("--------------");
        writeln();

        //~ break;
    }
}
