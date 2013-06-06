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
    [TemplateDescriptor(Tags = new[] {"wide"}, AvailableWithoutTag = false, Inherited = false, Name = "TeaserWide")]
    public class TeaserWideController : BlockController<WideTeaserBlock> {
        private readonly Client _client;
        private readonly IContentRepository _repository;

        /// <summary>
        /// Initializes a new instance of the <see cref="TeaserWideController" /> class.
        /// </summary>
        public TeaserWideController() {
            _repository = ServiceLocator.Current.GetInstance<IContentRepository>(); ;
            _client = ClientFactory.GetSdkClient();
        }

        /// <summary>
        /// Indexes the specified current block.
        /// </summary>
        /// <param name="currentBlock">The current block.</param>
        /// <returns></returns>
        public override ActionResult Index(WideTeaserBlock currentBlock) {

            WebMedia media = null;
            // try to load, apply effects and resize the image
            if (currentBlock.WideTeaserImage != null) {
                media = _client.Load<WebMedia>(currentBlock.WideTeaserImage.Id)
                               .ApplyEffects(currentBlock.WideTeaserImage.Effects)
                               .Resize(237, 167, ResizeMode.ScaleToFill)
                               .SingleOrDefault();
            }

            var model = new TeaserBlockViewModel<WideTeaserBlock>
                {
                    Block = currentBlock,
                    Page = _repository.Get<PageData>(currentBlock.WideTeaserLink),
                    WebMedia = media
                };

            return PartialView(model);
        }
    }
}