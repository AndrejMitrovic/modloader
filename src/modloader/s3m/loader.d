/*
 *             Copyright Andrej Mitrovic 2014.
 *  Distributed under the Boost Software License, Version 1.0.
 *     (See accompanying file LICENSE_1_0.txt or copy at
 *           http://www.boost.org/LICENSE_1_0.txt)
 */
module modloader.s3m.loader;

//~ import std.algorithm : filter;
import std.conv      : text;
import std.exception : enforce;

import modloader.util : modDir, streamFile, ZCharArray;

import modloader.s3m.internal :
    ModuleHeaderSize,
    SamplesHeaderSize,
    ModuleInternal,
    ScreamTrackerTag,
    toModule
    //~ toModule,
    //~ TrackRowInternal, toTrackRow,
    //~ SampleInternal,   toSample
    ;

import modloader.s3m.types : Module;
//~ import modloader.s3m.util  : decodeComment, toSampleSize;

/**
    Read a Scream Tracker 3 Module file.

    S3M Reference:
    ftp://ftp.modland.com/pub/documents/format_documentation/Scream Tracker v3.20 (.s3m).html
    ftp://ftp.modland.com/pub/documents/format_documentation/Scream Tracker v3.20 effects (.s3m).txt
*/
Module readS3M(string path)
{
    //~ import std.array : uninitializedArray;
    import std.stdio : stderr, writefln, writeln, writef, write;
    import std.string : format;

    auto file = path.streamFile;
    enforce(file.size > 0);

    enforce(file.size > ModuleHeaderSize + SamplesHeaderSize + 64, file.size.text);

    auto modInternal = file.read!ModuleInternal;

    enforce(modInternal.scrm == ScreamTrackerTag, "%X".format(modInternal.scrm));

    auto mod = modInternal.toModule();

    //~ enum HeaderSize = 66;
    //~ enforce(file.pos == HeaderSize);

    //~ enum SampleByteSize = 37;
    //~ enum PatternOrderSize = 128;
    //~ enum TrackByteSize = 64 * 3;
    //~ enum PatternByteSize = 32 * short.sizeof;

    //~ const totalBytes = HeaderSize +
                       //~ SampleByteSize * modInternal.numSamples +
                       //~ PatternOrderSize +
                       //~ TrackByteSize * modInternal.numTracks +
                       //~ PatternByteSize * modInternal.numOfPatterns +
                       //~ modInternal.commentSize;

    //~ enforce(totalBytes < file.size);

    //~ mod.samples = uninitializedArray!(Sample[])(modInternal.numSamples);

    //~ foreach (ref sample; mod.samples)
    //~ {
        //~ sample = file.read!SampleInternal.toSample;
    //~ }

    //~ enforce(file.pos == 0x42 + modInternal.numSamples * SampleByteSize);

    //~ mod.sequence = file.read!(ubyte[128])[0 .. modInternal.numOfOrders].dup;

    //~ enforce(file.pos == 0xC2 + modInternal.numSamples * SampleByteSize);

    //~ mod.tracks = uninitializedArray!(Track[])(modInternal.numTracks);

    //~ foreach (ref track; mod.tracks)
    //~ {
        //~ foreach (ref row; track.rows)
        //~ {
            //~ row = file.read!TrackRowInternal.toTrackRow;
        //~ }
    //~ }

    //~ enforce(file.pos == 0xC2 +
            //~ modInternal.numSamples * SampleByteSize +
            //~ modInternal.numTracks * TrackByteSize);

    //~ mod.patterns = uninitializedArray!(Pattern[])(modInternal.numOfPatterns);
    //~ foreach (ref pattern; mod.patterns)
    //~ {
        //~ pattern = file.read!Pattern;
    //~ }

    //~ enforce(file.pos == 0xC2 +
            //~ modInternal.numSamples * SampleByteSize +
            //~ modInternal.numTracks * TrackByteSize +
            //~ modInternal.numOfPatterns * PatternByteSize);

    //~ mod.comment = file.read!(char[])(modInternal.commentSize).decodeComment().idup;

    //~ enforce(file.pos == 0xC2 +
            //~ modInternal.numSamples * SampleByteSize +
            //~ modInternal.numTracks * TrackByteSize +
            //~ modInternal.numOfPatterns * PatternByteSize +
            //~ modInternal.commentSize);

    //~ foreach (ref sample; mod.samples.filter!(a => a.length))
    //~ {
        //~ size_t byteCount = sample.length * sample.type.toSampleSize;
        //~ enforce(byteCount, sample.text);

        //~ sample.data = uninitializedArray!(ubyte[])(byteCount);
        //~ file.readTo(sample.data);
    //~ }

    //~ enforce(file.end);

    return mod;
}

///
version (TestModloader)
unittest
{
    import std.path : buildPath;
    import std.stdio : writeln;

    //~ import modloader.s3m.util : prettyPrint;

    foreach (modFile; testModFiles)
    {
        auto mod = modDir.buildPath(modFile).readS3M;
        //~ mod.prettyPrint();
    }
}

version (unittest)
private immutable testModFiles =
[
    "sine_mod.s3m",
];
