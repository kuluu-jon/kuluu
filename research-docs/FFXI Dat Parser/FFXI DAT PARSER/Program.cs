using FFXI_DAT_PARSER.TOOLS.COMMON;
using FFXI_DAT_PARSER.TOOLS.DAT.TYPES;
using System.Runtime.InteropServices;

namespace FFXI_DAT_PARSER
{
    public class Program
    {
        private static readonly Shared shared = new();

        [DllImport("kernel32.dll", ExactSpelling = true)]
        private static extern IntPtr GetConsoleWindow();

        private static IntPtr ThisConsole = GetConsoleWindow();

        [DllImport("user32.dll", CharSet = CharSet.Auto, SetLastError = true)]
        private static extern bool ShowWindow(IntPtr hWnd, int nCmdShow);

        private const int MAXIMIZE = 3;

        private static void Main()
        {
            ShowWindow(ThisConsole, MAXIMIZE);
            //if (!shared.askUser.Confirm("Is your installation directory for FFXI: {C:/Program Files (x86)/PlayOnline/SquareEnix/FINAL FANTASY XI/}."))
            //{
            //    shared.rom.installPath = shared.askUser.GetAnswer("Please update your installation directory (Press enter when you are done).");
            //}
            while (true)
            {
                Console.Write("Enter a zoneId to look up  zone related dats.");
                int id;
                try
                {
                    id = int.Parse(Console.ReadLine() ?? string.Empty);
                }
                catch
                {
                    Console.ForegroundColor = ConsoleColor.Red;
                    Console.Write("Need to enter numbers!." + Environment.NewLine);
                    id = -1;
                    Console.ForegroundColor = ConsoleColor.White;
                }
                for (int i = 0; i < 7; i++)
                {
                    switch (i)
                    {
                        case 0:
                            shared.dat.ParseDat(BUMPMAP_DATLOOKUP(id), id, DatType.BumpMap);
                            break;

                        case 1:
                            shared.dat.ParseDat(DIALOG_DATLOOKUP(id, id), id, DatType.Dialog);
                            break;

                        case 2:
                            shared.dat.ParseDat(ENTITY_DATLOOKUP(id, id), id, DatType.Entity);
                            break;

                        case 3:
                            shared.dat.ParseDat(EVENTDATA_DATLOOKUP(id), id, DatType.EventData);
                            break;

                        case 4:
                            shared.dat.ParseDat(EVENTMESSAGE_DATLOOKUP(id), id, DatType.EventMessge);
                            break;

                        case 5:
                            shared.dat.ParseDat(SHADOW_DATLOOKUP(id), id, DatType.Shadow);
                            break;

                        case 6:
                            //   shared.dat.ParseDat(ZONEMODEL_DATLOOKUP(id), id, DatType.ZoneModel);
                            break;

                        default:
                            Console.WriteLine("ERROR");
                            break;
                    }
                }
            }
        }

        /// <summary>
        /// Header reads as "Shadow", not 100% sure what this dat actually is.
        /// But when Editied to a darker colour, the Shadows around Entities and objects appear darker.
        /// This info is found in the same function that calls BUMPMAP,ZONEMODEL,SHADOW
        /// </summary>
        /// <param name="zoneID"></param>
        private static string SHADOW_DATLOOKUP(int zoneID)
        {
            var fileId = 7052;
            if (File.Exists($@"{shared.rom.installPath}{shared.rom.GetRomPath(fileId, shared.rom.tableDirectory)}"))
            {
                Print($@"ZoneID {zoneID}: SHADOW.DAT", $@"{shared.rom.GetRomPath(fileId, shared.rom.tableDirectory)}", $@"FILE ID {fileId}");
                return $@"{shared.rom.installPath}{shared.rom.GetRomPath(fileId, shared.rom.tableDirectory)}";
            }
            else return "NILL";
        }

