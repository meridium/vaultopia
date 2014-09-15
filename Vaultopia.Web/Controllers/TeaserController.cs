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
    [TemplateDescriptor(Tags = new[] {"narrow"}, AvailableWithoutTag = false, Inherited = false, Name = "Teaser")]
    public class TeaserController : BlockController<TeaserBlock> {
        private readonly Client _client;
        private readonly IContentRepository _repository;

        /// <summary>
        /// Indexes the specified current block.
        /// </summary>
        /// <param name="currentBlock">The current block.</param>
        /// <returns></returns>
        public override ActionResult Index(TeaserBlock currentBlock) {

            var model = new TeaserBlockViewModel<TeaserBlock> {
                Block = currentBlock,
                Page = _repository.Get<PageData>(currentBlock.TeaserLink),
               
            };

            return PartialView(model);
        }

        /// <summary>
        /// Initializes a new instance of the <see cref="TeaserController"/> class.
        /// </summary>
        public TeaserController() {
            var repository = ServiceLocator.Current.GetInstance<IContentRepository>();
            _repository = repository;
            _client = ClientFactory.GetSdkClient();
        }
    }
}