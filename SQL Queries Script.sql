--Part A
WITH ShiftCounts AS (
	-- Counts the number of the shifts per opertor in the last month
    SELECT
        SA.OperatorID,
        E.FirstName,
        E.LastName,
        COUNT(SA.ShiftID) AS ShiftCount
    FROM ShiftAssignment SA
    JOIN Employee E ON SA.OperatorID = E.EmployeeID
    WHERE SA.ShiftDate >= DATEADD(MONTH, -1, (SELECT MAX(ShiftDate) FROM ShiftAssignment))
        AND SA.ShiftDate <= (SELECT MAX(ShiftDate) FROM ShiftAssignment)
    GROUP BY SA.OperatorID, E.FirstName, E.LastName
    HAVING COUNT(SA.ShiftID) > 0 -- Excluding operators with no shifts
)
--Operators with the most number of shifts
SELECT 
    'Maximum Shifts' AS ResultType,
    OperatorID,
    FirstName,
    LastName,
    ShiftCount AS ShiftCount
FROM ShiftCounts
WHERE ShiftCount = (SELECT MAX(ShiftCount) FROM ShiftCounts)

UNION ALL

--Operators with the lowest number of shifts
SELECT 
    'Minimum Shifts' AS ResultType,
    OperatorID,
    FirstName,
    LastName,
    ShiftCount AS ShiftCount
FROM ShiftCounts
WHERE ShiftCount = (SELECT MIN(ShiftCount) FROM ShiftCounts);


--Part B
SELECT M.MachineID, M.MachineType, P.ProductName, P.ManufactureDate
FROM Machine M
JOIN Product_ P ON M.MachineID = P.MachineID
WHERE P.ManufactureDate >= DATEADD(DAY, -3, (SELECT MAX(ManufactureDate) FROM Product_))
  AND P.ProductName IN ('Flywheel', 'Clutch Plate', 'Pressure Plate')
ORDER BY M.MachineID, P.ManufactureDate;

CREATE OR ALTER PROCEDURE GetRecentMachineProducts
    @Days INT, -- Number of days to look back
    @ProductNames NVARCHAR(MAX) -- Comma-separated list of product names
AS
BEGIN
	-- Validate input parameters
    IF @Days IS NULL OR @Days <= 0
    BEGIN
        RAISERROR('Days parameter must be a positive integer', 16, 1);
        RETURN;
    END

    IF @ProductNames IS NULL OR LEN(TRIM(@ProductNames)) = 0
    BEGIN
        RAISERROR('ProductNames parameter cannot be empty', 16, 1);
        RETURN;
    END

    -- Convert the comma-separated list of product names into a table
    DECLARE @ProductTable TABLE (ProductName NVARCHAR(100));
    INSERT INTO @ProductTable (ProductName)
    SELECT value FROM STRING_SPLIT(@ProductNames, ',');

    -- Retrieve the results
    SELECT 
        M.MachineID, 
        M.MachineType, 
        P.ProductName, 
        P.ManufactureDate
    FROM Machine M
    JOIN Product_ P ON M.MachineID = P.MachineID
    WHERE P.ManufactureDate >= DATEADD(DAY, -@Days, (SELECT MAX(ManufactureDate) FROM Product_))
      AND P.ProductName IN (SELECT ProductName FROM @ProductTable)
    ORDER BY M.MachineID, P.ManufactureDate;
END;

EXEC GetRecentMachineProducts @Days = 3, @ProductNames = 'Flywheel,Clutch Plate,Pressure Plate';

--Part C
SELECT 
    M.MachineID,M.MachineType,
    COUNT(MT.MaintenanceID) AS Occasions
FROM 
    Machine M
JOIN 
    Maintenance MT ON M.MachineID = MT.MachineID
GROUP BY 
    M.MachineID, M.MachineType
HAVING 
    COUNT(MT.MaintenanceID) > 3
ORDER BY 
    Occasions DESC;

--Creating index on the Machine ID
CREATE INDEX IX_Maintenance_MachineID ON Maintenance(MachineID);

-- Stored Procedure Part C
CREATE PROCEDURE GetMachinesWithHighMaintenance
	@MaintenanceCount INT = 3 -- Setting the default value to 3
AS
BEGIN
	-- Validate input parameter
    IF @MaintenanceCount < 1
    BEGIN
        RAISERROR('Maintenance count threshold must be at least 1', 16, 1);
        RETURN;
    END


	-- Selecting machines with more than the specified maintenance occasions
	SELECT 
		M.MachineID,M.MachineType,
		COUNT(MT.MaintenanceID) AS Occasions
	FROM 
		Machine M
	JOIN 
		Maintenance MT ON M.MachineID = MT.MachineID
	GROUP BY 
		M.MachineID, M.MachineType
	HAVING 
		COUNT(MT.MaintenanceID) > @MaintenanceCount
	ORDER BY 
		Occasions DESC;
END;

--Executing the Stored Procedure
EXEC GetMachinesWithHighMaintenance @MaintenanceCount = 3;

--Part D
--Version 2--
CREATE OR ALTER PROCEDURE CheckAndUpdate_ManagerTable_SELFJOIN
    @EmployeeID INT, 
    @NewSalary FLOAT
