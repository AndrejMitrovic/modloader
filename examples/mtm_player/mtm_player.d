/*
 *             Copyright Andrej Mitrovic 2014.
 *  Distributed under the Boost Software License, Version 1.0.
 *     (See accompanying file LICENSE_1_0.txt or copy at
 *           http://www.boost.org/LICENSE_1_0.txt)
 */
module mtm_player;

/*
Run via:
rdmd -Isrc -I..\RtAudioD\src -I..\wkBindKeys -unittest ..\RtAudioD\implib\dsound.lib examples\mtm_player\mtm_player.d examples\modules\modern_society.mtm 2 0
*/

// Tick duration is 20ms.

// Each row will play for 6 ticks.
// 4 rows equals 1 beat.
// 1 beat is done in 4 * 6 ticks == 24 ticks.

// IOW: 24 ticks per beat

// Each row is done in 120 msecs.
// => that's all we need really.

// Each beat is done in 480 msecs.

// 60 seconds / 0.480 seconds = 125 beats per minute.

// Tick duration in milliseconds of a BMP is:
// 2500 / BPM

// Row time duration in milliseconds is:
// (2500 / BPM) * 6

// To conver this to samples we do:
// 44100 samples per second:
//
// 50 ticks per second.
// 44100 / 50
// 882 samples per tick
//
// samples per row:
// 882 * 6:
// 5292 samples per row

// 735 samples per millisecond
// 735 * tick duration (20 msecs) =
// 14700 samples before a single tick duration is done.

// which means a row is done in:
// 14700 * 6 = 88200 samples

pragma(lib, "winmm.lib");

import rtaudio;

import modloader.mtm;

import core.stdc.stdlib;
import core.thread;

import std.algorithm;
import std.conv;
import std.exception;
import std.stdio;
import std.range;
import std.typetuple;

enum SampleRate = 44100;

/// The format type used in our callbacks (use only int8/int16 formats for most devices).
enum DeviceFormatType = RtAudioFormat.int16;

/// Sample type based on the selected format type.
private alias DeviceSampleType = GetSampleType!DeviceFormatType;

immutable ProTrackerPeriodTable =
[
    //~ 8363, 8860, 9387, 9945, 10537, 11163, 11827, 12530, 13257, 14065, 14901, 15787, 16726
    1712, 1616, 1524, 1440, 1356, 1280, 1208, 1140, 1076, 1016, 960, 907,
    856, 808, 762, 720, 678, 640, 604, 570, 538, 508, 480, 453,
    428, 404, 381, 360, 339, 320, 302, 285, 269, 254, 240, 226,
    214, 202, 190, 180, 170, 160, 151, 143, 135, 127, 120, 113,
    107, 101, 95, 90, 85, 80, 75, 71, 67, 63, 60, 56,
    53, 50, 47, 45, 42, 40, 37, 35, 33, 31, 30, 28
];

float getFrequency(ubyte pitch)
{
    return ProTrackerPeriodTable[pitch];
}

struct Stride
{
    this(ubyte[] data, float phaseIncrement)
    {
        this.data = data;
        this.phaseIncrement = phaseIncrement;
    }

    /** Linear interpolation. */
    @property ubyte front()
    {
        float fIndex = getIndex();
        int index    = cast(int)fIndex;
        float fract  = fIndex - index;

        alias toFloat = toSampleType!float;
        alias toUbyte = toSampleType!ubyte;

        float lo = toFloat(data[index]);
        float hi = toFloat(data[index + 1]);

        float val = lo + fract * (hi - lo);

        return toUbyte(val);
    }

    private float getIndex()
    {
        return phase * data.length;
    }

    @property bool empty()
    {
        return cast(size_t)(getIndex() + 1) >= data.length;
    }

    @property void popFront()
    {
        phase += phaseIncrement;
    }

    @property void popFrontNumber(size_t count)
    {
        foreach (i; 0 .. count)
            phase += phaseIncrement;
    }

    Stride save()
    {
        return this;
    }

private:
    float phase = 0;

private:
    /* const */ ubyte[] data;
    /* const */ float phaseIncrement;
}

Stride stride(ubyte[] data, float step)
{
    return Stride(data, step);
}

struct Voice
{
    this(ubyte pitch, ubyte[] data)
    {
        auto freq = getFrequency(pitch);
        auto phaseIncrement = 80 * (freq / (cast(float)data.length * cast(float)SampleRate));
        range = Stride(data, phaseIncrement);
    }

    auto peek(size_t count)
    {
        return range.save.take(count);
    }

    void advance(size_t count)
    {
        range.popFrontNumber(count);
    }

private:
    Stride range;
}

/// Temporary data the callback reads and manipulates, which avoids the use of globals.
struct CallbackData
{
    size_t sampleRate;

    size_t channelCount;

    bool doCheckSampleCount;
    size_t curSampleCount;
    size_t maxSampleCount;

    size_t samplesPerRow;
    size_t curRowCount = size_t.max;

    Voice[VoiceCount] voices;

    ///
    Module mod;
}

// todo: we need to return proper status codes as defined in RtAudio, use an enum and re-define
// the callback as returning the enum rather than an int.
enum StatusCode
{
    ok = 0,
    outOfFrames = 1
}

