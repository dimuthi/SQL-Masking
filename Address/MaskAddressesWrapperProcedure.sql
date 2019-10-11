CREATE PROCEDURE MaskAddressesWrapperProcedure 
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
	CREATE TABLE #duplicateAddresses(
		ID INT NOT NULL IDENTITY(1,1),
		DuplicateAddress varchar(max),
		SubstituteAddress varchar(max)
	);
	DECLARE @sql NVARCHAR(MAX);
	CREATE Table #count(value INT);
		
	SET @sql='INSERT INTO #count(value) SELECT COUNT(*) FROM '+@originalDbName+'.'+@originalSchemaName+'.'+@originalTableName;
	EXEC sys.sp_executesql @sql
	SET @totalRows= (SELECT TOP(1) value FROM #count)
	DROP TABLE #count;

	SET @sql='INSERT INTO #duplicateAddresses (DuplicateAddress) SELECT '+@originalDbName+'.'+@originalSchemaName+'.'+@originalTableName+'.'+@originalColumnName+
	' FROM '+@originalDbName+'.'+@originalSchemaName+'.'+@originalTableName+
	' GROUP BY '+@originalColumnName+
	' HAVING COUNT(*)>1';
	EXEC sys.sp_executesql @sql;

	DECLARE @totalDuplicateRows INT = (SELECT COUNT(*) FROM #duplicateAddresses );
	DECLARE @cntDuplicate INT=1;
	DECLARE @maskedAddresses varchar(max);
	DECLARE @currentAddress varchar(max);

	WHILE @cntDuplicate <= @totalDuplicateRows
	BEGIN
		SET @currentAddress=(SELECT #duplicateAddresses.DuplicateAddress FROM #duplicateAddresses WHERE ID=@cntDuplicate);
		EXEC MaskAddressesAtomicProcedure @maskedAddress=@maskedAddresses OUTPUT;
		WHILE EXISTS (SELECT 1 FROM #duplicateAddresses WHERE SubstituteAddress IN (@maskedAddresses))
		BEGIN
			EXEC MaskAddressesAtomicProcedure @maskedAddress=@maskedAddresses OUTPUT;
		END

		UPDATE #duplicateAddresses
		SET SubstituteAddress=@maskedAddresses
		WHERE ID=@cntDuplicate
		SET @cntDuplicate=@cntDuplicate+1
	END

	WHILE @cnt <= @totalRows
	BEGIN
		DECLARE @place varchar(max);
		DECLARE @substituteAddress varchar(max)
		SET @sql=N'( SELECT @currentAddress= '+@originalDbName+'.'+@originalSchemaName+'.'+@originalTableName+'.'+@originalColumnName+' FROM '+@originalDbName+'.'+@originalSchemaName+'.'+@originalTableName+' WHERE '+@originalIdColumn+'='+CAST(@cnt AS VARCHAR(MAX))+')';
		EXEC sys.sp_executesql @sql,N'@currentAddress NVARCHAR(MAX) OUTPUT', @currentAddress=@place OUTPUT
		IF EXISTS (SELECT 1 FROM #duplicateAddresses WHERE DuplicateAddress=@place)
		BEGIN
			SET @sql=N'( SELECT @substituteAddress= SubstituteAddress FROM #duplicateAddresses WHERE DuplicateAddress = '''+@place+''')';
			EXEC sys.sp_executesql @sql,N'@substituteAddress varchar(max) OUTPUT',@substituteAddress=@substituteAddress OUTPUT
			SET @sql=N'UPDATE '+@substituteDbName+'.'+@substituteSchemaName+'.'+@substituteTableName+' SET '+@substituteColumnName+' = '+CAST(@substituteAddress AS nvarchar(max))+'WHERE '+@substituteIdColumn+'='+CAST(@cnt AS VARCHAR(MAX));
			EXEC sys.sp_executesql @sql;
		END
		ELSE
		BEGIN
			DECLARE @maskedAddress varchar(max);
			DECLARE @repeatAddFlag INT=0;
			SET @sql=N'( SELECT @currentAddress= '+@originalDbName+'.'+@originalSchemaName+'.'+@originalTableName+'.'+@originalColumnName+' FROM '+@originalDbName+'.'+@originalSchemaName+'.'+@originalTableName+' WHERE '+@originalIdColumn+'='+CAST(@cnt AS VARCHAR(MAX))+')';
			EXEC sys.sp_executesql @sql,N'@currentAddress varchar(max) OUTPUT', @currentAddress=@place OUTPUT

			EXEC MaskAddressesAtomicProcedure @maskedAddress=@maskedAddress OUTPUT;

			SET @sql=N'SELECT @repeatValue=1 FROM '+@substituteDbName+'.'+@substituteSchemaName+'.'+@substituteTableName+' WHERE '+@substituteColumnName+' IN ('''+@maskedAddress+''')'
			EXEC sys.sp_executesql @sql,N'@repeatValue INT OUTPUT',@repeatValue=@repeatAddFlag OUTPUT

			WHILE  (@repeatAddFlag=1)
			BEGIN
				EXEC MaskAddressesAtomicProcedure @maskedAddress=@maskedAddress OUTPUT;

				SET @sql=N'SELECT @repeatValue=0 FROM '+@substituteDbName+'.'+@substituteSchemaName+'.'+@substituteTableName+' WHERE '+@maskedAddress+' NOT IN (SELECT '+@substituteColumnName+ ' FROM '+@substituteDbName+'.'+@substituteSchemaName+'.'+@substituteTableName+')'
				EXEC sys.sp_executesql @sql,N'@repeatValue INT OUTPUT',@repeatValue=@repeatAddFlag OUTPUT
			END

			SET @sql=N'UPDATE '+@substituteDbName+'.'+@substituteSchemaName+'.'+@substituteTableName+' SET '+@substituteColumnName+' = '+CAST(@maskedAddress AS varchar(max))+' WHERE '+@substituteIdColumn+'='+CAST(@cnt AS VARCHAR(MAX));
			EXEC sys.sp_executesql @sql
		END
		SET @cnt=@cnt+1
	END
	
END