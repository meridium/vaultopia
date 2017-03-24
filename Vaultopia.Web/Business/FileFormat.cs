using EPiServer.Core;
using EPiServer.DataAnnotations;
using EPiServer.Framework.DataAnnotations;

namespace Vaultopia.Web.Business
{
    [ContentType]
    [MediaDescriptor(ExtensionString = "pdf,doc,docx,xls,xlsx,ppt,pptx,eps,ai,dwg,indd,ps,tif,tiff")]
    public class FileFormat : MediaData
    {
    }

}