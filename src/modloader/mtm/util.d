/*
 *             Copyright Andrej Mitrovic 2014.
 *  Distributed under the Boost Software License, Version 1.0.
 *     (See accompanying file LICENSE_1_0.txt or copy at
 *           http://www.boost.org/LICENSE_1_0.txt)
 */
module modloader.mtm.util;

import modloader.mtm.types : SampleType;

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
