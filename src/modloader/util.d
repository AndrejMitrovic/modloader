/*
 *             Copyright Andrej Mitrovic 2014.
 *  Distributed under the Boost Software License, Version 1.0.
 *     (See accompanying file LICENSE_1_0.txt or copy at
 *           http://www.boost.org/LICENSE_1_0.txt)
 */
module modloader.util;

import std.traits : isSomeChar;

/**
    C-style strings stored in static arrays are typically either zero-terminated,
    or use the entire length of the static array for the string.
*/
string fromStaticZ(Array : C[N], C, size_t N)(const auto ref Array array) @safe pure
    if (isSomeChar!C)
{
    import std.algorithm : countUntil;

    auto idx = (cast(const(byte)[])array[]).countUntil(0);

    // .idup => Issue 12467 - Regression (2.066 git-head): char[] is implicitly convertible to string:
    // https://d.puremagic.com/issues/show_bug.cgi?id=12467
    if (idx != -1)
        return array[0 .. idx].idup;
    else
        return array[].idup;
}

///
unittest
{
    char[4] arr;
    arr[0 .. 4] = "foo\0";
    assert(arr.fromStaticZ == "foo");

    arr[3] = 'd';
    assert(arr.fromStaticZ == "food");

    import core.stdc.string : strncpy;

    char[10] arr2;
    strncpy(arr2.ptr, "Hello, world", 10);
    assert(arr2.fromStaticZ == "Hello, wor", arr2.fromStaticZ);

    strncpy(arr2.ptr, "Hello!", 10);
    assert(arr2.fromStaticZ == "Hello!", arr2.fromStaticZ);
}

version (unittest):

import std.stdio : File;

/// Root dir of the modloader project.
immutable string rootDir;

shared static this()
{
    import core.runtime : Runtime;
    import std.file : exists;
    import std.getopt : getopt;

    auto args = Runtime.args;
    getopt(args, "rootDir", cast(string*)&rootDir);

    assert(rootDir.exists, rootDir);
}

/// Get the absolute path of $(D path) relative to the root dir of the modloader project.
string workFilePath(in char[] path)
{
    import std.path : buildPath, isAbsolute;

    assert(!path.isAbsolute());
    return rootDir.buildPath(path);
}

/**
    Return true if enum $(D en) is in a valid state.
*/
bool isValidEnum(E)(E en)
    if (is(E == enum))
{
    import std.traits : EnumMembers;

    foreach (val; EnumMembers!E)
    {
        if (en == val)
            return true;
    }

    return false;
}

///
unittest
{
    enum E { a = 1, b = 2 }

    E e = cast(E)3;
    assert(!e.isValidEnum);

    e = E.init;
    assert(e.isValidEnum);
}

/** Return the attributes of a type or symbol $(D T). */
template GetAttributes(T...) if (T.length == 1)
{
    import std.typetuple : TypeTuple;
    alias GetAttributes = TypeTuple!(__traits(getAttributes, T[0]));
}

///
unittest
{
    @("foo") struct S
    {
        @("bar") int x;
    }

    static assert(GetAttributes!S[0] == "foo");
    static assert(GetAttributes!(S.x)[0] == "bar");
}

/// Used as an attribute for de-serialization of static (and possibly zero-terminated) char arrays into strings.
struct ZCharArray { size_t size; }

/// Used as an attribute for fields which should not automatically be de-serialized.
enum SkipLoad;

/// Check whether the $(D symbol) has the $(D ZCharArray) attribute.
enum hasZCharArray(alias symbol) = is(typeof(GetAttributes!(symbol)[0]) == ZCharArray);

/// Get the $(D ZCharArray) attribute of a $(D symbol).
enum getZCharArray(alias symbol) = GetAttributes!(symbol)[0];

/// Check whether the $(D symbol) has the $(D SkipLoad) attribute.
enum hasSkipLoad(alias symbol) = is(GetAttributes!(symbol)[0] == SkipLoad);

///
struct FileStreamer
{
    import std.stdio : File;

    ///
    this(string filePath)
    {
        import std.exception : enforce;

        this.file = File(filePath, "rb");

        this.size = file.size;
        enforce(this.size != ulong.max);
    }

    /// Read data from file interpreted as $(D T), ensuring File's read position is re-set to the
    /// position before the call.
    @property T peek(T)()
    {
        ulong lastPos = file.tell;

        auto result = read!T();

        file.seek(lastPos);

        return result;
    }

    /// Read data from file interpreted as $(D T), and seek File to the next position.
    @property T read(T)() if (!is(T == struct))
    {
        import std.conv : text;
        import std.exception : enforce;

        auto result = *(cast(T*)file.rawRead(buffer[0 .. T.sizeof]).ptr);

        static if (is(T == enum))
            enforce(result.isValidEnum(), text(result));

        return result;

    }

    /// ditto : read an array
    @property T read(T : E[], E)(size_t count) if (!is(T == struct))
    {
        assert(count * E.sizeof <= buffer.length);
        return cast(T)file.rawRead(buffer[0 .. count * E.sizeof]);
    }

    /// ditto : read struct fields, with attribute support.
    @property T read(T)() if (is(T == struct))
    {
        T result;

        foreach (idx, _; result.tupleof)
        {
            static if (hasSkipLoad!(result.tupleof[idx]))
            {
                // skip loading
            }
            else
            static if (hasZCharArray!(result.tupleof[idx]))
            {
                enum Size = getZCharArray!(result.tupleof[idx]).size;
                alias Type = char[Size];
                result.tupleof[idx] = read!Type.fromStaticZ;
            }
            else
            {
                result.tupleof[idx] = read!(typeof(result.tupleof[idx]));
            }
        }

        return result;
    }

    /// read directly to a user-provided buffer
    @property void readTo(Buffer : E[], E)(Buffer userBuffer)
    {
        import std.exception : enforce;
        enforce(file.rawRead(userBuffer).length == userBuffer.length);
    }

    /// Move the File's read position forward by $(D byteCount).
    void moveForward(ulong byteCount)
    {
        ulong lastPos = file.tell;
        file.seek(lastPos + byteCount);
    }

    /// Move the File's read position to $(D bytePos).
    void moveTo(ulong bytePos)
    {
        file.seek(bytePos);
    }

    /// Get the current File's read position.
    @property ulong pos()
    {
        return file.tell;
    }

    /// Return $(D true) if the File end has been reached
    @property bool end()
    {
        // either way we have nothing else to read
        return file.eof || pos >= size;
    }

    ///
    const ulong size;

private:
    File file;
    ubyte[1024] buffer;
}

/// Get a FileStreamer for a file path.
FileStreamer streamFile(string path)
{
    return FileStreamer(path);
}

/// Read an entire file into memory.
ubyte[] readBytes(in char[] path)
{
    import std.file : read;
    return cast(ubyte[])read(path);
}
