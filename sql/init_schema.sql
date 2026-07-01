CREATE TABLE IF NOT EXISTS `user` (
    `id` BIGINT PRIMARY KEY AUTO_INCREMENT COMMENT 'Primary key',
    `username` VARCHAR(64) NOT NULL COMMENT 'Login username',
    `password_hash` VARCHAR(255) NOT NULL COMMENT 'Encrypted password hash',
    `nickname` VARCHAR(64) DEFAULT NULL COMMENT 'Display name',
    `email` VARCHAR(128) DEFAULT NULL COMMENT 'Email address',
    `phone` VARCHAR(32) DEFAULT NULL COMMENT 'Phone number',
    `status` VARCHAR(32) NOT NULL DEFAULT 'ENABLED' COMMENT 'User status',
    `token_version` INT NOT NULL DEFAULT 0 COMMENT 'Token version for logout and reset',
    `created_at` DATETIME NOT NULL DEFAULT CURRENT_TIMESTAMP COMMENT 'Creation time',
    `updated_at` DATETIME NOT NULL DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP COMMENT 'Update time',
    `deleted` TINYINT(1) NOT NULL DEFAULT 0 COMMENT 'Logical delete flag',
    UNIQUE KEY `uk_user_username` (`username`),
    UNIQUE KEY `uk_user_email` (`email`),
    UNIQUE KEY `uk_user_phone` (`phone`)
) COMMENT='System user';

CREATE TABLE IF NOT EXISTS `role` (
    `id` BIGINT PRIMARY KEY AUTO_INCREMENT COMMENT 'Primary key',
    `code` VARCHAR(64) NOT NULL COMMENT 'Role code',
    `name` VARCHAR(64) NOT NULL COMMENT 'Role name',
    `description` VARCHAR(255) DEFAULT NULL COMMENT 'Role description',
    `created_at` DATETIME NOT NULL DEFAULT CURRENT_TIMESTAMP COMMENT 'Creation time',
    `updated_at` DATETIME NOT NULL DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP COMMENT 'Update time',
    `deleted` TINYINT(1) NOT NULL DEFAULT 0 COMMENT 'Logical delete flag',
    UNIQUE KEY `uk_role_code` (`code`)
) COMMENT='Role definition';

CREATE TABLE IF NOT EXISTS `permission` (
    `id` BIGINT PRIMARY KEY AUTO_INCREMENT COMMENT 'Primary key',
    `code` VARCHAR(64) NOT NULL COMMENT 'Permission code',
    `name` VARCHAR(64) NOT NULL COMMENT 'Permission name',
    `description` VARCHAR(255) DEFAULT NULL COMMENT 'Permission description',
    `permission_type` VARCHAR(32) DEFAULT NULL COMMENT 'Permission type',
    `api_path` VARCHAR(255) DEFAULT NULL COMMENT 'Protected API path',
    `http_method` VARCHAR(16) DEFAULT NULL COMMENT 'Protected HTTP method',
    `created_at` DATETIME NOT NULL DEFAULT CURRENT_TIMESTAMP COMMENT 'Creation time',
    `updated_at` DATETIME NOT NULL DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP COMMENT 'Update time',
    `deleted` TINYINT(1) NOT NULL DEFAULT 0 COMMENT 'Logical delete flag',
    UNIQUE KEY `uk_permission_code` (`code`)
) COMMENT='Permission definition';

CREATE TABLE IF NOT EXISTS `user_role` (
    `id` BIGINT PRIMARY KEY AUTO_INCREMENT COMMENT 'Primary key',
    `user_id` BIGINT NOT NULL COMMENT 'User id',
    `role_id` BIGINT NOT NULL COMMENT 'Role id',
    `created_at` DATETIME NOT NULL DEFAULT CURRENT_TIMESTAMP COMMENT 'Creation time',
    `updated_at` DATETIME NOT NULL DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP COMMENT 'Update time',
    `deleted` TINYINT(1) NOT NULL DEFAULT 0 COMMENT 'Logical delete flag',
    UNIQUE KEY `uk_user_role_pair` (`user_id`, `role_id`)
) COMMENT='User role relation';

