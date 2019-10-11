CREATE PROCEDURE MaskFullNameWrapperProcedure(
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
	@surnameFirst INT)
AS
BEGIN
		DECLARE @cnt INT=1;
		DECLARE @totalRows INT=0;
		CREATE TABLE #duplicateNames(
			ID INT NOT NULL IDENTITY(1,1),
			DuplicateName VARCHAR(MAX),
			SubstituteName VARCHAR(MAX)
		);
		DECLARE @sql NVARCHAR(MAX);
		CREATE Table #count(value INT);
		
		SET @sql='INSERT INTO #count(value) SELECT COUNT(*) FROM '+@originalDbName+'.'+@originalSchemaName+'.'+@originalTableName;
		EXEC sys.sp_executesql @sql

		SET @totalRows= (SELECT TOP(1) value FROM #count)
		DROP TABLE #count;

		SET @sql='INSERT INTO #duplicateNames(DuplicateName) SELECT '+@originalDbName+'.'+@originalSchemaName+'.'+@originalTableName+'.'+@originalColumnName+
		' FROM '+@originalDbName+'.'+@originalSchemaName+'.'+@originalTableName+
		' GROUP BY '+@originalColumnName+
		' HAVING COUNT(*)>1';
		EXEC sys.sp_executesql @sql;


		DECLARE @totalDuplicateRows INT = (SELECT COUNT(*) FROM #duplicateNames );
		DECLARE @cntDuplicate INT=1;
		DECLARE @maskedName VARCHAR(MAX);
		DECLARE @currentName VARCHAR(MAX);
		DECLARE @firstName VARCHAR(MAX);
		DECLARE @gender VARCHAR(MAX);

		WHILE @cntDuplicate <= @totalDuplicateRows
		BEGIN

			SET @currentName=(SELECT #duplicateNames.DuplicateName FROM #duplicateNames WHERE ID=@cntDuplicate);

			
			IF(@surnameFirst=0)
			BEGIN
				SET @firstName = SUBSTRING(@currentName, 1, charindex(' ', @currentName)-1)
			END
			IF(@surnameFirst=1)
			BEGIN
				SET @firstName = SUBSTRING(@currentName, CHARINDEX(' ', @currentName) +1, 20)
			END

			IF EXISTS (SELECT 1 FROM SubstitutionDb.dbo.norwayFirstNameUnisex WHERE FirstName IN (@firstName))
			BEGIN
				SET @gender='Unisex';
			END
			IF EXISTS (SELECT 1 FROM SubstitutionDb.dbo.norwayFirstNameMale WHERE FirstName IN (@firstName))
			BEGIN
				SET @gender='Male';
			END
			IF EXISTS (SELECT 1 FROM SubstitutionDb.dbo.norwayFirstNameFemale WHERE FirstName IN  (@firstName))
			BEGIN
				SET @gender='Female';
			END
			
			EXEC MaskFullNameAtomicProcedure @gender = @gender,@surnameFirst=@surnameFirst,@maskedName=@maskedName OUTPUT;
	
			WHILE EXISTS (SELECT 1 FROM #duplicateNames WHERE SubstituteName IN (@maskedName))
			BEGIN
				EXEC MaskFullNameAtomicProcedure @gender= @gender,@surnameFirst=@surnameFirst,@maskedName=@maskedName OUTPUT;
			END

			UPDATE #duplicateNames
			SET SubstituteName=@maskedName
			WHERE ID=@cntDuplicate
			SET @cntDuplicate=@cntDuplicate+1
		END

		WHILE @cnt <= @totalRows
		BEGIN

			DECLARE @name VARCHAR(MAX);
			DECLARE @substituteName VARCHAR(MAX)

			SET @sql=N'( SELECT @currentName= '+@originalDbName+'.'+@originalSchemaName+'.'+@originalTableName+'.'+@originalColumnName+' FROM '+@originalDbName+'.'+@originalSchemaName+'.'+@originalTableName+' WHERE '+@originalIdColumn+'='+CAST(@cnt AS VARCHAR(MAX))+')';
			EXEC sys.sp_executesql @sql,N'@currentName NVARCHAR(MAX) OUTPUT', @currentName=@name OUTPUT

			IF EXISTS (SELECT 1 FROM #duplicateNames WHERE DuplicateName=@name)
			BEGIN

				SET @sql=N'( SELECT @substituteName= SubstituteName FROM #duplicateNames WHERE DuplicateName = '''+@name+''')';
				EXEC sys.sp_executesql @sql,N'@substituteName NVARCHAR(MAX) OUTPUT',@substituteName=@substituteName OUTPUT

	
				SET @sql=N'UPDATE '+@substituteDbName+'.'+@substituteSchemaName+'.'+@substituteTableName+' SET '+@substituteColumnName+' = '''+@substituteName+''' WHERE '+@substituteIdColumn+'='+CAST(@cnt AS VARCHAR(MAX));
				EXEC sys.sp_executesql @sql;

			END; 
			ELSE
			BEGIN
				DECLARE @maskedSingleName VARCHAR(MAX);
				DECLARE @repeatNameFlag INT=0;

				IF(@surnameFirst=0)
				BEGIN
					SET @firstName = SUBSTRING(@name, 1, charindex(' ', @name)-1)
				END
				IF(@surnameFirst=1)
				BEGIN
					SET @firstName = SUBSTRING(@name, CHARINDEX(' ', @name) +1, 20)
				END
				
				IF EXISTS (SELECT 1 FROM SubstitutionDb.dbo.norwayFirstNameUnisex WHERE FirstName IN  (@firstName))
				BEGIN
					SET @gender='Unisex';
				END
				IF EXISTS (SELECT 1 FROM SubstitutionDb.dbo.norwayFirstNameMale WHERE FirstName IN  (@firstName))
				BEGIN
					SET @gender='Male';
				END
				IF EXISTS (SELECT 1 FROM SubstitutionDb.dbo.norwayFirstNameFemale WHERE FirstName IN  (@firstName))
				BEGIN
					SET @gender='Female';
				END
				

				EXEC MaskFullNameAtomicProcedure @gender = @gender,@surnameFirst=@surnameFirst,@maskedName=@maskedSingleName OUTPUT;

				SET @sql=N'SELECT @repeatValue=1 FROM '+@substituteDbName+'.'+@substituteSchemaName+'.'+@substituteTableName+' WHERE '+@substituteColumnName+' IN ('''+@maskedSingleName+''')'
				EXEC sys.sp_executesql @sql,N'@repeatValue INT OUTPUT',@repeatValue=@repeatNameFlag OUTPUT

				WHILE  (@repeatNameFlag=1)
				BEGIN

					EXEC MaskFullNameAtomicProcedure @gender = @gender,@surnameFirst=@surnameFirst,@maskedName=@maskedSingleName OUTPUT;
					SET @sql=N'SELECT @repeatValue=0 FROM '+@substituteDbName+'.'+@substituteSchemaName+'.'+@substituteTableName+'WHERE'+@maskedSingleName+' NOT IN (SELECT '+@substituteColumnName+ ' FROM '+@substituteDbName+'.'+@substituteSchemaName+'.'+@substituteTableName+')'
					EXEC sys.sp_executesql @sql,N'@repeatValue INT OUTPUT',@repeatValue=@repeatNameFlag OUTPUT
				END

				SET @sql=N'UPDATE '+@substituteDbName+'.'+@substituteSchemaName+'.'+@substituteTableName+' SET '+@substituteColumnName+' = '''+@maskedSingleName+''' WHERE '+@substituteIdColumn+'='+CAST(@cnt AS VARCHAR(MAX));
				EXEC sys.sp_executesql @sql
			
			END
			SET @cnt=@cnt+1
		END
END
GO

