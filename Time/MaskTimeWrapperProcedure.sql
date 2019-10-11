CREATE PROCEDURE MaskTimeWrapperProcedure(

	@originalDbName VARCHAR(MAX),
	@originalSchemaName VARCHAR(MAX),
	@originalTableName VARCHAR(MAX),
	@originalColumnName VARCHAR(MAX),
	@substituteDbName VARCHAR(MAX),
	@substituteSchemaName VARCHAR(MAX),
	@substituteTableName VARCHAR(MAX),
	@substituteColumnName VARCHAR(MAX),
	@substituteIdColumnName VARCHAR(MAX),
	@maskTillMillisecondFlag INT
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
			DECLARE @maskTimeSeconds TIME(0);
		END
		ELSE
		BEGIN
			DECLARE @maskTimeMilliseconds TIME(7);
		END

		WHILE @cnt <= @totalRows
		BEGIN

				IF(@maskTillMillisecondFlag=0)
				BEGIN
					EXEC MaskTimeTillSecondsAtomicProcedure @time=@maskTimeSeconds OUTPUT
				
					SET @sql=N'UPDATE '+@substituteDbName+'.'+@substituteSchemaName+'.'+@substituteTableName+' SET '+@substituteColumnName+' = '''+CAST(@maskTimeSeconds AS VARCHAR)+''' WHERE '+@substituteIdColumnName+' ='+CAST(@cnt AS VARCHAR(MAX));
					EXEC sys.sp_executesql @sql
				END
				ELSE
				BEGIN
					EXEC MaskTimeTillMillisecondsAtomicProcedure @time=@maskTimeMilliseconds OUTPUT

					SET @sql=N'UPDATE '+@substituteDbName+'.'+@substituteSchemaName+'.'+@substituteTableName+' SET '+@substituteColumnName+' = '''+CAST(@maskTimeMilliseconds AS VARCHAR)+''' WHERE '+@substituteIdColumnName+' ='+CAST(@cnt AS VARCHAR(MAX));
					EXEC sys.sp_executesql @sql
				END

			SET @cnt=@cnt+1
		END
END
GO