        /// <summary>
        /// This is just a dialog dat
        /// This call is used when you change zones, prep for Event data
        /// </summary>
        /// <param name="zoneID"></param>
        private static string EVENTMESSAGE_DATLOOKUP(int zoneID)
        {
            var fileId = 0;
            if (zoneID < 2000)
            {
                if (zoneID < 1000)
                {
                    fileId = zoneID < 256 ? zoneID + KeyTables.GetDatFileIdOffset(105) : KeyTables.GetDatFileIdOffset(108) + zoneID - 256;
                    if (File.Exists($@"{shared.rom.installPath}{shared.rom.GetRomPath(fileId, shared.rom.tableDirectory)}"))
                    {
                        Print($@"ZoneID {zoneID}: EVENTMESSAGE.DAT", $@"{shared.rom.GetRomPath(fileId, shared.rom.tableDirectory)}", $@"FILE ID {fileId}");
                        return $@"{shared.rom.installPath}{shared.rom.GetRomPath(fileId, shared.rom.tableDirectory)}";
                    }
                }
                else
                {
                    fileId = KeyTables.GetDatFileIdOffset(106) + zoneID - 1000;
                    if (File.Exists($@"{shared.rom.installPath}{shared.rom.GetRomPath(fileId, shared.rom.tableDirectory)}"))
                    {
                        Print($@"ZoneID {zoneID}: EVENTMESSAGE.DAT", $@"{shared.rom.GetRomPath(fileId, shared.rom.tableDirectory)}", $@"FILE ID {fileId}");
                        return $@"{shared.rom.installPath}{shared.rom.GetRomPath(fileId, shared.rom.tableDirectory)}";
                    }
                }
            }
            else
            {
                fileId = KeyTables.GetDatFileIdOffset(107) + zoneID - 2000;
                if (File.Exists($@"{shared.rom.installPath}{shared.rom.GetRomPath(fileId, shared.rom.tableDirectory)}"))
                {
                    Print($@"ZoneID {zoneID}: EVENTMESSAGE.DAT", $@"{shared.rom.GetRomPath(fileId, shared.rom.tableDirectory)}", $@"FILE ID {fileId}");
                    return $@"{shared.rom.installPath}{shared.rom.GetRomPath(fileId, shared.rom.tableDirectory)}";
                }
            }
            return "NILL";
        }

        /// <summary>
        /// these dats contain event data e.g. entity server ids, event ids, offsets,scene data.
        /// This call is used when you change zones, prep for Event data
        /// </summary>
        /// <param name="zoneID"></param>
        private static string EVENTDATA_DATLOOKUP(int zoneID)
        {
            if (zoneID < 2000)
            {
                if (zoneID < 1000)
                {
                    var fileId = zoneID < 256 ? zoneID + 5820 : zoneID + 84735;
                    if (File.Exists($@"{shared.rom.installPath}{shared.rom.GetRomPath(fileId, shared.rom.tableDirectory)}"))
                    {
                        Print($@"ZoneID {zoneID}: EVENT.DAT", $@"{shared.rom.GetRomPath(fileId, shared.rom.tableDirectory)}", $@"FILE ID {fileId}");
                        return $@"{shared.rom.installPath}{shared.rom.GetRomPath(fileId, shared.rom.tableDirectory)}";
                    }
                }
                else
                {
                    var fileId = zoneID + 56881;
                    if (File.Exists($@"{shared.rom.installPath}{shared.rom.GetRomPath(fileId, shared.rom.tableDirectory)}"))
                    {
                        Print($@"ZoneID {zoneID}: EVENT.DAT", $@"{shared.rom.GetRomPath(fileId, shared.rom.tableDirectory)}", $@"FILE ID {fileId}");
                        return $@"{shared.rom.installPath}{shared.rom.GetRomPath(fileId, shared.rom.tableDirectory)}";
                    }
                }
            }
            else
            {
                var fileId = zoneID + 65611;
                if (File.Exists($@"{shared.rom.installPath}{shared.rom.GetRomPath(fileId, shared.rom.tableDirectory)}"))
                {
                    Print($@"ZoneID {zoneID}: EVENT.DAT", $@"{shared.rom.GetRomPath(fileId, shared.rom.tableDirectory)}", $@"FILE ID {fileId}");
                    return $@"{shared.rom.installPath}{shared.rom.GetRomPath(fileId, shared.rom.tableDirectory)}";
                }
            }
            return "NILL";
        }

        //FFXI allows for a single zone to have multiple Entity dats & DIALOG dats  depending on the zones 'instance' being loaded/used. Internally,
        //the client has a shift for the id based on the zone id and a sub-zone id which is sent in the 0x00A zone enter packet.
        //Packet: Zone Enter (0x000A)
        //+0x30 = zone id
        //+0x9E = zone sub id
        //zones 1000 to 1026 return dats related to Dungeons
        //in this case we are just setting subid to id for testing.
        private static string ENTITY_DATLOOKUP(int zoneID, int subID)
        {
            if (subID < 1000 || subID > 1299)
            {
                var fileId = zoneID < 256 ? zoneID + 6720 : zoneID + 86235;
                if (File.Exists($@"{shared.rom.installPath}{shared.rom.GetRomPath(fileId, shared.rom.tableDirectory)}"))
                {
                    Print($@"ZoneID {zoneID}: ENTITY.DAT", $@"{shared.rom.GetRomPath(fileId, shared.rom.tableDirectory)}", $@"FILE ID {fileId}");
                    return $@"{shared.rom.installPath}{shared.rom.GetRomPath(fileId, shared.rom.tableDirectory)}";
                }
            }
            else
            {
                var fileId = subID + 66911;
                if (File.Exists($@"{shared.rom.installPath}{shared.rom.GetRomPath(fileId, shared.rom.tableDirectory)}"))
                {
                    Print($@"ZoneID {zoneID}: ENTITY.DAT", $@"{shared.rom.GetRomPath(fileId, shared.rom.tableDirectory)}", $@"FILE ID {fileId}");
                    return $@"{shared.rom.installPath}{shared.rom.GetRomPath(fileId, shared.rom.tableDirectory)}";
                }
            }
            return "NILL";
        }

