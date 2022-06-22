using Newtonsoft.Json;
using Newtonsoft.Json.Linq;
using System.Runtime.InteropServices;
using System.Text;

namespace FFXI_DAT_PARSER.TOOLS.DAT.TYPES
{
    public class EntityDat
    {
        [JsonProperty(Order = 1)] public int zoneID { get; set; }
        [JsonProperty(Order = 2)] public List<ENTITY> entities = new();

        public EntityDat()
        {
        }

        public unsafe bool ParseDat(Span<byte> data, int zoneid)
        {
            entities.Clear();
            zoneID = zoneid;
            try
            {
                if (data.Length > 32)
                {
                    for (var i = 0; i < data.Length;)
                    {
                        var Name = Encoding.ASCII.GetString(data.Slice(i, 28)).TrimEnd('\0');
                        var ServerID = MemoryMarshal.Read<uint>(data[(i + 28)..]);
                        var TargetIndex = (int)(ServerID & 0xFFF);
                        var zoneId = (int)((ServerID >> 12) & 0xFFF);
                        entities.Add(new ENTITY { name = Name, serverID = ServerID, targetIndex = TargetIndex, zoneID = zoneId });
                        i += 32;
                    }
                }
                if (data.Length < 32)
                {
                    entities.Add(new ENTITY { name = "none", serverID = 0, targetIndex = 0, zoneID = zoneID });
                }
                DumpToJson(zoneID);
                return true;
            }
            catch (Exception ex)
            {
                Console.ForegroundColor = ConsoleColor.Red;
                Console.WriteLine(ex.ToString());
                Console.ForegroundColor = ConsoleColor.White;
                return false;
            }
        }

        private void DumpToJson(int zone)
        {
            try
            {
                var path = ($@"{AppDomain.CurrentDomain.BaseDirectory}Entities");
                if (!Directory.Exists(path))
                    Directory.CreateDirectory(path);
                if (!Directory.Exists(path)) return;
                var outFile = File.Create($@"{path}\\{zone}.json");
                outFile.Close();
                string JSONresult = JsonConvert.SerializeObject(this);
                string jsonFormatted = JValue.Parse(JSONresult).ToString(Formatting.Indented);
                File.WriteAllText(outFile.Name, jsonFormatted);
            }
            catch (Exception ex)
            {
                Console.ForegroundColor = ConsoleColor.Red;
                Console.WriteLine(ex.ToString());
            }
        }
    }
}