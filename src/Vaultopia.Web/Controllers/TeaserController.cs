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

            WebMedia media = null;
            // try to load, apply effects and resize the image
            if (currentBlock.TeaserImage != null) {
                media = _client.Load<WebMedia>(currentBlock.TeaserImage.Id)
                               .ApplyEffects(currentBlock.TeaserImage.Effects)
                               .Resize(218, 138, ResizeMode.ScaleToFill)
                .SingleOrDefault() ?? _client.Load<WebMedia>(currentBlock.TeaserImage.Id)
                                             .Resize(null, 138).SingleOrDefault();
            }

            var model = new TeaserBlockViewModel<TeaserBlock> {
                Block = currentBlock,
                Page = _repository.Get<PageData>(currentBlock.TeaserLink),
                WebMedia = media
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