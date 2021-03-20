--sql server --
--query_SalesmanFeatMonthly

SELECT
    *
FROM (
    SELECT
        code,
        O1,
        O2,
        O3,
        PERIOD,
        FYB
    FROM (
        SELECT
            code,
            name,
            PERIOD,
            FYB
        FROM (
            SELECT
                MAN_Data.code,
                name
            FROM
                MAN_Data
            WHERE
                MAN_Data. [Role] = '88') Man
        LEFT JOIN (
            SELECT
                SS_Detail.Man_Code, SS_Detail. [Period], sum(SS_Detail.FYB) FYB
            FROM
                SS_Detail
            WHERE
                SS_Detail.CT = '1'
                AND SS_Detail.BCode IN ('499', '500', '5343')
            GROUP BY
                SS_Detail.Man_Code,
                SS_Detail. [Period]) s_FYB ON Man.code = s_FYB.Man_Code) T
    LEFT JOIN (
        SELECT
            D1.Man_Code,
            D2.O1,
            D2.O2,
            D2.O3
        FROM (
            SELECT
                Man_Code,
                max(MAN_Chg. [Date])
                Date
            FROM
                MAN_Chg
            GROUP BY
                Man_Code) D1
        LEFT JOIN (
            SELECT
                Man_Code,
                O1,
                O2,
                O3,
                Date
            FROM
                MAN_Chg) D2 ON D1.Man_Code = D2.Man_Code
            AND D1.Date = D2.Date) M ON T.code = M.Man_Code) TT PIVOT (SUM(TT.FYB)
        FOR TT. [Period] IN ([201001],
            [201002],
            [201003],
            [201004],
            [201005],
            [201006],
            [201007],
            [201008],
            [201009],
            [201010],
            [201011],
            [201012],
            [201101],
            [201102],
            [201103],
            [201104],
            [201105],
            [201106],
            [201107],
            [201108],
            [201109],
            [201110],
            [201111],
            [201112],
            [201201],
            [201202],
            [201203],
            [201204],
            [201205],
            [201206],
            [201207],
            [201208],
            [201209],
            [201210],
            [201211],
            [201212],
            [201301],
            [201302],
            [201303],
            [201304],
            [201305],
            [201306],
            [201307],
            [201308],
            [201309],
            [201310],
            [201311],
            [201312],
            [201401],
            [201402],
            [201403],
            [201404],
            [201405],
            [201406],
            [201407],
            [201408],
            [201409],
            [201410],
            [201411],
            [201412],
            [201501],
            [201502],
            [201503],
            [201504],
            [201505],
            [201506],
            [201507],
            [201508],
            [201509],
            [201510],
            [201511],
            [201512],
            [201601],
            [201602],
            [201603],
            [201604],
            [201605],
            [201606],
            [201607],
            [201608],
            [201609],
            [201610],
            [201611],
            [201612],
            [201701],
            [201702],
            [201703],
            [201704],
            [201705],
            [201706],
            [201707],
            [201708],
            [201709],
            [201710],
            [201711],
            [201712],
            [201801],
            [201802],
            [201803],
            [201804],
            [201805],
            [201806],
            [201807],
            [201808],
            [201809],
            [201810],
            [201811],
            [201812])) S
WHERE
    O1 IS not NULL
    and O2 IS not NULL
    and O3 IS not NULL
ORDER BY
    cod