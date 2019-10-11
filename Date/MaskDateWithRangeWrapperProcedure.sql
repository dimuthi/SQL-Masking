CREATE PROCEDURE MaskDateWithRangeWrapperProcedure(
	@startingDate DATE,
	@range INT,
	@type VARCHAR(10),
	@originalDbName VARCHAR(MAX),
	@originalSchemaName VARCHAR(MAX),
	@originalTableName VARCHAR(MAX),
	@originalColumnName1 VARCHAR(MAX),
	@originalColumnName2 VARCHAR(MAX),
	@originalIdColumn VARCHAR(MAX),
	@substituteDbName VARCHAR(MAX),
	@substituteSchemaName VARCHAR(MAX),
	@substituteTableName VARCHAR(MAX),
	@substituteColumnName1 VARCHAR(MAX),
	@substituteColumnName2 VARCHAR(MAX),
	@substituteIdColumn VARCHAR(MAX)
)
AS
BEGIN

		DECLARE @cnt INT = 1;
		DECLARE @totalRows INT;
		DECLARE @sql NVARCHAR(MAX);
		CREATE Table #count(value INT);
		DECLARE @maskedStartDate DATE;
		DECLARE @maskedFinishDate DATE


		SET @sql='INSERT INTO #count(value) SELECT COUNT(*) FROM '+@originalDbName+'.'+@originalSchemaName+'.'+@originalTableName;
		EXEC sys.sp_executesql @sql

		SET @totalRows= (SELECT TOP(1) value FROM #count)
		DROP TABLE #count;

		WHILE @cnt<=@totalRows
		BEGIN
		
			EXEC MaskDateWithRangeAtomicProcedure @startYear=@startingDate,@range=@range,@type=@type,@startDate=@maskedStartDate OUTPUT,@finishDate=@maskedFinishDate OUTPUT;

			SET @sql=N'UPDATE '+@substituteDbName+'.'+@substituteSchemaName+'.'+@substituteTableName+' SET '+@substituteColumnName1+' = '''+CAST(@maskedStartDate AS VARCHAR)+''','+@substituteColumnName2+' = '''+CAST(@maskedFinishDate AS VARCHAR)+''''+' WHERE '+@substituteIdColumn+' ='+CAST(@cnt AS VARCHAR(MAX));
			EXEC sys.sp_executesql @sql
		
			SET @cnt=@cnt+1
		END
END
GO

