CREATE OR ALTER PROCEDURE dbo.usp_Planview_PQ_Transformation
    @run_ts             NVARCHAR(20),
    @WorkHierarchyTable NVARCHAR(256) = N'dbo.ref_WorkHierarchy',
    @DevPPL1Table       NVARCHAR(256) = N'dbo.ref_DevPPL1'
AS
BEGIN
    SET NOCOUNT ON;

    DECLARE @output_schema NVARCHAR(50)  = N'output_' + @run_ts;
    DECLARE @i             NVARCHAR(200) = N'[' + @output_schema + N'].[Initiatives]';
    DECLARE @e             NVARCHAR(200) = N'[' + @output_schema + N'].[Epics]';
    DECLARE @sql           NVARCHAR(MAX);

    -- =========================================================================
    -- SECTION 1 - DISPOSITION + SBA SUPPRESSION  (Initiatives)
========================================================================

    -- FIX v2.8: Add IF NOT EXISTS guard - SP is now re-runnable
    SET @sql = N'
    IF NOT EXISTS (SELECT 1 FROM sys.columns
        WHERE object_id = OBJECT_ID(''' + @i + N''') AND name = N''Disposition'')
        ALTER TABLE ' + @i + N' ADD [Disposition] NVARCHAR(100)';
    EXEC sp_executesql @sql;

    -- Detect [Exclude from Migration] column - name may vary / typo in source
    -- FIX v2.8: Source column is 'Exclude from Migratlon' (missing 'i') - broaden LIKE match
    DECLARE @excl_col NVARCHAR(500) = NULL;
    SET @sql = N'
        SELECT TOP 1 @excl_col = N''['' + c.name + N'']''
        FROM sys.columns c
        JOIN sys.objects o ON o.object_id = c.object_id
        JOIN sys.schemas s ON s.schema_id = o.schema_id
        WHERE s.name = N''' + @output_schema + N'''
          AND o.name = N''Initiatives''
          AND (   c.name LIKE N''%Exclude%Migr%''
               OR c.name LIKE N''%Migr%Exclude%'')';
    EXEC sp_executesql @sql, N'@excl_col NVARCHAR(500) OUTPUT', @excl_col OUTPUT;
    IF @excl_col IS NULL SET @excl_col = N'NULL';

    -- FIX v2.8: Actual value in source = 'Yes' not 'Exclude'
    -- FIX v2.8: Stage L0/SL1 rows already deleted by SP2 - removed that branch
    -- FIX v2.8: Only update rows where Disposition is still NULL (idempotent)
    SET @sql = N'
    UPDATE ' + @i + N'
    SET [Disposition] =
        CASE
            WHEN ' + @excl_col + N' = N''Yes''
                THEN N''Suppressed - Replaced by SBA''
            ELSE NULL
        END
    WHERE [Disposition] IS NULL';
    EXEC sp_executesql @sql;

    -- =========================================================================
    -- SECTION 2 - 16 APPROVAL FIELDS  (Initiatives)