///
int audio_callback(void* outputBuffer, void* /*inputBuffer*/, size_t sampleCount,
                   double /*streamTime*/, RtAudioStreamStatus status, void* userData)
{
    CallbackData* data = cast(CallbackData*)userData;
    DeviceSampleType[] buffer = (cast(DeviceSampleType*)outputBuffer)[0 .. (data.channelCount * sampleCount)];

    if (status)
        writeln("Stream underflow detected!");

    play_non_interleaved(buffer, sampleCount, data);

    data.curSampleCount += sampleCount;

    if (data.doCheckSampleCount && data.curSampleCount >= data.maxSampleCount)
        return StatusCode.outOfFrames;

    return StatusCode.ok;
}

///
alias convert = toSampleType!DeviceSampleType;

///
void play_non_interleaved(DeviceSampleType[] buffer, size_t sampleCount, CallbackData* data)
{
    size_t curRowCount = data.curSampleCount / data.samplesPerRow;

    // play a new row
    if (curRowCount != data.curRowCount)
    {
        const seqIdx = curRowCount / RowCount;
        const patIdx = data.mod.sequence[seqIdx];
        const pattern = data.mod.patterns[patIdx];

        const curRow = curRowCount % RowCount;

        foreach (chanIdx, channel; pattern.voices)
        {
            if (channel == 0)
                continue;  // empty channel

            const noteData = data.mod.tracks[channel - 1].rows[curRow];

            const instrument = noteData.instrumentNumber;
            if (instrument == 0)
                continue;  // no instrument number

            const note = noteData.pitchValue;
            if (note == 0)
                continue;  // no note data

            static immutable noteNames = ["C-", "C#", "D-", "D#", "E-", "F-", "F#", "G-", "G#", "A-", "A#", "B-"];
            import std.string;

            const noteName = format("%s%s", noteNames[note % 12], (note / 12) + 3);
            stderr.writefln("new note %s %s at row %s for pattern %s sequence %s", note, noteName, curRow, patIdx, seqIdx);

            auto sample = data.mod.samples[instrument - 1];

            // load data
            data.voices[chanIdx] = Voice(note, sample.data);
        }
    }

    data.curRowCount = curRowCount;

    foreach (ref channelBuffer; buffer.chunks(sampleCount))
    {
        channelBuffer[] = 0;

        foreach (voiceIdx, ref voice; data.voices)
        {
            auto buff = voice.peek(channelBuffer.length);

            foreach (inSample, ref outSample; lockstep(buff, channelBuffer))
                outSample += inSample.convert / data.voices.length;
        }
    }

    // remove the data from the voice buffers
    foreach (ref voice; data.voices)
        voice.advance(sampleCount);
}

///
int main(string[] args)
{
    import core.memory;
    GC.disable();
    scope (exit)
        GC.enable();

    // minimal command-line checking
    if (args.length < 3 || args.length > 6)
    {
        printUsage();
        return 1;
    }

    RtAudio dac = new RtAudio();

    if (dac.getDeviceCount() < 1)
    {
        writeln("\nNo audio devices found!\n");
        return 1;
    }

    size_t sampleCount, device, offset;

    CallbackData data;

    data.mod = readMTM(args[1]);

    data.channelCount = to!size_t(args[2]);

    data.sampleRate = SampleRate;

    enum ticksPerMinute = 50;  // 50 hz as in old Amiga hardware

    enum ticksPerRow = 6;

    enum rowsPerBeat = 4;

    enum ticksPerBeat = ticksPerRow * rowsPerBeat;

    static assert(ticksPerBeat == 24);

    const samplesPerTick = data.sampleRate / ticksPerMinute;

    const samplesPerRow = samplesPerTick * ticksPerRow;

    data.samplesPerRow = samplesPerRow;

    const samplesPerPattern = samplesPerRow * RowCount;

    data.maxSampleCount = data.mod.sequence.length * samplesPerPattern;

    enum startPattern = 7;

    data.curSampleCount = samplesPerPattern * min(startPattern, data.mod.sequence.length);

    // todo: add check for module channel count
    // enforce(data.flacHeader.numChannels == data.channelCount);  // hardcode for now

    if (args.length > 3)
        device = to!size_t(args[3]);

    if (args.length > 4)
        offset = to!size_t(args[4]);

    if (data.maxSampleCount > 0)
        data.doCheckSampleCount = true;

    // Let RtAudio print messages to stderr.
    dac.showWarnings(true);

    // Set our stream parameters for output only.
    enum inParams = null;

    sampleCount = 512;  // desired frame count
    StreamParameters oParams;
    oParams.deviceId     = device;
    oParams.nChannels    = data.channelCount;
    oParams.firstChannel = offset;

    StreamOptions options;
    options.flags  = StreamFlags.hog_device;
    options.flags |= StreamFlags.schedule_realtime;
    options.flags |= StreamFlags.non_interleaved;

    dac.openStream(&oParams, inParams, DeviceFormatType, data.sampleRate, &sampleCount,
                   &audio_callback, &data, &options);

    dac.startStream();

    scope (exit)
    {
        if (dac.isStreamOpen())
            dac.closeStream();
    }

    if (data.doCheckSampleCount)
    {
        while (dac.isStreamRunning() == true)
            Thread.sleep(1000.msecs);
    }
    else
    {
        stderr.writefln("Playing ...");
        //~ Thread.sleep(2.seconds);

        //~ stderr.writefln("Stream latency = %s", dac.getStreamLatency());
        //~ stderr.writefln("Playing ... press any key to quit (buffer size = %s)", sampleCount);
        while (!kbhit) { }

        // Stop the stream
        dac.stopStream();
    }

    return 0;
}

// todo: windows-only
extern(C) int kbhit();

///
void printUsage()
{
    writeln("\nusage: <app> <modfile> <numOfChannels> <device> <channelOffset> <time>");
}
