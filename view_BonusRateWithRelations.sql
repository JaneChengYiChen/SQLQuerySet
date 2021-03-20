--sql server --
--view_BonusRateWithRelations

CREATE VIEW v_LS_mentoring_relation_ratios AS 
        WITH mentoring_line AS (
            SELECT
                man_code,
                man_name,
                man_tcode,
                gd_code,
                gd_name,
                gd_tcode,
                LV,
                CASE WHEN LV = 1 THEN
                    POWER(cast(0.5 AS float),
                        init_split)
                ELSE
                    POWER(cast(0.5 AS float),
                        gd_split_sum + init_split - gd_split)
                END square,
                N'單純輔導線' line_name,
                NULL binding_man_code,
                NULL binding_man_tcode,
                0 DEPTH
            FROM (
                SELECT
                    *,
                    SUM(gd_split) OVER (PARTITION BY man_code ORDER BY LV) gd_split_sum
                FROM (
                SELECT
                    mt.Man_Code man_code,
                    md_man. [Name] man_name,
                    md_man.TCode man_tcode,
                    mt.GDCode gd_code,
                    md.name gd_name,
                    md.TCode gd_tcode,
                    mt.LV,
                    CASE WHEN tp.man_code IS NOT NULL THEN
                        1
                    ELSE
                        0
                    END init_split,
                    CASE WHEN tp_gd.man_code IS NOT NULL THEN
                        1
                    ELSE
                        0
                    END gd_split
                FROM
                    pks_ManTree mt
                LEFT JOIN v_LS_turning_points tp ON mt.Man_Code = tp.man_code
                LEFT JOIN v_LS_turning_points tp_gd ON mt.GDCode = tp_gd.man_code
                LEFT JOIN pks_MAN_Data md_man ON mt.Man_Code = md_man.Code
                LEFT JOIN pks_MAN_Data md ON mt.GDCode = md.Code
            WHERE
                mt.SType = 1 -- 輔導線
        ) mentoring_line) mentoring_line_rate
        ),
        cross_line AS (
        SELECT
            man_code,
            man_name,
            man_tcode,
            gd_code,
            gd_name,
            gd_tcode,
            LV,
            CASE WHEN LV = 1 THEN
            ( CASE WHEN is_recommended = 0 THEN
                POWER(cast(0.5 AS float),
            init_split + man_depth + DEPTH - 1)
            ELSE
                POWER(cast(0.5 AS float),
            ( CASE WHEN is_recommended = 1
                AND man_depth > 1 THEN
                [DEPTH] + man_depth - 1
            ELSE
                [DEPTH]
            END))
            END)
        ELSE
            ( CASE WHEN is_recommended = 0 THEN
                POWER(cast(0.5 AS float),
            [DEPTH] + man_depth + gd_split_sum - gd_split - is_not_turning_points)
            ELSE
                POWER(cast(0.5 AS float),
            gd_split_sum - gd_split + ( CASE WHEN is_recommended = 1
                AND man_depth > 1 THEN
                [DEPTH] + man_depth - 1
            ELSE
                [DEPTH]
            END))
            END)
            END square,
            N'跨區/育成綜合輔導線' line_name,
            binding_man_code,
            binding_man_tcode,
            DEPTH
        FROM (
        SELECT
            *,
            SUM(gd_split) OVER (PARTITION BY man_code,
                binding_man_code,
                [DEPTH] ORDER BY LV) gd_split_sum
        FROM (
        SELECT
            a.*,
            CASE WHEN tp.man_code IS NOT NULL THEN
                1
            ELSE
                0
            END init_split,
            CASE WHEN tp_gd.man_code IS NOT NULL THEN
                1
            ELSE
                0
            END gd_split
        FROM
            v_LS_mentoring_cross_relations a
            LEFT JOIN v_LS_turning_points tp ON a.man_code = tp.man_code
            LEFT JOIN v_LS_turning_points tp_gd ON a.gd_code = tp_gd.man_code) cross_line) cross_line_rate
        ),
        unionData AS (
        SELECT
            man_code
            , man_name
            , man_tcode
            , vmr.fy_rate man_fy_rate 
            , vmr.sy_rate man_sy_rate
            , vmr.continued_rate man_continued_rate
            , vmr.year_end_rate man_year_end_rate
            , vmr.service_rate man_service_rate
            , gd_name
            , gd_code
            , gd_tcode
            , vmr_gd.fy_rate gd_fy_rate 
            , vmr_gd.sy_rate gd_sy_rate
            , vmr_gd.continued_rate gd_continued_rate
            , vmr_gd.year_end_rate gd_year_end_rate
            , vmr_gd.service_rate gd_service_rate
            , LV
            , square
            , line_name
            , isnull(binding_man_code, 0 ) binding_man_code
            , isnull(binding_man_tcode, 0 ) binding_man_tcode
            , vmr_binding.fy_rate binding_fy_rate 
            , vmr_binding.sy_rate binding_sy_rate
            , vmr_binding.continued_rate binding_continued_rate
            , vmr_binding.year_end_rate binding_year_end_rate
            , vmr_binding.service_rate binding_service_rate
            , DEPTH
        FROM (
        SELECT
            *
        FROM
            mentoring_line
        UNION ALL
        SELECT
            *
        FROM
            cross_line) a
        left join v_commission_rates vmr on a.man_tcode = vmr.tcode 
        left join v_commission_rates vmr_gd on a.gd_tcode = vmr_gd.tcode 
        left join v_commission_rates vmr_binding on a.binding_man_tcode = vmr_binding.tcode 
        )
        
        SELECT
            a.man_code
            , a.man_name
            , a.man_tcode
            , a.gd_code
            , a.gd_name
            , a.gd_tcode
            , a.binding_man_code
            , a.binding_man_tcode
            , a.LV
            , a.square
            , a.line_name
            , a.[DEPTH]
            , -- FIRST YEAR RATE
            CASE WHEN a.binding_man_code = 0 
            THEN
            (
                CASE WHEN a.LV = 1 THEN
                    (a.gd_fy_rate - a.man_fy_rate) / 100
                ELSE
                    (a.gd_fy_rate - b.gd_fy_rate) /100
                END)
            ELSE
            (
                CASE WHEN a.LV = 1 THEN
                    (a.gd_fy_rate - a.binding_fy_rate) /100
                ELSE
                    (a.gd_fy_rate - b.gd_fy_rate) /100
                END)
            END gd_diff_fy_rate
            , -- SECOND YEAR RATE
            CASE WHEN a.binding_man_code = 0 
            THEN
            (
                CASE WHEN a.LV = 1 THEN
                    (a.gd_sy_rate - a.man_sy_rate) / 100
                ELSE
                    (a.gd_sy_rate - b.gd_sy_rate) /100
                END)
            ELSE
            (
                CASE WHEN a.LV = 1 THEN
                    (a.gd_sy_rate - a.binding_sy_rate) /100
                ELSE
                    (a.gd_sy_rate - b.gd_sy_rate) /100
                END)
            END gd_diff_sy_rate
            , -- CONTINUED RATE
            CASE WHEN a.binding_man_code = 0 
            THEN
            (
                CASE WHEN a.LV = 1 THEN
                    (a.gd_continued_rate- a.man_continued_rate) / 100
                ELSE
                    (a.gd_continued_rate - b.gd_continued_rate) /100
                END)
            ELSE
            (
                CASE WHEN a.LV = 1 THEN
                    (a.gd_continued_rate - a.binding_continued_rate) /100
                ELSE
                    (a.gd_continued_rate - b.gd_continued_rate) /100
                END)
            END gd_diff_continued_rate
            , -- YEAR END BONUS
            CASE WHEN a.binding_man_code = 0 
            THEN
            (
                CASE WHEN a.LV = 1 THEN
                    (a.gd_year_end_rate- a.man_year_end_rate) / 100
                ELSE
                    (a.gd_year_end_rate - b.gd_year_end_rate) /100
                END)
            ELSE
            (
                CASE WHEN a.LV = 1 THEN
                    (a.gd_year_end_rate - a.binding_year_end_rate) /100
                ELSE
                    (a.gd_year_end_rate - b.gd_year_end_rate) /100
                END)
            END gd_diff_year_end_rate
            , -- service_rate
            CASE WHEN a.binding_man_code = 0 
            THEN
            (
                CASE WHEN a.LV = 1 THEN
                    (a.gd_service_rate- a.man_service_rate) / 100
                ELSE
                    (a.gd_service_rate - b.gd_service_rate) /100
                END)
            ELSE
            (
                CASE WHEN a.LV = 1 THEN
                    (a.gd_service_rate - a.binding_service_rate) /100
                ELSE
                    (a.gd_service_rate - b.gd_service_rate) /100
                END)
            END gd_diff_service_rate
            
        FROM
            unionData a
            left join unionData b on a.man_code = b.man_code 
            and a.[DEPTH] = b.DEPTH 
            and a.binding_man_code = b.binding_man_code
            and a.LV = b.LV+1 ;