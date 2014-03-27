/*
 *             Copyright Andrej Mitrovic 2014.
 *  Distributed under the Boost Software License, Version 1.0.
 *     (See accompanying file LICENSE_1_0.txt or copy at
 *           http://www.boost.org/LICENSE_1_0.txt)
 */
module modloader.mtm.types;

///
enum ChannelType : ubyte
{
    invalid = ubyte.max, /// sentinel
    ubit8   = 0x00,      ///
    ubit16  = 0x01,      ///
}

/**
    An MTM module is composed out of:

    - A sequence, which holds the indices of patterns to be played in that order,
    where patterns can be played multiple times.

    - A set of unique patterns. Each pattern holds a $(D VoiceCount) amount of indices to
    tracks (channels/voices).

    - Tracks (channels/voices). Each track is composed out of note and effect commands.
    It contains $(D RowCount) amount of these commands.
*/
struct Module
{
    ///
    string songName;

    ///
    ChannelType channelType;

    ///
    ubyte beatsPerTrack;

    ///
    ubyte[VoiceCount] panPositions;

    ///
    Sample[] samples;

    /// Also known as channels/voices.
    /// Each track is has a sequence of note and effect data.
    Track[] tracks;

    /// Each pattern is composed of a maximum of VoiceCount
    /// amount of tracks (channels/voices). Each pattern holds
    /// indices of the tracks (channels/voices) that it uses.
    Pattern[] patterns;

    ///
    alias PatternIdx = ubyte;

    /// This is the sequence of the entire track.
    /// The sequence is composed of patterns being
    /// organized in any order and can be repeated.
    /// E.g.: [0, 1, 1, 2] would play back the
    /// patterns at those indices.
    PatternIdx[] sequence;

    ///
    string comment;

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
enum SampleType : ubyte
{
    invalid = ubyte.max, /// sentinel
    ubit8   = 0x00,      ///
    ubit16  = 0x01,      ///
}

///
struct Sample
{
    ///
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
    SampleType type;

    ///
    ubyte[] data;
}

///
struct TrackRow
{
    ///
    ubyte pitchValue;

    ///
    ubyte instrumentNumber;

    ///
    ubyte effectNumber;

    ///
    ubyte effectArgument;

    ///
    string toString()
    {
        import std.string : format;

        return format("%s: %3s  %s: %3s  %s: %3s  %s: %3s",
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

    ///
    string toString()
    {
        import std.string : format;
        return format("%(%s \n%)", rows);
    }
}

///
enum VoiceCount = 32;

///
struct Pattern
{
    ///
    alias TrackIdx = short;

    /// Which track is used as which voice in this pattern.
    /// Note that this is a 1-based index. When any TrackIdx is
    /// 0 it means the track is empty.
    TrackIdx[VoiceCount] voices;

    ///
    string toString()
    {
        string result;
        import std.string : stripRight, format;

        foreach (idx, voice; voices)
            result ~= "%s: %s ".format(idx, voice);

        return result.stripRight;
    }
}
