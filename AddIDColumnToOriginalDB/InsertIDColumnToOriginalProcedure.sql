CREATE PROCEDURE InsertIDColumnToOriginalProcedure @originalDbname varchar(100),@originalSchemaname varchar(100),@originalTablename varchar(100),@newColumnname varchar(100)
AS
BEGIN
	DECLARE @sql nvarchar(100);
	SET @sql='ALTER TABLE '+@originalDbname+'.'+@originalSchemaname+'.'+ @originalTablename+' ADD '+@newColumnname+' int IDENTITY(1,1)'
	EXEC sys.sp_executesql @sql
END