AS
BEGIN
    SET NOCOUNT ON;
    
    DECLARE @ManagerSalary FLOAT;
    DECLARE @EmployeeExists BIT = 0;

    -- Check if employee exists first
    SELECT @EmployeeExists = 1
    FROM Employee 
    WHERE EmployeeID = @EmployeeID;

    IF @EmployeeExists = 0
    BEGIN
        RAISERROR('Employee does not exist', 16, 1);
        RETURN; -- Explicitly exit
    END

    -- Get manager's salary
    SELECT @ManagerSalary = M.Salary
    FROM Employee E
    JOIN Employee M ON E.ManagerID = M.EmployeeID
    WHERE E.EmployeeID = @EmployeeID;

    -- Validate salary
    IF @NewSalary > @ManagerSalary
    BEGIN
        RAISERROR('Salary exceeds manager', 16, 1);
        RETURN; -- Explicitly exit
    END
    ELSE IF @ManagerSalary IS NULL
    BEGIN
        RAISERROR('Manager salary missing', 16, 1);
        RETURN; -- Explicitly exit
    END

    -- Update if valid
    UPDATE Employee
    SET Salary = @NewSalary
    WHERE EmployeeID = @EmployeeID;

    PRINT 'Salary has been updated successfully';
END;

--Test Case 1: Succesful Salary Update--
EXEC CheckAndUpdate_ManagerTable_SELFJOIN @EmployeeID = 6, @NewSalary = 40000;

SELECT * 
FROM Employee
WHERE EmployeeID = 6;

--Test Case 2: Salary Exceeding Manager's Salary--
 EXEC CheckAndUpdate_ManagerTable_SELFJOIN @EmployeeID = 5, @NewSalary = 60000;

--Test Case 3: Updating a Manager’s Salary (Allowed)
EXEC CheckAndUpdate_ManagerTable_SELFJOIN @EmployeeID = 2, @NewSalary = 58000;

SELECT * 
FROM Employee
WHERE EmployeeID = 2;



--Trigger implementation
CREATE TRIGGER trg_PreventSalaryExceedingManager
ON Employee
AFTER UPDATE
AS 
BEGIN
    -- Check if any updated salary exceeds the manager's salary
    IF EXISTS(
        SELECT 1
        FROM inserted I
        JOIN Employee E ON I.ManagerID = E.EmployeeID
        WHERE I.Salary > E.Salary
    )
    BEGIN
        -- If any updated salary exceeds the manager's salary, print an error message
        PRINT 'Error: Employee salary cannot exceed their manager''s salary';
        
        -- Roll back the transaction to prevent the invalid update
        ROLLBACK TRANSACTION;
    END
    ELSE
    BEGIN
        -- If no salaries exceed the manager's salary, proceed with the update
        UPDATE Employee
        SET Salary = I.Salary -- Update the salary with the new value from the inserted table
        FROM inserted I
        WHERE Employee.EmployeeID = I.EmployeeID; -- Match the employee ID in the inserted table

        -- Print a success message to confirm the update
        PRINT 'Salary has been updated successfully.';
    END
END;



-- Valid salary update within manager's limit
UPDATE Employee
SET Salary = 55000
WHERE EmployeeID = 5;  -- Charlie Davis

SELECT * FROM Employee WHERE EmployeeID = 5;

-- Invalid update: salary exceeds manager's salary
UPDATE Employee
SET Salary = 65000
WHERE EmployeeID = 5;  -- Charlie Davis


--Successful Manager Salary Update
UPDATE Employee
SET Salary = 58000
WHERE EmployeeID = 2

SELECT * FROM Employee WHERE EmployeeID = 2;



--Part E

CREATE OR ALTER PROCEDURE GetSalaryReport
    @DateRangeType VARCHAR(10) -- Accepts 'Week', 'Month', or 'Quarter'
AS
BEGIN
		

    -- Determine the date range dynamically
    DECLARE @StartDate DATE, @EndDate DATE;

    SET @EndDate = GETDATE(); -- Current date

    IF @DateRangeType = 'Week'
        SET @StartDate = DATEADD(WEEK, -1, @EndDate)
    ELSE IF @DateRangeType = 'Month'
        SET @StartDate = DATEADD(MONTH, -1, @EndDate)
    ELSE IF @DateRangeType = 'Quarter'
        SET @StartDate = DATEADD(QUARTER, -1, @EndDate);
    ELSE
    BEGIN
        PRINT 'Invalid Date Range Type. Use "Week", "Month", or "Quarter."';
        RETURN;
    END

    -- Generate the salary report
    SELECT DISTINCT
        D.DepartmentID,
        D.DepartmentName,
        E.EmployeeID,
        E.FirstName,
        E.LastName,
        E.Job_Title,
        E.Salary,
        SUM(E.Salary) OVER (PARTITION BY D.DepartmentID) AS TotalSalaryBill
    FROM Employee E
    JOIN Department D ON E.DepartmentID = D.DepartmentID
    LEFT JOIN Operator O ON E.EmployeeID = O.EmployeeID
    LEFT JOIN ShiftAssignment SA ON O.OperatorID = SA.OperatorID
    WHERE SA.ShiftDate BETWEEN @StartDate AND @EndDate OR SA.ShiftDate IS NULL -- Include employees without shifts
    ORDER BY D.DepartmentID, E.EmployeeID;
END;

EXEC GetSalaryReport 'Week';
EXEC GetSalaryReport 'Month';
EXEC GetSalaryReport 'Quarter';