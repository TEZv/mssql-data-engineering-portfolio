USE master;
GO

IF DB_ID(N'MediaPerformancePortfolio') IS NULL
    CREATE DATABASE MediaPerformancePortfolio;
GO

ALTER DATABASE MediaPerformancePortfolio SET RECOVERY SIMPLE;
ALTER DATABASE MediaPerformancePortfolio SET READ_COMMITTED_SNAPSHOT ON WITH ROLLBACK IMMEDIATE;
GO

USE MediaPerformancePortfolio;
GO

IF NOT EXISTS (SELECT 1 FROM sys.schemas WHERE name = N'stg') EXEC(N'CREATE SCHEMA stg');
IF NOT EXISTS (SELECT 1 FROM sys.schemas WHERE name = N'ref') EXEC(N'CREATE SCHEMA ref');
IF NOT EXISTS (SELECT 1 FROM sys.schemas WHERE name = N'mart') EXEC(N'CREATE SCHEMA mart');
IF NOT EXISTS (SELECT 1 FROM sys.schemas WHERE name = N'etl') EXEC(N'CREATE SCHEMA etl');
IF NOT EXISTS (SELECT 1 FROM sys.schemas WHERE name = N'audit') EXEC(N'CREATE SCHEMA audit');
GO
