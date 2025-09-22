use [ProductTestAnalysis]

--Component Analysis

Select * from Component_Details

-- Components by Phase
SELECT Component_Phaseid, COUNT(*) as ComponentCount
FROM Component_Details
GROUP BY Component_Phaseid
ORDER BY ComponentCount DESC;

--Latest Components
Select Name , Version , Release_date
from Component_Details
order by Release_date desc

--Component Types Summary
SELECT 
    CASE 
        WHEN Name LIKE '%Firmware%' THEN 'Firmware'
        WHEN Name LIKE '%BIOS%' THEN 'BIOS'
        WHEN Name LIKE '%Driver%' OR Name LIKE '%rpm%' OR Name LIKE '%vib%' OR Name LIKE '%deb%' THEN 'Driver'
		WHEN Name LIKE '%Cli%' THEN 'CLI'
        WHEN Name LIKE '%GUI%' THEN 'GUI'
        ELSE 'Other'
    END as ComponentType,
    COUNT(*) as Count
FROM Component_Details
GROUP BY 
    CASE 
        WHEN Name LIKE '%Firmware%' THEN 'Firmware'
        WHEN Name LIKE '%BIOS%' THEN 'BIOS'
		WHEN Name LIKE '%Driver%' OR Name LIKE '%rpm%' OR Name LIKE '%vib%' OR Name LIKE '%deb%' THEN 'Driver'
        WHEN Name LIKE '%Cli%' THEN 'CLI'
        WHEN Name LIKE '%GUI%' THEN 'GUI'
        ELSE 'Other'
    END;


--Configuration Analysis

Select * from Configuration_Details

--Configuration by Server Type

Select Server , count(*) as config_count
from configuration_details
group by server
order by config_count asc

--Configuration by Operating System

Select Operating_System as OS ,count(*) as OS_count
from configuration_Details
group by Operating_system
order by Operating_system asc

--TestRuns by Owners

Select o.Name , SUM(c.test_runs) as Totaltestruns ,
Round(
(SUM(c.test_runs)*100)/
(Select SUM(test_runs) 
from Configuration_Details),2) as Allocated_percentage
from Configuration_Details as c
join Configuration_Owners as o
on c.Owner_id=o.Owner_id
group by o.Name
order by totaltestruns desc


--Most used adapters

Select Adapter , count(*) as Usagecount
from Configuration_Details
group by Adapter
order by Usagecount desc


/* 
Project Analysis
*/

Select * from Project_Details

--Projects by OEM

Select OEM , count(*) as ProjectCount
from Project_Details
group by OEM
order by ProjectCount desc


--Project by Duration

Select Project_Name , DATEDIFF(day,Start_Date,End_Date) as DurationDays
from Project_Details
order by DurationDays desc

--Active Projects

Select Project_Name , Start_Date ,End_Date
from Project_Details
where getdate() between Start_Date AND End_Date

/* 
Test Case Analysis
*/

Select * from Test_Cases

--Test Cases by Module

Select Module , count(*) as TestCaseCount
from  Test_Cases
group by Module
order by TestCaseCount desc

--Automated vs Manual test cases
Select isAutomated , count(*) as count
from Test_Cases
group by isAutomated 

--average test cases per module

SELECT 
    Module,
    AVG(
        CASE 
            WHEN TestCase_Duration LIKE '%day%' THEN 
                CAST(SUBSTRING(TestCase_Duration, 1, CHARINDEX('day', TestCase_Duration)-2) as FLOAT) * 24 +
                CAST(SUBSTRING(TestCase_Duration, CHARINDEX('day', TestCase_Duration)+4, 
                      CHARINDEX('hr', TestCase_Duration) - (CHARINDEX('day', TestCase_Duration)+4)) as FLOAT)
            ELSE CAST(SUBSTRING(TestCase_Duration, 1, CHARINDEX('hr', TestCase_Duration)-1) as FLOAT)
        END
    ) as AvgHours
FROM Test_Cases
GROUP BY Module;

/*
Test Run Analysis
*/

--Test Run Status Summary
SELECT status, COUNT(*) as RunCount
FROM Test_Run
GROUP BY status
ORDER BY RunCount DESC;

