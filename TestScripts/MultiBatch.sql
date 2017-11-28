ALTER TABLE Person.Address ADD UpdatedFlag BIT
GO

CREATE NONCLUSTERED INDEX IX_Person_Adddress_UpdatedFlag (UpdatedFlag, StateProvinceID)
GO

UPDATE Person.Address SET UpdatedFlag = 0
GO
