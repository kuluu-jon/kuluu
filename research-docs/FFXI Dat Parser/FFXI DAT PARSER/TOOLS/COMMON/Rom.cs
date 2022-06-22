using System.Runtime.InteropServices;

namespace FFXI_DAT_PARSER.TOOLS.COMMON
{
    public class Rom
    {
        public Rom()
        {
            installPath = "C:/Program Files (x86)/PlayOnline/SquareEnix/FINAL FANTASY XI/";
        }

        public string installPath { get; set; }

        public (int RomIndex, string Vtable, string Ftable)[] tableDirectory = new (int RomIndex, string Vtable, string Ftable)[]
        {
                (1, "C:\\Program Files (x86)\\PlayOnline\\SquareEnix\\FINAL FANTASY XI\\VTABLE.dat",
                    "C:\\Program Files (x86)\\PlayOnline\\SquareEnix\\FINAL FANTASY XI\\FTABLE.dat"),
                (2, "C:\\Program Files (x86)\\PlayOnline\\SquareEnix\\FINAL FANTASY XI\\ROM2\\VTABLE2.dat",
                    "C:\\Program Files (x86)\\PlayOnline\\SquareEnix\\FINAL FANTASY XI\\ROM2\\FTABLE2.dat"),
                (3, "C:\\Program Files (x86)\\PlayOnline\\SquareEnix\\FINAL FANTASY XI\\ROM3\\VTABLE3.dat",
                    "C:\\Program Files (x86)\\PlayOnline\\SquareEnix\\FINAL FANTASY XI\\ROM3\\FTABLE3.dat"),
                (4, "C:\\Program Files (x86)\\PlayOnline\\SquareEnix\\FINAL FANTASY XI\\ROM4\\VTABLE4.dat",
                    "C:\\Program Files (x86)\\PlayOnline\\SquareEnix\\FINAL FANTASY XI\\ROM4\\FTABLE4.dat"),
                (5, "C:\\Program Files (x86)\\PlayOnline\\SquareEnix\\FINAL FANTASY XI\\ROM5\\VTABLE5.dat",
                    "C:\\Program Files (x86)\\PlayOnline\\SquareEnix\\FINAL FANTASY XI\\ROM5\\FTABLE5.dat"),
                (6, "C:\\Program Files (x86)\\PlayOnline\\SquareEnix\\FINAL FANTASY XI\\ROM6\\VTABLE6.dat",
                    "C:\\Program Files (x86)\\PlayOnline\\SquareEnix\\FINAL FANTASY XI\\ROM6\\FTABLE6.dat"),
                (7, "C:\\Program Files (x86)\\PlayOnline\\SquareEnix\\FINAL FANTASY XI\\ROM7\\VTABLE7.dat",
                    "C:\\Program Files (x86)\\PlayOnline\\SquareEnix\\FINAL FANTASY XI\\ROM7\\FTABLE7.dat"),
                (8, "C:\\Program Files (x86)\\PlayOnline\\SquareEnix\\FINAL FANTASY XI\\ROM8\\VTABLE8.dat",
                    "C:\\Program Files (x86)\\PlayOnline\\SquareEnix\\FINAL FANTASY XI\\ROM8\\FTABLE8.dat"),
                (9, "C:\\Program Files (x86)\\PlayOnline\\SquareEnix\\FINAL FANTASY XI\\ROM9\\VTABLE9.dat",
                    "C:\\Program Files (x86)\\PlayOnline\\SquareEnix\\FINAL FANTASY XI\\ROM9\\FTABLE9.dat")
        };

        public string GetRomPath(int FileID, IList<(int RomIndex, string Vtable, string Ftable)> tableDirectory)
        {
            for (var i = 0; i < tableDirectory.Count; i++)
            {
                var vData = File.ReadAllBytes($@"{tableDirectory[i].Vtable}").AsSpan();
                if (FileID > vData.Length) continue;
                var vTableValue = vData[FileID];
                var fData = File.ReadAllBytes($@"{tableDirectory[i].Ftable}").AsSpan();
                var fTableOffset = FileID * 2;
                var fTableValue = MemoryMarshal.Read<UInt16>(fData[fTableOffset..]);
                switch (vTableValue)
                {
                    case 0:
                        continue;
                    case 1:
                        return $@"ROM/{fTableValue >> 7}/{fTableValue & 0x7F}.DAT";

                    default:
                        return $@"ROM{vTableValue}/{fTableValue >> 7}/{fTableValue & 0x7F}.DAT";
                }
            }
            return "NULL";
        }
    }
}