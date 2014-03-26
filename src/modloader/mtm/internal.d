/*
 *             Copyright Andrej Mitrovic 2014.
 *  Distributed under the Boost Software License, Version 1.0.
 *     (See accompanying file LICENSE_1_0.txt or copy at
 *           http://www.boost.org/LICENSE_1_0.txt)
 */
module modloader.mtm.internal;

import modloader.mtm.types : ChannelType, Module;

import modloader.util : ZCharArray;

///
package struct ModuleHeader
{
    ///
    @ZCharArray(3) string id;

    ///
    byte version_;

    ///
    @ZCharArray(20) string songName;

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
}

/// Fill the initial data from a Module header to a Module.
package Module toModule(ModuleHeader modHeader)
{
    Module result;

    with (result)
    {
        songName = modHeader.songName;
        channelType = modHeader.channelType;
        beatsPerTrack = modHeader.beatsPerTrack;
        panPositions = modHeader.panPositions;
    }

    return result;
}