-- Test Success Rate by Configuration
SELECT 
    c.Configuration_id,
    c.Server,
    c.Operating_System,
    COUNT(tr.Test_Runid) as TotalRuns,
    SUM(CASE WHEN tr.status = 'Pass' THEN 1 ELSE 0 END) as PassedRuns,
    CAST(SUM(CASE WHEN tr.status = 'Pass' THEN 1 ELSE 0 END) as FLOAT) / NULLIF(COUNT(tr.Test_Runid), 0) * 100 as SuccessRate
FROM Test_Run tr
JOIN Configuration_Details c ON tr.Config_id = c.Configuration_id
GROUP BY c.Configuration_id, c.Server, c.Operating_System
HAVING COUNT(tr.Test_Runid) > 0
ORDER BY SuccessRate DESC;

-- Most Tested Configurations
SELECT 
    c.Configuration_id,
    c.Server,
    c.Adapter,
    c.Operating_System,
    COUNT(tr.Test_Runid) as TotalTestRuns
FROM Test_Run tr
JOIN Configuration_Details c ON tr.Config_id = c.Configuration_id
GROUP BY c.Configuration_id, c.Server, c.Adapter, c.Operating_System
ORDER BY TotalTestRuns DESC;

/*
Cross-Table Analysis
*/

-- Components with Project Phase Information
SELECT 
    cd.Name,
    cd.Version,
    cd.Release_Date,
    pp.Phase_Name,
    pp.Start_Date as Phase_Start,
    pp.End_Date as Phase_End
FROM Component_Details cd
LEFT JOIN Project_Phases pp ON cd.Component_Phaseid = pp.Phase_id;

-- Test Coverage by Component Type
SELECT 
    CASE 
        WHEN tc.Module = 'Firmware' THEN 'Adapter_Firmware'
        WHEN tc.Module = 'Driver' THEN 'Windows_Driver%'
		WHEN tc.Module = 'Cli' THEN '%Cli%'
        WHEN tc.Module = 'GUI' THEN '%GUI%'
        ELSE 'Other'
    END as ComponentCategory,
    COUNT(DISTINCT tc.TestCase_id) as TestCaseCount,
    COUNT(tr.Test_Runid) as TestRunCount
FROM Test_Cases tc
LEFT JOIN Test_Run tr ON tc.TestCase_id = tr.TestCase_id
GROUP BY 
    CASE 
        WHEN tc.Module = 'Firmware' THEN 'Adapter_Firmware'
        WHEN tc.Module = 'Driver' THEN 'Windows_Driver%'
        WHEN tc.Module = 'Cli' THEN '%Cli%'
        WHEN tc.Module = 'GUI' THEN '%GUI%'
        ELSE 'Other'
    END;

-- Owner Performance Analysis
SELECT 
    co.Name,
    COUNT(DISTINCT cd.Configuration_id) as ConfigurationsManaged,
    SUM(cd.Test_runs) as TotalTestRuns,
    COUNT(tr.Test_Runid) as TestRunsExecuted,
    SUM(CASE WHEN tr.status = 'Pass' THEN 1 ELSE 0 END) as PassedTests
FROM Configuration_Owners co
LEFT JOIN Configuration_Details cd ON co.Owner_id = cd.Owner_id
LEFT JOIN Test_Run tr ON cd.Configuration_id = tr.Config_id
GROUP BY co.Name
ORDER BY TotalTestRuns DESC;


Select o.Name , SUM(c.test_runs) as Totaltestruns ,
Round(
(SUM(c.test_runs)*100)/
(Select SUM(test_runs) 
from Configuration_Details),2) as Allocated_percentage
from Configuration_Details as c
join Configuration_Owners as o
on c.Owner_id=o.Owner_id
group by o.Name
order by totaltestruns desc


-- Project Phase Progress
SELECT 
    pd.Project_Name,
    pp.Phase_Name,
    pp.Start_Date,
    pp.End_Date,
    CASE 
        WHEN GETDATE() < pp.Start_Date THEN 'Not Started'
        WHEN GETDATE() BETWEEN pp.Start_Date AND pp.End_Date THEN 'In Progress'
        ELSE 'Completed'
    END as Status
FROM Project_Phases pp
JOIN Project_Details pd ON pp.Project_id = pd.Project_id
WHERE pp.Phase_Name IS NOT NULL AND pp.Phase_Name != '';

