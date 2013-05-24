using System.Linq;
using System.Web;
using System.Web.Mvc;
using System.Web.Routing;
using EPiServer.Framework;
using EPiServer.Framework.Initialization;
using ImageVault.EPiServer.Common.Handlers;

namespace Vaultopia.Web
{
    public class Global : EPiServer.Global
    {
        /// <summary>
        /// Application_s the start.
        /// </summary>
        protected void Application_Start()
        {
            AreaRegistration.RegisterAllAreas();

            RouteTable.Routes.MapRoute("Upload", "Gallery/UploadFile", new {controller = "Gallery", action = "UploadFile"});
            RouteTable.Routes.MapRoute("Save", "Gallery/Save", new { controller = "Gallery", action = "Save" });
        }
    }

    /// <summary>
    /// A custom route to use instead of the default imagevaultws
    /// that is added when initializing ImageVault,
    /// to bypass the content link issue.
    /// Todo: Remove when fixed in ImageVault
    /// </summary>
    public class MyRoute : Route {
        public MyRoute(string url, IRouteHandler handler):base(url,handler) { }

        public override VirtualPathData GetVirtualPath(RequestContext requestContext, RouteValueDictionary values)
        {
            return null;
        }
    }

    /// <summary>
    /// Dummy routehandler
    /// 
    /// Todo: Remove when fixed in ImageVault
    /// </summary>
    public class MyRouteHandler : IRouteHandler {
        /// <summary>
        /// Provides the object that processes the request.
        /// </summary>
        /// <param name="requestContext">An object that encapsulates information about the request.</param>
        /// <returns>
        /// An object that processes the request.
        /// </returns>
        public IHttpHandler GetHttpHandler(RequestContext requestContext) {
            return new MvcHandler(requestContext);
        }
    }

    /// <summary>
    /// Module that finds the default imagevaultws route and
    /// replaces it with a custom route.
    /// 
    /// Todo: Remove when fixed in ImageVault
    /// </summary>
    [InitializableModule, ModuleDependency(typeof(ImageVault.EPiServer.ImageVaultModule))]
    public class MyInitMod:IInitializableModule {
        /// <summary>
        /// Initializes the specified context.
        /// </summary>
        /// <param name="context">The context.</param>
        public void Initialize(InitializationEngine context) {

            // Find the imagevaultws route and remove it
            var route = RouteTable.Routes.Where(r => r.GetType() == typeof (Route))
                                  .Cast<Route>().Single(r => r.Url == "imagevaultws/{*value}");

            RouteTable.Routes.Remove(route);

            // Insert custom imagevaultws route
            var handler = new RestHandler("imagevaultws");
            RouteTable.Routes.Insert(0,new MyRoute("imagevaultws/{*value}",handler));

        }

        public void Uninitialize(InitializationEngine context) {
            //throw new System.NotImplementedException();
        }

        public void Preload(string[] parameters) {
            //throw new System.NotImplementedException();

        }
    }
}