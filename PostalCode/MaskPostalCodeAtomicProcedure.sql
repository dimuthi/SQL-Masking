CREATE PROCEDURE MaskPostalCodeAtomicProcedure @maskedPostalCode int OUTPUT
AS
BEGIN
	DECLARE @rand1 int;
	SET @rand1 = FLOOR(RAND()*(8-1+1))+1
	SET @maskedPostalCode =(SELECT [postalcode] FROM SubstitutionDb.dbo.postalCodeTable WHERE id = @rand1)
END