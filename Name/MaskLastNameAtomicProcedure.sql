CREATE PROCEDURE MaskLastNameAtomicProcedure(
	@maskedLastName VARCHAR(MAX) OUTPUT
)
AS
BEGIN
	
	DECLARE @lastNameIndex INT; 
	DECLARE @maskLastName VARCHAR(MAX);

	SET @lastNameIndex = (SELECT FLOOR(RAND()*(788-1)+1));
	SET @maskLastName = (SELECT [LastName] FROM SubstitutionDb.dbo.norwayLastNameSubstitution WHERE ID = @lastNameIndex);

	SET @maskedLastName=@maskLastName;

END

GO

