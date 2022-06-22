using FFXI_DAT_PARSER.TOOLS.COMMON;
using FFXI_DAT_PARSER.TOOLS.DAT.TYPES;

namespace FFXI_DAT_PARSER.TOOLS.DAT
{
    public class Dat
    {
        private Shared shared { get; set; }

        public Dat(Shared shd)
        {
            shared = shd;
        }

        public bool ParseDat(string path, int zoneID, DatType Type)
        {
            if (path == "NILL") return false;
            var data = File.ReadAllBytes(path).AsSpan();
            switch (Type)
            {
                case DatType.BumpMap:
                    return true;

                case DatType.Dialog:
                    return shared.dialogDat.ParseDat(data, zoneID, "Dialog");

                case DatType.Entity:
                    return shared.entityDat.ParseDat(data, zoneID);

                case DatType.EventData:
                    return true;
                //  return shared.eventDat.ParseDat(data, zoneID);

                case DatType.EventMessge:
                    return shared.dialogDat.ParseDat(data, zoneID, "EventMessage");

                case DatType.Shadow:
                    return true;

                case DatType.ZoneModel:
                    return shared.modelDat.ParseDat(data, zoneID);
            }

            return false;
        }
    }
}