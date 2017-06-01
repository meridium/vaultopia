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
using ImageVault.EPiServer;
using Vaultopia.Web.Models.Blocks;
using Vaultopia.Web.ToIV;

namespace Vaultopia.Web.Controllers
{
    [TemplateDescriptor(Tags = new[] { "aside" }, AvailableWithoutTag = false, Inherited = false, Name = "AsideTeaser")]
    public class AsideTeaserBlockController : BlockController<AsideTeaserBlock>
    {
        private readonly IContentRepository _repository;
        private readonly Client _client;

        /// <summary>
        /// Indexes the specified current block.
        /// </summary>
        /// <param name="currentBlock">The current block.</param>
        /// <returns></returns>
        public override ActionResult Index(AsideTeaserBlock currentBlock)
        {
            var pms = new PropertyMediaSettings {Width = 412, Height = 277, ResizeMode = ResizeMode.ScaleToFill};

            var model = new TeaserBlockViewModel<AsideTeaserBlock>
            {
                Block = currentBlock,
                Page = _repository.Get<PageData>(currentBlock.TeaserLink),
                WebMedia = _client.Load<WebMedia>(currentBlock.TeaserImage, pms)
                    .UsedOn(nameof(AsideTeaserBlock)+nameof(currentBlock.TeaserImage))
                    .SingleOrDefault()
            };
            return PartialView(model);
        }

        /// <summary>
        /// Initializes a new instance of the <see cref="AsideTeaserBlockController" /> class.
        /// </summary>
        public AsideTeaserBlockController()
        {
            _repository = ServiceLocator.Current.GetInstance<IContentRepository>();
            _client = ClientFactory.GetSdkClient();
        }
    }
}