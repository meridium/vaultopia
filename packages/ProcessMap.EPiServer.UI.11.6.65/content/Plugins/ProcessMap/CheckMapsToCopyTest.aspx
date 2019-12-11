<%@ Page Language="C#" AutoEventWireup="true" Inherits="System.Web.UI.Page" %>
<%@ Import Namespace="System.IO" %>
<%@ Import Namespace="EPiServer" %>
<%@ Import Namespace="EPiServer.Core" %>
<%@ Import Namespace="EPiServer.DataAbstraction" %>
<%@ Import Namespace="EPiServer.Filters" %>
<%@ Import Namespace="EPiServer.ServiceLocation" %>
<%@ Import Namespace="ProcessMap.EPiServer.Common" %>
<%@ Import Namespace="ProcessMap.EPiServer.Common.Extensions.ProcessMapExtension" %>
<%@ Import Namespace="ProcessMapEditor.Data.V3" %>


<!DOCTYPE html>

<html xmlns="http://www.w3.org/1999/xhtml">
<head id="Head1" runat="server">
    <title></title>
    <script runat="server">

        public Dictionary<int, List<string>> GetProcessMapPageTypes() {
            var pageTypes = new Dictionary<int, List<string>>();
            var processMapPropertyType = PageDefinitionType.Load("ProcessMap.EPiServer.Property.PropertyProcessMap", "ProcessMap.EPiServer");
            //Response.Write(processMapPropertyType.Name);
            foreach (PageType pt in PageType.List()) {

                foreach (var definition in pt.Definitions) {
                    if (definition.Type.Name == processMapPropertyType.Name) {
                        if (!pageTypes.ContainsKey(pt.ID)) {
                            pageTypes.Add(pt.ID, new List<string>());
                        }
                        var pageType = pageTypes[pt.ID];
                        pageType.Add(definition.Name);
                        //Response.Write(definition.Name);
                    }
                }
            }
            return pageTypes;
        }
        public string ProcessMapXmlDataPath {
            get {
                _webConfigXmlDataPath = BaseEPiUtil.WebConfigXMLDataPath;
                while (_webConfigXmlDataPath.EndsWith("\\") || _webConfigXmlDataPath.EndsWith("/")) {
                    _webConfigXmlDataPath = _webConfigXmlDataPath.Substring(0, _webConfigXmlDataPath.Length - 1);
                }
                return _webConfigXmlDataPath;
            }
        }
        private string _webConfigXmlDataPath;
        public static string ParseFilename(string identifier) {
            if (string.IsNullOrEmpty(identifier)) {
                return identifier;
            }
            if (identifier.Contains("|")) {
                identifier = identifier.Substring(0, identifier.IndexOf("|"));
            }
            return identifier;
        }
        public  ProcessMapPage[] GetPageCollection() {
            var pageTypes = GetProcessMapPageTypes();
            if (pageTypes.Count == 0)
                return new ProcessMapPage[0];

            var returnList = new List<ProcessMapPage>();
            var criterias = new PropertyCriteriaCollection();

            foreach (var pair in pageTypes) {
                var pageTypeId = pair.Key;
                criterias.Add(new PropertyCriteria {
                    Condition = CompareCondition.Equal,
                    Name = "PageTypeID",
                    Type = PropertyDataType.PageType,
                    Value = String.Format("{0}", pageTypeId),
                    Required = false
                });
            }

            //iterate all pages that has a processmap property
            var pc = DataFactory.Instance.FindPagesWithCriteria(ContentReference.StartPage, criterias);
            foreach (var pageData in pc) {

                //iterate all languages on that page
                var languages = DataFactory.Instance.GetLanguageBranches(pageData.PageLink);
                foreach (var page in languages) {
                    // Iterate published pages where a map really exists
                    if (page.PendingPublish || !pageTypes.ContainsKey(page.PageTypeID)) {
                        continue;
                    }
                    //iterate all properties
                    foreach (var propertyName in pageTypes[page.PageTypeID]) {
                        var prop = page.Property[propertyName];

                        //look for processmap properties
                        var propValue = prop != null ? prop.Value as ProcessMapDataType : null;
                        if (propValue == null || string.IsNullOrEmpty(propValue.Filename)) {
                            continue;
                        }

                        var ils = new LanguageSelector(page.LanguageBranch);
                        var pmp = new ProcessMapPage {
                            Language = page.LanguageID,
                            PropertyName = prop.Name,
                            PageName = page.PageName,
                            FileName = ParseFilename(propValue.Filename),
                            //BreadCrumb = GetBreadCrumb(page.ParentLink, ils)
                        };

                        if (string.IsNullOrEmpty(pmp.FileName)) continue;
                        var dir = new DirectoryInfo(ProcessMapXmlDataPath);
                        var fi = new FileInfo(Path.Combine(dir.FullName, pmp.FileName));
                        //en tom fil är inte 0 men den är mindre än 10
                        if (!fi.Exists || fi.Length <= 10) continue;
                        returnList.Add(pmp);
                    }
                }
            }

            return returnList.ToArray();
        }
    
    </script>
