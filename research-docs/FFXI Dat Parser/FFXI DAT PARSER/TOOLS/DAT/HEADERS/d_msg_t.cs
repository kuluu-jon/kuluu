namespace FFXI_DAT_PARSER.TOOLS.DAT.HEADERS
{
    public unsafe struct d_msg_header_t
    {
        public fixed byte d_msg[8];   //'d_msg' string denoting the file type.
        public ushort HeaderDecoded;  // Flag if the file header is already decoded. (1 = Decoded, Else = Encoded via rotation.)
        public ushort DataEncoded;    // Flag if the string data of the file is bitwise 'NOT' encoded.
        public ushort Unknown0000;    // Unknown flag that deals with how the first entry is handled. (Always 3 in current client.)
        public ushort Unknown0001;    // Unknown flag that works with Unknown0000 if it is not set to 3. (Not used in any DAT file currently.)
        public uint Unknown0002;    // Unknown flag that works with HeaderDecoded if it is not set to 1. (Seems to be unused now, no reference in latest client.)
        public uint FileSize;       // The size of the entire file.
        public uint HeaderSize;     // The size of the header.
        public uint ToCSize;        // The size of the table of contents.
        public uint EntrySize;      // The size of each entry.
        public uint DataSize;       // The size of data in the file. (FileSize - HeaderSize)
        public uint EntryCount;     // The number of entries within the file.
        public uint Unknown0003;    // Unknown flag that works with HeaderDecoded if it is not set to 1.
        public fixed byte Unknown0004[16]; // Unknown
    };

    public unsafe struct d_msg_entry_t
    {
        public uint Offset;
        public uint Length;
    };

    public unsafe struct d_msg_entryinfo_t
    {
        public uint Offset;
        public uint Flag;
    };

    public unsafe struct d_msg_entryheader_t
    {
        public uint Count;
        public List<d_msg_entryinfo_t> Info;
    };
}