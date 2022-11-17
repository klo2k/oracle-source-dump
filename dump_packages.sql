-- Ensure we dump the package as-is
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

-- Get the schema and package name from command line
define DB_SCHEMA=&1
define DB_PACKAGE=&2 ''

-- Generate the actual export script
spool /mnt/out/run_dump_packages.sql
begin
  -- Set the '/' package terminator in output
  dbms_output.put_line(q'[exec DBMS_METADATA.SET_TRANSFORM_PARAM(DBMS_METADATA.SESSION_TRANSFORM,'SQLTERMINATOR',true);]');

  -- Write script to dump single package if DB_PACKAGE defined
  if (trim('&&DB_PACKAGE') is not null) then
    -- Save to `/mnt/out/[SCHEMA].[PACKAGE].sql`
    dbms_output.put_line (q'[
spool "/mnt/out/]'||upper('&&DB_SCHEMA')||'.'||upper('&&DB_PACKAGE')||q'[.sql"
select
  ltrim(
    dbms_metadata.get_ddl('PACKAGE', upper('&&DB_PACKAGE'), upper('&&DB_SCHEMA')),
    chr(10)||' '
  )
from dual;
spool off
]'
    );
  -- Write script to dump all packages
  else
    for p in (select distinct owner, name from all_source where type='PACKAGE' and owner=upper('&&DB_SCHEMA')) loop
      dbms_output.put_line ('spool "/mnt/out/'||p.owner||'.'||p.name||'.sql"');
      dbms_output.put_line (
        -- e.g. `select dbms_metadata.get_ddl('PACKAGE', 'SOME_PACKAGE', 'SOME_SCHEMA')||chr(10)||';' from dual;`
        -- chr(39) = `'` - Work-around `ORA-03114: not connected to ORACLE` error if I use `'''`
        'select dbms_metadata.get_ddl(''PACKAGE'', '||chr(39)||p.name||chr(39)||', '||chr(39)||p.owner||chr(39)||') from dual;'
      );
      dbms_output.put_line ('spool off');
      -- `ltrim` fixes the leading '\n '
      -- chr(39) = `'` - Work-around `ORA-03114: not connected to ORACLE` error if I use `'''`
      -- e.g.: `select ltrim(dbms_metadata.get_ddl('PACKAGE', 'SOME_PACKAGE', 'SOME_SCHEMA'),chr(10)||' ') from dual;`
      dbms_output.put_line (
        q'[
spool "/mnt/out/]'||p.owner||'.'||p.name||q'[.sql"
select
  ltrim(
    dbms_metadata.get_ddl('PACKAGE', ']'||p.name||q'[', ']'||p.owner||q'['),
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
@/mnt/out/run_dump_packages.sql

exit
