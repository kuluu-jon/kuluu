namespace FFXI_DAT_PARSER.TOOLS.COMMON
{
    public enum Element : byte
    {
        Fire = 0x00,
        Ice = 0x01,
        Air = 0x02,
        Earth = 0x03,
        Thunder = 0x04,
        Water = 0x05,
        Light = 0x06,
        Dark = 0x07,
        Special = 0x0f, // this is the element set on the Meteor spell
        Undecided = 0xff, // this is the element set on inactive furnishing items in the item data
    }
}