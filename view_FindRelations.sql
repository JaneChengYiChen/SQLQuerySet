--sql server --
--view_FindRelations

CREATE VIEW v_LS_recommender_mentorings AS 
        WITH relations_frame AS (
            SELECT
                vp.man_code,
                vp.man_name,
                vp.man_tcode,
                vp.gd_code,
                vp.gd_name,
                vp.gd_tcode,
                1 LV
            FROM
                v_LS_turning_points vp
            UNION ALL
            SELECT
                vp.man_code,
                vp.man_name,
                vp.man_tcode,
                mt.GDCode gd_code,
                md. [Name] gd_name,
                md.TCode gd_tcode,
                mt.LV + 1
            FROM
                v_LS_turning_points vp
            LEFT JOIN (
                SELECT
                    GDCode,
                    LV,
                    Man_Code
                FROM
                    pks_ManTree
                WHERE
                    SType = 1) mt ON vp.gd_code = mt.Man_Code
            LEFT JOIN pks_MAN_Data md ON mt.GDCode = md.Code
        WHERE
            mt.GDCode IS NOT NULL
        )
        
        SELECT
            a.*, 
            case when  vp.man_code is null then 0 else 
            ROW_NUMBER() OVER(PARTITION BY a.man_code, (case when vp.man_code is not null then 1 else 0 end) ORDER BY vp.man_code, LV ASC)
            end row
        FROM
            relations_frame a
            left join v_LS_turning_points vp on vp.man_code = a.gd_code