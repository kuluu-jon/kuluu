using Newtonsoft.Json;

namespace FFXI_DAT_PARSER.TOOLS.DAT.TYPES
{
    public enum DatType
    {
        BumpMap,
        Dialog,
        Entity,
        EventData,
        EventMessge,
        ZoneModel,
        Shadow
    }

    public class ENTITY
    {
        [JsonProperty(Order = 1)] public string? name { get; init; }
        [JsonProperty(Order = 2)] public uint serverID { get; init; }
        [JsonProperty(Order = 3)] public int targetIndex { get; init; }
        [JsonProperty(Order = 4)] public int zoneID { get; set; }
    }

    public class ACTORS
    {
        [JsonProperty(Order = 1)] public uint id { get; set; }
        [JsonProperty(Order = 2)] public string? name { get; set; }
        [JsonProperty(Order = 3)] public List<EVENTS> events = new List<EVENTS>();
    }

    public class EVENTS
    {
        [JsonProperty(Order = 1)] public uint EventCount;
        [JsonIgnore] public List<ushort> EventOffsets = new();
        [JsonProperty(Order = 3)] public List<Event> Event = new();
        [JsonIgnore] public uint RefCount;
        [JsonIgnore] public List<uint> References = new();
        [JsonIgnore] public uint SceneSize;
        [JsonIgnore] public List<byte> SceneData = new();
    }

    public class Event
    {
        public ushort eventID;
        public List<DIALOG> dialog = new();

        [JsonIgnore] public List<byte> opcode = new();
        [JsonIgnore] public List<int> offset = new();
    }

    public class DIALOG
    {
        [JsonProperty(Order = 1)]
        public int index { get; set; }

        [JsonProperty(Order = 2)]
        public string? text { get; set; }
    }

    public class dialog
    {
        public uint offset { get; set; }
        public uint length { get; set; }
    }

    public class DatChunk
    {
        public byte[] Data { get; init; }

        public uint Size { get; init; }

        public ResourceType Type { get; init; }
    }
}