</head>
<body>
    <form id="form1" runat="server">
    <div id="main" runat="server">
        <%
            
            var pageTypes = GetProcessMapPageTypes();
            if (pageTypes.Count == 0) { %>
       <div>No pageTypes found.</div> 
        <% }
            var returnList = new List<ProcessMapPage>();
            var criterias = new PropertyCriteriaCollection();

            foreach (var pair in pageTypes) {
                var pageTypeId = pair.Key;
                criterias.Add(new PropertyCriteria {
                    Condition = CompareCondition.Equal,
                    Name = "PageTypeID",
                    Type = PropertyDataType.PageType,
                    Value = String.Format("{0}", pageTypeId),
                    Required = false,
                });
            }
            var languageBranchRepository = ServiceLocator.Current.GetInstance<ILanguageBranchRepository>();
            var languageBranches = languageBranchRepository.ListEnabled();
            var dict = new Dictionary<int, PageData>();
            foreach (var languageBranch in languageBranches) {
                %><div>Search language branch <%=languageBranch.Name %> (<%=languageBranch.LanguageID %>) for pages</div><%
                //iterate all pages that has a processmap property
                var pages = DataFactory.Instance.FindPagesWithCriteria(ContentReference.StartPage, criterias, languageBranch.LanguageID);
                foreach (var data in pages) {
                    if (!dict.ContainsKey(data.PageLink.ID)) {
                        dict.Add(data.PageLink.ID,data);
                    }
                }
            }
            var pc = dict.Values;    
            %>
        
        <div>Found <%=pc.Count %> pages based on a page template with a processmap property on it </div>
        <%
            foreach (var pageData in pc) {
                %><div><h1>Checking page <%=pageData.PageName %> (<%=pageData.PageLink.ID %>)</h1></div><%
                //iterate all languages on that page
                var languages = DataFactory.Instance.GetLanguageBranches(pageData.PageLink);
                %><div>Found <%=languages.Count %> languages for page</div><%
                foreach (var page in languages) {
                    %><div>Checking language <%=page.Language.Name %></div><%
                    // Iterate published pages where a map really exists
                    if (page.PendingPublish || !pageTypes.ContainsKey(page.PageTypeID)) {
                        %><div>Page contains no map</div><%
                        continue;
                    }
                    //iterate all properties
                    foreach (var propertyName in pageTypes[page.PageTypeID]) {
                                                %><div>Checking property <%=propertyName %></div><%

                        var prop = page.Property[propertyName];

                        //look for processmap properties
                        var propValue = prop != null ? prop.Value as ProcessMapDataType : null;
                        if (propValue == null || string.IsNullOrEmpty(propValue.Filename)) {
                                                    %><div>Ignoring property since it is no processmap property or has no content</div><%

                            continue;
                        }

                        //var ils = new LanguageSelector(page.LanguageBranch);
                        var pmp = new ProcessMapPage {
                            Language = page.LanguageID,
                            PropertyName = prop.Name,
                            PageName = page.PageName,
                            FileName = ParseFilename(propValue.Filename),
                            //BreadCrumb = GetBreadCrumb(page.ParentLink, ils)
                        };

                        if (string.IsNullOrEmpty(pmp.FileName)) {
                                                    %><div>No filename</div><%
continue;
                        }
                        var dir = new DirectoryInfo(ProcessMapXmlDataPath);
                        var fi = new FileInfo(Path.Combine(dir.FullName, pmp.FileName));
                        //en tom fil är inte 0 men den är mindre än 10
                        if (!fi.Exists || fi.Length <= 10) {
                                                    %><div>File does not exists or is empty</div><%
continue;
                        }
                        %><div style="font-weight: bold;color: green">Found process map:<%=pmp.FileName %></div><%

                        returnList.Add(pmp);
                    }
                }
            }
        
            
             %>
    </div>
    </form>
</body>
</html>
