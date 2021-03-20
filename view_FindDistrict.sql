--sql server --
--view_FindDistrict


CREATE view v_district_groups as
WITH man_status AS (
	SELECT
		md.code man_code,
		md.name man_name,
		t.TCode man_tcode,
		t.Title man_title,
		ty.TNo man_tno,
		ty.Item title,
		CASE WHEN ty.TNo = 17 -- sales one 
		THEN
		(
			CASE WHEN t.TLevel >= 50 THEN
				1
			ELSE
				0
			END)
		WHEN ty.TNo = 325 -- sales one better
		THEN
		(
			CASE WHEN t.TLevel >= 75 THEN
				1
			ELSE
				0
			END)
		WHEN ty.TNo = 324 -- sales two
		THEN
		(
			CASE WHEN t.TLevel >= 82 THEN
				1
			ELSE
				0
			END)
		END is_district_boss
	FROM
		MAN_Data md
	LEFT JOIN Title t ON md.TCode = t.TCode
	LEFT JOIN Title_Type ty ON t. [Type] = ty.TNo
	where md.[Role] in (88,1520)
)
SELECT
	*
FROM (
	SELECT
		m.man_code,
		m.man_name,
		m.man_title,
		m.man_code district_man_code,
		m.man_name district_man_name,
		m.man_title district_man_title
	FROM
		man_status m
	where m.is_district_boss = 1) man_is_district_boss
UNION ALL (
	SELECT
		man_code,
		man_name,
		man_title,
		gd_code,
		gd_name,
		gd_title
	FROM (
		SELECT
			m.man_code,
			s.man_name,
			s.man_title,
			m.LV,
			m.GDCode gd_code,
			s_gd.man_name gd_name,
			s_gd.man_title gd_title,
			ROW_NUMBER() OVER (PARTITION BY m.man_code ORDER BY LV ASC) AS which_system
		FROM
			ManTree m
		LEFT JOIN man_status s ON m.Man_Code = s.man_code
		LEFT JOIN man_status s_gd ON m.GDCode = s_gd.man_code
	WHERE
		SType = 2
		AND s.man_tno != 324
		AND s_gd.is_district_boss = 1
		AND s.is_district_boss = 0
	UNION ALL
	SELECT
		m.man_code,
		s.man_name,
		s.man_title,
		m.LV,
		m.GDCode gd_code,
		s_gd.man_name gd_name,
		s_gd.man_name gd_title,
		ROW_NUMBER() OVER (PARTITION BY m.man_code ORDER BY LV ASC) AS which_system
	FROM
		ManTree m
	LEFT JOIN man_status s ON m.Man_Code = s.man_code
	LEFT JOIN man_status s_gd ON m.GDCode = s_gd.man_code
WHERE
	SType = 1
	AND s.man_tno = 324
	AND s_gd.is_district_boss = 1
	AND s.is_district_boss = 0) man_not_district_boss
WHERE
	which_system = 1)