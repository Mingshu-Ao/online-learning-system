#!/usr/bin/env bash
set -euo pipefail

ROOT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
ENV_FILE="${ROOT_DIR}/deployment/server.env"

if [[ ! -f "${ENV_FILE}" ]]; then
  echo "Missing ${ENV_FILE}. Copy deployment/server.env.example first." >&2
  exit 1
fi

set -a
source "${ENV_FILE}"
set +a

BACKEND_BASE_URL="${SEED_BACKEND_BASE_URL:-http://127.0.0.1:${SERVER_PORT:-8080}}"
MYSQL_ARGS=(
  -h127.0.0.1
  -P"${MYSQL_PORT:-3306}"
  -u"${MYSQL_USER}"
  -p"${MYSQL_PASSWORD}"
  -D"${MYSQL_DATABASE}"
  --default-character-set=utf8mb4
)

require_command() {
  if ! command -v "$1" >/dev/null 2>&1; then
    echo "Required command not found: $1" >&2
    exit 1
  fi
}

mysql_exec() {
  mysql "${MYSQL_ARGS[@]}" "$@"
}

mysql_value() {
  mysql_exec -N -B -e "$1"
}

wait_for_backend() {
  local url="${BACKEND_BASE_URL}/api/common/ping"
  local i
  for i in $(seq 1 20); do
    if curl -fsS --connect-timeout 1 --max-time 2 "${url}" >/dev/null 2>&1; then
      return 0
    fi
    sleep 1
  done
  echo "Backend is not ready at ${url}. Start the local stack first." >&2
  exit 1
}

ensure_user() {
  local username="$1"
  local password="$2"
  local nickname="$3"
  local email="$4"
  local phone="$5"
  local exists

  exists="$(mysql_value "SELECT COUNT(*) FROM user WHERE username = '${username}' AND deleted = 0;")"
  if [[ "${exists}" != "0" ]]; then
    echo "User already exists: ${username}"
    return 0
  fi

  local response_file
  response_file="$(mktemp)"
  local http_code
  http_code="$(curl -sS -o "${response_file}" -w '%{http_code}' \
    -X POST "${BACKEND_BASE_URL}/api/auth/register" \
    -H 'Content-Type: application/json' \
    -d "{\"username\":\"${username}\",\"password\":\"${password}\",\"nickname\":\"${nickname}\",\"email\":\"${email}\",\"phone\":\"${phone}\"}")"

  if [[ "${http_code}" != "200" ]]; then
    echo "Failed to create user ${username}, HTTP ${http_code}:" >&2
    cat "${response_file}" >&2
    rm -f "${response_file}"
    exit 1
  fi

  rm -f "${response_file}"
  echo "Created user: ${username}"
}

set_exact_roles() {
  local username="$1"
  shift
  local role_codes=("$@")
  local joined=""
  local code

  for code in "${role_codes[@]}"; do
    if [[ -n "${joined}" ]]; then
      joined+=","
    fi
    joined+="'${code}'"
  done

  mysql_exec <<SQL
SET @user_id := (SELECT id FROM user WHERE username = '${username}' AND deleted = 0 LIMIT 1);
DELETE FROM user_role WHERE user_id = @user_id;
INSERT INTO user_role (user_id, role_id, created_at, updated_at, deleted)
SELECT @user_id, r.id, NOW(), NOW(), 0
FROM role r
WHERE @user_id IS NOT NULL
  AND r.code IN (${joined})
  AND r.deleted = 0;
SQL
  echo "Assigned roles to ${username}: ${role_codes[*]}"
}

