using System;
using System.Collections.Generic;
using System.Linq;
using System.Web;
using System.Web.Mvc;
using EPiServer;
using EPiServer.Core;
using EPiServer.Framework.DataAnnotations;
using EPiServer.ServiceLocation;
using EPiServer.Web;
using EPiServer.Web.Mvc;
using ImageVault.Client;
using ImageVault.Client.Query;
using ImageVault.Common.Data;
using Vaultopia.Web.Models.Blocks;

namespace Vaultopia.Web.Controllers
{
    [TemplateDescriptor(Tags = new[] {"aside"}, AvailableWithoutTag = false, Inherited = false, Name = "AsideTeaser")]
    public class ProcessMapBlockController : BlockController<ProcessMapBlock>
    {
        private readonly IContentRepository _repository;
        private readonly Client _client;

        public override ActionResult Index(ProcessMapBlock currentBlock)
        {
            return PartialView(currentBlock);
        }





        /// <summary>
        /// Initializes a new instance of the <see cref="Vaultopia.Web.Controllers.ProcessMapBlockController" /> class.
        /// </summary>
        public ProcessMapBlockController()
        {
            _repository = ServiceLocator.Current.GetInstance<IContentRepository>();
            ;
            _client = ClientFactory.GetSdkClient();
        }
    }
}
    




