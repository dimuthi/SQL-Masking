CREATE PROCEDURE MaskAddressesAtomicProcedure @maskedAddress VARCHAR(MAX) OUTPUT
AS
BEGIN
	DECLARE @rand1 int;
	DECLARE @place VARCHAR(500);
	SET @rand1 = FLOOR(RAND()*(500-1+1))+1
	SET @place =(SELECT placeName FROM SubstitutionDb.dbo.lookupAddresstable WHERE AddressID = @rand1);
	SET @maskedAddress=@place;
END