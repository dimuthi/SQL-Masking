CREATE PROCEDURE MaskBirthdateAtomicProcedure
	@birthdate DATE,
	@maskedBirthdate DATE OUTPUT
AS
BEGIN

	DECLARE @maskedYear INT;
	DECLARE @maskedMonth INT=(SELECT FLOOR(RAND()*(13-1)+1));
	DECLARE @maskedDate INT;
	DECLARE @randomValueAddForBirthyear INT = (SELECT FLOOR(RAND()*(4-1)+1));
	DECLARE @valueOfSignNegative INT=(SELECT FLOOR(RAND()*(7-1)+1));
	DECLARE @newBirthdate VARCHAR(MAX);

	IF (@valueOfSignNegative<3)
	BEGIN
		SET @randomValueAddForBirthyear = - @randomValueAddForBirthyear
		SET @newBirthdate= (SELECT DATEADD(YEAR,@randomValueAddForBirthyear,@birthdate))
	END
	ElSE
	BEGIN
		SET @newBirthdate= (SELECT DATEADD(YEAR,@randomValueAddForBirthyear,@birthdate))
	END

	SET @maskedYear=(SELECT YEAR(@newBirthdate))
	
	IF (@maskedMonth IN (1,3,5,7,8,10,11) )
	BEGIN
		SET @maskedDate= (SELECT FLOOR(RAND()*(31-1)+1));
	END
	ELSE IF ( @maskedMonth =2 )
	BEGIN
		SET @maskedDate =(SELECT FLOOR(RAND()*(28-1)+1));
	END
	ELSE
	BEGIN
		SET @maskedDate=(SELECT FLOOR(RAND()*(30-1)+1));
	END

	SET @newBirthdate= CAST(@maskedYear AS VARCHAR(MAX))+'-'+CAST(@maskedMonth AS varchar(MAX))+'-'+CAST(@maskedDate AS varchar(MAX));
	SET @maskedBirthdate= CAST(@newBirthdate AS DATE)
	
END
GO