seed_core_data() {
  mysql_exec <<'SQL'
SET NAMES utf8mb4;
START TRANSACTION;

SET @student1_id := (SELECT id FROM user WHERE username = 'student001' AND deleted = 0 LIMIT 1);
SET @student2_id := (SELECT id FROM user WHERE username = 'student002' AND deleted = 0 LIMIT 1);
SET @student3_id := (SELECT id FROM user WHERE username = 'student003' AND deleted = 0 LIMIT 1);
SET @teacher1_id := (SELECT id FROM user WHERE username = 'teacher001' AND deleted = 0 LIMIT 1);
SET @teacher2_id := (SELECT id FROM user WHERE username = 'teacher002' AND deleted = 0 LIMIT 1);
SET @admin1_id := (SELECT id FROM user WHERE username = 'admin001' AND deleted = 0 LIMIT 1);

INSERT INTO course (title, summary, cover_url, category, difficulty, teacher_id, teacher_name, student_count, status, review_comment, created_at, updated_at, deleted)
SELECT 'Java 程序设计基础', '从开发环境、基础语法到面向对象，一套适合新手上手的 Java 课程。', 'https://placehold.co/1200x675/png?text=Java+Programming', '编程开发', '初级', @teacher1_id, '王老师', 0, 'PUBLISHED', '演示数据：已发布课程', NOW(), NOW(), 0
FROM DUAL
WHERE @teacher1_id IS NOT NULL
  AND NOT EXISTS (SELECT 1 FROM course WHERE title = 'Java 程序设计基础' AND teacher_id = @teacher1_id AND deleted = 0);

INSERT INTO course (title, summary, cover_url, category, difficulty, teacher_id, teacher_name, student_count, status, review_comment, created_at, updated_at, deleted)
SELECT '数据结构与算法入门', '围绕数组、链表、栈、队列与复杂度分析建立算法思维。', 'https://placehold.co/1200x675/png?text=Data+Structure', '计算机基础', '中级', @teacher1_id, '王老师', 0, 'PUBLISHED', '演示数据：已发布课程', NOW(), NOW(), 0
FROM DUAL
WHERE @teacher1_id IS NOT NULL
  AND NOT EXISTS (SELECT 1 FROM course WHERE title = '数据结构与算法入门' AND teacher_id = @teacher1_id AND deleted = 0);

INSERT INTO course (title, summary, cover_url, category, difficulty, teacher_id, teacher_name, student_count, status, review_comment, created_at, updated_at, deleted)
SELECT '机器学习实践导论', '用监督学习案例带你理解建模、训练与评估的基本流程。', 'https://placehold.co/1200x675/png?text=Machine+Learning', '人工智能', '中级', @teacher2_id, '李老师', 0, 'PUBLISHED', '演示数据：已发布课程', NOW(), NOW(), 0
FROM DUAL
WHERE @teacher2_id IS NOT NULL
  AND NOT EXISTS (SELECT 1 FROM course WHERE title = '机器学习实践导论' AND teacher_id = @teacher2_id AND deleted = 0);

INSERT INTO course (title, summary, cover_url, category, difficulty, teacher_id, teacher_name, student_count, status, review_comment, created_at, updated_at, deleted)
SELECT 'Spring Boot 项目实战', '面向教师与管理员演示的待审核课程。', 'https://placehold.co/1200x675/png?text=Spring+Boot', '工程实践', '中级', @teacher2_id, '李老师', 0, 'PENDING', '演示数据：待审核课程', NOW(), NOW(), 0
FROM DUAL
WHERE @teacher2_id IS NOT NULL
  AND NOT EXISTS (SELECT 1 FROM course WHERE title = 'Spring Boot 项目实战' AND teacher_id = @teacher2_id AND deleted = 0);

SET @course_java := (SELECT id FROM course WHERE title = 'Java 程序设计基础' AND teacher_id = @teacher1_id AND deleted = 0 LIMIT 1);
SET @course_algo := (SELECT id FROM course WHERE title = '数据结构与算法入门' AND teacher_id = @teacher1_id AND deleted = 0 LIMIT 1);
SET @course_ml := (SELECT id FROM course WHERE title = '机器学习实践导论' AND teacher_id = @teacher2_id AND deleted = 0 LIMIT 1);

INSERT INTO course_chapter (course_id, parent_id, title, sort_order, created_at, updated_at, deleted)
SELECT @course_java, NULL, 'Java 与开发环境', 1, NOW(), NOW(), 0
FROM DUAL
WHERE @course_java IS NOT NULL
  AND NOT EXISTS (SELECT 1 FROM course_chapter WHERE course_id = @course_java AND title = 'Java 与开发环境' AND deleted = 0);

INSERT INTO course_chapter (course_id, parent_id, title, sort_order, created_at, updated_at, deleted)
SELECT @course_java, NULL, '面向对象基础', 2, NOW(), NOW(), 0
FROM DUAL
WHERE @course_java IS NOT NULL
  AND NOT EXISTS (SELECT 1 FROM course_chapter WHERE course_id = @course_java AND title = '面向对象基础' AND deleted = 0);

INSERT INTO course_chapter (course_id, parent_id, title, sort_order, created_at, updated_at, deleted)
SELECT @course_algo, NULL, '线性表与复杂度', 1, NOW(), NOW(), 0
FROM DUAL
WHERE @course_algo IS NOT NULL
  AND NOT EXISTS (SELECT 1 FROM course_chapter WHERE course_id = @course_algo AND title = '线性表与复杂度' AND deleted = 0);

INSERT INTO course_chapter (course_id, parent_id, title, sort_order, created_at, updated_at, deleted)
SELECT @course_algo, NULL, '栈、队列与 BFS 思维', 2, NOW(), NOW(), 0
FROM DUAL
WHERE @course_algo IS NOT NULL
  AND NOT EXISTS (SELECT 1 FROM course_chapter WHERE course_id = @course_algo AND title = '栈、队列与 BFS 思维' AND deleted = 0);

INSERT INTO course_chapter (course_id, parent_id, title, sort_order, created_at, updated_at, deleted)
SELECT @course_ml, NULL, '监督学习概览', 1, NOW(), NOW(), 0
FROM DUAL
WHERE @course_ml IS NOT NULL
  AND NOT EXISTS (SELECT 1 FROM course_chapter WHERE course_id = @course_ml AND title = '监督学习概览' AND deleted = 0);

INSERT INTO course_chapter (course_id, parent_id, title, sort_order, created_at, updated_at, deleted)
SELECT @course_ml, NULL, '模型评估与误差分析', 2, NOW(), NOW(), 0
FROM DUAL
WHERE @course_ml IS NOT NULL
  AND NOT EXISTS (SELECT 1 FROM course_chapter WHERE course_id = @course_ml AND title = '模型评估与误差分析' AND deleted = 0);

SET @java_ch1 := (SELECT id FROM course_chapter WHERE course_id = @course_java AND title = 'Java 与开发环境' AND deleted = 0 LIMIT 1);
SET @java_ch2 := (SELECT id FROM course_chapter WHERE course_id = @course_java AND title = '面向对象基础' AND deleted = 0 LIMIT 1);
SET @algo_ch1 := (SELECT id FROM course_chapter WHERE course_id = @course_algo AND title = '线性表与复杂度' AND deleted = 0 LIMIT 1);
SET @algo_ch2 := (SELECT id FROM course_chapter WHERE course_id = @course_algo AND title = '栈、队列与 BFS 思维' AND deleted = 0 LIMIT 1);
SET @ml_ch1 := (SELECT id FROM course_chapter WHERE course_id = @course_ml AND title = '监督学习概览' AND deleted = 0 LIMIT 1);
SET @ml_ch2 := (SELECT id FROM course_chapter WHERE course_id = @course_ml AND title = '模型评估与误差分析' AND deleted = 0 LIMIT 1);

INSERT INTO course_resource (course_id, chapter_id, title, resource_type, access_type, original_file_name, storage_path, file_url, mime_type, file_size, duration_seconds, transcoding_status, cover_url, created_at, updated_at, deleted)
SELECT @course_java, @java_ch1, '课程导学：Java 发展与安装', 'VIDEO', 'ENROLLED', 'java-intro.mp4', '/demo/java-intro.mp4', 'https://interactive-examples.mdn.mozilla.net/media/cc0-videos/flower.mp4', 'video/mp4', 12500000, 600, 'NOT_REQUIRED', 'https://placehold.co/640x360/png?text=Java+Intro', NOW(), NOW(), 0
FROM DUAL
WHERE @java_ch1 IS NOT NULL
  AND NOT EXISTS (SELECT 1 FROM course_resource WHERE chapter_id = @java_ch1 AND title = '课程导学：Java 发展与安装' AND deleted = 0);

INSERT INTO course_resource (course_id, chapter_id, title, resource_type, access_type, original_file_name, storage_path, file_url, mime_type, file_size, duration_seconds, transcoding_status, cover_url, created_at, updated_at, deleted)
SELECT @course_java, @java_ch1, '环境安装清单', 'PDF', 'PUBLIC', 'java-setup.pdf', '/demo/java-setup.pdf', 'https://www.w3.org/WAI/ER/tests/xhtml/testfiles/resources/pdf/dummy.pdf', 'application/pdf', 240000, NULL, 'NOT_REQUIRED', 'https://placehold.co/640x360/png?text=PDF', NOW(), NOW(), 0
FROM DUAL
WHERE @java_ch1 IS NOT NULL
  AND NOT EXISTS (SELECT 1 FROM course_resource WHERE chapter_id = @java_ch1 AND title = '环境安装清单' AND deleted = 0);

INSERT INTO course_resource (course_id, chapter_id, title, resource_type, access_type, original_file_name, storage_path, file_url, mime_type, file_size, duration_seconds, transcoding_status, cover_url, created_at, updated_at, deleted)
SELECT @course_java, @java_ch2, '类与对象快速入门', 'VIDEO', 'ENROLLED', 'java-oop.mp4', '/demo/java-oop.mp4', 'https://interactive-examples.mdn.mozilla.net/media/cc0-videos/flower.mp4', 'video/mp4', 16800000, 900, 'NOT_REQUIRED', 'https://placehold.co/640x360/png?text=OOP', NOW(), NOW(), 0
FROM DUAL
WHERE @java_ch2 IS NOT NULL
  AND NOT EXISTS (SELECT 1 FROM course_resource WHERE chapter_id = @java_ch2 AND title = '类与对象快速入门' AND deleted = 0);

INSERT INTO course_resource (course_id, chapter_id, title, resource_type, access_type, original_file_name, storage_path, file_url, mime_type, file_size, duration_seconds, transcoding_status, cover_url, created_at, updated_at, deleted)
SELECT @course_java, @java_ch2, '在线实验：对象建模练习', 'LINK', 'PUBLIC', 'java-oop-lab.url', '/demo/java-oop-lab.url', 'https://example.com/labs/java-oop', 'text/uri-list', 128, NULL, 'NOT_REQUIRED', 'https://placehold.co/640x360/png?text=Lab', NOW(), NOW(), 0
FROM DUAL
WHERE @java_ch2 IS NOT NULL
  AND NOT EXISTS (SELECT 1 FROM course_resource WHERE chapter_id = @java_ch2 AND title = '在线实验：对象建模练习' AND deleted = 0);

INSERT INTO course_resource (course_id, chapter_id, title, resource_type, access_type, original_file_name, storage_path, file_url, mime_type, file_size, duration_seconds, transcoding_status, cover_url, created_at, updated_at, deleted)
SELECT @course_algo, @algo_ch1, '数组与链表对比', 'VIDEO', 'ENROLLED', 'array-vs-list.mp4', '/demo/array-vs-list.mp4', 'https://interactive-examples.mdn.mozilla.net/media/cc0-videos/flower.mp4', 'video/mp4', 14600000, 720, 'NOT_REQUIRED', 'https://placehold.co/640x360/png?text=Array+vs+List', NOW(), NOW(), 0
FROM DUAL
WHERE @algo_ch1 IS NOT NULL
  AND NOT EXISTS (SELECT 1 FROM course_resource WHERE chapter_id = @algo_ch1 AND title = '数组与链表对比' AND deleted = 0);

INSERT INTO course_resource (course_id, chapter_id, title, resource_type, access_type, original_file_name, storage_path, file_url, mime_type, file_size, duration_seconds, transcoding_status, cover_url, created_at, updated_at, deleted)
SELECT @course_algo, @algo_ch1, '复杂度速查图', 'IMAGE', 'PUBLIC', 'complexity-cheatsheet.png', '/demo/complexity-cheatsheet.png', 'https://placehold.co/1200x675/png?text=Complexity+Cheat+Sheet', 'image/png', 86000, NULL, 'NOT_REQUIRED', 'https://placehold.co/640x360/png?text=Complexity', NOW(), NOW(), 0
FROM DUAL
WHERE @algo_ch1 IS NOT NULL
  AND NOT EXISTS (SELECT 1 FROM course_resource WHERE chapter_id = @algo_ch1 AND title = '复杂度速查图' AND deleted = 0);

INSERT INTO course_resource (course_id, chapter_id, title, resource_type, access_type, original_file_name, storage_path, file_url, mime_type, file_size, duration_seconds, transcoding_status, cover_url, created_at, updated_at, deleted)
SELECT @course_algo, @algo_ch2, '栈与队列习题讲义', 'PDF', 'ENROLLED', 'stack-queue.pdf', '/demo/stack-queue.pdf', 'https://www.w3.org/WAI/ER/tests/xhtml/testfiles/resources/pdf/dummy.pdf', 'application/pdf', 320000, NULL, 'NOT_REQUIRED', 'https://placehold.co/640x360/png?text=Stack+Queue', NOW(), NOW(), 0
FROM DUAL
WHERE @algo_ch2 IS NOT NULL
  AND NOT EXISTS (SELECT 1 FROM course_resource WHERE chapter_id = @algo_ch2 AND title = '栈与队列习题讲义' AND deleted = 0);

INSERT INTO course_resource (course_id, chapter_id, title, resource_type, access_type, original_file_name, storage_path, file_url, mime_type, file_size, duration_seconds, transcoding_status, cover_url, created_at, updated_at, deleted)
SELECT @course_ml, @ml_ch1, '回归与分类的直观理解', 'VIDEO', 'ENROLLED', 'ml-intro.mp4', '/demo/ml-intro.mp4', 'https://interactive-examples.mdn.mozilla.net/media/cc0-videos/flower.mp4', 'video/mp4', 15400000, 780, 'NOT_REQUIRED', 'https://placehold.co/640x360/png?text=ML+Intro', NOW(), NOW(), 0
FROM DUAL
WHERE @ml_ch1 IS NOT NULL
  AND NOT EXISTS (SELECT 1 FROM course_resource WHERE chapter_id = @ml_ch1 AND title = '回归与分类的直观理解' AND deleted = 0);

INSERT INTO course_resource (course_id, chapter_id, title, resource_type, access_type, original_file_name, storage_path, file_url, mime_type, file_size, duration_seconds, transcoding_status, cover_url, created_at, updated_at, deleted)
SELECT @course_ml, @ml_ch2, '模型评估指标卡片', 'LINK', 'PUBLIC', 'ml-metrics.url', '/demo/ml-metrics.url', 'https://example.com/cards/ml-metrics', 'text/uri-list', 128, NULL, 'NOT_REQUIRED', 'https://placehold.co/640x360/png?text=Metrics', NOW(), NOW(), 0
FROM DUAL
WHERE @ml_ch2 IS NOT NULL
  AND NOT EXISTS (SELECT 1 FROM course_resource WHERE chapter_id = @ml_ch2 AND title = '模型评估指标卡片' AND deleted = 0);

INSERT INTO course_enrollment (course_id, user_id, created_at, updated_at, deleted)
SELECT @course_java, @student1_id, NOW(), NOW(), 0
FROM DUAL
WHERE @course_java IS NOT NULL AND @student1_id IS NOT NULL
  AND NOT EXISTS (SELECT 1 FROM course_enrollment WHERE course_id = @course_java AND user_id = @student1_id AND deleted = 0);

INSERT INTO course_enrollment (course_id, user_id, created_at, updated_at, deleted)
SELECT @course_algo, @student1_id, NOW(), NOW(), 0
FROM DUAL
WHERE @course_algo IS NOT NULL AND @student1_id IS NOT NULL
  AND NOT EXISTS (SELECT 1 FROM course_enrollment WHERE course_id = @course_algo AND user_id = @student1_id AND deleted = 0);

INSERT INTO course_enrollment (course_id, user_id, created_at, updated_at, deleted)
SELECT @course_ml, @student1_id, NOW(), NOW(), 0
FROM DUAL
WHERE @course_ml IS NOT NULL AND @student1_id IS NOT NULL
  AND NOT EXISTS (SELECT 1 FROM course_enrollment WHERE course_id = @course_ml AND user_id = @student1_id AND deleted = 0);

INSERT INTO course_enrollment (course_id, user_id, created_at, updated_at, deleted)
SELECT @course_java, @student2_id, NOW(), NOW(), 0
FROM DUAL
WHERE @course_java IS NOT NULL AND @student2_id IS NOT NULL
  AND NOT EXISTS (SELECT 1 FROM course_enrollment WHERE course_id = @course_java AND user_id = @student2_id AND deleted = 0);

INSERT INTO course_enrollment (course_id, user_id, created_at, updated_at, deleted)
SELECT @course_ml, @student2_id, NOW(), NOW(), 0
FROM DUAL
WHERE @course_ml IS NOT NULL AND @student2_id IS NOT NULL
  AND NOT EXISTS (SELECT 1 FROM course_enrollment WHERE course_id = @course_ml AND user_id = @student2_id AND deleted = 0);

INSERT INTO course_enrollment (course_id, user_id, created_at, updated_at, deleted)
SELECT @course_algo, @student3_id, NOW(), NOW(), 0
FROM DUAL
WHERE @course_algo IS NOT NULL AND @student3_id IS NOT NULL
  AND NOT EXISTS (SELECT 1 FROM course_enrollment WHERE course_id = @course_algo AND user_id = @student3_id AND deleted = 0);

UPDATE course c
SET c.student_count = (
  SELECT COUNT(*)
  FROM course_enrollment ce
  WHERE ce.course_id = c.id AND ce.deleted = 0
)
WHERE c.id IN (@course_java, @course_algo, @course_ml);

SET @java_video_1 := (SELECT id FROM course_resource WHERE chapter_id = @java_ch1 AND title = '课程导学：Java 发展与安装' AND deleted = 0 LIMIT 1);
SET @java_video_2 := (SELECT id FROM course_resource WHERE chapter_id = @java_ch2 AND title = '类与对象快速入门' AND deleted = 0 LIMIT 1);
SET @algo_video_1 := (SELECT id FROM course_resource WHERE chapter_id = @algo_ch1 AND title = '数组与链表对比' AND deleted = 0 LIMIT 1);
SET @java_pdf_1 := (SELECT id FROM course_resource WHERE chapter_id = @java_ch1 AND title = '环境安装清单' AND deleted = 0 LIMIT 1);

INSERT INTO video_progress (user_id, course_id, chapter_id, resource_id, current_position, duration_seconds, effective_study_seconds, progress_percent, completed, last_playback_rate, last_client_timestamp, last_report_at, last_study_at, created_at, updated_at, deleted)
SELECT @student1_id, @course_java, @java_ch1, @java_video_1, 600, 600, 540, 100.0, 1, 1.0, UNIX_TIMESTAMP(NOW()) * 1000, DATE_SUB(NOW(), INTERVAL 2 DAY), DATE_SUB(NOW(), INTERVAL 2 DAY), NOW(), NOW(), 0
FROM DUAL
WHERE @student1_id IS NOT NULL AND @java_video_1 IS NOT NULL
ON DUPLICATE KEY UPDATE
  current_position = VALUES(current_position),
  duration_seconds = VALUES(duration_seconds),
  effective_study_seconds = VALUES(effective_study_seconds),
  progress_percent = VALUES(progress_percent),
  completed = VALUES(completed),
  last_playback_rate = VALUES(last_playback_rate),
  last_client_timestamp = VALUES(last_client_timestamp),
  last_report_at = VALUES(last_report_at),
  last_study_at = VALUES(last_study_at),
  updated_at = NOW(),
  deleted = 0;

INSERT INTO video_progress (user_id, course_id, chapter_id, resource_id, current_position, duration_seconds, effective_study_seconds, progress_percent, completed, last_playback_rate, last_client_timestamp, last_report_at, last_study_at, created_at, updated_at, deleted)
SELECT @student1_id, @course_java, @java_ch2, @java_video_2, 390, 900, 360, 43.3, 0, 1.25, UNIX_TIMESTAMP(NOW()) * 1000, DATE_SUB(NOW(), INTERVAL 1 DAY), DATE_SUB(NOW(), INTERVAL 1 DAY), NOW(), NOW(), 0
FROM DUAL
WHERE @student1_id IS NOT NULL AND @java_video_2 IS NOT NULL
ON DUPLICATE KEY UPDATE
  current_position = VALUES(current_position),
  duration_seconds = VALUES(duration_seconds),
  effective_study_seconds = VALUES(effective_study_seconds),
  progress_percent = VALUES(progress_percent),
  completed = VALUES(completed),
  last_playback_rate = VALUES(last_playback_rate),
  last_client_timestamp = VALUES(last_client_timestamp),
  last_report_at = VALUES(last_report_at),
  last_study_at = VALUES(last_study_at),
  updated_at = NOW(),
  deleted = 0;

INSERT INTO video_progress (user_id, course_id, chapter_id, resource_id, current_position, duration_seconds, effective_study_seconds, progress_percent, completed, last_playback_rate, last_client_timestamp, last_report_at, last_study_at, created_at, updated_at, deleted)
SELECT @student2_id, @course_java, @java_ch1, @java_video_1, 180, 600, 180, 30.0, 0, 1.0, UNIX_TIMESTAMP(NOW()) * 1000, DATE_SUB(NOW(), INTERVAL 3 DAY), DATE_SUB(NOW(), INTERVAL 3 DAY), NOW(), NOW(), 0
FROM DUAL
WHERE @student2_id IS NOT NULL AND @java_video_1 IS NOT NULL
ON DUPLICATE KEY UPDATE
  current_position = VALUES(current_position),
  duration_seconds = VALUES(duration_seconds),
  effective_study_seconds = VALUES(effective_study_seconds),
  progress_percent = VALUES(progress_percent),
  completed = VALUES(completed),
  last_playback_rate = VALUES(last_playback_rate),
  last_client_timestamp = VALUES(last_client_timestamp),
  last_report_at = VALUES(last_report_at),
  last_study_at = VALUES(last_study_at),
  updated_at = NOW(),
  deleted = 0;

INSERT INTO study_record (user_id, course_id, chapter_id, resource_id, reported_position, trusted_position, duration_seconds, trusted_increment_seconds, report_interval_seconds, playback_rate, client_timestamp, suspicious, suspicious_reason, created_at, updated_at, deleted)
SELECT @student1_id, @course_java, @java_ch1, @java_video_1, 120, 120, 600, 120, 120, 1.0, 1716200000000, 0, NULL, DATE_SUB(NOW(), INTERVAL 2 DAY), DATE_SUB(NOW(), INTERVAL 2 DAY), 0
FROM DUAL
WHERE @student1_id IS NOT NULL AND @java_video_1 IS NOT NULL
  AND NOT EXISTS (
    SELECT 1 FROM study_record
    WHERE user_id = @student1_id AND resource_id = @java_video_1 AND client_timestamp = 1716200000000 AND deleted = 0
  );

INSERT INTO study_record (user_id, course_id, chapter_id, resource_id, reported_position, trusted_position, duration_seconds, trusted_increment_seconds, report_interval_seconds, playback_rate, client_timestamp, suspicious, suspicious_reason, created_at, updated_at, deleted)
SELECT @student1_id, @course_java, @java_ch2, @java_video_2, 390, 390, 900, 90, 90, 1.25, 1716286400000, 0, NULL, DATE_SUB(NOW(), INTERVAL 1 DAY), DATE_SUB(NOW(), INTERVAL 1 DAY), 0
FROM DUAL
WHERE @student1_id IS NOT NULL AND @java_video_2 IS NOT NULL
  AND NOT EXISTS (
    SELECT 1 FROM study_record
    WHERE user_id = @student1_id AND resource_id = @java_video_2 AND client_timestamp = 1716286400000 AND deleted = 0
  );

INSERT INTO learning_daily_stat (user_id, stat_date, total_study_seconds, last_study_at, created_at, updated_at, deleted)
SELECT @student1_id, DATE_SUB(CURDATE(), INTERVAL 6 DAY), 1800, DATE_SUB(NOW(), INTERVAL 6 DAY), NOW(), NOW(), 0
FROM DUAL
WHERE @student1_id IS NOT NULL
ON DUPLICATE KEY UPDATE total_study_seconds = VALUES(total_study_seconds), last_study_at = VALUES(last_study_at), updated_at = NOW(), deleted = 0;

INSERT INTO learning_daily_stat (user_id, stat_date, total_study_seconds, last_study_at, created_at, updated_at, deleted)
SELECT @student1_id, DATE_SUB(CURDATE(), INTERVAL 5 DAY), 2400, DATE_SUB(NOW(), INTERVAL 5 DAY), NOW(), NOW(), 0
FROM DUAL
WHERE @student1_id IS NOT NULL
ON DUPLICATE KEY UPDATE total_study_seconds = VALUES(total_study_seconds), last_study_at = VALUES(last_study_at), updated_at = NOW(), deleted = 0;

INSERT INTO learning_daily_stat (user_id, stat_date, total_study_seconds, last_study_at, created_at, updated_at, deleted)
SELECT @student1_id, DATE_SUB(CURDATE(), INTERVAL 4 DAY), 1200, DATE_SUB(NOW(), INTERVAL 4 DAY), NOW(), NOW(), 0
FROM DUAL
WHERE @student1_id IS NOT NULL
ON DUPLICATE KEY UPDATE total_study_seconds = VALUES(total_study_seconds), last_study_at = VALUES(last_study_at), updated_at = NOW(), deleted = 0;

INSERT INTO learning_daily_stat (user_id, stat_date, total_study_seconds, last_study_at, created_at, updated_at, deleted)
SELECT @student1_id, DATE_SUB(CURDATE(), INTERVAL 3 DAY), 0, DATE_SUB(NOW(), INTERVAL 3 DAY), NOW(), NOW(), 0
FROM DUAL
WHERE @student1_id IS NOT NULL
ON DUPLICATE KEY UPDATE total_study_seconds = VALUES(total_study_seconds), last_study_at = VALUES(last_study_at), updated_at = NOW(), deleted = 0;

INSERT INTO learning_daily_stat (user_id, stat_date, total_study_seconds, last_study_at, created_at, updated_at, deleted)
SELECT @student1_id, DATE_SUB(CURDATE(), INTERVAL 2 DAY), 2700, DATE_SUB(NOW(), INTERVAL 2 DAY), NOW(), NOW(), 0
FROM DUAL
WHERE @student1_id IS NOT NULL
ON DUPLICATE KEY UPDATE total_study_seconds = VALUES(total_study_seconds), last_study_at = VALUES(last_study_at), updated_at = NOW(), deleted = 0;

INSERT INTO learning_daily_stat (user_id, stat_date, total_study_seconds, last_study_at, created_at, updated_at, deleted)
SELECT @student1_id, DATE_SUB(CURDATE(), INTERVAL 1 DAY), 3600, DATE_SUB(NOW(), INTERVAL 1 DAY), NOW(), NOW(), 0
FROM DUAL
WHERE @student1_id IS NOT NULL
ON DUPLICATE KEY UPDATE total_study_seconds = VALUES(total_study_seconds), last_study_at = VALUES(last_study_at), updated_at = NOW(), deleted = 0;

INSERT INTO learning_daily_stat (user_id, stat_date, total_study_seconds, last_study_at, created_at, updated_at, deleted)
SELECT @student1_id, CURDATE(), 1800, NOW(), NOW(), NOW(), 0
FROM DUAL
WHERE @student1_id IS NOT NULL
ON DUPLICATE KEY UPDATE total_study_seconds = VALUES(total_study_seconds), last_study_at = VALUES(last_study_at), updated_at = NOW(), deleted = 0;

INSERT INTO study_room (room_name, capacity, course_id, open_time, close_time, status, created_at, updated_at, deleted)
SELECT 'Java 晚间自习室', 8, @course_java, DATE_SUB(NOW(), INTERVAL 7 DAY), DATE_ADD(NOW(), INTERVAL 30 DAY), 'OPEN', NOW(), NOW(), 0
FROM DUAL
WHERE @course_java IS NOT NULL
  AND NOT EXISTS (SELECT 1 FROM study_room WHERE room_name = 'Java 晚间自习室' AND deleted = 0);

INSERT INTO study_room (room_name, capacity, course_id, open_time, close_time, status, created_at, updated_at, deleted)
SELECT '算法冲刺自习室', 6, @course_algo, DATE_SUB(NOW(), INTERVAL 10 DAY), DATE_ADD(NOW(), INTERVAL 15 DAY), 'OPEN', NOW(), NOW(), 0
FROM DUAL
WHERE @course_algo IS NOT NULL
  AND NOT EXISTS (SELECT 1 FROM study_room WHERE room_name = '算法冲刺自习室' AND deleted = 0);

SET @room_java := (SELECT id FROM study_room WHERE room_name = 'Java 晚间自习室' AND deleted = 0 LIMIT 1);
SET @room_algo := (SELECT id FROM study_room WHERE room_name = '算法冲刺自习室' AND deleted = 0 LIMIT 1);

INSERT INTO room_record (room_id, user_id, seat_no, focus_minutes, start_time, end_time, session_token, status, created_at, updated_at, deleted)
SELECT @room_java, @student1_id, 3, 45, DATE_SUB(NOW(), INTERVAL 1 DAY), DATE_SUB(NOW(), INTERVAL 1 DAY) + INTERVAL 45 MINUTE, 'demo-room-java-s1', 'COMPLETED', NOW(), NOW(), 0
FROM DUAL
WHERE @room_java IS NOT NULL AND @student1_id IS NOT NULL
  AND NOT EXISTS (SELECT 1 FROM room_record WHERE session_token = 'demo-room-java-s1' AND deleted = 0);

INSERT INTO room_record (room_id, user_id, seat_no, focus_minutes, start_time, end_time, session_token, status, created_at, updated_at, deleted)
SELECT @room_algo, @student3_id, 2, 30, DATE_SUB(NOW(), INTERVAL 2 DAY), DATE_SUB(NOW(), INTERVAL 2 DAY) + INTERVAL 30 MINUTE, 'demo-room-algo-s3', 'COMPLETED', NOW(), NOW(), 0
FROM DUAL
WHERE @room_algo IS NOT NULL AND @student3_id IS NOT NULL
  AND NOT EXISTS (SELECT 1 FROM room_record WHERE session_token = 'demo-room-algo-s3' AND deleted = 0);

INSERT INTO room_checkin (room_id, user_id, checkin_date, total_focus_minutes, completed_count, last_checkin_at, created_at, updated_at, deleted)
SELECT @room_java, @student1_id, CURDATE(), 45, 1, NOW(), NOW(), NOW(), 0
FROM DUAL
WHERE @room_java IS NOT NULL AND @student1_id IS NOT NULL
ON DUPLICATE KEY UPDATE total_focus_minutes = VALUES(total_focus_minutes), completed_count = VALUES(completed_count), last_checkin_at = VALUES(last_checkin_at), updated_at = NOW(), deleted = 0;

INSERT INTO room_checkin (room_id, user_id, checkin_date, total_focus_minutes, completed_count, last_checkin_at, created_at, updated_at, deleted)
SELECT @room_algo, @student3_id, DATE_SUB(CURDATE(), INTERVAL 1 DAY), 30, 1, DATE_SUB(NOW(), INTERVAL 1 DAY), NOW(), NOW(), 0
FROM DUAL
WHERE @room_algo IS NOT NULL AND @student3_id IS NOT NULL
ON DUPLICATE KEY UPDATE total_focus_minutes = VALUES(total_focus_minutes), completed_count = VALUES(completed_count), last_checkin_at = VALUES(last_checkin_at), updated_at = NOW(), deleted = 0;

INSERT INTO knowledge_point (course_id, teacher_id, name, description, created_at, updated_at, deleted)
SELECT @course_java, @teacher1_id, '类与对象', '理解类、对象、属性、方法及其实例化过程。', NOW(), NOW(), 0
FROM DUAL
WHERE @course_java IS NOT NULL AND @teacher1_id IS NOT NULL
  AND NOT EXISTS (SELECT 1 FROM knowledge_point WHERE course_id = @course_java AND name = '类与对象' AND deleted = 0);

INSERT INTO knowledge_point (course_id, teacher_id, name, description, created_at, updated_at, deleted)
SELECT @course_java, @teacher1_id, '封装与访问控制', '理解 private、protected、public 与包访问的区别。', NOW(), NOW(), 0
FROM DUAL
WHERE @course_java IS NOT NULL AND @teacher1_id IS NOT NULL
  AND NOT EXISTS (SELECT 1 FROM knowledge_point WHERE course_id = @course_java AND name = '封装与访问控制' AND deleted = 0);

INSERT INTO knowledge_point (course_id, teacher_id, name, description, created_at, updated_at, deleted)
SELECT @course_java, @teacher1_id, '继承与多态', '理解 extends、override 与运行时多态。', NOW(), NOW(), 0
FROM DUAL
WHERE @course_java IS NOT NULL AND @teacher1_id IS NOT NULL
  AND NOT EXISTS (SELECT 1 FROM knowledge_point WHERE course_id = @course_java AND name = '继承与多态' AND deleted = 0);

SET @kp_class := (SELECT id FROM knowledge_point WHERE course_id = @course_java AND name = '类与对象' AND deleted = 0 LIMIT 1);
SET @kp_access := (SELECT id FROM knowledge_point WHERE course_id = @course_java AND name = '封装与访问控制' AND deleted = 0 LIMIT 1);
SET @kp_inherit := (SELECT id FROM knowledge_point WHERE course_id = @course_java AND name = '继承与多态' AND deleted = 0 LIMIT 1);

INSERT INTO knowledge_relation (course_id, knowledge_point_id, prerequisite_id, created_at, updated_at, deleted)
SELECT @course_java, @kp_access, @kp_class, NOW(), NOW(), 0
FROM DUAL
WHERE @kp_access IS NOT NULL AND @kp_class IS NOT NULL
  AND NOT EXISTS (
    SELECT 1 FROM knowledge_relation
    WHERE course_id = @course_java AND knowledge_point_id = @kp_access AND prerequisite_id = @kp_class AND deleted = 0
  );

INSERT INTO knowledge_relation (course_id, knowledge_point_id, prerequisite_id, created_at, updated_at, deleted)
SELECT @course_java, @kp_inherit, @kp_access, NOW(), NOW(), 0
FROM DUAL
WHERE @kp_inherit IS NOT NULL AND @kp_access IS NOT NULL
  AND NOT EXISTS (
    SELECT 1 FROM knowledge_relation
    WHERE course_id = @course_java AND knowledge_point_id = @kp_inherit AND prerequisite_id = @kp_access AND deleted = 0
  );

INSERT INTO question (course_id, chapter_id, teacher_id, stem, question_type, standard_answer, analysis, difficulty, knowledge_point, partial_credit_enabled, created_at, updated_at, deleted)
SELECT @course_java, @java_ch1, @teacher1_id, 'Java 源代码经过 javac 编译后生成的产物是什么？', 'SINGLE_CHOICE', '\"A\"', 'Java 源文件会先编译成字节码，再由 JVM 执行。', '初级', '类与对象', 0, NOW(), NOW(), 0
FROM DUAL
WHERE @course_java IS NOT NULL AND @teacher1_id IS NOT NULL
  AND NOT EXISTS (
    SELECT 1 FROM question
    WHERE course_id = @course_java AND teacher_id = @teacher1_id AND stem = 'Java 源代码经过 javac 编译后生成的产物是什么？' AND deleted = 0
  );

INSERT INTO question (course_id, chapter_id, teacher_id, stem, question_type, standard_answer, analysis, difficulty, knowledge_point, partial_credit_enabled, created_at, updated_at, deleted)
SELECT @course_java, @java_ch2, @teacher1_id, 'JVM 屏蔽了不同操作系统的底层差异，因此 Java 具备较强的跨平台能力。', 'TRUE_FALSE', 'true', '字节码运行在 JVM 上，JVM 为不同平台提供统一执行环境。', '初级', '封装与访问控制', 0, NOW(), NOW(), 0
FROM DUAL
WHERE @course_java IS NOT NULL AND @teacher1_id IS NOT NULL
  AND NOT EXISTS (
    SELECT 1 FROM question
    WHERE course_id = @course_java AND teacher_id = @teacher1_id AND stem = 'JVM 屏蔽了不同操作系统的底层差异，因此 Java 具备较强的跨平台能力。' AND deleted = 0
  );

INSERT INTO question (course_id, chapter_id, teacher_id, stem, question_type, standard_answer, analysis, difficulty, knowledge_point, partial_credit_enabled, created_at, updated_at, deleted)
SELECT @course_java, @java_ch2, @teacher1_id, '在 Java 中，允许子类和同包类访问、但不允许其他包普通类直接访问的关键字是什么？', 'FILL_BLANK', '[\"protected\"]', 'protected 兼顾继承场景与同包访问。', '中级', '封装与访问控制', 0, NOW(), NOW(), 0
FROM DUAL
WHERE @course_java IS NOT NULL AND @teacher1_id IS NOT NULL
  AND NOT EXISTS (
    SELECT 1 FROM question
    WHERE course_id = @course_java AND teacher_id = @teacher1_id AND stem = '在 Java 中，允许子类和同包类访问、但不允许其他包普通类直接访问的关键字是什么？' AND deleted = 0
  );

INSERT INTO question (course_id, chapter_id, teacher_id, stem, question_type, standard_answer, analysis, difficulty, knowledge_point, partial_credit_enabled, created_at, updated_at, deleted)
SELECT @course_java, @java_ch2, @teacher1_id, '下面哪些描述体现了面向对象中的封装思想？', 'MULTIPLE_CHOICE', '[\"A\",\"C\"]', '隐藏内部状态，只暴露稳定接口，是封装的核心。', '中级', '封装与访问控制', 1, NOW(), NOW(), 0
FROM DUAL
WHERE @course_java IS NOT NULL AND @teacher1_id IS NOT NULL
  AND NOT EXISTS (
    SELECT 1 FROM question
    WHERE course_id = @course_java AND teacher_id = @teacher1_id AND stem = '下面哪些描述体现了面向对象中的封装思想？' AND deleted = 0
  );

INSERT INTO question (course_id, chapter_id, teacher_id, stem, question_type, standard_answer, analysis, difficulty, knowledge_point, partial_credit_enabled, created_at, updated_at, deleted)
SELECT @course_algo, @algo_ch1, @teacher1_id, '数组与链表相比，各自的随机访问和插入删除复杂度有什么差异？请简要说明。', 'SHORT_ANSWER', '\"开放题\"', '演示主观题，提交后会进入待人工批改状态。', '中级', '线性表', 0, NOW(), NOW(), 0
FROM DUAL
WHERE @course_algo IS NOT NULL AND @teacher1_id IS NOT NULL
  AND NOT EXISTS (
    SELECT 1 FROM question
    WHERE course_id = @course_algo AND teacher_id = @teacher1_id AND stem = '数组与链表相比，各自的随机访问和插入删除复杂度有什么差异？请简要说明。' AND deleted = 0
  );

SET @q_java_sc := (SELECT id FROM question WHERE stem = 'Java 源代码经过 javac 编译后生成的产物是什么？' AND teacher_id = @teacher1_id AND deleted = 0 LIMIT 1);
SET @q_java_tf := (SELECT id FROM question WHERE stem = 'JVM 屏蔽了不同操作系统的底层差异，因此 Java 具备较强的跨平台能力。' AND teacher_id = @teacher1_id AND deleted = 0 LIMIT 1);
SET @q_java_fb := (SELECT id FROM question WHERE stem = '在 Java 中，允许子类和同包类访问、但不允许其他包普通类直接访问的关键字是什么？' AND teacher_id = @teacher1_id AND deleted = 0 LIMIT 1);
SET @q_java_mc := (SELECT id FROM question WHERE stem = '下面哪些描述体现了面向对象中的封装思想？' AND teacher_id = @teacher1_id AND deleted = 0 LIMIT 1);
SET @q_algo_sa := (SELECT id FROM question WHERE stem = '数组与链表相比，各自的随机访问和插入删除复杂度有什么差异？请简要说明。' AND teacher_id = @teacher1_id AND deleted = 0 LIMIT 1);

INSERT INTO question_option (question_id, option_key, option_content, sort_order, created_at, updated_at, deleted)
SELECT @q_java_sc, 'A', '字节码文件（.class）', 1, NOW(), NOW(), 0
FROM DUAL
WHERE @q_java_sc IS NOT NULL
  AND NOT EXISTS (SELECT 1 FROM question_option WHERE question_id = @q_java_sc AND option_key = 'A' AND deleted = 0);

INSERT INTO question_option (question_id, option_key, option_content, sort_order, created_at, updated_at, deleted)
SELECT @q_java_sc, 'B', '平台相关的机器码', 2, NOW(), NOW(), 0
FROM DUAL
WHERE @q_java_sc IS NOT NULL
  AND NOT EXISTS (SELECT 1 FROM question_option WHERE question_id = @q_java_sc AND option_key = 'B' AND deleted = 0);

INSERT INTO question_option (question_id, option_key, option_content, sort_order, created_at, updated_at, deleted)
SELECT @q_java_sc, 'C', '数据库脚本文件', 3, NOW(), NOW(), 0
FROM DUAL
WHERE @q_java_sc IS NOT NULL
  AND NOT EXISTS (SELECT 1 FROM question_option WHERE question_id = @q_java_sc AND option_key = 'C' AND deleted = 0);

INSERT INTO question_option (question_id, option_key, option_content, sort_order, created_at, updated_at, deleted)
SELECT @q_java_sc, 'D', 'JAR 安装包', 4, NOW(), NOW(), 0
FROM DUAL
WHERE @q_java_sc IS NOT NULL
  AND NOT EXISTS (SELECT 1 FROM question_option WHERE question_id = @q_java_sc AND option_key = 'D' AND deleted = 0);

INSERT INTO question_option (question_id, option_key, option_content, sort_order, created_at, updated_at, deleted)
SELECT @q_java_mc, 'A', '通过 private 隐藏对象内部状态', 1, NOW(), NOW(), 0
FROM DUAL
WHERE @q_java_mc IS NOT NULL
  AND NOT EXISTS (SELECT 1 FROM question_option WHERE question_id = @q_java_mc AND option_key = 'A' AND deleted = 0);

INSERT INTO question_option (question_id, option_key, option_content, sort_order, created_at, updated_at, deleted)
SELECT @q_java_mc, 'B', '把所有字段都声明为 public', 2, NOW(), NOW(), 0
FROM DUAL
WHERE @q_java_mc IS NOT NULL
  AND NOT EXISTS (SELECT 1 FROM question_option WHERE question_id = @q_java_mc AND option_key = 'B' AND deleted = 0);

INSERT INTO question_option (question_id, option_key, option_content, sort_order, created_at, updated_at, deleted)
SELECT @q_java_mc, 'C', '通过 getter 或方法控制外部访问', 3, NOW(), NOW(), 0
FROM DUAL
WHERE @q_java_mc IS NOT NULL
  AND NOT EXISTS (SELECT 1 FROM question_option WHERE question_id = @q_java_mc AND option_key = 'C' AND deleted = 0);

INSERT INTO question_option (question_id, option_key, option_content, sort_order, created_at, updated_at, deleted)
SELECT @q_java_mc, 'D', '让外部直接修改对象全部属性', 4, NOW(), NOW(), 0
FROM DUAL
WHERE @q_java_mc IS NOT NULL
  AND NOT EXISTS (SELECT 1 FROM question_option WHERE question_id = @q_java_mc AND option_key = 'D' AND deleted = 0);

INSERT INTO paper (title, course_id, teacher_id, total_score, pass_score, duration_minutes, allow_redo, max_attempts, start_time, end_time, published, created_at, updated_at, deleted)
SELECT 'Java 基础阶段测验', @course_java, @teacher1_id, 100.00, 60.00, 45, 1, 2, DATE_SUB(NOW(), INTERVAL 7 DAY), DATE_ADD(NOW(), INTERVAL 30 DAY), 1, NOW(), NOW(), 0
FROM DUAL
WHERE @course_java IS NOT NULL AND @teacher1_id IS NOT NULL
  AND NOT EXISTS (SELECT 1 FROM paper WHERE title = 'Java 基础阶段测验' AND course_id = @course_java AND teacher_id = @teacher1_id AND deleted = 0);

INSERT INTO paper (title, course_id, teacher_id, total_score, pass_score, duration_minutes, allow_redo, max_attempts, start_time, end_time, published, created_at, updated_at, deleted)
SELECT '算法思维热身卷', @course_algo, @teacher1_id, 40.00, 24.00, 20, 0, 1, DATE_SUB(NOW(), INTERVAL 3 DAY), DATE_ADD(NOW(), INTERVAL 20 DAY), 1, NOW(), NOW(), 0
FROM DUAL
WHERE @course_algo IS NOT NULL AND @teacher1_id IS NOT NULL
  AND NOT EXISTS (SELECT 1 FROM paper WHERE title = '算法思维热身卷' AND course_id = @course_algo AND teacher_id = @teacher1_id AND deleted = 0);

SET @paper_java := (SELECT id FROM paper WHERE title = 'Java 基础阶段测验' AND course_id = @course_java AND teacher_id = @teacher1_id AND deleted = 0 LIMIT 1);
SET @paper_algo := (SELECT id FROM paper WHERE title = '算法思维热身卷' AND course_id = @course_algo AND teacher_id = @teacher1_id AND deleted = 0 LIMIT 1);

INSERT INTO paper_question (paper_id, question_id, chapter_id, sort_order, score, question_stem, question_type, option_snapshot, standard_answer, analysis, difficulty, knowledge_point, partial_credit_enabled, created_at, updated_at, deleted)
SELECT @paper_java, @q_java_sc, @java_ch1, 1, 20.00, 'Java 源代码经过 javac 编译后生成的产物是什么？', 'SINGLE_CHOICE', '[{"optionKey":"A","content":"class"},{"optionKey":"B","content":"machine"},{"optionKey":"C","content":"script"},{"optionKey":"D","content":"jar"}]', '\"A\"', 'Java 源文件会先编译成字节码，再由 JVM 执行。', '初级', '类与对象', 0, NOW(), NOW(), 0
FROM DUAL
WHERE @paper_java IS NOT NULL AND @q_java_sc IS NOT NULL
  AND NOT EXISTS (SELECT 1 FROM paper_question WHERE paper_id = @paper_java AND sort_order = 1 AND deleted = 0);

INSERT INTO paper_question (paper_id, question_id, chapter_id, sort_order, score, question_stem, question_type, option_snapshot, standard_answer, analysis, difficulty, knowledge_point, partial_credit_enabled, created_at, updated_at, deleted)
SELECT @paper_java, @q_java_tf, @java_ch2, 2, 20.00, 'JVM 屏蔽了不同操作系统的底层差异，因此 Java 具备较强的跨平台能力。', 'TRUE_FALSE', '[]', 'true', '字节码运行在 JVM 上，JVM 为不同平台提供统一执行环境。', '初级', '封装与访问控制', 0, NOW(), NOW(), 0
FROM DUAL
WHERE @paper_java IS NOT NULL AND @q_java_tf IS NOT NULL
  AND NOT EXISTS (SELECT 1 FROM paper_question WHERE paper_id = @paper_java AND sort_order = 2 AND deleted = 0);

INSERT INTO paper_question (paper_id, question_id, chapter_id, sort_order, score, question_stem, question_type, option_snapshot, standard_answer, analysis, difficulty, knowledge_point, partial_credit_enabled, created_at, updated_at, deleted)
SELECT @paper_java, @q_java_fb, @java_ch2, 3, 20.00, '在 Java 中，允许子类和同包类访问、但不允许其他包普通类直接访问的关键字是什么？', 'FILL_BLANK', '[]', '[\"protected\"]', 'protected 兼顾继承场景与同包访问。', '中级', '封装与访问控制', 0, NOW(), NOW(), 0
FROM DUAL
WHERE @paper_java IS NOT NULL AND @q_java_fb IS NOT NULL
  AND NOT EXISTS (SELECT 1 FROM paper_question WHERE paper_id = @paper_java AND sort_order = 3 AND deleted = 0);

INSERT INTO paper_question (paper_id, question_id, chapter_id, sort_order, score, question_stem, question_type, option_snapshot, standard_answer, analysis, difficulty, knowledge_point, partial_credit_enabled, created_at, updated_at, deleted)
SELECT @paper_java, @q_java_mc, @java_ch2, 4, 40.00, '下面哪些描述体现了面向对象中的封装思想？', 'MULTIPLE_CHOICE', '[{"optionKey":"A","content":"hide"},{"optionKey":"B","content":"public"},{"optionKey":"C","content":"getter"},{"optionKey":"D","content":"edit"}]', '[\"A\",\"C\"]', '隐藏内部状态，只暴露稳定接口，是封装的核心。', '中级', '封装与访问控制', 1, NOW(), NOW(), 0
FROM DUAL
WHERE @paper_java IS NOT NULL AND @q_java_mc IS NOT NULL
  AND NOT EXISTS (SELECT 1 FROM paper_question WHERE paper_id = @paper_java AND sort_order = 4 AND deleted = 0);

INSERT INTO paper_question (paper_id, question_id, chapter_id, sort_order, score, question_stem, question_type, option_snapshot, standard_answer, analysis, difficulty, knowledge_point, partial_credit_enabled, created_at, updated_at, deleted)
SELECT @paper_algo, @q_algo_sa, @algo_ch1, 1, 40.00, '数组与链表相比，各自的随机访问和插入删除复杂度有什么差异？请简要说明。', 'SHORT_ANSWER', '[]', '\"开放题\"', '演示主观题，提交后会进入待人工批改状态。', '中级', '线性表', 0, NOW(), NOW(), 0
FROM DUAL
WHERE @paper_algo IS NOT NULL AND @q_algo_sa IS NOT NULL
  AND NOT EXISTS (SELECT 1 FROM paper_question WHERE paper_id = @paper_algo AND sort_order = 1 AND deleted = 0);

INSERT INTO exam_record (paper_id, course_id, user_id, attempt_no, start_time, deadline_time, submit_time, status, objective_score, total_score, pass_score, passed, answered_count, total_question_count, created_at, updated_at, deleted)
SELECT @paper_java, @course_java, @student1_id, 1, DATE_SUB(NOW(), INTERVAL 12 HOUR), DATE_SUB(NOW(), INTERVAL 11 HOUR) + INTERVAL 45 MINUTE, DATE_SUB(NOW(), INTERVAL 11 HOUR), 'COMPLETED', 40.00, 40.00, 60.00, 0, 4, 4, NOW(), NOW(), 0
FROM DUAL
WHERE @paper_java IS NOT NULL AND @student1_id IS NOT NULL
  AND NOT EXISTS (SELECT 1 FROM exam_record WHERE paper_id = @paper_java AND user_id = @student1_id AND attempt_no = 1 AND deleted = 0);

SET @exam_java_student1 := (SELECT id FROM exam_record WHERE paper_id = @paper_java AND user_id = @student1_id AND attempt_no = 1 AND deleted = 0 LIMIT 1);
SET @paper_java_q1 := (SELECT id FROM paper_question WHERE paper_id = @paper_java AND sort_order = 1 AND deleted = 0 LIMIT 1);
SET @paper_java_q2 := (SELECT id FROM paper_question WHERE paper_id = @paper_java AND sort_order = 2 AND deleted = 0 LIMIT 1);
SET @paper_java_q3 := (SELECT id FROM paper_question WHERE paper_id = @paper_java AND sort_order = 3 AND deleted = 0 LIMIT 1);
SET @paper_java_q4 := (SELECT id FROM paper_question WHERE paper_id = @paper_java AND sort_order = 4 AND deleted = 0 LIMIT 1);

INSERT INTO user_answer (exam_record_id, paper_question_id, question_id, question_type, answer_content, awarded_score, correct_flag, auto_graded, needs_manual_review, created_at, updated_at, deleted)
SELECT @exam_java_student1, @paper_java_q1, @q_java_sc, 'SINGLE_CHOICE', '\"B\"', 0.00, 0, 1, 0, NOW(), NOW(), 0
FROM DUAL
WHERE @exam_java_student1 IS NOT NULL AND @paper_java_q1 IS NOT NULL
  AND NOT EXISTS (SELECT 1 FROM user_answer WHERE exam_record_id = @exam_java_student1 AND paper_question_id = @paper_java_q1 AND deleted = 0);

INSERT INTO user_answer (exam_record_id, paper_question_id, question_id, question_type, answer_content, awarded_score, correct_flag, auto_graded, needs_manual_review, created_at, updated_at, deleted)
SELECT @exam_java_student1, @paper_java_q2, @q_java_tf, 'TRUE_FALSE', 'false', 0.00, 0, 1, 0, NOW(), NOW(), 0
FROM DUAL
WHERE @exam_java_student1 IS NOT NULL AND @paper_java_q2 IS NOT NULL
  AND NOT EXISTS (SELECT 1 FROM user_answer WHERE exam_record_id = @exam_java_student1 AND paper_question_id = @paper_java_q2 AND deleted = 0);

INSERT INTO user_answer (exam_record_id, paper_question_id, question_id, question_type, answer_content, awarded_score, correct_flag, auto_graded, needs_manual_review, created_at, updated_at, deleted)
SELECT @exam_java_student1, @paper_java_q3, @q_java_fb, 'FILL_BLANK', '[\"private\"]', 0.00, 0, 1, 0, NOW(), NOW(), 0
FROM DUAL
WHERE @exam_java_student1 IS NOT NULL AND @paper_java_q3 IS NOT NULL
  AND NOT EXISTS (SELECT 1 FROM user_answer WHERE exam_record_id = @exam_java_student1 AND paper_question_id = @paper_java_q3 AND deleted = 0);

INSERT INTO user_answer (exam_record_id, paper_question_id, question_id, question_type, answer_content, awarded_score, correct_flag, auto_graded, needs_manual_review, created_at, updated_at, deleted)
SELECT @exam_java_student1, @paper_java_q4, @q_java_mc, 'MULTIPLE_CHOICE', '[\"A\",\"C\"]', 40.00, 1, 1, 0, NOW(), NOW(), 0
FROM DUAL
WHERE @exam_java_student1 IS NOT NULL AND @paper_java_q4 IS NOT NULL
  AND NOT EXISTS (SELECT 1 FROM user_answer WHERE exam_record_id = @exam_java_student1 AND paper_question_id = @paper_java_q4 AND deleted = 0);

SET @ua_java_q1 := (SELECT id FROM user_answer WHERE exam_record_id = @exam_java_student1 AND paper_question_id = @paper_java_q1 AND deleted = 0 LIMIT 1);
SET @ua_java_q2 := (SELECT id FROM user_answer WHERE exam_record_id = @exam_java_student1 AND paper_question_id = @paper_java_q2 AND deleted = 0 LIMIT 1);
SET @ua_java_q3 := (SELECT id FROM user_answer WHERE exam_record_id = @exam_java_student1 AND paper_question_id = @paper_java_q3 AND deleted = 0 LIMIT 1);

INSERT INTO wrong_question (user_id, course_id, chapter_id, question_id, latest_exam_record_id, latest_user_answer_id, question_type, question_stem, option_snapshot, standard_answer, analysis, knowledge_point, status, wrong_count, last_wrong_at, created_at, updated_at, deleted)
SELECT @student1_id, @course_java, @java_ch1, @q_java_sc, @exam_java_student1, @ua_java_q1, 'SINGLE_CHOICE', 'Java 源代码经过 javac 编译后生成的产物是什么？', '[{"optionKey":"A","content":"class"},{"optionKey":"B","content":"machine"},{"optionKey":"C","content":"script"},{"optionKey":"D","content":"jar"}]', '\"A\"', 'Java 源文件会先编译成字节码，再由 JVM 执行。', '类与对象', 'UNMASTERED', 1, DATE_SUB(NOW(), INTERVAL 11 HOUR), NOW(), NOW(), 0
FROM DUAL
WHERE @student1_id IS NOT NULL AND @q_java_sc IS NOT NULL
  AND NOT EXISTS (SELECT 1 FROM wrong_question WHERE user_id = @student1_id AND question_id = @q_java_sc AND deleted = 0);

INSERT INTO wrong_question (user_id, course_id, chapter_id, question_id, latest_exam_record_id, latest_user_answer_id, question_type, question_stem, option_snapshot, standard_answer, analysis, knowledge_point, status, wrong_count, last_wrong_at, created_at, updated_at, deleted)
SELECT @student1_id, @course_java, @java_ch2, @q_java_tf, @exam_java_student1, @ua_java_q2, 'TRUE_FALSE', 'JVM 屏蔽了不同操作系统的底层差异，因此 Java 具备较强的跨平台能力。', '[]', 'true', '字节码运行在 JVM 上，JVM 为不同平台提供统一执行环境。', '封装与访问控制', 'REVIEWING', 1, DATE_SUB(NOW(), INTERVAL 11 HOUR), NOW(), NOW(), 0
FROM DUAL
WHERE @student1_id IS NOT NULL AND @q_java_tf IS NOT NULL
  AND NOT EXISTS (SELECT 1 FROM wrong_question WHERE user_id = @student1_id AND question_id = @q_java_tf AND deleted = 0);

INSERT INTO wrong_question (user_id, course_id, chapter_id, question_id, latest_exam_record_id, latest_user_answer_id, question_type, question_stem, option_snapshot, standard_answer, analysis, knowledge_point, status, wrong_count, last_wrong_at, created_at, updated_at, deleted)
SELECT @student1_id, @course_java, @java_ch2, @q_java_fb, @exam_java_student1, @ua_java_q3, 'FILL_BLANK', '在 Java 中，允许子类和同包类访问、但不允许其他包普通类直接访问的关键字是什么？', '[]', '[\"protected\"]', 'protected 兼顾继承场景与同包访问。', '封装与访问控制', 'UNMASTERED', 2, DATE_SUB(NOW(), INTERVAL 11 HOUR), NOW(), NOW(), 0
FROM DUAL
WHERE @student1_id IS NOT NULL AND @q_java_fb IS NOT NULL
  AND NOT EXISTS (SELECT 1 FROM wrong_question WHERE user_id = @student1_id AND question_id = @q_java_fb AND deleted = 0);

INSERT INTO knowledge_resource (course_id, knowledge_point_id, resource_type, resource_id, created_at, updated_at, deleted)
SELECT @course_java, @kp_class, 'CHAPTER', @java_ch1, NOW(), NOW(), 0
FROM DUAL
WHERE @kp_class IS NOT NULL AND @java_ch1 IS NOT NULL
  AND NOT EXISTS (
    SELECT 1 FROM knowledge_resource
    WHERE knowledge_point_id = @kp_class AND resource_type = 'CHAPTER' AND resource_id = @java_ch1 AND deleted = 0
  );

INSERT INTO knowledge_resource (course_id, knowledge_point_id, resource_type, resource_id, created_at, updated_at, deleted)
SELECT @course_java, @kp_class, 'VIDEO', @java_video_1, NOW(), NOW(), 0
FROM DUAL
WHERE @kp_class IS NOT NULL AND @java_video_1 IS NOT NULL
  AND NOT EXISTS (
    SELECT 1 FROM knowledge_resource
    WHERE knowledge_point_id = @kp_class AND resource_type = 'VIDEO' AND resource_id = @java_video_1 AND deleted = 0
  );

INSERT INTO knowledge_resource (course_id, knowledge_point_id, resource_type, resource_id, created_at, updated_at, deleted)
SELECT @course_java, @kp_access, 'VIDEO', @java_video_2, NOW(), NOW(), 0
FROM DUAL
WHERE @kp_access IS NOT NULL AND @java_video_2 IS NOT NULL
  AND NOT EXISTS (
    SELECT 1 FROM knowledge_resource
    WHERE knowledge_point_id = @kp_access AND resource_type = 'VIDEO' AND resource_id = @java_video_2 AND deleted = 0
  );

INSERT INTO knowledge_resource (course_id, knowledge_point_id, resource_type, resource_id, created_at, updated_at, deleted)
SELECT @course_java, @kp_access, 'DOCUMENT', @java_pdf_1, NOW(), NOW(), 0
FROM DUAL
WHERE @kp_access IS NOT NULL AND @java_pdf_1 IS NOT NULL
  AND NOT EXISTS (
    SELECT 1 FROM knowledge_resource
    WHERE knowledge_point_id = @kp_access AND resource_type = 'DOCUMENT' AND resource_id = @java_pdf_1 AND deleted = 0
  );

INSERT INTO knowledge_resource (course_id, knowledge_point_id, resource_type, resource_id, created_at, updated_at, deleted)
SELECT @course_java, @kp_access, 'QUESTION', @q_java_tf, NOW(), NOW(), 0
FROM DUAL
WHERE @kp_access IS NOT NULL AND @q_java_tf IS NOT NULL
  AND NOT EXISTS (
    SELECT 1 FROM knowledge_resource
    WHERE knowledge_point_id = @kp_access AND resource_type = 'QUESTION' AND resource_id = @q_java_tf AND deleted = 0
  );

INSERT INTO knowledge_resource (course_id, knowledge_point_id, resource_type, resource_id, created_at, updated_at, deleted)
SELECT @course_java, @kp_access, 'QUESTION', @q_java_fb, NOW(), NOW(), 0
FROM DUAL
WHERE @kp_access IS NOT NULL AND @q_java_fb IS NOT NULL
  AND NOT EXISTS (
    SELECT 1 FROM knowledge_resource
    WHERE knowledge_point_id = @kp_access AND resource_type = 'QUESTION' AND resource_id = @q_java_fb AND deleted = 0
  );

INSERT INTO knowledge_resource (course_id, knowledge_point_id, resource_type, resource_id, created_at, updated_at, deleted)
SELECT @course_java, @kp_inherit, 'QUESTION', @q_java_mc, NOW(), NOW(), 0
FROM DUAL
WHERE @kp_inherit IS NOT NULL AND @q_java_mc IS NOT NULL
  AND NOT EXISTS (
    SELECT 1 FROM knowledge_resource
    WHERE knowledge_point_id = @kp_inherit AND resource_type = 'QUESTION' AND resource_id = @q_java_mc AND deleted = 0
  );

INSERT INTO learning_recommendation (user_id, course_id, batch_no, knowledge_point_id, knowledge_point_name, resource_type, resource_id, resource_title, reason, sort_order, default_recommendation, created_at, updated_at, deleted)
SELECT @student1_id, @course_java, 'demo-java-batch-1', @kp_class, '类与对象', 'CHAPTER', @java_ch1, 'Java 与开发环境', '“类与对象”是后续知识点的基础，建议先回看课程主线章节。', 1, 0, NOW(), NOW(), 0
FROM DUAL
WHERE @student1_id IS NOT NULL AND @kp_class IS NOT NULL AND @java_ch1 IS NOT NULL
  AND NOT EXISTS (
    SELECT 1 FROM learning_recommendation
    WHERE user_id = @student1_id AND course_id = @course_java AND batch_no = 'demo-java-batch-1' AND resource_id = @java_ch1 AND deleted = 0
  );

INSERT INTO learning_recommendation (user_id, course_id, batch_no, knowledge_point_id, knowledge_point_name, resource_type, resource_id, resource_title, reason, sort_order, default_recommendation, created_at, updated_at, deleted)
SELECT @student1_id, @course_java, 'demo-java-batch-1', @kp_access, '封装与访问控制', 'VIDEO', @java_video_2, '类与对象快速入门', '你在“封装与访问控制”相关错题中连续出错，建议优先复习该视频。', 2, 0, NOW(), NOW(), 0
FROM DUAL
WHERE @student1_id IS NOT NULL AND @kp_access IS NOT NULL AND @java_video_2 IS NOT NULL
  AND NOT EXISTS (
    SELECT 1 FROM learning_recommendation
    WHERE user_id = @student1_id AND course_id = @course_java AND batch_no = 'demo-java-batch-1' AND resource_id = @java_video_2 AND deleted = 0
  );

INSERT INTO learning_recommendation (user_id, course_id, batch_no, knowledge_point_id, knowledge_point_name, resource_type, resource_id, resource_title, reason, sort_order, default_recommendation, created_at, updated_at, deleted)
SELECT @student1_id, @course_java, 'demo-java-batch-1', @kp_access, '封装与访问控制', 'DOCUMENT', @java_pdf_1, '环境安装清单', '文档适合用来快速回顾访问控制相关定义。', 3, 0, NOW(), NOW(), 0
FROM DUAL
WHERE @student1_id IS NOT NULL AND @kp_access IS NOT NULL AND @java_pdf_1 IS NOT NULL
  AND NOT EXISTS (
    SELECT 1 FROM learning_recommendation
    WHERE user_id = @student1_id AND course_id = @course_java AND batch_no = 'demo-java-batch-1' AND resource_id = @java_pdf_1 AND deleted = 0
  );

INSERT INTO announcement (title, content, visibility, status, publish_at, created_at, updated_at, deleted)
SELECT '平台演示数据已准备完成', '你现在可以直接使用学生、教师、管理员三个角色体验课程、考试、推荐与自习室功能。', 'ALL', 'PUBLISHED', DATE_SUB(NOW(), INTERVAL 1 DAY), NOW(), NOW(), 0
FROM DUAL
WHERE NOT EXISTS (SELECT 1 FROM announcement WHERE title = '平台演示数据已准备完成' AND deleted = 0);

INSERT INTO announcement (title, content, visibility, status, publish_at, created_at, updated_at, deleted)
SELECT '教师提交通知', 'teacher001 和 teacher002 已具备课程维护、题库管理和知识点维护权限。', 'TEACHER', 'PUBLISHED', DATE_SUB(NOW(), INTERVAL 12 HOUR), NOW(), NOW(), 0
FROM DUAL
WHERE NOT EXISTS (SELECT 1 FROM announcement WHERE title = '教师提交通知' AND deleted = 0);

INSERT INTO announcement (title, content, visibility, status, publish_at, created_at, updated_at, deleted)
SELECT '管理员巡检提示', 'admin001 可查看待审核课程、公告和日志示例。', 'ADMIN', 'PUBLISHED', DATE_SUB(NOW(), INTERVAL 6 HOUR), NOW(), NOW(), 0
FROM DUAL
WHERE NOT EXISTS (SELECT 1 FROM announcement WHERE title = '管理员巡检提示' AND deleted = 0);

INSERT INTO ai_conversation (user_id, course_id, input_type, title, latest_summary, last_message_at, created_at, updated_at, deleted)
SELECT @student1_id, @course_ml, 'TEXT', '逻辑回归和分类边界', '讨论了逻辑回归如何输出概率以及如何理解线性分类边界。', DATE_SUB(NOW(), INTERVAL 5 HOUR), NOW(), NOW(), 0
FROM DUAL
WHERE @student1_id IS NOT NULL AND @course_ml IS NOT NULL
  AND NOT EXISTS (
    SELECT 1 FROM ai_conversation
    WHERE user_id = @student1_id AND course_id = @course_ml AND title = '逻辑回归和分类边界' AND deleted = 0
  );

SET @ai_conv_1 := (SELECT id FROM ai_conversation WHERE user_id = @student1_id AND course_id = @course_ml AND title = '逻辑回归和分类边界' AND deleted = 0 LIMIT 1);

INSERT INTO ai_message (conversation_id, message_role, input_type, content, structured_payload, file_name, mime_type, file_size, created_at, updated_at, deleted)
SELECT @ai_conv_1, 'USER', 'TEXT', '为什么逻辑回归明明名字里有回归，却被用来做分类？', NULL, NULL, NULL, NULL, DATE_SUB(NOW(), INTERVAL 5 HOUR), DATE_SUB(NOW(), INTERVAL 5 HOUR), 0
FROM DUAL
WHERE @ai_conv_1 IS NOT NULL
  AND NOT EXISTS (
    SELECT 1 FROM ai_message
    WHERE conversation_id = @ai_conv_1 AND message_role = 'USER'
      AND content = '为什么逻辑回归明明名字里有回归，却被用来做分类？' AND deleted = 0
  );

INSERT INTO ai_message (conversation_id, message_role, input_type, content, structured_payload, file_name, mime_type, file_size, created_at, updated_at, deleted)
SELECT @ai_conv_1, 'ASSISTANT', 'TEXT', '因为它输出的是样本属于某一类的概率，最后再用阈值把概率映射成类别，所以本质上是分类模型。', '{"highlights":["sigmoid 输出概率","阈值映射类别","适合二分类入门"]}', NULL, NULL, NULL, DATE_SUB(NOW(), INTERVAL 4 HOUR), DATE_SUB(NOW(), INTERVAL 4 HOUR), 0
FROM DUAL
WHERE @ai_conv_1 IS NOT NULL
  AND NOT EXISTS (
    SELECT 1 FROM ai_message
    WHERE conversation_id = @ai_conv_1 AND message_role = 'ASSISTANT'
      AND content = '因为它输出的是样本属于某一类的概率，最后再用阈值把概率映射成类别，所以本质上是分类模型。' AND deleted = 0
  );

INSERT INTO ai_call_log (user_id, conversation_id, course_id, input_type, endpoint, status, request_summary, response_summary, error_message, duration_ms, created_at, updated_at, deleted)
SELECT @student1_id, @ai_conv_1, @course_ml, 'TEXT', '/chat/recommend', 'SUCCESS', '学生询问逻辑回归为何用于分类', '返回了概率解释、sigmoid 与阈值分类说明', NULL, 842, NOW(), NOW(), 0
FROM DUAL
WHERE @student1_id IS NOT NULL AND @ai_conv_1 IS NOT NULL AND @course_ml IS NOT NULL
  AND NOT EXISTS (
    SELECT 1 FROM ai_call_log
    WHERE conversation_id = @ai_conv_1 AND endpoint = '/chat/recommend' AND request_summary = '学生询问逻辑回归为何用于分类' AND deleted = 0
  );

INSERT INTO login_log (user_id, username, success, failure_reason, request_path, ip_address, user_agent, created_at, updated_at, deleted)
SELECT @student1_id, 'student001', 1, NULL, '/api/auth/login', '127.0.0.1', 'DemoSeed/1.0', DATE_SUB(NOW(), INTERVAL 2 HOUR), DATE_SUB(NOW(), INTERVAL 2 HOUR), 0
FROM DUAL
WHERE @student1_id IS NOT NULL
  AND NOT EXISTS (
    SELECT 1 FROM login_log
    WHERE username = 'student001' AND request_path = '/api/auth/login' AND user_agent = 'DemoSeed/1.0' AND deleted = 0
  );

INSERT INTO login_log (user_id, username, success, failure_reason, request_path, ip_address, user_agent, created_at, updated_at, deleted)
SELECT @teacher1_id, 'teacher001', 1, NULL, '/api/auth/login', '127.0.0.1', 'DemoSeed/1.0', DATE_SUB(NOW(), INTERVAL 90 MINUTE), DATE_SUB(NOW(), INTERVAL 90 MINUTE), 0
FROM DUAL
WHERE @teacher1_id IS NOT NULL
  AND NOT EXISTS (
    SELECT 1 FROM login_log
    WHERE username = 'teacher001' AND request_path = '/api/auth/login' AND user_agent = 'DemoSeed/1.0' AND deleted = 0
  );

INSERT INTO operation_log (operator_user_id, operator_username, action, target_type, target_id, http_method, request_path, success, request_summary, error_message, duration_ms, ip_address, user_agent, created_at, updated_at, deleted)
SELECT @teacher1_id, 'teacher001', '创建课程', 'course', CAST(@course_java AS CHAR), 'POST', '/api/teacher/courses', 1, '创建 Java 程序设计基础 演示课程', NULL, 215, '127.0.0.1', 'DemoSeed/1.0', DATE_SUB(NOW(), INTERVAL 80 MINUTE), DATE_SUB(NOW(), INTERVAL 80 MINUTE), 0
FROM DUAL
WHERE @teacher1_id IS NOT NULL AND @course_java IS NOT NULL
  AND NOT EXISTS (
    SELECT 1 FROM operation_log
    WHERE operator_username = 'teacher001' AND action = '创建课程' AND request_path = '/api/teacher/courses' AND deleted = 0
  );

INSERT INTO operation_log (operator_user_id, operator_username, action, target_type, target_id, http_method, request_path, success, request_summary, error_message, duration_ms, ip_address, user_agent, created_at, updated_at, deleted)
SELECT @admin1_id, 'admin001', '审核课程', 'course', CAST(@course_ml AS CHAR), 'POST', '/api/admin/courses/{id}/review', 1, '管理员查看并确认机器学习实践导论课程数据完整', NULL, 168, '127.0.0.1', 'DemoSeed/1.0', DATE_SUB(NOW(), INTERVAL 70 MINUTE), DATE_SUB(NOW(), INTERVAL 70 MINUTE), 0
FROM DUAL
WHERE @admin1_id IS NOT NULL AND @course_ml IS NOT NULL
  AND NOT EXISTS (
    SELECT 1 FROM operation_log
    WHERE operator_username = 'admin001' AND action = '审核课程' AND request_path = '/api/admin/courses/{id}/review' AND deleted = 0
  );

INSERT INTO resource_access_log (user_id, course_id, resource_id, resource_type, request_path, ip_address, user_agent, created_at, updated_at, deleted)
SELECT @student1_id, @course_java, @java_video_2, 'VIDEO', '/api/resources/' , '127.0.0.1', 'DemoSeed/1.0', DATE_SUB(NOW(), INTERVAL 50 MINUTE), DATE_SUB(NOW(), INTERVAL 50 MINUTE), 0
FROM DUAL
WHERE @student1_id IS NOT NULL AND @course_java IS NOT NULL AND @java_video_2 IS NOT NULL
  AND NOT EXISTS (
    SELECT 1 FROM resource_access_log
    WHERE user_id = @student1_id AND resource_id = @java_video_2 AND request_path = '/api/resources/' AND deleted = 0
  );

INSERT INTO system_error_log (user_id, error_code, exception_class, error_message, http_method, request_path, request_summary, ip_address, user_agent, created_at, updated_at, deleted)
SELECT @student2_id, 40004, 'BusinessException', '示例错误：学生尝试访问未报名课程资源', 'GET', '/api/resources/999/download', '{"resourceId":999}', '127.0.0.1', 'DemoSeed/1.0', DATE_SUB(NOW(), INTERVAL 40 MINUTE), DATE_SUB(NOW(), INTERVAL 40 MINUTE), 0
FROM DUAL
WHERE @student2_id IS NOT NULL
  AND NOT EXISTS (
    SELECT 1 FROM system_error_log
    WHERE exception_class = 'BusinessException' AND request_path = '/api/resources/999/download' AND deleted = 0
  );

COMMIT;
SQL
}