-- Test Efficiency by Configuration
SELECT 
    c.Configuration_id,
    c.Server,
    c.Operating_System,
    AVG(
        CASE 
            WHEN tc.TestCase_Duration LIKE '%day%' THEN 
                CAST(SUBSTRING(tc.TestCase_Duration, 1, CHARINDEX('day', tc.TestCase_Duration)-2) as FLOAT) * 24 +
                CAST(SUBSTRING(tc.TestCase_Duration, CHARINDEX('day', tc.TestCase_Duration)+4, 
                      CHARINDEX('hr', tc.TestCase_Duration) - (CHARINDEX('day', tc.TestCase_Duration)+4)) as FLOAT)
            ELSE CAST(SUBSTRING(tc.TestCase_Duration, 1, CHARINDEX('hr', tc.TestCase_Duration)-1) as FLOAT)
        END
    ) as AvgTestDurationHours,
    COUNT(tr.Test_Runid) as TotalRuns,
    SUM(CASE WHEN tr.status = 'Pass' THEN 1 ELSE 0 END) as PassedRuns
FROM Configuration_Details c
JOIN Test_Run tr ON c.Configuration_id = tr.Config_id
JOIN Test_Cases tc ON tr.TestCase_id = tc.TestCase_id
GROUP BY c.Configuration_id, c.Server, c.Operating_System;

/*
                                                      Overall Project Health Snapshot
*/


-- Key Metrics for Dashboard
SELECT 
    (SELECT COUNT(DISTINCT Project_id) FROM Project_Details) as Total_Projects,
    (SELECT COUNT(*) FROM Configuration_Details) as Total_Configurations,
    (SELECT COUNT(*) FROM Test_Cases) as Total_Test_Cases,
    (SELECT COUNT(*) FROM Test_Run) as Total_Test_Runs,
    (SELECT COUNT(DISTINCT Config_id) FROM Test_Run) as Configurations_Tested,
    (SELECT CAST(SUM(CASE WHEN status = 'Pass' THEN 1 ELSE 0 END) as FLOAT) / COUNT(*) * 100 
     FROM Test_Run WHERE status IN ('Pass', 'Fail')) as Overall_Pass_Rate,
    (SELECT COUNT(*) FROM Test_Run WHERE status = 'Block') as Blocked_Tests;


/*
                                                     Test Coverage Analysis (Critical for Compliance)
*/

-- Coverage by Server Platform
SELECT 
    cd.Server,
    COUNT(DISTINCT cd.Configuration_id) as Total_Configs,
    COUNT(DISTINCT tr.Config_id) as Tested_Configs,
    CAST(COUNT(DISTINCT tr.Config_id) as FLOAT) / NULLIF(COUNT(DISTINCT cd.Configuration_id), 0) * 100 as Coverage_Percentage
FROM Configuration_Details cd
LEFT JOIN Test_Run tr ON cd.Configuration_id = tr.Config_id
GROUP BY cd.Server
ORDER BY Coverage_Percentage DESC;

-- Coverage by Operating System
SELECT 
    cd.Operating_System,
    COUNT(DISTINCT cd.Configuration_id) as Total_Configs,
    COUNT(DISTINCT tr.Config_id) as Tested_Configs,
    CAST(COUNT(DISTINCT tr.Config_id) as FLOAT) / NULLIF(COUNT(DISTINCT cd.Configuration_id), 0) * 100 as Coverage_Percentage
FROM Configuration_Details cd
LEFT JOIN Test_Run tr ON cd.Configuration_id = tr.Config_id
GROUP BY cd.Operating_System
ORDER BY Coverage_Percentage DESC;

/*
       Quality & Stability Metrics
*/
-- Failure Rate by Configuration (Identify problematic hardware)
SELECT 
    c.Configuration_id,
    c.Server,
    c.Adapter,
    c.Operating_System,
    COUNT(tr.Test_Runid) as TotalRuns,
    SUM(CASE WHEN tr.status = 'Fail' THEN 1 ELSE 0 END) as Failures,
    CAST(SUM(CASE WHEN tr.status = 'Fail' THEN 1 ELSE 0 END) as FLOAT) / NULLIF(COUNT(tr.Test_Runid), 0) * 100 as Failure_Rate
FROM Test_Run tr
JOIN Configuration_Details c ON tr.Config_id = c.Configuration_id
WHERE tr.status IN ('Pass', 'Fail') -- Exclude Blocked
GROUP BY c.Configuration_id, c.Server, c.Adapter, c.Operating_System
HAVING COUNT(tr.Test_Runid) > 5 -- Only consider sufficiently tested configs
ORDER BY Failure_Rate DESC;

