CREATE PROCEDURE InsertIDColumnToMaskProcedure 
	@substituteDbName VARCHAR(MAX),
	@substituteSchemaName VARCHAR(MAX),
	@substituteTableName VARCHAR(MAX),
	@newColumnname VARCHAR(MAX),
	@noOfRows int
AS
BEGIN
	DECLARE @sql nvarchar(100);
	DECLARE @total int=@noOfRows;
	DECLARE @cnt int =1;
	SET @sql='ALTER TABLE '+@substituteDbName+'.'+@substituteSchemaName+'.'+ @substituteTableName+' ADD '+@newColumnname+' int NULL'
	EXEC sys.sp_executesql @sql
	WHILE(@cnt<=@total)
	BEGIN
		SET @sql='INSERT INTO '+@substituteDbName+'.'+@substituteSchemaName+'.'+ @substituteTableName+' ('+@newColumnname+') VALUES ('+CAST(@cnt AS Varchar(max))+')'
		EXEC sys.sp_executesql @sql
		SET @cnt =@cnt+1;
	END
	
END