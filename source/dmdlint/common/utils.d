module dmdlint.common.utils;

import std.algorithm;
import std.range;
import std.array;
import std.traits;
import std.typecons;
import std.meta;

string toDString(const(char*) cstr) @nogc pure nothrow
{
    import core.stdc.string : strlen;
    return (cstr)
        ? cast(string) cstr[0..strlen(cstr)]
        : null;
}

void writeLEB128(T, R)(ref R range, T value)
    if(is(ForeachType!R == ubyte) && isIntegral!T)
{
    static if(isSigned!T)
    {
        while (1)
        {
            ubyte b = value & 0x7F;

            value >>= 7;
            if ((value == 0 && !(b & 0x40)) ||
                (value == -1 && (b & 0x40)))
            {
                 range ~= cast(ubyte)b;
                 break;
            }
            range ~= cast(ubyte)(b | 0x80);
        }
    } else {
        do
        {
            ubyte b = value & 0x7F;

            value >>= 7;
            if (value)
                b |= 0x80;
            range ~= cast(ubyte)b;
        } while (value);
    }
}

Nullable!T readLEB128(T, R)(ref R range)
{
    OriginalType!T result = 0;
    size_t shift;
    ubyte b = void;

    static if(isSigned!T)
    {
        do {
            if(range.empty)
                return Nullable!T.init;
            b = range.front;
            range.popFront;

            result |= (b & 0x7F) << shift;
            shift += 7;
        } while ((b & 0x80) != 0);

        if ((shift < T.sizeof) && (b & 0x40))
            result |= (~0 << shift);

        return nullable!T(cast(T)result);
    } else {
        while (true) {
            if(range.empty)
                return Nullable!T.init;
            b = range.front;
            range.popFront;

            result |= (b & 0x7F) << shift;
            if ((b & 0x80) == 0)
                return nullable!T(cast(T)result);
            shift += 7;
        }
    }
}

auto toLEB128(T)(T value)
{
    ubyte[] ret;
    ret.writeLEB128(value);
    return ret;
}

unittest {
    ubyte[] i100 = toLEB128(int(100));
    assert(i100 == [228u, 0u]);
    assert(i100.readLEB128!int.get() == 100);

    ubyte[] u300 = toLEB128(uint(300u));
    assert(u300 == [172u, 2u]);
    assert(u300.readLEB128!uint.get() == 300u);

    ubyte[] u0 = [];
    assert(u0.readLEB128!uint.isNull);
}

enum TypeTagID : ubyte
{
    // special cases
    sbarray, /// signed byte arrays
    ubarray, /// unsigned byte arrays
    cbarray, /// character byte arrays (for UTF-8 auto decoding)
    bbarray, /// boolean arrays
    tuple,   /// tuple types

    struct_,
    class_,
    enum_,
    vector,
    bool_,
    byte_,
    ubyte_,
    short_,
    ushort_,
    int_,
    uint_,
    long_,
    ulong_,
    cent_,
    ucent_,
    char_,
    wchar_,
    dchar_,
    float_,
    double_,
    real_,
    ifloat_,
    idouble_,
    ireal_,
    cfloat_,
    cdouble_,
    creal_,
    void_,
    dynArray,
    staArray,
    assArray,
    function_,
    delegate_,
    pointer,
}

