using Newtonsoft.Json;
using Newtonsoft.Json.Linq;
using System.Runtime.InteropServices;
using System.Text;

namespace FFXI_DAT_PARSER.TOOLS.DAT.TYPES
{
    public class DialogDat
    {
        [JsonProperty(Order = 2)] public int zoneID { get; set; }

        [JsonProperty(Order = 3)] public List<DIALOG> Dialog_Entries = new List<DIALOG>();

        public DialogDat()
        {
        }

        private string? Type;

        public unsafe bool ParseDat(Span<byte> data, int zoneid, string? type)
        {
            zoneID = zoneid;
            Dialog_Entries.Clear();
            if (data.Length > 4)
            {
                if (Decrypted(data))
                {
                    var firstDIALOGPosition = MemoryMarshal.Read<uint>(data[4..]);
                    var count = firstDIALOGPosition / 4;
                    count += 1;
                    var dialogEntries = new List<uint>((int)count + 1) { firstDIALOGPosition };
                    for (var i = 0; i < count; ++i)
                    {
                        dialogEntries.Add(MemoryMarshal.Read<uint>(data[((4 * i))..]));
                    }
                    dialogEntries.Add((uint)data.Length - 4);
                    dialogEntries.Sort();

                    for (var i = 1; i < (int)count; ++i)
                    {
                        if (4 + dialogEntries[i] >= data.Length)
                        {
                            break;
                        }
                        var textStart = dialogEntries[i];
                        var textEnd = dialogEntries[i + 1];
                        var Text = Encoding.UTF8.GetString(data.Slice((int)(textStart), (int)(textEnd - textStart))).TrimEnd('\0');
                        Dialog_Entries.Add(new DIALOG { index = i - 1, text = Text });
                    }
                }
                DumpToJson(zoneid, type);
                return true;
            }
            else return false;
        }

        private void DumpToJson(int zone, string? type)
        {
            try
            {
                var path = ($@"{AppDomain.CurrentDomain.BaseDirectory}{type}");
                if (!Directory.Exists(path))
                    Directory.CreateDirectory(path);
                if (!Directory.Exists(path)) return;
                var outFile = File.Create($@"{path}\\{zone}.json");
                outFile.Close();
                string JSONresult = JsonConvert.SerializeObject(this);
                string jsonFormatted = JValue.Parse(JSONresult).ToString(Newtonsoft.Json.Formatting.Indented);
                File.WriteAllText(outFile.Name, jsonFormatted);
            }
            catch (Exception ex)
            {
                Console.ForegroundColor = ConsoleColor.Red;
                Console.WriteLine(ex.ToString());
            }
        }

        public bool Decrypted(Span<byte> data)
        {
            if (data[3] == 0x10)
            {
                for (int i = 0; i < data.Length; ++i)
                {
                    data[i] ^= 0x80;
                }
                data[3] = 0;
                return true;
            }
            else return false;
        }
    }
}