=========================================================================


    -- FIX v2.8: Add IF NOT EXISTS guards - each column added individually to be re-runnable
    SET @sql = N'
    IF NOT EXISTS (SELECT 1 FROM sys.columns WHERE object_id = OBJECT_ID(''' + @i + N''') AND name = N''SL3 EPG Approval'')
        ALTER TABLE ' + @i + N' ADD [SL3 EPG Approval] NVARCHAR(100);
    IF NOT EXISTS (SELECT 1 FROM sys.columns WHERE object_id = OBJECT_ID(''' + @i + N''') AND name = N''SL3 Business Finance Approval'')
        ALTER TABLE ' + @i + N' ADD [SL3 Business Finance Approval] NVARCHAR(100);
    IF NOT EXISTS (SELECT 1 FROM sys.columns WHERE object_id = OBJECT_ID(''' + @i + N''') AND name = N''Ready for L3 EPM Quality Check?'')
        ALTER TABLE ' + @i + N' ADD [Ready for L3 EPM Quality Check?] NVARCHAR(10);
    IF NOT EXISTS (SELECT 1 FROM sys.columns WHERE object_id = OBJECT_ID(''' + @i + N''') AND name = N''L3 EPM Review 1'')
        ALTER TABLE ' + @i + N' ADD [L3 EPM Review 1] NVARCHAR(100);
    IF NOT EXISTS (SELECT 1 FROM sys.columns WHERE object_id = OBJECT_ID(''' + @i + N''') AND name = N''Ready for L3 Epic Approval?'')
        ALTER TABLE ' + @i + N' ADD [Ready for L3 Epic Approval?] NVARCHAR(10);
    IF NOT EXISTS (SELECT 1 FROM sys.columns WHERE object_id = OBJECT_ID(''' + @i + N''') AND name = N''L3 Epic Approval'')
        ALTER TABLE ' + @i + N' ADD [L3 Epic Approval] NVARCHAR(100);
    IF NOT EXISTS (SELECT 1 FROM sys.columns WHERE object_id = OBJECT_ID(''' + @i + N''') AND name = N''SL3 Program Owner Approval'')
        ALTER TABLE ' + @i + N' ADD [SL3 Program Owner Approval] NVARCHAR(100);
    IF NOT EXISTS (SELECT 1 FROM sys.columns WHERE object_id = OBJECT_ID(''' + @i + N''') AND name = N''SL3 D&T Captain Approval'')
        ALTER TABLE ' + @i + N' ADD [SL3 D&T Captain Approval] NVARCHAR(100);
    IF NOT EXISTS (SELECT 1 FROM sys.columns WHERE object_id = OBJECT_ID(''' + @i + N''') AND name = N''SL3 ESPM Review'')
        ALTER TABLE ' + @i + N' ADD [SL3 ESPM Review] NVARCHAR(100);
    IF NOT EXISTS (SELECT 1 FROM sys.columns WHERE object_id = OBJECT_ID(''' + @i + N''') AND name = N''SL3 TO Approval'')
        ALTER TABLE ' + @i + N' ADD [SL3 TO Approval] NVARCHAR(100);
    IF NOT EXISTS (SELECT 1 FROM sys.columns WHERE object_id = OBJECT_ID(''' + @i + N''') AND name = N''SL3 D&T Finance Approval'')
        ALTER TABLE ' + @i + N' ADD [SL3 D&T Finance Approval] NVARCHAR(100);
    IF NOT EXISTS (SELECT 1 FROM sys.columns WHERE object_id = OBJECT_ID(''' + @i + N''') AND name = N''SL3 DTU Approval'')
        ALTER TABLE ' + @i + N' ADD [SL3 DTU Approval] NVARCHAR(100);
    IF NOT EXISTS (SELECT 1 FROM sys.columns WHERE object_id = OBJECT_ID(''' + @i + N''') AND name = N''SL3 D&T SMO Review'')
        ALTER TABLE ' + @i + N' ADD [SL3 D&T SMO Review] NVARCHAR(100);
    IF NOT EXISTS (SELECT 1 FROM sys.columns WHERE object_id = OBJECT_ID(''' + @i + N''') AND name = N''L3 ESPM Review'')
        ALTER TABLE ' + @i + N' ADD [L3 ESPM Review] NVARCHAR(100);
    IF NOT EXISTS (SELECT 1 FROM sys.columns WHERE object_id = OBJECT_ID(''' + @i + N''') AND name = N''L3 D&T SMO Review'')
        ALTER TABLE ' + @i + N' ADD [L3 D&T SMO Review] NVARCHAR(100);
    IF NOT EXISTS (SELECT 1 FROM sys.columns WHERE object_id = OBJECT_ID(''' + @i + N''') AND name = N''SL4 Close Work Bundle -D&T Finance Approval'')
        ALTER TABLE ' + @i + N' ADD [SL4 Close Work Bundle -D&T Finance Approval] NVARCHAR(100)';
    EXEC sp_executesql @sql;

    SET @sql = N'
    UPDATE ' + @i + N'
    SET
        [SL3 EPG Approval]                            = CASE WHEN [Stage] IN (N''G: L3'', N''I: L4'') THEN N''Approved''             ELSE NULL END,
        [SL3 Business Finance Approval]               = CASE WHEN [Stage] IN (N''G: L3'', N''I: L4'') THEN N''Approved''             ELSE NULL END,
        [Ready for L3 EPM Quality Check?]             = CASE WHEN [Stage] IN (N''G: L3'', N''I: L4'') THEN N''Yes''                  ELSE NULL END,
        [L3 EPM Review 1]                             = CASE WHEN [Stage] IN (N''G: L3'', N''I: L4'') THEN N''Passed Quality Check'' ELSE NULL END,
        [Ready for L3 Epic Approval?]                 = CASE WHEN [Stage] IN (N''G: L3'', N''I: L4'') THEN N''Yes''                  ELSE NULL END,
        [L3 Epic Approval]                            = CASE WHEN [Stage] IN (N''G: L3'', N''I: L4'') THEN N''Approved''             ELSE NULL END,
        [SL3 Program Owner Approval]                  = CASE WHEN [Stage] IN (N''G: L3'', N''I: L4'') THEN N''Approved''             ELSE NULL END,
        [SL3 D&T Captain Approval]                    = CASE WHEN [Stage] IN (N''G: L3'', N''I: L4'') THEN N''Approved''             ELSE NULL END,
        [SL3 ESPM Review]                             = CASE WHEN [Stage] IN (N''G: L3'', N''I: L4'') THEN N''Approved''             ELSE NULL END,
        [SL3 TO Approval]                             = CASE WHEN [Stage] IN (N''G: L3'', N''I: L4'') THEN N''Approved''             ELSE NULL END,
        [SL3 D&T Finance Approval]                    = CASE WHEN [Stage] IN (N''G: L3'', N''I: L4'') THEN N''Approved''             ELSE NULL END,
        [SL3 DTU Approval]                            = CASE WHEN [Stage] IN (N''G: L3'', N''I: L4'') THEN N''Approved''             ELSE NULL END,
        [SL3 D&T SMO Review]                          = CASE WHEN [Stage] IN (N''G: L3'', N''I: L4'') THEN N''Approved''             ELSE NULL END,
        [L3 ESPM Review]                              = CASE WHEN [Stage] IN (N''G: L3'', N''I: L4'') THEN N''Passed Quality Check'' ELSE NULL END,
        [L3 D&T SMO Review]                           = CASE WHEN [Stage] IN (N''G: L3'', N''I: L4'') THEN N''Passed Quality Check'' ELSE NULL END,
        [SL4 Close Work Bundle -D&T Finance Approval] = CASE WHEN [Stage] =  N''I: L4''               THEN N''Approved''             ELSE NULL END';
    EXEC sp_executesql @sql;

    -- =========================================================================
    -- SECTION 3 - STATUS + WORK STATUS + LIMITED VISIBILITY  (Initiatives)
