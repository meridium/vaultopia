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

            // abort if the the property is empty
            if (currentBlock.TeaserImage == null) {
                return new EmptyResult();
            }

            // try to load, apply effects and resize the image
            var media = _client.Load<WebMedia>(currentBlock.TeaserImage.Id)
                               .ApplyEffects(currentBlock.TeaserImage.Effects)
                               .Resize(237, 167, ResizeMode.ScaleToFill)
                               .SingleOrDefault();

            // abort if media is not an image
            if (media == null) {
                return new EmptyResult();
            }

            var model = new TeaserBlockViewModel<WideTeaserBlock>
                {
                    Block = currentBlock,
                    Page = _repository.Get<PageData>(currentBlock.TeaserLink),
                    WebMedia = media
                        
                };

            return PartialView(model);
        }
    }
}