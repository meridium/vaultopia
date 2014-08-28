using System.Web.Mvc;
using System.Web.Routing;

namespace Vaultopia.Web
{
    public class MvcApplication : EPiServer.Global
    {
        protected void Application_Start()
        {
            AreaRegistration.RegisterAllAreas();
            RouteConfig.RegisterRoutes(RouteTable.Routes);
        }
    }
}
