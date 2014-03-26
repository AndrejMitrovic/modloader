/*
 *             Copyright Andrej Mitrovic 2014.
 *  Distributed under the Boost Software License, Version 1.0.
 *     (See accompanying file LICENSE_1_0.txt or copy at
 *           http://www.boost.org/LICENSE_1_0.txt)
 */
module modloader.mtm.types;

import modloader.util : SkipLoad, ZCharArray;

///
enum ChannelType : ubyte { invalid = ubyte.max, bit8 = 0x00, bit16 = 0x01, }

///
struct Module
{
    ///
    @ZCharArray(3)
    string id;

    ///
    byte version_;

    ///
    @ZCharArray(20)
    string songName;

    ///
    ushort numTracks;

    ///
    ubyte lastPattern;

    ///
    ubyte lastOrder;

    ///
    @property ubyte numOfOrders()
    {
        import std.conv : to;
        return to!ubyte(lastOrder + 1);
    }

    ///
    short commentSize;

    ///
    ubyte numSamples;

    ///
    @property ubyte numOfPatterns()
    {
        import std.conv : to;
        return to!ubyte(lastPattern + 1);
    }

    ///
    ChannelType channelType;

    ///
    ubyte beatsPerTrack;

    ///
    ubyte numChannels;

    ///
    ubyte[32] panPositions;

    ///
    @SkipLoad Sample[] samples;

    ///
    @SkipLoad Track[] tracks;

    ///
    @SkipLoad Pattern[] patterns;

    ///
    @SkipLoad ubyte[] patternOrders;

    ///
    @SkipLoad string comment;

    ///
    string toString()
    {
        import std.string : format;

        return format(
            "%-10s: %s\n"
            "%-10s: %s\n"
            "%-10s: %s\n"
            "%-10s: %s\n",

            "song_name", songName,
            "samples",   samples.length,
            "tracks",    tracks.length,
            "patterns",  patterns.length,
        );
    }
}

///
enum SampleType : ubyte { invalid = ubyte.max, bit8 = 0x00, bit16 = 0x01, }

///
struct Sample
{
    ///
    @ZCharArray(22)
    string sampleName;

    ///
    uint length;

    ///
    uint loopStart;

    ///
    uint loopEnd;

    ///
    byte fineTune;

    ///
    ubyte volume;

    ///
    SampleType sampleType;

    ///
    @SkipLoad ubyte[] sampleData;
}

///
struct TrackRow
{
    import std.bitmanip : bitfields;

    ///
    mixin(bitfields!(
        uint, "pitchValue", 6,
        uint, "instrumentNumber", 6,
        uint, "effectNumber", 4));

    ///
    ubyte effectArgument;

    ///
    string toString()
    {
        import std.string : format;

        return format("%s: %3s %s: %3s %s: %3s %s: %3s",
            "pitchValue",       pitchValue,
            "instrumentNumber", instrumentNumber,
            "effectNumber",     effectNumber,
            "effectArgument",   effectArgument);
    }
}

///
enum RowCount = 64;

///
struct Track
{
    ///
    TrackRow[RowCount] rows;
}

///
enum VoiceCount = 32;

///
struct Pattern
{
    ///
    short[VoiceCount] voices;

    ///
    string toString()
    {
        import std.string : format;
        return format("%(%3s %)", voices);
    }
}