CREATE TABLE IF NOT EXISTS `role_permission` (
    `id` BIGINT PRIMARY KEY AUTO_INCREMENT COMMENT 'Primary key',
    `role_id` BIGINT NOT NULL COMMENT 'Role id',
    `permission_id` BIGINT NOT NULL COMMENT 'Permission id',
    `created_at` DATETIME NOT NULL DEFAULT CURRENT_TIMESTAMP COMMENT 'Creation time',
    `updated_at` DATETIME NOT NULL DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP COMMENT 'Update time',
    `deleted` TINYINT(1) NOT NULL DEFAULT 0 COMMENT 'Logical delete flag',
    UNIQUE KEY `uk_role_permission_pair` (`role_id`, `permission_id`)
) COMMENT='Role permission relation';

CREATE TABLE IF NOT EXISTS `course` (
    `id` BIGINT PRIMARY KEY AUTO_INCREMENT COMMENT 'Primary key',
    `title` VARCHAR(128) NOT NULL COMMENT 'Course title',
    `summary` VARCHAR(500) DEFAULT NULL COMMENT 'Course summary',
    `cover_url` VARCHAR(255) DEFAULT NULL COMMENT 'Cover url',
    `category` VARCHAR(64) DEFAULT NULL COMMENT 'Course category',
    `difficulty` VARCHAR(32) DEFAULT NULL COMMENT 'Difficulty level',
    `teacher_id` BIGINT NOT NULL COMMENT 'Teacher id',
    `teacher_name` VARCHAR(64) NOT NULL COMMENT 'Teacher display name',
    `student_count` BIGINT NOT NULL DEFAULT 0 COMMENT 'Enrollment count',
    `status` VARCHAR(32) NOT NULL DEFAULT 'DRAFT' COMMENT 'Course status',
    `review_comment` VARCHAR(500) DEFAULT NULL COMMENT 'Review comment',
    `created_at` DATETIME NOT NULL DEFAULT CURRENT_TIMESTAMP COMMENT 'Creation time',
    `updated_at` DATETIME NOT NULL DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP COMMENT 'Update time',
    `deleted` TINYINT(1) NOT NULL DEFAULT 0 COMMENT 'Logical delete flag'
) COMMENT='Course basic information';

CREATE TABLE IF NOT EXISTS `course_chapter` (
    `id` BIGINT PRIMARY KEY AUTO_INCREMENT COMMENT 'Primary key',
    `course_id` BIGINT NOT NULL COMMENT 'Course id',
    `parent_id` BIGINT DEFAULT NULL COMMENT 'Parent chapter id',
    `title` VARCHAR(128) NOT NULL COMMENT 'Chapter title',
    `sort_order` INT NOT NULL DEFAULT 0 COMMENT 'Sort order',
    `created_at` DATETIME NOT NULL DEFAULT CURRENT_TIMESTAMP COMMENT 'Creation time',
    `updated_at` DATETIME NOT NULL DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP COMMENT 'Update time',
    `deleted` TINYINT(1) NOT NULL DEFAULT 0 COMMENT 'Logical delete flag'
) COMMENT='Course chapter';

