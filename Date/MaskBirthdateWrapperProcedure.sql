CREATE PROCEDURE MaskBirthdateWrapperProcedure(
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
)
AS 
BEGIN
	
		DECLARE @cnt INT=1;
		DECLARE @totalRows INT=0;
		CREATE TABLE #duplicateBirthdates(
			ID INT NOT NULL IDENTITY(1,1),
			DuplicateBirthdate VARCHAR(MAX),
			SubstituteBirthdate VARCHAR(MAX)
		);
		DECLARE @sql NVARCHAR(MAX);
		CREATE Table #count(value INT);
		
		SET @sql='INSERT INTO #count(value) SELECT COUNT(*) FROM '+@originalDbName+'.'+@originalSchemaName+'.'+@originalTableName;
		EXEC sys.sp_executesql @sql

		SET @totalRows= (SELECT TOP(1) value FROM #count)
		DROP TABLE #count;

		SET @sql='INSERT INTO #duplicateBirthdates(DuplicateBirthdate) SELECT '+@originalDbName+'.'+@originalSchemaName+'.'+@originalTableName+'.'+@originalColumnName+
		' FROM '+@originalDbName+'.'+@originalSchemaName+'.'+@originalTableName+
		' GROUP BY '+@originalColumnName+
		' HAVING COUNT(*)>1';
		EXEC sys.sp_executesql @sql;

		DECLARE @totalDuplicateRows INT = (SELECT COUNT(*) FROM #duplicateBirthdates );
		DECLARE @cntDuplicate INT=1;
		DECLARE @maskedBirthdate DATE;
		DECLARE @currentBirthdate DATE;

		
		WHILE @cntDuplicate <= @totalDuplicateRows
		BEGIN

			SET @currentBirthdate=(SELECT #duplicateBirthdates.DuplicateBirthdate FROM #duplicateBirthdates WHERE ID=@cntDuplicate);

			EXEC MaskBirthdateAtomicProcedure @birthdate=@currentBirthdate,@maskedBirthdate=@maskedBirthdate OUTPUT;
	
			WHILE EXISTS (SELECT 1 FROM #duplicateBirthdates WHERE SubstituteBirthdate IN (@maskedBirthdate))
			BEGIN
				EXEC MaskBirthdateAtomicProcedure @birthdate=@currentBirthdate,@maskedBirthdate=@maskedBirthdate OUTPUT;
			END

			UPDATE #duplicateBirthdates
			SET SubstituteBirthdate=@maskedBirthdate
			WHERE ID=@cntDuplicate
			SET @cntDuplicate=@cntDuplicate+1
		END
		
		WHILE @cnt <= @totalRows
		BEGIN

			DECLARE @substituteBirthdate VARCHAR(MAX)

			SET @sql=N'( SELECT @currentBirthdate= '+@originalDbName+'.'+@originalSchemaName+'.'+@originalTableName+'.'+@originalColumnName+' FROM '+@originalDbName+'.'+@originalSchemaName+'.'+@originalTableName+' WHERE '+@originalIdColumn+' ='+CAST(@cnt AS VARCHAR(MAX))+')';
			EXEC sys.sp_executesql @sql,N'@currentBirthdate DATE OUTPUT', @currentBirthdate=@currentBirthdate OUTPUT

			IF EXISTS (SELECT 1 FROM #duplicateBirthdates WHERE DuplicateBirthdate=@currentBirthdate)
			BEGIN

				SET @sql=N'( SELECT @substituteBirthdate=SubstituteBirthdate FROM #duplicateBirthdates WHERE DuplicateBirthdate = '''+CAST(@currentBirthdate AS VARCHAR)+''')';
				EXEC sys.sp_executesql @sql,N'@substituteBirthdate DATE OUTPUT',@substituteBirthdate=@substituteBirthdate OUTPUT

	
				SET @sql=N'UPDATE '+@substituteDbName+'.'+@substituteSchemaName+'.'+@substituteTableName+' SET '+@substituteColumnName+' = '''+CAST(@substituteBirthdate AS VARCHAR)+''' WHERE '+@substituteIdColumn+' ='+CAST(@cnt AS VARCHAR(MAX));
				EXEC sys.sp_executesql @sql;

			END; 
			ELSE
			BEGIN

				DECLARE @maskedSingleBirthdate VARCHAR(MAX);
				DECLARE @repeatBirthdayFlag INT=0;

				
				EXEC MaskBirthdateAtomicProcedure @birthdate=@currentBirthdate,@maskedBirthdate=@maskedSingleBirthdate OUTPUT;


				SET @sql=N'SELECT @repeatValue=1 FROM '+@substituteDbName+'.'+@substituteSchemaName+'.'+@substituteTableName+' WHERE '+@substituteColumnName+' IN ('''+CAST(@maskedSingleBirthdate AS VARCHAR)+''')'
				EXEC sys.sp_executesql @sql,N'@repeatValue INT OUTPUT',@repeatValue=@repeatBirthdayFlag OUTPUT

				WHILE  (@repeatBirthdayFlag=1)
				BEGIN

					EXEC MaskBirthdateAtomicProcedure @birthdate=@currentBirthdate,@maskedBirthdate=@maskedSingleBirthdate OUTPUT;
					SET @sql=N'SELECT @repeatValue= 0 FROM '+@substituteDbName+'.'+@substituteSchemaName+'.'+@substituteTableName+' WHERE '''+ @maskedSingleBirthdate +''' NOT IN (SELECT '+@substituteColumnName+ ' FROM '+@substituteDbName+'.'+@substituteSchemaName+'.'+@substituteTableName+')'
					EXEC sys.sp_executesql @sql,N'@repeatValue INT OUTPUT',@repeatValue=@repeatBirthdayFlag OUTPUT
				END

				SET @sql=N'UPDATE '+@substituteDbName+'.'+@substituteSchemaName+'.'+@substituteTableName+' SET '+@substituteColumnName+' = '''+CAST(@maskedSingleBirthdate AS VARCHAR)+''' WHERE '+@substituteIdColumn+' ='+CAST(@cnt AS VARCHAR(MAX));
				EXEC sys.sp_executesql @sql
			
			END
			SET @cnt=@cnt+1
		END
END
GO

