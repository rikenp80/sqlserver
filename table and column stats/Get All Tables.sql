SET QUOTED_IDENTIFIER OFF
GO

SELECT "TRUNCATE TABLE " + name,
		"SELECT * FROM " + name + " WITH (NOLOCK)",
		"SELECT '" + name + "', COUNT(*) FROM " + name + " WITH (NOLOCK)",
		"DROP TABLE " + name
FROM sys.tables ORDER BY name