-- Failure Rate by Test Case Module (Find unstable areas)
SELECT 
    tc.Module,
    COUNT(tr.Test_Runid) as TotalRuns,
    SUM(CASE WHEN tr.status = 'Fail' THEN 1 ELSE 0 END) as Failures,
    SUM(CASE WHEN tr.status = 'Block' THEN 1 ELSE 0 END) as Blocked,
    CAST(SUM(CASE WHEN tr.status = 'Fail' THEN 1 ELSE 0 END) as FLOAT) / 
    NULLIF(SUM(CASE WHEN tr.status IN ('Pass', 'Fail') THEN 1 ELSE 0 END), 0) * 100 as Failure_Rate
FROM Test_Run tr
JOIN Test_Cases tc ON tr.TestCase_id = tc.TestCase_id
GROUP BY tc.Module
ORDER BY Failure_Rate DESC;


/*
         Blocked Test Analysis (Uncover Dependencies & Issues)
*/

-- What is blocking progress?
SELECT 
    tc.TestCase_id,
    tc.Module,
    c.Server,
    c.Operating_System,
    COUNT(tr.Test_Runid) as Blocked_Count
FROM Test_Run tr
JOIN Test_Cases tc ON tr.TestCase_id = tc.TestCase_id
JOIN Configuration_Details c ON tr.Config_id = c.Configuration_id
WHERE tr.status = 'Block'
GROUP BY tc.TestCase_id, tc.Module, c.Server, c.Operating_System
ORDER BY Blocked_Count DESC;

/*
        Efficiency & Productivity Metrics
*/
-- Calculate average test duration in hours for analysis
WITH DurationCTE AS (
    SELECT 
        TestCase_id,
        -- Parse the duration string into total hours
        CASE 
            WHEN TestCase_Duration LIKE '%day%' THEN 
                CAST(SUBSTRING(TestCase_Duration, 1, CHARINDEX('day', TestCase_Duration)-2) as FLOAT) * 24 +
                CAST(SUBSTRING(TestCase_Duration, CHARINDEX('day', TestCase_Duration)+4, 
                      CHARINDEX('hr', TestCase_Duration) - (CHARINDEX('day', TestCase_Duration)+4)) as FLOAT)
            ELSE CAST(SUBSTRING(TestCase_Duration, 1, CHARINDEX('hr', TestCase_Duration)-1) as FLOAT)
        END as DurationHours
    FROM Test_Cases
)
-- Analyze by Module
SELECT 
    tc.Module,
    COUNT(tc.TestCase_id) as Number_of_Tests,
    AVG(d.DurationHours) as Avg_Duration_Hrs,
    SUM(d.DurationHours) as Total_Estimated_Effort_Hrs
FROM Test_Cases tc
JOIN DurationCTE d ON tc.TestCase_id = d.TestCase_id
GROUP BY tc.Module
ORDER BY Total_Estimated_Effort_Hrs DESC;

/*
. Resource Utilization & Ownership Analysis
*/

-- Workload distribution across owners/teams
SELECT 
    co.Name as Owner,
    COUNT(DISTINCT cd.Configuration_id) as Configs_Managed,
    SUM(cd.Test_runs) as Planned_Test_Runs,
    (SELECT COUNT(*) FROM Test_Run tr 
     JOIN Configuration_Details cd2 ON tr.Config_id = cd2.Configuration_id 
     WHERE cd2.Owner_id = co.Owner_id) as Actual_Test_Runs_Executed,
    -- Efficiency: Actual vs Planned
    CAST((SELECT COUNT(*) FROM Test_Run tr 
          JOIN Configuration_Details cd2 ON tr.Config_id = cd2.Configuration_id 
          WHERE cd2.Owner_id = co.Owner_id) as FLOAT) / 
    NULLIF(SUM(cd.Test_runs), 0) * 100 as Execution_Rate
FROM Configuration_Owners co
LEFT JOIN Configuration_Details cd ON co.Owner_id = cd.Owner_id
GROUP BY co.Name, co.Owner_id
ORDER BY Actual_Test_Runs_Executed DESC;

