--beginvalidatingquery
	if exists (select * from dbo.sysobjects where id = object_id(N'[dbo].[sp_DatabaseVersion]') and OBJECTPROPERTY(id, N'IsProcedure') = 1)
    begin
            if exists (select * from dbo.tblPropertyDefinitionType where AssemblyName IN('ProcessMap.EPiServer7', 'ProcessMap.EPiServer75'))
                 select 1, 'Upgrading database'
            else
 				select 0, 'No database upgrade is necessary'
    end
    else
            select -1, 'Not an EPiServer database'

--endvalidatingquery
GO
----------------------------------------------------------------------------------------------------
-- UpgradeProcessMapEPi7.sql
--
-- Description:
--		This script upgrades the ProcessMap properties of an existing EPiServer CMS 7 database to CMS 8.
--
-- History:
-- 2015-09-03	Created /rb
----------------------------------------------------------------------------------------------------
------------------------------------------
-- Step 1:
--		Replace old assembly names with new
------------------------------------------
UPDATE pdt1
SET pdt1.AssemblyName ='ProcessMap.EPiServer', pdt1.TypeName = 'ProcessMap.EPiServer.Property.PropertyProcessMap'
FROM tblPropertyDefinitionType as pdt1
WHERE pdt1.AssemblyName IN ('ProcessMap.EPiServer7', 'ProcessMap.EPiServer75');

GO
------------------------------------------
-- Step 2:
--		Delete old Plugin-registrations.
------------------------------------------
DELETE FROM tblPlugin
WHERE AssemblyName IN ('ProcessMap.EPiServer7', 'ProcessMap.EPiServer75');

GO
------------------------------------------
-- Step 3:
--		Remap dds from old assemblies (ProcessMap.EPiServer7.dll, ProcessMap.EPiServer75.dll) to new assembly (ProcessMap.EPiServer.dll)
------------------------------------------
UPDATE tblBigTableReference SET
ElementType='ProcessMap.EPiServer.Property.PropertyProcessMapSettings, ProcessMap.EPiServer, Version=3.4.0.0, Culture=neutral, PublicKeyToken=null'
WHERE ElementType like 'ProcessMap.EPiServer7%.Property.PropertyProcessMapSettings, ProcessMap.EPiServer7%,%'

GO
UPDATE tblBigTable SET
ItemType='ProcessMap.EPiServer.Property.PropertyProcessMapSettings, ProcessMap.EPiServer, Version=3.4.0.0, Culture=neutral, PublicKeyToken=null'
WHERE ItemType like 'ProcessMap.EPiServer7%.Property.PropertyProcessMapSettings, ProcessMap.EPiServer7%,%'
