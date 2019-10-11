CREATE PROCEDURE DropIDColumnFromOriginalProcedure @originalDbname varchar(100),@originalSchemaname varchar(100),@originalTablename varchar(100),@dropColumnName varchar(100)
AS
BEGIN
	DECLARE @sql nvarchar(100);
	SET @sql='ALTER TABLE '+@originalDbname+'.'+@originalSchemaname+'.'+ @originalTablename+' DROP COLUMN '+@dropColumnName
	EXEC sys.sp_executesql @sql
END