-- Find owners with high failure rates (may need support)
SELECT 
    co.Name as Owner,
    COUNT(tr.Test_Runid) as Total_Runs,
    SUM(CASE WHEN tr.status = 'Fail' THEN 1 ELSE 0 END) as Failures,
    CAST(SUM(CASE WHEN tr.status = 'Fail' THEN 1 ELSE 0 END) as FLOAT) / 
    NULLIF(SUM(CASE WHEN tr.status IN ('Pass', 'Fail') THEN 1 ELSE 0 END), 0) * 100 as Failure_Rate
FROM Test_Run tr
JOIN Configuration_Details cd ON tr.Config_id = cd.Configuration_id
JOIN Configuration_Owners co ON cd.Owner_id = co.Owner_id
WHERE tr.status IN ('Pass', 'Fail')
GROUP BY co.Name
HAVING COUNT(tr.Test_Runid) > 10
ORDER BY Failure_Rate DESC;

/*
Risk Assessment & Projection
*/

-- High-risk: Configurations with high failure rates AND low test coverage
WITH ConfigStats AS (
    SELECT 
        c.Configuration_id,
        c.Server,
        c.Operating_System,
        COUNT(tr.Test_Runid) as Test_Count,
        CAST(SUM(CASE WHEN tr.status = 'Fail' THEN 1 ELSE 0 END) as FLOAT) / 
        NULLIF(SUM(CASE WHEN tr.status IN ('Pass', 'Fail') THEN 1 ELSE 0 END), 0) * 100 as Failure_Rate,
        c.Test_runs as Planned_Tests
    FROM Configuration_Details c
    LEFT JOIN Test_Run tr ON c.Configuration_id = tr.Config_id
    GROUP BY c.Configuration_id, c.Server, c.Operating_System, c.Test_runs
    HAVING COUNT(tr.Test_Runid) > 0
)
SELECT 
    *,
    -- Risk Score: Failure Rate * (1 - Completion %)
    Failure_Rate * (1 - (CAST(Test_Count as FLOAT) / NULLIF(Planned_Tests, 0))) as Risk_Score
FROM ConfigStats
WHERE Test_Count < Planned_Tests -- Incomplete testing
ORDER BY Risk_Score DESC;

/*
Component Quality Analysis
*/

-- Link test results back to specific components (e.g., Adapter Firmware version)
-- This requires the Component_Phaseid in Configuration_Details to be populated, which it isn't in the sample.
-- Here is the analysis we *would* do if the data was linked:

SELECT 
    cd.Adapter, 
        --cd.Component_Version, 
    COUNT(tr.Test_Runid) as TotalRuns,
    SUM(CASE WHEN tr.status = 'Pass' THEN 1 ELSE 0 END) as PassedRuns,
    CAST(SUM(CASE WHEN tr.status = 'Pass' THEN 1 ELSE 0 END) as FLOAT) / NULLIF(COUNT(tr.Test_Runid), 0) * 100 as SuccessRate
FROM Test_Run tr
JOIN Configuration_Details cd ON tr.Config_id = cd.Configuration_id
-- JOIN Component_Details comp ON cd.Component_Version = comp.Version
GROUP BY cd.Adapter --, cd.Component_Version
ORDER BY SuccessRate ASC; -- Show worst-performing adapters first


/*
Readiness for Release (Go/No-Go Criteria)
*/

-- Critical metrics for a release decision
DECLARE @TotalTestRuns INT = (SELECT COUNT(*) FROM Test_Run);
DECLARE @TotalConfigs INT = (SELECT COUNT(*) FROM Configuration_Details);

SELECT 
    'Test Coverage' as Metric,
    CAST((SELECT COUNT(DISTINCT Config_id) FROM Test_Run) as FLOAT) / @TotalConfigs * 100 as Value,
    CASE WHEN CAST((SELECT COUNT(DISTINCT Config_id) FROM Test_Run) as FLOAT) / @TotalConfigs * 100 >= 85 THEN 'PASS' ELSE 'FAIL' END as Status
UNION ALL
SELECT 
    'Overall Pass Rate',
    (SELECT CAST(SUM(CASE WHEN status = 'Pass' THEN 1 ELSE 0 END) as FLOAT) / SUM(CASE WHEN status IN ('Pass', 'Fail') THEN 1 ELSE 0 END) * 100 
     FROM Test_Run),
    CASE WHEN (SELECT CAST(SUM(CASE WHEN status = 'Pass' THEN 1 ELSE 0 END) as FLOAT) / SUM(CASE WHEN status IN ('Pass', 'Fail') THEN 1 ELSE 0 END) * 100 
              FROM Test_Run) >= 95 THEN 'PASS' ELSE 'FAIL' END
