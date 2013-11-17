-- Give SharePoint Installation account (e.g. spsetup) correct server role 
USE [master] 
GO
CREATE LOGIN [splive360\svcspsetup] FROM WINDOWS WITH DEFAULT_DATABASE=[master] 
GO 
EXEC master..sp_addsrvrolemember @loginame = N'splive360\svcspsetup', @rolename = N'dbcreator' 
GO 
EXEC master..sp_addsrvrolemember @loginame = N'splive360\svcspsetup', @rolename = N'securityadmin' 
GO

-- Set MAXDOP
EXEC sys.sp_configure N'show advanced options', N'1'  RECONFIGURE WITH OVERRIDE 
GO 
EXEC sys.sp_configure N'max degree of parallelism', N'1' 
GO 
RECONFIGURE WITH OVERRIDE 
GO 
EXEC sys.sp_configure N'show advanced options', N'0'  RECONFIGURE WITH OVERRIDE 
GO 

-- Restrict Maximum Memory 
EXEC sys.sp_configure N'show advanced options', N'1'  RECONFIGURE WITH OVERRIDE 
GO
EXEC sys.sp_configure N'max server memory (MB)', N'6144'
GO 
RECONFIGURE WITH OVERRIDE
GO 
EXEC sys.sp_configure N'show advanced options', N'0'  RECONFIGURE WITH OVERRIDE
GO 
    
-- Set Model database to Simple for Development
/*
USE [master]
GO 
ALTER DATABASE [model] SET RECOVERY SIMPLE WITH NO_WAIT 
GO
*/