CREATE PROCEDURE MaskImageAtomicProcedure(
	@type VARCHAR(MAX),
	@maskedImage VARBINARY(MAX) OUTPUT
)
AS
BEGIN
	DECLARE @totalImageCount INT;
	DECLARE @randomIndex INT;

	IF(@type IN ('house'))
	BEGIN
		SET @totalImageCount =(SELECT COUNT(*) FROM SubstitutionDb.dbo.imageSubstitutionHouse)
		SET @randomIndex =(SELECT FLOOR(RAND()*(@totalImageCount-1)+1));
		SET @maskedImage = (SELECT Houses FROM SubstitutionDb.dbo.imageSubstitutionHouse WHERE ID=@randomIndex)
	END
	IF(@type IN ('face'))
	BEGIN
		SET @totalImageCount =(SELECT COUNT(*) FROM SubstitutionDb.dbo.imageSubstitutionFace)
		SET @randomIndex =(SELECT FLOOR(RAND()*(@totalImageCount-1)+1));
		SET @maskedImage = (SELECT Faces FROM SubstitutionDb.dbo.imageSubstitutionFace WHERE ID=@randomIndex)
	END
END
GO