UNION ALL
SELECT 
    'Blocked Test Rate',
    (SELECT CAST(SUM(CASE WHEN status = 'Block' THEN 1 ELSE 0 END) as FLOAT) / @TotalTestRuns * 100 FROM Test_Run),
    CASE WHEN (SELECT CAST(SUM(CASE WHEN status = 'Block' THEN 1 ELSE 0 END) as FLOAT) / @TotalTestRuns * 100 FROM Test_Run) <= 5 THEN 'PASS' ELSE 'FAIL' END;


/*
	1. KPI Definition & Calculation Queries
A. Test Efficiency & Productivity KPIs

1.1 Test Execution Rate (Planned vs. Actual)

*/
-- How many tests were planned vs. actually executed?
SELECT 
    SUM(cd.Test_runs) AS Total_Planned_Test_Runs,
    (SELECT COUNT(*) FROM Test_Run) AS Total_Actual_Test_Runs,
    CAST((SELECT COUNT(*) FROM Test_Run) AS FLOAT) / NULLIF(SUM(cd.Test_runs), 0) * 100 AS Execution_Rate_Percentage
FROM Configuration_Details cd;

-- What percentage of test cases are automated?
SELECT 
    isAutomated,
    COUNT(*) AS TestCase_Count,
    CAST(COUNT(*) * 100.0 / (SELECT COUNT(*) FROM Test_Cases) AS DECIMAL(5,2)) AS Percentage
FROM Test_Cases
GROUP BY isAutomated;

-- Parse duration and find average test time per module (identify bottlenecks)
-- Average Test Duration by Module
WITH ParsedDurations AS (
    SELECT 
        Module,
        TestCase_id,
        -- Convert all durations to minutes
        CASE 
            WHEN TestCase_Duration LIKE '%day%' THEN 
                (CAST(SUBSTRING(TestCase_Duration, 1, CHARINDEX('day', TestCase_Duration)-2) AS FLOAT) * 24 * 60) +
                (CAST(SUBSTRING(TestCase_Duration, CHARINDEX('day', TestCase_Duration)+4, CHARINDEX('hr', TestCase_Duration) - (CHARINDEX('day', TestCase_Duration)+4)) AS FLOAT) * 60) +
                CAST(SUBSTRING(TestCase_Duration, CHARINDEX('mins', TestCase_Duration)-3, 2) AS FLOAT)
            WHEN TestCase_Duration LIKE '%hr%' THEN 
                (CAST(SUBSTRING(TestCase_Duration, 1, CHARINDEX('hr', TestCase_Duration)-1) AS FLOAT) * 60) +
                CAST(SUBSTRING(TestCase_Duration, CHARINDEX('mins', TestCase_Duration)-3, 2) AS FLOAT)
            ELSE CAST(SUBSTRING(TestCase_Duration, 1, CHARINDEX('mins', TestCase_Duration)-1) AS FLOAT)
        END AS Duration_Mins
    FROM Test_Cases
)
SELECT 
    Module,
    AVG(Duration_Mins) AS Avg_Duration_Mins,
    SUM(Duration_Mins) AS Total_Module_Duration_Mins
FROM ParsedDurations
GROUP BY Module
ORDER BY Total_Module_Duration_Mins DESC;

/*
B. Quality & Reliability KPIs

2.1 Overall Test Pass/Fail/Block Rate
*/

-- High-level quality assessment
SELECT 
    status,
    COUNT(*) AS Run_Count,
    CAST(COUNT(*) * 100.0 / (SELECT COUNT(*) FROM Test_Run) AS DECIMAL(5,2)) AS Percentage
FROM Test_Run
GROUP BY status
ORDER BY Run_Count DESC;

-- Which configurations are most/least stable?
SELECT 
    cd.Configuration_id,
    cd.Server,
    cd.Operating_System,
    COUNT(tr.Test_Runid) AS Total_Runs,
    SUM(CASE WHEN tr.status = 'Pass' THEN 1 ELSE 0 END) AS Passed_Runs,
    SUM(CASE WHEN tr.status = 'Fail' THEN 1 ELSE 0 END) AS Failed_Runs,
    CAST(SUM(CASE WHEN tr.status = 'Pass' THEN 1 ELSE 0 END) AS FLOAT) / 
    NULLIF(COUNT(tr.Test_Runid), 0) * 100 AS Pass_Rate
