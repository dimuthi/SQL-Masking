CREATE PROCEDURE MaskNICNumberWrapperProcedure
	@originalDbName VARCHAR(MAX),
	@originalSchemaName VARCHAR(MAX),
	@originalTableName VARCHAR(MAX),
	@originalColumnName VARCHAR(MAX),
	@originalIdColumn VARCHAR(MAX),
	@substituteDbName VARCHAR(MAX),
	@substituteSchemaName VARCHAR(MAX),
	@substituteTableName VARCHAR(MAX),
	@substituteColumnName VARCHAR(MAX),
	@substituteIdColumn VARCHAR(MAX),
	@yearRange int
AS
BEGIN
	DECLARE @cnt INT=1;
	DECLARE @totalRows INT=0;
	DECLARE @OriginalrowNumber int;
	CREATE TABLE #duplicateNic(
	ID INT NOT NULL IDENTITY(1,1),
	DuplicateNic varchar(max),
	SubstituteNic varchar(max)
	);
	DECLARE @sql NVARCHAR(MAX);
	CREATE Table #count(value INT);
	
	SET @sql='INSERT INTO #count(value) SELECT COUNT(*) FROM '+@originalDbName+'.'+@originalSchemaName+'.'+@originalTableName;
	EXEC sys.sp_executesql @sql

	SET @totalRows= (SELECT TOP(1) value FROM #count)
	DROP TABLE #count;

	SET @sql='INSERT INTO #duplicateNic(DuplicateNic) SELECT '+@originalDbName+'.'+@originalSchemaName+'.'+@originalTableName+'.'+@originalColumnName+
	' FROM '+@originalDbName+'.'+@originalSchemaName+'.'+@originalTableName+
	' GROUP BY '+@originalColumnName+
	' HAVING COUNT(*)>1';
	EXEC sys.sp_executesql @sql;

	DECLARE @totalDuplicateRows INT = (SELECT COUNT(*) FROM #duplicateNic );
	DECLARE @cntDuplicate INT=1;
	DECLARE @maskedNic varchar(max);
	DECLARE @currentNic varchar(max);

	WHILE @cntDuplicate <= @totalDuplicateRows
	BEGIN
		SET @OriginalrowNumber = @cntDuplicate
		SET @currentNic=(SELECT #duplicateNic.DuplicateNic FROM #duplicateNic WHERE ID=@cntDuplicate);
		EXEC MaskNICNumberAtomicProcedure @originalDbName, @originalSchemaName, @originalTableName, @originalColumnName,@originalIdColumn,@OriginalrowNumber,@yearRange,@maskedNicNum=@maskedNic OUTPUT;

		WHILE EXISTS (SELECT 1 FROM #duplicateNic WHERE SubstituteNic IN (@maskedNic))
		BEGIN
			EXEC MaskNICNumberAtomicProcedure @originalDbName, @originalSchemaName, @originalTableName, @originalColumnName,@originalIdColumn,@OriginalrowNumber,@yearRange,@maskedNicNum=@maskedNic OUTPUT;
		END

		UPDATE #duplicateNic
		SET SubstituteNic=@maskedNic
		WHERE ID=@cntDuplicate
		SET @cntDuplicate=@cntDuplicate+1
	END

	WHILE @cnt <= @totalRows
	BEGIN
		SET @OriginalrowNumber = @cnt
		DECLARE @nicnum varchar(max);
		DECLARE @substitutenicnum varchar(max)
		SET @sql=N'( SELECT @currentNic= '+@originalDbName+'.'+@originalSchemaName+'.'+@originalTableName+'.'+@originalColumnName+' FROM '+@originalDbName+'.'+@originalSchemaName+'.'+@originalTableName+' WHERE '+@originalIdColumn+'='+CAST(@cnt AS VARCHAR(MAX))+')';
		EXEC sys.sp_executesql @sql,N'@currentNic NVARCHAR(MAX) OUTPUT', @currentNic=@nicnum OUTPUT
		IF EXISTS (SELECT 1 FROM #duplicateNic WHERE DuplicateNic=@nicnum)
		BEGIN
			SET @sql=N'( SELECT @substitutenicnum= SubstituteNic FROM #duplicateNic WHERE DuplicateNic = '''+@nicnum+''')';
			EXEC sys.sp_executesql @sql,N'@substitutenicnum varchar(max) OUTPUT',@substitutenicnum=@substitutenicnum OUTPUT

			SET @sql=N'UPDATE '+@substituteDbName+'.'+@substituteSchemaName+'.'+@substituteTableName+' SET '+@substituteColumnName+' = '''+CAST(@substitutenicnum AS nvarchar(max))+'''WHERE '+@substituteIdColumn+'='+CAST(@cnt AS VARCHAR(MAX));
			EXEC sys.sp_executesql @sql;
		END
		ELSE
		BEGIN
			DECLARE @maskedNicNum varchar(max);
			DECLARE @repeatNicFlag INT=0;
			SET @sql=N'( SELECT @currentNic= '+@originalDbName+'.'+@originalSchemaName+'.'+@originalTableName+'.'+@originalColumnName+' FROM '+@originalDbName+'.'+@originalSchemaName+'.'+@originalTableName+' WHERE '+@originalIdColumn+'='+CAST(@cnt AS VARCHAR(MAX))+')';
			EXEC sys.sp_executesql @sql,N'@currentNic varchar(max) OUTPUT', @currentNic=@nicnum OUTPUT

			EXEC MaskNICNumberAtomicProcedure @originalDbName, @originalSchemaName, @originalTableName, @originalColumnName,@originalIdColumn,@OriginalrowNumber,@yearRange,@maskedNicNum=@maskedNicNum OUTPUT;

			SET @sql=N'SELECT @repeatValue=1 FROM '+@substituteDbName+'.'+@substituteSchemaName+'.'+@substituteTableName+' WHERE '+@substituteColumnName+' IN ('''+@maskedNicNum+''')'
			EXEC sys.sp_executesql @sql,N'@repeatValue INT OUTPUT',@repeatValue=@repeatNicFlag OUTPUT
			WHILE  (@repeatNicFlag=1)
			BEGIN
				EXEC MaskNICNumberAtomicProcedure @originalDbName, @originalSchemaName, @originalTableName, @originalColumnName,@originalIdColumn,@OriginalrowNumber,@yearRange,@maskedNicNum=@maskedNicNum OUTPUT;
				
				SET @sql=N'SELECT @repeatValue=0 FROM '+@substituteDbName+'.'+@substituteSchemaName+'.'+@substituteTableName+' WHERE '''+@maskedNicNum+''' NOT IN (SELECT '+@substituteColumnName+ ' FROM '+@substituteDbName+'.'+@substituteSchemaName+'.'+@substituteTableName+')'

				EXEC sys.sp_executesql @sql,N'@repeatValue INT OUTPUT',@repeatValue=@repeatNicFlag OUTPUT
			END

			SET @sql=N'UPDATE '+@substituteDbName+'.'+@substituteSchemaName+'.'+@substituteTableName+' SET '+@substituteColumnName+' = '''+CAST(@maskedNicNum AS varchar(max))+''' WHERE '+@substituteIdColumn+'='+CAST(@cnt AS VARCHAR(MAX));
			EXEC sys.sp_executesql @sql
			
		END
		SET @cnt=@cnt+1
	END
	
END