CREATE TABLE IF NOT EXISTS `course_resource` (
    `id` BIGINT PRIMARY KEY AUTO_INCREMENT COMMENT 'Primary key',
    `course_id` BIGINT NOT NULL COMMENT 'Course id',
    `chapter_id` BIGINT NOT NULL COMMENT 'Chapter id',
    `title` VARCHAR(128) NOT NULL COMMENT 'Resource title',
    `resource_type` VARCHAR(32) NOT NULL COMMENT 'Resource type',
    `access_type` VARCHAR(32) NOT NULL COMMENT 'Access type',
    `original_file_name` VARCHAR(255) NOT NULL COMMENT 'Original file name',
    `storage_path` VARCHAR(255) NOT NULL COMMENT 'Stored file path',
    `file_url` VARCHAR(255) NOT NULL COMMENT 'Resolved access url',
    `mime_type` VARCHAR(128) DEFAULT NULL COMMENT 'Mime type',
    `file_size` BIGINT NOT NULL COMMENT 'File size in bytes',
    `duration_seconds` BIGINT DEFAULT NULL COMMENT 'Duration in seconds',
    `transcoding_status` VARCHAR(32) NOT NULL DEFAULT 'NOT_REQUIRED' COMMENT 'Transcoding status',
    `cover_url` VARCHAR(255) DEFAULT NULL COMMENT 'Resource cover url',
    `created_at` DATETIME NOT NULL DEFAULT CURRENT_TIMESTAMP COMMENT 'Creation time',
    `updated_at` DATETIME NOT NULL DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP COMMENT 'Update time',
    `deleted` TINYINT(1) NOT NULL DEFAULT 0 COMMENT 'Logical delete flag'
) COMMENT='Course resource metadata';

CREATE TABLE IF NOT EXISTS `course_enrollment` (
    `id` BIGINT PRIMARY KEY AUTO_INCREMENT COMMENT 'Primary key',
    `course_id` BIGINT NOT NULL COMMENT 'Course id',
    `user_id` BIGINT NOT NULL COMMENT 'User id',
    `created_at` DATETIME NOT NULL DEFAULT CURRENT_TIMESTAMP COMMENT 'Creation time',
    `updated_at` DATETIME NOT NULL DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP COMMENT 'Update time',
    `deleted` TINYINT(1) NOT NULL DEFAULT 0 COMMENT 'Logical delete flag',
    UNIQUE KEY `uk_course_enrollment_pair` (`course_id`, `user_id`)
) COMMENT='Course enrollment';

CREATE TABLE IF NOT EXISTS `video_progress` (
    `id` BIGINT PRIMARY KEY AUTO_INCREMENT COMMENT 'Primary key',
    `user_id` BIGINT NOT NULL COMMENT 'User id',
    `course_id` BIGINT NOT NULL COMMENT 'Course id',
    `chapter_id` BIGINT NOT NULL COMMENT 'Chapter id',
    `resource_id` BIGINT NOT NULL COMMENT 'Video resource id',
    `current_position` BIGINT NOT NULL DEFAULT 0 COMMENT 'Max trusted current position in seconds',
    `duration_seconds` BIGINT NOT NULL COMMENT 'Canonical video duration in seconds',
    `effective_study_seconds` BIGINT NOT NULL DEFAULT 0 COMMENT 'Trusted effective study seconds used for completion',
    `progress_percent` DOUBLE NOT NULL DEFAULT 0 COMMENT 'Progress percentage based on trusted position',
    `completed` TINYINT(1) NOT NULL DEFAULT 0 COMMENT 'Whether the video completion threshold is reached',
    `last_playback_rate` DOUBLE NOT NULL DEFAULT 1 COMMENT 'Last accepted playback rate',
    `last_client_timestamp` BIGINT DEFAULT NULL COMMENT 'Last client timestamp',
    `last_report_at` DATETIME NOT NULL DEFAULT CURRENT_TIMESTAMP COMMENT 'Last report time on server',
    `last_study_at` DATETIME NOT NULL DEFAULT CURRENT_TIMESTAMP COMMENT 'Last trusted study time',
    `created_at` DATETIME NOT NULL DEFAULT CURRENT_TIMESTAMP COMMENT 'Creation time',
    `updated_at` DATETIME NOT NULL DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP COMMENT 'Update time',
    `deleted` TINYINT(1) NOT NULL DEFAULT 0 COMMENT 'Logical delete flag',
    UNIQUE KEY `uk_video_progress_user_resource` (`user_id`, `resource_id`)
) COMMENT='Video learning progress';

