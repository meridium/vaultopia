--beginvalidatingquery
	if exists (select * from dbo.sysobjects where id = object_id(N'[dbo].[sp_DatabaseVersion]') and OBJECTPROPERTY(id, N'IsProcedure') = 1)
    begin
            if exists (select * from dbo.tblPropertyDefinitionType where AssemblyName = 'ImageVault.EPiServer7')
                 select 1, 'Upgrading database'
            else
 				select 0, 'No database upgrade is necessary'
    end
    else
            select -1, 'Not an EPiServer database'

--endvalidatingquery
GO
----------------------------------------------------------------------------------------------------
-- UpgradeEPiServer7.sql
--
-- Description:
--		This script upgrades the ImageVault properties of an existing EPiServer CMS 7 database to CMS 8.
--
-- History:
-- 2015-02-26	Created /rw
----------------------------------------------------------------------------------------------------
------------------------------------------
-- Step 1:
--		Transfer the propertytypes to the
--		new PropertyDefinitionTypes.
------------------------------------------
UPDATE tblPropertyDefinitionType 
SET AssemblyName ='ImageVault.EPiServer'
WHERE AssemblyName  IN('ImageVault.EPiServer7','ImageVault.EPiServer7.AddOn');

GO

------------------------------------------
-- Step 2:
--		Delete old Plugin-registrations.
------------------------------------------
DELETE FROM tblPlugin
WHERE AssemblyName = 'ImageVault.EPiServer7' OR AssemblyName = 'ImageVault.EPiServer7.AddOn';

GO
------------------------------------------
-- Step 3:
--		Remap dds from old assembly (ImageVault.EPiServer7.dll) to new assembly (ImageVault.EPiServer.dll)
------------------------------------------
UPDATE tblBigTableReference SET
ElementType='ImageVault.EPiServer.PropertyMediaSettings, ImageVault.EPiServer, Version=4.7.0.0, Culture=neutral, PublicKeyToken=null'
WHERE ElementType like 'ImageVault.EPiServer.PropertyMediaSettings, ImageVault.EPiServer7,%'

GO
UPDATE tblBigTable SET
ItemType='ImageVault.EPiServer.PropertyMediaSettings, ImageVault.EPiServer, Version=4.7.0.0, Culture=neutral, PublicKeyToken=null'
WHERE ItemType like 'ImageVault.EPiServer.PropertyMediaSettings, ImageVault.EPiServer7,%'
