using Vaultopia.Web.Models.ViewModels;

namespace Vaultopia.Web.Business
{
    /// <summary>
    /// 
    /// </summary>
    interface IModifyLayout
    {
        /// <summary>
        /// Modifies the layout.
        /// </summary>
        /// <param name="layoutModel">The layout model.</param>
        void ModifyLayout(LayoutModel layoutModel);
    }
}
