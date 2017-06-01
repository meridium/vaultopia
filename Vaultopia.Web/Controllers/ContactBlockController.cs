using System.Web.Mvc;
using EPiServer.Framework.DataAnnotations;
using EPiServer.Web.Mvc;
using Vaultopia.Web.Models.Blocks;

namespace Vaultopia.Web.Controllers
{
    [TemplateDescriptor(/*Tags = new[] {"narrow"}, AvailableWithoutTag = false*/AvailableWithoutTag=true, Inherited = false, Name = "Contact")]
    public class ContactBlockController : BlockController<ContactBlock>
    {
        public override ActionResult Index(ContactBlock currentBlock)
        {
                return PartialView(currentBlock);
        }
    }
}