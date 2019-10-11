CREATE PROCEDURE MaskTimeWithRangeWrapperProcedure(

	@originalDbName VARCHAR(MAX),
	@originalSchemaName VARCHAR(MAX),
	@originalTableName VARCHAR(MAX),
	@originalColumnName1 VARCHAR(MAX),
	@originalColumnName2 VARCHAR(MAX),
	@substituteDbName VARCHAR(MAX),
	@substituteSchemaName VARCHAR(MAX),
	@substituteTableName VARCHAR(MAX),
	@substituteColumnName1 VARCHAR(MAX),
	@substituteColumnName2 VARCHAR(MAX),
	@substituteIdColumnName VARCHAR(MAX),
	@maskTillMillisecondFlag INT,
	@range INT,
	@type VARCHAR(10)
)
AS
BEGIN
		DECLARE @cnt INT=1;
		DECLARE @totalRows INT=0;
		DECLARE @sql NVARCHAR(MAX);
		CREATE Table #count(value INT);
		
		SET @sql='INSERT INTO #count(value) SELECT COUNT(*) FROM '+@originalDbName+'.'+@originalSchemaName+'.'+@originalTableName;
		EXEC sys.sp_executesql @sql

		SET @totalRows= (SELECT TOP(1) value FROM #count)
		DROP TABLE #count;

		IF(@maskTillMillisecondFlag=0)
		BEGIN
			DECLARE @maskStartTimeSeconds TIME(0);
			DECLARE @maskFinishTimeSeconds TIME(0);
		END
		ELSE
		BEGIN
			DECLARE @maskStartTimeMilliseconds TIME(7);
			DECLARE @maskFinishTimeMilliseconds TIME(7);
		END

		WHILE @cnt <= @totalRows
		BEGIN

				IF(@maskTillMillisecondFlag=0)
				BEGIN
					EXEC MaskTimeTillSecondsWithRangeAtomicProcedure @range=@range,@type=@type,@maskedStartTimeSeconds=@maskStartTimeSeconds  OUTPUT,@maskedFinishTimeSeconds=@maskFinishTimeSeconds  OUTPUT

					SET @sql=N'UPDATE '+@substituteDbName+'.'+@substituteSchemaName+'.'+@substituteTableName+' SET '+@substituteColumnName1+' = '''+CAST(@maskStartTimeSeconds AS VARCHAR)+''','+@substituteColumnName2+' = '''+CAST(@maskFinishTimeSeconds AS VARCHAR)+''''+' WHERE '+@substituteIdColumnName+' ='+CAST(@cnt AS VARCHAR(MAX));
					EXEC sys.sp_executesql @sql
				END
				ELSE
				BEGIN
					EXEC MaskTimeTillMillisecondsWithRangeAtomicProcedure  @range=@range,@type=@type,@maskedStartTimeMilliseconds=@maskStartTimeMilliseconds  OUTPUT,@maskedFinishTimeMilliseconds=@maskFinishTimeMilliseconds  OUTPUT

					SET @sql=N'UPDATE '+@substituteDbName+'.'+@substituteSchemaName+'.'+@substituteTableName+' SET '+@substituteColumnName1+' = '''+CAST(@maskStartTimeMilliseconds AS VARCHAR)+''','+@substituteColumnName2+' = '''+CAST(@maskFinishTimeMilliseconds AS VARCHAR)+''''+' WHERE '+@substituteIdColumnName+' ='+CAST(@cnt AS VARCHAR(MAX));
					EXEC sys.sp_executesql @sql
				END

			SET @cnt=@cnt+1
		END
END
GO

