--sql server --
--usp_TaiwanReport

CREATE PROCEDURE dbo.usp_taiwan_award_report (@mode varchar(255))
	AS BEGIN

DECLARE @personal_award_details TABLE
(
group_name nvarchar(20),
man_name nvarchar(30),
man_code int,
ins_no varchar(40),
receive_date smalldatetime,
adate smalldatetime,
fyb numeric,
ss_fyb numeric,
weighted_rate numeric,
pro_name nvarchar(100),
weighted_fyb numeric

)


insert into @personal_award_details
SELECT
	g. [Name] group_name,
	b.name man_name,
	a.man_code,
	a.ins_no,
	a.receive_date,
	a.adate,
	a.fyb,
	a.ss_fyb,
	weighted_rate,
	pro_name,
	weighted_fyb
FROM
	v_taiwain_2021 a
	LEFT JOIN man_data b ON a.man_code = b.code
	LEFT JOIN [Group] g ON b.BGCode = g.GCode
	
	
DECLARE @supervisor_award_details TABLE
(
group_name nvarchar(20),
district_man_name nvarchar(30),
district_man_code int,
man_name nvarchar(30),
man_code int,
fyb numeric,
ss_fyb numeric,
weighted_fyb numeric,
weighted_ss_fyb numeric,
acheived_man tinyint

)	

insert into @supervisor_award_details
SELECT
	g. [Name] group_name,
	b.district_man_name,
	b.district_man_code,
	b.man_name,
	b.man_code,
	sum(a.fyb) fyb,
	sum(a.ss_fyb) ss_fyb,
	sum(a.weighted_fyb) weighted_fyb,
	sum(a.weighted_ss_fyb) weighted_ss_fyb,
	CASE WHEN sum(a.weighted_fyb) / 1000000 >= 1 AND a.man_code != b.district_man_code THEN
		1
	ELSE
		0
END acheived_man
FROM
	v_taiwain_2021 a
	LEFT JOIN v_district_groups b ON a.man_code = b.man_code
	LEFT JOIN man_data c ON b.district_man_code = c.code
	LEFT JOIN [Group] g ON c.BGCode = g.GCode
WHERE
	g.name IS NOT NULL
GROUP BY
	g. [Name],
	b.man_name,
	b.man_code,
	b.district_man_name,
	b.district_man_code,
	a.man_code



if(@mode = 'personal_award_details') 
BEGIN
SELECT
	group_name,
	man_name,
	ins_no,
	receive_date,
	adate,
	Format(fyb, 'N0') fyb,
	Format(ss_fyb, 'N0') ss_fyb,
	weighted_rate,
	pro_name
FROM
	@personal_award_details
END


if(@mode = 'personal_award_sum') 
BEGIN
SELECT
	group_name,
	man_name,
	Format(sum(fyb), 'N0') fyb,
	Format(sum(weighted_fyb), 'N0') weighted_fyb,
	CONVERT(VARCHAR, cast(round(sum(weighted_fyb) / 1000000, 3) * 100 AS DECIMAL (14, 1))) + '%' feat_percentage,
	floor(sum(weighted_fyb) / 1000000) feat_tickets
FROM
	@personal_award_details
GROUP BY
	group_name,
	man_name,
	man_code
END



if(@mode = 'supervisor_award_details') 
BEGIN
SELECT
	group_name,
	district_man_name,
	man_name,
	Format(sum(fyb), 'N0') fyb,
	Format(sum(ss_fyb), 'N0') ss_fyb,
	Format(sum(weighted_fyb), 'N0') weighted_fyb,
	Format(sum(weighted_ss_fyb), 'N0') weighted_ss_fyb
FROM
	@supervisor_award_details
GROUP BY
	group_name,
	district_man_name,
	man_name
END


if(@mode = 'supervisor_award_sum') 
BEGIN
SELECT
	group_name,
	district_man_name,
	Format(sum(fyb), 'N0') fyb,
	Format(sum(weighted_fyb), 'N0') weighted_fyb,
	CONVERT(VARCHAR, cast(round(sum(weighted_fyb) / 5000000, 3) * 100 AS DECIMAL (14, 1))) + '%' feat_percentage,
	floor(sum(weighted_fyb) / 5000000) feat_tickets,
	Format(sum(acheived_man), 'N0') acheived_man,
	(sum(acheived_man) / 3) acheived_man_tickets,
	floor(sum(weighted_fyb) / 5000000) + (sum(acheived_man) / 3) all_tickets
FROM
	@supervisor_award_details group_member_detail
GROUP BY
	group_name,
	district_man_name,
	district_man_code
END	
		
END;