        //FFXI allows for a single zone to have multiple Entity dats & DIALOG dats  depending on the zones 'instance' being loaded/used. Internally,
        //the client has a shift for the id based on the zone id and a sub-zone id which is sent in the 0x00A zone enter packet.
        //Packet: Zone Enter (0x000A)
        //+0x30 = zone id
        //+0x9E = zone sub id
        //zones 1000 to 1026 return dats related to Dungeons
        //in this case we are just setting subid to id for testing.
        private static string DIALOG_DATLOOKUP(int zoneID, int subID)
        {
            if (subID < 1000 || subID > 1299)
            {
                var fileId = zoneID < 256 ? zoneID + KeyTables.GetDatFileIdOffset(105) : KeyTables.GetDatFileIdOffset(108) + zoneID - 256;
                if (File.Exists($@"{shared.rom.installPath}{shared.rom.GetRomPath(fileId, shared.rom.tableDirectory)}"))
                {
                    Print($@"ZoneID {zoneID}: DIALOG.DAT", $@"{shared.rom.GetRomPath(fileId, shared.rom.tableDirectory)}", $@"FILE ID {fileId}");
                    return $@"{shared.rom.installPath}{shared.rom.GetRomPath(fileId, shared.rom.tableDirectory)}";
                }
            }
            else
            {
                var fileId = KeyTables.GetDatFileIdOffset(107) + subID - 1000;
                if (File.Exists($@"{shared.rom.installPath}{shared.rom.GetRomPath(fileId, shared.rom.tableDirectory)}"))
                {
                    Print($@"ZoneID {zoneID}: DIALOG.DAT", $@"{shared.rom.GetRomPath(fileId, shared.rom.tableDirectory)}", $@"FILE ID {fileId}");
                    return $@"{shared.rom.installPath}{shared.rom.GetRomPath(fileId, shared.rom.tableDirectory)}";
                }
            }
            return "NILL";
        }

        /// <summary>
        /// lookS up the ZONEMODEL.DAT
        /// This info is found in the same function that calls BUMPMAP,ZONEMODEL,SHADOW
        /// </summary>
        /// <param name="zoneID"></param>
        private static string ZONEMODEL_DATLOOKUP(int zoneID)
        {
            var fileId = zoneID < 256 ? zoneID + 100 : zoneID + 83635;
            if (File.Exists($@"{shared.rom.installPath}{shared.rom.GetRomPath(fileId, shared.rom.tableDirectory)}"))
            {
                Print($@"ZoneID {zoneID}: ZONEMODEL.DAT", $@"{shared.rom.GetRomPath(fileId, shared.rom.tableDirectory)}", $@"FILE ID {fileId}");
                return $@"{shared.rom.installPath}{shared.rom.GetRomPath(fileId, shared.rom.tableDirectory)}";
            }
            else
                return "NILL";
        }

        /// <summary>
        /// Returns the BUMPMAP.DAT
        /// This info is found in the same function that calls BUMPMAP,ZONEMODEL,SHADOW
        /// </summary>
        /// <param name="zoneID"></param>
        private static string BUMPMAP_DATLOOKUP(int zoneID)
        {
            var fileId = zoneID < 256 ? zoneID + 39831 : zoneID + 84435;
            if (File.Exists($@"{shared.rom.installPath}{shared.rom.GetRomPath(fileId, shared.rom.tableDirectory)}"))
            {
                Print($@"ZoneID {zoneID}: BUMPMAP.DAT", $@"{shared.rom.GetRomPath(fileId, shared.rom.tableDirectory)}", $@"FILE ID {fileId}");
                return $@"{shared.rom.installPath}{shared.rom.GetRomPath(fileId, shared.rom.tableDirectory)}";
            }
            else return "NILL";
        }

        private static void Print(string a, string b, string c)
        {
            char pad = ' ';
            Console.ForegroundColor = ConsoleColor.Yellow;
            Console.Write(a.PadRight(40, pad));
            Console.ForegroundColor = ConsoleColor.Green;
            Console.Write(b.PadRight(40, pad));
            Console.ForegroundColor = ConsoleColor.White;
            Console.WriteLine(c.PadRight(20, pad));
        }
    }
}