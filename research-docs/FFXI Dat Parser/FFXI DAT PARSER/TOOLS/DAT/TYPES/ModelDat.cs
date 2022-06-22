using System.Runtime.InteropServices;

namespace FFXI_DAT_PARSER.TOOLS.DAT.TYPES
{
    public class ModelDat
    {
        public List<DatChunk> Chunks { get; set; }
        private int zoneID { get; set; }
        private int BlockSize { get; set; }
        private byte[] dword_78C2E3F0 = new byte[0x2A759F90];
        private int dword_78C2E414 { get; set; }

        public ModelDat()
        {
            Chunks = new List<DatChunk>();
        }

        private int position = 0;
        private uint size = 0;

        public unsafe bool ParseDat(Span<byte> data, int zoneid)
        {
            try
            {
                zoneID = zoneid;
                Chunks.Clear();
                position = 0;
                size = 0;
                while (position < data.Length)
                {
                    position += 4;
                    var value = MemoryMarshal.Read<uint>(data[position..]);
                    var type = (ResourceType)(value & 0x7F);
                    size = 16 * ((value >> 7) & 0x7FFFF) - 16;
                    var Size = 16 * ((data[position] >> 7) & 0x7FFFF) - 16;
                    position += 12;
                    Span<byte> block = new Span<byte> { };

                    switch (type)
                    {
                        case ResourceType.Mmb:
                            break;

                        case ResourceType.Mzb:
                            block = data.Slice(position, (int)size + 48);
                            ParseMzb(block, 1);
                            break;

                        case ResourceType.Rid:
                            //Rid.ParseRid(block, zoneId);
                            break;

                        case ResourceType.Unknown:
                            break;
                    }
                    Chunks.Add(new DatChunk { Data = block.ToArray(), Type = type, Size = size });
                    position += block.Length;
                }
                return true;
            }
            catch (Exception ex)
            {
                Console.WriteLine($@"Zoneid: {zoneid} | MZB count: {Chunks.Count}");
                Console.WriteLine($@"{data.Length} {position} {size} {ex.ToString()}");
                return false;
            }
        }

        private void ParseMzb(Span<byte> data, int a1)
        {
            dword_78C2E414 += a1;
            sub_78807DE0(32, data, dword_78C2E3F0);
        }

        public void sub_78807DE0(int a1, Span<byte> data, byte[] dword)
        {
        }
    }
}