DECLARE @Random INT;

SELECT @Random = ROUND(((100 - 10 -1) * RAND() + 10), 0)

SELECT @Random

DECLARE @colors TABLE (Name VARCHAR(20) NOT NULL)

INSERT INTO @colors VALUES
('Email'),
('InPerson'),
('Phone'),
('noInteraction'),
('Donation'),
('Pledge')


SELECT TOP 1 *
FROM @colors
ORDER BY NEWID()