FROM Test_Run tr
JOIN Configuration_Details cd ON tr.Config_id = cd.Configuration_id
GROUP BY cd.Configuration_id, cd.Server, cd.Operating_System
HAVING COUNT(tr.Test_Runid) > 3 -- Only consider sufficiently tested configs
ORDER BY Pass_Rate ASC; -- Show least stable first

-- Identify which software modules have the highest failure rates
SELECT 
    tc.Module,
    COUNT(tr.Test_Runid) AS Total_Runs,
    SUM(CASE WHEN tr.status = 'Fail' THEN 1 ELSE 0 END) AS Failures,
    SUM(CASE WHEN tr.status = 'Block' THEN 1 ELSE 0 END) AS Blocked,
    CAST(SUM(CASE WHEN tr.status = 'Fail' THEN 1 ELSE 0 END) AS FLOAT) / 
    NULLIF(SUM(CASE WHEN tr.status IN ('Pass', 'Fail') THEN 1 ELSE 0 END), 0) * 100 AS Failure_Rate
FROM Test_Run tr
JOIN Test_Cases tc ON tr.TestCase_id = tc.TestCase_id
GROUP BY tc.Module
ORDER BY Failure_Rate DESC;


/*
C. Coverage & Completeness KPIs

3.1 Test Coverage by Server Platform

*/

-- Are we testing on all server platforms?
SELECT 
    cd.Server,
    COUNT(DISTINCT cd.Configuration_id) AS Total_Configs,
    COUNT(DISTINCT tr.Config_id) AS Tested_Configs,
    CAST(COUNT(DISTINCT tr.Config_id) AS FLOAT) / 
    NULLIF(COUNT(DISTINCT cd.Configuration_id), 0) * 100 AS Coverage_Percentage
FROM Configuration_Details cd
LEFT JOIN Test_Run tr ON cd.Configuration_id = tr.Config_id
GROUP BY cd.Server
ORDER BY Coverage_Percentage ASC; -- Show least covered first

-- Are we testing on all supported OSes?
SELECT 
    cd.Operating_System,
    COUNT(DISTINCT cd.Configuration_id) AS Total_Configs,
    COUNT(DISTINCT tr.Config_id) AS Tested_Configs,
    CAST(COUNT(DISTINCT tr.Config_id) AS FLOAT) / 
    NULLIF(COUNT(DISTINCT cd.Configuration_id), 0) * 100 AS Coverage_Percentage
FROM Configuration_Details cd
LEFT JOIN Test_Run tr ON cd.Configuration_id = tr.Config_id
GROUP BY cd.Operating_System
ORDER BY Coverage_Percentage ASC;

-- How many test cases have been executed vs. defined?
SELECT 
    (SELECT COUNT(*) FROM Test_Cases) AS Total_Test_Cases_Defined,
    COUNT(DISTINCT TestCase_id) AS Test_Cases_Executed,
    CAST(COUNT(DISTINCT TestCase_id) AS FLOAT) / 
    (SELECT COUNT(*) FROM Test_Cases) * 100 AS Utilization_Percentage
FROM Test_Run;

/*

D. Resource & Ownership KPIs

4.1 Workload Distribution Across Teams/Owners

*/

-- How is the testing workload distributed?
SELECT 
    co.Name AS Owner,
    COUNT(DISTINCT cd.Configuration_id) AS Configs_Managed,
    SUM(cd.Test_runs) AS Planned_Test_Runs,
    (SELECT COUNT(*) FROM Test_Run tr 
     JOIN Configuration_Details cd2 ON tr.Config_id = cd2.Configuration_id 
     WHERE cd2.Owner_id = co.Owner_id) AS Actual_Test_Runs_Executed
FROM Configuration_Owners co
LEFT JOIN Configuration_Details cd ON co.Owner_id = cd.Owner_id
GROUP BY co.Name, co.Owner_id
ORDER BY Actual_Test_Runs_Executed DESC;


