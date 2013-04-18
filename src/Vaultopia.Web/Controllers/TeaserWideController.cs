using System.Web.Mvc;
using EPiServer;
using EPiServer.Core;
using EPiServer.Framework.DataAnnotations;
using EPiServer.ServiceLocation;
using EPiServer.Web.Mvc;
using Vaultopia.Web.Models.Blocks;

namespace Vaultopia.Web.Controllers {
    [TemplateDescriptor(Tags = new [] { "wide" }, AvailableWithoutTag = false, Inherited = false, Name="TeaserWide")]
    public class TeaserWideController : BlockController<TeaserBlock> {

        private readonly IContentRepository _repository;

        public TeaserWideController(/*IContentRepository repository*/) {
            
            //Why can't this be injected?
            var repository = ServiceLocator.Current.GetInstance<IContentRepository>();

            _repository = repository;
        }

        public override ActionResult Index(TeaserBlock currentBlock) {

            var model = new TeaserBlockViewModel {
                                                     Block = currentBlock,
                                                     Page = _repository.Get<PageData>(currentBlock.TeaserLink)
                                                 };

            return PartialView(model);
        }
    }
}