seed_room_seats() {
  local room_name="$1"
  local capacity="$2"
  local occupied_csv="${3:-}"
  local room_id
  local seat
  local status

  room_id="$(mysql_value "SELECT id FROM study_room WHERE room_name = '${room_name}' AND deleted = 0 LIMIT 1;")"
  if [[ -z "${room_id}" ]]; then
    echo "Study room not found, skip seats: ${room_name}" >&2
    return 0
  fi

  for seat in $(seq 1 "${capacity}"); do
    status="EMPTY"
    if [[ ",${occupied_csv}," == *",${seat},"* ]]; then
      status="OCCUPIED"
    fi
    mysql_exec -e "
      INSERT INTO study_room_seat (room_id, seat_no, status, created_at, updated_at, deleted)
      SELECT ${room_id}, ${seat}, '${status}', NOW(), NOW(), 0
      FROM DUAL
      WHERE NOT EXISTS (
        SELECT 1 FROM study_room_seat WHERE room_id = ${room_id} AND seat_no = ${seat} AND deleted = 0
      );
      UPDATE study_room_seat
      SET status = '${status}', updated_at = NOW(), deleted = 0
      WHERE room_id = ${room_id} AND seat_no = ${seat};
    " >/dev/null
  done

  echo "Seeded seats for ${room_name}"
}