template getTypeTagID(T)
{
    // special cases first
    static if(isArray!T && is(ElementEncodingType!T : ubyte))
    {
        static if(is(Unqual!(ElementEncodingType!T) == char))
            enum getTypeTagID = TypeTagID.cbarray;
        else static if(is(Unqual!(ElementEncodingType!T) == ubyte))
            enum getTypeTagID = TypeTagID.ubarray;
        else static if(is(Unqual!(ElementEncodingType!T) == byte))
            enum getTypeTagID = TypeTagID.sbarray;
        else static if(is(Unqual!(ElementEncodingType!T) == bool))
            enum getTypeTagID = TypeTagID.bbarray;
    }
    else static if(__traits(isSame, TemplateOf!T, Tuple))
        enum getTypeTagID = TypeTagID.tuple;

    // other cases
    else static if(is(T == class))          enum getTypeTagID = TypeTagID.class_;
    else static if(is(T == struct))         enum getTypeTagID = TypeTagID.struct_;
    else static if(is(T == enum))           enum getTypeTagID = TypeTagID.enum_;
    else static if(is(T == function))       enum getTypeTagID = TypeTagID.function_;
    else static if(is(T == delegate))       enum getTypeTagID = TypeTagID.delegate_;
    else static if(isSIMDVector!T)          enum getTypeTagID = TypeTagID.vector;
    else static if(isStaticArray!T)         enum getTypeTagID = TypeTagID.staArray;
    else static if(isAssociativeArray!T)    enum getTypeTagID = TypeTagID.assArray;
    else static if(isArray!T)               enum getTypeTagID = TypeTagID.dynArray;
    else static if(isPointer!T)             enum getTypeTagID = TypeTagID.pointer;
    else static if(is(Unqual!T == bool))    enum getTypeTagID = TypeTagID.bool_;
    else static if(is(Unqual!T == byte))    enum getTypeTagID = TypeTagID.byte_;
    else static if(is(Unqual!T == ubyte))   enum getTypeTagID = TypeTagID.ubyte_;
    else static if(is(Unqual!T == short))   enum getTypeTagID = TypeTagID.short_;
    else static if(is(Unqual!T == ushort))  enum getTypeTagID = TypeTagID.ushort_;
    else static if(is(Unqual!T == int))     enum getTypeTagID = TypeTagID.int_;
    else static if(is(Unqual!T == uint))    enum getTypeTagID = TypeTagID.uint_;
    else static if(is(Unqual!T == long))    enum getTypeTagID = TypeTagID.long_;
    else static if(is(Unqual!T == ulong))   enum getTypeTagID = TypeTagID.ulong_;
    /* else static if(is(Unqual!T == cent))    enum getTypeTagID = TypeTagID.cent_; */
    /* else static if(is(Unqual!T == ucent))   enum getTypeTagID = TypeTagID.ucent_; */
    else static if(is(Unqual!T == char))    enum getTypeTagID = TypeTagID.char_;
    else static if(is(Unqual!T == wchar))   enum getTypeTagID = TypeTagID.wchar_;
    else static if(is(Unqual!T == dchar))   enum getTypeTagID = TypeTagID.dchar_;
    else static if(is(Unqual!T == float))   enum getTypeTagID = TypeTagID.float_;
    else static if(is(Unqual!T == double))  enum getTypeTagID = TypeTagID.double_;
    else static if(is(Unqual!T == real))    enum getTypeTagID = TypeTagID.real_;
    else static if(is(Unqual!T == ifloat))  enum getTypeTagID = TypeTagID.ifloat_;
    else static if(is(Unqual!T == idouble)) enum getTypeTagID = TypeTagID.idouble_;
    else static if(is(Unqual!T == ireal))   enum getTypeTagID = TypeTagID.ireal_;
    else static if(is(Unqual!T == cfloat))  enum getTypeTagID = TypeTagID.cfloat_;
    else static if(is(Unqual!T == cdouble)) enum getTypeTagID = TypeTagID.cdouble_;
    else static if(is(Unqual!T == creal))   enum getTypeTagID = TypeTagID.creal_;
    else static if(is(Unqual!T == void))    enum getTypeTagID = TypeTagID.void_;
    else                                    static assert(0, "Invalid Type!");
}

unittest
{
    assert(getTypeTagID!int == TypeTagID.int_);
    assert(getTypeTagID!string == TypeTagID.cbarray);
    assert(getTypeTagID!(byte[]) == TypeTagID.sbarray);
    assert(getTypeTagID!(bool[]) == TypeTagID.bbarray);
    assert(getTypeTagID!(ubyte[]) == TypeTagID.ubarray);
    assert(getTypeTagID!(char[]) == TypeTagID.cbarray);
    assert(getTypeTagID!(int[]) == TypeTagID.dynArray);
    assert(getTypeTagID!(int[5]) == TypeTagID.staArray);
    assert(getTypeTagID!(int[ulong]) == TypeTagID.assArray);
}

template isPackableType(T)
{
    static if(isAggregateType!T)
        enum isPackableType = allSatisfy!(isPackableType, Fields!T);
    else
        enum isPackableType = !(
                isDelegate!T || isFunctionPointer!T || isPointer!T
            );
}