CREATE TABLE IF NOT EXISTS `study_record` (
    `id` BIGINT PRIMARY KEY AUTO_INCREMENT COMMENT 'Primary key',
    `user_id` BIGINT NOT NULL COMMENT 'User id',
    `course_id` BIGINT NOT NULL COMMENT 'Course id',
    `chapter_id` BIGINT NOT NULL COMMENT 'Chapter id',
    `resource_id` BIGINT NOT NULL COMMENT 'Video resource id',
    `reported_position` BIGINT NOT NULL COMMENT 'Frontend reported current position',
    `trusted_position` BIGINT NOT NULL COMMENT 'Server accepted trusted position',
    `duration_seconds` BIGINT NOT NULL COMMENT 'Canonical video duration',
    `trusted_increment_seconds` BIGINT NOT NULL DEFAULT 0 COMMENT 'Trusted increment for this report',
    `report_interval_seconds` BIGINT NOT NULL DEFAULT 0 COMMENT 'Seconds since previous report',
    `playback_rate` DOUBLE NOT NULL DEFAULT 1 COMMENT 'Reported playback rate',
    `client_timestamp` BIGINT DEFAULT NULL COMMENT 'Client timestamp',
    `suspicious` TINYINT(1) NOT NULL DEFAULT 0 COMMENT 'Whether the report is suspicious',
    `suspicious_reason` VARCHAR(255) DEFAULT NULL COMMENT 'Reason for suspicious report',
    `created_at` DATETIME NOT NULL DEFAULT CURRENT_TIMESTAMP COMMENT 'Creation time',
    `updated_at` DATETIME NOT NULL DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP COMMENT 'Update time',
    `deleted` TINYINT(1) NOT NULL DEFAULT 0 COMMENT 'Logical delete flag'
) COMMENT='Study report history';

CREATE TABLE IF NOT EXISTS `learning_daily_stat` (
    `id` BIGINT PRIMARY KEY AUTO_INCREMENT COMMENT 'Primary key',
    `user_id` BIGINT NOT NULL COMMENT 'User id',
    `stat_date` DATE NOT NULL COMMENT 'Statistic date',
    `total_study_seconds` BIGINT NOT NULL DEFAULT 0 COMMENT 'Trusted study seconds accumulated in the day',
    `last_study_at` DATETIME NOT NULL DEFAULT CURRENT_TIMESTAMP COMMENT 'Latest study time in the day',
    `created_at` DATETIME NOT NULL DEFAULT CURRENT_TIMESTAMP COMMENT 'Creation time',
    `updated_at` DATETIME NOT NULL DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP COMMENT 'Update time',
    `deleted` TINYINT(1) NOT NULL DEFAULT 0 COMMENT 'Logical delete flag',
    UNIQUE KEY `uk_learning_daily_stat_user_date` (`user_id`, `stat_date`)
) COMMENT='Daily learning statistics';

CREATE TABLE IF NOT EXISTS `ai_call_log` (
    `id` BIGINT PRIMARY KEY AUTO_INCREMENT COMMENT 'Primary key',
    `user_id` BIGINT DEFAULT NULL COMMENT 'Caller user id',
    `input_type` VARCHAR(32) NOT NULL COMMENT 'Input type',
    `request_summary` VARCHAR(500) DEFAULT NULL COMMENT 'Request summary',
    `response_summary` VARCHAR(500) DEFAULT NULL COMMENT 'Response summary',
    `created_at` DATETIME NOT NULL DEFAULT CURRENT_TIMESTAMP COMMENT 'Creation time',
    `updated_at` DATETIME NOT NULL DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP COMMENT 'Update time',
    `deleted` TINYINT(1) NOT NULL DEFAULT 0 COMMENT 'Logical delete flag'
) COMMENT='AI call log';
