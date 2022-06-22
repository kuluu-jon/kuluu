using System.Text;

namespace FFXI_DAT_PARSER.TOOLS.COMMON
{
    public static class ExceptionExtension
    {
        public static string ToFullBlownString(this System.Exception e, int level = int.MaxValue)
        {
            var sb = new StringBuilder();
            var exception = e;
            var counter = 1;
            while (exception != null && counter <= level)
            {
                sb.AppendLine($"{counter}-> Level: {counter}");
                sb.AppendLine($"{counter}-> Message: {exception.Message}");
                sb.AppendLine($"{counter}-> Source: {exception.Source}");
                sb.AppendLine($"{counter}-> Target Site: {exception.TargetSite}");
                sb.AppendLine($"{counter}-> Stack Trace: {exception.StackTrace}");

                exception = exception.InnerException;
                counter++;
            }

            return sb.ToString();
        }
    }
}