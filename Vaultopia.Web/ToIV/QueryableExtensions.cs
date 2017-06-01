using EPiServer.Core;
using ImageVault.Client.Query;
using ImageVault.Common.Data;
using ImageVault.EPiServer;

namespace Vaultopia.Web.ToIV
{
    public static class QueryableExtensions
    {
        public static IIVQueryable<T> UsedOn<T>(this IIVQueryable<T> source, PageData d, string name)
        {
            return source.UsedOn(new EPiServerPublishDetails(d, name));
        }
        public static IIVQueryable<T> UsedOn<T>(this IIVQueryable<T> source, string name)
        {
            return source.UsedOn(new PublishDetailsData(name,null,name));
        }
    }
}