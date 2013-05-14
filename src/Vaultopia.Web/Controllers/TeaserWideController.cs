using System.Linq;
using System.Web.Mvc;
using EPiServer;
using EPiServer.Core;
using EPiServer.Framework.DataAnnotations;
using EPiServer.ServiceLocation;
using EPiServer.Web.Mvc;
using ImageVault.Client;
using ImageVault.Client.Query;
using ImageVault.Common.Data;
using Vaultopia.Web.Models.Blocks;

namespace Vaultopia.Web.Controllers {
    [TemplateDescriptor(Tags = new [] { "wide" }, AvailableWithoutTag = false, Inherited = false, Name="TeaserWide")]
    public class TeaserWideController : BlockController<WideTeaserBlock> {

        private readonly IContentRepository _repository;
        private readonly Client _client;

        public TeaserWideController(/*IContentRepository repository*/) {
            
            //Why can't this be injected?
            var repository = ServiceLocator.Current.GetInstance<IContentRepository>();

            _repository = repository;
            _client = ClientFactory.GetSdkClient();
        }

        public override ActionResult Index(WideTeaserBlock currentBlock) {

            var model = new TeaserBlockViewModel<WideTeaserBlock> {
                                                     Block = currentBlock,
                                                     Page = _repository.Get<PageData>(currentBlock.TeaserLink),
                                                     WebMedia = _client.Load<WebMedia>(currentBlock.TeaserImage.Id).ApplyEffects(currentBlock.TeaserImage.Effects).Resize(237, 167, ResizeMode.ScaleToFill).Single()
                                                 };

            return PartialView(model);
        }
    }
}