print_summary() {
  mysql_exec -e "
    SELECT 'user' AS table_name, COUNT(*) AS cnt FROM user
    UNION ALL SELECT 'course', COUNT(*) FROM course
    UNION ALL SELECT 'course_chapter', COUNT(*) FROM course_chapter
    UNION ALL SELECT 'course_resource', COUNT(*) FROM course_resource
    UNION ALL SELECT 'course_enrollment', COUNT(*) FROM course_enrollment
    UNION ALL SELECT 'video_progress', COUNT(*) FROM video_progress
    UNION ALL SELECT 'study_room', COUNT(*) FROM study_room
    UNION ALL SELECT 'study_room_seat', COUNT(*) FROM study_room_seat
    UNION ALL SELECT 'question', COUNT(*) FROM question
    UNION ALL SELECT 'paper', COUNT(*) FROM paper
    UNION ALL SELECT 'exam_record', COUNT(*) FROM exam_record
    UNION ALL SELECT 'wrong_question', COUNT(*) FROM wrong_question
    UNION ALL SELECT 'knowledge_point', COUNT(*) FROM knowledge_point
    UNION ALL SELECT 'learning_recommendation', COUNT(*) FROM learning_recommendation
    UNION ALL SELECT 'announcement', COUNT(*) FROM announcement
    UNION ALL SELECT 'ai_conversation', COUNT(*) FROM ai_conversation
    UNION ALL SELECT 'login_log', COUNT(*) FROM login_log
    UNION ALL SELECT 'operation_log', COUNT(*) FROM operation_log;
  "
}

