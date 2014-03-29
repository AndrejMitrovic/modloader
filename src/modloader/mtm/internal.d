/*
 *             Copyright Andrej Mitrovic 2014.
 *  Distributed under the Boost Software License, Version 1.0.
 *     (See accompanying file LICENSE_1_0.txt or copy at
 *           http://www.boost.org/LICENSE_1_0.txt)
 */
module modloader.mtm.internal;

import modloader.mtm.types : ChannelType, Module, Sample, SampleType, TrackRow;

import modloader.util : ZCharArray;

package struct ModuleInternal
{
    @ZCharArray(3)
    string id;

    byte version_;

    @ZCharArray(20)
    string songName;

    ushort numTracks;

    ubyte lastPattern;

    ubyte lastOrder;

    @property ubyte numOfOrders()
    {
        import std.conv : to;
        return to!ubyte(lastOrder + 1);
    }

    short commentSize;

    ubyte numSamples;

    @property ubyte numOfPatterns()
    {
        import std.conv : to;
        return to!ubyte(lastPattern + 1);
    }


    ChannelType channelType;

    ubyte beatsPerTrack;

    ubyte numChannels;

    ubyte[32] panPositions;
}

package Module toModule(ModuleInternal input)
{
    typeof(return) result;

    with (result)
    {
        songName = input.songName;
        channelType = input.channelType;
        beatsPerTrack = input.beatsPerTrack;
        panPositions = input.panPositions;
    }

    return result;
}

package struct TrackRowInternal
{
    ubyte[3] bytes;

    // Note: Unusable, file format uses Big-Endian encoding.
    /+ import std.bitmanip : bitfields;

    mixin(bitfields!(
        uint, "pitchValue", 6,
        uint, "instrumentNumber", 6,
        uint, "effectNumber", 4));


    ubyte effectArgument; +/
}

package TrackRow toTrackRow(TrackRowInternal input)
{
    import std.conv : to;

    typeof(return) result;

    // Note: Unusable, file format uses Big-Endian encoding.
    /+ with (result)
    {
        pitchValue = input.pitchValue.to!ubyte;
        instrumentNumber = input.instrumentNumber.to!ubyte;
        effectNumber = input.effectNumber.to!ubyte;
        effectArgument = input.effectArgument;
    } +/

    with (result)
    {
        if (input.bytes[0] & 0xFC)
            pitchValue = (input.bytes[0] >> 2);

        instrumentNumber = ((input.bytes[0] & 0x03) << 4) | (input.bytes[1] >> 4);
        effectNumber = input.bytes[1] & 0x0F;
        effectArgument = input.bytes[2];
    }

    return result;
}

package struct SampleInternal
{
    @ZCharArray(22)
    string sampleName;

    uint length;

    uint loopStart;

    uint loopEnd;

    byte fineTune;

    ubyte volume;

    SampleType type;
}

package Sample toSample(SampleInternal input)
{
    typeof(return) result;

    with (result)
    {
        sampleName = input.sampleName;
        length = input.length;
        loopStart = input.loopStart;
        loopEnd = input.loopEnd;
        fineTune = input.fineTune;
        volume = input.volume;
        type = input.type;
    }

    return result;
}
