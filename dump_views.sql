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
define DB_VIEW=&2 ''

-- Generate the actual export script
spool /mnt/out/run_dump_views.sql
begin
  -- Write script to dump single view if DB_VIEW defined
  if (trim('&&DB_VIEW') is not null) then
    -- Save to `/mnt/out/[SCHEMA].[VIEW].sql`
    -- We append ';' as new line instead of using `DBMS_METADATA.SET_TRANSFORM_PARAM(DBMS_METADATA.SESSION_TRANSFORM,'SQLTERMINATOR',true);`
    -- due to ';' being swallowed if last line is comment - i.e. `-- ... ;`
    dbms_output.put_line (q'[
spool "/mnt/out/]'||upper('&&DB_SCHEMA')||'.'||upper('&&DB_VIEW')||q'[.sql"
select
  ltrim(
    dbms_metadata.get_ddl('VIEW', upper('&&DB_VIEW'), upper('&&DB_SCHEMA'))||chr(10)||';',
    chr(10)||' '
  )
from dual;
spool off
]'
    );
  -- Write script to dump all views
  else
    for v in (select owner, view_name from all_views where owner=upper('&&DB_SCHEMA')) loop
      -- `ltrim` fixes the leading '\n '
      -- e.g.: `select ltrim(dbms_metadata.get_ddl('VIEW', 'SOME_VIEW', 'SOME_SCHEMA')||chr(10)||';',chr(10)||''') from dual;`
      dbms_output.put_line (
        q'[
spool "/mnt/out/]'||v.owner||'.'||v.view_name||q'[.sql"
select
  ltrim(
    dbms_metadata.get_ddl('VIEW', ']'||v.view_name||q'[', ']'||v.owner||q'[')||chr(10)||';',
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
@/mnt/out/run_dump_views.sql

exit
