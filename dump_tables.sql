-- Ensure we dump the object as-is
set serveroutput on
SET LINESIZE 32767
SET PAGESIZE 0
SET LONG 2000000000

-- Increase performance: Fetch 32k characters at a time
SET LONGCHUNKSIZE 32000

SET SQLBLANKLINES ON
SET TRIMSPOOL ON
set feedback off
--set echo off
-- Disable echo output of 'define'
set verify off

-- Exit on error
whenever sqlerror exit sql.sqlcode
whenever oserror exit failure

-- Get the schema and object name from command line
define DB_SCHEMA=&1
define DB_TABLE=&2 ''

-- Generate the actual export script
spool /mnt/out/run_dump_tables.sql
begin
  dbms_output.put_line(q'[
-- Set the '/' SQL terminator in output
exec DBMS_METADATA.SET_TRANSFORM_PARAM(DBMS_METADATA.SESSION_TRANSFORM,'SQLTERMINATOR',true);
-- Make DDL more portable - remove segment attributes like storage, tablespace etc...
exec DBMS_METADATA.SET_TRANSFORM_PARAM(DBMS_METADATA.SESSION_TRANSFORM,'SEGMENT_ATTRIBUTES',false);
]'
  );

  -- Write script to dump single table if DB_TABLE defined
  if (trim('&&DB_TABLE') is not null) then
    -- Save to `/mnt/out/[SCHEMA].[TABLE].sql`
    -- We append ';' as new line instead of using `DBMS_METADATA.SET_TRANSFORM_PARAM(DBMS_METADATA.SESSION_TRANSFORM,'SQLTERMINATOR',true);`
    -- due to ';' being swallowed if last line is comment - i.e. `-- ... ;`
    dbms_output.put_line (q'[
spool "/mnt/out/]'||upper('&&DB_SCHEMA')||'.'||upper('&&DB_TABLE')||q'[.sql"
select
  ltrim(
    dbms_metadata.get_ddl('TABLE', upper('&&DB_TABLE'), upper('&&DB_SCHEMA')),
    chr(10)||' '
  )
from dual;
spool off
]'
    );
  -- Write script to dump all tables
  else
    for o in (
      -- Get tables only; filter out materialised views
      select owner, table_name from all_tables where owner=upper('&&DB_SCHEMA')
      minus
      select owner, mview_name from all_mviews where owner=upper('&&DB_SCHEMA')
    ) loop
      -- e.g.: `select ltrim(dbms_metadata.get_ddl('TABLE', 'SOME_TABLE', 'SOME_SCHEMA'),chr(10)||' ') from dual;`
      dbms_output.put_line (
        q'[
spool "/mnt/out/]'||o.owner||'.'||o.table_name||q'[.sql"
select
  ltrim(
    dbms_metadata.get_ddl('TABLE', ']'||o.table_name||q'[', ']'||o.owner||q'['),
    chr(10)||' '
  )
from dual;
spool off
]'
      );
    end loop;
  end if;
end;
/

spool off

-- Run the export script
@/mnt/out/run_dump_tables.sql

exit
