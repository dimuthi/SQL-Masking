CREATE PROCEDURE MaskFirstNameAtomicProcedure(
	@gender VARCHAR(10),
	@maskedFirstName VARCHAR(MAX) OUTPUT)
AS
BEGIN
	
	DECLARE @firstNameIndex INT; 
	DECLARE @maskFirstName VARCHAR(MAX);
	IF(@gender='Male')
		BEGIN
			SET @firstNameIndex =(SELECT FLOOR(RAND()*(7732-1)+1));
			SET @maskFirstName = (SELECT [FirstName] FROM SubstitutionDb.dbo.norwayFirstNameMale WHERE ID = @firstNameIndex);
		END
	IF(@gender='Female')
		BEGIN
			SET @firstNameIndex = (SELECT FLOOR(RAND()*(7144-1)+1));
			SET @maskFirstName = (SELECT [FirstName] FROM SubstitutionDb.dbo.norwayFirstNameFeMale WHERE ID = @firstNameIndex);
		END
	IF(@gender='Unisex')
		BEGIN
			SET @firstNameIndex = (SELECT FLOOR(RAND()*(744-1)+1));
			SET @maskFirstName = (SELECT [FirstName] FROM SubstitutionDb.dbo.norwayFirstNameFeMale WHERE ID = @firstNameIndex);
		END

	SET @maskedFirstName= @maskFirstName;

END
GO

