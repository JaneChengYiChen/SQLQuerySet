--sql server --
--usp_ThrowBackData

CREATE PROCEDURE dbo.ThrowBackData (@Man_Code int, @IDate smalldatetime)
	AS BEGIN

declare @tempA table
(
 Rec_No int,
 Man_Code int,
 GDCode int,
 Tcode int,
 CMCode int
)

declare @tempA_Mentor table
(
 Rec_No int,
 man_code int,
 Tcode int,
 GDCode int,
 GDTcode int
)

declare @tempA_Recommender table
(
 Rec_No int,
 man_code int,
 Tcode int,
 GDCode int,
 GDTcode int
)


declare @tempB table
(
 Man_Code int,
 GDCode int,
 LV int
)


declare @original table
(
 man_code int,
 tcode int,
 man_name nvarchar(30),
 man_rate int,
 gd_code int,
 gd_tcode int,
 gd_name nvarchar(30),
 gd_rate int,
 LV int
)


insert into @tempA
Select
 m.Rec_No, m.Man_Code, GDCode, Tcode, CMCode
FROM
 pks_MAN_Chg m
 INNER JOIN (
  SELECT
   max(Rec_No) Rec_No,
   Man_Code
  FROM
   pks_MAN_Chg
  WHERE
   Date <= @IDate
  GROUP BY
   Man_Code
   ) latest_data ON m.Man_Code = latest_data.Man_Code
 AND m.Rec_No = latest_data.Rec_No;


insert INTO @tempA_Mentor
SELECT
 a1.Rec_No,
 a1.man_code,
 a1.Tcode,
 a2.man_code GDCode,
 a2.Tcode GDTcode
FROM
 @tempA a1 left join @tempA a2 on a1.GDCode = a2.man_code;

insert INTO @tempA_Recommender
SELECT
 a1.Rec_No,
 a1.man_code,
 a1.Tcode,
 a2.man_code GDCode,
 a2.Tcode GDTcode
FROM
 @tempA a1 left join @tempA a2 on a1.CMCode = a2.man_code;


with Dataframe as (
select 
a.man_code
, a.Tcode man_tcode
, a.GDCode gd_code
, a.GDTcode gd_tcode
, 1 DEPTH
from @tempA_Mentor a

UNION ALL
 SELECT
 b.man_code
, b.Tcode man_tcode
, b.GDCode
, b.GDTcode gd_tcode
, c.DEPTH + 1 DEPTH
FROM
@tempA_Mentor b
INNER JOIN DataFrame c ON b.man_code = c.gd_code
)

select a.gd_code 
, a.gd_tcode 
, a.man_code 
, a.man_tcode 
, a.DEPTH 
, b.CMcode 
, b.tcode 
 from Dataframe a
 left join @tempA b on a.man_code = b.man_code
 left join @tempA c on b.CMcode = c.man_code
 where a.gd_code = @Man_Code;

END;
