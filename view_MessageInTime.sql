--mysql--
--view_MessageInTime

SELECT
	line_schedule_lists.line_schedule_id AS id,
	line_schedule_lists.line_user_id AS line_user_id,
	line_schedule_lists.text AS text,
	line_schedule_lists.img_name AS img_name,
	line_schedule_lists.imagemap AS imagemap,
	line_schedule_lists.is_feedback AS is_feedback,
	line_schedule_lists.feedback_module_type AS feedback_module_type,
	line_schedule_lists.total_receivers AS total_receivers,
	line_schedule_lists.schedule_time AS schedule_time
FROM
	line_schedule_lists
WHERE ((line_schedule_lists.is_deleted = 0)
	and(timediff(now(), line_schedule_lists.schedule_time) <= 00/20/00)
	and(abs((unix_timestamp(now()) - unix_timestamp(line_schedule_lists.schedule_time))) <= 1200)
	and(line_schedule_lists.is_sent = 0));