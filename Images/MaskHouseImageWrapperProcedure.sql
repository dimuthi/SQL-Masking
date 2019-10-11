CREATE PROCEDURE MaskHouseImageWrapperProcedure(
	
	@dbName VARCHAR(MAX),
	@schemaName VARCHAR(MAX),
	@tableName VARCHAR(MAX),
	@columnName VARCHAR(MAX),
	@substituteDbName VARCHAR(MAX),
	@substituteSchemaName VARCHAR(MAX),
	@substituteTableName VARCHAR(MAX),
	@substituteColumnName VARCHAR(MAX),
	@substituteIdColumnName VARCHAR(MAX)
)
AS
BEGIN
	
		DECLARE @cnt INT=1;
		DECLARE @totalRows INT=0;
		DECLARE @sql NVARCHAR(MAX);
		DECLARE @maskedImage VARBINARY(MAX)
		CREATE Table #count(value INT);
		
		SET @sql='INSERT INTO #count(value) SELECT COUNT(*) FROM '+@dbName+'.'+@schemaName+'.'+@tableName;
		EXEC sys.sp_executesql @sql

		SET @totalRows= (SELECT TOP(1) value FROM #count)
		DROP TABLE #count;

		WHILE @cnt<=@totalRows
		BEGIN
			EXEC MaskImageAtomicProcedure @type='house',@maskedImage=@maskedImage OUTPUT
			SET @sql=N'UPDATE '+@substituteDbName+'.'+@substituteSchemaName+'.'+@substituteTableName+' SET '+@substituteColumnName+' = @maskedImage'+' WHERE '+@substituteIdColumnName+' ='+CAST(@cnt AS VARCHAR(MAX));
			EXEC sys.sp_executesql @sql,N'@maskedImage VARBINARY(MAX)',@maskedImage
			SET @cnt=@cnt+1
		END
		
END
GO

