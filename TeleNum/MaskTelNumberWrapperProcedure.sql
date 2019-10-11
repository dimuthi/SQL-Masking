CREATE PROCEDURE MaskTelNumberWrapperProcedure 
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
	CREATE TABLE #duplicateTel(
		ID INT NOT NULL IDENTITY(1,1),
		DuplicateTel varchar(max),
		SubstituteTel varchar(max)
	);
	DECLARE @sql NVARCHAR(MAX);
	CREATE Table #count(value INT);
		
	SET @sql='INSERT INTO #count(value) SELECT COUNT(*) FROM '+@originalDbName+'.'+@originalSchemaName+'.'+@originalTableName;
	EXEC sys.sp_executesql @sql
	SET @totalRows= (SELECT TOP(1) value FROM #count)
	DROP TABLE #count;

	SET @sql='INSERT INTO #duplicateTel(DuplicateTel) SELECT '+@originalDbName+'.'+@originalSchemaName+'.'+@originalTableName+'.'+@originalColumnName+
	' FROM '+@originalDbName+'.'+@originalSchemaName+'.'+@originalTableName+
	' GROUP BY '+@originalColumnName+
	' HAVING COUNT(*)>1';
	EXEC sys.sp_executesql @sql;

	DECLARE @totalDuplicateRows INT = (SELECT COUNT(*) FROM #duplicateTel );
	DECLARE @cntDuplicate INT=1;
	DECLARE @maskedTel varchar(max);
	DECLARE @currentTel varchar(max);

	WHILE @cntDuplicate <= @totalDuplicateRows
	BEGIN
		SET @currentTel=(SELECT #duplicateTel.DuplicateTel FROM #duplicateTel WHERE ID=@cntDuplicate);
		EXEC MaskTelNumberAtomicProcedure @maskedTelNum=@maskedTel OUTPUT;
		WHILE EXISTS (SELECT 1 FROM #duplicateTel WHERE SubstituteTel IN (@maskedTel))
		BEGIN
			EXEC MaskTelNumberAtomicProcedure @maskedTelNum=@maskedTel OUTPUT;
		END

		UPDATE #duplicateTel
		SET SubstituteTel=@maskedTel
		WHERE ID=@cntDuplicate
		SET @cntDuplicate=@cntDuplicate+1
	END

	WHILE @cnt <= @totalRows
	BEGIN
		DECLARE @telnum varchar(max);
		DECLARE @substitutetel varchar(max)
		SET @sql=N'( SELECT @currentTel= '+@originalDbName+'.'+@originalSchemaName+'.'+@originalTableName+'.'+@originalColumnName+' FROM '+@originalDbName+'.'+@originalSchemaName+'.'+@originalTableName+' WHERE '+@originalIdColumn+'='+CAST(@cnt AS VARCHAR(MAX))+')';
		EXEC sys.sp_executesql @sql,N'@currentTel NVARCHAR(MAX) OUTPUT', @currentTel=@telnum OUTPUT
		IF EXISTS (SELECT 1 FROM #duplicateTel WHERE DuplicateTel=@telnum)
		BEGIN
			SET @sql=N'( SELECT @substitutetel= SubstituteTel FROM #duplicateTel WHERE DuplicateTel = '''+@telnum+''')';
			EXEC sys.sp_executesql @sql,N'@substitutetel bigint OUTPUT',@substitutetel=@substitutetel OUTPUT
			SET @sql=N'UPDATE '+@substituteDbName+'.'+@substituteSchemaName+'.'+@substituteTableName+' SET '+@substituteColumnName+' = '+CAST(@substitutetel AS nvarchar(max))+'WHERE '+@substituteIdColumn+'='+CAST(@cnt AS VARCHAR(MAX));
			EXEC sys.sp_executesql @sql;
		END
		ELSE
		BEGIN
			DECLARE @maskedTelNum varchar(max);
			DECLARE @repeatTelFlag INT=0;
			SET @sql=N'( SELECT @currentTel= '+@originalDbName+'.'+@originalSchemaName+'.'+@originalTableName+'.'+@originalColumnName+' FROM '+@originalDbName+'.'+@originalSchemaName+'.'+@originalTableName+' WHERE '+@originalIdColumn+'='+CAST(@cnt AS VARCHAR(MAX))+')';
			EXEC sys.sp_executesql @sql,N'@currentTel bigint OUTPUT', @currentTel=@telnum OUTPUT

			EXEC MaskTelNumberAtomicProcedure @maskedTelNum=@maskedTelNum OUTPUT;

			SET @sql=N'SELECT @repeatValue=1 FROM '+@substituteDbName+'.'+@substituteSchemaName+'.'+@substituteTableName+' WHERE '+@substituteColumnName+' IN ('''+@maskedTelNum+''')'
			EXEC sys.sp_executesql @sql,N'@repeatValue INT OUTPUT',@repeatValue=@repeatTelFlag OUTPUT

			WHILE  (@repeatTelFlag=1)
			BEGIN
				EXEC MaskTelNumberAtomicProcedure @maskedTelNum=@maskedTelNum OUTPUT;
				SET @sql=N'SELECT @repeatValue=0 FROM '+@substituteDbName+'.'+@substituteSchemaName+'.'+@substituteTableName+' WHERE '''+@maskedTelNum+''' NOT IN (SELECT '+@substituteColumnName+ ' FROM '+@substituteDbName+'.'+@substituteSchemaName+'.'+@substituteTableName+')'
				EXEC sys.sp_executesql @sql,N'@repeatValue INT OUTPUT',@repeatValue=@repeatTelFlag OUTPUT
			END

			SET @sql=N'UPDATE '+@substituteDbName+'.'+@substituteSchemaName+'.'+@substituteTableName+' SET '+@substituteColumnName+' = '+CAST(@maskedTelNum AS varchar(max))+' WHERE '+@substituteIdColumn+'='+CAST(@cnt AS VARCHAR(MAX));
			EXEC sys.sp_executesql @sql
		END
		SET @cnt=@cnt+1
	END
	
END