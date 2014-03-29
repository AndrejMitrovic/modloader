/*
 *             Copyright Andrej Mitrovic 2014.
 *  Distributed under the Boost Software License, Version 1.0.
 *     (See accompanying file LICENSE_1_0.txt or copy at
 *           http://www.boost.org/LICENSE_1_0.txt)
 */
module modloader.s3m.internal;

import std.bitmanip : littleEndianToNative, bigEndianToNative;

import modloader.s3m.types : Module
//~ ChannelType, Sample, SampleType, TrackRow
;

import modloader.util : Converter, ZCharArray, PartialTempl;

/// Internal byte-swap attribute
private alias ConvertLE(Type) = Converter!(
    PartialTempl!(littleEndianToNative, Type),
    ubyte[Type.sizeof]
);

/// ditto
private alias ConvertLE(alias symbol) = ConvertLE!(typeof(symbol));

package enum ScreamTrackerTag = 0x4D524353;

package struct ModuleInternal
{
    @ZCharArray(28)
    string name;

    ubyte b1A;

    ubyte type;

    @ConvertLE!ushort
    {
        ushort reserved1;

        ushort ordnum;

        ushort insnum;

        ushort patnum;

        ushort flags;

        ushort cwtv;

        ushort version_;
    }

    @ConvertLE!scrm
    uint scrm;

    ubyte globalvol;

    ubyte speed;

    ubyte tempo;

    ubyte mastervol;

    ubyte ultraclicks;

    ubyte panning_present;

    ubyte[8] reserved2;

    ushort special;

    ubyte[32] channels;
}

///
package Module toModule(ModuleInternal input)
{
    typeof(return) result;

    with (result)
    {
        songName = input.name;
    }

    return result;
}

package enum ModuleHeaderSize = 96;

package struct SamplesInternal
{
    ubyte type;

    @ZCharArray(12)
    string dosname;

    ubyte hmem;

    ushort memseg;

    uint length;

    uint loopbegin;

    uint loopend;

    ubyte vol;

    ubyte bReserved;

    ubyte pack;

    ubyte flags;

    uint finetune;

    uint dwReserved;

    ushort intgp;

    ushort int512;

    uint lastused;

    @ZCharArray(28)
    string name;

    @ZCharArray(4)
    string scrs;
}

package enum SamplesHeaderSize = 80;

//~ ///
//~ package TrackRow toTrackRow(TrackRowInternal input)
//~ {
    //~ import std.conv : to;

    //~ typeof(return) result;

    //~ /+ with (result)
    //~ {
        //~ pitchValue = input.pitchValue.to!ubyte;
        //~ instrumentNumber = input.instrumentNumber.to!ubyte;
        //~ effectNumber = input.effectNumber.to!ubyte;
        //~ effectArgument = input.effectArgument;
    //~ } +/

    //~ with (result)
    //~ {
        //~ if (input.bytes[0] & 0xFC)
            //~ pitchValue = (input.bytes[0] >> 2);

        //~ instrumentNumber = ((input.bytes[0] & 0x03) << 4) | (input.bytes[1] >> 4);
        //~ effectNumber = input.bytes[1] & 0x0F;
        //~ effectArgument = input.bytes[2];
    //~ }

    //~ return result;
//~ }

//~ ///
//~ package Sample toSample(SampleInternal input)
//~ {
    //~ typeof(return) result;

    //~ with (result)
    //~ {
        //~ sampleName = input.sampleName;
        //~ length = input.length;
        //~ loopStart = input.loopStart;
        //~ loopEnd = input.loopEnd;
        //~ fineTune = input.fineTune;
        //~ volume = input.volume;
        //~ type = input.type;
    //~ }

    //~ return result;
//~ }