enum SignatureChecks
{
    none,   /// No signature checks ( performance )
    strict, /// Strictly necessary signature checks ( portable )
    full,   /// Full signature checks ( debugging, not portable )
}

enum Endianess
{
    leb128,       // use LEB128 to express endianess-dependent types
    bigEndian,    // use big endian
    littleEndian, // use little endian
    platform,     // use the platform-specific endianess
}

auto genTypeSignature(T, SignatureChecks checks = SignatureChecks.full)()
{
    ubyte[] buf;

    static if (checks == SignatureChecks.full)
    {
        // 1. Size in bytes of the struct
        buf.writeLEB128(T.sizeof);

        // 2. Size boundary struct needed to be aligned on
        buf.writeLEB128(T.alignof);
    }

    static if (checks >= SignatureChecks.strict)
    {
        // 3. Type tag ID
        buf.writeLEB128(getTypeTagID!T);
    }

    return buf;
}

private auto genElementaryPackedBuffer(R, T)(R range, T element)
    if(is(ForeachType!R == ubyte))
{
    static if(isArray!T && is(ElementEncodingType!T : ubyte))
    {
        range.writeLEB128(element.length);
        foreach(e; element)
            range ~= cast(ubyte)e;
    } else {
        static if(is(Unqual!T : ubyte))
            range ~= element;
        else static if(isIntegral!T)
            range.writeLEB128(element);
        else static assert(0);
    }

    return range;
}

auto genPackedBuffer(SignatureChecks checks = SignatureChecks.strict, T)(T value)
{
    Appender!(ubyte[]) buf;
    buf ~= genTypeSignature!(T, checks);

    // Aggregate types
    static if(isAggregateType!T)
    {
        static immutable fields = [ FieldNameTuple!T ];
        static if(checks >= SignatureChecks.strict)
        {
            // Number of fields
            buf.writeLEB128(fields.length);
        }
        static foreach(m; fields)
        {
            static if(checks == SignatureChecks.full)
            {
                // offset of that field
                buf.writeLEB128(mixin("value.", m, ".offsetof"));
            }
            buf ~= genPackedBuffer!(checks)(mixin("value.", m));
        }
    }
    else static if(isArray!T && !is(ElementEncodingType!T : ubyte))
    {
        buf.writeLEB128(value.length);
        foreach(e; value)
            buf ~= genPackedBuffer!(checks)(e);
    } else {
        buf.genElementaryPackedBuffer(value);
    }

    return buf[];
}

private Nullable!T unpackElementaryBuffer(T, R)(ref R range)
    if(is(ForeachType!R == ubyte) /*&& isPackableType!T*/)
{
    static if(isArray!T && is(ElementEncodingType!T : ubyte))
    {
        auto len = range.readLEB128!size_t;
        if (len.isNull)
            return Nullable!T.init;
        static if (isStaticArray!T)
        {
            if (T.length != len.get())
                return Nullable!T.init;

            ubyte[T.length] value = void;
        }
        else
        {
            ubyte[] value = uninitializedArray!(ubyte[])(len.get());
        }

        foreach(ref e; value)
        {
            e = range.front;
            range.popFront;
        }

        return nullable!T(cast(T)value);
    } else {
        Nullable!T value = void;

        static if(is(Unqual!T : ubyte))
        {
            if (range.empty)
                return Nullable!T.init;
            value = cast(T)range.front;
            range.popFront;
        }
        else static if(isIntegral!T)
        {
            value = range.readLEB128!T;
        }
        else static assert(0);

        return value;
    }
}