-- Which owners/teams have the highest quality output?
SELECT 
    co.Name AS Owner,
    COUNT(tr.Test_Runid) AS Total_Runs,
    SUM(CASE WHEN tr.status = 'Pass' THEN 1 ELSE 0 END) AS Passed_Runs,
    CAST(SUM(CASE WHEN tr.status = 'Pass' THEN 1 ELSE 0 END) AS FLOAT) / 
    NULLIF(COUNT(tr.Test_Runid), 0) * 100 AS Pass_Rate
FROM Test_Run tr
JOIN Configuration_Details cd ON tr.Config_id = cd.Configuration_id
JOIN Configuration_Owners co ON cd.Owner_id = co.Owner_id
WHERE tr.status IN ('Pass', 'Fail')
GROUP BY co.Name
HAVING COUNT(tr.Test_Runid) > 10
ORDER BY Pass_Rate DESC;

/*

2. Advanced IT Analysis Queries
A. Trend Analysis & Forecasting

A.1 Project Phase Progress vs. Test Completion

*/

-- If dates were available: Track test execution velocity against project phases
SELECT 
    pp.Phase_Name,
    pp.Start_Date,
    pp.End_Date,
    (SELECT COUNT(*) FROM Test_Run tr 
     WHERE CAST(tr.Start_Date AS DATE) BETWEEN pp.Start_Date AND pp.End_Date) AS Tests_Completed_In_Phase
FROM Project_Phases pp
WHERE pp.Phase_Name IS NOT NULL
ORDER BY pp.Start_Date;


-- Is a specific server/OS/adapter combination causing most failures?
--Root cause Analysis
SELECT TOP 10
    cd.Server,
    cd.Adapter,
    cd.Operating_System,
    COUNT(tr.Test_Runid) AS Total_Runs,
    SUM(CASE WHEN tr.status = 'Fail' THEN 1 ELSE 0 END) AS Failure_Count,
    CAST(SUM(CASE WHEN tr.status = 'Fail' THEN 1 ELSE 0 END) AS FLOAT) / 
    NULLIF(COUNT(tr.Test_Runid), 0) * 100 AS Failure_Rate
FROM Test_Run tr
JOIN Configuration_Details cd ON tr.Config_id = cd.Configuration_id
WHERE tr.status IN ('Pass', 'Fail')
GROUP BY cd.Server, cd.Adapter, cd.Operating_System
HAVING COUNT(tr.Test_Runid) > 5
ORDER BY Failure_Rate DESC;


-- What is causing the most blockers? (e.g., a specific test case or configuration)
SELECT 
    tc.TestCase_id,
    tc.Module,
    cd.Server,
    cd.Operating_System,
    COUNT(*) AS Blocked_Count
FROM Test_Run tr
JOIN Test_Cases tc ON tr.TestCase_id = tc.TestCase_id
JOIN Configuration_Details cd ON tr.Config_id = cd.Configuration_id
WHERE tr.status = 'Block'
GROUP BY tc.TestCase_id, tc.Module, cd.Server, cd.Operating_System
ORDER BY Blocked_Count DESC;

/*
3. Executive Summary View (Dashboard Query)
*/

SELECT 
    -- Volume Metrics
    (SELECT COUNT(*) FROM Project_Details) AS Total_Projects,
    (SELECT COUNT(*) FROM Configuration_Details) AS Total_Configurations,
    (SELECT COUNT(*) FROM Test_Cases) AS Total_Test_Cases,
    (SELECT COUNT(*) FROM Test_Run) AS Total_Test_Runs_Executed,

    -- Quality Metrics
    (SELECT CAST(SUM(CASE WHEN status = 'Pass' THEN 1 ELSE 0 END) AS FLOAT) / 
            SUM(CASE WHEN status IN ('Pass', 'Fail') THEN 1 ELSE 0 END) * 100 
     FROM Test_Run) AS Overall_Pass_Rate,

    -- Efficiency Metrics
    (SELECT CAST(COUNT(DISTINCT Config_id) AS FLOAT) / 
            (SELECT COUNT(*) FROM Configuration_Details) * 100 
     FROM Test_Run) AS Hardware_Coverage_Percentage,

    -- Risk Metrics
    (SELECT CAST(SUM(CASE WHEN status = 'Block' THEN 1 ELSE 0 END) AS FLOAT) / 
            COUNT(*) * 100 
     FROM Test_Run) AS Blocked_Tests_Percentage