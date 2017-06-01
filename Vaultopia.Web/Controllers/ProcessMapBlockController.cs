using System.Web.Mvc;
using EPiServer;
using EPiServer.Framework.DataAnnotations;
using EPiServer.ServiceLocation;
using EPiServer.Web.Mvc;
using ImageVault.Client;
using Vaultopia.Web.Models.Blocks;

namespace Vaultopia.Web.Controllers
{
    [TemplateDescriptor(Tags = new[] {"aside"}, AvailableWithoutTag = false, Inherited = false, Name = "AsideTeaser")]
    public class ProcessMapBlockController : BlockController<ProcessMapBlock>
    {
        public override ActionResult Index(ProcessMapBlock currentBlock)
        {
            return PartialView(currentBlock);
        }
    }
}