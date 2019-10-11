CREATE PROCEDURE MaskBloodGroupAtomicProcedure @blood varchar(50) OUTPUT
AS
BEGIN
	DECLARE @rand1 int;
	SET @rand1 = FLOOR(RAND()*(8-1+1))+1;
	SET @blood =(SELECT [blood] FROM SubstitutionDb.dbo.bloodGroup WHERE id = @rand1)
END