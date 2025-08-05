/* ⚠️ WARNING ⚠️
   Running the script below will forcefully disconnect all users
   and roll back any active transactions immediately.

   If you are connected to this database, you will be disconnected.

   This may result in data loss for any unsaved work.

   Do NOT run this unless you are absolutely sure.
*/

USE master;
GO

-- Drop and recreate the 'DataWarehouse' database
IF EXISTS(SELECT 1 FROM sys.databases WHERE name = 'DataWarehouse')
BEGIN
	-- Set the database to SINGLE_USER mode
	-- Allows only one user connection at a time
	-- Immediately disconnect all other users
	-- Rolls back any uncommitted transactions
	ALTER DATABASE DataWarehouse SET SINGLE_USER WITH ROLLBACK IMMEDIATE;
	DROP DATABASE DataWarehouse;
END;
GO

-- Create the 'DataWarehouse' database
CREATE DATABASE DataWarehouse;
GO
USE DataWarehouse;
GO

-- Create Schemas
CREATE SCHEMA bronze;
GO
CREATE SCHEMA silver;
GO
CREATE SCHEMA gold;
GO