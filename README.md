# Big Data and Databases Coursework

## Project Overview
This repository contains coursework for the Big Data and Databases module (CSI-5-BDD, 2025). It models, builds, queries, and visualises a relational database for a fictional manufacturer, **LSBU Manufacturing Ltd**, covering ER modelling, normalisation, T-SQL (stored procedures, triggers, indexing), and a Power BI dashboard.

## Task Breakdown
1. **Task 1 — ER Diagram**: Nine entities (Department, Employee, Manager, Machine, Maintenance, Production, Operator, ShiftAssignment, Product) modelled in Chen notation, with primary/foreign keys and cardinalities defined.
2. **Task 2 — Normalisation**: Functional dependencies for each entity, with the schema justified against 1NF, 2NF, and 3NF/BCNF.
3. **Task 3 — Build & Populate**: Schema created in SQL Server (parent tables first, foreign keys added via `ALTER`), constraints briefly disabled to bulk-load sample data, then re-enabled.
4. **Task 4 — SQL Queries (Parts A–E)**: Five operational queries, each hardened from a plain query into a validated, parameterised stored procedure or trigger:
   - **Part A**: Operators with the most/fewest shifts in the last month (CTE + `UNION ALL`).
   - **Part B**: Machines producing specific products in the last N days (`GetRecentMachineProducts` procedure).
   - **Part C**: Machines exceeding a maintenance-count threshold, backed by an index on `Maintenance.MachineID` (`GetMachinesWithHighMaintenance` procedure).
   - **Part D**: Enforcing that an employee's salary can't exceed their manager's — via a self-join procedure (`CheckAndUpdate_ManagerTable_SELFJOIN`) and an `AFTER UPDATE` trigger with `ROLLBACK TRANSACTION`.
   - **Part E**: Rolling weekly/monthly/quarterly department salary reports (`GetSalaryReport`) using `SUM() OVER (PARTITION BY ...)`.
5. **Task 5 — Power BI Dashboard**: A two-page dashboard (table, line chart, bar chart, pie chart, histogram, stacked bar, doughnut chart) with slicers for manufacture date, production date, and department — each visual mapped back to a Task 4 query.

## Files in the Repository
- **CSI_5_BDD_CW.docx**: Full written report — ER diagram, functional dependencies, build screenshots, query explanations, dashboard write-up, conclusion, and references.
- **csi-5-bdd_coursework2025 final.pdf**: Original coursework brief and instructions.
- **SQL Queries Script.sql**: All T-SQL for Task 4 (Parts A–E), including stored procedures, the trigger, the index, and test-case executions.
- **Task 5 new.pbix**: The Power BI dashboard file for Task 5.

## How to Use
1. **SQL Queries Script.sql**:
   - Open the file in a SQL editor (e.g., Microsoft SQL Server Management Studio).
   - Execute the queries as per the instructions provided in the coursework documentation.

2. **Task 5 new.pbix**:
   - Open the file in Power BI Desktop.
   - Analyze and modify the report as required.

3. **Documentation**:
   - Refer to `CSI_5_BDD_CW.docx` and `csi-5-bdd_coursework2025 final.pdf` for detailed instructions and guidelines.

## Prerequisites
- SQL database management system (e.g., Microsoft SQL Server).
- Power BI Desktop installed.

## Author
Yameen Munir

## License
This project is for educational purposes and is not licensed for commercial use.
