using FFXI_DAT_PARSER.TOOLS.DAT;
using FFXI_DAT_PARSER.TOOLS.DAT.TYPES;

namespace FFXI_DAT_PARSER.TOOLS.COMMON
{
    public class Shared
    {
        public Dat dat { get; set; }
        public Rom rom { get; set; }
        public AskUser askUser { get; set; }
        public DialogDat dialogDat { get; set; }
        public EntityDat entityDat { get; set; }

        //     public EventDat eventDat { get; set; }
        public ModelDat modelDat { get; set; }

        public Shared()
        {
            dat = new Dat(this);
            rom = new Rom();
            askUser = new AskUser();
            dialogDat = new DialogDat();
            entityDat = new EntityDat();
            //  eventDat = new EventDat(this);
            modelDat = new ModelDat();
        }
    }
}