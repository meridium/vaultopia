using System.Linq;
using System.Web.Mvc;
using EPiServer;
using EPiServer.Core;
using EPiServer.ServiceLocation;
using EPiServer.Web.Mvc;
using ImageVault.Client;
using ImageVault.Client.Query;
using ImageVault.Common.Data;
using Vaultopia.Web.Models.Blocks;

namespace Vaultopia.Web.Controllers {
    public class TeaserController : BlockController<TeaserBlock> {
        private readonly IContentRepository _repository;
        private readonly Client _client;

        public TeaserController(/*IContentRepository repository*/) {
            
            //Why can't this be injected?
            var repository = ServiceLocator.Current.GetInstance<IContentRepository>();

            _repository = repository;
            _client = ClientFactory.GetSdkClient();
        }

        public override ActionResult Index(TeaserBlock currentBlock) {

            var model = new TeaserBlockViewModel {
                Block = currentBlock,
                Page = _repository.Get<PageData>(currentBlock.TeaserLink),
                WebMedia = _client.Load<WebMedia>(currentBlock.TeaserImage.Id).Resize(width: 280, height: 180, resizeMode: ResizeMode.ScaleToFill).Single()
            };

            return PartialView(model);
        }
    }
}
