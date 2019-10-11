CREATE PROCEDURE MaskDateWrapperProcedure(
	@startingDate DATE,
	@yearRange INT,
	@substituteDbName VARCHAR(MAX),
	@substituteSchemaName VARCHAR(MAX),
	@substituteTableName VARCHAR(MAX),
	@substituteColumnName VARCHAR(MAX),
	@substituteIdColumn VARCHAR(MAX)

)
AS
BEGIN

		DECLARE @cnt INT = 1;
		DECLARE @totalRows INT;
		DECLARE @sql NVARCHAR(MAX);
		CREATE Table #count(value INT);
		DECLARE @maskedDate VARCHAR(MAX)
		DECLARE @currentDate VARCHAR(MAX)
			

		SET @sql='INSERT INTO #count(value) SELECT COUNT(*) FROM '+@substituteDbName+'.'+@substituteSchemaName+'.'+@substituteTableName;
		EXEC sys.sp_executesql @sql

		SET @totalRows= (SELECT TOP(1) value FROM #count)
		DROP TABLE #count;

		WHILE @cnt<=@totalRows
		BEGIN
		
			EXEC MaskDateAtomicProcedure @startingDate=@startingDate,@yearRange=@yearRange,@maskedRandomDate=@maskedDate OUTPUT;
			SET @sql=N'UPDATE '+@substituteDbName+'.'+@substituteSchemaName+'.'+@substituteTableName+' SET '+@substituteColumnName+' = '''+CAST(@maskedDate AS VARCHAR)+''' WHERE '+@substituteIdColumn+' ='+CAST(@cnt AS VARCHAR(MAX));
			EXEC sys.sp_executesql @sql
		
			SET @cnt=@cnt+1
		END
END
GO

