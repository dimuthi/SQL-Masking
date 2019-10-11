CREATE PROCEDURE MaskPostalCodeWrapperProcedure 
	@originalDbName VARCHAR(MAX),
	@originalSchemaName VARCHAR(MAX),
	@originalTableName VARCHAR(MAX),
	@originalColumnName VARCHAR(MAX),
	@originalIdColumn VARCHAR(MAX),
	@substituteDbName VARCHAR(MAX),
	@substituteSchemaName VARCHAR(MAX),
	@substituteTableName VARCHAR(MAX),
	@substituteColumnName VARCHAR(MAX),
	@substituteIdColumn VARCHAR(MAX)
AS
BEGIN
	DECLARE @cnt INT=1;
	DECLARE @totalRows INT=0;
	CREATE TABLE #duplicatePost(
		ID INT NOT NULL IDENTITY(1,1),
		DuplicatePost varchar(max),
		SubstitutePost varchar(max)
	);
	DECLARE @sql NVARCHAR(MAX);
	CREATE Table #count(value INT);
	
	SET @sql='INSERT INTO #count(value) SELECT COUNT(*) FROM '+@originalDbName+'.'+@originalSchemaName+'.'+@originalTableName;
	EXEC sys.sp_executesql @sql
	SET @totalRows= (SELECT TOP(1) value FROM #count)
	DROP TABLE #count;

	SET @sql='INSERT INTO #duplicatePost(DuplicatePost) SELECT '+@originalDbName+'.'+@originalSchemaName+'.'+@originalTableName+'.'+@originalColumnName+
	' FROM '+@originalDbName+'.'+@originalSchemaName+'.'+@originalTableName+
	' GROUP BY '+@originalColumnName+
	' HAVING COUNT(*)>1';
	EXEC sys.sp_executesql @sql;

	DECLARE @totalDuplicateRows INT = (SELECT COUNT(*) FROM #duplicatePost );
	DECLARE @cntDuplicate INT=1;
	DECLARE @maskedPost varchar(max);
	DECLARE @currentPost varchar(max);

	WHILE @cntDuplicate <= @totalDuplicateRows
	BEGIN
		SET @currentPost=(SELECT #duplicatePost.DuplicatePost FROM #duplicatePost WHERE ID=@cntDuplicate);
		EXEC MaskPostalCodeAtomicProcedure @maskedPostalCode=@maskedPost OUTPUT;
		WHILE EXISTS (SELECT 1 FROM #duplicatePost WHERE SubstitutePost IN (@maskedPost))
		BEGIN
			EXEC MaskPostalCodeAtomicProcedure @maskedPostalCode=@maskedPost OUTPUT;
		END

		UPDATE #duplicatePost
		SET SubstitutePost=@maskedPost
		WHERE ID=@cntDuplicate
		SET @cntDuplicate=@cntDuplicate+1
	END

	WHILE @cnt <= @totalRows
	BEGIN
		DECLARE @postcode varchar(max);
		DECLARE @substitutepostcode varchar(max)
		SET @sql=N'( SELECT @currentPost= '+@originalDbName+'.'+@originalSchemaName+'.'+@originalTableName+'.'+@originalColumnName+' FROM '+@originalDbName+'.'+@originalSchemaName+'.'+@originalTableName+' WHERE '+@originalIdColumn+'='+CAST(@cnt AS VARCHAR(MAX))+')';
		EXEC sys.sp_executesql @sql,N'@currentPost NVARCHAR(MAX) OUTPUT', @currentPost=@postcode OUTPUT

		IF EXISTS (SELECT 1 FROM #duplicatePost WHERE DuplicatePost=@postcode)
		BEGIN
			SET @sql=N'( SELECT @substitutepostcode= SubstitutePost FROM #duplicatePost WHERE DuplicatePost = '''+@postcode+''')';
			EXEC sys.sp_executesql @sql,N'@substitutepostcode bigint OUTPUT',@substitutepostcode=@substitutepostcode OUTPUT

			SET @sql=N'UPDATE '+@substituteDbName+'.'+@substituteSchemaName+'.'+@substituteTableName+' SET '+@substituteColumnName+' = '+CAST(@substitutepostcode AS nvarchar(max))+'WHERE '+@substituteIdColumn+'='+CAST(@cnt AS VARCHAR(MAX));
			EXEC sys.sp_executesql @sql;
		END
		ELSE
		BEGIN
			DECLARE @maskedPostalCode varchar(max);
			DECLARE @repeatPostFlag INT=0;

			SET @sql=N'( SELECT @currentPost= '+@originalDbName+'.'+@originalSchemaName+'.'+@originalTableName+'.'+@originalColumnName+' FROM '+@originalDbName+'.'+@originalSchemaName+'.'+@originalTableName+' WHERE '+@originalIdColumn+'='+CAST(@cnt AS VARCHAR(MAX))+')';
			EXEC sys.sp_executesql @sql,N'@currentPost int OUTPUT', @currentPost=@postcode OUTPUT

			EXEC MaskPostalCodeAtomicProcedure @maskedPostalCode=@maskedPostalCode OUTPUT;

			SET @sql=N'SELECT @repeatValue=1 FROM '+@substituteDbName+'.'+@substituteSchemaName+'.'+@substituteTableName+' WHERE '+@substituteColumnName+' IN ('''+@maskedPostalCode+''')'
			EXEC sys.sp_executesql @sql,N'@repeatValue INT OUTPUT',@repeatValue=@repeatPostFlag OUTPUT

			WHILE  (@repeatPostFlag=1)
			BEGIN
				EXEC MaskPostalCodeAtomicProcedure @maskedPostalCode=@maskedPostalCode OUTPUT;
				SET @sql=N'SELECT @repeatValue=0 FROM '+@substituteDbName+'.'+@substituteSchemaName+'.'+@substituteTableName+' WHERE '''+@maskedPostalCode+''' NOT IN (SELECT '+@substituteColumnName+ ' FROM '+@substituteDbName+'.'+@substituteSchemaName+'.'+@substituteTableName+')'

				EXEC sys.sp_executesql @sql,N'@repeatValue INT OUTPUT',@repeatValue=@repeatPostFlag OUTPUT
			END

			SET @sql=N'UPDATE '+@substituteDbName+'.'+@substituteSchemaName+'.'+@substituteTableName+' SET '+@substituteColumnName+' = '+CAST(@maskedPostalCode AS varchar(max))+' WHERE '+@substituteIdColumn+'='+CAST(@cnt AS VARCHAR(MAX));
			EXEC sys.sp_executesql @sql
			
		END
		SET @cnt=@cnt+1
	END
END