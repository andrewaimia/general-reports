SELECT CASE tdata.type WHEN 'Checking' THEN 1 WHEN 'Credit Card' THEN 2 WHEN 'Cash' THEN 3 WHEN 'Loan' THEN 4 WHEN 'Investment' THEN 5 WHEN 'Asset' THEN 6 WHEN 'Share' THEN 7 ELSE 10 END AS SORTORDER,
       CASE tdata.type WHEN 'Checking' THEN 'Bank Account' WHEN 'Investment' THEN 'Stocks' WHEN 'Asset' THEN 'Assets' ELSE tdata.type || ' Account' END AS TYPE,
       tdata.account AS ACCOUNT,
       tdata.pricedate AS PRICEDATE,
       tdata.balance AS BALANCE,
       tdata.basebalance AS BASEBALANCE,
       tdata.Reconciled AS RECONCILED,
       tdata.PFX_SYMBOL AS PFX_SYMBOL,
       tdata.SFX_SYMBOL AS SFX_SYMBOL,
       tdata.DECIMAL_POINT AS DECIMAL_POINT,
       tdata.GROUP_SEPARATOR AS GROUP_SEPARATOR,
	tdata.per_rate as PER_RATE,
	tdata.per_type as PER_TYPE
  FROM (
           SELECT acc.accounttype AS type,
                  acc.accountname AS account,
                  skh.date AS pricedate,
                  sum(stk.numshares * IFNULL(skh.value, stk.currentprice) ) AS balance,
                  sum(stk.numshares * IFNULL(skh.value, stk.currentprice) * CH1.CURRVALUE ) AS basebalance,
                  '' AS reconciled,
                  cf1.PFX_SYMBOL AS PFX_SYMBOL,
                  cf1.SFX_SYMBOL AS SFX_SYMBOL,
                  cf1.DECIMAL_POINT AS DECIMAL_POINT,
                  cf1.GROUP_SEPARATOR AS GROUP_SEPARATOR,
		0 as PER_RATE,
		'' as PER_TYPE
             FROM accountlist_v1 AS acc
                  JOIN
                  currencyformats_v1 AS cf1 ON acc.currencyid = cf1.currencyid
                  LEFT JOIN
                  CURRENCYHISTORY_v1 AS CH1 ON CH1.CURRENCYID = cf1.CURRENCYID AND 
                                              CH1.CURRDATE = (
                                                                SELECT MAX(CRHST.CURRDATE) 
                                                                  FROM CURRENCYHISTORY_v1 AS CRHST
                                                                 WHERE CRHST.CURRENCYID = cf1.CURRENCYID
                                                            )
                  JOIN
                  stock_v1 AS stk ON acc.ACCOUNTID = stk.heldat
                  JOIN
                  stockhistory_v1 AS skh ON skh.symbol = stk.symbol AND 
                                            skh.date = (
                                                           SELECT MAX(STKHST.DATE) 
                                                             FROM STOCKHISTORY_v1 AS STKHST
                                                            WHERE STKHST.SYMBOL = stk.symbol
                                                       )
            WHERE acc.ACCOUNTTYPE = 'Investment'
            GROUP BY acc.accounttype,
                     acc.accountname
           UNION ALL
           SELECT a.accounttype AS type,
                  a.ACCOUNTNAME AS account,
                  strftime('%Y-%m-%d', date('now') ) AS pricedate,
                  (
                      SELECT a.INITIALBAL + total(tb.TRANSAMOUNT) 
                        FROM (
                                 SELECT c1.ACCOUNTID,
                                        (CASE WHEN c1.TRANSCODE = 'Deposit' THEN c1.TRANSAMOUNT ELSE -c1.TRANSAMOUNT END) AS TRANSAMOUNT
                                   FROM CHECKINGACCOUNT_v1 AS c1
                                  WHERE c1.STATUS NOT IN ('D', 'V') 
                                 UNION ALL
                                 SELECT c2.TOACCOUNTID,
                                        c2.TOTRANSAMOUNT
                                   FROM CHECKINGACCOUNT_v1 AS c2
                                  WHERE c2.TRANSCODE = 'Transfer' AND 
                                        c2.STATUS NOT IN ('D', 'V') 
                             )
                             AS tb
                       WHERE tb.ACCOUNTID = a.ACCOUNTID
                  )
                  AS BALANCE,
                  (
                      SELECT a.INITIALBAL + total(tbb.TRANSAMOUNT) 
                        FROM (
                                 SELECT c1.ACCOUNTID,
                                        (CASE WHEN c1.TRANSCODE = 'Deposit' THEN c1.TRANSAMOUNT ELSE -c1.TRANSAMOUNT END) AS TRANSAMOUNT
                                   FROM CHECKINGACCOUNT_v1 AS c1
                                  WHERE c1.STATUS NOT IN ('D', 'V') 
                                 UNION ALL
                                 SELECT c2.TOACCOUNTID,
                                        c2.TOTRANSAMOUNT
                                   FROM CHECKINGACCOUNT_v1 AS c2
                                  WHERE c2.TRANSCODE = 'Transfer' AND 
                                        c2.STATUS NOT IN ('D', 'V') 
                             )
                             AS tbb
                       WHERE tbb.ACCOUNTID = a.ACCOUNTID
                  ) * CH2.CURRVALUE
                  AS basebalance,
                  (
                      SELECT a.INITIALBAL + total(tr.TRANSAMOUNT) 
                        FROM (
                                 SELECT ca1.ACCOUNTID,
                                        (CASE WHEN ca1.TRANSCODE = 'Deposit' THEN ca1.TRANSAMOUNT ELSE -ca1.TRANSAMOUNT END) AS TRANSAMOUNT
                                   FROM CHECKINGACCOUNT_v1 AS ca1
                                  WHERE ca1.STATUS = 'R'
                                 UNION ALL
                                 SELECT ca2.TOACCOUNTID,
                                        ca2.TOTRANSAMOUNT
                                   FROM CHECKINGACCOUNT_v1 AS ca2
                                  WHERE ca2.TRANSCODE = 'Transfer' AND 
                                        ca2.STATUS = 'R'
                             )
                             AS tr
                       WHERE tr.ACCOUNTID = a.ACCOUNTID
                  )
                  AS RECONCILED,
                  cf2.PFX_SYMBOL,
                  cf2.SFX_SYMBOL,
                  cf2.DECIMAL_POINT,
                  cf2.GROUP_SEPARATOR,
		0 as PER_RATE,
		'' as PER_TYPE
             FROM ACCOUNTLIST_v1 AS a
                  INNER JOIN
                  CURRENCYFORMATS_v1 AS cf2 ON cf2.CURRENCYID = a.CURRENCYID
                  LEFT JOIN
                  CURRENCYHISTORY_v1 AS CH2 ON CH2.CURRENCYID = cf2.CURRENCYID AND 
                                              CH2.CURRDATE = (
                                                                SELECT MAX(CRHST2.CURRDATE) 
                                                                  FROM CURRENCYHISTORY_v1 AS CRHST2
                                                                 WHERE CRHST2.CURRENCYID = cf2.CURRENCYID
                                                            )
            WHERE a.ACCOUNTTYPE IN ('Checking', 'Term', 'Credit Card', 'Cash', 'Loan') AND 
                  a.STATUS = 'Open'
           UNION ALL
           SELECT 'Asset' AS TYPE,
                  ass.assetname AS ACCOUNT,
                  ass.startdate AS PRICEDATE,
                  ass.value AS BALANCE,
                  ass.value AS basebalance,--assets seem to always be in base currency in v1.3.3 dbv7
                  '' AS RECONCILED,
                  (SELECT cft1.pfx_symbol from CURRENCYFORMATS_v1 as cft1 where cft1.currencyid = (select inf.infovalue from infotable_v1 as inf where inf.infoname = 'BASECURRENCYID')) AS PFX_SYMBOL,
                  (SELECT cft1.sfx_symbol from CURRENCYFORMATS_v1 as cft1 where cft1.currencyid = (select inf.infovalue from infotable_v1 as inf where inf.infoname = 'BASECURRENCYID')) AS SFX_SYMBOL,
                  (SELECT cft1.DECIMAL_POINT from CURRENCYFORMATS_v1 as cft1 where cft1.currencyid = (select inf.infovalue from infotable_v1 as inf where inf.infoname = 'BASECURRENCYID')) AS DECIMAL_POINT,
                  (SELECT cft1.GROUP_SEPARATOR from CURRENCYFORMATS_v1 as cft1 where cft1.currencyid = (select inf.infovalue from infotable_v1 as inf where inf.infoname = 'BASECURRENCYID')) AS GROUP_SEPARATOR,
		ass.VALUECHANGERATE as PER_RATE,
		ass.VALUECHANGE as PER_TYPE
             FROM ASSETS_v1 AS ass
       )
       AS tdata
 ORDER BY sortorder,
          tdata.ACCOUNT ASC;
