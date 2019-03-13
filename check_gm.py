#!/usr/bin/env python
# vi:tabstop=4:expandtab:shiftwidth=4:softtabstop=4:autoindent:smarttab

import os
import sqlite3

def check(curs, report):
    print ('checking %s' % report)
    sql = ''
    for line in open(os.path.join(report, 'sqlcontent.sql'), 'r'):
        sql = sql + line
    curs.execute(sql)
    print ('done %s' % report)

if __name__ == '__main__':
    
    dbfilepath = 'C:\\Users\\andrew.owen\\OneDrive - Aimia Inc\\Documents\\Personal\\MMEX\\Fin'
    dbfilename = 'Test-rpt.mmb'
    dbschemafilepath = 'C:\\Users\\andrew.owen\\Documents\\GitHub\\andrewaimia-general-reports' 
    dbschemafile = 'tables_v1.sql'
    exitcode = 0

    try:
        #print('Connecting database...' % dbfilename)
        #conn = sqlite3.connect(dbfilepath + '\\' + dbfilename)
        print('Connecting database...')
        conn = sqlite3.connect(':memory:')
        conn.row_factory = sqlite3.Row
        curs = conn.cursor()
        sql = ''
    except:
        print('Error: Cannot connect to DB')
        exit_code = 1
    else:
        try:
            print('Opening DB schema file %s...' % dbschemafile)
            try:
                sfile = open(dbschemafilepath + '\\' + dbschemafile, 'r')
            except FileNotFoundError as fnf_error:
                print(fnf_error)
            except:
                print('Error:Cannot open DB schema file')
                exit_code = 1
            else:
                for line in sfile:
                    sql = sql + ' '+ line
                curs.executescript(sql)
                conn.commit()
                sql = '' #reset for next statement
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
        if not sfile.closed:
            sfile.close()
        print('End')
    
    exit(exitcode)