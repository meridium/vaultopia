using System.Web.Mvc;
using EPiServer;
using EPiServer.Framework.DataAnnotations;
using EPiServer.ServiceLocation;
using EPiServer.Web.Mvc;
using ImageVault.Client;
using Vaultopia.Web.Models.Blocks;

namespace Vaultopia.Web.Controllers
{
    [TemplateDescriptor(/*Tags = new[] {"narrow"}, AvailableWithoutTag = false*/AvailableWithoutTag=true, Inherited = false, Name = "Contact")]
    public class ContactBlockController : BlockController<ContactBlock>
    {
        private readonly IContentRepository _repository;
        private readonly Client _client;


        public override ActionResult Index(ContactBlock currentBlock)
        {
                return PartialView(currentBlock);
        }

        public ContactBlockController()
        {
            _repository = ServiceLocator.Current.GetInstance<IContentRepository>();
            _client = ClientFactory.GetSdkClient();
        }
    }
}