main() {
  require_command curl
  require_command mysql
  wait_for_backend

  echo "Preparing demo users ..."
  ensure_user "student001" "123456" "学生一号" "student001@example.com" "13800138000"
  ensure_user "student002" "123456" "学生二号" "student002@example.com" "13800138001"
  ensure_user "student003" "123456" "学生三号" "student003@example.com" "13800138002"
  ensure_user "teacher001" "123456" "王老师" "teacher001@example.com" "13900139000"
  ensure_user "teacher002" "123456" "李老师" "teacher002@example.com" "13900139001"
  ensure_user "admin001" "123456" "管理员一号" "admin001@example.com" "13700137000"

  set_exact_roles "student001" "STUDENT"
  set_exact_roles "student002" "STUDENT"
  set_exact_roles "student003" "STUDENT"
  set_exact_roles "teacher001" "TEACHER"
  set_exact_roles "teacher002" "TEACHER"
  set_exact_roles "admin001" "ADMIN"

  echo "Seeding demo business data ..."
  seed_core_data
  seed_room_seats "Java 晚间自习室" 8 "3"
  seed_room_seats "算法冲刺自习室" 6 "2"

  echo
  echo "Demo data is ready."
  echo "Example accounts:"
  echo "  student001 / 123456"
  echo "  student002 / 123456"
  echo "  teacher001 / 123456"
  echo "  teacher002 / 123456"
  echo "  admin001   / 123456"
  echo
  print_summary
}

main "$@"
