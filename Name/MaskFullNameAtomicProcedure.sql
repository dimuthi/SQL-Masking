CREATE PROCEDURE MaskFullNameAtomicProcedure(
	@gender VARCHAR(10),
	@surnameFirst INT=0,
	@maskedName VARCHAR(MAX) OUTPUT
)
AS
BEGIN

	DECLARE @firstNameIndex INT; 
	DECLARE @lastNameIndex INT;
	DECLARE @maskLastName VARCHAR(MAX);
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

	SET @lastNameIndex = (SELECT FLOOR(RAND()*(789-1)+1));
	SET @maskLastName = (SELECT [LastName] FROM SubstitutionDb.dbo.norwayLastNameSubstitution WHERE ID = @lastNameIndex);

	IF(@surnameFirst=0)
	BEGIN
		SET @maskedName= @maskFirstName+' '+@maskLastName;
	END
	ELSE IF(@surnameFirst=1)
	BEGIN
		SET @maskedName= +@maskLastName+' '+@maskFirstName;
	END
END;
GO