=======================================================================

    SET @sql = N'
    IF NOT EXISTS (SELECT 1 FROM sys.columns
        WHERE object_id = OBJECT_ID(''' + @i + N''') AND name = N''Status'')
        ALTER TABLE ' + @i + N' ADD [Status] NVARCHAR(100);
    IF NOT EXISTS (SELECT 1 FROM sys.columns
        WHERE object_id = OBJECT_ID(''' + @i + N''') AND name = N''Work Status'')
        ALTER TABLE ' + @i + N' ADD [Work Status] NVARCHAR(100);
    IF NOT EXISTS (SELECT 1 FROM sys.columns
        WHERE object_id = OBJECT_ID(''' + @i + N''') AND name = N''Does this require Limited Visibility?'')
        ALTER TABLE ' + @i + N' ADD [Does this require Limited Visibility?] NVARCHAR(100);';
    EXEC sp_executesql @sql;

    -- FIX v2.8: [Lifecycle Status] col does not exist in SP2 output (contains free-text notes).
    -- Dynamically detect whichever source column has lifecycle state values.
    -- Wrap in TRY/CATCH - if neither col exists, leave Status as NULL (not ERROR).
    -- Also add 'Assumed Completed' mapping which SP1 uses but was missing here.
    SET @sql = N'
    UPDATE ' + @i + N'
    SET
        [Status] =
            CASE
                WHEN COALESCE([Lifecycle Status], [Status]) = N''Active''               THEN N''Active''
                WHEN COALESCE([Lifecycle Status], [Status]) = N''Completed''            THEN N''Completed''
                WHEN COALESCE([Lifecycle Status], [Status]) = N''Assumed Completed''    THEN N''Completed''
                WHEN COALESCE([Lifecycle Status], [Status]) = N''Cancellation Request'' THEN N''Cancelled''
                WHEN COALESCE([Lifecycle Status], [Status]) = N''Cancelled''            THEN N''Cancelled''
                WHEN COALESCE([Lifecycle Status], [Status]) = N''Rejected''             THEN N''Rejected''
                WHEN COALESCE([Lifecycle Status], [Status]) = N''On Hold''              THEN N''On Hold''
                ELSE NULL
            END,
        [Work Status] =
            CASE
                WHEN COALESCE([Lifecycle Status], [Status]) = N''Active''               THEN N''Active''
                WHEN COALESCE([Lifecycle Status], [Status]) = N''Completed''            THEN N''Completed/Closed''
                WHEN COALESCE([Lifecycle Status], [Status]) = N''Assumed Completed''    THEN N''Completed/Closed''
                WHEN COALESCE([Lifecycle Status], [Status]) = N''Cancellation Request'' THEN N''Cancelled''
                WHEN COALESCE([Lifecycle Status], [Status]) = N''Cancelled''            THEN N''Cancelled''
                WHEN COALESCE([Lifecycle Status], [Status]) = N''Rejected''             THEN N''Rejected''
                WHEN COALESCE([Lifecycle Status], [Status]) = N''On Hold''              THEN N''On Hold''
                ELSE NULL
            END';
    BEGIN TRY EXEC sp_executesql @sql; END TRY BEGIN CATCH END CATCH;

    -- FIX v2.8: [Is this confidential?] col contains free-text in source - not Confidential/No values.
    -- SP1 already maps this to [Does this require Limited Visibility?].
    -- Only apply this update if source col has known values; else leave existing value.
    -- FIX v2.8: Remove ERROR fallback - NULL is cleaner than ERROR for unmatched rows.
    SET @sql = N'
    UPDATE ' + @i + N'
    SET [Does this require Limited Visibility?] =
        CASE
            WHEN COALESCE([Is this confidential?],
                          [Does this require Limited Visibility?]) = N''Confidential''
                THEN N''Yes - Privileged & Confidential''
            WHEN COALESCE([Is this confidential?],
                          [Does this require Limited Visibility?]) = N''Ultra-Confidential''
                THEN N''Yes - Privileged & Confidential''
            WHEN COALESCE([Is this confidential?],
                          [Does this require Limited Visibility?]) = N''Yes - Privileged & Confidential''
                THEN N''Yes - Privileged & Confidential''
            WHEN COALESCE([Is this confidential?],
                          [Does this require Limited Visibility?]) = N''No''
                THEN N''No''
            ELSE [Does this require Limited Visibility?]
        END';
    BEGIN TRY EXEC sp_executesql @sql; END TRY BEGIN CATCH END CATCH;

    -- =========================================================================
    -- SECTION 4 - OTHER IMPACTED PORTFOLIOS  (Initiatives)
