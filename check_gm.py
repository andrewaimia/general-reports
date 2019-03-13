#!/usr/bin/env python
# vi:tabstop=4:expandtab:shiftwidth=4:softtabstop=4:autoindent:smarttab

import os
import sqlite3

def check(curs, report):
    print ('checking %s' % report)
    sql = ''
    try:
        for line in open(os.path.join(report, 'sqlcontent.sql'), 'r'):
            sql = sql + line
        curs.execute(sql)
    except FileNotFoundError as fnf_error:
        print(fnf_error)
        exit_code = 0
    except:
        print('Error:Cannot process sql file')
        exit_code = 1
    else
        print ('processed %s' % report)
    finally:
        print ('done %s' % report)
        return(exit_code)


if __name__ == '__main__':
    dbschemafile = 'tables_v1.sql'
    exitcode = 0

    try:
        print('Connecting database...')
        conn = sqlite3.connect(':memory:')
    except:
        print('Error: Cannot connect to DB')
        exit_code = 1
    else:
        try:
            conn.row_factory = sqlite3.Row
            curs = conn.cursor()
            sql = ''
            print('Opening DB schema file %s...' % dbschemafile)
            try:
                sfile = open(dbschemafile, 'r')
            except FileNotFoundError as fnf_error:
                print(fnf_error)
                exit_code = 1
            except:
                print('Error:Cannot open DB schema file')
                exit_code = 1
            else:
                for line in sfile:
                    sql = sql + ' '+ line
                curs.executescript(sql)
                conn.commit()
                sfile.close()
        except:
            print('Error:Cannot process DB schema file')
            exitcode = 1
        else:
            anyNotPassed = False
            
            for report in os.listdir('.'):
                if not report.startswith('.') and os.path.isdir(report):
                    try:
                        check(curs, report)
                    except:
                        anyNotPassed = True
                        print ('ERR: %s' % report)
            conn.close()
            
            if anyNotPassed:
                exitcode = 1
        finally:
            conn.close()
    finally:
        print('End')
    
    exit(exitcode)