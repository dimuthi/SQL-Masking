CREATE PROCEDURE DropIDColumnFromMaskProcedure 
	@substituteDbName VARCHAR(MAX),
	@substituteSchemaName VARCHAR(MAX),
	@substituteTableName VARCHAR(MAX),
	@dropColumnName VARCHAR(MAX)
AS
BEGIN
	DECLARE @sql nvarchar(100);
	SET @sql='ALTER TABLE '+@substituteDbName+'.'+@substituteSchemaName+'.'+ @substituteTableName+' DROP COLUMN '+@dropColumnName
	EXEC sys.sp_executesql @sql
END