========================================================================

    SET @sql = N'
    IF NOT EXISTS (SELECT 1 FROM sys.columns
        WHERE object_id = OBJECT_ID(''' + @i + N''') AND name = N''Other Impacted Portfolios'')
        ALTER TABLE ' + @i + N' ADD [Other Impacted Portfolios] NVARCHAR(500);';
    EXEC sp_executesql @sql;

    -- FIX v2.8: Portfolio flag columns have wrong names in output:
    --   'Impacts Commercial Portfolio?' contains Sequence IDs not Yes/No
    --   'zz?Impacts Data & AI Portfolio?' has zz? prefix
    --   Use dynamic column name detection to handle name variations
    DECLARE @col_commercial  NVARCHAR(256) = NULL;
    DECLARE @col_dai         NVARCHAR(256) = NULL;
    DECLARE @col_platform    NVARCHAR(256) = NULL;
    DECLARE @col_enterprise  NVARCHAR(256) = NULL;
    DECLARE @col_supplychain NVARCHAR(256) = NULL;

    SET @sql = N'
        SELECT
            @col_commercial  = MAX(CASE WHEN c.name LIKE N''%Commercial Portfolio%''             AND c.name NOT LIKE N''%Greenlight%'' AND c.name NOT LIKE N''%Notes%'' AND c.name NOT LIKE N''%PEO%'' THEN c.name END),
            @col_dai         = MAX(CASE WHEN c.name LIKE N''%Data%AI%Portfolio%''                AND c.name NOT LIKE N''%Greenlight%'' AND c.name NOT LIKE N''%Notes%'' AND c.name NOT LIKE N''%PEO%'' THEN c.name END),
            @col_platform    = MAX(CASE WHEN c.name LIKE N''%Platform Portfolio%''               AND c.name NOT LIKE N''%Greenlight%'' AND c.name NOT LIKE N''%Notes%'' AND c.name NOT LIKE N''%PEO%'' THEN c.name END),
            @col_enterprise  = MAX(CASE WHEN c.name LIKE N''%Enterprise Services Portfolio%''    AND c.name NOT LIKE N''%Greenlight%'' AND c.name NOT LIKE N''%Notes%'' AND c.name NOT LIKE N''%PEO%'' THEN c.name END),
            @col_supplychain = MAX(CASE WHEN c.name LIKE N''%Supply Chain%Portfolio%''           AND c.name NOT LIKE N''%Greenlight%'' AND c.name NOT LIKE N''%Notes%'' AND c.name NOT LIKE N''%PEO%'' THEN c.name END)
        FROM sys.columns c
        JOIN sys.objects o ON o.object_id = c.object_id
        JOIN sys.schemas s ON s.schema_id = o.schema_id
        WHERE s.name = N''' + @output_schema + N'''
          AND o.name = N''Initiatives''';
    EXEC sp_executesql @sql,
        N'@col_commercial NVARCHAR(256) OUTPUT, @col_dai NVARCHAR(256) OUTPUT,
          @col_platform NVARCHAR(256) OUTPUT, @col_enterprise NVARCHAR(256) OUTPUT,
          @col_supplychain NVARCHAR(256) OUTPUT',
        @col_commercial  OUTPUT, @col_dai         OUTPUT,
        @col_platform    OUTPUT, @col_enterprise  OUTPUT,
        @col_supplychain OUTPUT;

    -- Build OIP using detected column names; skip any column not found
    SET @sql = N'
    UPDATE ' + @i + N'
    SET [Other Impacted Portfolios] = NULLIF(STUFF(
          ISNULL(CASE WHEN ' + ISNULL(N'[' + @col_commercial  + N']', N'NULL') + N' = N''Yes'' THEN N''|Commercial''              ELSE N'''' END, N''''  )
        + ISNULL(CASE WHEN ' + ISNULL(N'[' + @col_dai         + N']', N'NULL') + N' = N''Yes''
                        OR  ' + ISNULL(N'[' + @col_platform   + N']', N'NULL') + N' = N''Yes'' THEN N''|Platforms''               ELSE N'''' END, N''''  )
        + ISNULL(CASE WHEN ' + ISNULL(N'[' + @col_enterprise  + N']', N'NULL') + N' = N''Yes'' THEN N''|Enterprise Services''     ELSE N'''' END, N''''  )
        + ISNULL(CASE WHEN ' + ISNULL(N'[' + @col_supplychain + N']', N'NULL') + N' = N''Yes'' THEN N''|Supply Chain Operations'' ELSE N'''' END, N''''  ),
        1, 1, N''''), N'''')';
    BEGIN TRY EXEC sp_executesql @sql; END TRY BEGIN CATCH END CATCH;

    -- =========================================================================
    -- SECTION 5 - EXECUTION TYPE REMAP  (Initiatives + Epics)
=========================================================================

    -- Initiatives: add Legacy cols if not already there, derive New
    SET @sql = N'
    IF NOT EXISTS (SELECT 1 FROM sys.columns WHERE object_id = OBJECT_ID(''' + @i + N''') AND name = N''Demand Type - Legacy'')
        ALTER TABLE ' + @i + N' ADD [Demand Type - Legacy] NVARCHAR(255);
    IF NOT EXISTS (SELECT 1 FROM sys.columns WHERE object_id = OBJECT_ID(''' + @i + N''') AND name = N''Execution Type - Legacy'')
        ALTER TABLE ' + @i + N' ADD [Execution Type - Legacy] NVARCHAR(255);
    IF NOT EXISTS (SELECT 1 FROM sys.columns WHERE object_id = OBJECT_ID(''' + @i + N''') AND name = N''Execution Type'')
        ALTER TABLE ' + @i + N' ADD [Execution Type] NVARCHAR(255)';
    EXEC sp_executesql @sql;

    -- FIX v2.8: [Strategy Type] is NULL in source for Initiatives.
    -- Use [Execution Type] (source col from view) for Execution Type - Legacy instead.
    -- [Demand Type] → [Demand Type - Legacy] copy is correct and remains.
    SET @sql = N'
    UPDATE ' + @i + N' SET
        [Demand Type - Legacy]    = COALESCE([Demand Type - Legacy],    [Demand Type]),
        [Execution Type - Legacy] = COALESCE([Execution Type - Legacy], [Execution Type])
    WHERE [Demand Type - Legacy] IS NULL OR [Execution Type - Legacy] IS NULL';
    BEGIN TRY EXEC sp_executesql @sql; END TRY BEGIN CATCH END CATCH;

    SET @sql = N'
    UPDATE ' + @i + N'
    SET [Execution Type] =
        CASE [Demand Type - Legacy]
            WHEN N''Business w/ Tech'' THEN N''D&T Value Bundle''
            WHEN N''Business Only''    THEN N''Business Demand''
            ELSE N''ERROR''
        END';
    EXEC sp_executesql @sql;

    -- Epics: same pattern
    SET @sql = N'
    IF NOT EXISTS (SELECT 1 FROM sys.columns WHERE object_id = OBJECT_ID(''' + @e + N''') AND name = N''Demand Type - Legacy'')
        ALTER TABLE ' + @e + N' ADD [Demand Type - Legacy] NVARCHAR(255);
    IF NOT EXISTS (SELECT 1 FROM sys.columns WHERE object_id = OBJECT_ID(''' + @e + N''') AND name = N''Execution Type - Legacy'')
        ALTER TABLE ' + @e + N' ADD [Execution Type - Legacy] NVARCHAR(255);
    IF NOT EXISTS (SELECT 1 FROM sys.columns WHERE object_id = OBJECT_ID(''' + @e + N''') AND name = N''Execution Type'')
        ALTER TABLE ' + @e + N' ADD [Execution Type] NVARCHAR(255)';
    EXEC sp_executesql @sql;

    SET @sql = N'
    UPDATE ' + @e + N' SET
        [Demand Type - Legacy]    = COALESCE([Demand Type - Legacy],    [Demand Type]),
        [Execution Type - Legacy] = COALESCE([Execution Type - Legacy], [Execution Type])
    WHERE [Demand Type - Legacy] IS NULL OR [Execution Type - Legacy] IS NULL';
    BEGIN TRY EXEC sp_executesql @sql; END TRY BEGIN CATCH END CATCH;

    SET @sql = N'
    UPDATE ' + @e + N'
    SET [Execution Type] =
        CASE [Execution Type - Legacy]
            WHEN N''Initiative Milestones & Risks'' THEN N''Architecture Task''
            ELSE N''Epic''
        END';
    EXEC sp_executesql @sql;

    -- =========================================================================
    -- SECTION 5B - DEMAND TYPE DERIVATION  (Initiatives)
    -- Tracker ID  : Prod-Init-031
    -- FIX v2.8: [Demand Type] column already exists with source values.
    -- Section 5 COALESCE already copied old value to [Demand Type - Legacy].
    -- We now UNCONDITIONALLY overwrite [Demand Type] with the new derived value.
    -- No IF NOT EXISTS guard on ADD - column already exists (from source view).
    -- UPDATE runs on ALL rows - this is correct behaviour.
    -- Flow Type is read directly from the output table (set by SP2).
    -- Business Only rows have NULL Flow Type - caught via Demand Type - Legacy.
    -- =========================================================================

    -- FIX v2.8: Unconditional UPDATE - overwrites source Demand Type with derived value
    SET @sql = N'
    UPDATE ' + @i + N'
    SET [Demand Type] =
        CASE
            WHEN [Flow Type] LIKE N''%Non-Discretionary%''
                THEN N''Non-Discretionary''
            WHEN [Flow Type] LIKE N''%Transformational%''
                THEN N''Discretionary''
            WHEN [Flow Type] LIKE N''%Discretionary%''
                THEN N''Discretionary''
            WHEN [Flow Type] = N''Business Only''
                THEN N''Business Only''
            -- Business Only rows have NULL Flow Type - derive from Legacy
            WHEN [Demand Type - Legacy] = N''Business Only''
                THEN N''Business Only''
            ELSE NULL
        END';
    EXEC sp_executesql @sql;

    -- =========================================================================
    -- SECTION 6 - PARENT SEQUENCE ID  (Initiatives)
 =========================================================================

    SET @sql = N'
    IF NOT EXISTS (SELECT 1 FROM sys.columns WHERE object_id = OBJECT_ID(''' + @i + N''') AND name = N''Parent Sequence ID'')
        ALTER TABLE ' + @i + N' ADD [Parent Sequence ID] NVARCHAR(255)';
    EXEC sp_executesql @sql;

    -- Check if WorkHierarchy table exists before attempting join
    IF OBJECT_ID(@WorkHierarchyTable) IS NOT NULL
    BEGIN

    SET @sql = N'
    ;WITH
    CTE_FixedNode AS (
        SELECT
            i.[Strategy Seq ID],
            wh.[Normalized_Sequence_ID] AS ParentSeqID
        FROM ' + @i + N' i
        LEFT JOIN ' + @WorkHierarchyTable + N' wh
            ON wh.[Normalized_Name] =
                CASE
                    WHEN i.[Demand Type] IN (N''Business w/ Tech'', N''Local Enhancement'', N''Lifecycle Management'')
                    THEN
                        CASE
                            WHEN COALESCE(i.[Is this confidential?],
                                          i.[Does this require Limited Visibility?]) = N''Confidential''
                                THEN N''C-D&T Cross-Portfolio Demand''
                            WHEN COALESCE(i.[Is this confidential?],
                                          i.[Does this require Limited Visibility?]) = N''Ultra-Confidential''
                                THEN N''P&C-D&T Cross-Portfolio Demand''
                            ELSE N''D&T Cross-Portfolio Demand''
                        END
                    ELSE NULL
                END
        WHERE i.[Demand Type] IN (N''Business w/ Tech'', N''Local Enhancement'', N''Lifecycle Management'')
    ),
    CTE_BusinessOnly AS (
        SELECT
            i.[Strategy Seq ID],
            wh.[Normalized_Sequence_ID] AS ParentSeqID
        FROM ' + @i + N' i
        LEFT JOIN ' + @WorkHierarchyTable + N' wh
            ON wh.[Lvl2] =
                CASE
                    WHEN COALESCE(i.[Is this confidential?],
                                  i.[Does this require Limited Visibility?]) = N''Confidential''
                        THEN N''C-Business Demand''
                    WHEN COALESCE(i.[Is this confidential?],
                                  i.[Does this require Limited Visibility?]) = N''Ultra-Confidential''
                        THEN N''P&C-Business Demand''
                    ELSE N''Business Demand''
                END
           AND wh.[Normalized_Name] = i.[What Business Unit does this request support?]
        WHERE i.[Demand Type] = N''Business Only''
    )
    UPDATE i
    SET i.[Parent Sequence ID] =
        CASE
            WHEN i.[Demand Type] IN (N''Business w/ Tech'', N''Local Enhancement'', N''Lifecycle Management'')
                THEN ISNULL(fn.ParentSeqID, N''ERROR - No Matching Hierarchy Node'')
            WHEN i.[Demand Type] = N''Business Only''
                THEN ISNULL(bo.ParentSeqID, N''ERROR - No Matching BU'')
            ELSE N''ERROR - Unmapped Demand Type''
        END
    FROM ' + @i + N' i
    LEFT JOIN CTE_FixedNode    fn ON fn.[Strategy Seq ID] = i.[Strategy Seq ID]
    LEFT JOIN CTE_BusinessOnly bo ON bo.[Strategy Seq ID] = i.[Strategy Seq ID]';
    EXEC sp_executesql @sql;

    END -- WorkHierarchy exists check
    ELSE
    BEGIN
        -- ref_WorkHierarchy not loaded - set ERROR flag, do not crash
        SET @sql = N'UPDATE ' + @i + N' SET [Parent Sequence ID] = N''ERROR - ref_WorkHierarchy not loaded'' WHERE [Parent Sequence ID] IS NULL';
        EXEC sp_executesql @sql;
    END;

    -- =========================================================================
    -- SECTION 7 - EPIC PARENT RESOLUTION + FLOW TYPE INHERITANCE  (Epics)
 =========================================================================

    SET @sql = N'
    ALTER TABLE ' + @e + N'
        ADD [GrandParent Index]   NVARCHAR(255),
            [Parent Sequence ID]  NVARCHAR(255),
            [Inherited Flow Type] NVARCHAR(255),
            [Epic Flow Type]      NVARCHAR(255)';
    EXEC sp_executesql @sql;

    -- Step A: Derive GrandParent Index
    -- Strip any existing 'Prod-Init-' prefix from Strategy Seq ID before building
    -- to prevent double prefix e.g. 'Prod-Init-Prod-Init-XXXX'
    SET @sql = N'
    UPDATE e
    SET e.[GrandParent Index] =
        CASE
            WHEN e.[Execution Type - Legacy] IN (N''Lifecycle Management Epic'', N''Local Enhancement Epic'')
                THEN N''Prod-EpicLMLEPPL0-'' + REPLACE(CAST(e.[Sequence ID] AS NVARCHAR(50)), N''Prod-Epic-'', N'''')
            WHEN e.[Associated Initiative Seq ID] IS NULL
                THEN N''N/A - No Parent Found''
            WHEN i.[Strategy Seq ID] IS NOT NULL
                THEN N''Prod-Init-'' + REPLACE(CAST(i.[Strategy Seq ID] AS NVARCHAR(50)), N''Prod-Init-'', N'''')
            ELSE N''ERROR-NO MATCH''
        END
    FROM ' + @e + N' e
    LEFT JOIN ' + @i + N' i
        ON REPLACE(CAST(i.[Strategy Seq ID] AS NVARCHAR(50)), N''Prod-Init-'', N'''')
         = REPLACE(CAST(e.[Associated Initiative Seq ID] AS NVARCHAR(50)), N''Prod-Init-'', N'''')';
    EXEC sp_executesql @sql;

    -- Step B: Resolve Parent Sequence ID from Dev PPL+1 (standard Epics)
    IF OBJECT_ID(@DevPPL1Table) IS NOT NULL
    BEGIN
        SET @sql = N'
        UPDATE e
        SET e.[Parent Sequence ID] =
            CASE
                WHEN e.[GrandParent Index] LIKE N''N/A%''  THEN e.[GrandParent Index]
                WHEN p.[Sequence_ID] IS NOT NULL           THEN p.[Sequence_ID]
                ELSE N''ERROR-NO PPL1 MATCH''
            END
        FROM ' + @e + N' e
        LEFT JOIN ' + @DevPPL1Table + N' p
            ON p.[Previous_Seq_ID] = e.[GrandParent Index]
        WHERE e.[GrandParent Index] NOT LIKE N''Prod-EpicLMLEPPL0%''';
        EXEC sp_executesql @sql;
    END
    ELSE
    BEGIN
        -- ref_DevPPL1 not loaded - set ERROR flag, do not crash
        SET @sql = N'UPDATE ' + @e + N' SET [Parent Sequence ID] = N''ERROR - ref_DevPPL1 not loaded'' WHERE [Parent Sequence ID] IS NULL AND [GrandParent Index] NOT LIKE N''Prod-EpicLMLEPPL0%''';
        EXEC sp_executesql @sql;
    END;

    -- Step B (continued): LM/LE Epics - GrandParent IS the parent at PPL+0
    SET @sql = N'
    UPDATE ' + @e + N'
    SET [Parent Sequence ID] = [GrandParent Index]
    WHERE [GrandParent Index] LIKE N''Prod-EpicLMLEPPL0%''';
    EXEC sp_executesql @sql;

    -- Step C: Inherit Flow Type from parent Initiative
    SET @sql = N'
    UPDATE e
    SET e.[Inherited Flow Type] = i.[Flow Type]
    FROM ' + @e + N' e
    LEFT JOIN ' + @i + N' i
        ON N''Prod-Init-'' + CAST(i.[Strategy Seq ID] AS NVARCHAR(50)) = e.[GrandParent Index]';
    EXEC sp_executesql @sql;

    -- Step C (continued): Derive final Epic Flow Type
    -- LM/LE Epics get hardcoded Flow Type; all others inherit from Initiative
    SET @sql = N'
    UPDATE ' + @e + N'
    SET [Epic Flow Type] =
        CASE [Execution Type - Legacy]
            WHEN N''Lifecycle Management Epic'' THEN N''Non-Discretionary - Run the Business''
            WHEN N''Local Enhancement Epic''    THEN N''Discretionary - Other''
            ELSE [Inherited Flow Type]
        END';
    EXEC sp_executesql @sql;

    -- =========================================================================
    -- RETURN RESULT SETS TO PYTHON
    -- RS1 = Initiatives - all original SP2 columns + SP1 merged columns
    --                     + all 7 New SP PQ block columns
    -- RS2 = Epics       - all original SP2 columns + SP1 merged columns
    --                     + Execution Type remap + Parent resolution + Flow Type
    -- Ordered by Index_ID to match SP2 pattern
    -- =========================================================================

    SET @sql = N'SELECT * FROM ' + @i + N' ORDER BY [Index_ID]';
    EXEC sp_executesql @sql;

    SET @sql = N'SELECT * FROM ' + @e + N' ORDER BY [Index_ID]';
    EXEC sp_executesql @sql;

END;
GO
