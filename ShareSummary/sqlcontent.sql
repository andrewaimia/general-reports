SELECT AC.ACCOUNTID,
       AC.ACCOUNTNAME,
       AC.ACCOUNTTYPE,
       AC.ACCOUNTNUM,
       AC.STATUS,
       AC.NOTES,
       AC.HELDAT,
       AC.WEBSITE,
       AC.CONTACTINFO,
       AC.ACCESSINFO,
       AC.INITIALBAL,
       AC.FAVORITEACCT,
       AC.CURRENCYID,
       AC.STATEMENTLOCKED,
       AC.STATEMENTDATE,
       AC.MINIMUMBALANCE,
       AC.CREDITLIMIT,
       AC.INTERESTRATE,
       AC.PAYMENTDUEDATE,
       AC.MINIMUMPAYMENT
  FROM ACCOUNTLIST_V1 AS ac
       INNER JOIN
       CURRENCYFORMATS_V1 AS c ON c.CURRENCYID = ac.CURRENCYID
       LEFT JOIN
       CURRENCYHISTORY_V1 AS CH ON CH.CURRENCYID = c.CURRENCYID AND 
                                   CH.CURRDATE = (
                                                 SELECT MAX(CRHST.CURRDATE) 
                                                   FROM CURRENCYHISTORY_V1 AS CRHST
                                                  WHERE CRHST.CURRENCYID = c.CURRENCYID
                                                )
WHERE AC.ACCOUNTTYPE = 'Investment';