private Nullable!T unpackBufferImpl(T, SignatureChecks checks = SignatureChecks.strict, R)(ref R range)
    if(is(ForeachType!R == ubyte) /*&& isPackableType!T*/)
{
    T value = void;

    static if(checks != SignatureChecks.none)
    {
        // check for type signature
        if(!skipOver(range, genTypeSignature!(T, checks)))
            return Nullable!T.init;
    }

    static if(isAggregateType!T)
    {
        static if(is(T == class))
            ret = new T();
        else static if(!is(T == struct))
            static assert(0, "Type not supported!");

        static immutable fields = [ FieldNameTuple!T ];

        static if(checks >= SignatureChecks.strict)
        {
            // Number of fields
            if(!skipOver(range, toLEB128(fields.length)))
                return Nullable!T.init;
        }

        static foreach(m; fields)
        {{
            static if(checks == SignatureChecks.full)
            {
                // offset of that field
                if(!skipOver(range, toLEB128(mixin("value.", m, ".offsetof"))))
                    return Nullable!T.init;
            }

            alias M = typeof(mixin("value.", m));
            Nullable!M nm = range.unpackBufferImpl!(M, checks);

            // if fail to unpack
            if(nm.isNull)
                return Nullable!T.init;
            mixin("value.", m) = nm.get();
        }}

        return nullable!T(value);
    } else static if(isArray!T && !is(ElementEncodingType!T : ubyte))
    {
        auto len = range.readLEB128!size_t;
        if (len.isNull)
            return Nullable!T.init;

        static if (isStaticArray!T)
        {
            if (T.length != len.get())
                return Nullable!T.init;
        }
        else
            value = uninitializedArray!T(len.get());

        foreach(ref e; value)
        {
            auto ne = range.unpackBufferImpl!(typeof(e), checks);
            if (ne.isNull)
                return Nullable!T.init;
            e = ne.get();
        }

        return nullable!T(value);
    } else {
        return range.unpackElementaryBuffer!T;
    }
}

Nullable!T unpackBuffer(T, SignatureChecks checks = SignatureChecks.strict, R)(R range)
    if(is(ForeachType!R == ubyte) /*&& isPackableType!T*/)
{
    typeof(return) tmpret = range.unpackBufferImpl!(T, checks);

    if(!range.empty)
        return Nullable!T.init;
    return tmpret;
}

unittest
{
    struct A {
        ubyte a;
        string str;
    }

    assert((cast(ubyte[])[0u]).unpackBuffer!A.isNull);
    ubyte[] b = A(10, "abc").genPackedBuffer;
    assert(b.unpackBuffer!A.get() == A(10, "abc"));

    b = A(200, "abcd").genPackedBuffer!(SignatureChecks.none);
    assert(b.unpackBuffer!(A, SignatureChecks.none).get() == A(200, "abcd"));

    b = A(200, "abcd").genPackedBuffer!(SignatureChecks.full);
    assert(b.unpackBuffer!(A, SignatureChecks.full).get() == A(200, "abcd"));

    struct B {
        ubyte a;
        string[] str;
        bool b;
        size_t c;
        int d;
    }

    b = B(200, ["abcd"], true, 0, 10).genPackedBuffer!(SignatureChecks.full);
    assert(b.unpackBuffer!(B, SignatureChecks.full).get() == B(200, ["abcd"], true, 0, 10));
}

unittest
{
    struct A {
        ubyte a;
        string str;
    }

    A a = A(10, "abc");

    assert(
        cast(ubyte[])[10u, 3u] ~ cast(ubyte[])"abc"
        == a.genPackedBuffer!(SignatureChecks.none));

    class B {
        this(size_t a, long b, string str)
        {
            this.a = a;
            this.b = b;
            this.str = str;
        }
        size_t a;
        long b;
        string str;
    }
    assert(
        toLEB128(size_t(100)) ~ toLEB128(long(200)) ~ 4u ~ cast(ubyte[])"abcd"
        == (new B(100, 200, "abcd")).genPackedBuffer!(SignatureChecks.none));

    assert(
        cast(ubyte[])[TypeTagID.struct_] ~ 2u ~
            TypeTagID.ubyte_ ~ 10u ~
            TypeTagID.cbarray ~ 3u ~ cast(ubyte[])"abc"
        == a.genPackedBuffer!(SignatureChecks.strict));

    assert(
        toLEB128(A.sizeof) ~ toLEB128(A.alignof) ~ TypeTagID.struct_ ~ 2u ~
            toLEB128(A.a.offsetof) ~
            toLEB128(ubyte.sizeof) ~ toLEB128(ubyte.alignof) ~ TypeTagID.ubyte_ ~
            10u ~
            toLEB128(A.str.offsetof) ~
            toLEB128(string.sizeof) ~ toLEB128(string.alignof) ~ TypeTagID.cbarray ~
            3u ~ cast(ubyte[])"abc"
        == a.genPackedBuffer!(SignatureChecks.full));
}
